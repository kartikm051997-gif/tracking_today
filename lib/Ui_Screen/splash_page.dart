import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackingapp/utilities/MyString.dart';
import 'login_page.dart';
import 'tracking_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _iconController;
  late Animation<Offset> _iconAnimation;

  late AnimationController _textController;
  late Animation<double> _textAnimation;

  @override
  void initState() {
    super.initState();

    // 🚀 Icon Slide Animation (left → right)
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _iconAnimation = Tween<Offset>(
      begin: const Offset(-2, 0), // start far left
      end: const Offset(0, 0), // center
    ).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeInOut),
    );

    _iconController.forward();

    // 🚀 Text Bounce Animation
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _textAnimation = CurvedAnimation(
      parent: _textController,
      curve: Curves.bounceInOut,
    );

    _textController.forward();

    // ✅ Navigate after 3 seconds
    Timer(const Duration(seconds: 3), () async {
      final prefs = await SharedPreferences.getInstance();
      final loggedIn = prefs.getBool("isLoggedIn") ?? false;

      if (!mounted) return;

      if (loggedIn) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TrackingPage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _iconController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent, // splash background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SlideTransition(
              position: _iconAnimation,
              child: const Icon(
                Icons.location_on,
                color: Colors.white,
                size: 60,
              ),
            ),
            const SizedBox(height: 20),
            ScaleTransition(
              scale: _textAnimation,
              child: Text(
                "Tracking App",
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                  fontFamily: MyString.poppins,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
