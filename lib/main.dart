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
 bool isAdmin = false;

 bool salesSeen = false;

@override
void initState() {
  super.initState();
  loadFavourites();
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

          bool isFav = favourites.any((e) => e['name'] == data['name']);

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductDetailsScreen(
                    product: product,
                    cart: cart,
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

    int cartCount = cart.length;
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
            color: Colors.white,
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
    icon: buildBadge(
      icon: Icons.shopping_cart,
      count: cartCount,
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
    return Scaffold(

      appBar: AppBar(
        title: Text("Sales 🔥"),
      ),

      /// 👑 زر إضافة عرض
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              backgroundColor: Colors.orange,
              child: Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddSaleScreen(),
                  ),
                );
              },
            )
          : null,

      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('sales')
            .orderBy('createdAt', descending: true)
            .snapshots(),

        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          var sales = snapshot.data!.docs;

          if (sales.isEmpty) {
            return Center(
              child: Text("No Sales Yet 🔥"),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(15),
            itemCount: sales.length,

            itemBuilder: (context, index) {

              var data =
                  sales[index].data() as Map<String, dynamic>;

              return Container(
                margin: EdgeInsets.only(bottom: 15),
                padding: EdgeInsets.all(15),

                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange,
                      Colors.deepOrange,
                    ],
                  ),
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [

                    Text(
                      data['title'] ?? "",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    SizedBox(height: 10),

                    Text(
                      data['description'] ?? "",
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),

                    SizedBox(height: 15),

                    Row(
                      children: [

                        Icon(
                          Icons.discount,
                          color: Colors.white,
                        ),

                        SizedBox(width: 6),

                        Text(
                          "${data['discount']}% OFF",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

///////////////////// 🔥 ADD SALE SCREEN /////////////////////

class AddSaleScreen extends StatefulWidget {
  @override
  State<AddSaleScreen> createState() => _AddSaleScreenState();
}

class _AddSaleScreenState extends State<AddSaleScreen> {

  String? selectedProductId;
  String? selectedProductName;
  String? selectedImage;

  final titleController = TextEditingController();
  final detailsController = TextEditingController();
  final discountController = TextEditingController();

  DateTime? expiryDate;

  bool isLoading = false;

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

  Future<void> addSale() async {

    if (selectedProductId == null ||
        titleController.text.trim().isEmpty ||
        detailsController.text.trim().isEmpty ||
        discountController.text.trim().isEmpty ||
        expiryDate == null) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Complete all fields")),
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

        "productId": selectedProductId,
        "productName": selectedProductName,
        "image": selectedImage,

        "title": titleController.text.trim(),
        "details": detailsController.text.trim(),

        "discount":
            int.parse(discountController.text.trim()),

        "expiryDate": expiryDate,

        "createdAt": Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Sale Added 🔥")),
      );

      Navigator.pop(context);

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error ❌")),
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

            /// 🔥 SELECT PRODUCT
            Text(
              "Choose Product",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 10),

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
                      child: Text(data['name']),
                    );

                  }).toList(),

                  onChanged: (value) {

                    var selected = products.firstWhere(
                      (p) => p.id == value,
                    );

                    var data =
                        selected.data() as Map<String, dynamic>;

                    List images = data.containsKey('images')
                        ? data['images']
                        : [data['image']];

                    setState(() {

                      selectedProductId = value;
                      selectedProductName = data['name'];

                      selectedImage =
                          images.isNotEmpty ? images[0] : "";
                    });
                  },

                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: 20),

            /// 📝 TITLE
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: "Sale Title",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
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
                  borderRadius: BorderRadius.circular(15),
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
                  borderRadius: BorderRadius.circular(15),
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
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(15),
                ),

                child: Text(
                  expiryDate == null
                      ? "Choose Expiry Date"
                      : "${expiryDate!.day}/${expiryDate!.month}/${expiryDate!.year}",
                ),
              ),
            ),

            SizedBox(height: 30),

            /// 🔥 BUTTON
            SizedBox(
              width: double.infinity,

              child: ElevatedButton(

                onPressed: isLoading ? null : addSale,

                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),

                child: isLoading
                    ? CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : Text("Add Sale"),
              ),
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
              Color(0xFF6DD5FA),
              Color(0xFF2980B9),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
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
                CircleAvatar(
                  radius: 25,
                  backgroundImage: NetworkImage(
                    user?.photoURL ??
                        "https://i.pravatar.cc/150?img=3",
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

            /// 📄 MENU
            buildItem(context, Icons.store, "Products", 0),
            buildItem(context, Icons.shopping_cart, "Cart", 1),
            buildItem(context, Icons.favorite, "Favourites", 2),
            buildItem(context, Icons.shopping_bag, "My Orders", 3),

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
///////////////////// 📦 DETAILS /////////////////////

class ProductDetailsScreen extends StatefulWidget {
  final dynamic product;
  final List<Map<String, dynamic>> cart;

  ProductDetailsScreen({required this.product, required this.cart});

  @override
  State<ProductDetailsScreen> createState() =>
      _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  String selectedSize = "";
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
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 6),
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey,
          ),
        ),
        child: Text(
          size,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var product = widget.product;
var data = widget.product.data() as Map<String, dynamic>;

List images = data.containsKey('images')
    ? data['images']
    : [data['image']];
    return Scaffold(
      appBar: AppBar(
        title: Text(product['name'] ?? "No Name"),
      ),

      // 🔥 الجسم
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [

SizedBox(
  height: 300,
  child:PageView.builder(
  itemCount: images.length,
  onPageChanged: (index) {
    setState(() {
      currentIndex = index;
    });
  },
  itemBuilder: (context, index) {
      return Image.network(
        images[index],
        fit: BoxFit.cover,
        width: double.infinity,
      );
    },
  ),
),
  SizedBox(height: 10),

Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: List.generate(images.length, (index) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4),
      width: currentIndex == index ? 12 : 8,
      height: currentIndex == index ? 12 : 8,
      decoration: BoxDecoration(
        color: currentIndex == index ? Colors.black : Colors.grey,
        shape: BoxShape.circle,
      ),
    );
  }),
),

                  SizedBox(height: 20),

                  Text(
                    product['name'],
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),

                  Text("${product['price']} EGP"),

                  SizedBox(height: 20),

                  // 🔥 المقاسات
                  Text(
                    "Choose Size",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),

                  SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      buildSizeButton("S"),
                      buildSizeButton("M"),
                      buildSizeButton("L"),
                      buildSizeButton("XL"),
                    ],
                  ),

                  SizedBox(height: 25),

                  // 🔢 الكمية
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove),
                        onPressed: () {
                          if (quantity > 1) {
                            setState(() {
                              quantity--;
                            });
                          }
                        },
                      ),
                      Text(
                        "$quantity",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            quantity++;
                          });
                        },
                      ),
                    ],
                  ),

                  SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // 🔥 الزرار تحت ثابت
          Padding(
            padding: EdgeInsets.all(15),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (selectedSize.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text("اختار المقاس الأول")),
                    );
                    return;
                  }

                  var index = widget.cart.indexWhere(
                    (i) =>
                        i['name'] == product['name'] &&
                        i['size'] == selectedSize,
                  );

                  if (index != -1) {
                    widget.cart[index]['quantity'] =
                        (widget.cart[index]['quantity'] ?? 1) +
                            quantity;
                  } else {
                    widget.cart.add({
                      "name": data['name'],
                      "price": data['price'],
                      "image": images.isNotEmpty ? images[0] : "",
                      "size": selectedSize,
                      "quantity": quantity,
                    });
                  }

                  // 🔥 Firebase
                  var user =
                      FirebaseAuth.instance.currentUser;

                  if (user != null) {
                    var cartRef = FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('cart');

                    var existing = await cartRef
                        .where("name",
                            isEqualTo: product['name'])
                        .where("size",
                            isEqualTo: selectedSize)
                        .get();

                    if (existing.docs.isNotEmpty) {
                      var doc = existing.docs.first;

                      await cartRef.doc(doc.id).update({
                        "quantity":
                            (doc['quantity'] ?? 1) +
                                quantity,
                      });
                    } else {
                      await cartRef.add({
                        "name": data['name'],
                        "price": data['price'],
                        "image": images.isNotEmpty ? images[0] : "",
                        "size": selectedSize,
                        "quantity": quantity,
                      });
                    }
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text("Added to cart 🛒")),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                      vertical: 15),
                ),
                child: Text("Add to Cart"),
              ),
            ),
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

  // 💾 حفظ منتج واحد
  Future<void> addToCartFirebase(Map<String, dynamic> item) async {
    var user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .add(item);
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
        SnackBar(content: Text("تم تطبيق خصم $percent%")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("كود غير صحيح ❌")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    loadCart(); // 🔥 أول ما الشاشة تفتح
  }

  @override
  Widget build(BuildContext context) {
    // 🔐 Check Login
    if (FirebaseAuth.instance.currentUser == null) {
      Future.microtask(() {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LoginScreen()),
        );
      });

      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: widget.cart.isEmpty
          ? Center(child: Text("Cart is empty"))
          : ListView.builder(
              itemCount: widget.cart.length,
              itemBuilder: (context, i) {
                return ListTile(
                  leading: Image.network(widget.cart[i]["image"]),
                  title: Text(widget.cart[i]["name"]),
                  subtitle: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text("${widget.cart[i]["price"]} EGP"),
    Text("Size: ${widget.cart[i]["size"]}"),

    SizedBox(height: 5),

    Row(
      children: [
        IconButton(
          icon: Icon(Icons.remove),
          onPressed: () async {
            if ((widget.cart[i]["quantity"] ?? 1) > 1) {
              setState(() {
                widget.cart[i]["quantity"]--;
              });

              await updateQuantityFirebase(i);
            }
          },
        ),

        Text(
          "${widget.cart[i]["quantity"] ?? 1}",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        IconButton(
          icon: Icon(Icons.add),
          onPressed: () async {
            setState(() {
              widget.cart[i]["quantity"]++;
            });

            await updateQuantityFirebase(i);
          },
        ),
      ],
    )
  ],
),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await removeFromCartFirebase(i);

                      setState(() {
                        widget.cart.removeAt(i);
                      });

                      double t = getTotalBeforeDiscount();
                      discount = t * (percent / 100);
                    },
                  ),
                );
              },
            ),

      bottomNavigationBar: Container(
        padding: EdgeInsets.all(15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            TextField(
              controller: promoController,
              decoration: InputDecoration(
                hintText: "Enter Promo Code",
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.check),
                  onPressed: applyPromo,
                ),
              ),
            ),

            SizedBox(height: 10),

            Text("Discount: $discount EGP"),

            SizedBox(height: 10),

            Text("Total: ${total()} EGP"),

            SizedBox(height: 10),

           ElevatedButton(
  onPressed: () {
    if (widget.cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("الكارت فاضي ❌")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        TextEditingController nameController = TextEditingController();
        TextEditingController phoneController = TextEditingController();

        return AlertDialog(
          title: Text("Enter your data"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: "Name"),
              ),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(labelText: "Phone"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                var user = FirebaseAuth.instance.currentUser;

                await FirebaseFirestore.instance.collection('orders').add({
                  "userId": user?.uid,
                  "name": nameController.text,
                  "phone": phoneController.text,
                  "items": widget.cart.map((item) {
  return {
    "name": item["name"],
    "price": item["price"],
    "quantity": item["quantity"] ?? 1,
    "image":item["image"],
    "size": item["size"],
  };
}).toList(),
                  "total": total(),
                  "date": FieldValue.serverTimestamp(),
                  "status": "pending"
                });

                // 🧹 فضي الكارت
                var cartRef = FirebaseFirestore.instance
                    .collection('users')
                    .doc(user!.uid)
                    .collection('cart');

                var snapshot = await cartRef.get();
                for (var doc in snapshot.docs) {
                  await doc.reference.delete();
                }

                setState(() {
                  widget.cart.clear();
                  discount = 0;
                });

                Navigator.pop(context); // يقفل الديالوج
  showDialog(
  context: context,
  barrierDismissible: false, // ❌ مينفعش يقفل بالضغط برا
  builder: (context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                blurRadius: 20,
                color: Colors.black26,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✅ أيقونة
              Icon(Icons.check_circle, color: Colors.green, size: 55),

              SizedBox(height: 15),

              // 🔥 السطر الأول
              Text(
                "Order Sent",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 10),

              // 🔥 السطر الثاني
              Text(
                "سيتم التواصل معك اليوم لتاكيد الاوردر و تحديد مكان الاستلام",
                textAlign: TextAlign.center,

              ),

              SizedBox(height: 10),

              // 🔥 السطر الثالث
              Text(
                "الاستلام يكون في خلال 2 ايام 💨",
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 20),

              // ✅ زرار OK
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // يقفل البوب اب
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text("OK"),
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
              child: Text("Confirm"),
            )
          ],
        );
      },
    );
  },
  child: Text("Place Order"),
)
          ],
        ),
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Dashboard 📊"),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('date', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var orders = snapshot.data!.docs;

          if (orders.isEmpty) {
            return Center(child: Text("No Orders Yet"));
          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, i) {
              var order = orders[i];
              final data = order.data() as Map<String, dynamic>;

              List items = data['items'] ?? [];

              bool isDelivered =
                  (data['status'] ?? 'pending') == 'delivered';

              return Card(
                margin: EdgeInsets.all(10),
                child: ListTile(
                  title: Text("Order #${i + 1}"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Name: ${data['name'] ?? 'No Name'}"),
                      Text("Phone: ${data['phone'] ?? 'No Phone'}"),

                      SizedBox(height: 5),

                      Text(
                        "Order Details:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),

                      SizedBox(height: 5),

                      if (items.isEmpty)
                        Text("No items")
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: items.map<Widget>((item) {
                            return Text(
                                "- ${item['name']} | ${item['size']} | (${item['price']} EGP) | x${item['quantity'] ?? 1}");
                          }).toList(),
                        ),

                      SizedBox(height: 5),

                      Text("Total: ${data['total'] ?? 0} EGP"),
                    ],
                  ),

                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ✅ Checkbox Toggle
                      Row(
                        children: [
                          Checkbox(
                            value: isDelivered,
                            activeColor:
                                isDelivered ? Colors.green : Colors.orange,
                            onChanged: (value) async {
                              String newStatus =
                                  isDelivered ? "pending" : "delivered";

                              await FirebaseFirestore.instance
                                  .collection('orders')
                                  .doc(order.id)
                                  .update({
                                "status": newStatus,
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isDelivered
                                        ? "Order is Pending ⏳"
                                        : "Order marked as Delivered ✅",
                                  ),
                                ),
                              );
                            },
                          ),
                          Text(
                            isDelivered
                                ? "Delivered"
                                : "Mark as Delivered",
                          ),
                        ],
                      ),

                      // 🗑 Delete
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text("Delete Order"),
                                content: Text(
                                    "Are you sure you want to delete this order?"),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      await FirebaseFirestore.instance
                                          .collection('orders')
                                          .doc(order.id)
                                          .delete();

                                      Navigator.pop(context);

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content:
                                                Text("Order deleted ❌")),
                                      );
                                    },
                                    child: Text("Delete",
                                        style:
                                            TextStyle(color: Colors.red)),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),

                      // ➡️ Details
                      IconButton(
                        icon: Icon(Icons.arrow_forward),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  OrderDetailsScreen(order: order),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
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
        isDark ? const Color(0xFF171326) : Colors.white;

    final Color iconBoxColor =
        isDark ? const Color(0xFF2A223D) : const Color(0xFFF3F3F3);

    final Color purpleColor =
        const Color(0xFF8E5CF7);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0D0917) : const Color(0xFFF7F7FA),

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
    color: purpleColor,
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
                                  purpleColor.withOpacity(.2),
                              child: Icon(
                                Icons.person,
                                size: 50,
                                color: purpleColor,
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
                              purpleColor: purpleColor,
                            ),

                            const SizedBox(height: 14),

                            _buildInfoTile(
                              icon: Icons.phone,
                              title: "Phone",
                              value: phone,
                              mainTextColor: mainTextColor,
                              subTextColor: subTextColor,
                              iconBoxColor: iconBoxColor,
                              purpleColor: purpleColor,
                            ),

                            const SizedBox(height: 14),

                            _buildInfoTile(
                              icon: Icons.calendar_month,
                              title: "Member Since",
                              value: "May 2024",
                              mainTextColor: mainTextColor,
                              subTextColor: subTextColor,
                              iconBoxColor: iconBoxColor,
                              purpleColor: purpleColor,
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
                            ),

                            _menuTile(
                              icon: Icons.credit_card,
                              title: "Payment Methods",
                              color: mainTextColor,
                            ),

                            _menuTile(
                              icon: Icons.notifications_none,
                              title: "Notifications",
                              color: mainTextColor,
                            ),

                            _menuTile(
                              icon: Icons.help_outline,
                              title: "Help & Support",
                              color: mainTextColor,
                            ),

                            _menuTile(
  icon: Icons.info_outline,
  title: "About MedLife",
  color: mainTextColor,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AboutMedLifeScreen(),
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
                            await FirebaseAuth.instance
                                .signOut();
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
    required Color purpleColor,
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
            color: purpleColor,
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
  VoidCallback? onTap, // 👈 ضف دي
}) {
  return ListTile(
    leading: Icon(
      icon,
      color: const Color(0xFF8E5CF7),
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
    onTap: onTap, // 👈 استخدمها هنا
  );
}
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;

  final TextEditingController oldPasswordController =
    TextEditingController();

  final TextEditingController newPasswordController =
    TextEditingController();

  final TextEditingController emailController =
    TextEditingController();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  bool obscureOldPassword = true;
  bool obscureNewPassword = true;
  bool isLoading = false;

  final Color purpleColor = const Color(0xFF8E5CF7);

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

  nameController.text = data['name'] ?? '';
  phoneController.text = data['phone'] ?? '';
  emailController.text = data['email'] ?? '';
}
  }

Future<void> saveChanges() async {
  try {
    setState(() {
      isLoading = true;
    });

    /// تحديث الاسم والموبايل
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .update({
      'name': nameController.text.trim(),
      'phone': phoneController.text.trim(),
      'email': emailController.text.trim(),
    });

    /// تحديث الايميل في Authentication
    if (emailController.text.trim() != user!.email) {
      await user!.updateEmail(
        emailController.text.trim(),
      );
    }

    /// تغيير الباسورد
    if (oldPasswordController.text.isNotEmpty &&
        newPasswordController.text.isNotEmpty) {
      AuthCredential credential =
          EmailAuthProvider.credential(
        email: user!.email!,
        password: oldPasswordController.text.trim(),
      );

      await user!.reauthenticateWithCredential(
        credential,
      );

      await user!.updatePassword(
        newPasswordController.text.trim(),
      );
    }

    setState(() {
      isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Profile Updated Successfully ✅"),
      ),
    );

    Navigator.pop(context);
  } on FirebaseAuthException catch (e) {
    setState(() {
      isLoading = false;
    });

    String message = e.message ?? "Error";

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    final bool isDark =
        Theme.of(context).brightness == Brightness.dark;

    final Color bgColor =
        isDark ? const Color(0xFF0D0917) : const Color(0xFFF7F7FA);

    final Color cardColor =
        isDark ? const Color(0xFF171326) : Colors.white;

    final Color textColor =
        isDark ? Colors.white : Colors.black;

    final Color subTextColor =
        isDark ? Colors.white70 : Colors.grey.shade700;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor:
            isDark ? Colors.black : Colors.white,
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
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
        ),
        actions: [
          TextButton(
            onPressed: isLoading ? null : saveChanges,
            child: Text(
              "Save",
              style: TextStyle(
                color: purpleColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor:
                    purpleColor.withOpacity(.2),
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
                controller: nameController,
                label: "Full Name",
                icon: Icons.person_outline,
                textColor: textColor,
                cardColor: cardColor,
              ),

              const SizedBox(height: 18),

              _buildTextField(
  controller: emailController,
  label: "Email Address",
  icon: Icons.email_outlined,
  textColor: textColor,
  cardColor: cardColor,
),

              const SizedBox(height: 18),

              _buildTextField(
                controller: phoneController,
                label: "Phone Number",
                icon: Icons.phone_outlined,
                textColor: textColor,
                cardColor: cardColor,
              ),

const SizedBox(height: 25),

Align(
  alignment: Alignment.centerLeft,
  child: Text(
    "Change Password",
    style: TextStyle(
      color: textColor,
      fontSize: 18,
      fontWeight: FontWeight.bold,
    ),
  ),
),

const SizedBox(height: 18),

/// OLD PASSWORD
TextField(
  controller: oldPasswordController,
  obscureText: obscureOldPassword,
  style: TextStyle(color: textColor),
  decoration: InputDecoration(
    labelText: "Old Password",
    prefixIcon: Icon(
      Icons.lock_outline,
      color: purpleColor,
    ),
    suffixIcon: IconButton(
      icon: Icon(
        obscureOldPassword
            ? Icons.visibility_off
            : Icons.visibility,
      ),
      onPressed: () {
        setState(() {
          obscureOldPassword =
              !obscureOldPassword;
        });
      },
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
    ),
  ),
),

const SizedBox(height: 18),

/// NEW PASSWORD
TextField(
  controller: newPasswordController,
  obscureText: obscureNewPassword,
  style: TextStyle(color: textColor),
  decoration: InputDecoration(
    labelText: "New Password",
    prefixIcon: Icon(
      Icons.lock,
      color: purpleColor,
    ),
    suffixIcon: IconButton(
      icon: Icon(
        obscureNewPassword
            ? Icons.visibility_off
            : Icons.visibility,
      ),
      onPressed: () {
        setState(() {
          obscureNewPassword =
              !obscureNewPassword;
        });
      },
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
    ),
  ),
),

const SizedBox(height: 10),

Align(
  alignment: Alignment.centerRight,
  child: GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ForgotPasswordScreen(),
        ),
      );
    },
    child: Text(
      "Forgot my password?",
      style: TextStyle(
        color: purpleColor,
        fontWeight: FontWeight.bold,
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
                      isLoading ? null : saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: purpleColor,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(18),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : const Text(
                          "Save Changes",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color textColor,
    required Color cardColor,
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
        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(18),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
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

      appBar: AppBar(
        title: Text("Forgot Password"),
      ),

      body: Padding(
        padding: EdgeInsets.all(20),

        child: Column(
          children: [

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [

                ChoiceChip(
                  label: Text("Email"),

                  selected: useEmail,

                  onSelected: (value) {
                    setState(() {
                      useEmail = true;
                      codeSent = false;
                    });
                  },
                ),

                SizedBox(width: 10),

                ChoiceChip(
                  label: Text("Phone"),

                  selected: !useEmail,

                  onSelected: (value) {
                    setState(() {
                      useEmail = false;
                      codeSent = false;
                    });
                  },
                ),
              ],
            ),

            SizedBox(height: 20),

            TextField(
              controller:
                  useEmail
                      ? emailController
                      : phoneController,

              keyboardType:
                  useEmail
                      ? TextInputType.emailAddress
                      : TextInputType.phone,

              decoration: InputDecoration(
                labelText:
                    useEmail
                        ? "Email Address"
                        : "Phone Number",

                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 20),

            if (!codeSent || useEmail)
              ElevatedButton(
                onPressed: sendCode,
                child: Text(
                  useEmail
                      ? "Send Reset Email"
                      : "Send Code",
                ),
              ),

            if (codeSent && !useEmail) ...[

              TextField(
                controller: codeController,
                decoration: InputDecoration(
                  labelText: "Verification Code",
                  border: OutlineInputBorder(),
                ),
              ),

              SizedBox(height: 20),

              TextField(
                controller: newPasswordController,
                obscureText: obscurePassword,

                decoration: InputDecoration(
                  labelText: "New Password",

                  border: OutlineInputBorder(),

                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
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

              SizedBox(height: 20),

              ElevatedButton(
                onPressed:
                    verifyCodeAndChangePassword,
                child: Text("Change Password"),
              ),
            ]
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
        isDark ? const Color(0xFF0D0917) : const Color(0xFFF7F7FA);

    final Color cardColor =
        isDark ? const Color(0xFF171326) : Colors.white;

    final Color boxColor =
        isDark ? const Color(0xFF221A3A) : const Color(0xFFF0F0F0);

    final Color mainText =
        isDark ? Colors.white : Colors.black;

    final Color subText =
        isDark ? Colors.white70 : Colors.grey.shade700;

    const Color purple = Color(0xFF8E5CF7);

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
                          const Color(0xFF2B1E4B),
                          const Color(0xFF1A1333),
                        ]
                      : [
                          const Color(0xFFEDE7FF),
                          const Color(0xFFF8F6FF),
                        ],
                ),
              ),
              child: Row(
                children: [

                  Column(
                    children: [
                      const Icon(Icons.favorite,
                          color: purple, size: 50),
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
                _iconItem(Icons.medical_services, "Scrubs", boxColor, subText),
                _iconItem(Icons.science, "Lab Coats", boxColor, subText),
                _iconItem(Icons.healing, "Accessories", boxColor, subText),
                _iconItem(Icons.local_shipping, "Delivery", boxColor, subText),
              ],
              cardColor,
              mainText,
            ),

            const SizedBox(height: 20),

            /// 🔥 WHY CHOOSE US
            _section(
              "Why Choose MedLife?",
              [
                _iconItem(Icons.star, "High Quality", boxColor, subText),
                _iconItem(Icons.attach_money, "Affordable", boxColor, subText),
                _iconItem(Icons.flash_on, "Fast", boxColor, subText),
                _iconItem(Icons.verified, "Trusted", boxColor, subText),
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
                    ),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      const Icon(Icons.phone, color: purple),
                      const SizedBox(width: 10),
                      Text("01066813466",
                          style: TextStyle(color: subText)),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(Icons.email, color: purple),
                      const SizedBox(width: 10),
                      Text("support@medlife.com",
                          style: TextStyle(color: subText)),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF8E5CF7)),
          const SizedBox(height: 10),
          Text(title,
              style: TextStyle(
                  color: mainText,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: subText, fontSize: 12)),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  color: mainText,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: items,
          ),
        ],
      ),
    );
  }

  /// 🔹 ICON ITEM
  Widget _iconItem(
      IconData icon, String text, Color boxColor, Color subText) {
    return Container(
      width: 80,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: boxColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF8E5CF7)),
          const SizedBox(height: 6),
          Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: subText, fontSize: 11)),
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
         TabBar(
  labelColor: Colors.deepPurpleAccent, // اللون عند الاختيار
  unselectedLabelColor: Colors.grey, // اللون العادي

  indicatorColor: Colors.deepPurpleAccent, // الخط البنفسجي تحت
  indicatorWeight: 4,

  tabs: [
    Tab(text: "Pending 🟠"),
    Tab(text: "Delivered 🟢"),
  ],
),
          Expanded(
            child: TabBarView(
              children: [
                OrdersList(status: "pending"),
                OrdersList(status: "delivered"),
              ],
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
.orderBy("date", descending: false) 
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