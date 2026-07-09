import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'notification_service.dart';


final GoogleSignIn googleSignIn = GoogleSignIn.instance;

Future<void> signInWithGoogleGlobal(
  BuildContext context,
) async {
  try {
    // WEB
    if (kIsWeb) {
      GoogleAuthProvider provider = GoogleAuthProvider();

      final userCredential =
          await FirebaseAuth.instance.signInWithPopup(provider);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'name': userCredential.user!.displayName ?? '',
        'phone': userCredential.user!.phoneNumber ?? '',
        'email': userCredential.user!.email ?? '',
        'role': 'user',
      }, SetOptions(merge: true));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProductsScreen(),
        ),
      );

      return;
    }

    // ANDROID / IOS
    await googleSignIn.signOut();
    await FirebaseAuth.instance.signOut();

    final GoogleSignInAccount? googleUser =
        await googleSignIn.authenticate();

    if (googleUser == null) return;

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final userCredential =
        await FirebaseAuth.instance.signInWithCredential(
      credential,
    );

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userCredential.user!.uid)
        .set({
      'name': userCredential.user!.displayName ?? '',
      'phone': userCredential.user!.phoneNumber ?? '',
      'email': userCredential.user!.email ?? '',
      'role': 'user',
    }, SetOptions(merge: true));

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ProductsScreen(),
      ),
    );
  } catch (e) {
    debugPrint("GOOGLE ERROR: $e");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString()),
      ),
    );
  }
}

// ✳️ ايميل الادمن
const String adminEmail = "youssef.hisham1771@gmail.com";

final cloudinary = CloudinaryPublic(
  'dzlorraqi',
  'Medlife',
  cache: false,
);

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
  } catch (e) {
    print("FCM ERROR: $e");
  }
}

void listenForAdminNotifications() {
  FirebaseFirestore.instance
      .collection('notifications')
      .orderBy('createdAt', descending: true)
      .limit(1)
      .snapshots()
      .listen((snapshot) async {
    if (snapshot.docs.isEmpty) return;

    final data = snapshot.docs.first.data();

    final title = data['title'] ?? '';
    final body = data['body'] ?? '';

    await NotificationService.showNotification(
      title,
      body,
    );
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await NotificationService.init();

if (!kIsWeb) {
    await FirebaseMessaging.instance.requestPermission(
  alert: true,
  badge: true,
  sound: true,
);
}

    if (!kIsWeb) {
  await googleSignIn.initialize();
}

await saveFcmToken();

listenForAdminNotifications();

    runApp(MyApp());
  } catch (e, s) {
    debugPrint("MAIN ERROR: $e");
    debugPrint("$s");
  }
}

class MyApp extends StatefulWidget {
  static _MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDark = false;

  @override
void initState() {
  super.initState();

  loadTheme();
  startNotificationsListener();
}

  // 📥 تحميل من الميموري
  void loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDark = prefs.getBool("isDark") ?? false;
    });
  }

  // 💾 حفظ الاختيار
  void toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      isDark = !isDark;
    });

    await prefs.setBool("isDark", isDark);
  }

  void startNotificationsListener() {
  FirebaseFirestore.instance
      .collection('notifications')
      .orderBy('createdAt', descending: true)
      .limit(1)
      .snapshots()
      .listen((snapshot) {

    if (snapshot.docs.isEmpty) return;

    final data = snapshot.docs.first.data();

    NotificationService.showNotification(
      data['title'] ?? '',
      data['body'] ?? '',
    );
  });
}

  @override
  Widget build(BuildContext context) {
   return MaterialApp(
  debugShowCheckedModeBanner: false,

  theme: ThemeData(
    brightness: Brightness.dark,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
    ),
  ),

  darkTheme: ThemeData(
    brightness: Brightness.dark,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
    ),
  ),

  themeMode: ThemeMode.dark,

  home: SplashScreen(),
);
  }
}

///////////////////// 🔥 SPLASH /////////////////////

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  late AnimationController _mainController;
  late AnimationController _dotsController;

late Animation<double> _fadeAnimation;
late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    /// ✨ Logo Animation
    _mainController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1800),
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: Curves.easeIn,
      ),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.85,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: Curves.easeOutBack,
      ),
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
                          .withOpacity(0.5),
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
                  Colors.white.withOpacity(0.05),
                  Colors.white.withOpacity(0.12),
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

///////////////////// 🔐 LOGIN (MODERN CLEAN UI) /////////////////////

class LoginScreen extends StatefulWidget {
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

String? token =
    await FirebaseMessaging.instance.getToken();

    print("TOKEN = $token");

await FirebaseFirestore.instance
    .collection('users')
    .doc(credential.user!.uid)
    .set({
  'fcmToken': token,
}, SetOptions(merge: true));

print("TOKEN SAVED");

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ProductsScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
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
                        color: Colors.white.withOpacity(.25),
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
                        color: Colors.blue.withOpacity(.08),
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
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "اكتب الايميل الأول",
                                  ),
                                ),
                              );
                              return;
                            }

                            await FirebaseAuth.instance
                                .sendPasswordResetEmail(
                              email:
                                  emailController.text.trim(),
                            );

                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              SnackBar(
                                content: Text(
                                  "تم ارسال رابط تغيير الباسورد",
                                ),
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

///////////////////// 🔐 REGISTER SCREEN /////////////////////

class RegisterScreen extends StatefulWidget {
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
        SnackBar(content: Text("املأ كل البيانات")),
      );
      return;
    }

    if (pass.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("الباسورد لازم يكون 8 حروف على الأقل")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      /// 🔐 CREATE ACCOUNT
      final userCred = await FirebaseAuth.instance
    .createUserWithEmailAndPassword(
  email: email.text.trim(),
  password: pass.text.trim(),
);

String? token = await FirebaseMessaging.instance.getToken();

print("FCM TOKEN: $token");

await FirebaseFirestore.instance
    .collection('users')
    .doc(userCred.user!.uid)
    .set({
  'name': name.text.trim(),
  'phone': phone.text.trim(),
  'email': email.text.trim(),
  'role': 'user',
  'fcmToken': token,
});

      /// 🔥 SAVE USER DATA
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCred.user!.uid)
          .set({
        'name': name.text.trim(),
        'phone': phone.text.trim(),
        'email': email.text.trim(),
        'role': 'user',
      });

      await saveFcmToken();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Account Created Successfully 🎉"),
        ),
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ProductsScreen(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
  print("AUTH ERROR: ${e.code}");
  print("AUTH MESSAGE: ${e.message}");

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(e.message ?? e.code)),
  );
}

catch (e, st) {
  print("GENERAL ERROR: $e");
  print(st);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("Register Error ❌")),
  );
}

    if (mounted) {
      setState(() => isLoading = false);
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
                        color: Colors.black.withOpacity(0.05),
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

///////////////////// 🛍 PRODUCTS /////////////////////

class ProductsScreen extends StatefulWidget {
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Map<String, dynamic>> cart = [];
  List<Map<String, dynamic>> favourites = [];

  int currentIndex = 0;

 int salesCount = 0;
 int cartCount = 0;
 bool isAdmin = false;

 bool salesSeen = false;

@override
void initState() {
  super.initState();

if (!kIsWeb){

  FirebaseMessaging.instance.requestPermission();
}

  loadFavourites();
  loadCart();

  checkAdmin();
  loadSalesCount();
}

Future<void> checkAdmin() async {
  var user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  var doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();

  if (doc.exists && doc.data()!['role'] == 'admin') {
    setState(() {
      isAdmin = true;
    });
  }
}

Future<void> loadSalesCount() async {
  var snapshot = await FirebaseFirestore.instance
      .collection('sales')
      .get();

  setState(() {
    salesCount = snapshot.docs.length;
  });
}

Future<void> toggleFavourite(Map<String, dynamic> item) async {
  var user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  var favRef = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('favourites');

  var existing = await favRef
      .where("name", isEqualTo: item['name'])
      .get();

  if (existing.docs.isNotEmpty) {
    // ❌ remove
    await favRef.doc(existing.docs.first.id).delete();

    setState(() {
      favourites.removeWhere((e) => e['name'] == item['name']);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Removed from Favourites ❌")),
    );
  } else {
    // ❤️ add
    await favRef.add(item);

    setState(() {
      favourites.add(item);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Added To Favourite ❤️")),
    );
  }
}

Future<void> loadFavourites() async {
  var user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  var snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('favourites')
      .get();

 setState(() {
  favourites = snapshot.docs.map((doc) {
    var data = doc.data();
    data['docId'] = doc.id; // 🔥 مهم جدًا
    return data;
  }).toList();
});
}

Future<void> removeFromFavourites(int index) async {
  var user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  var favRef = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('favourites');

  var docId = favourites[index]['docId'];

  if (docId != null) {
    await favRef.doc(docId).delete();
  }

  setState(() {
    favourites.removeAt(index);
  });
}

Future<void> loadCart() async {
  var user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  var snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('cart')
      .get();

  setState(() {
    cart = snapshot.docs.map((doc) => doc.data()).toList();
  });
}

Widget buildProducts() {
  return StreamBuilder(
    stream: FirebaseFirestore.instance.collection('Products').snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return Center(child: CircularProgressIndicator());
      }

      var products = snapshot.data!.docs;

return Column(
  children: [

    /// 🔥 البانر فوق
    BannerSlider(isAdmin: isAdmin),

/// 🔥 OUR PRODUCTS
Padding(
  padding: const EdgeInsets.symmetric(
    vertical: 18,
    horizontal: 20,
  ),

  child: Builder(
    builder: (context) {

      final bool isDark =
          Theme.of(context).brightness ==
              Brightness.dark;

      final Color textColor =
          isDark
              ? Colors.white
              : const Color(0xFF1D1B20);

      final Color lineColor =
          isDark
              ? const Color(0xFF6EA6C1)
              : const Color(0xFF5B8DA8);

      return Row(
        children: [

          /// LEFT LINE
          Expanded(
            child: Container(
              height: 2,

              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    lineColor.withOpacity(.9),
                  ],

                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),

          const SizedBox(width: 14),

          /// TEXT
          Text(
            "Our Products",

            style: GoogleFonts.poppins(
              color: textColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),

          const SizedBox(width: 14),

          /// RIGHT LINE
          Expanded(
            child: Container(
              height: 2,

              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    lineColor.withOpacity(.9),
                    Colors.transparent,
                  ],

                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
        ],
      );
    },
  ),
),

    /// 🔥 المنتجات تحت
    Expanded(
      child: GridView.builder(
        padding: EdgeInsets.all(10),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio:
    MediaQuery.of(context).size.width < 400
        ? 0.54
        : 0.60,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          var product = products[index];
          var data = product.data() as Map<String, dynamic>;

          List images = data.containsKey('images')
              ? data['images']
              : [data['image']];

          bool isFav =
              favourites.any((e) => e['name'] == data['name']);

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductDetailsScreen(
                    product: product,
                    cart: cart,

                    onAddToCart: () {
                      setState(() {});
                    },
                  ),
                ),
              );
            },
            child: Stack(
              children: [
                Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(28),

    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF111827),
        Color(0xFF0B1220),
        Color(0xFF091428),
      ],
    ),

    border: Border.all(
      color: Color(0xFF1F2A44),
      width: 1,
    ),

    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(.35),
        blurRadius: 20,
        offset: Offset(0, 10),
      ),
    ],
  ),

  child: Column(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [

      /// 🔥 IMAGE
      AspectRatio(
  aspectRatio: 0.8,
        child: Stack(
          children: [

            ClipRRect(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(28),
              ),

              child: Image.network(
                images.isNotEmpty ? images[0] : "",
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),

            /// ❤️ Favourite
            Positioned(
              top: 12,
              left: 12,
              child: GestureDetector(
                onTap: () {

                  var item = {
                    "name": data['name'],
                    "price": data['price'],
                    "image": images.isNotEmpty
                        ? images[0]
                        : "",
                  };

                  toggleFavourite(item);
                },

                child: Container(
                  width: 46,
                  height: 46,

                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(.45),
                    border: Border.all(
                      color: Colors.white10,
                    ),
                  ),

                  child: Icon(
                    isFav
                        ? Icons.favorite
                        : Icons.favorite_border,

                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),

            /// 🔥 NEW BADGE
            if (data['createdAt'] != null &&
                DateTime.now()
                        .difference(
                          (data['createdAt'] as Timestamp)
                              .toDate(),
                        )
                        .inDays <
                    7)

              Positioned(
                left: 12,
                bottom: 12,

                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),

                  decoration: BoxDecoration(
                    color: Color(0xFF6EA6C1),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),

                  child: Text(
                    "NEW",

                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            /// 🔥 MENU BUTTON
            if (isAdmin)
              Positioned(
                top: 12,
                right: 12,

                child: PopupMenuButton<String>(
                  color: Color(0xFF111827),

                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(18),
                  ),

                  onSelected: (value) async {

                    if (value == "edit") {

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AddEditProductScreen(
                            docId: product.id,
                            oldData: data,
                          ),
                        ),
                      );
                    }

                    if (value == "delete") {

                      await FirebaseFirestore.instance
                          .collection('Products')
                          .doc(product.id)
                          .delete();
                    }
                  },

                  itemBuilder: (context) => [

                    PopupMenuItem(
                      value: "edit",

                      child: Row(
                        children: [

                          Icon(
                            Icons.edit,
                            color: Color(0xFF6EA6C1),
                          ),

                          SizedBox(width: 10),

                          Text(
                            "Edit",
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    PopupMenuItem(
                      value: "delete",

                      child: Row(
                        children: [

                          Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),

                          SizedBox(width: 10),

                          Text(
                            "Delete",
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  child: Container(
                    width: 46,
                    height: 46,

                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(.45),
                      border: Border.all(
                        color: Colors.white10,
                      ),
                    ),

                    child: Icon(
                      Icons.more_vert,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),

      /// 🔥 NAME + PRICE
        Padding(
          padding: const EdgeInsets.only(
            top: 18,
            left: 8,
            right: 8,
            bottom: 8,
          ),

          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [

              Text(
  data['name'],
  textAlign: TextAlign.center,
  maxLines: 2,
  overflow: TextOverflow.ellipsis,

  style: TextStyle(
    color: Colors.white,
    fontSize: 16,
    fontWeight: FontWeight.bold,
  ),
),

              SizedBox(height: 0.4),

              Text(
                "${data['price']} EGP",

                textAlign: TextAlign.center,

                style: TextStyle(
                  color: Color(0xFF6EA6C1),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

Spacer(),

      /// 🔥 ADD TO CART BUTTON
      Padding(
        padding: const EdgeInsets.only(
          left: 14,
          right: 14,
          bottom: 5,
          top: 1,
        ),

        child: InkWell(
          borderRadius: BorderRadius.circular(20),

          onTap: () {

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ProductDetailsScreen(
        product: product,
        cart: cart,
        onAddToCart: () {
          setState(() {});
        },
      ),
    ),
  );

},

          child: Container(
            width: double.infinity,
            height: 40,

            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(20),

              color: Colors.white.withOpacity(.06),

              border: Border.all(
                color: Colors.white10,
              ),
            ),

            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,

              children: [

                Icon(
                  Icons.shopping_cart_outlined,
                  color: Color(0xFF6EA6C1),
                ),

                SizedBox(width: 5),

                Text(
                  "Add to Cart",

                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  ),
)
              ],
            ),
          );
        },
      ),
    ),
  ],
);
    },
  );
}

Widget buildFavourites() {
  if (favourites.isEmpty) {
    return Center(
      child: Text(
        "No Favourites Yet ❤️",
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
        ),
      ),
    );
  }

  return SingleChildScrollView(
    padding: EdgeInsets.all(16),
    child: Column(
      children: [

        /// HEADER fav
        Container(
          padding: EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white10),
            gradient: LinearGradient(
              colors: [
                Color(0xFF0E1220),
                Color(0xFF151A29),
              ],
            ),
          ),
          child: Row(
            children: [

              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF1B2233),
                  border: Border.all(
                    color: Color(0xFF6EA6C1),
                  ),
                ),
                child: Icon(
                  Icons.favorite,
                  color: Color(0xFF6EA6C1),
                  size: 30,
                ),
              ),

              SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [

                    Text(
                      "My Favourites",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    SizedBox(height: 6),

                    Text(
                      "${favourites.length} items saved",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),

                    SizedBox(height: 4),

                    Text(
                      "Items you love, all in one place.",
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 25),

        /// GRID
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: favourites.length,
          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio:
    MediaQuery.of(context).size.width < 400
        ? 0.54
        : 0.60,
crossAxisSpacing: 10,
mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {

            var item = favourites[index];

            return buildFavouriteCard(
              item,
              index,
            );
          },
        ),

        SizedBox(height: 25),

        /// FEATURES
        Container(
          padding: EdgeInsets.symmetric(
            vertical: 20,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceEvenly,
            children: [

              buildFeature(
                Icons.workspace_premium_outlined,
                "Premium Quality",
                "Comfort & quality",
              ),

              buildFeature(
                Icons.assignment_return_outlined,
                "Easy Returns",
                "14-day return",
              ),

              buildFeature(
                Icons.headset_mic_outlined,
                "Support",
                "24/7 Help",
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget buildFavouriteCard(
  Map item,
  int index,
) {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF111827),
          Color(0xFF0B1220),
          Color(0xFF091428),
        ],
      ),
      border: Border.all(
        color: Color(0xFF1F2A44),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(.35),
          blurRadius: 20,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [

        /// IMAGE
        AspectRatio(
          aspectRatio: 0.8,
          child: Stack(
            children: [

              ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                child: Image.network(
                  item["image"],
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),

              /// ❤️ REMOVE FROM FAVOURITES
              Positioned(
                top: 12,
                left: 12,
                child: GestureDetector(
                  onTap: () {
                    removeFromFavourites(index);
                  },
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(.45),
                      border: Border.all(
                        color: Colors.white10,
                      ),
                    ),
                    child: Icon(
                      Icons.favorite,
                      color: Colors.red,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        /// NAME + PRICE
        Padding(
          padding: const EdgeInsets.only(
            top: 15,
            left: 8,
            right: 8,
            bottom: 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              Text(
                item["name"],
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 4),

              Text(
                "${item["price"]} EGP",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF6EA6C1),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        Spacer(),

        /// ADD TO CART BUTTON
        Padding(
          padding: const EdgeInsets.only(
            left: 14,
            right: 14,
            bottom: 2,
            top: 0,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              /// add to cart
            },
            child: Container(
              width: double.infinity,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white.withOpacity(.06),
                border: Border.all(
                  color: Colors.white10,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  Icon(
                    Icons.shopping_cart_outlined,
                    color: Color(0xFF6EA6C1),
                  ),

                  SizedBox(width: 5),

                  Text(
                    "Add to Cart",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget buildFeature(
  IconData icon,
  String title,
  String subtitle,
) {
  return Expanded(
    child: Column(
      children: [

        CircleAvatar(
          radius: 28,
          backgroundColor:
              Color(0xFF1A2233),
          child: Icon(
            icon,
            color: Color(0xFF6EA6C1),
          ),
        ),

        SizedBox(height: 10),

        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),

        SizedBox(height: 4),

        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white60,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}

Widget buildBadge({
  required IconData icon,
  required int count,
}) {
  return Stack(
    clipBehavior: Clip.none,
    children: [
      Icon(icon, size: 28),

      if (count > 0)
        Positioned(
          right: -6,
          top: -6,
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
    ],
  );
}

  @override
  Widget build(BuildContext context) {
    var user = FirebaseAuth.instance.currentUser;



int favCount = favourites.length;
    
return Scaffold(
  appBar: AppBar(
  centerTitle: false,
  backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
  iconTheme: IconThemeData(
    color: Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black,
  ),
  title: currentIndex == 0

    /// 🔥 MEDLIFE LOGO
    ? RichText(
        text: TextSpan(
          children: [

            TextSpan(
              text: "Med",

              style: GoogleFonts.poppins(
                color: Color(0xFF35C2F1),
                fontSize: 21,
                fontWeight: FontWeight.w900,

                letterSpacing: 0.5,

                shadows: [
                  Shadow(
                    color: Colors.black54,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
            ),

            TextSpan(
              text: "Life",

              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w900,

                letterSpacing: 0.5,

                shadows: [
                  Shadow(
                    color: Colors.black54,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
            ),
          ],
        ),
      )

    /// 🔥 باقي الصفحات
    : Text(
        currentIndex == 1
            ? "Cart"
            : currentIndex == 2
                ? "Favourites"
                : "My Orders",

        style: GoogleFonts.poppins(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
  actions: [
    /* Padding(
  padding: const EdgeInsets.symmetric(horizontal: 6),
  child: GestureDetector(
    onTap: () {
      MyApp.of(context)!.toggleTheme();
    },
    child: AnimatedContainer(
      duration: Duration(milliseconds: 250),
      width: 50,
      height: 25,
      padding: EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),

        // 🔥 الخلفية الرمادي الثابتة
        color: Colors.grey.shade400,

        border: Border.all(
          color: Colors.grey.shade500,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MyApp.of(context)!.isDark
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,

              // 🔥 لون الدائرة نفسها
              color: MyApp.of(context)!.isDark
                  ? Colors.black
                  : Colors.white,

              boxShadow: [
                BoxShadow(
                  blurRadius: 4,
                  color: Colors.black12,
                ),
              ],
            ),
            child: Icon(
              MyApp.of(context)!.isDark
                  ? Icons.nightlight_round
                  : Icons.wb_sunny,
              size: 15,
              color: MyApp.of(context)!.isDark
                  ? Colors.white
                  : Colors.black,
            ),
          ),
        ],
      ),
    ),
  ),
),
*/

/// 🔥 SALES
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 4),
  child: GestureDetector(
    onTap: () async {

      /// 👁️ المستخدم شاف العروض
      setState(() {
        salesSeen = true;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SalesScreen(
            isAdmin: isAdmin,
          ),
        ),
      );
    },

    child: Stack(
      clipBehavior: Clip.none,
      children: [

        /// 🔥 ICON
       Container(
  padding: EdgeInsets.all(8),
  child: Icon(
    Icons.percent,
    color:
        Theme.of(context).brightness ==
                Brightness.dark
            ? Colors.white
            : Colors.black,
    size: 28,
  ),
),

        /// 🔴 BADGE
        if (!salesSeen && salesCount > 0)
          Positioned(
            right: -5,
            top: -5,
            child: Container(
              padding: EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                salesCount.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    ),
  ),
),

if (isAdmin)
  IconButton(
    icon: Icon(Icons.insert_chart_outlined_rounded),
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AdminOrdersScreen()),
      );
    },
  ),
  // 👤 Profile
  IconButton(
    icon: Icon(Icons.person),
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProfileScreen()),
      );
    },
  ),
IconButton(
  icon: Icon(Icons.menu),
  onPressed: () {
    showGeneralDialog(
      context: context,
      barrierLabel: "Menu",
      barrierDismissible: true,
      transitionDuration: Duration(milliseconds: 500), // 🔥 أسرع + Bounce
      pageBuilder: (_, __, ___) {
        return Align(
          alignment: Alignment.centerRight,
          child: CustomDrawer(),
        );
      },
      transitionBuilder: (_, anim, __, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutBack, // 🔥 Bounce effect
        );

        return SlideTransition(
          position: Tween(
            begin: Offset(1, 0),
            end: Offset(0, 0),
          ).animate(curved),
          child: child,
        );
      },
    );
  },
),
],
  ),

 body: currentIndex == 0
    ? buildProducts()
    : currentIndex == 1
        ? CartScreen(cart: cart)
        : currentIndex == 2
            ? buildFavourites()
            : MyOrdersScreen(),

floatingActionButton: isAdmin
    ? Container(
        width: 50,
        height: 50,

        decoration: BoxDecoration(
          shape: BoxShape.circle,

          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF59C7FF),
              Color(0xFF6EA6C1),
            ],
          ),
        ),

        child: FloatingActionButton(
          heroTag: "addProduct",

          elevation: 0,

          backgroundColor: Colors.transparent,

          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddEditProductScreen(),
              ),
            );
          },

          child: const Icon(
            Icons.add,
            size: 25,
            color: Colors.white,
          ),
        ),
      )
    : null,

    floatingActionButtonLocation:
    FloatingActionButtonLocation.endFloat,

bottomNavigationBar: Container(
  margin: const EdgeInsets.only(
    left: 4,
    right: 4,
  ),

  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(20),

    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF111827),
        Color(0xFF0B1220),
        Color(0xFF091428),
      ],
    ),

    border: Border.all(
      color: Colors.white10,
      width: 1,
    ),

    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(.35),
        blurRadius: 25,
        spreadRadius: 2,
        offset: const Offset(0, 10),
      ),
    ],
  ),

  child: ClipRRect(
    borderRadius: BorderRadius.circular(30),

    child: BottomNavigationBar(
      currentIndex: currentIndex,

      backgroundColor: Colors.transparent,

      elevation: 0,

      type: BottomNavigationBarType.fixed,

      selectedItemColor: Colors.white,

      unselectedItemColor: Colors.white70,

      showUnselectedLabels: true,

      selectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),

      unselectedLabelStyle: const TextStyle(
        fontSize: 12,
      ),

      onTap: (i) {
        setState(() {
          currentIndex = i;
        });
      },

      items: [

        /// 🏬 PRODUCTS
        BottomNavigationBarItem(
          label: "Products",

          icon: AnimatedContainer(
            duration: const Duration(milliseconds: 300),

            padding: EdgeInsets.symmetric(
              horizontal: currentIndex == 0 ? 14 : 0,
              vertical: 6,
            ),

            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),

              gradient: currentIndex == 0
                  ? const LinearGradient(
                      colors: [
                        Color(0xFF59C7FF),
                        Color(0xFF6EA6C1),
                      ],
                    )
                  : null,

              boxShadow: currentIndex == 0
                  ? [
                      BoxShadow(
                        color: const Color(0xFF59C7FF)
                            .withOpacity(.35),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : [],
            ),

            child: Icon(
              Icons.store,
              color: currentIndex == 0
                  ? Colors.white
                  : Colors.white70,
            ),
          ),
        ),

        /// 🛒 CART
        BottomNavigationBarItem(
          label: "Cart",

          icon: AnimatedContainer(
            duration: const Duration(milliseconds: 300),

            padding: EdgeInsets.symmetric(
              horizontal: currentIndex == 1 ? 14 : 0,
              vertical: 6,
            ),

            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),

              gradient: currentIndex == 1
                  ? const LinearGradient(
                      colors: [
                        Color(0xFF59C7FF),
                        Color(0xFF6EA6C1),
                      ],
                    )
                  : null,

              boxShadow: currentIndex == 1
                  ? [
                      BoxShadow(
                        color: const Color(0xFF59C7FF)
                            .withOpacity(.35),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : [],
            ),

            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .collection('cart')
                  .snapshots(),

              builder: (context, snapshot) {

                int count =
                    snapshot.data?.docs.length ?? 0;

                return buildBadge(
                  icon: Icons.shopping_cart,
                  count: count,
                );
              },
            ),
          ),
        ),

        /// ❤️ FAVOURITES
        BottomNavigationBarItem(
          label: "Favourites",

          icon: AnimatedContainer(
            duration: const Duration(milliseconds: 300),

            padding: EdgeInsets.symmetric(
              horizontal: currentIndex == 2 ? 14 : 0,
              vertical: 6,
            ),

            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),

              gradient: currentIndex == 2
                  ? const LinearGradient(
                      colors: [
                        Color(0xFF59C7FF),
                        Color(0xFF6EA6C1),
                      ],
                    )
                  : null,

              boxShadow: currentIndex == 2
                  ? [
                      BoxShadow(
                        color: const Color(0xFF59C7FF)
                            .withOpacity(.35),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : [],
            ),

            child: buildBadge(
              icon: Icons.favorite,
              count: favCount,
            ),
          ),
        ),

        /// 📦 ORDERS
        BottomNavigationBarItem(
          label: "My Orders",

          icon: AnimatedContainer(
            duration: const Duration(milliseconds: 300),

            padding: EdgeInsets.symmetric(
              horizontal: currentIndex == 3 ? 14 : 0,
              vertical: 6,
            ),

            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),

              gradient: currentIndex == 3
                  ? const LinearGradient(
                      colors: [
                        Color(0xFF59C7FF),
                        Color(0xFF6EA6C1),
                      ],
                    )
                  : null,

              boxShadow: currentIndex == 3
                  ? [
                      BoxShadow(
                        color: const Color(0xFF59C7FF)
                            .withOpacity(.35),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : [],
            ),

            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where(
                    'userId',
                    isEqualTo:
                        FirebaseAuth.instance.currentUser?.uid,
                  )
                  .snapshots(),

              builder: (context, snapshot) {

                int count =
                    snapshot.data?.docs.length ?? 0;

                return buildBadge(
                  icon: Icons.shopping_bag,
                  count: count,
                );
              },
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

class SalesScreen extends StatelessWidget {
  final bool isAdmin;

  SalesScreen({required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final bool isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark
              ? const Color(0xFF07070A)
              : const Color(0xFFF5F5F7),

      appBar: AppBar(
        backgroundColor:
            isDark
                ? const Color(0xFF07070A)
                : const Color(0xFFF5F5F7),

        elevation: 0,

        title: Text(
          "Sales",

          style: TextStyle(
            color:
                isDark
                    ? Colors.white
                    : Colors.black,

            fontWeight: FontWeight.bold,
            fontSize: 30,
          ),
        ),

        iconTheme: IconThemeData(
          color:
              isDark
                  ? Colors.white
                  : Colors.black,
        ),

        actions: [
          IconButton(
            onPressed: () {},

            icon: const Icon(
              Icons.search,
              size: 28,
            ),
          ),

          IconButton(
            onPressed: () {},

            icon: const Icon(
              Icons.tune,
              size: 28,
            ),
          ),

          const SizedBox(width: 6),
        ],
      ),

      floatingActionButton:
          isAdmin
              ? Container(
                width: 64,
                height: 64,

                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(28),

                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF3B82F6),
                      Color(0xFF7CC7FF),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),

                  boxShadow: [
                    BoxShadow(
                      color: const Color(
                        0xFF3B82F6,
                      ).withOpacity(0.35),

                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),

                child: FloatingActionButton(
                  backgroundColor:
                      Colors.transparent,

                  elevation: 0,

                  onPressed: () {
                    Navigator.push(
                      context,

                      MaterialPageRoute(
                        builder:
                            (_) => AddSaleScreen(),
                      ),
                    );
                  },

                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              )
              : null,

      body: StreamBuilder(
        stream:
            FirebaseFirestore.instance
                .collection('sales')
                .orderBy(
                  'createdAt',
                  descending: true,
                )
                .snapshots(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          var sales = snapshot.data!.docs;

if (!isAdmin) {
  sales = sales.where((doc) {

    final sale =
        doc.data() as Map<String, dynamic>;

    if (sale['expiryDate'] == null) {
      return true;
    }

    final expiryDate =
        (sale['expiryDate'] as Timestamp)
            .toDate();

    return expiryDate.isAfter(
      DateTime.now(),
    );

  }).toList();
}

          if (sales.isEmpty) {
            return Center(
              child: Text(
                "No Sales Yet",

                style: TextStyle(
                  color:
                      isDark
                          ? Colors.white
                          : Colors.black,
                ),
              ),
            );
          }

          int totalSales = sales.length;

          double avgDiscount =
              sales.fold<double>(
                0.0,
                (sum, item) =>
                    sum +
                    (((item.data()
                                        as Map<
                                          String,
                                          dynamic
                                        >)['discount'] ??
                                    0)
                                as num)
                            .toDouble(),
              ) /
              sales.length;

              double totalDiscountValue =
    sales.fold<double>(
      0.0,
      (sum, item) {
        var sale = item.data() as Map<String, dynamic>;

        double price =
            ((sale['price'] ?? 0) as num).toDouble();

        double discount =
            ((sale['discount'] ?? 0) as num).toDouble();

        return sum + (price * discount / 100);
      },
    );

    int activeSales =
    sales.where((saleDoc) {

  final data =
      saleDoc.data()
          as Map<String, dynamic>;

  final expiry =
      (data['expiryDate']
              as Timestamp)
          .toDate();

  return expiry.isAfter(
      DateTime.now());

}).length;

          return ListView(
            padding:
                const EdgeInsets.all(18),

            children: [
              /// STATS
              Container(
                padding:
                    const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 22,
                    ),

                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(22),

                  gradient:
                      isDark
                          ? const LinearGradient(
                            colors: [
                              Color(0xFF15111A),
                              Color(0xFF100C14),
                            ],
                            begin:
                                Alignment.topLeft,
                            end: Alignment
                                .bottomRight,
                          )
                          : null,

                  color:
                      isDark
                          ? null
                          : Colors.white,

                  border: Border.all(
                    color: Colors.white
                        .withOpacity(0.05),
                  ),
                ),

                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceAround,

                  children: [
                    statItem(
                      Icons.local_offer_outlined,
                      "Total Sales",
                      "$totalSales",
                    ),

                    divider(),

                    statItem(
                      Icons
                          .shopping_bag_outlined,
                      "Active Sales",
                      "$activeSales",
                    ),

                    divider(),

                    statItem(
                      Icons.percent,
                      "Avg. Discount",
                      "${avgDiscount.toInt()}%",
                    ),

                    divider(),

                    statItem(
  Icons.attach_money,
  "Total Discount",
  "${totalDiscountValue.toStringAsFixed(0)} EGP",
),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              /// SALES LIST
              ...List.generate(
                sales.length,
                (index) {
                  var sale =
                      sales[index].data()
                          as Map<
                            String,
                            dynamic
                          >;

                          DateTime expiryDate =
    (sale['expiryDate'] as Timestamp).toDate();

bool isExpired =
    expiryDate.isBefore(DateTime.now());

                  return Container(
                    height: 170,

                    margin:
                        const EdgeInsets.only(
                          bottom: 18,
                        ),

                    padding:
                        const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),

                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(
                            30,
                          ),

                      gradient:
                          isDark
                              ? const LinearGradient(
                                colors: [
                                  Color(
                                    0xFF15121A,
                                  ),
                                  Color(
                                    0xFF0E0C12,
                                  ),
                                ],
                                begin:
                                    Alignment
                                        .topLeft,
                                end: Alignment
                                    .bottomRight,
                              )
                              : null,

                      color:
                          isDark
                              ? null
                              : Colors.white,

                      border: Border.all(
                        color: Colors.white
                            .withOpacity(
                              0.05,
                            ),
                      ),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withOpacity(
                                0.28,
                              ),

                          blurRadius: 18,

                          offset:
                              const Offset(
                                0,
                                8,
                              ),
                        ),
                      ],
                    ),

                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .center,

                      children: [
                        /// IMAGE
                        Container(
                          width: 102,
                          height: 102,

                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(
                                  28,
                                ),

                            gradient:
                                LinearGradient(
                                  colors: [
                                    Colors.white
                                        .withOpacity(
                                          0.06,
                                        ),

                                    Colors.white
                                        .withOpacity(
                                          0.02,
                                        ),
                                  ],

                                  begin:
                                      Alignment
                                          .topLeft,

                                  end: Alignment
                                      .bottomRight,
                                ),
                          ),

                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(
                                  24,
                                ),

                            child:
                                sale['image'] !=
                                            null &&
                                        sale['image']
                                            .toString()
                                            .isNotEmpty
                                    ? Image.network(
                                      sale['image'],

                                      fit:
                                          BoxFit
                                              .cover,
                                    )
                                    : const Icon(
                                      Icons.image,
                                      color:
                                          Colors
                                              .white54,

                                      size: 38,
                                    ),
                          ),
                        ),

                        const SizedBox(
                          width: 16,
                        ),

                        /// INFO
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                            mainAxisAlignment:
                                MainAxisAlignment
                                    .center,

                            children: [
                              /// TITLE
                              Text(
                                sale['title'] ??
                                    "",

                                maxLines: 1,

                                overflow:
                                    TextOverflow
                                        .ellipsis,

                                style: TextStyle(
                                  color:
                                      isDark
                                          ? Colors
                                              .white
                                          : Colors
                                              .black,

                                  fontSize: 18,

                                  fontWeight:
                                      FontWeight
                                          .w700,
                                ),
                              ),

                              const SizedBox(
                                height: 8,
                              ),

                              /// DETAILS
                              Text(
                                sale['details'] ??
                                    "",

                                maxLines: 1,

                                overflow:
                                    TextOverflow
                                        .ellipsis,

                                style: TextStyle(
                                  color:
                                      isDark
                                          ? Colors
                                              .white70
                                          : Colors
                                              .black54,

                                  fontSize: 14,
                                ),
                              ),

                              const SizedBox(
                                height: 14,
                              ),

                              /// DISCOUNT
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                      horizontal:
                                          16,
                                      vertical:
                                          10,
                                    ),

                                decoration:
                                    BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(
                                            18,
                                          ),

                                      border:
                                          Border.all(
                                            color: const Color(
                                              0xFF2F5BFF,
                                            ).withOpacity(
                                              0.25,
                                            ),
                                          ),

                                      color: Colors
                                          .black
                                          .withOpacity(
                                            0.18,
                                          ),
                                    ),

                                child: Row(
                                  mainAxisSize:
                                      MainAxisSize
                                          .min,

                                  children: [
                                    const Icon(
                                      Icons
                                          .local_offer_outlined,

                                      color: Color(
                                        0xFF4A8DFF,
                                      ),

                                      size: 18,
                                    ),

                                    const SizedBox(
                                      width: 8,
                                    ),

                                    Text(
                                      "${sale['discount']}% OFF",

                                      style:
                                          const TextStyle(
                                            color:
                                                Color(
                                                  0xFF4A8DFF,
                                                ),

                                            fontSize:
                                                16,

                                            fontWeight:
                                                FontWeight
                                                    .bold,
                                          ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(
                                height: 14,
                              ),

                              /// DATE + STATUS
                              Row(
                                children: [
                                  const Icon(
                                    Icons
                                        .calendar_today_outlined,

                                    color:
                                        Colors
                                            .white70,

                                    size: 15,
                                  ),

                                  const SizedBox(
                                    width: 5,
                                  ),

                                  Text(
  sale['expiryDate'] != null
      ? DateFormat(
          'dd MMM yyyy',
        ).format(
          (sale['expiryDate'] as Timestamp)
              .toDate(),
        )
      : "No Expiry Date",
  style: TextStyle(
    color: isDark
        ? Colors.white70
        : Colors.black54,
    fontSize: 12,
  ),
),

                                  const SizedBox(
                                    width: 16,
                                  ),

                                  Container(
  width: 7,
  height: 7,
  decoration: BoxDecoration(
    color: isExpired
        ? Colors.red
        : const Color(0xFF6DFF4D),
    shape: BoxShape.circle,
  ),
),

                                  const SizedBox(
                                    width: 5,
                                  ),

                                  Text(
  isExpired ? "Expired" : "Active",
  style: TextStyle(
    color: isExpired
        ? Colors.red
        : const Color(0xFF6DFF4D),
    fontSize: 13,
    fontWeight: FontWeight.w600,
  ),
),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(
                          width: 14,
                        ),

                        /// BUTTONS
                        Column(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .center,

                          children: [
                            buildActionButton(
                              icon: Icons
                                  .arrow_forward_ios,

                              color: const Color(
                                0xFF4A8DFF,
                              ),

                              onTap:
                                  () async {
                                var product =
                                    await FirebaseFirestore
                                        .instance
                                        .collection(
                                          'Products',
                                        )
                                        .doc(
                                          sale['productId'],
                                        )
                                        .get();

                                if (product
                                    .exists) {
                                  Navigator.push(
                                    context,

                                    MaterialPageRoute(
                                      builder:
                                          (_) =>
                                              ProductDetailsScreen(
                                                product:
                                                    product,

                                                cart:
                                                    [],

                                                onAddToCart:
                                                    () {},
                                              ),
                                    ),
                                  );
                                }
                              },
                            ),

                            if (isAdmin) ...[
                              const SizedBox(
                                height: 10,
                              ),

                              buildActionButton(
                                icon: Icons
                                    .edit_outlined,

                                color:
                                    const Color(
                                      0xFF4A8DFF,
                                    ),

                                onTap: () {
                                  Navigator.push(
                                    context,

                                    MaterialPageRoute(
                                      builder:
                                          (_) =>
                                              EditSaleScreen(
                                                saleId:
                                                    sales[index]
                                                        .id,

                                                saleData:
                                                    sale,
                                              ),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(
                                height: 10,
                              ),

                              buildActionButton(
                                icon: Icons
                                    .delete_outline,

                                color:
                                    Colors
                                        .redAccent,

                                onTap:
                                    () async {
                                  await FirebaseFirestore
                                      .instance
                                      .collection(
                                        'sales',
                                      )
                                      .doc(
                                        sales[index]
                                            .id,
                                      )
                                      .delete();

                                  ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Sale Deleted",
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget buildActionButton({
  required IconData icon,
  required Color color,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,

    child: Container(
      width: 40,
      height: 40,

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),

        color: const Color(0xFF1F1B27),

        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
      ),

      child: Icon(
        icon,
        color: color,
        size: 17,
      ),
    ),
  );
}

  Widget divider() {
    return Container(
      width: 1,
      height: 70,

      color: Colors.white.withOpacity(
        0.08,
      ),
    );
  }

  Widget statItem(
    IconData icon,
    String title,
    String value,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,

      children: [
        Icon(
          icon,
          color: const Color(0xFF3B82F6),
          size: 34,
        ),

        const SizedBox(height: 3),

        Text(
          title,

          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
          ),
        ),

        const SizedBox(height: 2),

        Text(
          value,

          style: const TextStyle(
            color: Color(0xFF3B82F6),

            fontSize: 16,

            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

///////////////////// 🔥 ADD SALE SCREEN /////////////////////

class AddSaleScreen extends StatefulWidget {
  @override
  State<AddSaleScreen> createState() => _AddSaleScreenState();
}

class _AddSaleScreenState extends State<AddSaleScreen> {

  final titleController = TextEditingController();
  final detailsController = TextEditingController();
  final discountController = TextEditingController();

  DateTime? expiryDate;

  bool isLoading = false;

  File? saleImageFile;
  String? uploadedImageUrl;
  String? selectedProductId;
  String? selectedProductName;
  double? selectedProductPrice;

  /// 📸 PICK IMAGE
  Future<void> pickImage() async {

    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked != null) {

      setState(() {
        saleImageFile = File(picked.path);
      });

      /// ☁️ Upload To Cloudinary
      try {

        CloudinaryResponse response =
            await cloudinary.uploadFile(

          CloudinaryFile.fromFile(
            saleImageFile!.path,
            resourceType: CloudinaryResourceType.Image,
          ),
        );

        uploadedImageUrl = response.secureUrl;

      } catch (e) {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Image Upload Failed ❌"),
          ),
        );
      }
    }
  }

  /// 📅 PICK DATE
  Future<void> pickDate() async {

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (picked != null) {

      setState(() {
        expiryDate = picked;
      });
    }
  }

  /// 🔥 ADD SALE
  Future<void> addSale() async {

    if (
        selectedProductId == null ||
        selectedProductPrice == null ||
        uploadedImageUrl == null ||
        titleController.text.trim().isEmpty ||
        detailsController.text.trim().isEmpty ||
        discountController.text.trim().isEmpty ||
        expiryDate == null
    ) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Complete all fields"),
        ),
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {

      await FirebaseFirestore.instance
          .collection('sales')
          .add({
        "image": uploadedImageUrl,

        "productId": selectedProductId,

"productName": selectedProductName,

'price': selectedProductPrice,

        "title": titleController.text.trim(),

        "details": detailsController.text.trim(),

        "discount":
            int.parse(discountController.text.trim()),

        "expiryDate": Timestamp.fromDate(expiryDate!),

        "createdAt": Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Sale Added 🔥"),
        ),
      );

      Navigator.pop(context);

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error ❌"),
        ),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: Text("Add Sale 🔥"),
      ),

      body: SingleChildScrollView(

        padding: EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 📸 IMAGE
            Text(
              "Sale Image",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 12),

            GestureDetector(

              onTap: pickImage,

              child: Container(

                height: 200,
                width: double.infinity,

                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.grey.shade400,
                  ),
                ),

                child: saleImageFile == null

                    ? Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [

                          Icon(
                            Icons.add_photo_alternate,
                            size: 50,
                            color: Colors.grey,
                          ),

                          SizedBox(height: 10),

                          Text(
                            "Choose Sale Image",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      )

                    : ClipRRect(
                        borderRadius:
                            BorderRadius.circular(20),

                        child: Image.file(
                          saleImageFile!,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
            ),

            SizedBox(height: 25),

            /// 🛍 SELECT PRODUCT
Text(
  "Choose Product",
  style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  ),
),

SizedBox(height: 12),

StreamBuilder(
  stream: FirebaseFirestore.instance
      .collection('Products')
      .snapshots(),

  builder: (context, snapshot) {

    if (!snapshot.hasData) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    var products = snapshot.data!.docs;

    return DropdownButtonFormField(

      value: selectedProductId,

      items: products.map((product) {

        var data =
            product.data() as Map<String, dynamic>;

        return DropdownMenuItem(

          value: product.id,

          child: Text(
            data['name'] ?? "",
          ),
        );

      }).toList(),

      onChanged: (value) {

        var selected = products.firstWhere(
          (p) => p.id == value,
        );

        var data =
            selected.data() as Map<String, dynamic>;

        setState(() {

  selectedProductId = selected.id;

  selectedProductName = data['name'];

  selectedProductPrice =
      (data['price'] as num).toDouble();
});
      },

      decoration: InputDecoration(

        hintText: "Choose Product",

        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(20),
        ),
      ),
    );
  },
),

SizedBox(height: 25),

            /// 📝 TITLE
            TextField(
              controller: titleController,

              decoration: InputDecoration(
                labelText: "Sale Title",

                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                ),
              ),
            ),

            SizedBox(height: 20),

            /// 📄 DETAILS
            TextField(
              controller: detailsController,
              maxLines: 4,

              decoration: InputDecoration(
                labelText: "Sale Details",

                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                ),
              ),
            ),

            SizedBox(height: 20),

            /// 💸 DISCOUNT
            TextField(
              controller: discountController,
              keyboardType: TextInputType.number,

              decoration: InputDecoration(
                labelText: "Discount %",

                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                ),
              ),
            ),

            SizedBox(height: 20),

            /// 📅 DATE
            GestureDetector(

              onTap: pickDate,

              child: Container(

                width: double.infinity,

                padding: EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 18,
                ),

                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                  ),

                  borderRadius:
                      BorderRadius.circular(15),
                ),

                child: Text(

                  expiryDate == null

                      ? "Choose Expiry Date"

                      : "${expiryDate!.day}/${expiryDate!.month}/${expiryDate!.year}",
                ),
              ),
            ),

            SizedBox(height: 35),

            /// 🔥 BUTTON
            SizedBox(

              width: double.infinity,

              child: ElevatedButton(

                onPressed:
                    isLoading ? null : addSale,

                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    vertical: 16,
                  ),
                ),

                child: isLoading

                    ? CircularProgressIndicator(
                        color: const Color(0xFF6EA6C1),
                      )

                    : Text(
                        "Add Sale",
                        style: TextStyle(
                          fontSize: 16,
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

class EditSaleScreen extends StatefulWidget {

  final String saleId;

  final Map<String, dynamic> saleData;

  EditSaleScreen({
    required this.saleId,
    required this.saleData,
  });

  @override
  State<EditSaleScreen> createState() =>
      _EditSaleScreenState();
}

class _EditSaleScreenState
    extends State<EditSaleScreen> {

  late TextEditingController titleController;

  late TextEditingController detailsController;

  late TextEditingController discountController;

  bool isLoading = false;

  @override
  void initState() {

    super.initState();

    titleController =
        TextEditingController(
      text: widget.saleData['title'],
    );

    detailsController =
        TextEditingController(
      text: widget.saleData['details'],
    );

    discountController =
        TextEditingController(
      text: widget.saleData['discount']
          .toString(),
    );
  }

  Future<void> updateSale() async {

    setState(() {
      isLoading = true;
    });

    await FirebaseFirestore.instance
        .collection('sales')
        .doc(widget.saleId)
        .update({

      "title":
          titleController.text.trim(),

      "details":
          detailsController.text.trim(),

      "discount":
          int.parse(
            discountController.text.trim(),
          ),
    });

    setState(() {
      isLoading = false;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(

      SnackBar(
        content: Text("Sale Updated 🔥"),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: Text("Edit Sale"),
      ),

      body: Padding(

        padding: EdgeInsets.all(20),

        child: Column(
          children: [

            TextField(

              controller: titleController,

              decoration: InputDecoration(
                labelText: "Sale Title",
              ),
            ),

            SizedBox(height: 20),

            TextField(

              controller: detailsController,

              maxLines: 4,

              decoration: InputDecoration(
                labelText: "Sale Details",
              ),
            ),

            SizedBox(height: 20),

            TextField(

              controller: discountController,

              keyboardType:
                  TextInputType.number,

              decoration: InputDecoration(
                labelText: "Discount %",
              ),
            ),

            SizedBox(height: 30),

            ElevatedButton(

              onPressed:
                  isLoading
                      ? null
                      : updateSale,

              child:
                  isLoading
                      ? CircularProgressIndicator()
                      : Text("Update Sale"),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var user = FirebaseAuth.instance.currentUser;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 260,
        margin: EdgeInsets.only(
          top: 60,
          right: 10,
          bottom: 60,
        ),
        padding: EdgeInsets.all(15),

        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),

          gradient: LinearGradient(
            colors: [
              Color(0xFF2D5A74),
              Color(0xFF123249),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),

          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Colors.black26,
            ),
          ],
        ),

        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user?.uid)
              .snapshots(),

          builder: (context, snapshot) {

            Map<String, dynamic> data = {};

            if (snapshot.hasData &&
                snapshot.data!.exists) {
              data =
                  snapshot.data!.data()
                      as Map<String, dynamic>;
            }

            String userName =
                data['name'] ?? "User";

            String email =
                data['email'] ?? "";

            String memberSince = "Unknown";

if (user?.metadata.creationTime != null) {

  DateTime createdAt =
      user!.metadata.creationTime!;

  List months = [
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec",
  ];

  memberSince =
      "${months[createdAt.month - 1]} ${createdAt.year}";
}

            return SingleChildScrollView(
              physics: BouncingScrollPhysics(),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  /// 🔥 HEADER
                  Container(
                    padding: EdgeInsets.all(14),

                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(24),

                      gradient: LinearGradient(
                        colors: [
                          Color(0xff133B63),
                          Color(0xff0B2340),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),

                    child: Column(
                      children: [

                        /// USER INFO
                        Row(
                          children: [

                            Container(
                              width: 58,
                              height: 58,

                              decoration: BoxDecoration(
                                shape: BoxShape.circle,

                                border: Border.all(
                                  color:
                                      Color(0xff58D0FF),
                                  width: 2,
                                ),

                                boxShadow: [
                                  BoxShadow(
                                    color: Color(
                                      0xff58D0FF,
                                    ).withOpacity(.4),

                                    blurRadius: 15,
                                  ),
                                ],
                              ),

                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),

                            SizedBox(width: 10),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,

                                children: [

                                  Text(
                                    userName,

                                    maxLines: 1,

                                    overflow:
                                        TextOverflow
                                            .ellipsis,

                                    style: TextStyle(
                                      color:
                                          Colors.white,

                                      fontWeight:
                                          FontWeight
                                              .bold,

                                      fontSize: 16,
                                    ),
                                  ),

                                  SizedBox(height: 3),

                                  Text(
                                    "Valued Customer",

                                    style: TextStyle(
                                      color: Color(
                                        0xff6DD5FF,
                                      ),

                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 16),

                        /// 🔥 STATS
                        Container(
                          padding:
                              EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 12,
                          ),

                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(
                              20,
                            ),

                            color: Colors.white
                                .withOpacity(.05),

                            border: Border.all(
                              color: Colors.white10,
                            ),
                          ),

                          child: Row(
                            children: [

                              Expanded(
                                child: Row(
                                  children: [

                                    Icon(
                                      Icons
                                          .verified_user,

                                      color: Color(
                                        0xff58D0FF,
                                      ),

                                      size: 22,
                                    ),

                                    SizedBox(width: 6),

                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,

                                        children: [

                                          Text(
                                            "Member since",

                                            overflow:
                                                TextOverflow
                                                    .ellipsis,

                                            style:
                                                TextStyle(
                                              color:
                                                  Colors
                                                      .white70,

                                              fontSize:
                                                  10,
                                            ),
                                          ),

                                          SizedBox(
                                            height: 2,
                                          ),

                                          Text(
                                            memberSince,

                                            overflow:
                                                TextOverflow
                                                    .ellipsis,

                                            style:
                                                TextStyle(
                                              color:
                                                  Colors
                                                      .white,

                                              fontWeight:
                                                  FontWeight
                                                      .bold,

                                              fontSize:
                                                  13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Container(
                                width: 1,
                                height: 35,
                                color: Colors.white12,
                              ),

                              SizedBox(width: 8),

                              Expanded(
                                child:
                                    FutureBuilder<
                                        QuerySnapshot>(
                                  future:
                                      FirebaseFirestore
                                          .instance
                                          .collection(
                                            'orders',
                                          )
                                          .where(
                                            'userId',
                                            isEqualTo:
                                                user
                                                    ?.uid,
                                          )
                                          .get(),

                                  builder:
                                      (context,
                                          orderSnap) {

                                    int totalOrders =
                                        orderSnap
                                            .data
                                            ?.docs
                                            .length ??
                                        0;

                                    return Row(
                                      children: [

                                        Icon(
                                          Icons
                                              .shopping_bag,

                                          color: Color(
                                            0xff58D0FF,
                                          ),

                                          size: 22,
                                        ),

                                        SizedBox(
                                          width: 6,
                                        ),

                                        Expanded(
                                          child:
                                              Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment
                                                    .start,

                                            children: [

                                              Text(
                                                "Total Orders",

                                                overflow:
                                                    TextOverflow
                                                        .ellipsis,

                                                style:
                                                    TextStyle(
                                                  color:
                                                      Colors
                                                          .white70,

                                                  fontSize:
                                                      10,
                                                ),
                                              ),

                                              SizedBox(
                                                height:
                                                    2,
                                              ),

                                              Text(
                                                "$totalOrders Orders",

                                                overflow:
                                                    TextOverflow
                                                        .ellipsis,

                                                style:
                                                    TextStyle(
                                                  color:
                                                      Colors
                                                          .white,

                                                  fontWeight:
                                                      FontWeight
                                                          .bold,

                                                  fontSize:
                                                      13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16),

                  /// 🔥 ITEMS
                  drawerItem(
                    context,

                    icon: Icons.person,

                    title: "My Profile",

                    subtitle:
                        "View and edit your information",

                    iconColor: Color(0xff4C7DFF),

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => ProfileScreen(),
                        ),
                      );
                    },
                  ),

                  drawerItem(
                    context,

                    icon: Icons.star,

                    title:
                        "Our Customers Reviews",

                    subtitle:
                        "See what our customers say",

                    iconColor: Colors.amber,

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => ReviewsScreen(),
                        ),
                      );
                    },
                  ),

                  drawerItem(
                    context,

                    icon: Icons.support_agent,

                    title: "Contact Us",

                    subtitle:
                        "We're here to help you",

                    iconColor: Colors.white,

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) =>
                                  ContactUsScreen(),
                        ),
                      );
                    },
                  ),

                  Divider(
                    color: Colors.white10,
                    height: 24,
                  ),

                  drawerItem(
                    context,

                    icon: Icons.settings,

                    title: "Settings",

                    subtitle: "App preferences",

                    iconColor: Colors.white,

                    onTap: () {},
                  ),

                  drawerItem(
                    context,

                    icon: Icons.privacy_tip,

                    title: "Privacy Policy",

                    subtitle:
                        "Your data is safe with us",

                    iconColor: Colors.white,

                    onTap: () {},
                  ),

                  drawerItem(
                    context,

                    icon: Icons.description,

                    title:
                        "Terms & Conditions",

                    subtitle:
                        "Read our terms of service",

                    iconColor: Colors.white,

                    onTap: () {},
                  ),

                  SizedBox(height: 12),

                  /// 🔥 LOGOUT
                  Container(
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(20),

                      gradient: LinearGradient(
                        colors: [
                          Colors.red.withOpacity(.18),

                          Colors.pink.withOpacity(
                            .08,
                          ),
                        ],
                      ),
                    ),

                    child: ListTile(
                      contentPadding:
                          EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),

                      leading: Icon(
                        Icons.logout,
                        color: Colors.redAccent,
                      ),

                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.redAccent,
                        size: 16,
                      ),

                      title: Text(
                        "Logout",

                        style: TextStyle(
                          color: Colors.redAccent,

                          fontWeight:
                              FontWeight.bold,

                          fontSize: 15,
                        ),
                      ),

                      subtitle: Text(
                        "Sign out from your account",

                        style: TextStyle(
                          color: Colors.white70,

                          fontSize: 11,
                        ),
                      ),

                      onTap: () async {

                        await FirebaseAuth.instance
                            .signOut();

                        Navigator.pushAndRemoveUntil(
                          context,

                          MaterialPageRoute(
                            builder:
                                (_) => LoginScreen(),
                          ),

                          (route) => false,
                        );
                      },
                    ),
                  ),

                  SizedBox(height: 14),

                  /// 🔥 SUPPORT BOX
                  Container(
                    padding: EdgeInsets.all(10),

                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(20),

                      color: Colors.white
                          .withOpacity(.05),

                      border: Border.all(
                        color: Colors.white10,
                      ),
                    ),

                    child: Row(
                      children: [

                        CircleAvatar(
                          radius: 20,

                          backgroundColor:
                              Colors.white
                                  .withOpacity(.08),

                          child: Icon(
                            Icons.headset_mic,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),

                        SizedBox(width: 10),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                            children: [

                              Text(
                                "Need help?",

                                style: TextStyle(
                                  color:
                                      Colors.white,

                                  fontWeight:
                                      FontWeight
                                          .bold,

                                  fontSize: 14,
                                ),
                              ),

                              SizedBox(height: 3),

                              Text(
  "Medlife.supportteam@gmail.com",

  maxLines: 1,

  overflow: TextOverflow.ellipsis,

  style: TextStyle(
    color: Color(0xff58D0FF),
    fontSize: 11,
  ),
),
                            ],
                          ),
                        ),

                        InkWell(
  onTap: () async {

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path:
          'Medlife.supportteam@gmail.com',
    );

    await launchUrl(emailLaunchUri);
  },

  child: CircleAvatar(
    radius: 20,
    backgroundColor: Color(0xff256DFF),

    child: Icon(
      Icons.email,
      color: Colors.white,
      size: 18,
    ),
  ),
),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget drawerItem(
    BuildContext context, {

    required IconData icon,

    required String title,

    required String subtitle,

    required Color iconColor,

    required VoidCallback onTap,
  }) {

    return Padding(
      padding: EdgeInsets.only(bottom: 10),

      child: Material(
        color: Colors.transparent,

        child: InkWell(
          borderRadius:
              BorderRadius.circular(20),

          onTap: onTap,

          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),

            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(20),

              color:
                  Colors.white.withOpacity(.03),
            ),

            child: Row(
              children: [

                Container(
                  width: 48,
                  height: 48,

                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),

                    color: Colors.white
                        .withOpacity(.05),
                  ),

                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 24,
                  ),
                ),

                SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      Text(
                        title,

                        style: TextStyle(
                          color: Colors.white,

                          fontWeight:
                              FontWeight.bold,

                          fontSize: 15,
                        ),
                      ),

                      SizedBox(height: 3),

                      Text(
                        subtitle,

                        maxLines: 2,

                        overflow:
                            TextOverflow.ellipsis,

                        style: TextStyle(
                          color: Colors.white70,

                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 4),

                Icon(
                  Icons.arrow_forward_ios,

                  color: Colors.white70,

                  size: 15,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ReviewsScreen extends StatefulWidget {
  @override
  State<ReviewsScreen> createState() =>
      _ReviewsScreenState();
}

class _ReviewsScreenState
    extends State<ReviewsScreen>
    with SingleTickerProviderStateMixin {

  final reviewController = TextEditingController();

  int selectedRating = 0;

  bool isLoading = false;

late AnimationController _barsController;

@override
void initState() {
  super.initState();

  _barsController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    _barsController.forward();
  });
}

@override
void dispose() {
  _barsController.dispose();
  reviewController.dispose();
  super.dispose();
}

  Future<void> submitReview() async {

    var user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    if (selectedRating == 0 ||
        reviewController.text.trim().isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Choose rating and write review"),
        ),
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {

      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      var userData =
          userDoc.data() as Map<String, dynamic>;

      var existing = await FirebaseFirestore.instance
          .collection('reviews')
          .where('userId', isEqualTo: user.uid)
          .get();

      if (existing.docs.isNotEmpty) {

        await FirebaseFirestore.instance
            .collection('reviews')
            .doc(existing.docs.first.id)
            .update({

          'rating': selectedRating,

          'review':
              reviewController.text.trim(),

          'createdAt': Timestamp.now(),
        });

      } else {

        await FirebaseFirestore.instance
            .collection('reviews')
            .add({

          'userId': user.uid,

          'userName':
              userData['name'] ?? "User",

          'rating': selectedRating,

          'review':
              reviewController.text.trim(),

          'createdAt': Timestamp.now(),
        });
      }

      reviewController.clear();

      setState(() {
        selectedRating = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Review Submitted Successfully ⭐"),
        ),
      );

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error ❌"),
        ),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    bool isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    const Color bgColor = Color(0xFF141118);

    const Color cardColor = Color(0xFF1D1B20);

    const Color blueColor = Color(0xFF6EA6C1);

    return Scaffold(

      backgroundColor: bgColor,

      appBar: AppBar(

  backgroundColor:
      isDark
          ? const Color(0xFF141118)
          : Colors.white,

  elevation: 0,

  leading: IconButton(
    icon: Icon(
      Icons.arrow_back,
      color:
          isDark
              ? Colors.white
              : Colors.black,
    ),

    onPressed: () {
      Navigator.pop(context);
    },
  ),

  title: Text(
    "Our Customers Reviews",

    style: TextStyle(
      color:
          isDark
              ? Colors.white
              : Colors.black,

      fontWeight: FontWeight.bold,
      fontSize: 24,
    ),
  ),
),

      body: StreamBuilder(

        stream: FirebaseFirestore.instance
            .collection('reviews')
            .orderBy(
              'createdAt',
              descending: true,
            )
            .snapshots(),

        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(
                color: blueColor,
              ),
            );
          }

          var reviews = snapshot.data!.docs;

          double average = 0;

          if (reviews.isNotEmpty) {

            int total = 0;

            for (var review in reviews) {
              total += review['rating'] as int;
            }

            average = total / reviews.length;
          }

          int star5 = 0;
          int star4 = 0;
          int star3 = 0;
          int star2 = 0;
          int star1 = 0;

          for (var review in reviews) {

            int rate = review['rating'];

            if (rate == 5) star5++;
            if (rate == 4) star4++;
            if (rate == 3) star3++;
            if (rate == 2) star2++;
            if (rate == 1) star1++;
          }

          double percent(int count) {

            if (reviews.isEmpty) return 0;

            return count / reviews.length;
          }

          return SingleChildScrollView(

            padding: EdgeInsets.all(20),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                /// ⭐ AVERAGE
                Center(
 child: TweenAnimationBuilder<double>(
  duration: const Duration(
    milliseconds: 1800,
  ),
  curve: Curves.easeOutCubic,
  tween: Tween(
    begin: 0,
    end: average,
  ),

    builder: (context, animatedAverage, child) {

      return Column(
        children: [

          Text(
            animatedAverage.toStringAsFixed(1),

            style: TextStyle(
              fontSize: 55,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          SizedBox(height: 8),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.center,

            children: List.generate(
              5,
              (index) {

                double fill =
                    animatedAverage - index;

                if (fill < 0) fill = 0;
                if (fill > 1) fill = 1;

                return Stack(
                  children: [

                    Icon(
                      Icons.star_border,
                      color: Color(0xFF6EA6C1),
                      size: 30,
                    ),

                    ClipRect(
                      child: Align(
                        alignment:
                            Alignment.centerLeft,

                        widthFactor: fill,

                        child: Icon(
                          Icons.star,
                          color:
                              Color(0xFF6EA6C1),
                          size: 30,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          SizedBox(height: 8),

          Text(
            "Based on ${reviews.length} Reviews",

            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      );
    },
  ),
),

                SizedBox(height: 30),

                /// 📊 BARS
                buildRatingBar(
                    5,
                    percent(star5),
                    isDark),

                buildRatingBar(
                    4,
                    percent(star4),
                    isDark),

                buildRatingBar(
                    3,
                    percent(star3),
                    isDark),

                buildRatingBar(
                    2,
                    percent(star2),
                    isDark),

                buildRatingBar(
                    1,
                    percent(star1),
                    isDark),

                SizedBox(height: 35),

                /// ✍️ REVIEW CARD
                Container(

                  padding: EdgeInsets.all(20),

                  decoration: BoxDecoration(

                    color: cardColor,

                    borderRadius:
                        BorderRadius.circular(30),
                  ),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      Text(
                        "Rate Our App",

                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 20),

                      /// ⭐ STARS
                      Row(
                        children: List.generate(
                          5,
                          (index) {

                            int star = index + 1;

                            return GestureDetector(

                              onTap: () {
                                setState(() {
                                  selectedRating = star;
                                });
                              },

                              child: AnimatedContainer(

                                duration:
                                    Duration(milliseconds: 200),

                                margin:
                                    EdgeInsets.only(right: 8),

                                child: Icon(

                                  star <= selectedRating
                                      ? Icons.star
                                      : Icons.star_border,

                                  color: blueColor,

                                  size: star == selectedRating
                                      ? 40
                                      : 34,
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      SizedBox(height: 20),

                      /// ✍️ REVIEW FIELD
                      TextField(

                        controller: reviewController,

                        maxLines: 4,

                        style: TextStyle(
                          color: Colors.white,
                        ),

                        decoration: InputDecoration(

                          hintText:
                              "Write your review...",

                          hintStyle: TextStyle(
                            color: Colors.white70,
                          ),

                          filled: true,

                          fillColor:
                              bgColor,

                          border: OutlineInputBorder(

                            borderRadius:
                                BorderRadius.circular(20),

                            borderSide:
                                BorderSide.none,
                          ),
                        ),
                      ),

                      SizedBox(height: 20),

                      /// 🚀 BUTTON
                      SizedBox(
                        width: double.infinity,

                        child: ElevatedButton(

                          onPressed:
                              isLoading
                                  ? null
                                  : submitReview,

                          style:
                              ElevatedButton.styleFrom(

                            backgroundColor:
                                blueColor,

                            foregroundColor:
                                Colors.white,

                            padding:
                                EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                          ),

                          child: isLoading
                              ? CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text(
                                  "Submit Review",
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 35),

                /// 👥 REVIEWS
                Text(
                  "Users Reviews",

                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 20),

                if (reviews.isEmpty)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),

                      child: Text(
                        "No Reviews Yet ⭐",

                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),

                ...reviews.map((doc) {

                  var data =
                      doc.data() as Map<String, dynamic>;

                  return buildReviewCard(
                    data['userName'],
                    data['rating'],
                    data['review'],
                    isDark,
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }

  /// ⭐ BAR
  Widget buildRatingBar(
  int star,
  double value,
  bool isDark,
) {
  final double startDelay =
      (5 - star) * 0.12;

  return AnimatedBuilder(
    animation: _barsController,

    builder: (context, child) {

      double progress =
          ((_barsController.value - startDelay) /
                  (1 - startDelay))
              .clamp(0.0, 1.0);

      progress = Curves.easeOutCubic
          .transform(progress);

      final animatedValue =
          value * progress;

      return Padding(
        padding:
            const EdgeInsets.only(bottom: 14),

        child: Row(
          children: [

            Text(
              "$star",
              style: const TextStyle(
                color: Colors.white,
              ),
            ),

            const SizedBox(width: 5),

            const Icon(
              Icons.star,
              color: Color(0xFF6EA6C1),
              size: 18,
            ),

            const SizedBox(width: 12),

            Expanded(
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(20),

                child: LinearProgressIndicator(
                  value: animatedValue,
                  minHeight: 10,
                  backgroundColor:
                      Colors.white12,

                  valueColor:
                      const AlwaysStoppedAnimation(
                    Color(0xFF6EA6C1),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 10),

            SizedBox(
              width: 42,
              child: Text(
                "${(animatedValue * 100).toInt()}%",
                textAlign: TextAlign.end,

                style: const TextStyle(
                  color: Colors.white70,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

  /// 💬 REVIEW CARD
  Widget buildReviewCard(
      String name,
      int stars,
      String review,
      bool isDark,
      ) {

    return Container(

      margin: EdgeInsets.only(bottom: 20),

      padding: EdgeInsets.all(18),

      decoration: BoxDecoration(

        color: Color(0xFF1D1B20),

        borderRadius:
            BorderRadius.circular(22),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Row(
            children: [

              CircleAvatar(
                backgroundColor:
                    Color(0xFF6EA6C1),

                child: Text(
                  name[0].toUpperCase(),
                ),
              ),

              SizedBox(width: 10),

              Expanded(
                child: Text(
                  name,

                  style: TextStyle(
                    color: Colors.white,
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 15),

          Row(
            children: List.generate(
              stars,
                  (index) => Icon(
                Icons.star,
                color: Color(0xFF6EA6C1),
                size: 20,
              ),
            ),
          ),

          SizedBox(height: 12),

          Text(
            review,

            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

//////////////////// 📞 CONTACT US SCREEN /////////////////////

class ContactUsScreen extends StatelessWidget {
  ContactUsScreen({super.key});

  /// 🔗 OPEN LINKS
  Future<void> openLink(String url) async {
    final Uri uri = Uri.parse(url);

    try {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  /// 🔹 CONTACT CARD
  Widget buildContactCard({
    required BuildContext context,
    String? imagePath,
    IconData? icon,
    Color? iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    bool isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: 18),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),

        color: isDark
            ? const Color(0xFF1D1B20)
            : Colors.black.withOpacity(0.03),

        border: Border.all(
          color: isDark
              ? Colors.white10
              : Colors.black12,
        ),

        boxShadow: [
          BoxShadow(
            blurRadius: 15,
            offset: Offset(0, 6),

            color: isDark
                ? Colors.black26
                : Colors.black12,
          ),
        ],
      ),

      child: Material(
        color: Colors.transparent,

        child: InkWell(
          borderRadius: BorderRadius.circular(24),

          onTap: onTap,

          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 18,
            ),

            child: Row(
              children: [

                /// 🔥 ICON / IMAGE
                Container(
                  width: 70,
                  height: 70,

                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: bgColor,
                  ),

                  child: imagePath != null
                      ? Padding(
                          padding:
                              const EdgeInsets.all(
                            14,
                          ),

                          child: Image.asset(
                            imagePath,
                            fit: BoxFit.contain,
                          ),
                        )
                      : Icon(
                          icon,
                          size: 38,
                          color: iconColor,
                        ),
                ),

                SizedBox(width: 18),

                /// 🔥 TEXT
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      Text(
                        title,

                        style: TextStyle(
                          fontSize: 22,
                          fontWeight:
                              FontWeight.bold,

                          color: isDark
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),

                      SizedBox(height: 6),

                      Text(
                        subtitle,

                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),

                      SizedBox(height: 6),

                      Text(
                        "Tap to open",

                        style: TextStyle(
                          fontSize: 13,

                          color: isDark
                              ? Colors.white60
                              : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),

                /// ➜ ARROW
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: const Color(0xFF6EA6C1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF141118)
          : Colors.white,

      appBar: AppBar(
        title: Text(
          "Contact Us",

          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        centerTitle: true,

        elevation: 0,

        backgroundColor: isDark
            ? const Color(0xFF141118)
            : Colors.white,

        foregroundColor:
            isDark
                ? Colors.white
                : Colors.black,
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),

        child: Column(
          children: [

            SizedBox(height: 10),

            /// 🎧 TOP ICON
            Container(
              padding: EdgeInsets.all(28),

              decoration: BoxDecoration(
                shape: BoxShape.circle,

                color: isDark
                    ? const Color(0xFF1D1B20)
                    : Colors.black.withOpacity(
                        0.04,
                      ),

                border: Border.all(
                  color: isDark
                      ? Colors.white12
                      : Colors.black12,
                ),
              ),

              child: Icon(
                Icons.support_agent_rounded,

                size: 70,

                color: const Color(
                  0xFF6EA6C1,
                ),
              ),
            ),

            SizedBox(height: 30),

            /// 🔥 TITLE
            Text(
              "We're Here For You",

              textAlign: TextAlign.center,

              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,

                color: isDark
                    ? Colors.white
                    : Colors.black,
              ),
            ),

            SizedBox(height: 12),

            /// 🔥 SUBTITLE
            Text(
              "Feel free to contact us anytime you need help.",

              textAlign: TextAlign.center,

              style: TextStyle(
                fontSize: 17,

                color: isDark
                    ? Colors.white70
                    : Colors.black54,
              ),
            ),

            SizedBox(height: 35),

            /// 📸 INSTAGRAM
            buildContactCard(
              context: context,

              imagePath:
                  "assets/Instagram.png",

              bgColor:
                  const Color(0x336EA6C1),

              title: "Instagram",

              subtitle: "@medlife_eg",

              onTap: () {
                openLink(
                  "https://www.instagram.com/medlife_eg?igsh=aWlxb20ybGZvamk2",
                );
              },
            ),

            /// 📘 FACEBOOK
            buildContactCard(
              context: context,

              imagePath:
                  "assets/Facebook.png",

              bgColor:
                  const Color(0x336EA6C1),

              title: "Facebook",

              subtitle: "MedLife",

              onTap: () {
                openLink(
                  "https://www.facebook.com/profile.php?id=61574319662590",
                );
              },
            ),

            /// 🎵 TIKTOK
            buildContactCard(
              context: context,

              imagePath:
                  "assets/Tiktok.png",

              bgColor:
                  const Color(0x336EA6C1),

              title: "TikTok",

              subtitle: "@medlife_eg",

              onTap: () {
                openLink(
                  "https://www.tiktok.com/@medlife_eg",
                );
              },
            ),

            /// 💬 WHATSAPP
            buildContactCard(
              context: context,

              imagePath:
                  "assets/Whatsapp.png",

              bgColor:
                  const Color(0x336EA6C1),

              title: "WhatsApp",

              subtitle:
                  "+20 1010 520 993",

              onTap: () {
                openLink(
                  "https://wa.me/201010520993",
                );
              },
            ),

            /// 📧 EMAIL
            buildContactCard(
              context: context,

              imagePath:
                  "assets/Gmail.png",

              bgColor:
                  const Color(0x336EA6C1),

              title: "Support Email",

              subtitle:
                  "medlife.supportteam@gmail.com",

              onTap: () {
                openLink(
                  "mailto:medlife.supportteam@gmail.com",
                );
              },
            ),

            SizedBox(height: 10),

            //// 🔒 PRIVACY
            Container(
              width: double.infinity,

              padding: EdgeInsets.all(20),

              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(
                  20,
                ),

                color: isDark
                    ? const Color(
                        0xFF1D1B20,
                      )
                    : Colors.black
                        .withOpacity(0.03),

                border: Border.all(
                  color: isDark
                      ? Colors.white10
                      : Colors.black12,
                ),

                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black
                            .withOpacity(0.25)
                        : Colors.black
                            .withOpacity(0.08),

                    blurRadius: 12,

                    offset: Offset(0, 5),
                  ),
                ],
              ),

              child: Row(
                children: [

                  Container(
                    padding: EdgeInsets.all(
                      12,
                    ),

                    decoration: BoxDecoration(
                      shape: BoxShape.circle,

                      color: const Color(
                        0x336EA6C1,
                      ),
                    ),

                    child: Icon(
                      Icons.shield_outlined,

                      color: const Color(
                        0xFF6EA6C1,
                      ),
                    ),
                  ),

                  SizedBox(width: 15),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [

                        Text(
                          "We value your privacy",

                          style: TextStyle(
                            fontWeight:
                                FontWeight.bold,

                            fontSize: 16,

                            color: isDark
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),

                        SizedBox(height: 5),

                        Text(
                          "Your information is safe with us and will never be shared.",

                          style: TextStyle(
                            color: isDark
                                ? Colors.white70
                                : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

///////////////////// 📦 DETAILS /////////////////////

class ProductDetailsScreen extends StatefulWidget {
  final dynamic product;
  final List<Map<String, dynamic>> cart;
  final VoidCallback onAddToCart;

  ProductDetailsScreen({
    required this.product,
    required this.cart,
    required this.onAddToCart,
  });

  @override
  State<ProductDetailsScreen> createState() =>
      _ProductDetailsScreenState();
}

class _ProductDetailsScreenState
    extends State<ProductDetailsScreen> {
  String selectedSize = "M";
  int quantity = 1;
  int currentIndex = 0;

  bool isDescriptionOpen = true;
bool isDeliveryOpen = true;
bool isReviewsOpen = false;

@override
void initState() {
  super.initState();
}

  Widget buildSizeButton(String size) {
    bool isSelected = selectedSize == size;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedSize = size;
        });
      },

      child: AnimatedContainer(
        duration: Duration(milliseconds: 250),

        width: 64,
        height: 64,

        alignment: Alignment.center,

        decoration: BoxDecoration(
          color: const Color(0xFF141118),

          borderRadius: BorderRadius.circular(18),

          border: Border.all(
            color: isSelected
                ? const Color(0xFF4EA5FF)
                : Colors.white10,
            width: 1.6,
          ),

          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF4EA5FF)
                        .withOpacity(.35),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),

        child: Text(
          size,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var product = widget.product;

    var data =
        widget.product.data() as Map<String, dynamic>;

    List images = data.containsKey('images')
        ? data['images']
        : [data['image']];

    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,

        title: Text(
          product['name'] ?? "",
          style: TextStyle(color: Colors.white),
        ),

        iconTheme: IconThemeData(color: Colors.white),

        actions: [
          GestureDetector(

  onTap: () {

    Navigator.push(
      context,

      MaterialPageRoute(
        builder: (_) => CartScreen(
          cart: widget.cart,
        ),
      ),
    );
  },

  child: Stack(
    clipBehavior: Clip.none,

    children: [

      Icon(
        Icons.shopping_cart_outlined,
        color: Colors.white,
        size: 30,
      ),

      if (widget.cart.isNotEmpty)

        Positioned(
          right: -6,
          top: -6,

          child: Container(

            padding: EdgeInsets.all(5),

            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),

            child: Text(

              "${widget.cart.length}",

              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
    ],
  ),
),

          SizedBox(width: 16),
        ],
      ),

      body: SafeArea(
        child: Column(
          children: [

            /// 🔥 BODY
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),

                child: Column(
                  children: [

                    /// 🔥 IMAGE + DETAILS
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [

                        /// 🔥 IMAGE
                        Expanded(
                          flex: 5,

                          child: Column(
                            children: [

                              Container(
                                height: 520,

                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(
                                          28),
                                ),

                                clipBehavior: Clip.antiAlias,

                                child: Stack(
                                  children: [

                                    PageView.builder(
                                      itemCount:
                                          images.length,

                                      onPageChanged:
                                          (index) {
                                        setState(() {
                                          currentIndex =
                                              index;
                                        });
                                      },

                                      itemBuilder:
                                          (context,
                                              index) {
                                        return Image.network(
                                          images[index],
                                          fit: BoxFit.cover,
                                          width:
                                              double.infinity,
                                        );
                                      },
                                    ),

                                    GestureDetector(

  onTap: () {

    showDialog(

      context: context,

      builder: (_) {

        return Dialog(

          backgroundColor: Colors.black,

          insetPadding: EdgeInsets.zero,

          child: Stack(

            children: [

              InteractiveViewer(

                minScale: 1,
                maxScale: 5,

                child: Image.network(

                  images[currentIndex],

                  width: double.infinity,

                  height: double.infinity,

                  fit: BoxFit.contain,
                ),
              ),

              Positioned(

                top: 40,
                right: 20,

                child: GestureDetector(

                  onTap: () {
                    Navigator.pop(context);
                  },

                  child: Container(

                    padding: EdgeInsets.all(10),

                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),

                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  },

  child: Container(

    padding: EdgeInsets.all(18),

    decoration: BoxDecoration(

      color: Colors.black45,
      shape: BoxShape.circle,
    ),

    child: Icon(

      Icons.zoom_in,

      color: Colors.white,
      size: 34,
    ),
  ),
)
                                  ],
                                ),
                              ),

                              SizedBox(height: 14),

                              /// 🔥 INDICATORS
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .center,

                                children: List.generate(
                                  images.length,
                                  (index) {
                                    return AnimatedContainer(
                                      duration: Duration(
                                          milliseconds:
                                              250),

                                      margin:
                                          EdgeInsets
                                              .symmetric(
                                        horizontal: 4,
                                      ),

                                      width:
                                          currentIndex ==
                                                  index
                                              ? 24
                                              : 8,

                                      height: 8,

                                      decoration:
                                          BoxDecoration(
                                        color:
                                            currentIndex ==
                                                    index
                                                ? const Color(
                                                    0xFF4EA5FF)
                                                : Colors
                                                    .white30,

                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                                    20),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(width: 18),

                        /// 🔥 RIGHT SIDE
                        Expanded(
                          flex: 4,

                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,

                            children: [

                              SizedBox(height: 25),

                              Text(
                                product['name'],

                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 34,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),

                              SizedBox(height: 10),

                              Text(
                                "${product['price']} EGP",

                                style: TextStyle(
                                  color: const Color(
                                      0xFF4EA5FF),

                                  fontSize: 24,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),

                              SizedBox(height: 48),

                              /// 🔥 SIZE TITLE
                              Row(
  children: [

    Expanded(
      child: Text(
        "Choose Size",
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    Icon(
      Icons.straighten,
      color: Color(0xFF4DA3FF),
      size: 18,
    ),

    SizedBox(width: 4),

    Flexible(
      child: Text(
        "Size Guide",
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Color(0xFF4DA3FF),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  ],
),

                              SizedBox(height: 22),

                              /// 🔥 SIZES
                              Wrap(
                                spacing: 14,
                                runSpacing: 14,

                                children: [
                                  buildSizeButton("S"),
                                  buildSizeButton("M"),
                                  buildSizeButton("L"),
                                  buildSizeButton("XL"),
                                ],
                              ),

                              SizedBox(height: 55),

                              /// 🔥 QUANTITY
                              Text(
                                "Quantity",

                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),

                              SizedBox(height: 18),

                              Container(
                                width: 220,
                                height: 70,

                                decoration: BoxDecoration(
                                  color:
                                      const Color(
                                          0xFF141118),

                                  borderRadius:
                                      BorderRadius
                                          .circular(24),

                                  border: Border.all(
                                    color:
                                        Colors.white10,
                                  ),
                                ),

                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .spaceEvenly,

                                  children: [

                                    IconButton(
                                      onPressed: () {
                                        if (quantity >
                                            1) {
                                          setState(() {
                                            quantity--;
                                          });
                                        }
                                      },

                                      icon: Icon(
                                        Icons.remove,
                                        color:
                                            Colors.white,
                                        size: 30,
                                      ),
                                    ),

                                    Text(
                                      "$quantity",

                                      style: TextStyle(
                                        color:
                                            Colors.white,
                                        fontSize: 26,
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
                                    ),

                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          quantity++;
                                        });
                                      },

                                      icon: Icon(
                                        Icons.add,
                                        color:
                                            Colors.white,
                                        size: 30,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 26),

                    /// 🔥 DESCRIPTION
Container(
  width: double.infinity,
  padding: EdgeInsets.all(22),

  decoration: BoxDecoration(
    color: const Color(0xFF141118),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(
      color: Colors.white10,
    ),
  ),

  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,

    children: [

      /// HEADER
      GestureDetector(

        onTap: () {
          setState(() {
            isDescriptionOpen =
                !isDescriptionOpen;
          });
        },

        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,

          children: [

            Text(
              "Description",

              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            AnimatedRotation(
              turns:
                  isDescriptionOpen
                      ? 0
                      : 0.5,

              duration:
                  Duration(milliseconds: 250),

              child: Icon(
                Icons.keyboard_arrow_up,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),

      /// CONTENT
      AnimatedCrossFade(

        duration:
            Duration(milliseconds: 250),

        crossFadeState:
            isDescriptionOpen
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,

        firstChild: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            SizedBox(height: 18),

            Text(
              data['description'] ??
                  "No description available",

              style: TextStyle(
                color: Colors.white70,
                height: 1.6,
                fontSize: 16,
              ),
            ),
          ],
        ),

        secondChild:
            SizedBox.shrink(),
      ),
    ],
  ),
),

                    SizedBox(height: 18),

                    /// 🔥 DELIVERY
Container(
  width: double.infinity,

  padding: EdgeInsets.all(22),

  decoration: BoxDecoration(
    color: const Color(0xFF141118),

    borderRadius:
        BorderRadius.circular(24),

    border: Border.all(
      color: Colors.white10,
    ),
  ),

  child: Column(
    crossAxisAlignment:
        CrossAxisAlignment.start,

    children: [

      /// HEADER
      GestureDetector(

        onTap: () {
          setState(() {
            isDeliveryOpen =
                !isDeliveryOpen;
          });
        },

        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,

          children: [

            Text(
              "Delivery",

              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            AnimatedRotation(
              turns:
                  isDeliveryOpen
                      ? 0
                      : 0.5,

              duration:
                  Duration(milliseconds: 250),

              child: Icon(
                Icons.keyboard_arrow_up,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),

      /// CONTENT
      AnimatedCrossFade(

        duration:
            Duration(milliseconds: 250),

        crossFadeState:
            isDeliveryOpen
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,

        firstChild: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            SizedBox(height: 18),

            Text(
              data['deliveryText'] ??
                  "No delivery info available",

              style: TextStyle(
                color: Colors.white70,
                height: 1.6,
                fontSize: 16,
              ),
            ),
          ],
        ),

        secondChild:
            SizedBox.shrink(),
      ),
    ],
  ),
),

                    SizedBox(height: 14),

                    /// 🔥 REVIEWS
                    buildSection("Reviews (Soon!)"),

                    SizedBox(height: 120),
                  ],
                ),
              ),
            ),

            /// 🔥 BOTTOM BAR
            Container(
              padding: EdgeInsets.fromLTRB(
                  20, 16, 20, 22),

              decoration: BoxDecoration(
                color: Colors.black,

                border: Border(
                  top: BorderSide(
                    color: Colors.white10,
                  ),
                ),
              ),

              child: Row(
                children: [

                  /// 🔥 PRICE
                  Expanded(
                    child: Text(
                      "${product['price']} EGP",

                      style: TextStyle(
                        color:
                            const Color(0xFF4EA5FF),

                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  SizedBox(width: 20),

                  /// 🔥 BUTTON
                  Expanded(
                    flex: 2,

                    child: SizedBox(
                      height: 68,

                      child: ElevatedButton(
                        onPressed: () async {

                          var index =
                              widget.cart.indexWhere(
                            (i) =>
                                i['name'] ==
                                    product['name'] &&
                                i['size'] ==
                                    selectedSize,
                          );

                          if (index != -1) {
                            widget.cart[index]
                                    ['quantity'] =
                                (widget.cart[index]
                                            ['quantity'] ??
                                        1) +
                                    quantity;
                          } else {
                            widget.cart.add({
                              "name": data['name'],
                              "price":
                                  data['price'],
                              "image": images
                                      .isNotEmpty
                                  ? images[0]
                                  : "",
                              "size":
                                  selectedSize,
                              "quantity":
                                  quantity,
                            });

                            widget.onAddToCart();
                          }

                          var user =
                              FirebaseAuth
                                  .instance
                                  .currentUser;

                          if (user != null) {

                            var cartRef =
                                FirebaseFirestore
                                    .instance
                                    .collection(
                                        'users')
                                    .doc(user.uid)
                                    .collection(
                                        'cart');

                            var existing =
                                await cartRef
                                    .where(
                                      "name",
                                      isEqualTo:
                                          product[
                                              'name'],
                                    )
                                    .where(
                                      "size",
                                      isEqualTo:
                                          selectedSize,
                                    )
                                    .get();

                            if (existing
                                .docs
                                .isNotEmpty) {

                              var doc =
                                  existing
                                      .docs
                                      .first;

                              await cartRef
                                  .doc(doc.id)
                                  .update({
                                "quantity":
                                    (doc['quantity'] ??
                                            1) +
                                        quantity,
                              });

                            } else {

                              await cartRef
                                  .add({
                                "name":
                                    data['name'],

                                "price":
                                    data['price'],

                                "image":
                                    images.isNotEmpty
                                        ? images[0]
                                        : "",

                                "size":
                                    selectedSize,

                                "quantity":
                                    quantity,
                              });
                            }
                          }

                          ScaffoldMessenger.of(
                                  context)
                              .showSnackBar(
                            SnackBar(
                              content: Text(
                                  "Added to cart 🛒"),
                            ),
                          );
                        },

                        style: ElevatedButton
                            .styleFrom(
                          backgroundColor:
                              const Color(
                                  0xFF67B7FF),

                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(24),
                          ),
                        ),

                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .center,

                          children: [

                            Icon(
                              Icons.shopping_cart_outlined,
                              color: Colors.white,
                              size: 36,
                            ),

                            SizedBox(width: 12),

                            Text(
                              "Add to Cart",

                              style: TextStyle(
                                color:
                                    Colors.white,
                                fontSize: 22,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ],
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
    );
  }

  Widget buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Container(
            width: 8,
            height: 8,

            margin: EdgeInsets.only(top: 8),

            decoration: BoxDecoration(
              color: const Color(0xFF4EA5FF),
              shape: BoxShape.circle,
            ),
          ),

          SizedBox(width: 14),

          Expanded(
            child: Text(
              text,

              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSection(String title) {
    return Container(
      width: double.infinity,

      padding: EdgeInsets.symmetric(
          horizontal: 22, vertical: 22),

      decoration: BoxDecoration(
        color: const Color(0xFF141118),

        borderRadius:
            BorderRadius.circular(22),

        border: Border.all(
          color: Colors.white10,
        ),
      ),

      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,

        children: [

          Text(
            title,

            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),

          Icon(
            Icons.keyboard_arrow_down,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}

//////////////////// 🛒 CART /////////////////////

class CartScreen extends StatefulWidget {
  List<Map<String, dynamic>> cart;

  CartScreen({required this.cart});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  TextEditingController promoController =
      TextEditingController();

  double discount = 0;
  double percent = 0;

  Future<void> updateQuantityFirebase(
    int index,
  ) async {
    var user =
        FirebaseAuth.instance.currentUser;

    if (user == null) return;

    var cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cart');

    var docId = widget.cart[index]['docId'];

    if (docId != null) {
      await cartRef.doc(docId).update({
        "quantity":
            widget.cart[index]["quantity"],
      });
    }
  }

  Future<void> loadCart() async {
    var user =
        FirebaseAuth.instance.currentUser;

    if (user == null) return;

    var snapshot = await FirebaseFirestore
        .instance
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .get();

    setState(() {
      widget.cart = snapshot.docs.map((doc) {
        var data = doc.data();

        data['docId'] = doc.id;

        return data;
      }).toList();
    });
  }

  Future<void> removeFromCartFirebase(
    int index,
  ) async {
    var user =
        FirebaseAuth.instance.currentUser;

    if (user == null) return;

    var cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cart');

    var docId = widget.cart[index]['docId'];

    if (docId != null) {
      await cartRef.doc(docId).delete();
    }
  }

  double getTotalBeforeDiscount() {
    double t = 0;

    for (var item in widget.cart) {
      t +=
          double.parse(
            item["price"].toString(),
          ) *
          (item["quantity"] ?? 1);
    }

    return t;
  }

  double total() {
    return getTotalBeforeDiscount() -
        discount;
  }

  void applyPromo() async {
    var code =
        promoController.text.trim();

    var snapshot = await FirebaseFirestore
        .instance
        .collection('promoCodes')
        .doc(code)
        .get();

    if (snapshot.exists) {
      percent =
          (snapshot['discount'] as num)
              .toDouble();

      double t =
          getTotalBeforeDiscount();

      setState(() {
        discount =
            t * (percent / 100);
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "تم تطبيق خصم $percent%",
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
              Text("كود غير صحيح ❌"),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();

    loadCart();
  }

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth
            .instance.currentUser ==
        null) {
      Future.microtask(() {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                LoginScreen(),
          ),
        );
      });

      return Scaffold(
        body: Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          const Color(0xFF0B0713),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFF0B0713),

        elevation: 0,
        toolbarHeight: 0,
      ),

      body: widget.cart.isEmpty
          ? Center(
              child: Text(
                "Cart is empty",

                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            )
          : ListView(
              padding:
                  EdgeInsets.all(16),

              children: [

Container(
  margin: EdgeInsets.only(bottom: 22),
  padding: EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 10,
  ),

  decoration: BoxDecoration(
    color: const Color(0xFF141118),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: Colors.white10,
    ),
  ),

  child: Row(
    children: [
      Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 50,
            height: 50,

            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF6EA6C1).withOpacity(.18),
            ),

            child: Icon(
              Icons.shopping_cart_outlined,
              color: Color(0xFF6EA6C1),
              size: 30,
            ),
          ),

          Positioned(
            right: -2,
            top: -2,

            child: Container(
              width: 20,
              height: 20,

              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF6EA6C1),
              ),

              child: Center(
                child: Text(
                  "${widget.cart.length}",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      SizedBox(width: 22),

      Container(
        width: 1,
        height: 50,
        color: Colors.white10,
      ),

      SizedBox(width: 12),

      Expanded(
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Text(
              "${widget.cart.length} Item",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 6),

            Text(
              "in your cart",
              style: TextStyle(
                color: Colors.white54,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    ],
  ),
),

                ...List.generate(
                  widget.cart.length,
                  (i) {
                    return Container(
                      margin:
                          EdgeInsets.only(
                        bottom: 16,
                      ),

                      padding:
                          EdgeInsets.all(
                        14,
                      ),

                      decoration:
                          BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(
                          24,
                        ),

                        color:
                            const Color(
                          0xFF141118,
                        ),

                        border:
                            Border.all(
                          color:
                              Colors.white10,
                        ),

                        boxShadow: [
                          BoxShadow(
                            color: Colors
                                .black
                                .withOpacity(
                              0.35,
                            ),

                            blurRadius:
                                20,

                            offset:
                                Offset(
                              0,
                              10,
                            ),
                          ),
                        ],
                      ),

                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                        children: [
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(
                              18,
                            ),

                            child:
                                Image.network(
                              widget.cart[i]
                                  ["image"],

                              width: 110,
                              height: 110,

                              fit: BoxFit
                                  .cover,
                            ),
                          ),

                          SizedBox(
                            width: 14,
                          ),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,

                              children: [
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,

                                  children: [
                                    Expanded(
                                      child:
                                          Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,

                                        children: [
                                          Text(
                                            widget.cart[
                                                    i]
                                                [
                                                "name"],

                                            style:
                                                TextStyle(
                                              color:
                                                  Colors.white,

                                              fontSize:
                                                  24,

                                              fontWeight:
                                                  FontWeight.bold,
                                            ),
                                          ),

                                          SizedBox(
                                            height:
                                                6,
                                          ),

                                          Text(
                                            "${widget.cart[i]["price"]} EGP",

                                            style:
                                                TextStyle(
                                              color:
                                                  Color(
                                                0xFF6EA6C1,
                                              ),

                                              fontSize:
                                                  18,

                                              fontWeight:
                                                  FontWeight.w600,
                                            ),
                                          ),

                                          SizedBox(
                                            height:
                                                5,
                                          ),

                                          Text(
                                            "Size: ${widget.cart[i]["size"]}",

                                            style:
                                                TextStyle(
                                              color:
                                                  Colors.white70,

                                              fontSize:
                                                  16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    IconButton(
                                      onPressed:
                                          () async {
                                        await removeFromCartFirebase(
                                          i,
                                        );

                                        setState(
                                          () {
                                            widget
                                                .cart
                                                .removeAt(
                                              i,
                                            );
                                          },
                                        );

                                        double t =
                                            getTotalBeforeDiscount();

                                        discount =
                                            t *
                                            (percent /
                                                100);
                                      },

                                      icon:
                                          Icon(
                                        Icons
                                            .delete_outline_rounded,

                                        color:
                                            Color(
                                          0xFF6EA6C1,
                                        ),

                                        size:
                                            30,
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(
                                  height: 14,
                                ),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .spaceBetween,

                                  children: [
                                    Container(
                                      decoration:
                                          BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(
                                          14,
                                        ),

                                        border:
                                            Border.all(
                                          color:
                                              Colors.white10,
                                        ),
                                      ),

                                      child:
                                          Row(
                                        children: [
                                          IconButton(
                                            icon:
                                                Icon(
                                              Icons.remove,

                                              color:
                                                  Colors.white,
                                            ),

                                            onPressed:
                                                () async {
                                              if ((widget.cart[i]["quantity"] ??
                                                      1) >
                                                  1) {
                                                setState(
                                                  () {
                                                    widget.cart[i]["quantity"]--;
                                                  },
                                                );

                                                await updateQuantityFirebase(
                                                  i,
                                                );
                                              }
                                            },
                                          ),

                                          Text(
                                            "${widget.cart[i]["quantity"] ?? 1}",

                                            style:
                                                TextStyle(
                                              color:
                                                  Colors.white,

                                              fontWeight:
                                                  FontWeight.bold,

                                              fontSize:
                                                  18,
                                            ),
                                          ),

                                          IconButton(
                                            icon:
                                                Icon(
                                              Icons.add,

                                              color:
                                                  Colors.white,
                                            ),

                                            onPressed:
                                                () async {
                                              setState(
                                                () {
                                                  widget.cart[i]["quantity"]++;
                                                },
                                              );

                                              await updateQuantityFirebase(
                                                i,
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),

                                    Text(
                                      "${(double.parse(widget.cart[i]["price"].toString()) * (widget.cart[i]["quantity"] ?? 1)).toStringAsFixed(0)} EGP",

                                      style:
                                          TextStyle(
                                        color:
                                            Colors.white,

                                        fontSize:
                                            24,

                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                Container(
                  padding:
                      EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),

                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                      0xFF141118,
                    ),

                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),

                    border: Border.all(
                      color:
                          Colors.white10,
                    ),
                  ),

                  child: TextField(
                    controller:
                        promoController,


  textAlignVertical: TextAlignVertical.center,

                    style: TextStyle(
                      color: Colors.white,
                    ),

                    decoration:
                        InputDecoration(
                      border:
                          InputBorder.none,

                      hintText:
                          "Enter Promo Code",

                      hintStyle:
                          TextStyle(
                        color:
                            Colors.white38,
                      ),

                      prefixIcon: Icon(
                        Icons
                            .discount_outlined,

                        color:
                            Colors.white38,
                      ),

                      suffixIcon:
                          TextButton(
                        onPressed:
                            applyPromo,

                        child: Text(
                          "Apply",

                          style:
                              TextStyle(
                            color:
                                Color(
                              0xFF6EA6C1,
                            ),

                            fontWeight:
                                FontWeight.bold,

                            fontSize:
                                18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 18),

                Container(
                  padding:
                      EdgeInsets.all(20),

                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                      0xFF141118,
                    ),

                    borderRadius:
                        BorderRadius.circular(
                      24,
                    ),

                    border: Border.all(
                      color:
                          Colors.white10,
                    ),
                  ),

                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween,

                        children: [
                          Text(
                            "Subtotal",

                            style:
                                TextStyle(
                              color:
                                  Colors.white70,

                              fontSize:
                                  20,
                            ),
                          ),

                          Text(
                            "${getTotalBeforeDiscount().toStringAsFixed(1)} EGP",

                            style:
                                TextStyle(
                              color:
                                  Colors.white70,

                              fontSize:
                                  20,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 12),

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween,

                        children: [
                          Text(
                            "Discount",

                            style:
                                TextStyle(
                              color:
                                  Colors.white70,

                              fontSize:
                                  20,
                            ),
                          ),

                          Text(
                            "- ${discount.toStringAsFixed(1)} EGP",

                            style:
                                TextStyle(
                              color:
                                  Color(
                                0xFF6EA6C1,
                              ),

                              fontSize:
                                  20,

                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      Divider(
                        height: 35,
                        color:
                            Colors.white12,
                      ),

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween,

                        children: [
                          Text(
                            "Total",

                            style:
                                TextStyle(
                              color:
                                  Colors.white,

                              fontSize:
                                  28,

                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          Text(
                            "${total().toStringAsFixed(1)} EGP",

                            style:
                                TextStyle(
                              color:
                                  Color(
                                0xFF6EA6C1,
                              ),

                              fontSize:
                                  32,

                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 22),

                SizedBox(
                  height: 68,
                  width: double.infinity,

                  child:
                      ElevatedButton.icon(
                    onPressed: () {
                      if (widget
                          .cart.isEmpty) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(
                          SnackBar(
                            content: Text(
                              "الكارت فاضي ❌",
                            ),
                          ),
                        );

                        return;
                      }

                      showDialog(
                        context: context,

                        builder:
                            (context) {
                          TextEditingController
                              nameController =
                              TextEditingController();

                          TextEditingController
                              phoneController =
                              TextEditingController();

                          return AlertDialog(
                            backgroundColor:
                                const Color(
                              0xFF141118,
                            ),

                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                20,
                              ),
                            ),

                            title: Text(
                              "Enter your data",

                              style:
                                  TextStyle(
                                color:
                                    Colors.white,
                              ),
                            ),

                            content:
                                Column(
                              mainAxisSize:
                                  MainAxisSize
                                      .min,

                              children: [
                                TextField(
                                  controller:
                                      nameController,

                                  style:
                                      TextStyle(
                                    color:
                                        Colors.white,
                                  ),

                                  decoration:
                                      InputDecoration(
                                    labelText:
                                        "Name",

                                    labelStyle:
                                        TextStyle(
                                      color:
                                          Colors.white70,
                                    ),
                                  ),
                                ),

                                SizedBox(
                                  height: 15,
                                ),

                                TextField(
                                  controller:
                                      phoneController,

                                  style:
                                      TextStyle(
                                    color:
                                        Colors.white,
                                  ),

                                  decoration:
                                      InputDecoration(
                                    labelText:
                                        "Phone",

                                    labelStyle:
                                        TextStyle(
                                      color:
                                          Colors.white70,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            actions: [
                              TextButton(
                                onPressed:
                                    () {
                                  Navigator.pop(
                                    context,
                                  );
                                },

                                child: Text(
                                  "Cancel",

                                  style:
                                      TextStyle(
                                    color:
                                        Colors.white70,
                                  ),
                                ),
                              ),

                              TextButton(
                                onPressed:
                                    () async {
                                  var user =
                                      FirebaseAuth
                                          .instance
                                          .currentUser;

                                  await FirebaseFirestore
                                      .instance
                                      .collection(
                                        'orders',
                                      )
                                      .add({
                                    "userId":
                                        user?.uid,

                                    "name":
                                        nameController
                                            .text
                                            .trim(),

                                    "phone":
                                        phoneController
                                            .text
                                            .trim(),

                                    "items":
                                        widget.cart.map((
                                      item,
                                    ) {
                                      return {
                                        "name":
                                            item["name"],

                                        "price":
                                            item["price"],

                                        "quantity":
                                            item["quantity"] ??
                                                1,

                                        "image":
                                            item["image"],

                                        "size":
                                            item["size"],
                                      };
                                    }).toList(),

                                    "total":
                                        total(),

                                    "status":
                                        "pending",

                                    "orderedAt":
                                        FieldValue.serverTimestamp(),

                                    "deliveredAt":
                                        null,

                                    "orderNumber":
                                        "#ORD-${DateTime.now().millisecondsSinceEpoch}",
                                  });

                                  var cartRef =
                                      FirebaseFirestore
                                          .instance
                                          .collection(
                                            'users',
                                          )
                                          .doc(
                                            user!
                                                .uid,
                                          )
                                          .collection(
                                            'cart',
                                          );

                                  var snapshot =
                                      await cartRef
                                          .get();

                                  for (var doc
                                      in snapshot
                                          .docs) {
                                    await doc
                                        .reference
                                        .delete();
                                  }

                                  setState(() {
                                    widget.cart
                                        .clear();

                                    discount =
                                        0;
                                  });

                                  Navigator.pop(
                                    context,
                                  );

                                  showDialog(
                                    context:
                                        context,

                                    barrierDismissible:
                                        false,

                                    builder:
                                        (
                                          context,
                                        ) {
                                      return Center(
                                        child:
                                            Material(
                                          color: Colors
                                              .transparent,

                                          child:
                                              Container(
                                            width:
                                                MediaQuery.of(
                                                          context,
                                                        )
                                                        .size
                                                        .width *
                                                    0.85,

                                            padding:
                                                EdgeInsets.all(
                                              20,
                                            ),

                                            decoration:
                                                BoxDecoration(
                                              color:
                                                  const Color(
                                                0xFF141118,
                                              ),

                                              borderRadius:
                                                  BorderRadius.circular(
                                                24,
                                              ),
                                            ),

                                            child:
                                                Column(
                                              mainAxisSize:
                                                  MainAxisSize.min,

                                              children: [
                                                Icon(
                                                  Icons
                                                      .check_circle,

                                                  color:
                                                      Color(
                                                    0xFF6EA6C1,
                                                  ),

                                                  size:
                                                      70,
                                                ),

                                                SizedBox(
                                                  height:
                                                      20,
                                                ),

                                                Text(
                                                  "Order Sent",

                                                  style:
                                                      TextStyle(
                                                    color:
                                                        Colors.white,

                                                    fontSize:
                                                        24,

                                                    fontWeight:
                                                        FontWeight.bold,
                                                  ),
                                                ),

                                                SizedBox(
                                                  height:
                                                      12,
                                                ),

                                                Text(
                                                  "سيتم التواصل معك اليوم لتأكيد الأوردر وتحديد مكان الاستلام",

                                                  textAlign:
                                                      TextAlign.center,

                                                  style:
                                                      TextStyle(
                                                    color:
                                                        Colors.white70,

                                                    fontSize:
                                                        16,
                                                  ),
                                                ),

                                                SizedBox(
                                                  height:
                                                      10,
                                                ),

                                                Text(
                                                  "الاستلام يكون خلال يومين 💨",

                                                  textAlign:
                                                      TextAlign.center,

                                                  style:
                                                      TextStyle(
                                                    color:
                                                        Colors.white70,

                                                    fontSize:
                                                        16,
                                                  ),
                                                ),

                                                SizedBox(
                                                  height:
                                                      22,
                                                ),

                                                SizedBox(
                                                  width:
                                                      double.infinity,

                                                  height:
                                                      55,

                                                  child:
                                                      ElevatedButton(
                                                    onPressed:
                                                        () {
                                                      Navigator.pop(
                                                        context,
                                                      );
                                                    },

                                                    style:
                                                        ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          Color(
                                                        0xFF6EA6C1,
                                                      ),

                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                          18,
                                                        ),
                                                      ),
                                                    ),

                                                    child:
                                                        Text(
                                                      "OK",

                                                      style:
                                                          TextStyle(
                                                        color:
                                                            Colors.white,

                                                        fontSize:
                                                            18,

                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },

                                child: Text(
                                  "Confirm",

                                  style:
                                      TextStyle(
                                    color:
                                        Color(
                                      0xFF6EA6C1,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },

                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(
                        0xFF6EA6C1,
                      ),

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          22,
                        ),
                      ),
                    ),

                    icon: Icon(
                      Icons
                          .shopping_bag_outlined,

                      color: Colors.white,
                    ),

                    label: Text(
                      "Place Order",

                      style: TextStyle(
                        color: Colors.white,

                        fontSize: 22,

                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 20),
              ],
            ),
    );
  }

  @override
  void dispose() {
    promoController.dispose();

    super.dispose();
  }
}

///////////////////// ➕ ADD / EDIT /////////////////////

class AddEditProductScreen extends StatefulWidget {
  final String? docId;
  final dynamic oldData;

  AddEditProductScreen({this.docId, this.oldData});

  @override
  State<AddEditProductScreen> createState() =>
      _AddEditProductScreenState();
}

class _AddEditProductScreenState
    extends State<AddEditProductScreen> {

  final name = TextEditingController();
  final price = TextEditingController();
  final description = TextEditingController();
  final deliveryText = TextEditingController();


  List<String> imageUrls = [];

  bool isLoading = false;

  final Color primaryColor = const Color(0xFF6EA6C1);

  @override
  void initState() {
    super.initState();

    if (widget.oldData != null) {

      name.text =
          widget.oldData['name']?.toString() ?? "";

      price.text =
          widget.oldData['price']?.toString() ?? "";

      description.text =
          widget.oldData['description']?.toString() ?? "";

      deliveryText.text =
    widget.oldData['deliveryText']?.toString() ?? "";

      if (widget.oldData['images'] != null) {

        imageUrls =
            List<String>.from(
                widget.oldData['images']);
      }
    }
  }

  ////////////////// IMAGE //////////////////

  Future<void> pickAndUploadImage() async {

    final picker = ImagePicker();

    final XFile? pickedFile =
        await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile == null) return;

    setState(() {
      isLoading = true;
    });

    try {

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
          'https://api.cloudinary.com/v1_1/dzlorraqi/image/upload',
        ),
      );

      request.fields['upload_preset'] = 'Medlife';

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          pickedFile.path,
        ),
      );

      var response = await request.send();

      var responseData =
          await response.stream.bytesToString();

      var data = jsonDecode(responseData);

      if (data['secure_url'] != null) {

        setState(() {

          imageUrls.add(
            data['secure_url'],
          );
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              "Image Uploaded Successfully ✅",
            ),
          ),
        );
      }

    } catch (e) {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "Upload Failed ❌",
          ),
        ),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  ////////////////// SAVE PRODUCT //////////////////

  Future<void> saveProduct() async {

    if (name.text.isEmpty ||
        price.text.isEmpty ||
        description.text.isEmpty ||
        imageUrls.isEmpty ||
deliveryText.text.isEmpty) {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "Please complete all fields",
          ),
        ),
      );

      return;
    }

    var data = {

      "name":
          name.text.trim(),

      "price":
          price.text.trim(),

      "description":
          description.text.trim(),

      "deliveryText":
    deliveryText.text.trim(),

      "images":
          imageUrls,

      "createdAt": Timestamp.now(),
    };

    if (widget.docId == null) {

      await FirebaseFirestore.instance
          .collection('Products')
          .add(data);

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "Product Added ✅",
          ),
        ),
      );

    } else {

      await FirebaseFirestore.instance
          .collection('Products')
          .doc(widget.docId)
          .update(data);

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "Product Updated ✅",
          ),
        ),
      );
    }

    Navigator.pop(context);
  }

  ////////////////// UI //////////////////

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
          const Color(0xFF0B0713),

      appBar: AppBar(

        backgroundColor:
            Colors.transparent,

        elevation: 0,

        title: Text(

          widget.docId == null
              ? "Add Product"
              : "Edit Product",

          style: TextStyle(
            color: Colors.white,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(

        padding: EdgeInsets.all(20),

        child: Column(

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            ////////////////// PRODUCT NAME //////////////////

            buildLabel("Product Name"),

            SizedBox(height: 10),

            buildTextField(
              controller: name,
              hint:
                  "Enter product name",
              icon:
                  Icons.shopping_bag_outlined,
            ),

            SizedBox(height: 22),

            ////////////////// PRICE //////////////////

            buildLabel("Price (EGP)"),

            SizedBox(height: 10),

            buildTextField(
              controller: price,
              hint:
                  "Enter product price",
              icon:
                  Icons.local_offer_outlined,
              keyboard:
                  TextInputType.number,
            ),

            SizedBox(height: 25),

            ////////////////// IMAGE //////////////////

            GestureDetector(

              onTap:
                  pickAndUploadImage,

              child: Container(

                width: double.infinity,

                padding:
                    EdgeInsets.symmetric(
                  vertical: 35,
                ),

                decoration:
                    BoxDecoration(

                  color:
                      Colors.white
                          .withOpacity(
                              0.03),

                  borderRadius:
                      BorderRadius
                          .circular(
                              24),

                  border: Border.all(
                    color: primaryColor
                        .withOpacity(
                            0.5),
                    width: 1.2,
                  ),
                ),

                child: Column(

                  children: [

                    Container(

                      padding:
                          EdgeInsets.all(
                              18),

                      decoration:
                          BoxDecoration(

                        shape:
                            BoxShape.circle,

                        color: primaryColor
                            .withOpacity(
                                0.12),
                      ),

                      child: Icon(
                        Icons
                            .cloud_upload_outlined,

                        color:
                            primaryColor,

                        size: 34,
                      ),
                    ),

                    SizedBox(height: 18),

                    Text(

                      "Upload Product Image",

                      style: TextStyle(
                        color:
                            primaryColor,
                        fontSize: 18,
                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),

                    SizedBox(height: 8),

                    Text(

                      "JPG, PNG up to 5MB",

                      style: TextStyle(
                        color:
                            Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            ////////////////// LOADING //////////////////

            if (isLoading)
              Center(
                child:
                    CircularProgressIndicator(
                  color:
                      primaryColor,
                ),
              ),

            ////////////////// IMAGES //////////////////

            Wrap(

              spacing: 12,
              runSpacing: 12,

              children:
                  imageUrls.map((url) {

                return Stack(

                  children: [

                    ClipRRect(

                      borderRadius:
                          BorderRadius
                              .circular(
                                  18),

                      child:
                          Image.network(

                        url,

                        width: 110,
                        height: 110,

                        fit:
                            BoxFit.cover,
                      ),
                    ),

                    Positioned(

                      top: 5,
                      right: 5,

                      child:
                          GestureDetector(

                        onTap: () {

                          setState(() {

                            imageUrls
                                .remove(
                                    url);
                          });
                        },

                        child:
                            Container(

                          padding:
                              EdgeInsets
                                  .all(5),

                          decoration:
                              BoxDecoration(

                            color:
                                Colors.red,

                            shape:
                                BoxShape
                                    .circle,
                          ),

                          child: Icon(

                            Icons.close,

                            color:
                                Colors.white,

                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),

            SizedBox(height: 28),

            ////////////////// DESCRIPTION //////////////////

            buildLabel("Description"),

            SizedBox(height: 10),

            Container(

              decoration:
                  BoxDecoration(

                color:
                    Colors.white
                        .withOpacity(
                            0.03),

                borderRadius:
                    BorderRadius
                        .circular(22),

                border: Border.all(
                  color:
                      Colors.white10,
                ),
              ),

              child: TextField(

                controller:
                    description,

                maxLines: 6,
                maxLength: 500,

                style: TextStyle(
                  color:
                      Colors.white,
                ),

                decoration:
                    InputDecoration(

                  border:
                      InputBorder.none,

                  contentPadding:
                      EdgeInsets.all(
                          20),

                  hintText:
                      "Enter product description",

                  hintStyle:
                      TextStyle(
                    color:
                        Colors.white38,
                  ),

                  prefixIcon:
                      Padding(

                    padding:
                        EdgeInsets.only(
                            bottom: 95),

                    child: Icon(
                      Icons
                          .description_outlined,

                      color:
                          primaryColor,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 24),

           ////////////////// DELIVERY INFO //////////////////

buildLabel("Delivery Info"),

SizedBox(height: 10),

buildTextField(

  controller: deliveryText,

  hint: "ُEnter Delivery Duration",

  icon: Icons.local_shipping_outlined,
),

SizedBox(height: 18),

            ////////////////// INFO BOX //////////////////

            Container(

              width: double.infinity,

              padding:
                  EdgeInsets.all(16),

              decoration:
                  BoxDecoration(

                color:
                    Colors.white
                        .withOpacity(
                            0.04),

                borderRadius:
                    BorderRadius
                        .circular(18),
              ),

              child: Row(

                children: [

                  Icon(
                    Icons.info_outline,
                    color:
                        primaryColor,
                  ),

                  SizedBox(width: 12),

                  Expanded(

                    child: Text(

                      "Customers will see this date as the estimated delivery time",

                      style: TextStyle(
                        color:
                            Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 35),

            ////////////////// BUTTON //////////////////

            SizedBox(

              width: double.infinity,
              height: 62,

              child: ElevatedButton(

                onPressed:
                    saveProduct,

                style:
                    ElevatedButton
                        .styleFrom(

                  backgroundColor:
                      primaryColor,

                  shape:
                      RoundedRectangleBorder(

                    borderRadius:
                        BorderRadius
                            .circular(
                                22),
                  ),
                ),

                child: Text(

                  widget.docId == null
                      ? "Add Product"
                      : "Update Product",

                  style: TextStyle(

                    color:
                        Colors.white,

                    fontSize: 20,

                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),

            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  ////////////////// REUSABLE //////////////////

  Widget buildLabel(String text) {

    return Text(

      text,

      style: TextStyle(
        color: Colors.white70,
        fontSize: 18,
        fontWeight:
            FontWeight.w500,
      ),
    );
  }

  Widget buildTextField({

    required TextEditingController controller,

    required String hint,

    required IconData icon,

    TextInputType keyboard =
        TextInputType.text,

  }) {

    return Container(

      decoration: BoxDecoration(

        color:
            Colors.white.withOpacity(
                0.03),

        borderRadius:
            BorderRadius.circular(
                20),

        border: Border.all(
          color: Colors.white10,
        ),
      ),

      child: TextField(

        controller: controller,

        keyboardType: keyboard,

        style: TextStyle(
          color: Colors.white,
        ),

        decoration: InputDecoration(

          border: InputBorder.none,

          contentPadding:
              EdgeInsets.symmetric(
            vertical: 22,
          ),

          hintText: hint,

          hintStyle: TextStyle(
            color: Colors.white38,
          ),

          prefixIcon: Container(

            margin: EdgeInsets.all(10),

            decoration: BoxDecoration(

              color:
                  primaryColor
                      .withOpacity(
                          0.12),

              borderRadius:
                  BorderRadius
                      .circular(
                          14),
            ),

            child: Icon(
              icon,
              color:
                  primaryColor,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {

    name.dispose();
    price.dispose();
    description.dispose();
    deliveryText.dispose();

    super.dispose();
  }
}

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() =>
      _AdminOrdersScreenState();
}

class _AdminOrdersScreenState
    extends State<AdminOrdersScreen> {

      String selectedFilter = 'Newest First';
      String selectedStatus = 'All';
      bool isSearching = false;

String searchQuery = '';

TextEditingController searchController =
    TextEditingController();

  @override
  Widget build(BuildContext context) {
    final bool isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Scaffold(
      backgroundColor: const Color(0xFF07070A),

      appBar: AppBar(
        backgroundColor: const Color(0xFF07070A),
        elevation: 0,

        title: isSearching

    ? TextField(

        controller: searchController,

        onChanged: (value) {

          setState(() {

            searchQuery = value;

          });
        },

        style: const TextStyle(
          color: Colors.white,
        ),

        decoration: const InputDecoration(

          hintText:
              'Search by ID, name or phone...',

          hintStyle: TextStyle(
            color: Colors.white54,
          ),

          border: InputBorder.none,
        ),
      )

    : const Text(

        "Admin Dashboard",

        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),

        iconTheme:
            const IconThemeData(color: Colors.white),

        actions: [
          IconButton(

  onPressed: () {

    setState(() {

      if (isSearching) {

        isSearching = false;

        searchQuery = '';

        searchController.clear();

      } else {

        isSearching = true;
      }
    });
  },

  icon: Icon(

    isSearching
        ? Icons.close
        : Icons.search,

    size: 26,
  ),
),

          PopupMenuButton<String>(
  icon: const Icon(
    Icons.filter_list_rounded,
    size: 26,
    color: Colors.white,
  ),

  onSelected: (value) {
    setState(() {
      selectedFilter = value;
    });
  },

  itemBuilder: (context) => [

    const PopupMenuItem(
      value: 'Newest First',
      child: Text('Newest First'),
    ),

    const PopupMenuItem(
      value: 'Oldest First',
      child: Text('Oldest First'),
    ),

    const PopupMenuItem(
      value: 'Highest Price',
      child: Text('Highest Price'),
    ),

    const PopupMenuItem(
      value: 'Lowest Price',
      child: Text('Lowest Price'),
    ),
  ],
),

          const SizedBox(width: 6),
        ],
      ),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance
    .collection('orders')
    .orderBy(
      'orderedAt',
      descending: true,
    )
    .snapshots(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          var orders = snapshot.data!.docs;

          List sortedOrders = List.from(orders);

          if (selectedStatus != 'All') {

  sortedOrders = sortedOrders.where((order) {

    String status =
        (order['status'] ?? '')
            .toString()
            .toLowerCase();

    return status ==
        selectedStatus.toLowerCase();

  }).toList();
}

if (searchQuery.isNotEmpty) {

  sortedOrders =
      sortedOrders.where((order) {

    final data =
        order.data()
            as Map<String, dynamic>;

    String name =
        (data['name'] ?? '')
            .toString()
            .toLowerCase();

    String phone =
        (data['phone'] ?? '')
            .toString()
            .toLowerCase();

    String id =
    order.id
        .substring(0, 6)
        .toLowerCase();

    String query =
        searchQuery.toLowerCase();

    return name.contains(query) ||

        phone.contains(query) ||

        id.contains(query);

  }).toList();
}

if (selectedFilter == 'Oldest First') {

  sortedOrders = orders.reversed.toList();

} else if (selectedFilter ==
    'Highest Price') {

  sortedOrders.sort((a, b) {

    double aTotal =
        (a['total'] ?? 0).toDouble();

    double bTotal =
        (b['total'] ?? 0).toDouble();

    return bTotal.compareTo(aTotal);
  });

} else if (selectedFilter ==
    'Lowest Price') {

  sortedOrders.sort((a, b) {

    double aTotal =
        (a['total'] ?? 0).toDouble();

    double bTotal =
        (b['total'] ?? 0).toDouble();

    return aTotal.compareTo(bTotal);
  });
}


          if (orders.isEmpty) {

  return const Center(
    child: Text(
      "No Orders Yet",

      style: TextStyle(
        color: Colors.white,
      ),
    ),
  );
}

if (sortedOrders.isEmpty) {

  return const Center(
    child: Text(
      "No Orders Found!",

      style: TextStyle(
        color: Colors.white70,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

          int totalOrders = orders.length;

          int deliveredCount = orders
              .where(
                (e) =>
                    (e['status'] ?? '') ==
                    'delivered',
              )
              .length;

          int pendingCount = orders
              .where(
                (e) =>
                    (e['status'] ?? '') ==
                    'pending',
              )
              .length;

          int processingCount = orders
              .where(
                (e) =>
                    (e['status'] ?? '') ==
                    'processing',
              )
              .length;

          return ListView(
            padding:
                const EdgeInsets.all(16),

            children: [
              /// STATS
              Row(
                children: [
                  Expanded(
                    child: dashboardStat(
                      icon:
                          Icons.shopping_bag_outlined,

                      title: "Total Orders",

                      value:
                          totalOrders.toString(),

                      color:
                          const Color(
                            0xFF3B82F6,
                          ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: dashboardStat(
                      icon:
                          Icons.access_time,

                      title: "Pending",

                      value:
                          pendingCount.toString(),

                      color:
                          Colors.orange,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: dashboardStat(
                      icon:
                          Icons.local_shipping_outlined,

                      title: "Processing",

                      value:
                          processingCount
                              .toString(),

                      color:
                          Colors.purpleAccent,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: dashboardStat(
                      icon:
                          Icons.check_circle_outline,

                      title: "Delivered",

                      value:
                          deliveredCount
                              .toString(),

                      color:
                          Colors.green,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              const Text(
                "Recent Orders",

                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 18),

SingleChildScrollView(
  scrollDirection: Axis.horizontal,

  child: Row(
    children: [

      statusChip('All'),
      statusChip('Pending'),
      statusChip('Processing'),
      statusChip('Delivered'),

    ],
  ),
),

const SizedBox(height: 20),

              ...List.generate(
                sortedOrders.length,
                (i) {
                  var order = sortedOrders[i];

                  final data =
                      order.data()
                          as Map<
                            String,
                            dynamic
                          >;

                  List items =
    data['items'] ?? [];

int totalQuantity = 0;

for (var item in items) {

  totalQuantity +=
      ((item['quantity'] ?? 1) as num).toInt();
}

String status =
    data['status'] ??
        'pending';

                  Color statusColor =
                      status == 'delivered'
                          ? Colors.green
                          : status ==
                              'processing'
                          ? Colors.purpleAccent
                          : Colors.orange;

                  Timestamp? orderedAt =
                      data['orderedAt'];

                  String orderedDate =
                      orderedAt != null
                          ? DateFormat(
                            'MMM dd, yyyy • hh:mm a',
                          ).format(
                            orderedAt
                                .toDate(),
                          )
                          : '';

                  return Container(
                    margin:
                        const EdgeInsets.only(
                          bottom: 18,
                        ),

                    padding:
                        const EdgeInsets.all(
                          16,
                        ),

                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(
                            28,
                          ),

                      gradient:
                          const LinearGradient(
                            colors: [
                              Color(
                                0xFF15121A,
                              ),
                              Color(
                                0xFF0C0B10,
                              ),
                            ],

                            begin:
                                Alignment
                                    .topLeft,

                            end: Alignment
                                .bottomRight,
                          ),

                      border: Border.all(
                        color: Colors.white
                            .withOpacity(
                              0.05,
                            ),
                      ),
                    ),

                    child: Column(
                      children: [
                        /// TOP
Row(
  crossAxisAlignment: CrossAxisAlignment.start,

  children: [

    /// ORDER INFO
    SizedBox(
      width: 120,

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Text(
            "ORDER NUM: ${(sortedOrders.length - i).toString().padLeft(4, '0')}",

            maxLines: 1,
            overflow: TextOverflow.ellipsis,

            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            "ID: ${order.id.substring(0, 6)}",

            maxLines: 1,
            overflow: TextOverflow.ellipsis,

            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),

    const Spacer(),

    Padding(
  padding: const EdgeInsets.only(right: 15),

  child: Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 6,
    ),

    decoration: BoxDecoration(
      borderRadius:
          BorderRadius.circular(12),

      color: statusColor.withOpacity(
        0.18,
      ),
    ),

    child: Text(
      status.toUpperCase(),

      style: TextStyle(
        color: statusColor,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    ),
  ),
),

    const Spacer(),

    SizedBox(
  width: 100,

  child: Column(
    crossAxisAlignment:
        CrossAxisAlignment.center,

    children: [

      Text(
        DateFormat(
          'MMM dd, yyyy',
        ).format(
          orderedAt!.toDate(),
        ),

        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,

        style: const TextStyle(
          color: Colors.white54,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),

      const SizedBox(height: 2),

      Text(
        DateFormat(
          'hh:mm a',
        ).format(
          orderedAt.toDate(),
        ),

        textAlign: TextAlign.center,

        style: const TextStyle(
          color: Colors.white38,
          fontSize: 15,
        ),
      ),
    ],
  ),
),
  ],
),

                        const SizedBox(height: 18),

                        /// USER INFO
                        Row(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,

                          children: [
                            CircleAvatar(
                              radius: 28,

                              backgroundColor:
                                  Colors.white12,

                              child: Text(
                                data['name'] !=
                                            null &&
                                        data['name']
                                            .toString()
                                            .isNotEmpty
                                    ? data['name'][0]
                                    : "U",

                                style:
                                    const TextStyle(
                                      color:
                                          Colors
                                              .white,

                                      fontWeight:
                                          FontWeight
                                              .bold,

                                      fontSize:
                                          22,
                                    ),
                              ),
                            ),

                            const SizedBox(
                              width: 14,
                            ),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,

                                children: [
                                  Text(
                                    data['name'] ??
                                        "No Name",

                                    style:
                                        const TextStyle(
                                          color:
                                              Colors
                                                  .white,

                                          fontSize:
                                              20,

                                          fontWeight:
                                              FontWeight
                                                  .w700,
                                        ),
                                  ),

                                  const SizedBox(
                                    height: 5,
                                  ),

                                  Text(
                                    data['phone'] ??
                                        "",

                                    style:
                                        const TextStyle(
                                          color:
                                              Colors
                                                  .white60,

                                          fontSize:
                                              14,
                                        ),
                                  ),

                                  const SizedBox(
                                    height: 14,
                                  ),

                                  SizedBox(
  height: 25,

  child: Row(
    children: [

      ...List.generate(

        items.length > 3 ? 3 : items.length,

        (index) {

          var item = items[index];

          return Container(
            width: 25,
            height: 25,

            margin: const EdgeInsets.only(
              right: 5,
            ),

            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(
                    10,
                  ),

              color: Colors.white10,
            ),

            child:
                item['image'] != null &&
                        item['image']
                            .toString()
                            .isNotEmpty
                    ? ClipRRect(
                      borderRadius:
                          BorderRadius.circular(
                            16,
                          ),

                      child:
                          Image.network(
                        item['image'],

                        fit:
                            BoxFit.cover,
                      ),
                    )
                    : const Icon(
                      Icons.image,
                      color:
                          Colors.white38,
                    ),
          );
        },
      ),

      if (items.length > 3)

        Container(
          width: 25,
          height: 25,

          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(
                  16,
                ),

            color: Colors.white10,
          ),

          child: Center(
            child: Text(
              "+${items.length - 3}",

              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight:
                    FontWeight.bold,
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

                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .end,

                              children: [
                                const Text(
                                  "Total Amount",

                                  style:
                                      TextStyle(
                                        color:
                                            Colors
                                                .white54,

                                        fontSize:
                                            14,
                                      ),
                                ),

                                const SizedBox(
                                  height: 6,
                                ),

                                Text(
                                  "${data['total'] ?? 0} EGP",

                                  style:
                                      const TextStyle(
                                        color:
                                            Colors
                                                .white,

                                        fontSize:
                                            26,

                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
                                ),

                                const SizedBox(
                                  height: 4,
                                ),

                                Text(
                                  "$totalQuantity Items",

                                  style:
                                      const TextStyle(
                                        color:
                                            Colors
                                                .white54,

                                        fontSize:
                                            13,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        /// BUTTONS
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,

                                    MaterialPageRoute(
                                      builder:
                                          (_) =>
                                              OrderDetailsScreen(
                                                order:
                                                    order,
                                              ),
                                    ),
                                  );
                                },

                                child: Container(
                                  height: 52,

                                  decoration:
                                      BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(
                                              16,
                                            ),

                                        border: Border.all(
                                          color:
                                              const Color(
                                                0xFF3B82F6,
                                              ),
                                        ),
                                      ),

                                  child:
                                      const Center(
                                        child: Text(
                                          "View Details",

                                          style:
                                              TextStyle(
                                                color:
                                                    Color(
                                                      0xFF3B82F6,
                                                    ),

                                                fontWeight:
                                                    FontWeight.bold,

                                                fontSize:
                                                    15,
                                              ),
                                        ),
                                      ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            GestureDetector(
                              onTap: () async {

  String newStatus = 'pending';

  if (status == 'pending') {

    newStatus = 'processing';

  } else if (status == 'processing') {

    newStatus = 'delivered';

  } else {

    newStatus = 'pending';
  }

  await FirebaseFirestore.instance
      .collection('orders')
      .doc(order.id)
      .update({

    "status": newStatus,

    if (newStatus == 'delivered')
      "deliveredAt":
          FieldValue.serverTimestamp(),
  });
},
                              child: Container(
                                width: 56,
                                height: 52,

                                decoration:
                                    BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(
                                            16,
                                          ),

                                      gradient:
                                          const LinearGradient(
                                            colors: [
                                              Color(
                                                0xFF3B82F6,
                                              ),
                                              Color(
                                                0xFF6CB7FF,
                                              ),
                                            ],
                                          ),
                                    ),

                                child: const Icon(
                                  Icons
                                      .local_shipping_outlined,

                                  color:
                                      Colors
                                          .white,
                                ),
                              ),
                            ),

                            const SizedBox(width: 10),

                            GestureDetector(
                              onTap: () async {
                                await FirebaseFirestore
                                    .instance
                                    .collection(
                                      'orders',
                                    )
                                    .doc(order.id)
                                    .delete();
                              },

                              child: Container(
                                width: 56,
                                height: 52,

                                decoration:
                                    BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(
                                            16,
                                          ),

                                      color:
                                          Colors.red
                                              .withOpacity(
                                                0.12,
                                              ),
                                    ),

                                child: const Icon(
                                  Icons
                                      .delete_outline,

                                  color:
                                      Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

Widget statusChip(String title) {

  bool isSelected =
      selectedStatus == title;

  return GestureDetector(

    onTap: () {

      setState(() {

        selectedStatus = title;

      });
    },

    child: Container(

      margin: const EdgeInsets.only(
        right: 10,
      ),

      padding:
          const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 10,
      ),

      decoration: BoxDecoration(

        borderRadius:
            BorderRadius.circular(30),

        color: isSelected
            ? Colors.white
            : Colors.white.withOpacity(
                0.05,
              ),

        border: Border.all(

          color: isSelected
              ? Colors.white
              : Colors.white12,
        ),
      ),

      child: Text(

        title,

        style: TextStyle(

          color: isSelected
              ? Colors.black
              : Colors.white70,

          fontWeight:
              FontWeight.w600,

          fontSize: 14,
        ),
      ),
    ),
  );
}

  Widget dashboardStat({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      height: 140,

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),

        gradient: const LinearGradient(
          colors: [
            Color(0xFF15121A),
            Color(0xFF0D0B10),
          ],

          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

        border: Border.all(
          color: Colors.white.withOpacity(
            0.05,
          ),
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Container(
            width: 42,
            height: 42,

            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(14),

              color: color.withOpacity(0.12),
            ),

            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),

          const Spacer(),

          Text(
            title,

            style: const TextStyle(
              color: Colors.white60,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            value,

            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class OrderDetailsScreen extends StatelessWidget {

  final dynamic order;

  const OrderDetailsScreen({
    super.key,
    required this.order,
  });

  Future<void> callCustomer(String phone) async {

  final Uri phoneUri = Uri(
    scheme: 'tel',
    path: phone,
  );

  if (await canLaunchUrl(phoneUri)) {

    await launchUrl(phoneUri);

  } else {

    throw 'Could not launch phone';
  }
}

Future<void> chatCustomer(String phone) async {

  String cleanedPhone =
      phone.replaceAll(RegExp(r'[^0-9]'), '');

  if (cleanedPhone.startsWith('0')) {

    cleanedPhone =
        '20${cleanedPhone.substring(1)}';
  }

  final Uri whatsappUri = Uri.parse(
    "https://wa.me/$cleanedPhone",
  );

  if (await canLaunchUrl(whatsappUri)) {

    await launchUrl(
      whatsappUri,
      mode:
          LaunchMode.externalApplication,
    );

  } else {

    throw 'Could not launch WhatsApp';
  }
}

  double parseToDouble(dynamic value) {

    if (value == null) return 0;

    return double.tryParse(
          value.toString(),
        ) ??
        0;
  }

  int parseToInt(dynamic value) {

    if (value == null) return 0;

    return int.tryParse(
          value.toString(),
        ) ??
        0;
  }

  @override
  Widget build(BuildContext context) {

    final data =
        order.data()
            as Map<String, dynamic>;

    List items =
        data['items'] ?? [];

    String customerName =
        data['name'] ??
            'Unknown';

    String phone =
        data['phone'] ??
            '';

    String address =
        data['address'] ??
            'No Address';

    double total =
        parseToDouble(
          data['total'],
        );

    double shipping =
        parseToDouble(
          data['shipping'],
        );

    double discount =
        parseToDouble(
          data['discount'],
        );

    Timestamp? orderedAt =
        data['orderedAt'];

    String orderedDate =
        orderedAt != null
            ? DateFormat(
                'MMM dd, yyyy',
              ).format(
                orderedAt.toDate(),
              )
            : '';

    String orderedTime =
        orderedAt != null
            ? DateFormat(
                'hh:mm a',
              ).format(
                orderedAt.toDate(),
              )
            : '';

    String orderId =
        order.id.length >= 6
            ? order.id.substring(
                0,
                6,
              )
            : order.id;

    double subtotal = 0;

    for (var item in items) {

      double price =
          parseToDouble(
            item['price'],
          );

      int quantity =
          parseToInt(
            item['quantity'],
          );

      subtotal +=
          (price * quantity);
    }

    return Scaffold(

      backgroundColor:
          const Color(
        0xFF05070D,
      ),

      appBar: AppBar(

        elevation: 0,

        backgroundColor:
            const Color(
          0xFF05070D,
        ),

        iconTheme:
            const IconThemeData(
          color: Colors.white,
        ),

        title: const Text(

          "Order Details",

          style: TextStyle(

            color:
                Colors.white,

            fontSize: 24,

            fontWeight:
                FontWeight.bold,
          ),
        ),

        actions: [

          IconButton(

            onPressed: () async {

  await Printing.layoutPdf(

    onLayout: (format) async {

      final pdf = pw.Document();

      final image = await imageFromAssetBundle(
        'assets/1.png',
      );

      pdf.addPage(

        pw.MultiPage(

          pageFormat: PdfPageFormat.a4,

          build: (context) => [

            /// TOP IMAGE
            pw.Container(

              height: 180,

              decoration: pw.BoxDecoration(

                borderRadius:
                    pw.BorderRadius.circular(20),

                image: pw.DecorationImage(
                  image: image,
                  fit: pw.BoxFit.cover,
                ),
              ),
            ),

            pw.SizedBox(height: 20),

            /// ORDER INFO
            pw.Text(

              "Order ID: $orderId",

              style: pw.TextStyle(

                fontSize: 24,
                fontWeight:
                    pw.FontWeight.bold,
              ),
            ),

            pw.SizedBox(height: 10),

            pw.Text(
              "$orderedDate • $orderedTime",
            ),

            pw.SizedBox(height: 25),

            /// CUSTOMER INFO
            pw.Text(

              "Customer Information",

              style: pw.TextStyle(

                fontSize: 20,
                fontWeight:
                    pw.FontWeight.bold,
              ),
            ),

            pw.SizedBox(height: 10),

            pw.Text(
              "Name: $customerName",
            ),

            pw.Text(
              "Phone: $phone",
            ),

            pw.SizedBox(height: 25),

            /// ITEMS
            pw.Text(

              "Order Items",

              style: pw.TextStyle(

                fontSize: 20,
                fontWeight:
                    pw.FontWeight.bold,
              ),
            ),

            pw.SizedBox(height: 15),

            ...items.map((item) {

              double price =
                  double.tryParse(
                        item['price']
                            .toString(),
                      ) ??
                      0;

              int quantity =
                  int.tryParse(
                        item['quantity']
                            .toString(),
                      ) ??
                      1;

              double totalPrice =
                  price * quantity;

              return pw.Container(

                margin:
                    const pw.EdgeInsets.only(
                  bottom: 12,
                ),

                padding:
                    const pw.EdgeInsets.all(12),

                decoration:
                    pw.BoxDecoration(

                  border: pw.Border.all(
                    color: PdfColors.grey300,
                  ),

                  borderRadius:
                      pw.BorderRadius.circular(
                    12,
                  ),
                ),

                child: pw.Row(

                  mainAxisAlignment:
                      pw.MainAxisAlignment
                          .spaceBetween,

                  children: [

                    pw.Column(

                      crossAxisAlignment:
                          pw.CrossAxisAlignment
                              .start,

                      children: [

                        pw.Text(

                          item['name'] ?? '',

                          style: pw.TextStyle(
                            fontWeight:
                                pw.FontWeight
                                    .bold,
                          ),
                        ),

                        pw.SizedBox(height: 5),

                        pw.Text(
                          "Size: ${item['size'] ?? 'N/A'}",
                        ),

                        pw.Text(
                          "$price EGP",
                        ),
                      ],
                    ),

                    pw.Column(

                      crossAxisAlignment:
                          pw.CrossAxisAlignment
                              .end,

                      children: [

                        pw.Text(
                          "x$quantity",
                        ),

                        pw.SizedBox(height: 5),

                        pw.Text(
                          "$totalPrice EGP",
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),

            pw.SizedBox(height: 20),

            /// TOTALS
            pw.Row(

              mainAxisAlignment:
                  pw.MainAxisAlignment
                      .spaceBetween,

              children: [

                pw.Text("Subtotal"),

                pw.Text(
                  "$subtotal EGP",
                ),
              ],
            ),

            pw.SizedBox(height: 8),

            pw.Row(

              mainAxisAlignment:
                  pw.MainAxisAlignment
                      .spaceBetween,

              children: [

                pw.Text("Shipping"),

                pw.Text(
                  "$shipping EGP",
                ),
              ],
            ),

            pw.SizedBox(height: 8),

            pw.Row(

              mainAxisAlignment:
                  pw.MainAxisAlignment
                      .spaceBetween,

              children: [

                pw.Text("Discount"),

                pw.Text(
                  "-$discount EGP",
                ),
              ],
            ),

            pw.Divider(),

            pw.Row(

              mainAxisAlignment:
                  pw.MainAxisAlignment
                      .spaceBetween,

              children: [

                pw.Text(

                  "Total Amount",

                  style: pw.TextStyle(
                    fontWeight:
                        pw.FontWeight.bold,
                    fontSize: 18,
                  ),
                ),

                pw.Text(

                  "$total EGP",

                  style: pw.TextStyle(
                    fontWeight:
                        pw.FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 25),

            /// ADDRESS
            pw.Text(

              "Shipping Address",

              style: pw.TextStyle(

                fontSize: 20,
                fontWeight:
                    pw.FontWeight.bold,
              ),
            ),

            pw.SizedBox(height: 10),

            pw.Text(address),
          ],
        ),
      );

      return pdf.save();
    },
  );
},

            icon: const Icon(
              Icons.print_outlined,
              color: Colors.white,
            ),
          ),
        ],
      ),

      body: ListView(

        padding:
            const EdgeInsets.all(
          16,
        ),

        children: [

          /// TOP BANNER
          Container(

            height: 185,

            decoration:
                BoxDecoration(

              borderRadius:
                  BorderRadius
                      .circular(
                30,
              ),

              image:
                  const DecorationImage(

                image: AssetImage(
                  "assets/1.png",
                ),

                fit: BoxFit.cover,
              ),

              boxShadow: [

                BoxShadow(

                  color: const Color(
                    0xFF6EA6C1,
                  ).withOpacity(
                    0.15,
                  ),

                  blurRadius: 30,

                  spreadRadius: 1,
                ),
              ],

              border: Border.all(

                color: Colors.white
                    .withOpacity(
                  0.06,
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          /// ORDER ID
          buildCard(

            child: Column(

              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

              children: [

                Row(

                  children: [

                    Expanded(

                      child: Text(

                        "Order ID: $orderId",

                        style:
                            const TextStyle(

                          color:
                              Colors
                                  .white,

                          fontSize:
                              22,

                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
                      ),
                    ),

                    GestureDetector(

                      onTap: () {

                        Clipboard.setData(

                          ClipboardData(
                            text:
                                orderId,
                          ),
                        );

                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(

                          const SnackBar(

                            content: Text(
                              "Order ID Copied",
                            ),
                          ),
                        );
                      },

                      child:
                          const Icon(

                        Icons
                            .copy_rounded,

                        color:
                            Colors
                                .white54,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 14,
                ),

                Row(

                  children: [

                    const Icon(

                      Icons
                          .calendar_month_rounded,

                      color:
                          Colors
                              .white54,

                      size: 18,
                    ),

                    const SizedBox(
                      width: 8,
                    ),

                    Text(

                      orderedDate,

                      style:
                          const TextStyle(

                        color:
                            Colors
                                .white70,

                        fontSize:
                            15,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 8,
                ),

                Padding(

                  padding:
                      const EdgeInsets.only(
                    left: 26,
                  ),

                  child: Text(

                    orderedTime,

                    style:
                        const TextStyle(

                      color:
                          Colors
                              .white54,

                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          /// CUSTOMER INFO
          buildCard(

            child: Column(

              children: [

                Row(

                  children: const [

                    CircleAvatar(

                      radius: 18,

                      backgroundColor:
                          Color(
                        0x226EA6C1,
                      ),

                      child: Icon(

                        Icons.person,

                        color: Color(
                          0xFF6EA6C1,
                        ),
                      ),
                    ),

                    SizedBox(
                      width: 12,
                    ),

                    Text(

                      "Customer Information",

                      style:
                          TextStyle(

                        color:
                            Colors
                                .white,

                        fontSize:
                            18,

                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 22,
                ),

                Row(

                  children: [

                    CircleAvatar(

                      radius: 34,

                      backgroundColor:
                          Colors
                              .white10,

                      child: Text(

                        customerName
                                .isNotEmpty
                            ? customerName[0]
                                .toUpperCase()
                            : "U",

                        style:
                            const TextStyle(

                          color:
                              Colors
                                  .white,

                          fontSize:
                              30,

                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
                      ),
                    ),

                    const SizedBox(
                      width: 18,
                    ),

                    Expanded(

                      child: Column(

                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                        children: [

                          Text(

                            customerName,

                            style:
                                const TextStyle(

                              color:
                                  Colors
                                      .white,

                              fontSize:
                                  22,

                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),

                          const SizedBox(
                            height: 10,
                          ),

                          Row(

                            children: [

                              const Icon(

                                Icons.phone,

                                color:
                                    Color(
                                  0xFF6EA6C1,
                                ),

                                size: 18,
                              ),

                              const SizedBox(
                                width: 8,
                              ),

                              Text(

                                phone,

                                style:
                                    const TextStyle(

                                  color:
                                      Colors
                                          .white70,

                                  fontSize:
                                      16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          /// ORDER ITEMS
          buildCard(

            child: Column(

              children: [

                Row(

                  children: const [

                    CircleAvatar(

                      radius: 18,

                      backgroundColor:
                          Color(
                        0x226EA6C1,
                      ),

                      child: Icon(

                        Icons
                            .shopping_bag_outlined,

                        color: Color(
                          0xFF6EA6C1,
                        ),
                      ),
                    ),

                    SizedBox(
                      width: 12,
                    ),

                    Text(

                      "Order Items",

                      style:
                          TextStyle(

                        color:
                            Colors
                                .white,

                        fontSize:
                            18,

                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 18,
                ),

                ...List.generate(
                  items.length,
                  (index) {

                    var item =
                        items[index];

                    double price =
                        parseToDouble(
                      item['price'],
                    );

                    int quantity =
                        parseToInt(
                      item['quantity'],
                    );

                    double totalPrice =
                        price *
                            quantity;

                    return Container(

                      margin:
                          const EdgeInsets.only(
                        bottom: 14,
                      ),

                      padding:
                          const EdgeInsets.all(
                        12,
                      ),

                      decoration:
                          BoxDecoration(

                        borderRadius:
                            BorderRadius
                                .circular(
                          22,
                        ),

                        color: Colors
                            .white
                            .withOpacity(
                          0.03,
                        ),
                      ),

                      child: Row(

                        children: [

                          ClipRRect(

                            borderRadius:
                                BorderRadius
                                    .circular(
                              18,
                            ),

                            child:
                                item['image'] !=
                                            null &&
                                        item['image']
                                            .toString()
                                            .isNotEmpty
                                    ? Image.network(

                                        item['image'],

                                        width:
                                            90,

                                        height:
                                            90,

                                        fit: BoxFit
                                            .cover,
                                      )
                                    : Container(

                                        width:
                                            90,

                                        height:
                                            90,

                                        color: Colors
                                            .white10,

                                        child:
                                            const Icon(
                                          Icons
                                              .image,

                                          color: Colors
                                              .white38,
                                        ),
                                      ),
                          ),

                          const SizedBox(
                            width: 14,
                          ),

                          Expanded(

                            child: Column(

                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,

                              children: [

                                Text(

                                  item['name'] ??
                                      '',

                                  style:
                                      const TextStyle(

                                    color:
                                        Colors
                                            .white,

                                    fontSize:
                                        19,

                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),

                                const SizedBox(
                                  height: 5,
                                ),

                                Text(

                                  "Size: ${item['size'] ?? 'N/A'}",

                                  style:
                                      const TextStyle(

                                    color:
                                        Colors
                                            .white60,

                                    fontSize:
                                        15,
                                  ),
                                ),

                                const SizedBox(
                                  height: 8,
                                ),

                                Text(

                                  "${price.toStringAsFixed(0)} EGP",

                                  style:
                                      const TextStyle(

                                    color:
                                        Color(
                                      0xFF6EA6C1,
                                    ),

                                    fontSize:
                                        18,

                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Column(

                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .end,

                            children: [

                              Container(

                                padding:
                                    const EdgeInsets.symmetric(
                                  horizontal:
                                      12,
                                  vertical:
                                      8,
                                ),

                                decoration:
                                    BoxDecoration(

                                  borderRadius:
                                      BorderRadius.circular(
                                    14,
                                  ),

                                  color:
                                      Colors
                                          .white10,
                                ),

                                child: Text(

                                  "x$quantity",

                                  style:
                                      const TextStyle(

                                    color:
                                        Colors
                                            .white,

                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                              ),

                              const SizedBox(
                                height: 18,
                              ),

                              Text(

                                "${totalPrice.toStringAsFixed(0)} EGP",

                                style:
                                    const TextStyle(

                                  color:
                                      Colors
                                          .white,

                                  fontSize:
                                      18,

                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(
                  height: 8,
                ),

                Divider(
                  color: Colors.white
                      .withOpacity(
                    0.08,
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                priceRow(
                  "Subtotal",
                  "${subtotal.toStringAsFixed(0)} EGP",
                ),

                const SizedBox(
                  height: 10,
                ),

                priceRow(
                  "Shipping",
                  "${shipping.toStringAsFixed(0)} EGP",
                ),

                const SizedBox(
                  height: 10,
                ),

                priceRow(
                  "Discount",
                  "-${discount.toStringAsFixed(0)} EGP",
                  color:
                      const Color(
                    0xFF6EA6C1,
                  ),
                ),

                const SizedBox(
                  height: 16,
                ),

                Divider(
                  color: Colors.white
                      .withOpacity(
                    0.08,
                  ),
                ),

                const SizedBox(
                  height: 16,
                ),

                Row(

                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,

                  children: [

                    const Text(

                      "Total Amount",

                      style:
                          TextStyle(

                        color:
                            Colors
                                .white,

                        fontSize:
                            22,

                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),

                    Text(

                      "${total.toStringAsFixed(0)} EGP",

                      style:
                          const TextStyle(

                        color:
                            Color(
                          0xFF6EA6C1,
                        ),

                        fontSize:
                            24,

                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          /// ADDRESS
          buildCard(

            child: Row(

              children: [

                const CircleAvatar(

                  radius: 18,

                  backgroundColor:
                      Color(
                    0x226EA6C1,
                  ),

                  child: Icon(

                    Icons.location_on,

                    color: Color(
                      0xFF6EA6C1,
                    ),
                  ),
                ),

                const SizedBox(
                  width: 14,
                ),

                Expanded(

                  child: Column(

                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [

                      const Text(

                        "Shipping Address",

                        style:
                            TextStyle(

                          color:
                              Colors
                                  .white,

                          fontSize:
                              18,

                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
                      ),

                      const SizedBox(
                        height: 5,
                      ),

                      Text(

                        address,

                        style:
                            const TextStyle(

                          color:
                              Colors
                                  .white60,

                          fontSize:
                              16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

/// BUTTONS
Row(

  children: [

    Expanded(

      child: GestureDetector(

        onTap: () {

          callCustomer(phone);
        },

        child: Container(

          height: 62,

          decoration: BoxDecoration(

            borderRadius:
                BorderRadius.circular(20),

            gradient: const LinearGradient(

              colors: [

                Color(0xFFB8D7E5),
                Color(0xFF6EA6C1),
              ],
            ),
          ),

          child: Row(

            mainAxisAlignment:
                MainAxisAlignment.center,

            children: const [

              Icon(
                Icons.call_outlined,
                color: Colors.white,
              ),

              SizedBox(width: 10),

              Text(

                "Call The Customer",

                style: TextStyle(

                  color: Colors.white,

                  fontSize: 16,

                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    ),

    const SizedBox(width: 14),

    Expanded(

      child: GestureDetector(

        onTap: () {

          chatCustomer(phone);
        },

        child: Container(

          height: 62,

          decoration: BoxDecoration(

            borderRadius:
                BorderRadius.circular(20),

            gradient: const LinearGradient(

              colors: [

                Color(0xFF32D951),
                Color(0xFF128C28),
              ],
            ),
          ),

          child: Row(

            mainAxisAlignment:
                MainAxisAlignment.center,

            children: const [

              Icon(
                Icons.chat_bubble_outline,
                color: Colors.white,
              ),

              SizedBox(width: 10),

              Text(

                "Chat The Customer",

                style: TextStyle(

                  color: Colors.white,

                  fontSize: 16,

                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ],
),

const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget buildCard({
    required Widget child,
  }) {

    return Container(

      padding:
          const EdgeInsets.all(
        18,
      ),

      decoration:
          BoxDecoration(

        borderRadius:
            BorderRadius.circular(
          28,
        ),

        gradient:
            const LinearGradient(

          colors: [

            Color(0xFF111827),
            Color(0xFF0A0F1A),
          ],

          begin:
              Alignment.topLeft,

          end:
              Alignment.bottomRight,
        ),

        border: Border.all(

          color: Colors.white
              .withOpacity(
            0.05,
          ),
        ),
      ),

      child: child,
    );
  }

  Widget priceRow(
    String title,
    String value, {
    Color color =
        Colors.white70,
  }) {

    return Row(

      mainAxisAlignment:
          MainAxisAlignment
              .spaceBetween,

      children: [

        Text(

          title,

          style: TextStyle(

            color: color,

            fontSize: 17,
          ),
        ),

        Text(

          value,

          style: TextStyle(

            color: color,

            fontSize: 17,

            fontWeight:
                FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});

  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final bool isDark =
        Theme.of(context).brightness == Brightness.dark;

    final Color mainTextColor =
        isDark ? Colors.white : Colors.black;

    final Color subTextColor =
        isDark ? Colors.white70 : Colors.grey.shade700;

    final Color cardColor =
        isDark
            ? const Color(0xFF1D1B20)
            : Colors.white;

    final Color iconBoxColor =
        isDark
            ? const Color(0xFF2A2730)
            : const Color(0xFFF3F3F3);

    final Color blueColor =
        isDark
            ? const Color(0xFF6EA6C1)
            : const Color(0xFF2D5A74);

    return Scaffold(
      backgroundColor:
          isDark
              ? const Color(0xFF141118)
              : const Color(0xFFF7F7FA),

      appBar: AppBar(
        backgroundColor:
            isDark ? Colors.black : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: mainTextColor,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          "My Profile",
          style: TextStyle(
            color: mainTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 30,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.edit,
              color: blueColor,
              size: 28,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),

      body: user == null
          ? Center(
              child: Text(
                "No User Found",
                style: TextStyle(
                  color: mainTextColor,
                ),
              ),
            )
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user!.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (!snapshot.data!.exists) {
                  return Center(
                    child: Text(
                      "User data not found",
                      style: TextStyle(
                        color: mainTextColor,
                      ),
                    ),
                  );
                }

                final data =
                    snapshot.data!.data() as Map<String, dynamic>;

                final String name =
                    data['name'] ?? 'No Name';

                final String email =
                    data['email'] ?? 'No Email';

                final String phone =
                    data['phone'] ?? 'No Phone';

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      /// PROFILE CARD
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius:
                              BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 45,
                              backgroundColor:
                                  blueColor.withOpacity(.15),
                              child: Icon(
                                Icons.person,
                                size: 50,
                                color: blueColor,
                              ),
                            ),

                            const SizedBox(height: 16),

                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: mainTextColor,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 8),

                            Text(
                              "Always remember, We care about you! ♡",
                              style: TextStyle(
                                fontSize: 15,
                                color: subTextColor,
                              ),
                            ),

                            const SizedBox(height: 24),

                            _buildInfoTile(
                              icon: Icons.email,
                              title: "Email",
                              value: email,
                              mainTextColor: mainTextColor,
                              subTextColor: subTextColor,
                              iconBoxColor: iconBoxColor,
                              blueColor: blueColor,
                            ),

                            const SizedBox(height: 14),

                            _buildInfoTile(
                              icon: Icons.phone,
                              title: "Phone",
                              value: phone,
                              mainTextColor: mainTextColor,
                              subTextColor: subTextColor,
                              iconBoxColor: iconBoxColor,
                              blueColor: blueColor,
                            ),

                            const SizedBox(height: 14),

                            _buildInfoTile(
                              icon: Icons.calendar_month,
                              title: "Member Since",
                              value: user!.metadata.creationTime != null
                                  ? DateFormat.yMMMM().format(
                                      user!.metadata.creationTime!,
                                    )
                                  : "Unknown",
                              mainTextColor: mainTextColor,
                              subTextColor: subTextColor,
                              iconBoxColor: iconBoxColor,
                              blueColor: blueColor,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// MENU CARD
                      Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius:
                              BorderRadius.circular(24),
                        ),
                        child: Column(
                          children: [
                            _menuTile(
                              icon: Icons.location_on_outlined,
                              title: "My Addresses",
                              color: mainTextColor,

                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const MyAddressesScreen(),
                                  ),
                                );
                              },
                            ),

                            _menuTile(
  icon: Icons.credit_card,
  title: "Payment Methods",
  color: mainTextColor,

  onTap: () {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Will Be Available Soon!",
        ),
      ),
    );
  },
),

_menuTile(
  icon: Icons.notifications_none,
  title: "Notifications",
  color: mainTextColor,

  onTap: () {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Will Be Available Soon!",
        ),
      ),
    );
  },
),

_menuTile(
  icon: Icons.help_outline,
  title: "Help & Support",
  color: mainTextColor,

  onTap: () {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Will Be Available Soon!",
        ),
      ),
    );
  },
),

                            _menuTile(
                              icon: Icons.info_outline,
                              title: "About MedLife",
                              color: mainTextColor,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AboutMedLifeScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// LOGOUT
                      Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius:
                              BorderRadius.circular(24),
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.logout,
                            color: Colors.red,
                          ),
                          title: const Text(
                            "Logout",
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 18,
                            color: Colors.red,
                          ),
                          onTap: () async {

  await FirebaseAuth.instance.signOut();

  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (context) => LoginScreen(),
    ),
    (route) => false,
  );
},
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    required Color mainTextColor,
    required Color subTextColor,
    required Color iconBoxColor,
    required Color blueColor,
  }) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: iconBoxColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: blueColor,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: subTextColor,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: mainTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String title,
    required Color color,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: const Color(0xFF6EA6C1),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 18,
      ),
      onTap: onTap,
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState
    extends State<EditProfileScreen> {

  final user = FirebaseAuth.instance.currentUser;

  final TextEditingController oldPasswordController =
      TextEditingController();

  final TextEditingController newPasswordController =
      TextEditingController();

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController phoneController =
      TextEditingController();

  bool obscureOldPassword = true;
  bool obscureNewPassword = true;
  bool isLoading = false;

  final Color purpleColor =
      const Color(0xFF6EA6C1);

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  Future<void> getUserData() async {

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    if (doc.exists) {

      final data = doc.data()!;

      nameController.text =
          data['name'] ?? '';

      phoneController.text =
          data['phone'] ?? '';

      emailController.text =
          data['email'] ?? '';
    }
  }

  Future<void> saveChanges() async {

    try {

      setState(() {
        isLoading = true;
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({

        'name':
            nameController.text.trim(),

        'phone':
            phoneController.text.trim(),

        'email':
            emailController.text.trim(),
      });

      if (emailController.text.trim()
          != user!.email) {

        await user!.verifyBeforeUpdateEmail(
          emailController.text.trim(),
        );
      }

      if (oldPasswordController
              .text
              .isNotEmpty &&
          newPasswordController
              .text
              .isNotEmpty) {

        AuthCredential credential =
            EmailAuthProvider.credential(

          email: user!.email!,

          password:
              oldPasswordController.text.trim(),
        );

        await user!
            .reauthenticateWithCredential(
          credential,
        );

        await user!.updatePassword(
          newPasswordController.text.trim(),
        );
      }

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(

        SnackBar(
          content: Text(
              "Profile Updated Successfully ✅"),
        ),
      );

      Navigator.pop(context);

    } on FirebaseAuthException catch (e) {

      setState(() {
        isLoading = false;
      });

      String message =
          e.message ?? "Error";

      ScaffoldMessenger.of(context)
          .showSnackBar(

        SnackBar(
          content: Text(message),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    final bool isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final Color bgColor =
        isDark
            ? const Color(0xFF141118)
            : const Color(0xFFF7F7FA);

    final Color cardColor =
        isDark
            ? const Color(0xFF1D1B20)
            : Colors.white;

    final Color textColor =
        isDark
            ? Colors.white
            : Colors.black;

    final Color subTextColor =
        isDark
            ? Colors.white70
            : Colors.grey.shade700;

    final Color iconBoxColor =
        isDark
            ? const Color(0xFF2E2B31)
            : const Color(0xFFF3F3F3);

    return Scaffold(

      backgroundColor: bgColor,

      appBar: AppBar(

        backgroundColor:
            isDark
                ? Colors.black
                : Colors.white,

        elevation: 0,

        leading: IconButton(

          icon: Icon(
            Icons.arrow_back,
            color: textColor,
          ),

          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: Text(

          "Edit Profile",

          style: TextStyle(
            color: textColor,
            fontWeight:
                FontWeight.bold,
            fontSize: 28,
          ),
        ),

        actions: [

          TextButton(

            onPressed:
                isLoading
                    ? null
                    : saveChanges,

            child: Text(

              "Save",

              style: TextStyle(
                color: purpleColor,
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          )
        ],
      ),

      body: SingleChildScrollView(

        padding:
            const EdgeInsets.all(16),

        child: Container(

          padding:
              const EdgeInsets.all(20),

          decoration: BoxDecoration(

            color: cardColor,

            borderRadius:
                BorderRadius.circular(24),
          ),

          child: Column(

            children: [

              CircleAvatar(

                radius: 50,

                backgroundColor:
                    iconBoxColor,

                child: Icon(

                  Icons.person,

                  size: 55,

                  color: purpleColor,
                ),
              ),

              const SizedBox(height: 16),

              Text(

                "Always remember, We care about you! ♡",

                style: TextStyle(
                  color: subTextColor,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 30),

              _buildTextField(

                controller:
                    nameController,

                label: "Full Name",

                icon:
                    Icons.person_outline,

                textColor: textColor,

                cardColor: cardColor,

                iconBoxColor:
                    iconBoxColor,
              ),

              const SizedBox(height: 18),

              _buildTextField(

                controller:
                    emailController,

                label:
                    "Email Address",

                icon:
                    Icons.email_outlined,

                textColor: textColor,

                cardColor: cardColor,

                iconBoxColor:
                    iconBoxColor,
              ),

              const SizedBox(height: 18),

              _buildTextField(

                controller:
                    phoneController,

                label:
                    "Phone Number",

                icon:
                    Icons.phone_outlined,

                textColor: textColor,

                cardColor: cardColor,

                iconBoxColor:
                    iconBoxColor,
              ),

              const SizedBox(height: 25),

              Align(

                alignment:
                    Alignment.centerLeft,

                child: Text(

                  "Change Password",

                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              TextField(

                controller:
                    oldPasswordController,

                obscureText:
                    obscureOldPassword,

                style: TextStyle(
                  color: textColor,
                ),

                decoration: InputDecoration(

                  labelText:
                      "Old Password",

                  labelStyle:
                      TextStyle(
                    color:
                        subTextColor,
                  ),

                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color:
                        purpleColor,
                  ),

                  suffixIcon:
                      IconButton(

                    icon: Icon(

                      obscureOldPassword
                          ? Icons
                              .visibility_off
                          : Icons
                              .visibility,

                      color:
                          purpleColor,
                    ),

                    onPressed: () {

                      setState(() {

                        obscureOldPassword =
                            !obscureOldPassword;
                      });
                    },
                  ),

                  filled: true,

                  fillColor:
                      cardColor,

                  border:
                      OutlineInputBorder(

                    borderRadius:
                        BorderRadius.circular(
                            18),
                  ),

                  enabledBorder:
                      OutlineInputBorder(

                    borderRadius:
                        BorderRadius.circular(
                            18),

                    borderSide:
                        BorderSide(
                      color:
                          iconBoxColor,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              TextField(

                controller:
                    newPasswordController,

                obscureText:
                    obscureNewPassword,

                style: TextStyle(
                  color: textColor,
                ),

                decoration: InputDecoration(

                  labelText:
                      "New Password",

                  labelStyle:
                      TextStyle(
                    color:
                        subTextColor,
                  ),

                  prefixIcon: Icon(
                    Icons.lock,
                    color:
                        purpleColor,
                  ),

                  suffixIcon:
                      IconButton(

                    icon: Icon(

                      obscureNewPassword
                          ? Icons
                              .visibility_off
                          : Icons
                              .visibility,

                      color:
                          purpleColor,
                    ),

                    onPressed: () {

                      setState(() {

                        obscureNewPassword =
                            !obscureNewPassword;
                      });
                    },
                  ),

                  filled: true,

                  fillColor:
                      cardColor,

                  border:
                      OutlineInputBorder(

                    borderRadius:
                        BorderRadius.circular(
                            18),
                  ),

                  enabledBorder:
                      OutlineInputBorder(

                    borderRadius:
                        BorderRadius.circular(
                            18),

                    borderSide:
                        BorderSide(
                      color:
                          iconBoxColor,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Align(

                alignment:
                    Alignment.centerRight,

                child: GestureDetector(

                  onTap: () {

                    Navigator.push(

                      context,

                      MaterialPageRoute(

                        builder: (_) =>
                            ForgotPasswordScreen(),
                      ),
                    );
                  },

                  child: Text(

                    "Forgot my password?",

                    style: TextStyle(
                      color:
                          purpleColor,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 35),

              SizedBox(

                width: double.infinity,

                height: 58,

                child: ElevatedButton(

                  onPressed:
                      isLoading
                          ? null
                          : saveChanges,

                  style:
                      ElevatedButton.styleFrom(

                    backgroundColor:
                        purpleColor,

                    shape:
                        RoundedRectangleBorder(

                      borderRadius:
                          BorderRadius.circular(
                              18),
                    ),
                  ),

                  child: isLoading

                      ? const CircularProgressIndicator(
                          color:
                              Colors.white,
                        )

                      : const Text(

                          "Save Changes",

                          style: TextStyle(

                            fontSize: 18,

                            fontWeight:
                                FontWeight.bold,

                            color:
                                Colors.white,
                          ),
                        ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({

    required TextEditingController
        controller,

    required String label,

    required IconData icon,

    required Color textColor,

    required Color cardColor,

    required Color iconBoxColor,

    bool enabled = true,
  }) {

    return TextField(

      controller: controller,

      enabled: enabled,

      style: TextStyle(
        color: textColor,
      ),

      decoration: InputDecoration(

        labelText: label,

        labelStyle: TextStyle(
          color: Colors.grey,
        ),

        prefixIcon: Icon(
          icon,
          color: purpleColor,
        ),

        filled: true,

        fillColor: cardColor,

        border: OutlineInputBorder(

          borderRadius:
              BorderRadius.circular(18),
        ),

        enabledBorder:
            OutlineInputBorder(

          borderRadius:
              BorderRadius.circular(18),

          borderSide: BorderSide(
            color: iconBoxColor,
          ),
        ),
      ),
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Password reset email sent ✅",
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
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
      backgroundColor: const Color(0xFF141118),

      appBar: AppBar(
        backgroundColor: const Color(0xFF141118),
        elevation: 0,
        foregroundColor: Colors.white,

        title: Text(
          "Forgot Password",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
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
                    Color(0x221D1B20),
                    Color(0x661D1B20),
                  ],
                ),
              ),

              child: Stack(
                alignment: Alignment.center,

                children: [
                  Icon(
                    Icons.lock_reset_rounded,
                    size: 110,
                    color: Color(0xFF6EA6C1),
                  ),

                  Positioned(
                    right: 0,
                    bottom: 5,

                    child: Container(
                      padding: EdgeInsets.all(12),

                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF6EA6C1),
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
                      color: Color(0xFF6EA6C1),
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  TextSpan(
                    text: "Your Password",
                    style: TextStyle(
                      color: Colors.white,
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
                color: Colors.white70,
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
                  color: Colors.white,
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

                color: const Color(0xFF1D1B20),

                border: Border.all(
                  color: Colors.white12,
                ),
              ),

              child: TextField(
                controller: emailController,

                keyboardType:
                    TextInputType.emailAddress,

                style: TextStyle(
                  color: Colors.white,
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
                    color: Colors.white38,
                    fontSize: 18,
                  ),

                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: Color(0xFF6EA6C1),
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
                      const Color(0xFF6EA6C1),

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

                color: const Color(0xFF1D1B20),

                border: Border.all(
                  color: Colors.white10,
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
                          const Color(0xFF6EA6C1),
                    ),
                  ),

                  SizedBox(width: 15),

                  Expanded(
                    child: Text(
                      "We’ll never share your email with anyone else.",

                      style: TextStyle(
                        color: Colors.white70,
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

class MyAddressesScreen extends StatefulWidget {
  const MyAddressesScreen({super.key});

  @override
  State<MyAddressesScreen> createState() =>
      _MyAddressesScreenState();
}

class _MyAddressesScreenState
    extends State<MyAddressesScreen> {

  final List<Map<String, dynamic>> addresses = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  /// 🔥 LOAD ADDRESSES INSTANTLY
  Future<void> _loadAddresses() async {

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('addresses')
        .get();

    addresses.clear();

    for (var doc in snapshot.docs) {

      addresses.add({
        "id": doc.id,
        "title": doc['title'],
        "address": doc['address'],
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  void _showAddAddressDialog() {

    if (addresses.length >= 3) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text("Maximum 3 addresses allowed"),
        ),
      );

      return;
    }

    final titleController =
        TextEditingController();

    final addressController =
        TextEditingController();

    showModalBottomSheet(

      context: context,

      isScrollControlled: true,

      backgroundColor:
          const Color(0xFF1D1B20),

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),

      builder: (context) {

        return Padding(

          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom:
                MediaQuery.of(context)
                    .viewInsets
                    .bottom +
                24,
          ),

          child: Column(

            mainAxisSize: MainAxisSize.min,

            children: [

              Container(
                width: 70,
                height: 5,

                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(.4),

                  borderRadius:
                      BorderRadius.circular(20),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                "Add New Address",

                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 24),

              TextField(

                controller: titleController,

                style: const TextStyle(
                  color: Colors.white,
                ),

                decoration: InputDecoration(

                  labelText: "Title",

                  labelStyle: const TextStyle(
                    color: Colors.white70,
                  ),

                  hintText:
                      "Home / Work / University",

                  hintStyle: const TextStyle(
                    color: Colors.white38,
                  ),

                  prefixIcon: const Icon(
                    Icons.title,
                    color: Color(0xFF6EA6C1),
                  ),

                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(18),

                    borderSide:
                        const BorderSide(
                      color: Color(0xFF6EA6C1),
                    ),
                  ),

                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(18),

                    borderSide:
                        const BorderSide(
                      color: Color(0xFF6EA6C1),
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              TextField(

                controller: addressController,

                maxLines: 3,

                style: const TextStyle(
                  color: Colors.white,
                ),

                decoration: InputDecoration(

                  labelText: "Address",

                  labelStyle: const TextStyle(
                    color: Colors.white70,
                  ),

                  hintText:
                      "Enter full address details",

                  hintStyle: const TextStyle(
                    color: Colors.white38,
                  ),

                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(
                      bottom: 50,
                    ),

                    child: Icon(
                      Icons.location_on,
                      color: Color(0xFF6EA6C1),
                    ),
                  ),

                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(18),

                    borderSide:
                        const BorderSide(
                      color: Color(0xFF6EA6C1),
                    ),
                  ),

                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(18),

                    borderSide:
                        const BorderSide(
                      color: Color(0xFF6EA6C1),
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(

                width: double.infinity,
                height: 56,

                child: ElevatedButton(

                  style: ElevatedButton.styleFrom(

                    backgroundColor:
                        const Color(0xFF6EA6C1),

                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                            18,
                          ),
                    ),
                  ),

                  onPressed: () async {

                    if (titleController.text
                            .trim()
                            .isEmpty ||
                        addressController.text
                            .trim()
                            .isEmpty) {
                      return;
                    }

                    final user =
                        FirebaseAuth.instance
                            .currentUser;

                    if (user == null) return;

                    final newAddress = {
                      "title":
                          titleController.text
                              .trim(),

                      "address":
                          addressController.text
                              .trim(),
                    };

                    /// 🔥 INSTANT UI UPDATE
                    setState(() {

                      addresses.add({
                        "id": "",
                        ...newAddress,
                      });
                    });

                    Navigator.pop(context);

                    /// 🔥 SAVE TO FIREBASE
                    final doc =
                        await FirebaseFirestore
                            .instance
                            .collection('users')
                            .doc(user.uid)
                            .collection(
                              'addresses',
                            )
                            .add(newAddress);

                    /// 🔥 UPDATE ID
                    final index =
                        addresses.indexWhere(
                      (e) => e["id"] == "",
                    );

                    if (index != -1) {

                      setState(() {

                        addresses[index]["id"] =
                            doc.id;
                      });
                    }
                  },

                  child: const Text(

                    "Save Address",

                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _deleteAddress(int index) async {

    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final addressId =
        addresses[index]["id"];

    /// 🔥 DELETE INSTANTLY
    setState(() {
      addresses.removeAt(index);
    });

    if (addressId != null &&
        addressId.toString().isNotEmpty) {

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('addresses')
          .doc(addressId)
          .delete();
    }
  }

  IconData _getAddressIcon(String title) {

    switch (title.toLowerCase()) {

      case "home":
        return Icons.home_outlined;

      case "work":
        return Icons.work_outline;

      case "university":
        return Icons.school_outlined;

      default:
        return Icons.location_on_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {

    const Color bgColor =
        Color(0xFF141118);

    const Color cardColor =
        Color(0xFF1D1B20);

    const Color mainText =
        Colors.white;

    const Color subText =
        Colors.white70;

    const Color blue =
        Color(0xFF6EA6C1);

    return Scaffold(

      backgroundColor: bgColor,

      appBar: AppBar(

        backgroundColor:
            const Color(0xFF141118),

        elevation: 0,

        leading: IconButton(

          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),

          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(

          "My Addresses",

          style: TextStyle(
            color: Colors.white,
            fontWeight:
                FontWeight.bold,
            fontSize: 30,
          ),
        ),

        actions: [

          if (addresses.length < 3)

            TextButton.icon(

              onPressed:
                  _showAddAddressDialog,

              icon: const Icon(
                Icons.add,
                color: blue,
              ),

              label: const Text(

                "Add",

                style: TextStyle(
                  color: blue,
                  fontSize: 16,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),

          const SizedBox(width: 8),
        ],
      ),

      floatingActionButton:
          addresses.isNotEmpty &&
                  addresses.length < 3

              ? FloatingActionButton.extended(

                backgroundColor: blue,

                onPressed:
                    _showAddAddressDialog,

                icon: const Icon(
                  Icons.add,
                  color: Colors.white,
                ),

                label: const Text(

                  "Add Address",

                  style: TextStyle(
                    color: Colors.white,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              )

              : null,

      body:
          isLoading

              ? const Center(
                  child:
                      CircularProgressIndicator(
                    color: blue,
                  ),
                )

              : SingleChildScrollView(

                padding:
                    const EdgeInsets.all(16),

                child: Column(

                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    /// TOP CARD
                    Container(

                      width: double.infinity,

                      padding:
                          const EdgeInsets.all(
                            20,
                          ),

                      decoration: BoxDecoration(

                        borderRadius:
                            BorderRadius.circular(
                              24,
                            ),

                        gradient:
                            const LinearGradient(

                              colors: [
                                Color(0xFF1D1B20),
                                Color(0xFF141118),
                              ],
                            ),
                      ),

                      child: Row(
                        children: [

                          Container(

                            width: 70,
                            height: 70,

                            decoration: BoxDecoration(
                              color:
                                  blue.withOpacity(
                                    .15,
                                  ),

                              shape:
                                  BoxShape.circle,
                            ),

                            child: const Icon(
                              Icons.location_on,
                              color: blue,
                              size: 36,
                            ),
                          ),

                          const SizedBox(
                            width: 18,
                          ),

                          Expanded(

                            child: Column(

                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,

                              children: [

                                const Text(

                                  "Manage your addresses",

                                  style: TextStyle(
                                    color:
                                        mainText,

                                    fontSize:
                                        22,

                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),

                                const SizedBox(
                                  height: 6,
                                ),

                                const Text(

                                  "You can add up to 3 addresses",

                                  style: TextStyle(
                                    color:
                                        subText,

                                    fontSize:
                                        15,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Container(

                            padding:
                                const EdgeInsets.symmetric(
                                  horizontal:
                                      16,

                                  vertical:
                                      12,
                                ),

                            decoration:
                                BoxDecoration(
                              color:
                                  blue.withOpacity(
                                    .15,
                                  ),

                              borderRadius:
                                  BorderRadius.circular(
                                    18,
                                  ),
                            ),

                            child: Text(

                              "${addresses.length}/3",

                              style:
                                  const TextStyle(
                                color:
                                    Colors.white,

                                fontWeight:
                                    FontWeight
                                        .bold,

                                fontSize:
                                    20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 26),

                    const Text(

                      "Your Addresses",

                      style: TextStyle(
                        color: mainText,
                        fontSize: 28,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 18),

                    if (addresses.isEmpty)

                      Container(

                        width: double.infinity,

                        padding:
                            const EdgeInsets.all(
                              30,
                            ),

                        decoration: BoxDecoration(
                          color: cardColor,

                          borderRadius:
                              BorderRadius.circular(
                                28,
                              ),
                        ),

                        child: Column(
                          children: [

                            Container(

                              width: 90,
                              height: 90,

                              decoration:
                                  BoxDecoration(
                                color:
                                    blue.withOpacity(
                                      .15,
                                    ),

                                shape:
                                    BoxShape.circle,
                              ),

                              child: const Icon(
                                Icons
                                    .location_off_outlined,

                                color: blue,
                                size: 45,
                              ),
                            ),

                            const SizedBox(
                              height: 22,
                            ),

                            const Text(

                              "No Addresses Yet",

                              style: TextStyle(
                                color:
                                    mainText,

                                fontSize: 24,

                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),

                            const SizedBox(
                              height: 10,
                            ),

                            const Text(

                              "Add your first address to make ordering faster and easier.",

                              textAlign:
                                  TextAlign.center,

                              style: TextStyle(
                                color:
                                    subText,

                                fontSize:
                                    15,

                                height:
                                    1.5,
                              ),
                            ),

                            const SizedBox(
                              height: 24,
                            ),

                            SizedBox(

                              width:
                                  double.infinity,

                              height: 56,

                              child:
                                  ElevatedButton.icon(

                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          blue,

                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(
                                              18,
                                            ),
                                      ),
                                    ),

                                    onPressed:
                                        _showAddAddressDialog,

                                    icon:
                                        const Icon(
                                      Icons.add,
                                      color:
                                          Colors
                                              .white,
                                    ),

                                    label:
                                        const Text(

                                          "Add Address",

                                          style:
                                              TextStyle(
                                            color:
                                                Colors
                                                    .white,

                                            fontWeight:
                                                FontWeight.bold,

                                            fontSize:
                                                18,
                                          ),
                                        ),
                                  ),
                            ),
                          ],
                        ),
                      ),

                    ...List.generate(
                      addresses.length,

                      (index) {

                        final item =
                            addresses[index];

                        return Padding(

                          padding:
                              const EdgeInsets.only(
                                bottom: 18,
                              ),

                          child: Container(

                            width:
                                double.infinity,

                            padding:
                                const EdgeInsets.all(
                                  18,
                                ),

                            decoration:
                                BoxDecoration(
                              color: cardColor,

                              borderRadius:
                                  BorderRadius.circular(
                                    28,
                                  ),
                            ),

                            child: Row(

                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,

                              children: [

                                Container(

                                  width: 70,
                                  height: 70,

                                  decoration:
                                      BoxDecoration(
                                    color:
                                        blue.withOpacity(
                                          .15,
                                        ),

                                    borderRadius:
                                        BorderRadius.circular(
                                          22,
                                        ),
                                  ),

                                  child: Icon(

                                    _getAddressIcon(
                                      item['title'],
                                    ),

                                    color: blue,
                                    size: 34,
                                  ),
                                ),

                                const SizedBox(
                                  width: 16,
                                ),

                                Expanded(

                                  child: Column(

                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,

                                    children: [

                                      Row(
                                        children: [

                                          Text(

                                            item['title'],

                                            style:
                                                const TextStyle(
                                              color:
                                                  mainText,

                                              fontSize:
                                                  24,

                                              fontWeight:
                                                  FontWeight.bold,
                                            ),
                                          ),

                                          const SizedBox(
                                            width:
                                                10,
                                          ),

                                          if (index ==
                                              0)

                                            Container(

                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal:
                                                        12,

                                                    vertical:
                                                        6,
                                                  ),

                                              decoration:
                                                  BoxDecoration(
                                                color:
                                                    blue.withOpacity(
                                                      .15,
                                                    ),

                                                borderRadius:
                                                    BorderRadius.circular(
                                                      14,
                                                    ),
                                              ),

                                              child:
                                                  const Text(

                                                    "Default",

                                                    style:
                                                        TextStyle(
                                                      color:
                                                          blue,

                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                            ),
                                        ],
                                      ),

                                      const SizedBox(
                                        height: 12,
                                      ),

                                      Text(

                                        item['address'],

                                        style:
                                            const TextStyle(
                                          color:
                                              subText,

                                          fontSize:
                                              16,

                                          height:
                                              1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                PopupMenuButton(

                                  color:
                                      cardColor,

                                  icon: const Icon(
                                    Icons.more_vert,
                                    color:
                                        subText,
                                  ),

                                  itemBuilder:
                                      (context) => [

                                        PopupMenuItem(

                                          onTap: () {

                                            Future.delayed(
                                              Duration
                                                  .zero,

                                              () {

                                                _deleteAddress(
                                                  index,
                                                );
                                              },
                                            );
                                          },

                                          child:
                                              const Row(
                                                children: [

                                                  Icon(
                                                    Icons
                                                        .delete,

                                                    color:
                                                        Colors.red,
                                                  ),

                                                  SizedBox(
                                                    width:
                                                        10,
                                                  ),

                                                  Text(
                                                    "Delete",
                                                  ),
                                                ],
                                              ),
                                        ),
                                      ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    Container(

                      width: double.infinity,

                      padding:
                          const EdgeInsets.all(
                            20,
                          ),

                      decoration: BoxDecoration(
                        color: cardColor,

                        borderRadius:
                            BorderRadius.circular(
                              24,
                            ),
                      ),

                      child: Row(
                        children: [

                          Container(

                            width: 55,
                            height: 55,

                            decoration:
                                BoxDecoration(
                              color:
                                  blue.withOpacity(
                                    .15,
                                  ),

                              borderRadius:
                                  BorderRadius.circular(
                                    18,
                                  ),
                            ),

                            child: const Icon(
                              Icons.shield_outlined,
                              color: blue,
                            ),
                          ),

                          const SizedBox(
                            width: 16,
                          ),

                          const Expanded(

                            child: Text(

                              "Your addresses are saved securely and used to deliver your orders.",

                              style: TextStyle(
                                color: subText,
                                fontSize: 15,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
    );
  }
}

class AboutMedLifeScreen extends StatelessWidget {
  const AboutMedLifeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark =
        Theme.of(context).brightness == Brightness.dark;

    final Color bgColor =
        isDark ? const Color(0xFF0D0917) : const Color(0xFFF3F3F5);

    final Color cardColor =
        isDark ? const Color(0xFF1D1B20) : Colors.white;

    final Color boxColor =
        isDark ? const Color(0xFF2A2730) : const Color(0xFFF4F4F4);

    final Color mainText =
        isDark ? Colors.white : Colors.black;

    final Color subText =
        isDark ? Colors.white70 : Colors.grey.shade700;

    const Color primaryBlue = Color(0xFF6EA6C1);

    return Scaffold(
      backgroundColor: bgColor,

      appBar: AppBar(
        title: Text(
          "About MedLife",
          style: TextStyle(color: mainText),
        ),
        backgroundColor:
            isDark ? Colors.black : Colors.white,
        iconTheme: IconThemeData(color: mainText),
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [

            /// 🔥 TOP CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),

                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          const Color(0xFF26222D),
                          const Color(0xFF1D1B20),
                        ]
                      : [
                          Colors.white,
                          const Color(0xFFF5F5F5),
                        ],
                ),
              ),

              child: Row(
                children: [

                  Column(
                    children: [

                      const Icon(
                        Icons.favorite,
                        color: primaryBlue,
                        size: 50,
                      ),

                      const SizedBox(height: 8),

                      Text(
                        "MedLife",
                        style: TextStyle(
                          color: mainText,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Text(
                        "For a better healthcare",
                        style: TextStyle(
                          color: subText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 20),

                  Expanded(
                    child: Text(
                      "MedLife is your trusted destination for high-quality medical scrubs, lab coats, and medical accessories.",
                      style: TextStyle(
                        color: subText,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// 🔥 VISION & MISSION
            Row(
              children: [

                Expanded(
                  child: _box(
                    icon: Icons.remove_red_eye,
                    title: "Our Vision",
                    text:
                        "To become the leading destination in the Middle East.",
                    cardColor: cardColor,
                    mainText: mainText,
                    subText: subText,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _box(
                    icon: Icons.track_changes,
                    title: "Our Mission",
                    text:
                        "Provide high quality with best price.",
                    cardColor: cardColor,
                    mainText: mainText,
                    subText: subText,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// 🔥 SERVICES
            _section(
              "Our Services",
              [
                _iconItem(
                  Icons.medical_services,
                  "Scrubs",
                  boxColor,
                  subText,
                ),

                _iconItem(
                  Icons.science,
                  "Lab Coats",
                  boxColor,
                  subText,
                ),

                _iconItem(
                  Icons.healing,
                  "Accessories",
                  boxColor,
                  subText,
                ),

                _iconItem(
                  Icons.local_shipping,
                  "Shipping",
                  boxColor,
                  subText,
                ),
              ],
              cardColor,
              mainText,
            ),

            const SizedBox(height: 20),

            /// 🔥 WHY CHOOSE US
            _section(
              "Why Choose MedLife?",
              [
                _iconItem(
                  Icons.star,
                  "High Quality",
                  boxColor,
                  subText,
                ),

                _iconItem(
                  Icons.attach_money,
                  "Affordable",
                  boxColor,
                  subText,
                ),

                _iconItem(
                  Icons.flash_on,
                  "Fast",
                  boxColor,
                  subText,
                ),

                _iconItem(
                  Icons.verified,
                  "Trusted",
                  boxColor,
                  subText,
                ),
              ],
              cardColor,
              mainText,
            ),

            const SizedBox(height: 20),

            /// 🔥 CONTACT
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  Text(
                    "Contact Us",
                    style: TextStyle(
                      color: mainText,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [

                      const Icon(
                        Icons.phone,
                        color: primaryBlue,
                      ),

                      const SizedBox(width: 10),

                      Text(
                        "01010520993",
                        style: TextStyle(
                          color: subText,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [

                      const Icon(
                        Icons.email,
                        color: primaryBlue,
                      ),

                      const SizedBox(width: 10),

                      GestureDetector(
                        onTap: () async {

                          final Uri emailUri = Uri(
                            scheme: 'mailto',
                            path: 'medlife.supportteam@gmail.com',
                            query:
                                'subject=MedLife Support',
                          );

                          await launchUrl(emailUri);
                        },

                        child: Text(
                          "medlife.supportteam@gmail.com",
                          style: TextStyle(
                            color: primaryBlue,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            decoration:
                                TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 CARD
  Widget _box({
    required IconData icon,
    required String title,
    required String text,
    required Color cardColor,
    required Color mainText,
    required Color subText,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),

      child: Column(
        children: [

          Icon(
            icon,
            color: Color(0xFF6EA6C1),
            size: 32,
          ),

          const SizedBox(height: 12),

          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: mainText,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: subText,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 SECTION
  Widget _section(
    String title,
    List<Widget> items,
    Color cardColor,
    Color mainText,
  ) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Text(
            title,
            style: TextStyle(
              color: mainText,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),

          const SizedBox(height: 18),

          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: items,
          ),
        ],
      ),
    );
  }

  /// 🔹 ICON ITEM
  Widget _iconItem(
    IconData icon,
    String text,
    Color boxColor,
    Color subText,
  ) {
    return Container(
      width: 120,

      padding: const EdgeInsets.symmetric(
        vertical: 20,
        horizontal: 12,
      ),

      decoration: BoxDecoration(
        color: boxColor,
        borderRadius: BorderRadius.circular(18),
      ),

      child: Column(
        children: [

          Icon(
            icon,
            size: 32,
            color: const Color(0xFF6EA6C1),
          ),

          const SizedBox(height: 10),

          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: subText,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class MyOrdersScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    return DefaultTabController(
      length: 2,

      child: Column(
        children: [

          const SizedBox(height: 12),

          /// 🔥 TAB BAR
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16),

            padding: EdgeInsets.all(6),

            decoration: BoxDecoration(
              color: const Color(0xFF141118),

              borderRadius: BorderRadius.circular(18),

              border: Border.all(
                color: Colors.white10,
              ),

              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.35),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),

            child: TabBar(

              dividerColor: Colors.transparent,

              indicator: BoxDecoration(
                color: const Color(0xFF6EA6C1),

                borderRadius: BorderRadius.circular(14),

                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6EA6C1)
                        .withOpacity(.35),

                    blurRadius: 14,
                    offset: Offset(0, 4),
                  ),
                ],
              ),

              indicatorSize: TabBarIndicatorSize.tab,

              labelColor: Colors.white,

              unselectedLabelColor: Colors.white60,

              labelStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),

              unselectedLabelStyle: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),

              tabs: [

                /// 🟠 PENDING
                Container(
                  height: 52,

                  alignment: Alignment.center,

                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,

                    children: [

                      Text(
                        "Pending",
                      ),

                      SizedBox(width: 6),

                      Container(
                        width: 10,
                        height: 10,

                        decoration: BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),

                /// 🟢 DELIVERED
                Container(
                  height: 52,

                  alignment: Alignment.center,

                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,

                    children: [

                      Text(
                        "Delivered",
                      ),

                      SizedBox(width: 6),

                      Container(
                        width: 10,
                        height: 10,

                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          /// 🔥 ORDERS
          Expanded(
            child: Container(

              margin: EdgeInsets.symmetric(horizontal: 10),

              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
              ),

              child: TabBarView(
                children: [

                  /// 🟠 Pending
                  Container(
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(24),
                    ),

                    child: OrdersList(
                      status: "pending",
                    ),
                  ),

                  /// 🟢 Delivered
                  Container(
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(24),
                    ),

                    child: OrdersList(
                      status: "delivered",
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OrdersList extends StatelessWidget {
  final String status;

  OrdersList({required this.status});

  @override
  Widget build(BuildContext context) {
    var user = FirebaseAuth.instance.currentUser;

    return StreamBuilder(
stream: FirebaseFirestore.instance
.collection('orders')
.where("userId", isEqualTo: user!.uid)
.where("status", isEqualTo: status)
.orderBy("orderedAt", descending: true)
.snapshots(),
builder: (context, snapshot) {

if (snapshot.hasError) {
  return Center(child: Text("Error: ${snapshot.error}"));
}

if (!snapshot.hasData) {
return Center(child: CircularProgressIndicator()); }

        var orders = snapshot.data!.docs;

        if (orders.isEmpty) {
          return Center(child: Text("No Orders"));
        }

        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, i) {
            var order = orders[i];
            var data = order.data() as Map<String, dynamic>;

Timestamp? orderedAt = data['orderedAt'];
Timestamp? deliveredAt = data['deliveredAt'];

String orderedDate = orderedAt != null
    ? DateFormat('dd MMM yyyy').format(
        orderedAt.toDate(),
      )
    : '';

String deliveredDate = deliveredAt != null
    ? DateFormat('dd MMM yyyy').format(
        deliveredAt.toDate(),
      )
    : '';

            List items = data['items'] ?? [];

            return Card(
              margin: EdgeInsets.all(10),
              child: ListTile(
                title: Text("Order #${i + 1}"),

                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔹 المنتجات
                    ...items.map<Widget>((item) {
                      return Text(
  "• ${item['name']} | Size: ${item['size'] ?? '-'} | Qty: ${item['quantity'] ?? 1} × (${item['price']})",
                      );
                    }).toList(),

                    SizedBox(height: 8),

                    Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [

    /// 🔥 ORDER DATE
    Row(
      children: [

        Icon(
          Icons.calendar_month_outlined,
          color: Colors.white70,
          size: 18,
        ),

        SizedBox(width: 8),

        Text(
          orderedDate,

          style: TextStyle(
            color: Colors.white70,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),

    /// 🔥 DELIVERED DATE
    if (data['status'] == "delivered" &&
        deliveredDate.isNotEmpty)

      Padding(
        padding: const EdgeInsets.only(top: 8),

        child: Row(
          children: [

            Icon(
              Icons.check_circle,
              color: Color(0xFF6EA6C1),
              size: 18,
            ),

            SizedBox(width: 8),

            Text(
              "Delivered: $deliveredDate",

              style: TextStyle(
                color: Color(0xFF6EA6C1),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
  ],
),

                    // 💰 التوتال
                    Text(
                      "Total: ${data['total']} EGP",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),

                    SizedBox(height: 5),

                    // 🔄 الحالة
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: status == "pending"
                            ? Colors.orange
                            : Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),

                trailing: Icon(Icons.arrow_forward),

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          MyOrderDetailsScreen(order: order),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class MyOrderDetailsScreen extends StatelessWidget {
  final QueryDocumentSnapshot order;

  const MyOrderDetailsScreen({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final data = order.data() as Map<String, dynamic>;

    List items = data['items'] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF070B1A),

      appBar: AppBar(
        backgroundColor: const Color(0xFF070B1A),
        elevation: 0,
        title: const Text("My Order Details"),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Container(
          padding: const EdgeInsets.all(18),

          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF0D1225),
                Color(0xFF061A42),
                Color(0xFF0D1225),
              ],
            ),
          ),

          child: Column(
            children: [

              /// المنتجات
              ...items.map((item) {

                int qty = item['quantity'] ?? 1;

                double price =
    double.tryParse(item['price'].toString()) ?? 0;

                double total =
                    price * qty;

                return Container(
                  margin: const EdgeInsets.only(
                    bottom: 18,
                  ),

                  padding: const EdgeInsets.all(14),

                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.05),
                    borderRadius:
                        BorderRadius.circular(24),
                  ),

                  child: Row(
                    children: [

                      /// الصورة
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(20),

                        child: Image.network(
                          item['image'],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),

                      const SizedBox(width: 16),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,

                          children: [

                            Text(
                              item['name'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              "Size: ${item['size']}",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              "${price.toStringAsFixed(0)} EGP",
                              style: const TextStyle(
                                color: Color(0xFF6EA6C1),
                                fontSize: 20,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Column(
                        children: [

                          Container(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),

                            decoration: BoxDecoration(
                              color: Colors.white12,
                              borderRadius:
                                  BorderRadius.circular(
                                20,
                              ),
                            ),

                            child: Text(
                              "x$qty",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          Text(
                            "${total.toStringAsFixed(0)} EGP",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),

              const Divider(
                color: Colors.white24,
                height: 40,
              ),

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,

                children: [
                  const Text(
                    "Total Amount",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Text(
                    "${data['total']} EGP",
                    style: const TextStyle(
                      color: Color(0xFF6EA6C1),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BannerSlider extends StatefulWidget {
  final bool isAdmin;

  BannerSlider({required this.isAdmin});

  @override
  _BannerSliderState createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> {
  late PageController _controller;
  int currentPage = 0;
  Timer? timer;
  int bannersLength = 0;
  bool isUploading = false;

  @override
  void initState() {
    super.initState();

    _controller = PageController(
      viewportFraction: 0.9,
      initialPage: 1000,
    );

    currentPage = 1000;

    timer = Timer.periodic(Duration(seconds: 3), (Timer timer) {
      if (_controller.hasClients) {
        currentPage++;

        _controller.animateToPage(
          currentPage,
          duration: Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<String?> uploadBannerToCloudinary() async {
    try {
      final picker = ImagePicker();

      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile == null) return null;

      setState(() {
        isUploading = true;
      });

      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          pickedFile.path,
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      setState(() {
        isUploading = false;
      });

      return response.secureUrl;
    } catch (e) {
      setState(() {
        isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Upload Failed ❌"),
        ),
      );

      return null;
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('banners')
          .snapshots(),
      builder: (context, snapshot) {
        var banners = snapshot.hasData
            ? snapshot.data!.docs
            : [];

        bannersLength = banners.length;

        return Column(
  children: [
    SizedBox(
      height: 190,

      child: Stack(
        children: [

          /// 🔥 LOADING
          if (!snapshot.hasData)
            Center(
              child: CircularProgressIndicator(),
            )

          /// 🔥 EMPTY
          else if (banners.isEmpty)
            Center(
              child: Text(
                "No Banners",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            )

          /// 🔥 BANNERS
          else
            PageView.builder(
              controller: _controller,
              itemCount: null,

              onPageChanged: (index) {
                setState(() {
                  currentPage = index;
                });
              },

              itemBuilder: (context, index) {

                var data =
                    banners[index % banners.length];

                return AnimatedBuilder(
                  animation: _controller,

                  builder: (context, child) {

                    double value = 1;
                    double parallax = 0;

                    if (_controller
                        .position
                        .haveDimensions) {

                      double page =
                          _controller.page ?? 0;

                      value = (1 -
                              ((page - index)
                                      .abs() *
                                  0.2))
                          .clamp(0.85, 1.0);

                      parallax =
                          (page - index) * 40;
                    }

                    return Transform.scale(
                      scale: value,

                      child: Transform.translate(
                        offset: Offset(
                          parallax,
                          0,
                        ),

                        child: child,
                      ),
                    );
                  },

                  child: Stack(
                    children: [

                      /// 🔥 BANNER IMAGE
                      Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: 6,
                        ),

                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(24),

                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withOpacity(.35),

                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),

                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(24),

                          child: Image.network(
                            data['image'],

                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                      ),

                      /// 🔥 DARK OVERLAY
                      Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: 6,
                        ),

                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(24),

                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,

                            colors: [
                              Colors.black.withOpacity(.15),
                              Colors.black.withOpacity(.05),
                            ],
                          ),
                        ),
                      ),

                      /// 🔥 MORE BUTTON
                      if (widget.isAdmin)
                        Positioned(
                          top: 12,
                          right: 18,

                          child: PopupMenuButton<String>(
                            color: Color(0xFF111827),

                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                      18),
                            ),

                            onSelected:
                                (value) async {

                              /// ➕ ADD
                              if (value == "add") {

                                String? imageUrl =
                                    await uploadBannerToCloudinary();

                                if (imageUrl != null) {

                                  await FirebaseFirestore
                                      .instance
                                      .collection(
                                          'banners')
                                      .add({
                                    "image":
                                        imageUrl,
                                  });

                                  ScaffoldMessenger.of(
                                          context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Banner Added ✅",
                                      ),
                                    ),
                                  );
                                }
                              }

                              /// ✏️ EDIT
                              if (value == "edit") {

                                String? newImage =
                                    await uploadBannerToCloudinary();

                                if (newImage != null) {

                                  await FirebaseFirestore
                                      .instance
                                      .collection(
                                          'banners')
                                      .doc(data.id)
                                      .update({
                                    "image":
                                        newImage,
                                  });

                                  ScaffoldMessenger.of(
                                          context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Banner Updated ✅",
                                      ),
                                    ),
                                  );
                                }
                              }

                              /// 🗑 DELETE
                              if (value == "delete") {

                                await FirebaseFirestore
                                    .instance
                                    .collection(
                                        'banners')
                                    .doc(data.id)
                                    .delete();

                                ScaffoldMessenger.of(
                                        context)
                                    .showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Banner Deleted 🗑",
                                    ),
                                  ),
                                );
                              }
                            },

                            itemBuilder: (context) => [

                              /// ➕ ADD
                              PopupMenuItem(
                                value: "add",

                                child: Row(
                                  children: [

                                    Icon(
                                      Icons.add,
                                      color: Color(
                                          0xFF6EA6C1),
                                    ),

                                    SizedBox(width: 10),

                                    Text(
                                      "Add Banner",

                                      style: TextStyle(
                                        color:
                                            Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              /// ✏️ EDIT
                              PopupMenuItem(
                                value: "edit",

                                child: Row(
                                  children: [

                                    Icon(
                                      Icons.edit,
                                      color: Color(
                                          0xFF6EA6C1),
                                    ),

                                    SizedBox(width: 10),

                                    Text(
                                      "Edit Banner",

                                      style: TextStyle(
                                        color:
                                            Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              /// 🗑 DELETE
                              PopupMenuItem(
                                value: "delete",

                                child: Row(
                                  children: [

                                    Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),

                                    SizedBox(width: 10),

                                    Text(
                                      "Delete Banner",

                                      style: TextStyle(
                                        color:
                                            Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            child: Container(
                              width: 48,
                              height: 48,

                              decoration: BoxDecoration(
                                shape: BoxShape.circle,

                                color: Colors.black
                                    .withOpacity(.45),

                                border: Border.all(
                                  color: Colors.white10,
                                ),

                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withOpacity(.3),

                                    blurRadius: 10,
                                    offset: Offset(
                                      0,
                                      4,
                                    ),
                                  ),
                                ],
                              ),

                              child: isUploading
                                  ? Padding(
                                      padding:
                                          EdgeInsets.all(
                                              12),

                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color:
                                            Colors.white,
                                      ),
                                    )
                                  : Icon(
                                      Icons.more_vert,
                                      color:
                                          Colors.white,
                                    ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    ),

    /// 🔥 INDICATOR
    if (banners.isNotEmpty)
      Padding(
        padding: EdgeInsets.only(top: 10),

        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: List.generate(
            banners.length,

            (index) {

              bool active =
                  currentPage % banners.length ==
                      index;

              return AnimatedContainer(
                duration: Duration(
                  milliseconds: 300,
                ),

                margin: EdgeInsets.symmetric(
                  horizontal: 4,
                ),

                width: active ? 18 : 7,
                height: 7,

                decoration: BoxDecoration(

                  borderRadius:
                      BorderRadius.circular(20),

                  gradient: active
                      ? LinearGradient(
                          colors: [
                            Color(0xFF6EA6C1),
                            Color(0xFF3B82F6),
                          ],
                        )
                      : null,

                  color: active
                      ? null
                      : Colors.grey.shade700,

                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: Color(0xFF6EA6C1)
                                .withOpacity(.5),

                            blurRadius: 8,
                          ),
                        ]
                      : [],
                ),
              );
            },
          ),
        ),
      ),
  ],
);
      },
    );
  }
}