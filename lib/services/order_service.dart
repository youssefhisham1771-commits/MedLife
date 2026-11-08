import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  Future<void> placeOrder({
    required String name,
    required String phone,
    required String addressTitle,
required String governorate,
required String address,
    required List<Map<String, dynamic>> cart,
    required double total,
    required double shipping,
    required double discount,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception("User is not logged in");
    }

    await _firestore.collection('orders').add({
      "userId": user.uid,

      "name": name,

      "phone": phone,

      "addressTitle": addressTitle,

"governorate": governorate,

"address": address,

      "items": cart.map((item) {
        return {
          "name": item["name"],
          "price": item["price"],
          "quantity": item["quantity"] ?? 1,
          "image": item["image"],
          "size": item["size"],
        };
      }).toList(),

      "shipping": shipping,

      "discount": discount,

      "total": total,

      "status": "pending",

      "orderedAt":
          FieldValue.serverTimestamp(),

      "deliveredAt": null,

      "orderNumber":
          "#ORD-${DateTime.now().millisecondsSinceEpoch}",
    });

    final cartRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('cart');

    final snapshot = await cartRef.get();

    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}