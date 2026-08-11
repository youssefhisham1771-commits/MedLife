import 'package:cloud_firestore/cloud_firestore.dart';

class PromoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<double?> getDiscount(String code) async {
    final snapshot =
        await _firestore.collection('promoCodes').doc(code).get();

    if (!snapshot.exists) {
      return null;
    }

    return (snapshot['discount'] as num).toDouble();
  }
}