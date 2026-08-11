import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

Future<void> saveFcmToken() async {
  try {
    if (kIsWeb) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({
      'fcmToken': token,
    }, SetOptions(merge: true));
  } catch (e, stackTrace) {
  debugPrint('FCM ERROR: $e');
  debugPrintStack(stackTrace: stackTrace);
}
  }