import 'package:flutter/material.dart';

import '../screens/home_screen.dart';
import '../theme.dart';

const kLogoAsset = 'assets/brand/logo.png';

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 40});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(kLogoAsset, height: size, fit: BoxFit.contain, filterQuality: FilterQuality.medium);
  }
}

/// মূল ট্যাবগুলোর উপরের বার: বাঁয়ে লোগো, পাশে স্ক্রিনের নাম।
AppBar brandAppBar(String title, {List<Widget>? actions}) {
  return AppBar(
    toolbarHeight: 64,
    titleSpacing: 12,
    title: Row(children: [
      const BrandLogo(size: 44),
      const SizedBox(width: 10),
      Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
    ]),
    actions: actions,
    bottom: const PreferredSize(
      preferredSize: Size.fromHeight(3),
      child: SizedBox(
        height: 3,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.brand, AppColors.yellow, AppColors.brand]),
          ),
        ),
      ),
    ),
  );
}

/// অ্যাপ খোলার সময় লোগোসহ প্রথম পর্দা।
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1700), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      ));
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: _anim, curve: Curves.easeOutBack);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.darkGradient),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ScaleTransition(
              scale: Tween(begin: 0.6, end: 1.0).animate(curve),
              child: FadeTransition(opacity: _anim, child: const BrandLogo(size: 220)),
            ),
            const SizedBox(height: 28),
            FadeTransition(
              opacity: _anim,
              child: const Text(
                'দোকানের সব হিসাব এক জায়গায়',
                style: TextStyle(color: AppColors.yellow, fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
