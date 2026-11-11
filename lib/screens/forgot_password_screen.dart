import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';



class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();

  Future<void> sendResetEmail() async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: emailController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Password reset email sent ✅",
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? "Error"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,

        title: Text(
          "Forgot Password",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),

        child: Column(
          children: [
            SizedBox(height: 10),

            /// TOP ICON
            Container(
              padding: EdgeInsets.all(35),

              decoration: BoxDecoration(
                shape: BoxShape.circle,

                gradient: RadialGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
                  ],
                ),
              ),

              child: Stack(
                alignment: Alignment.center,

                children: [
                  Icon(
                    Icons.lock_reset_rounded,
                    size: 110,
                    color: Theme.of(context).colorScheme.primary,
                  ),

                  Positioned(
                    right: 0,
                    bottom: 5,

                    child: Container(
                      padding: EdgeInsets.all(12),

                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.primary,
                      ),

                      child: Icon(
                        Icons.email_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 25),

            /// TITLE
            RichText(
              textAlign: TextAlign.center,

              text: TextSpan(
                children: [
                  TextSpan(
                    text: "Reset ",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  TextSpan(
                    text: "Your Password",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 18),

            /// SUBTITLE
            Text(
              "Enter your email address and we’ll send you a link to reset your password. (CHECK SPAM!!)",

              textAlign: TextAlign.center,

              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 20,
                height: 1.5,
              ),
            ),

            SizedBox(height: 40),

            /// INPUT TITLE
            Align(
              alignment: Alignment.centerLeft,

              child: Text(
                "Email Address",

                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            SizedBox(height: 15),

            /// EMAIL FIELD
            Container(
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(24),

                color: Theme.of(context).colorScheme.surface,

                border: Border.all(
                  color: Theme.of(context).dividerColor,
                ),
              ),

              child: TextField(
                controller: emailController,

                keyboardType:
                    TextInputType.emailAddress,

                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 18,
                ),

                decoration: InputDecoration(
                  border: InputBorder.none,

                  contentPadding:
                      EdgeInsets.symmetric(
                    vertical: 24,
                  ),

                  hintText:
                      "Enter your email address",

                  hintStyle: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontSize: 18,
                  ),

                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                ),
              ),
            ),

            SizedBox(height: 35),

            /// SEND BUTTON
            SizedBox(
              width: double.infinity,
              height: 68,

              child: ElevatedButton(
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).colorScheme.primary,

                  elevation: 12,

                  shadowColor:
                      const Color(0x886EA6C1),

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      40,
                    ),
                  ),
                ),

                onPressed: sendResetEmail,

                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,

                  children: [
                    Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 28,
                    ),

                    SizedBox(width: 12),

                    Text(
                      "Send Reset Email",

                      style: TextStyle(
                        fontSize: 24,
                        fontWeight:
                            FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 35),

            /// PRIVACY
            Container(
              padding: EdgeInsets.all(18),

              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(22),

                color: Theme.of(context).colorScheme.surface,

                border: Border.all(
                  color: Theme.of(context).dividerColor,
                ),
              ),

              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),

                    decoration: BoxDecoration(
                      shape: BoxShape.circle,

                      color:
                          const Color(0x336EA6C1),
                    ),

                    child: Icon(
                      Icons.shield_outlined,
                      color:
                          Theme.of(context).colorScheme.primary,
                    ),
                  ),

                  SizedBox(width: 15),

                  Expanded(
                    child: Text(
                      "We’ll never share your email with anyone else.",

                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }
}