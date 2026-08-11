import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'products_screen.dart';
import 'register_screen.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';

///////////////////// 🔐 LOGIN (MODERN CLEAN UI) /////////////////////

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passController = TextEditingController();

  bool isLoading = false;
  bool isGoogleLoading = false;
  bool isPasswordHidden = true;

  /// 🔥 LOGIN WITH EMAIL
  Future<void> login() async {
    if (emailController.text.trim().isEmpty ||
        passController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please Write Your Email & Password")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final credential =
    await FirebaseAuth.instance.signInWithEmailAndPassword(
  email: emailController.text.trim(),
  password: passController.text.trim(),
);

await saveFcmToken();

      if (!mounted) return;

Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ProductsScreen()),
        );
      }
    on FirebaseAuthException catch (e) {
      String message = "حصل خطأ";

      if (e.code == 'user-not-found') {
        message = "الايميل ده مش متسجل";
      } else if (e.code == 'wrong-password') {
        message = "الباسورد غلط";
      } else if (e.code == 'invalid-email') {
        message = "الايميل غير صحيح";
      } else if (e.code == 'user-disabled') {
        message = "الحساب متوقف";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffF5F8FD),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [

              /// 🔥 TOP DESIGN
              Stack(
                children: [

                  Container(
                    height: 260,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xffF8FBFF),
                          Color(0xffEAF3FF),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),

                  Positioned(
                    top: -60,
                    left: -50,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    top: 50,
                    right: -30,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        color: Colors.white.withValues(alpha: .25),
                      ),
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.only(top: 50),
                    child: Center(
                      child: Column(
                        children: [

                          /// 🔥 LOGO
                          Image.asset(
                            "assets/banner.png",
                            height: 120,
                          ),

                          SizedBox(height: 10),

                          Text(
                            "MEDICAL SCRUBS & APPAREL",
                            style: TextStyle(
                              color: Color(0xff1D3557),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              /// 🔥 CARD
              Transform.translate(
                offset: Offset(0, -20),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 22),
                  padding: EdgeInsets.all(22),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: .08),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      /// TITLE
                      Text(
                        "Welcome Back 👋",
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff16355C),
                        ),
                      ),

                      SizedBox(height: 6),

                      Text(
                        "Login to your account",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 17,
                        ),
                      ),

                      SizedBox(height: 30),

                      /// EMAIL
                      Container(
                        decoration: BoxDecoration(
                          color: Color(0xffF7F9FC),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.grey.shade200,
                          ),
                        ),

                        child: TextField(
  controller: emailController,
  keyboardType: TextInputType.emailAddress,

  style: TextStyle(
    color: Color(0xff16355C), // 👈 نفس لون Welcome Back
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.2,
  ),

  textAlignVertical: TextAlignVertical.center,

  decoration: InputDecoration(
    border: InputBorder.none,

    hintText: "Email",

    hintStyle: TextStyle(
      color: Color(0xff16355C),
      fontSize: 17,
    ),

    isCollapsed: true,

    contentPadding: EdgeInsets.symmetric(
      vertical: 22,
      horizontal: 0,
    ),

    prefixIcon: Padding(
      padding: EdgeInsets.all(12),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xffEAF3FF),
        ),

        child: Icon(
          Icons.email,
          color: Color(0xff2D7DFF),
        ),
      ),
    ),
  ),
),
                      ),

                      SizedBox(height: 18),

                      /// PASSWORD
                      Container(
                        decoration: BoxDecoration(
                          color: Color(0xffF7F9FC),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.grey.shade200,
                          ),
                        ),

                        child: TextField(
  controller: passController,
  obscureText: isPasswordHidden,

  style: TextStyle(
    color: Color(0xff16355C),
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.2,
  ),

  textAlignVertical: TextAlignVertical.center,

  decoration: InputDecoration(
    border: InputBorder.none,

    hintText: "Password",

    hintStyle: TextStyle(
      color: Color(0xff16355C),
      fontSize: 17,
    ),

    isCollapsed: true,

    contentPadding: EdgeInsets.symmetric(
      vertical: 22,
      horizontal: 0,
    ),

    prefixIcon: Padding(
      padding: EdgeInsets.all(12),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xffEAF3FF),
        ),

        child: Icon(
          Icons.lock,
          color: Color(0xff2D7DFF),
        ),
      ),
    ),

    suffixIcon: IconButton(
      icon: Icon(
        isPasswordHidden
            ? Icons.visibility
            : Icons.visibility_off,
        color: Colors.grey,
      ),
      onPressed: () {
        setState(() {
          isPasswordHidden = !isPasswordHidden;
        });
      },
    ),
  ),
),
                      ),

                      SizedBox(height: 12),

                      /// FORGOT PASSWORD
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () async {
  if (emailController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("اكتب الايميل الأول"),
      ),
    );
    return;
  }

  final messenger = ScaffoldMessenger.of(context);

  await FirebaseAuth.instance.sendPasswordResetEmail(
    email: emailController.text.trim(),
  );

  if (!mounted) return;

  messenger.showSnackBar(
    const SnackBar(
      content: Text("تم ارسال رابط تغيير الباسورد"),
    ),
  );
},
                          child: Text(
                            "Forgot Password?",
                            style: TextStyle(
                              color: Color(0xff2D7DFF),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 8),

                      /// LOGIN BUTTON
                      isLoading
                          ? Center(
                              child:
                                  CircularProgressIndicator(),
                            )
                          : SizedBox(
                              width: double.infinity,
                              height: 58,

                              child: ElevatedButton(
                                onPressed: login,

                                style:
                                    ElevatedButton.styleFrom(
                                  elevation: 0,

                                  backgroundColor:
                                      Color(0xff1565D8),

                                  shape:
                                      RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(
                                      18,
                                    ),
                                  ),
                                ),

                                child: Text(
                                  "Login",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight:
                                        FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),

                      SizedBox(height: 18),

                      /// REGISTER
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [

                          Text(
                            "Don't have an account?",
                            style: TextStyle(
                              color: Colors.black87,
                            ),
                          ),

                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      RegisterScreen(),
                                ),
                              );
                            },

                            child: Text(
                              "Register",
                              style: TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                                color: Color(0xff1565D8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              /// 🔥 SOCIAL LOGIN
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 28),

                child: Row(
                  children: [

                    Expanded(
                      child: Divider(
                        color: Colors.grey.shade300,
                      ),
                    ),

                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        "Or continue with",
                        style: TextStyle(
                          color: Colors.black54,
                        ),
                      ),
                    ),

                    Expanded(
                      child: Divider(
                        color: Colors.grey.shade300,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 22),

              /// GOOGLE
              Padding(
  padding: EdgeInsets.symmetric(horizontal: 22),

  child: Center(
    child: InkWell(
      borderRadius: BorderRadius.circular(18),

      onTap: isGoogleLoading
    ? null
    : () => signInWithGoogleGlobal(context),

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
          child: isGoogleLoading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    Image.network(
                      "https://cdn-icons-png.flaticon.com/512/2991/2991148.png",
                      height: 24,
                    ),

                    SizedBox(width: 10),

                    Text(
                      "Google",
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
    ),
  ),
),

              SizedBox(height: 40),

              /// 🔥 BOTTOM FEATURES
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),

                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceAround,

                  children: [

                    featureItem(
                      Icons.verified_user_outlined,
                      "Premium Quality",
                    ),

                    featureItem(
                      Icons.local_shipping_outlined,
                      "Fast Shipping",
                    ),

                    featureItem(
                      Icons.support_agent,
                      "24/7 Support",
                    ),
                  ],
                ),
              ),

              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget featureItem(IconData icon, String title) {
    return Column(
      children: [

        Container(
          width: 65,
          height: 65,

          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,

            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
              ),
            ],
          ),

          child: Icon(
            icon,
            color: Color(0xff0B1F51),
            size: 32,
          ),
        ),

        SizedBox(height: 10),

        Text(
          title,
          textAlign: TextAlign.center,

          style: TextStyle(
            fontSize: 13,
            color: Color(0xff0B1F51),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passController.dispose();
    super.dispose();
  }
}