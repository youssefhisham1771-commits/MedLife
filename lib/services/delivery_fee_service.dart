import 'package:cloud_firestore/cloud_firestore.dart';

class DeliveryFeeService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('deliveryFees');

  Future<Map<String, double>> getAllFees() async {
    final snapshot = await _collection.get();

    final Map<String, double> fees = {};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      fees[doc.id] = (data['fee'] as num?)?.toDouble() ?? 0;
    }

    return fees;
  }

  Future<double> getFee(String governorate) async {
    final doc = await _collection.doc(governorate).get();

    if (!doc.exists) {
      return 0;
    }

    final data = doc.data();

    return (data?['fee'] as num?)?.toDouble() ?? 0;
  }

  Future<void> saveFee({
    required String governorate,
    required double fee,
  }) async {
    await _collection.doc(governorate).set({
      'governorate': governorate,
      'fee': fee,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteFee(String governorate) async {
    await _collection.doc(governorate).delete();
  }
}
