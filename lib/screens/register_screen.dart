import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'products_screen.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';

///////////////////// 🔐 REGISTER SCREEN /////////////////////

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final pass = TextEditingController();

  bool isLoading = false;
  bool isPasswordHidden = true;

  Future<void> register() async {
  if (name.text.trim().isEmpty ||
      phone.text.trim().isEmpty ||
      email.text.trim().isEmpty ||
      pass.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("املأ كل البيانات"),
      ),
    );
    return;
  }

  if (pass.text.trim().length < 8) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("الباسورد لازم يكون 8 حروف على الأقل"),
      ),
    );
    return;
  }

  setState(() => isLoading = true);

  try {
    // 1️⃣ Create Firebase Authentication account
    final userCred =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email.text.trim(),
      password: pass.text.trim(),
    );

    final user = userCred.user;

    if (user == null) {
      throw Exception("User account was not created.");
    }

    // 2️⃣ Create user document in Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({
      'name': name.text.trim(),
      'phone': phone.text.trim(),
      'email': email.text.trim(),
      'role': 'user',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 3️⃣ Save FCM token separately.
    // This function is protected against Web/FCM errors.
    await saveFcmToken();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Welcome to MedLife!"),
      ),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const ProductsScreen(),
      ),
    );
  } on FirebaseAuthException catch (e) {
    debugPrint("AUTH ERROR: ${e.code}");
    debugPrint("AUTH MESSAGE: ${e.message}");

    if (!mounted) return;

    String message;

    switch (e.code) {
      case 'email-already-in-use':
        message = "The email address is already in use.";
        break;

      case 'invalid-email':
        message = "Please enter a valid email address.";
        break;

      case 'weak-password':
        message = "The password is too weak.";
        break;

      case 'operation-not-allowed':
        message = "Email/password registration is not enabled.";
        break;

      default:
        message = e.message ?? "Registration failed.";
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  } catch (e, stackTrace) {
    debugPrint("REGISTER ERROR: $e");
    debugPrintStack(stackTrace: stackTrace);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Something went wrong. Please try again."),
      ),
    );
  } finally {
    if (mounted) {
      setState(() => isLoading = false);
    }
  }
}

  

  Widget buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? isPasswordHidden : false,
        keyboardType: keyboard,
        style: const TextStyle(
  color: Color(0xff0B1F51),
  fontSize: 17,
  fontWeight: FontWeight.w500,
),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Color(0xff0B1F51),
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(
            icon,
            color: Color(0xff2F80ED),
          ),
          suffixIcon: isPassword
              ? IconButton(
                  onPressed: () {
                    setState(() {
                      isPasswordHidden = !isPasswordHidden;
                    });
                  },
                  icon: Icon(
                    isPasswordHidden
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.grey,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        ),
      ),
    );
  }

  Widget socialButton({
  required String text,
  required String image,
  VoidCallback? onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),

    child: Container(
      width: 220,
      height: 62,

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),

        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),

      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [

            Image.network(
              image,
              height: 24,
            ),

            SizedBox(width: 10),

            Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xff0B1F51),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget featureItem(
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.white,
          child: Icon(
            icon,
            color: Color(0xff0B1F51),
            size: 28,
          ),
        ),
        SizedBox(height: 10),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xff0B1F51),
          ),
        ),
        SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffF5F9FF),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 22),

            child: Column(
              children: [

                SizedBox(height: 20),

                /// 🔙 BACK
                Align(
                  alignment: Alignment.centerLeft,
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back,
                      color: Colors.black),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),

                SizedBox(height: 15),

                /// 🖼️ LOGO
                Image.asset(
  "assets/b2.png",
  height: 170,
  fit: BoxFit.contain,
),

                SizedBox(height: 10),

                /// 🔥 TITLE
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Create Account",
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff0B1F51),
                        ),
                      ),

                      SizedBox(height: 5),

                      Text(
                        "Sign up to get started!",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 25),

                /// 📦 CARD
                Container(
                  padding: EdgeInsets.all(20),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(35),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),

                  child: Column(
                    children: [

                      /// 👤 NAME
                      buildTextField(
                        controller: name,
                        hint: "Full Name",
                        icon: Icons.person_outline,
                      ),

                      SizedBox(height: 18),

                      /// 📱 PHONE
                      buildTextField(
                        controller: phone,
                        hint: "Phone Number",
                        icon: Icons.phone_outlined,
                        keyboard: TextInputType.phone,
                      ),

                      SizedBox(height: 18),

                      /// 📧 EMAIL
                      buildTextField(
                        controller: email,
                        hint: "Email Address",
                        icon: Icons.email_outlined,
                        keyboard: TextInputType.emailAddress,
                      ),

                      SizedBox(height: 18),

                      /// 🔐 PASSWORD
                      buildTextField(
                        controller: pass,
                        hint: "Password",
                        icon: Icons.lock_outline,
                        isPassword: true,
                      ),

                      SizedBox(height: 20),

                      /// 🔥 REGISTER BUTTON
                      isLoading
                          ? Center(
                              child: CircularProgressIndicator(),
                            )
                          : SizedBox(
                              width: double.infinity,
                              height: 60,

                              child: ElevatedButton(
                                onPressed: register,

                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xff1565FF),

                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(18),
                                  ),

                                  elevation: 8,
                                ),

                                child: Text(
                                  "Register",
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),

                      SizedBox(height: 20),

                      /// 🔁 LOGIN
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an account?",
                            style: TextStyle(fontSize: 16,
                            color: Color(0xff0B1F51),
                            ),
                          ),

                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text(
                              "Login",
                              style: TextStyle(
                                color: Color(0xff2F80ED),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 30),

                /// ➖ OR
                Row(
                  children: [

                    Expanded(
                      child: Divider(
                        thickness: 1,
                        color: Colors.grey.shade300,
                      ),
                    ),

                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        "Or sign up with",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),

                    Expanded(
                      child: Divider(
                        thickness: 1,
                        color: Colors.grey.shade300,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 25),

                /// 🌍 SOCIAL
Center(
  child: socialButton(
    text: "Google",
    image:
        "https://cdn-icons-png.flaticon.com/512/300/300221.png",
    onTap: () => signInWithGoogleGlobal(context),
  ),
),

                SizedBox(height: 35),

                /// 🔥 FEATURES
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceAround,
                  children: [

                    Expanded(
                      child: featureItem(
                        Icons.security_outlined,
                        "Secure Account",
                        "Your data is safe with us",
                      ),
                    ),

                    Expanded(
                      child: featureItem(
                        Icons.local_shipping_outlined,
                        "Fast & Easy",
                        "Quick setup in seconds",
                      ),
                    ),

                    Expanded(
                      child: featureItem(
                        Icons.support_agent_outlined,
                        "24/7 Support",
                        "We're here to help",
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    email.dispose();
    pass.dispose();
    super.dispose();
  }
}