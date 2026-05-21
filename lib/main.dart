import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

// ✳️ ايميل الادمن
const String adminEmail = "youssef.hisham1771@gmail.com";

final cloudinary = CloudinaryPublic(
  'dzlorraqi',
  'Medlife',
  cache: false,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp());
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
      ),

      darkTheme: ThemeData(
        brightness: Brightness.dark,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
      ),

      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,

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
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    /// 🎬 Animation Controller
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );

    /// ✨ Fade
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    /// 🔍 Scale
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    /// 🔥 نسمع لحالة اليوزر
    FirebaseAuth.instance.authStateChanges().listen((user) {
      Future.delayed(Duration(milliseconds: 1800), () {
        if (!mounted) return;

        if (user == null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => LoginScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => ProductsScreen()),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Image.asset(
              "assets/logo.png",
              width: 200,
            ),
          ),
        ),
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
  bool isPasswordHidden = true;

  Future<void> login() async {
    if (emailController.text.trim().isEmpty ||
        passController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("اكتب الايميل والباسورد")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passController.text.trim(),
      );

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
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 25),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// 🔥 TITLE
              Text(
                "Welcome Back 👋",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 8),

              Text(
                "Login to your account",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),

              SizedBox(height: 35),

              /// 📧 EMAIL
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: "Email",
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 15, vertical: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              SizedBox(height: 15),

              /// 🔑 PASSWORD
              TextField(
                controller: passController,
                obscureText: isPasswordHidden,
                decoration: InputDecoration(
                  hintText: "Password",
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 15, vertical: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
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

              SizedBox(height: 30),

              /// 🔥 LOGIN BUTTON
              isLoading
                  ? Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(
                          "Login",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),

              SizedBox(height: 15),

              /// 🔁 REGISTER
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => RegisterScreen()),
                    );
                  },
                  child: Text(
                    "Don't have an account? Register",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passController.dispose();
    super.dispose();
  }
}

///////////////////// 🔐 REGISTER (MODERN CLEAN UI) /////////////////////

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

    if (pass.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("الباسورد لازم يكون 6 حروف على الأقل")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      /// 🔐 إنشاء الحساب
      final userCred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: pass.text.trim(),
      );

      /// 🔥 حفظ بيانات اليوزر
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCred.user!.uid)
          .set({
        'name': name.text.trim(),
        'phone': phone.text.trim(),
        'email': email.text.trim(),
        'role': 'user',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Account Created Successfully 🎉")),
      );

if (mounted) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => ProductsScreen()),
  );
}

    } on FirebaseAuthException catch (e) {
      String message = "حصل خطأ";

      if (e.code == 'email-already-in-use') {
        message = "الايميل مستخدم بالفعل";
      } else if (e.code == 'invalid-email') {
        message = "الايميل غير صحيح";
      } else if (e.code == 'weak-password') {
        message = "الباسورد ضعيف";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      print("ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Register Error ❌")),
      );
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 25),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              SizedBox(height: 40),

              /// 🔥 TITLE
              Text(
                "Create Account 🚀",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 8),

              Text(
                "Sign up to get started",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),

              SizedBox(height: 30),

              /// 👤 NAME
              TextField(
                controller: name,
                decoration: InputDecoration(
                  hintText: "Full Name",
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 15, vertical: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              SizedBox(height: 15),

              /// 📱 PHONE
              TextField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: "Phone",
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 15, vertical: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              SizedBox(height: 15),

              /// 📧 EMAIL
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: "Email",
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 15, vertical: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              SizedBox(height: 15),

              /// 🔑 PASSWORD
              TextField(
                controller: pass,
                obscureText: isPasswordHidden,
                decoration: InputDecoration(
                  hintText: "Password",
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 15, vertical: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
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

              SizedBox(height: 30),

              /// 🔥 REGISTER BUTTON
              isLoading
                  ? Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(
                          "Register",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),

              SizedBox(height: 15),

              /// 🔁 LOGIN
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Already have an account? Login",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),

              SizedBox(height: 20),
            ],
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
          childAspectRatio: 0.75,
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
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.vertical(
                              top: Radius.circular(15)),
                          child: Image.network(
                            images.isNotEmpty ? images[0] : "",
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Text(
                              data['name'],
                              style: TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                            Text("${data['price']} EGP"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                /// ❤️ Favorite
                Positioned(
                  top: 10,
                  left: 10,
                  child: GestureDetector(
                    onTap: () {
                      var item = {
                        "name": data['name'],
                        "price": data['price'],
                        "image": images.isNotEmpty ? images[0] : "",
                      };

                      toggleFavourite(item);
                    },
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? Colors.red : Colors.grey,
                      ),
                    ),
                  ),
                ),

                /// 🔥 Admin Controls
                if (isAdmin)
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Column(
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddEditProductScreen(
                                  docId: product.id,
                                  oldData: data,
                                ),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('Products')
                                .doc(product.id)
                                .delete();
                          },
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
        style: TextStyle(fontSize: 18),
      ),
    );
  }

  return GridView.builder(
    padding: EdgeInsets.all(10),
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      childAspectRatio: 0.75,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
    ),
    itemCount: favourites.length,
    itemBuilder: (context, index) {
      var item = favourites[index];

      return Stack(
        children: [
          Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(15)),
                    child: Image.network(
                      item["image"],
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Text(
                        item["name"],
                        style: TextStyle(
                            fontWeight: FontWeight.bold),
                      ),
                      Text("${item["price"]} EGP"),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ❤️ remove from favourites
          Positioned(
            top: 10,
            left: 10,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  favourites.removeAt(index);
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text("Removed from Favourites ❌")),
                );
              },
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.favorite,
                  color: Colors.red,
                ),
              ),
            ),
          ),
        ],
      );
    },
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
  title: Text(
  currentIndex == 0
      ? "MedLife"
      : currentIndex == 1
          ? "Cart 🛒"
          : currentIndex == 2
              ? "Favourites ❤️"
              : "My Orders 🛍",
    style: GoogleFonts.poppins(
      fontSize: 26,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.5,
    ),
  ),
  actions: [
    Padding(
  padding: const EdgeInsets.symmetric(horizontal: 6),
  child: GestureDetector(
    onTap: () {
      MyApp.of(context)!.toggleTheme();
    },
    child: AnimatedContainer(
      duration: Duration(milliseconds: 250),
      width: 58,
      height: 32,
      padding: EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),

        // 🔥 الخلفية الرمادي الثابتة
        color: Colors.grey.shade300,

        border: Border.all(
          color: Colors.grey.shade400,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MyApp.of(context)!.isDark
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
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
    icon: Icon(Icons.admin_panel_settings),
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
    ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddEditProductScreen(),
            ),
          );
        },
        child: Icon(Icons.add),
      )
    : null,

bottomNavigationBar: BottomNavigationBar(
  currentIndex: currentIndex,

  backgroundColor: MyApp.of(context)!.isDark
      ? Colors.black
      : Colors.white,

  selectedItemColor: MyApp.of(context)!.isDark
      ? Colors.white
      : Colors.deepPurple,

  unselectedItemColor: Colors.grey,

  type: BottomNavigationBarType.fixed,
  elevation: 10,

  onTap: (i) {
    setState(() {
      currentIndex = i;
    });
  },

 items: [
  const BottomNavigationBarItem(
    icon: Icon(Icons.store),
    label: "Products",
  ),

  /// 🛒 CART
 BottomNavigationBarItem(
  icon: StreamBuilder(
    stream: FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .collection('cart')
        .snapshots(),
    builder: (context, snapshot) {

      int count = snapshot.data?.docs.length ?? 0;

      return buildBadge(
        icon: Icons.shopping_cart,
        count: count,
      );
    },
  ),
  label: "Cart",
),

  /// ❤️ FAVOURITES
  BottomNavigationBarItem(
    icon: buildBadge(
      icon: Icons.favorite,
      count: favCount,
    ),
    label: "Favourites",
  ),

  /// 📦 ORDERS (🔥 من Firebase)
  BottomNavigationBarItem(
    icon: StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('userId',
              isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        int count = snapshot.data?.docs.length ?? 0;

        return buildBadge(
          icon: Icons.shopping_bag,
          count: count,
        );
      },
    ),
    label: "My Orders",
  ),
],
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
                      "$totalSales",
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
                      "2000 EGP",
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
                                    "May 31, 2024",

                                    style: TextStyle(
                                      color:
                                          isDark
                                              ? Colors
                                                  .white70
                                              : Colors
                                                  .black54,

                                      fontSize:
                                          12,
                                    ),
                                  ),

                                  const SizedBox(
                                    width: 16,
                                  ),

                                  Container(
                                    width: 7,
                                    height: 7,

                                    decoration:
                                        const BoxDecoration(
                                          color:
                                              Color(
                                                0xFF6DFF4D,
                                              ),

                                          shape:
                                              BoxShape
                                                  .circle,
                                        ),
                                  ),

                                  const SizedBox(
                                    width: 5,
                                  ),

                                  const Text(
                                    "Active",

                                    style:
                                        TextStyle(
                                          color:
                                              Color(
                                                0xFF6DFF4D,
                                              ),

                                          fontSize:
                                              13,

                                          fontWeight:
                                              FontWeight
                                                  .w600,
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

          selectedProductName =
              data['name'];
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
        margin: EdgeInsets.only(top: 60, right: 10, bottom: 60),
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),

          /// 🎨 Gradient
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
            )
          ],
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 👤 USER
            Row(
              children: [
                Container(
  width: 50,
  height: 50,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    color: Colors.white.withOpacity(0.2),

    border: Border.all(
      color: Colors.white,
      width: 2,
    ),
  ),

  child: Icon(
    Icons.person,
    color: Colors.white,
    size: 28,
  ),
),
                SizedBox(width: 10),
                Expanded(
                  child:StreamBuilder(
  stream: FirebaseFirestore.instance
      .collection('users')
      .doc(user?.uid)
      .snapshots(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return Text(
        "Loading...",
        style: TextStyle(color: Colors.white),
      );
    }

    var data = snapshot.data!.data() as Map<String, dynamic>;

    return Text(
      data['name'] ?? "User",
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  },
),
                ),
              ],
            ),

            SizedBox(height: 10),

            /// ✏️ Edit Profile
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProfileScreen()),
                );
              },
              child: Text(
                "My Profile",
                style: TextStyle(color: Colors.white),
              ),
            ),

            Divider(color: Colors.white38),

            ListTile(
  leading: Icon(
    Icons.star_rate_rounded,
    color: Colors.amber,
  ),

  title: Text(
    "Our Customers Reviews",
    style: TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
    ),
  ),

  onTap: () {

    Navigator.push(

      context,

      MaterialPageRoute(

        builder: (_) => ReviewsScreen(),
      ),
    );
  },
),

ListTile(
  leading: Icon(
    Icons.support_agent,
    color: Colors.white,
  ),

  title: Text(
    "Contact Us",
    style: TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
    ),
  ),

  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContactUsScreen(),
      ),
    );
  },
),

            Spacer(),

            /// 🚪 Logout
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text(
                "Logout",
                style: TextStyle(color: Colors.red,
                fontWeight: FontWeight.bold,),
              ),
              onTap: () async {
                await FirebaseAuth.instance.signOut();

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 عنصر في القائمة
  Widget buildItem(
      BuildContext context, IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: TextStyle(color: Colors.white),
      ),
      onTap: () {
        Navigator.pop(context);

        var state =
            context.findAncestorStateOfType<_ProductsScreenState>();

        state?.setState(() {
          state.currentIndex = index;
        });
      },
    );
  }
}

class ReviewsScreen extends StatefulWidget {
  @override
  State<ReviewsScreen> createState() =>
      _ReviewsScreenState();
}

class _ReviewsScreenState
    extends State<ReviewsScreen> {

  final reviewController = TextEditingController();

  int selectedRating = 0;

  bool isLoading = false;

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
                  child: Column(
                    children: [

                      Text(
                        average
                            .toStringAsFixed(1),

                        style: TextStyle(
                          fontSize: 55,
                          fontWeight:
                              FontWeight.bold,

                          color: Colors.white,
                        ),
                      ),

                      SizedBox(height: 8),

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,

                        children: List.generate(
                          5,
                          (index) => Icon(
                            index < average.round()
                                ? Icons.star
                                : Icons.star_border,

                            color: blueColor,
                            size: 30,
                          ),
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

    return Padding(

      padding: EdgeInsets.only(bottom: 14),

      child: Row(
        children: [

          Text(
            "$star",

            style: TextStyle(
              color: Colors.white,
            ),
          ),

          SizedBox(width: 5),

          Icon(
            Icons.star,
            color: Color(0xFF6EA6C1),
            size: 18,
          ),

          SizedBox(width: 12),

          Expanded(
            child: ClipRRect(

              borderRadius:
                  BorderRadius.circular(20),

              child: LinearProgressIndicator(

                value: value,

                minHeight: 10,

                backgroundColor:
                    Colors.white12,

                valueColor:
                    AlwaysStoppedAnimation(
                  Color(0xFF6EA6C1),
                ),
              ),
            ),
          ),

          SizedBox(width: 10),

          Text(
            "${(value * 100).toInt()}%",

            style: TextStyle(
              color: Colors.white70,
            ),
          ),
        ],
      ),
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
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

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
          )
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

                /// 🔥 ICON
                Container(
                  width: 70,
                  height: 70,

                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: bgColor,
                  ),

                  child: Icon(
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
                          fontWeight: FontWeight.bold,

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
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark
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

        backgroundColor:
            isDark
                ? const Color(0xFF141118)
                : Colors.white,

        foregroundColor:
            isDark ? Colors.white : Colors.black,
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
                    : Colors.black.withOpacity(0.04),

                border: Border.all(
                  color: isDark
                      ? Colors.white12
                      : Colors.black12,
                ),
              ),

              child: Icon(
                Icons.support_agent_rounded,
                size: 70,

                color: const Color(0xFF6EA6C1),
              ),
            ),

            SizedBox(height: 30),

            /// 🔥 TITLE
            Text(
              "We're Here For You",

              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,

                color: isDark
                    ? Colors.white
                    : Colors.black,
              ),

              textAlign: TextAlign.center,
            ),

            SizedBox(height: 12),

            /// 🔥 SUBTITLE
            Text(
              "Feel free to contact us anytime you need help.",

              style: TextStyle(
                fontSize: 17,

                color: isDark
                    ? Colors.white70
                    : Colors.black54,
              ),

              textAlign: TextAlign.center,
            ),

            SizedBox(height: 35),

            /// 📸 INSTAGRAM
buildContactCard(
  context: context,

  icon: Icons.camera_alt_rounded,

  iconColor: const Color(0xFF6EA6C1),

  bgColor: const Color(0x336EA6C1),

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

  icon: Icons.facebook_rounded,

  iconColor: const Color(0xFF6EA6C1),

  bgColor: const Color(0x336EA6C1),

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

  icon: Icons.music_note_rounded,

  iconColor: const Color(0xFF6EA6C1),

  bgColor: const Color(0x336EA6C1),

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

  icon: Icons.chat,

  iconColor: const Color(0xFF6EA6C1),

  bgColor: const Color(0x336EA6C1),

  title: "WhatsApp",

  subtitle: "+20 1010 520 993",

  onTap: () {
    openLink(
      "https://wa.me/201010520993",
    );
  },
),

/// 📧 EMAIL
buildContactCard(
  context: context,

  icon: Icons.email_rounded,

  iconColor: const Color(0xFF6EA6C1),

  bgColor: const Color(0x336EA6C1),

  title: "Support Email",

  subtitle: "medlife.supportteam@gmail.com",

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
                borderRadius: BorderRadius.circular(20),

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
                    color: isDark
                        ? Colors.black.withOpacity(0.25)
                        : Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: Offset(0, 5),
                  ),
                ],
              ),

              child: Row(
                children: [

                  Container(
                    padding: EdgeInsets.all(12),

                    decoration: BoxDecoration(
                      shape: BoxShape.circle,

                      color: const Color(0x336EA6C1),
                    ),

                    child: Icon(
                      Icons.shield_outlined,
                      color: const Color(0xFF6EA6C1),
                    ),
                  ),

                  SizedBox(width: 15),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [

                        Text(
                          "We value your privacy",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
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
            )
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
          Icon(Icons.favorite_border, color: Colors.white),

          SizedBox(width: 18),

          Icon(Icons.shopping_bag_outlined,
              color: Colors.white),

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

                                    Positioned(
                                      top: 18,
                                      right: 18,

                                      child: Container(
                                        width: 58,
                                        height: 58,

                                        decoration:
                                            BoxDecoration(
                                          color: Colors
                                              .black54,
                                          shape:
                                              BoxShape
                                                  .circle,
                                        ),

                                        child: Icon(
                                          Icons.zoom_in,
                                          color:
                                              Colors.white,
                                          size: 30,
                                        ),
                                      ),
                                    ),
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

                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .spaceBetween,

                            children: [

                              Text(
                                "Description",

                                style: TextStyle(
                                  color:
                                      Colors.white,
                                  fontSize: 22,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),

                              Icon(
                                Icons.keyboard_arrow_up,
                                color: Colors.white,
                              ),
                            ],
                          ),

                          SizedBox(height: 18),

                          Text(
                            "Our premium scrubs are designed for all-day comfort and performance. Made from high-quality, breathable fabric that keeps you cool and comfortable in every shift.",

                            style: TextStyle(
                              color: Colors.white70,
                              height: 1.6,
                              fontSize: 16,
                            ),
                          ),

                          SizedBox(height: 20),

                          buildBullet(
                              "Modern fit with a flattering silhouette"),

                          buildBullet(
                              "Multiple pockets for convenience"),

                          buildBullet(
                              "Soft, durable, and easy to care for"),

                          buildBullet(
                              "Ideal for healthcare professionals"),
                        ],
                      ),
                    ),

                    SizedBox(height: 18),

                    /// 🔥 SHIPPING
                    buildSection("Shipping & Returns"),

                    SizedBox(height: 14),

                    /// 🔥 REVIEWS
                    buildSection("Reviews (128)"),

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
                              Icons.shopping_bag_outlined,
                              color: Colors.white,
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
  TextEditingController promoController = TextEditingController();

  double discount = 0;
  double percent = 0;

  Future<void> updateQuantityFirebase(int index) async {
    var user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    var cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cart');

    var docId = widget.cart[index]['docId'];

    if (docId != null) {
      await cartRef.doc(docId).update({
        "quantity": widget.cart[index]["quantity"],
      });
    }
  }

  // 🔥 تحميل الكارت من فايربيز
  Future<void> loadCart() async {
    var user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    var snapshot = await FirebaseFirestore.instance
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

  // ❌ حذف منتج
  Future<void> removeFromCartFirebase(int index) async {
    var user = FirebaseAuth.instance.currentUser;
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

  // 🧠 الحساب
  double getTotalBeforeDiscount() {
    double t = 0;

    for (var item in widget.cart) {
      t += double.parse(item["price"].toString()) *
          (item["quantity"] ?? 1);
    }

    return t;
  }

  double total() {
    return getTotalBeforeDiscount() - discount;
  }

  // 🎁 برومو كود
  void applyPromo() async {
    var code = promoController.text.trim();

    var snapshot = await FirebaseFirestore.instance
        .collection('promoCodes')
        .doc(code)
        .get();

    if (snapshot.exists) {
      percent = (snapshot['discount'] as num).toDouble();

      double t = getTotalBeforeDiscount();

      setState(() {
        discount = t * (percent / 100);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("تم تطبيق خصم $percent%"),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("كود غير صحيح ❌"),
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

    if (FirebaseAuth.instance.currentUser == null) {

      Future.microtask(() {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => LoginScreen(),
          ),
        );
      });

      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B0713),

      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0713),
        elevation: 0,

        title: Text(
          "Cart (${widget.cart.length})",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 32,
            color: Colors.white,
          ),
        ),
      ),

      body: widget.cart.isEmpty
          ? Center(
              child: Text(
                "Cart is empty",
                style: TextStyle(color: Colors.white),
              ),
            )
          : ListView(
              padding: EdgeInsets.all(16),
              children: [

                /// 🛒 المنتجات
                ...List.generate(widget.cart.length, (i) {

                  return Container(
                    margin: EdgeInsets.only(bottom: 16),

                    padding: EdgeInsets.all(14),

                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),

                      color: const Color(0xFF141118),

                      border: Border.all(
                        color: Colors.white10,
                      ),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),

                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [

                        /// 📸 صورة المنتج
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(18),

                          child: Image.network(
                            widget.cart[i]["image"],

                            width: 110,
                            height: 110,
                            fit: BoxFit.cover,
                          ),
                        ),

                        SizedBox(width: 14),

                        /// 🔥 البيانات
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,

                            children: [

                              Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,

                                children: [

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,

                                      children: [

                                        Text(
                                          widget.cart[i]["name"],

                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight:
                                                FontWeight.bold,
                                          ),
                                        ),

                                        SizedBox(height: 6),

                                        Text(
                                          "${widget.cart[i]["price"]} EGP",

                                          style: TextStyle(
                                            color: Color(0xFF6EA6C1),
                                            fontSize: 18,
                                            fontWeight:
                                                FontWeight.w600,
                                          ),
                                        ),

                                        SizedBox(height: 5),

                                        Text(
                                          "Size: ${widget.cart[i]["size"]}",

                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  /// 🗑 حذف
                                  IconButton(
                                    onPressed: () async {

                                      await removeFromCartFirebase(i);

                                      setState(() {

                                        widget.cart.removeAt(i);
                                      });

                                      double t =
                                          getTotalBeforeDiscount();

                                      discount =
                                          t * (percent / 100);
                                    },

                                    icon: Icon(
                                      Icons.delete_outline_rounded,
                                      color: Color(0xFF6EA6C1),
                                      size: 30,
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 14),

                              /// ➖➕ الكمية
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,

                                children: [

                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(
                                              14),

                                      border: Border.all(
                                        color: Colors.white10,
                                      ),
                                    ),

                                    child: Row(
                                      children: [

                                        IconButton(
                                          icon: Icon(
                                            Icons.remove,
                                            color: Colors.white,
                                          ),

                                          onPressed: () async {

                                            if ((widget.cart[i]
                                                        ["quantity"] ??
                                                    1) >
                                                1) {

                                              setState(() {

                                                widget.cart[i]
                                                    ["quantity"]--;
                                              });

                                              await updateQuantityFirebase(
                                                  i);
                                            }
                                          },
                                        ),

                                        Text(
                                          "${widget.cart[i]["quantity"] ?? 1}",

                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight:
                                                FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),

                                        IconButton(
                                          icon: Icon(
                                            Icons.add,
                                            color: Colors.white,
                                          ),

                                          onPressed: () async {

                                            setState(() {

                                              widget.cart[i]
                                                  ["quantity"]++;
                                            });

                                            await updateQuantityFirebase(
                                                i);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),

                                  /// 💰 السعر النهائي
                                  Text(
                                    "${(double.parse(widget.cart[i]["price"].toString()) * (widget.cart[i]["quantity"] ?? 1)).toStringAsFixed(0)} EGP",

                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
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
                }),

                /// 🎁 Promo Code
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),

                  decoration: BoxDecoration(
                    color: const Color(0xFF141118),

                    borderRadius:
                        BorderRadius.circular(20),

                    border: Border.all(
                      color: Colors.white10,
                    ),
                  ),

                  child: TextField(
                    controller: promoController,

                    style: TextStyle(color: Colors.white),

                    decoration: InputDecoration(
                      border: InputBorder.none,

                      hintText: "Enter Promo Code",

                      hintStyle:
                          TextStyle(color: Colors.white38),

                      prefixIcon: Icon(
                        Icons.discount_outlined,
                        color: Colors.white38,
                      ),

                      suffixIcon: TextButton(
                        onPressed: applyPromo,

                        child: Text(
                          "Apply",

                          style: TextStyle(
                            color: Color(0xFF6EA6C1),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 18),

                /// 💳 Summary
                Container(
                  padding: EdgeInsets.all(20),

                  decoration: BoxDecoration(
                    color: const Color(0xFF141118),

                    borderRadius:
                        BorderRadius.circular(24),

                    border: Border.all(
                      color: Colors.white10,
                    ),
                  ),

                  child: Column(
                    children: [

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,

                        children: [

                          Text(
                            "Subtotal",

                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 20,
                            ),
                          ),

                          Text(
                            "${getTotalBeforeDiscount().toStringAsFixed(1)} EGP",

                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 12),

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,

                        children: [

                          Text(
                            "Discount",

                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 20,
                            ),
                          ),

                          Text(
                            "- ${discount.toStringAsFixed(1)} EGP",

                            style: TextStyle(
                              color: Color(0xFF6EA6C1),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      Divider(
                        height: 35,
                        color: Colors.white12,
                      ),

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,

                        children: [

                          Text(
                            "Total",

                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          Text(
                            "${total().toStringAsFixed(1)} EGP",

                            style: TextStyle(
                              color: Color(0xFF6EA6C1),
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 22),

                /// ✅ PLACE ORDER
                SizedBox(
                  height: 68,
                  width: double.infinity,

                  child: ElevatedButton.icon(

                    onPressed: () {

                      if (widget.cart.isEmpty) {

                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          SnackBar(
                            content:
                                Text("الكارت فاضي ❌"),
                          ),
                        );

                        return;
                      }

                      showDialog(
                        context: context,

                        builder: (context) {

                          TextEditingController
                              nameController =
                              TextEditingController();

                          TextEditingController
                              phoneController =
                              TextEditingController();

                          return AlertDialog(

                            backgroundColor:
                                const Color(0xFF141118),

                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(20),
                            ),

                            title: Text(
                              "Enter your data",

                              style:
                                  TextStyle(color: Colors.white),
                            ),

                            content: Column(
                              mainAxisSize:
                                  MainAxisSize.min,

                              children: [

                                TextField(
                                  controller:
                                      nameController,

                                  style: TextStyle(
                                      color: Colors.white),

                                  decoration: InputDecoration(
                                    labelText: "Name",

                                    labelStyle: TextStyle(
                                        color: Colors.white70),
                                  ),
                                ),

                                SizedBox(height: 15),

                                TextField(
                                  controller:
                                      phoneController,

                                  style: TextStyle(
                                      color: Colors.white),

                                  decoration: InputDecoration(
                                    labelText: "Phone",

                                    labelStyle: TextStyle(
                                        color: Colors.white70),
                                  ),
                                ),
                              ],
                            ),

                            actions: [

                              TextButton(
                                onPressed: () async {

                                  var user = FirebaseAuth
                                      .instance.currentUser;

                                  await FirebaseFirestore
                                      .instance
                                      .collection('orders')
                                      .add({

                                    "userId": user?.uid,

                                    "name":
                                        nameController.text,

                                    "phone":
                                        phoneController.text,

                                    "items": widget.cart
                                        .map((item) {

                                      return {

                                        "name": item["name"],

                                        "price":
                                            item["price"],

                                        "quantity":
                                            item["quantity"] ?? 1,

                                        "image":
                                            item["image"],

                                        "size":
                                            item["size"],
                                      };

                                    }).toList(),

                                    "total": total(),

                                    "orderedAt": FieldValue.serverTimestamp(),
"deliveredAt": null,

                                    "status": "pending"
                                  });

                                  /// 🧹 فضي الكارت
                                  var cartRef =
                                      FirebaseFirestore
                                          .instance
                                          .collection('users')
                                          .doc(user!.uid)
                                          .collection('cart');

                                  var snapshot =
                                      await cartRef.get();

                                  for (var doc
                                      in snapshot.docs) {

                                    await doc.reference
                                        .delete();
                                  }

                                  setState(() {

                                    widget.cart.clear();

                                    discount = 0;
                                  });

                                  Navigator.pop(context);

                                  showDialog(
                                    context: context,

                                    barrierDismissible:
                                        false,

                                    builder: (context) {

                                      return Center(
                                        child: Material(
                                          color:
                                              Colors.transparent,

                                          child: Container(
                                            width:
                                                MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.85,

                                            padding:
                                                EdgeInsets.all(
                                                    20),

                                            decoration:
                                                BoxDecoration(
                                              color:
                                                  const Color(
                                                      0xFF141118),

                                              borderRadius:
                                                  BorderRadius
                                                      .circular(
                                                          24),
                                            ),

                                            child: Column(
                                              mainAxisSize:
                                                  MainAxisSize
                                                      .min,

                                              children: [

                                                Icon(
                                                  Icons
                                                      .check_circle,

                                                  color: Color(
                                                      0xFF6EA6C1),

                                                  size: 70,
                                                ),

                                                SizedBox(
                                                    height:
                                                        20),

                                                Text(
                                                  "Order Sent",

                                                  style:
                                                      TextStyle(
                                                    color: Colors
                                                        .white,

                                                    fontSize:
                                                        24,

                                                    fontWeight:
                                                        FontWeight
                                                            .bold,
                                                  ),
                                                ),

                                                SizedBox(
                                                    height:
                                                        12),

                                                Text(
                                                  "سيتم التواصل معك اليوم لتأكيد الأوردر وتحديد مكان الاستلام",

                                                  textAlign:
                                                      TextAlign
                                                          .center,

                                                  style:
                                                      TextStyle(
                                                    color: Colors
                                                        .white70,

                                                    fontSize:
                                                        16,
                                                  ),
                                                ),

                                                SizedBox(
                                                    height:
                                                        10),

                                                Text(
                                                  "الاستلام يكون خلال يومين 💨",

                                                  textAlign:
                                                      TextAlign
                                                          .center,

                                                  style:
                                                      TextStyle(
                                                    color: Colors
                                                        .white70,

                                                    fontSize:
                                                        16,
                                                  ),
                                                ),

                                                SizedBox(
                                                    height:
                                                        22),

                                                SizedBox(
                                                  width:
                                                      double.infinity,

                                                  height: 55,

                                                  child:
                                                      ElevatedButton(
                                                    onPressed:
                                                        () {

                                                      Navigator.pop(
                                                          context);
                                                    },

                                                    style:
                                                        ElevatedButton
                                                            .styleFrom(

                                                      backgroundColor:
                                                          Color(
                                                              0xFF6EA6C1),

                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                18),
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

                                  style: TextStyle(
                                    color: Color(0xFF6EA6C1),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },

                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF6EA6C1),

                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(22),
                      ),
                    ),

                    icon: Icon(
                      Icons.shopping_bag_outlined,
                      color: Colors.white,
                    ),

                    label: Text(
                      "Place Order",

                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
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

  List<String> imageUrls = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    if (widget.oldData != null) {
      name.text = widget.oldData['name']?.toString() ?? "";
      price.text = widget.oldData['price']?.toString() ?? "";

      if (widget.oldData['images'] != null) {
        imageUrls =
            List<String>.from(widget.oldData['images']);
      }
    }
  }

  Future<void> pickAndUploadImage() async {
    final picker = ImagePicker();

    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

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
          imageUrls.add(data['secure_url']);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Image Uploaded Successfully ✅"),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Upload Failed ❌"),
        ),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> saveProduct() async {
    if (name.text.isEmpty ||
        price.text.isEmpty ||
        imageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please complete all fields"),
        ),
      );
      return;
    }

    var data = {
      "name": name.text.trim(),
      "price": price.text.trim(),
      "images": imageUrls,
    };

    if (widget.docId == null) {
      await FirebaseFirestore.instance
          .collection('Products')
          .add(data);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Product Added ✅"),
        ),
      );
    } else {
      await FirebaseFirestore.instance
          .collection('Products')
          .doc(widget.docId)
          .update(data);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Product Updated ✅"),
        ),
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.docId == null
              ? "Add Product"
              : "Edit Product",
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: name,
                decoration: InputDecoration(
                  labelText: "Product Name",
                  border: OutlineInputBorder(),
                ),
              ),

              SizedBox(height: 15),

              TextField(
                controller: price,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Price",
                  border: OutlineInputBorder(),
                ),
              ),

              SizedBox(height: 20),

              ElevatedButton(
                onPressed: pickAndUploadImage,
                child: Text("Upload Image"),
              ),

              SizedBox(height: 15),

              if (isLoading)
                CircularProgressIndicator(),

              SizedBox(height: 15),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: imageUrls.map((url) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(12),
                        child: Image.network(
                          url,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              imageUrls.remove(url);
                            });
                          },
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.red,
                            child: Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    ],
                  );
                }).toList(),
              ),

              SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: saveProduct,
                  child: Text(
                    widget.docId == null
                        ? "Add Product"
                        : "Update Product",
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    name.dispose();
    price.dispose();
    super.dispose();
  }
}

class AdminOrdersScreen extends StatelessWidget {
  const AdminOrdersScreen({super.key});

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

        title: const Text(
          "Admin Dashboard 📊",

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
            onPressed: () {},

            icon: const Icon(
              Icons.search,
              size: 26,
            ),
          ),

          IconButton(
            onPressed: () {},

            icon: const Icon(
              Icons.filter_list_rounded,
              size: 26,
            ),
          ),

          const SizedBox(width: 6),
        ],
      ),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy(
              'date',
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

              ...List.generate(
                orders.length,
                (i) {
                  var order = orders[i];

                  final data =
                      order.data()
                          as Map<
                            String,
                            dynamic
                          >;

                  List items =
                      data['items'] ?? [];

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
                          children: [
                            Text(
                              "#ORD-${1000 + i}",

                              style:
                                  const TextStyle(
                                    color:
                                        Colors
                                            .white,

                                    fontSize:
                                        20,

                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                            ),

                            const SizedBox(
                              width: 10,
                            ),

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
                                    borderRadius:
                                        BorderRadius.circular(
                                          12,
                                        ),

                                    color:
                                        statusColor
                                            .withOpacity(
                                              0.18,
                                            ),
                                  ),

                              child: Text(
                                status
                                    .toUpperCase(),

                                style:
                                    TextStyle(
                                      color:
                                          statusColor,

                                      fontWeight:
                                          FontWeight
                                              .bold,

                                      fontSize:
                                          12,
                                    ),
                              ),
                            ),

                            const Spacer(),

                            Text(
                              orderedDate,

                              style:
                                  const TextStyle(
                                    color:
                                        Colors
                                            .white54,

                                    fontSize:
                                        12,
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
                                    height: 48,

                                    child: ListView
                                        .builder(
                                      scrollDirection:
                                          Axis.horizontal,

                                      itemCount:
                                          items
                                              .length,

                                      itemBuilder:
                                          (
                                            context,
                                            index,
                                          ) {
                                            var item =
                                                items[index];

                                            return Container(
                                              width:
                                                  48,

                                              margin:
                                                  const EdgeInsets.only(
                                                    right:
                                                        8,
                                                  ),

                                              decoration:
                                                  BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),

                                                    color:
                                                        Colors.white10,
                                                  ),

                                              child:
                                                  item['image'] !=
                                                              null &&
                                                          item['image']
                                                              .toString()
                                                              .isNotEmpty
                                                      ? ClipRRect(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
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
                                  "${items.length} Items",

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
                                String newStatus =
                                    status ==
                                            'delivered'
                                        ? 'pending'
                                        : 'delivered';

                                await FirebaseFirestore
                                    .instance
                                    .collection(
                                      'orders',
                                    )
                                    .doc(
                                      order.id,
                                    )
                                    .update({
                                  "status":
                                      newStatus,
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

  OrderDetailsScreen({required this.order});

  @override
  Widget build(BuildContext context) {
    List items = order['items'] ?? [];

    return Scaffold(
      appBar: AppBar(title: Text("Order Details 📦")),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, i) {
          var item = items[i];

         return ListTile(
  leading: item['image'] != null
      ? Image.network(item['image'])
      : Icon(Icons.image_not_supported),
  title: Text(item['name']),
  subtitle: Text("${item['price']} EGP"),
);
        },
      ),
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

        await user!.updateEmail(
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

  final phoneController = TextEditingController();

  final emailController = TextEditingController();

  final codeController = TextEditingController();

  final newPasswordController =
      TextEditingController();

  String verificationId = "";

  bool codeSent = false;

  bool obscurePassword = true;

  bool useEmail = true;

  Future<void> sendCode() async {

    if (useEmail) {

      try {

        await FirebaseAuth.instance
            .sendPasswordResetEmail(
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

    } else {

      try {

        String phone = phoneController.text.trim();

        if (phone.startsWith('0')) {
          phone = '+2$phone';
        }

        await FirebaseAuth.instance.verifyPhoneNumber(

          phoneNumber: phone,

          verificationCompleted:
              (PhoneAuthCredential credential) {},

          verificationFailed:
              (FirebaseAuthException e) {

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(e.message ?? "Error"),
              ),
            );
          },

          codeSent:
              (String verId, int? resendToken) {

            verificationId = verId;

            setState(() {
              codeSent = true;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Code Sent ✅"),
              ),
            );
          },

          codeAutoRetrievalTimeout:
              (String verId) {},
        );

      } catch (e) {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Something went wrong"),
          ),
        );
      }
    }
  }

  Future<void> verifyCodeAndChangePassword() async {

    try {

      PhoneAuthCredential credential =
          PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: codeController.text.trim(),
      );

      await FirebaseAuth.instance
          .signInWithCredential(credential);

      await FirebaseAuth.instance.currentUser!
          .updatePassword(
        newPasswordController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text("Password Changed Successfully ✅"),
        ),
      );

      Navigator.pop(context);

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Invalid Code ❌"),
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

            /// 🔥 TOP ICON
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
                    useEmail
                        ? Icons.lock_reset_rounded
                        : Icons.phone_android_rounded,

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
                        useEmail
                            ? Icons.email_outlined
                            : Icons.phone,

                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 25),

            /// 🔥 TITLE
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

            /// 🔥 SUBTITLE
            Text(

              useEmail
                  ? "Enter your email address and we’ll send you a link to reset your password. (CHECK SPAM!!)"
                  : "Enter your phone number and we’ll send you a code to reset your password. (CHECK SPAM!!)",

              textAlign: TextAlign.center,

              style: TextStyle(
                color: Colors.white70,
                fontSize: 20,
                height: 1.5,
              ),
            ),

            SizedBox(height: 40),

            /// 🔥 TOGGLE BUTTONS
            Container(
              padding: EdgeInsets.all(5),

              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),

                border: Border.all(
                  color: Colors.white12,
                ),

                color: const Color(0xFF1D1B20),
              ),

              child: Row(
                children: [

                  /// EMAIL
                  Expanded(
                    child: GestureDetector(

                      onTap: () {
                        setState(() {
                          useEmail = true;
                          codeSent = false;
                        });
                      },

                      child: AnimatedContainer(
                        duration:
                            Duration(milliseconds: 250),

                        padding: EdgeInsets.symmetric(
                          vertical: 16,
                        ),

                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(40),

                          gradient: useEmail
                              ? LinearGradient(
                                  colors: [
                                    Color(0xFF6EA6C1),
                                    Color(0xFF8CC6E3),
                                  ],
                                )
                              : null,
                        ),

                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [

                            Icon(
                              Icons.email_outlined,
                              color: Colors.white,
                            ),

                            SizedBox(width: 10),

                            Text(
                              "Email",

                              style: TextStyle(
                                color: Colors.white,
                                fontWeight:
                                    FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),

                            if (useEmail) ...[
                              SizedBox(width: 10),

                              Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20,
                              ),
                            ]
                          ],
                        ),
                      ),
                    ),
                  ),

                  /// PHONE
                  Expanded(
                    child: GestureDetector(

                      onTap: () {
                        setState(() {
                          useEmail = false;
                          codeSent = false;
                        });
                      },

                      child: AnimatedContainer(
                        duration:
                            Duration(milliseconds: 250),

                        padding: EdgeInsets.symmetric(
                          vertical: 16,
                        ),

                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(40),

                          gradient: !useEmail
                              ? LinearGradient(
                                  colors: [
                                    Color(0xFF6EA6C1),
                                    Color(0xFF8CC6E3),
                                  ],
                                )
                              : null,
                        ),

                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [

                            Icon(
                              Icons.phone_outlined,
                              color: Colors.white,
                            ),

                            SizedBox(width: 10),

                            Text(
                              "Phone",

                              style: TextStyle(
                                color: Colors.white,
                                fontWeight:
                                    FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),

                            if (!useEmail) ...[
                              SizedBox(width: 10),

                              Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20,
                              ),
                            ]
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 35),

            /// 🔥 INPUT TITLE
            Align(
              alignment: Alignment.centerLeft,

              child: Text(
                useEmail
                    ? "Email Address"
                    : "Phone Number",

                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            SizedBox(height: 15),

            /// 🔥 TEXT FIELD
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

                controller:
                    useEmail
                        ? emailController
                        : phoneController,

                keyboardType:
                    useEmail
                        ? TextInputType.emailAddress
                        : TextInputType.phone,

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
                      useEmail
                          ? "Enter your email address"
                          : "Enter your phone number",

                  hintStyle: TextStyle(
                    color: Colors.white38,
                    fontSize: 18,
                  ),

                  prefixIcon: Icon(
                    useEmail
                        ? Icons.email_outlined
                        : Icons.phone_outlined,

                    color: Color(0xFF6EA6C1),
                    size: 28,
                  ),
                ),
              ),
            ),

            SizedBox(height: 35),

            /// 🔥 BUTTON
            if (!codeSent || useEmail)
              SizedBox(
                width: double.infinity,
                height: 68,

                child: ElevatedButton(

                  style: ElevatedButton.styleFrom(

                    backgroundColor:
                        const Color(0xFF6EA6C1),

                    elevation: 12,

                    shadowColor:
                        const Color(0x886EA6C1),

                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(40),
                    ),
                  ),

                  onPressed: sendCode,

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
                        useEmail
                            ? "Send Reset Email"
                            : "Send Code",

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

            /// 🔥 PHONE VERIFY SECTION
            if (codeSent && !useEmail) ...[

              SizedBox(height: 35),

              /// CODE FIELD
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

                  controller: codeController,

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

                    hintText: "Verification Code",

                    hintStyle: TextStyle(
                      color: Colors.white38,
                      fontSize: 18,
                    ),

                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: Color(0xFF6EA6C1),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 25),

              /// PASSWORD FIELD
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

                  controller:
                      newPasswordController,

                  obscureText: obscurePassword,

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

                    hintText: "New Password",

                    hintStyle: TextStyle(
                      color: Colors.white38,
                      fontSize: 18,
                    ),

                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: Color(0xFF6EA6C1),
                    ),

                    suffixIcon: IconButton(

                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,

                        color: Colors.white70,
                      ),

                      onPressed: () {

                        setState(() {
                          obscurePassword =
                              !obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
              ),

              SizedBox(height: 30),

              /// CHANGE PASSWORD BUTTON
              SizedBox(
                width: double.infinity,
                height: 68,

                child: ElevatedButton(

                  style: ElevatedButton.styleFrom(

                    backgroundColor:
                        const Color(0xFF6EA6C1),

                    elevation: 12,

                    shadowColor:
                        const Color(0x886EA6C1),

                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(40),
                    ),
                  ),

                  onPressed:
                      verifyCodeAndChangePassword,

                  child: Text(
                    "Change Password",

                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],

            SizedBox(height: 35),

            /// 🔒 PRIVACY
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

                      useEmail
                          ? "We’ll never share your email with anyone else."
                          : "We’ll never share your phone number with anyone else.",

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
                  "Delivery",
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
                        "01066813466",
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
                          OrderDetailsScreen(order: order),
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
                  if (!snapshot.hasData)
                    Center(
                      child: CircularProgressIndicator(),
                    )
                  else if (banners.isEmpty)
                    Center(
                      child: Text("No Banners"),
                    )
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
                                .position.haveDimensions) {
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
                                offset:
                                    Offset(parallax, 0),
                                child: child,
                              ),
                            );
                          },
                          child: Stack(
                            children: [
                              Container(
                                margin:
                                    EdgeInsets.symmetric(
                                        horizontal: 6),
                                child: ClipRRect(
                                  borderRadius:
                                      BorderRadius
                                          .circular(15),
                                  child: Image.network(
                                    data['image'],
                                    fit: BoxFit.cover,
                                    width:
                                        double.infinity,
                                  ),
                                ),
                              ),

                              if (widget.isAdmin)
                                Positioned(
                                  top: 10,
                                  right: 20,
                                  child: Row(
                                    children: [
                                      /// ✏️ Edit
                                      IconButton(
                                        icon: Icon(
                                          Icons.edit,
                                          color:
                                              Colors.blue,
                                        ),
                                        onPressed:
                                            () async {
                                          String?
                                              newImage =
                                              await uploadBannerToCloudinary();

                                          if (newImage !=
                                              null) {
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
                                                content:
                                                    Text(
                                                  "Banner Updated ✅",
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                      ),

                                      /// 🗑 Delete
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete,
                                          color:
                                              Colors.red,
                                        ),
                                        onPressed:
                                            () async {
                                          await FirebaseFirestore
                                              .instance
                                              .collection(
                                                  'banners')
                                              .doc(data.id)
                                              .delete();
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),

                  /// ➕ Add Banner
                  if (widget.isAdmin)
                    Positioned(
                      bottom: 10,
                      right: 20,
                      child: FloatingActionButton(
                        mini: true,
                        child: isUploading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(Icons.add),
                        onPressed: () async {
                          String? imageUrl =
                              await uploadBannerToCloudinary();

                          if (imageUrl != null) {
                            await FirebaseFirestore
                                .instance
                                .collection('banners')
                                .add({
                              "image": imageUrl,
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
                        },
                      ),
                    ),
                ],
              ),
            ),

            if (banners.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: List.generate(
                    banners.length,
                    (index) {
                      return AnimatedContainer(
                        duration: Duration(
                            milliseconds: 300),
                        margin:
                            EdgeInsets.symmetric(
                                horizontal: 3),
                        width: currentPage %
                                    banners.length ==
                                index
                            ? 12
                            : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: currentPage %
                                      banners.length ==
                                  index
                              ? Colors.black
                              : Colors.grey,
                          borderRadius:
                              BorderRadius.circular(
                                  10),
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