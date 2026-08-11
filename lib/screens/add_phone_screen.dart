import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'otp_verification_screen.dart';
import 'products_screen.dart';

class AddPhoneScreen extends StatefulWidget {
  const AddPhoneScreen({super.key});

  @override
  State<AddPhoneScreen> createState() => _AddPhoneScreenState();
}

class _AddPhoneScreenState extends State<AddPhoneScreen> {
  final phoneController = TextEditingController();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  bool isLoading = false;

  String completePhone = "";

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xff121212) : Colors.white,

      body: SafeArea(
        child: Stack(
          children: [

            /// Background

            Positioned(
              top: -120,
              right: -80,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xff2D7DFF)
                      .withValues(alpha: .08),
                ),
              ),
            ),

            Positioned(
              top: 180,
              left: 55,
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Color(0xff62D84E),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            Positioned(
              top: 130,
              right: 105,
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Color(0xff73B4FF),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            Form(
              key: formKey,

              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Center(
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(
                            0xff2D7DFF,
                          ).withValues(alpha: .08),
                        ),

                        child: const Icon(
                          Icons.add_call,
                          size: 75,
                          color: Color(0xff1565D8),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    const Center(
                      child: Text(
                        "Add Phone Number",
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    Center(
                      child: Text(
                        "Please add your phone number to\ncomplete your account.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 19,
                          color: Colors.grey.shade600,
                          height: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 45),

                    Container(
                      padding: const EdgeInsets.all(24),

                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xff1D1D1D)
                            : Colors.white,

                        borderRadius:
                            BorderRadius.circular(28),

                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: .06),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),

                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [

                          Row(
                            children: const [

                              Icon(
                                Icons.call,
                                color: Color(0xff5A9CFF),
                              ),

                              SizedBox(width: 12),

                              Text(
                                "Phone Number",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          IntlPhoneField(
  controller: phoneController,

  initialCountryCode: "EG",

  decoration: InputDecoration(
    hintText: "1001234567",

    filled: true,
    fillColor: isDark
        ? const Color(0xff2A2A2A)
        : const Color(0xffF7F9FC),

    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide.none,
    ),

    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(
        color: Colors.grey.shade300,
      ),
    ),

    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(
        color: Color(0xff1565D8),
        width: 2,
      ),
    ),
  ),

  onChanged: (phone) {
    completePhone = phone.completeNumber;
  },

  validator: (phone) {
    if (phone == null ||
        phone.number.trim().isEmpty) {
      return "Enter phone number";
    }

    if (phone.number.length < 10) {
      return "Invalid phone number";
    }

    return null;
  },
),

const SizedBox(height: 35),

SizedBox(
  width: double.infinity,
  height: 58,

  child: ElevatedButton(
    onPressed: isLoading
    ? null
    : () async {

        if (!formKey.currentState!.validate()) {
          return;
        }

        setState(() {
          isLoading = true;
        });

        await FirebaseAuth.instance.verifyPhoneNumber(

          phoneNumber: completePhone,

          verificationCompleted:
              (PhoneAuthCredential credential) async {

            await FirebaseAuth.instance.currentUser!
                .linkWithCredential(credential);

            await FirebaseFirestore.instance
                .collection("users")
                .doc(FirebaseAuth.instance.currentUser!.uid)
                .update({

              "phone": completePhone,
              "phoneVerified": true,

            });

            if (!mounted) return;

            Navigator.pushAndRemoveUntil(

              context,

              MaterialPageRoute(
                builder: (_) => ProductsScreen(),
              ),

              (route) => false,
            );
          },

          verificationFailed:
              (FirebaseAuthException e) {

            setState(() {
              isLoading = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(

              SnackBar(
                content: Text(
                  e.message ?? "Verification Failed",
                ),
              ),
            );
          },

          codeSent:
              (String verificationId,
                  int? resendToken) {

            setState(() {
              isLoading = false;
            });

            Navigator.push(

              context,

              MaterialPageRoute(

                builder: (_) =>
                    OtpVerificationScreen(

                  verificationId:
                      verificationId,

                  phoneNumber:
                      completePhone,

                ),
              ),
            );
          },

          codeAutoRetrievalTimeout:
              (verificationId) {},

        );
      },

    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xff1565D8),

      elevation: 0,

      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
      ),
    ),

    child: isLoading
        ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white,
            ),
          )
        : const Text(
            "Continue",
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
        ),
          ),
),
],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}