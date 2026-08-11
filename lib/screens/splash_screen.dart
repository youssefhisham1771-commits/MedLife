import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'products_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

///////////////////// 🔥 SPLASH /////////////////////

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
State<SplashScreen> createState() =>
    _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  late AnimationController _mainController;
  late AnimationController _dotsController;

  @override
  void initState() {
    super.initState();

    /// ✨ Logo Animation
    _mainController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1800),
    );

    /// 🔵 Dots Animation
    _dotsController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    )..repeat();

    _mainController.forward();

    /// 🔥 Auth Listener
    FirebaseAuth.instance.authStateChanges().listen((user) {
      Future.delayed(Duration(milliseconds: 3200), () {
        if (!mounted) return;

        if (user == null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => LoginScreen(),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ProductsScreen(),
            ),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  Widget buildDot(int index) {
    return AnimatedBuilder(
      animation: _dotsController,
      builder: (context, child) {

        double value = (_dotsController.value * 3);

        bool active =
            value >= index && value < index + 1;

        return AnimatedContainer(
          duration: Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: 6),

          width: active ? 24 : 10,
          height: 10,

          decoration: BoxDecoration(
            color: active
                ? Color(0xff67B7FF)
                : Color(0xffD6E9FF),

            borderRadius: BorderRadius.circular(20),

            boxShadow: active
                ? [
                    BoxShadow(
                      color: Color(0xff67B7FF)
                          .withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ]
                : [],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [

          /// 🌊 Background ثابتة
Image.asset(
  "assets/splash.png",
  fit: BoxFit.cover,
),

          /// ✨ Premium Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.05),
                  Colors.white.withValues(alpha: 0.12),
                ],
              ),
            ),
          ),

          /// 🔥 Main Content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                SizedBox(height: 300),

                /// 🔵 Premium Dots
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    buildDot(0),
                    buildDot(1),
                    buildDot(2),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}