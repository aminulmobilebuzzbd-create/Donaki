import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import 'demo_data.dart';
import 'widgets/brand.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDemoData) {
    await seedDemoDataIfEmpty();
    // স্ক্রিনশট স্ক্রিপ্ট যাতে বোতামগুলো খুঁজে পায়
    SemanticsBinding.instance.ensureSemantics();
  }
  runApp(const DokaniApp());
}

class DokaniApp extends StatelessWidget {
  const DokaniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'প্রাইম দোকানি',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const SplashScreen(),
    );
  }
}
