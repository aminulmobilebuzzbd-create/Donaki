import 'package:flutter/material.dart';

/// প্রাইম লোগোর রং: লাল, হলুদ আর কালো।
class AppColors {
  /// লোগোর লাল (বোতাম, মূল রং)
  static const brand = Color(0xFFD7141A);

  /// লোগোর হলুদ (কালো পটভূমিতে লেখা, হাইলাইট)
  static const yellow = Color(0xFFFFD000);

  /// সাদার উপর পড়ার মতো গাঢ় হলুদ
  static const accent = Color(0xFFE09A00);

  /// উপরের বার, নিচের বার, ব্যানার
  static const dark = Color(0xFF161616);
  static const dark2 = Color(0xFF2A1A12);

  static const cream = Color(0xFFFFF8E7);

  /// টাকা বাইরে গেল / কাস্টমারের কাছে পাবো / খরচ
  static const out = Color(0xFFC62828);

  /// টাকা হাতে এলো / পেলাম / বিক্রি
  static const inn = Color(0xFF2E7D32);

  /// কালো পটভূমির উপর লাল/সবুজ
  static const outOnDark = Color(0xFFFF7A6B);
  static const innOnDark = Color(0xFF7DDB8F);

  static const darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [dark, dark2],
  );
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.brand,
    primary: AppColors.brand,
    onPrimary: Colors.white,
    secondary: AppColors.yellow,
    onSecondary: AppColors.dark,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.cream,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.dark,
      foregroundColor: Colors.white,
      centerTitle: false,
      titleTextStyle: TextStyle(color: AppColors.yellow, fontSize: 21, fontWeight: FontWeight.w700),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.yellow,
      foregroundColor: AppColors.dark,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.dark,
      indicatorColor: AppColors.yellow,
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(color: s.contains(WidgetState.selected) ? AppColors.dark : Colors.white70),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          color: s.contains(WidgetState.selected) ? AppColors.yellow : Colors.white70,
          fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : null),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.brand : null),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.yellow : Colors.white),
        foregroundColor: const WidgetStatePropertyAll(AppColors.dark),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.brand, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
    ),
  );
}
