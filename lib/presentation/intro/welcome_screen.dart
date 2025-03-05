import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:velora/data/sources/firebase_service.dart';
import 'package:velora/presentation/intro/what_screen.dart';
import 'package:velora/presentation/screens/0Auth/login.dart';
import 'package:velora/presentation/screens/1Home/home.dart';
import 'package:velora/presentation/widgets/reusable_wdgts.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 2));

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // No user logged in, go to Login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
      return;
    }

    // Fetch user data from Firestore
    final Map<String, dynamic>? userData =
        await FirebaseServices.getUserData(user.uid);

    // Ensure userData isn't null before accessing properties
    final bool isSetupComplete = userData?['setupComplete'] ?? false;

    // Navigate based on setup status
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            isSetupComplete ? const HomePage() : const WhatScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppLogo(), // Reusing AppLogo from reusable_wdgts.dart
            const SizedBox(height: 20),
            CustomTitleText(text: "Welcome to Velora"),
            const SizedBox(height: 10),
            CustomSubtitleText(text: "Your cycling journey starts here."),
          ],
        ),
      ),
    );
  }
}
