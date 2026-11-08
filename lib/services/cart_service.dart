import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'offline_storage_service.dart';

class CartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final OfflineStorageService _storage = OfflineStorageService();

  CollectionReference<Map<String, dynamic>> _ref(String uid) =>
      _firestore.collection('users').doc(uid).collection('cart');

  Future<List<Map<String, dynamic>>> loadCart() async {
    final user = _auth.currentUser;
    if (user == null) return [];
    final local = await _storage.loadCart(user.uid);
    try {
      final snap = await _ref(user.uid).get(
        const GetOptions(source: Source.serverAndCache),
      );
      final remote = snap.docs.map((d) => <String, dynamic>{...d.data(), 'docId': d.id}).toList();
      final result = remote.isNotEmpty || local.isEmpty ? remote : local;
      await _storage.saveCart(user.uid, result);
      return result;
    } catch (_) { return local; }
  }

  Future<void> addOrUpdateItem(Map<String, dynamic> item) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User is not logged in');
    final items = await _storage.loadCart(user.uid);
    final i = items.indexWhere((x) => x['name'] == item['name'] && x['size'] == item['size']);
    if (i >= 0) {
      items[i]['quantity'] = ((items[i]['quantity'] as num?)?.toInt() ?? 1) +
          ((item['quantity'] as num?)?.toInt() ?? 1);
    } else {
      final next = Map<String, dynamic>.from(item);
      next['docId'] = 'cart_${DateTime.now().microsecondsSinceEpoch}';
      items.add(next);
    }
    await _storage.saveCart(user.uid, items);
    await syncCart();
  }

  Future<void> updateQuantity(String docId, int quantity) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final items = await _storage.loadCart(user.uid);
    final i = items.indexWhere((x) => x['docId'] == docId);
    if (i < 0) return;
    items[i]['quantity'] = quantity;
    await _storage.saveCart(user.uid, items);
    try {
      final data = Map<String, dynamic>.from(items[i])..remove('docId');
      await _ref(user.uid).doc(docId).set(data);
    } catch (_) {}
  }

  Future<void> removeItem(String docId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final items = await _storage.loadCart(user.uid);
    items.removeWhere((x) => x['docId'] == docId);
    await _storage.saveCart(user.uid, items);
    try { await _ref(user.uid).doc(docId).delete(); } catch (_) {}
  }

  Future<void> clearCart() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _storage.saveCart(user.uid, []);
    try {
      final snap = await _ref(user.uid).get();
      final batch = _firestore.batch();
      for (final doc in snap.docs) { batch.delete(doc.reference); }
      await batch.commit();
    } catch (_) {}
  }

  Future<void> syncCart() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final items = await _storage.loadCart(user.uid);
    try {
      final remote = await _ref(user.uid).get(const GetOptions(source: Source.server));
      final ids = items.map((x) => x['docId']?.toString()).whereType<String>().toSet();
      final batch = _firestore.batch();
      for (final doc in remote.docs) {
        if (!ids.contains(doc.id)) batch.delete(doc.reference);
      }
      for (final item in items) {
        final id = item['docId']?.toString();
        if (id == null || id.isEmpty) continue;
        final data = Map<String, dynamic>.from(item)..remove('docId');
        batch.set(_ref(user.uid).doc(id), data);
      }
      await batch.commit();
    } catch (_) {}
  }
}