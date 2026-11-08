import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'offline_storage_service.dart';
import 'cart_service.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final OfflineStorageService _storage = OfflineStorageService();
  final CartService _cart = CartService();

  /// true = stored in Firestore; false = safely saved locally awaiting sync.
  Future<bool> placeOrder({
    required String name, required String phone, required String addressTitle,
    required String governorate, required String address,
    required List<Map<String, dynamic>> cart, required double total,
    required double shipping, required double discount,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User is not logged in');
    final now = DateTime.now();
    final localId = 'offline_${now.microsecondsSinceEpoch}';
    final payload = <String, dynamic>{
      'userId': user.uid, 'name': name, 'phone': phone,
      'addressTitle': addressTitle, 'governorate': governorate, 'address': address,
      'items': cart.map((x) => {
        'name': x['name'], 'price': x['price'], 'quantity': x['quantity'] ?? 1,
        'image': x['image'], 'size': x['size'],
      }).toList(),
      'shipping': shipping, 'discount': discount, 'total': total,
      'status': 'pending', 'syncStatus': 'pending_sync',
      'orderedAt': now.toIso8601String(), 'deliveredAt': null,
      'orderNumber': '#ORD-${now.millisecondsSinceEpoch}',
    };
    await _storage.addPendingOrder(user.uid, {'localId': localId, 'payload': payload});
    await _cart.clearCart();
    try {
      await _syncOne(user.uid, localId, payload);
      return true;
    } catch (_) { return false; }
  }

  Future<void> syncPendingOrders() async {
    final user = _auth.currentUser;
    if (user == null) return;
    for (final entry in await _storage.loadPendingOrders(user.uid)) {
      final id = entry['localId']?.toString();
      final raw = entry['payload'];
      if (id == null || raw is! Map) continue;
      try { await _syncOne(user.uid, id, Map<String, dynamic>.from(raw)); }
      catch (_) { break; }
    }
  }

  Future<void> _syncOne(String uid, String id, Map<String, dynamic> payload) async {
    final date = DateTime.tryParse(payload['orderedAt']?.toString() ?? '') ?? DateTime.now();
    final data = Map<String, dynamic>.from(payload)
      ..remove('syncStatus')
      ..['orderedAt'] = Timestamp.fromDate(date);
    // Fixed document ID prevents duplicate orders if synchronization is retried.
    await _firestore.collection('orders').doc(id).set(data);
    await _storage.removePendingOrder(uid, id);
  }
}