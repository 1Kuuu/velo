import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:velora/presentation/intro/when_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:velora/core/configs/theme/theme_provider.dart';
import 'dart:async';

class WhatScreen extends StatefulWidget {
  const WhatScreen({super.key});

  @override
  State<WhatScreen> createState() => _WhatScreenState();
}

class _WhatScreenState extends State<WhatScreen> {
  String? selectedBike;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final int maxRetries = 3;

  void _selectBike(String bikeType) async {
    print("🚲 Step 1: Starting bike selection for type: $bikeType");
    setState(() {
      selectedBike = bikeType;
    });
    print("🚲 Step 2: Updated UI state with selected bike");

    try {
      final user = FirebaseAuth.instance.currentUser;
      print(
          "🔐 Step 3: Checking user auth status. User: ${user?.uid ?? 'null'}");

      if (user == null) {
        print("❌ Step 4a: No authenticated user found");
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

      print("📝 Step 4b: User authenticated, preparing Firestore update");

      final dataToSave = {
        'bike_type': bikeType,
        'lastUpdated': FieldValue.serverTimestamp(),
        'setupComplete': false, // Add this to ensure it's set
      };
      print("📝 Step 5: Data to save: $dataToSave");

      print("💾 Step 6: Starting Firestore write operation");
      final docRef = _firestore.collection('users').doc(user.uid);
      print("📂 Step 6a: Document reference created: ${docRef.path}");

      // First check if document exists
      print("🔍 Step 6b: Checking if document exists");
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        print("📄 Step 6c: Document doesn't exist, creating new document");
        await docRef.set({
          'setupComplete': false,
          'createdAt': FieldValue.serverTimestamp(),
          'bike_type': bikeType,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        print("✅ Step 6d: Created initial document");
      } else {
        print("📄 Step 6c: Document exists, updating");
        await docRef.update(dataToSave);
        print("✅ Step 6d: Updated existing document");
      }

      print("✅ Step 7: Firestore write completed successfully");

      // Verify the data was saved
      print("🔍 Step 8: Verifying saved data");
      final verifySnapshot = await docRef.get();
      print("📄 Step 9: Retrieved document data: ${verifySnapshot.data()}");

      if (!verifySnapshot.exists) {
        print("❌ Step 10a: Document does not exist after save!");
        throw Exception("Failed to verify saved data");
      }

      print("✅ Step 10b: Document exists and contains data");

      if (mounted) {
        print("🎉 Step 11: Showing success toast");
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

        print("⏳ Step 12: Starting navigation delay");
        await Future.delayed(const Duration(milliseconds: 500));

        print("🔄 Step 13: Navigating to WhenScreen");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WhenScreen()),
        );
        print("✅ Step 14: Navigation complete");
      }
    } catch (e, stackTrace) {
      print("❌ Error in _selectBike: $e");
      print("📚 Stack trace: $stackTrace");

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
                style: TextStyle(
                  fontSize: 36,
                  color: isDarkMode
                      ? const Color(0xFF4A3B7C)
                      : const Color(0xFFB22222),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'TYPE OF BIKE ARE YOU USING?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'SELECT HERE:',
                style: TextStyle(
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
                        : const Color(0xFFB22222))
                    : (isDarkMode ? Colors.grey[800]! : Colors.grey),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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
