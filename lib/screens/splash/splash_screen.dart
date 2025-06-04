import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('seenOnboarding') ?? false;
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return; // ✅ Ensure widget is still mounted

    if (!seen) {
      prefs.setBool('seenOnboarding', true);
      Navigator.pushReplacementNamed(context, '/register');
    } else {
      final loggedIn = prefs.getBool('loggedIn') ?? false;
      Navigator.pushReplacementNamed(context, loggedIn ? '/home' : '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset('assets/images/splash_logo.png', width: 200),
      ),
    );
  }
}
