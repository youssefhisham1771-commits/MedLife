import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';
import 'services/firebase_service.dart';



// ✳️ ايميل الادمن
const String adminEmail = "youssef.hisham1771@gmail.com";

final cloudinary = CloudinaryPublic(
  'dzlorraqi',
  'Medlife',
  cache: false,
);

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

    await FirebaseMessaging.instance.requestPermission(
  alert: true,
  badge: true,
  sound: true,
);

    if (!kIsWeb) {

}

await saveFcmToken();

listenForAdminNotifications();

    runApp(const MyApp());
  } catch (e, s) {
    debugPrint("MAIN ERROR: $e");
    debugPrint("$s");
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<MyAppState>();

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
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