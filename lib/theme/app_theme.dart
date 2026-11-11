import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static final ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF3986A8),
      brightness: Brightness.light,
      primary: const Color(0xFF286F91),
      secondary: const Color(0xFF5C9DB8),
      surface: Colors.white,
      onSurface: const Color(0xFF172B3A),
    ),
    scaffoldBackgroundColor: const Color(0xFFF3F7FA),
    canvasColor: const Color(0xFFF3F7FA),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF172B3A),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFF286F91)),
      titleTextStyle: TextStyle(color: Color(0xFF172B3A), fontSize: 20, fontWeight: FontWeight.w700),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 2,
      shadowColor: Color(0x1419364A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Color(0xFFE4ECF1))),
    ),
    dialogTheme: DialogThemeData(backgroundColor: Colors.white, surfaceTintColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
    bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Colors.white, surfaceTintColor: Colors.transparent, modalBackgroundColor: Colors.white),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF7FAFC),
      hintStyle: const TextStyle(color: Color(0xFF8495A2)),
      labelStyle: const TextStyle(color: Color(0xFF526675)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFDCE6EC))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFDCE6EC))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF3986A8), width: 1.5)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF286F91), foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))),
    dividerColor: const Color(0xFFE3EBF0),
    iconTheme: const IconThemeData(color: Color(0xFF42677D)),
    textTheme: const TextTheme(bodyLarge: TextStyle(color: Color(0xFF243B4A)), bodyMedium: TextStyle(color: Color(0xFF526675)), titleLarge: TextStyle(color: Color(0xFF172B3A), fontWeight: FontWeight.w700)),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(backgroundColor: Colors.white, selectedItemColor: Color(0xFF286F91), unselectedItemColor: Color(0xFF81919D), type: BottomNavigationBarType.fixed, elevation: 0),
  );

  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6EA6C1), brightness: Brightness.dark, primary: const Color(0xFF6EA6C1), secondary: const Color(0xFF59C7FF), surface: const Color(0xFF141118), onSurface: Colors.white),
    scaffoldBackgroundColor: const Color(0xFF0B0713),
    canvasColor: const Color(0xFF0B0713),
    appBarTheme: const AppBarTheme(backgroundColor: Colors.black, foregroundColor: Colors.white, surfaceTintColor: Colors.transparent, elevation: 0, iconTheme: IconThemeData(color: Colors.white), titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
    cardTheme: CardThemeData(color: const Color(0xFF141118), surfaceTintColor: Colors.transparent, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Colors.white10))),
    dialogTheme: DialogThemeData(backgroundColor: const Color(0xFF17151D), surfaceTintColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
    bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Color(0xFF111827), surfaceTintColor: Colors.transparent, modalBackgroundColor: Color(0xFF111827)),
    inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: const Color(0xFF1D1B20), hintStyle: const TextStyle(color: Colors.white54), labelStyle: const TextStyle(color: Colors.white70), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.white12)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.white12)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF6EA6C1), width: 1.5))),
    elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF397E9E), foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))),
    dividerColor: Colors.white12,
    iconTheme: const IconThemeData(color: Colors.white70),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(backgroundColor: Color(0xFF0B1220), selectedItemColor: Colors.white, unselectedItemColor: Colors.white70, type: BottomNavigationBarType.fixed, elevation: 0),
  );
}
