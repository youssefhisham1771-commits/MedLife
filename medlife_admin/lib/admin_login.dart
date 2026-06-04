import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';

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
        password:
            passwordController.text.trim(),
      );

      if (credential.user!.email !=
          "admin@medlife.com") {

        await FirebaseAuth.instance.signOut();

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              "Not Authorized",
            ),
          ),
        );

        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (_) =>
                  const DashboardScreen(),
        ),
      );

    } catch (e, s) {
  print("ERROR = $e");
  print("STACK = $s");


      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );

    } finally {

      setState(() {
        loading = false;
      });
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
                  onPressed:
                      loading
                          ? null
                          : login,
                  child: loading
                      ? const CircularProgressIndicator()
                      : const Text(
                          "Login",
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