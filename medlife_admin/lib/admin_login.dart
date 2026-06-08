import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AdminLogin extends StatefulWidget {
  const AdminLogin({super.key});

  @override
  State<AdminLogin> createState() =>
      _AdminLoginState();
}

class _AdminLoginState
    extends State<AdminLogin> {

  final emailController =
      TextEditingController();

  final passwordController =
      TextEditingController();

  bool loading = false;

  Future<void> login() async {
  try {
    setState(() {
      loading = true;
    });

    final credential =
        await FirebaseAuth.instance
            .signInWithEmailAndPassword(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    final uid = credential.user!.uid;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (!userDoc.exists ||
        userDoc.data()?['role'] != 'admin') {

      await FirebaseAuth.instance.signOut();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Not Authorized"),
        ),
      );

      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const DashboardScreen(),
      ),
    );
  } on FirebaseAuthException catch (e) {
    print("CODE = ${e.code}");
    print("MESSAGE = ${e.message}");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.message ?? e.code),
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }
}

Future<void> signInAdminWithGoogle() async {
  try {
    setState(() => loading = true);

    GoogleAuthProvider provider = GoogleAuthProvider();

    final credential =
        await FirebaseAuth.instance.signInWithPopup(provider);

    final uid = credential.user!.uid;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (!doc.exists ||
        doc.data()?['role'] != 'admin') {

      await FirebaseAuth.instance.signOut();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You are not an admin"),
        ),
      );

      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const DashboardScreen(),
      ),
    );
  } catch (e) {
    print(e);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString())),
    );
  } finally {
    if (mounted) {
      setState(() => loading = false);
    }
  }
}

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor:
          const Color(0xff0B1120),

      body: Center(
        child: Container(
          width: 400,
          padding:
              const EdgeInsets.all(25),

          decoration: BoxDecoration(
            color:
                const Color(0xff111827),
            borderRadius:
                BorderRadius.circular(
              20,
            ),
          ),

          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [

              const Text(
                "MEDLIFE ADMIN",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 25),

              TextField(
                controller:
                    emailController,
                decoration:
                    const InputDecoration(
                  labelText: "Email",
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller:
                    passwordController,
                obscureText: true,
                decoration:
                    const InputDecoration(
                  labelText: "Password",
                ),
              ),

              const SizedBox(height: 25),

              SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    onPressed: loading
        ? null
        : signInAdminWithGoogle,
    child: const Text(
      "Login With Google",
    ),
  ),
),
            ],
          ),
        ),
      ),
    );
  }
}