import 'package:flutter/material.dart';

import 'demo_data.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDemoData) await seedDemoDataIfEmpty();
  runApp(const DokaniApp());
}

class DokaniApp extends StatelessWidget {
  const DokaniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'দোকানি',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const HomeScreen(),
    );
  }
}
