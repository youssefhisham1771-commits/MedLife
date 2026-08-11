import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  Future<List<Map<String, dynamic>>> loadCart() async {
    final user = _auth.currentUser;

    if (user == null) return [];

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();

      data['docId'] = doc.id;

      return data;
    }).toList();
  }
  Future<void> updateQuantity(
  String docId,
  int quantity,
) async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) return;

  await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('cart')
      .doc(docId)
      .update({
    'quantity': quantity,
  });
}

Future<void> removeItem(String docId) async {
  final user = _auth.currentUser;

  if (user == null) return;

  await _firestore
      .collection('users')
      .doc(user.uid)
      .collection('cart')
      .doc(docId)
      .delete();
}
}