import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'command_center.dart';
import 'admin_login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MedLifeAdminApp());
}

class MedLifeAdminApp extends StatefulWidget {
  const MedLifeAdminApp({super.key});
  @override
  State<MedLifeAdminApp> createState() => _MedLifeAdminAppState();
}
class _MedLifeAdminAppState extends State<MedLifeAdminApp> {
  ThemeMode mode = ThemeMode.dark;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'MedLife Command Center', debugShowCheckedModeBanner: false,
    themeMode: mode,
    theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff3978f6)), scaffoldBackgroundColor: const Color(0xfff3f6fb), cardTheme: CardThemeData(color: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)))),
    darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff3978f6), brightness: Brightness.dark), scaffoldBackgroundColor: const Color(0xff0a1020), cardTheme: CardThemeData(color: const Color(0xff111a2b), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)))),
    home: StreamBuilder<User?>(stream: FirebaseAuth.instance.authStateChanges(), builder: (context, auth) {
      if (auth.connectionState == ConnectionState.waiting) return const Scaffold(body: Center(child: CircularProgressIndicator()));
      if (auth.data == null) return const AdminLogin();
      return FutureBuilder<DocumentSnapshot<Map<String,dynamic>>>(future: FirebaseFirestore.instance.collection('users').doc(auth.data!.uid).get(), builder: (context, user) {
        if (user.connectionState == ConnectionState.waiting) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        if (!user.hasData || !user.data!.exists || user.data!.data()?['role'] != 'admin') { FirebaseAuth.instance.signOut(); return const AdminLogin(); }
        return CommandCenter(onThemeChanged: (dark) => setState(() => mode = dark ? ThemeMode.dark : ThemeMode.light));
      });
    }),
  );
}
