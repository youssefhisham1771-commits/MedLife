import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'products_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const OtpVerificationScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  State<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState
    extends State<OtpVerificationScreen> {

  final codeController = TextEditingController();

  bool isLoading = false;

  Future<void> verifyCode() async {

    if (codeController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enter the 6-digit code"),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {

      PhoneAuthCredential credential =
          PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: codeController.text.trim(),
      );

      await FirebaseAuth.instance.currentUser!
          .linkWithCredential(credential);

          await FirebaseAuth.instance.currentUser!.reload();

      await FirebaseFirestore.instance
          .collection("users")
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({

        "phone": widget.phoneNumber,
        "phoneVerified": true,
        "phoneVerifiedAt": FieldValue.serverTimestamp(),

      });

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => ProductsScreen(),
        ),
        (route) => false,
      );

    } on FirebaseAuthException catch (e) {

      String message = "Verification failed";

      if (e.code == "invalid-verification-code") {
        message = "Incorrect code";
      }

      if (e.code == "credential-already-in-use") {
  message = "This phone number is already linked to another account.";
}

if (e.code == "session-expired") {
  message = "Verification code expired. Please request a new code.";
}

if (e.code == "invalid-phone-number") {
  message = "Invalid phone number.";
}

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }

  }

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(),

      body: Padding(

        padding: const EdgeInsets.all(24),

        child: Column(

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            const SizedBox(height: 30),

            const Text(
              "Verify Phone",
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              "Code sent to\n${widget.phoneNumber}",
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 40),

            TextField(

              controller: codeController,

              keyboardType: TextInputType.number,

              maxLength: 6,

              decoration: InputDecoration(

                hintText: "123456",

                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(18),
                ),

              ),
            ),

            const SizedBox(height: 30),

            SizedBox(

              width: double.infinity,
              height: 56,

              child: ElevatedButton(

                onPressed:
                    isLoading ? null : verifyCode,

                child: isLoading

                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )

                    : const Text(
                        "Verify",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),

              ),
            ),

          ],
        ),
      ),
    );
  }
}