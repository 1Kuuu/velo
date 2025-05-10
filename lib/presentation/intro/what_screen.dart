import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:velora/presentation/intro/when_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:velora/core/configs/theme/theme_provider.dart';
import 'package:velora/core/configs/theme/app_fonts.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'dart:async';

class WhatScreen extends StatefulWidget {
  const WhatScreen({super.key});

  @override
  State<WhatScreen> createState() => _WhatScreenState();
}

class _WhatScreenState extends State<WhatScreen> {
  String? selectedBike;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _selectBike(String bikeType) async {
    setState(() {
      selectedBike = bikeType;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (mounted) {
          DelightToastBar(
            builder: (context) => const ToastCard(
              title: Text('Error'),
              subtitle: Text("Please sign in to continue"),
              leading: Icon(Icons.error, color: Colors.red),
            ),
            position: DelightSnackbarPosition.top,
            autoDismiss: true,
            snackbarDuration: const Duration(seconds: 2),
            animationDuration: const Duration(milliseconds: 300),
          ).show(context);
        }
        return;
      }

      final dataToSave = {
        'bike_type': bikeType,
        'lastUpdated': FieldValue.serverTimestamp(),
        'setupComplete': false,
      };

      final docRef = _firestore.collection('users').doc(user.uid);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        await docRef.set({
          'setupComplete': false,
          'createdAt': FieldValue.serverTimestamp(),
          'bike_type': bikeType,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } else {
        await docRef.update(dataToSave);
      }

      if (mounted) {
        DelightToastBar(
          builder: (context) => ToastCard(
            title: const Text('Saved!'),
            subtitle: Text("You've selected: $bikeType"),
            leading: const Icon(Icons.check_circle, color: Colors.green),
          ),
          position: DelightSnackbarPosition.top,
          autoDismiss: true,
          snackbarDuration: const Duration(seconds: 2),
          animationDuration: const Duration(milliseconds: 300),
        ).show(context);

        await Future.delayed(const Duration(milliseconds: 500));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WhenScreen()),
        );
      }
    } catch (e) {
      String errorMessage = "Failed to save";
      if (e is FirebaseException) {
        errorMessage = "${e.code}: ${e.message}";
      } else if (e is TimeoutException) {
        errorMessage =
            "Connection timeout. Please check your internet and try again.";
      }

      if (mounted) {
        DelightToastBar(
          builder: (context) => ToastCard(
            title: const Text('Error'),
            subtitle: Text(errorMessage),
            leading: const Icon(Icons.error, color: Colors.red),
          ),
          position: DelightSnackbarPosition.top,
          autoDismiss: true,
          snackbarDuration: const Duration(seconds: 2),
          animationDuration: const Duration(milliseconds: 300),
        ).show(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                isDarkMode
                    ? 'assets/images/logo-w.png'
                    : 'assets/images/logo.png',
                height: 30,
              ),
              const SizedBox(height: 20),
              Text(
                'WHAT',
                style: AppFonts.bold.copyWith(
                  fontSize: 36,
                  color: isDarkMode
                      ? const Color(0xFF4A3B7C)
                      : AppColors.primary,
                ),
              ),
              Text(
                'TYPE OF BIKE ARE YOU USING?',
                style: AppFonts.bold.copyWith(
                  fontSize: 22,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'SELECT HERE:',
                style: AppFonts.regular.copyWith(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey,
                  fontSize: 16,
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    const SizedBox(height: 20),
                    _buildBikeOption('ROADBIKE', 'assets/images/roadbike.png'),
                    const SizedBox(height: 20),
                    _buildBikeOption(
                        'MOUNTAINBIKE', 'assets/images/mountainbike.png'),
                    const SizedBox(height: 20),
                    _buildBikeOption('FIXIE', 'assets/images/fixie.png'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBikeOption(String title, String imagePath) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDarkMode = themeProvider.isDarkMode;

        return GestureDetector(
          onTap: () => _selectBike(title),
          child: Container(
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              border: Border.all(
                color: selectedBike == title
                    ? (isDarkMode
                        ? const Color(0xFF4A3B7C)
                        : AppColors.primary)
                    : (isDarkMode ? Colors.grey[800]! : Colors.grey),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  title,
                  style: AppFonts.bold.copyWith(
                    fontSize: 18,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                Image.asset(
                  imagePath,
                  height: 150,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
