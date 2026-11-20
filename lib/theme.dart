import 'package:flutter/material.dart';

/// দোকানি এর নিজস্ব রং: গাঢ় সবুজ-নীল (teal) মূল রং, সাথে কমলা হাইলাইট।
class AppColors {
  static const brand = Color(0xFF00695C);
  static const accent = Color(0xFFFFA000);

  /// টাকা বাইরে গেল / কাস্টমারের কাছে পাবো / খরচ
  static const out = Color(0xFFC62828);

  /// টাকা হাতে এলো / পেলাম / বিক্রি
  static const inn = Color(0xFF2E7D32);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.brand,
    primary: AppColors.brand,
    secondary: AppColors.accent,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFFF5F7F6),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.brand,
      foregroundColor: Colors.white,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.white,
    ),
  );
}
