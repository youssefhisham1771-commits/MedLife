import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../screens/products_screen.dart';
import 'firebase_service.dart';

final GoogleSignIn googleSignIn = GoogleSignIn.instance;

bool _googleInitialized = false;

/// Initialize Google Sign-In once.
Future<void> initializeGoogleSignIn() async {
  if (_googleInitialized) return;

  if (kIsWeb) {
    _googleInitialized = true;
    return;
  }

  await googleSignIn.initialize();

  _googleInitialized = true;
}

/// Create or update the Firestore user document.
Future<void> createOrUpdateGoogleUser(User user) async {
  final userRef = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid);

  final existingUser = await userRef.get();

  final data = <String, dynamic>{
    'name': user.displayName ?? '',
    'email': user.email ?? '',
    'phone': user.phoneNumber ?? '',
    'photoUrl': user.photoURL ?? '',
    'role': 'user',
  };

  // Add createdAt ONLY for a new user.
  if (!existingUser.exists) {
    data['createdAt'] = FieldValue.serverTimestamp();
  }

  await userRef.set(
    data,
    SetOptions(merge: true),
  );
}

/// Google Sign-In for Web + Android/iOS.
Future<void> signInWithGoogleGlobal(
  BuildContext context,
) async {
  try {
    // ============================================================
    // WEB
    // ============================================================

    if (kIsWeb) {
      final GoogleAuthProvider provider =
          GoogleAuthProvider();

      final userCredential =
          await FirebaseAuth.instance.signInWithPopup(
        provider,
      );

      final user = userCredential.user;

      if (user == null) {
        throw Exception(
          'Google authentication failed.',
        );
      }

      // Create/update Firestore user.
      await createOrUpdateGoogleUser(user);

      // FCM errors must NOT break login.
      await saveFcmToken();

      if (!context.mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const ProductsScreen(),
        ),
      );

      return;
    }

    // ============================================================
    // ANDROID / IOS
    // ============================================================

    await initializeGoogleSignIn();

    // Start Google authentication.
    final GoogleSignInAccount googleUser =
        await googleSignIn.authenticate();

    final GoogleSignInAuthentication googleAuth =
        googleUser.authentication;

    final String? idToken = googleAuth.idToken;

    if (idToken == null) {
      throw Exception(
        'Google ID token is missing.',
      );
    }

    final credential =
        GoogleAuthProvider.credential(
      idToken: idToken,
    );

    final userCredential =
        await FirebaseAuth.instance
            .signInWithCredential(credential);

    final user = userCredential.user;

    if (user == null) {
      throw Exception(
        'Firebase authentication failed.',
      );
    }

    // Create/update Firestore user.
    await createOrUpdateGoogleUser(user);

    // FCM errors must NOT break Google login.
    await saveFcmToken();

    if (!context.mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const ProductsScreen(),
      ),
    );
  } on FirebaseAuthException catch (e) {
    debugPrint(
      'GOOGLE FIREBASE AUTH ERROR: ${e.code}',
    );

    debugPrint(
      'GOOGLE FIREBASE AUTH MESSAGE: ${e.message}',
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          e.message ??
              'Google authentication failed.',
        ),
      ),
    );
  } catch (e, stackTrace) {
    debugPrint(
      'GOOGLE ERROR: $e',
    );

    debugPrintStack(
      stackTrace: stackTrace,
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Google Sign-In failed. Please try again.',
        ),
      ),
    );
  }
}