import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:velora/presentation/screens/1Home/home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velora/presentation/widgets/reusable_wdgts.dart';
import 'package:velora/core/configs/theme/theme_provider.dart';
import 'package:velora/core/configs/theme/app_fonts.dart';
import 'package:provider/provider.dart';
import 'package:velora/presentation/intro/what_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isLoading = true;
  bool _isNewUser = false;
  String? _bikeType;
  Map<String, dynamic> _timePrefs = {};
  List<String> _locationPrefs = [];
  
  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }
  
  Future<void> _checkUserStatus() async {
    setState(() => _isLoading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _isNewUser = true;
        });
        return;
      }
      
      // Check if user has bike preferences
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      // If no user document or no bike type, redirect to bike selection
      if (!userDoc.exists || !(userDoc.data()?.containsKey('bike_type') ?? false)) {
        debugPrint("No user document or bike_type found for ${user.uid}");
        
        // Create minimal user document if it doesn't exist
        if (!userDoc.exists) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'uid': user.uid,
            'email': user.email,
            'createdAt': FieldValue.serverTimestamp(),
            'lastUpdated': FieldValue.serverTimestamp(),
            'setupComplete': false,
          });
        }
        
        // Set as new user to show setup screen
        setState(() {
          _isLoading = false;
          _isNewUser = true;
        });
        return;
      }
      
      // User exists and has bike type
      final userData = userDoc.data()!;
      _bikeType = userData['bike_type'] as String?;
      
      // Load preferences
      final prefDoc = await FirebaseFirestore.instance
          .collection('user_preferences')
          .doc(user.uid)
          .get();
      
      if (prefDoc.exists && prefDoc.data() != null) {
        final prefData = prefDoc.data()!;
        if (prefData.containsKey('time_preferences')) {
          _timePrefs = prefData['time_preferences'] as Map<String, dynamic>? ?? {};
        }
        
        if (prefData.containsKey('location_preferences')) {
          _locationPrefs = (prefData['location_preferences'] as List<dynamic>?)
                  ?.whereType<String>()
                  .toList() ??
              [];
        }
      }
      
      setState(() {
        _isLoading = false;
        _isNewUser = false;
      });
      
    } catch (e) {
      debugPrint("Error checking user status: $e");
      setState(() {
        _isLoading = false;
        _isNewUser = true;
      });
      _showErrorToast(context, "Error loading your profile: $e");
    }
  }

  void _goToSetup() {
    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(builder: (context) => const WhatScreen())
    );
  }

  Future<void> _goToHome() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showErrorToast(context, 'Please sign in to continue');
        return;
      }
      
      // Mark setup as complete
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'setupComplete': true,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboardingComplete', true);
      
      if (!mounted) return;
      
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomePage()),
        (route) => false,
      );
    } catch (e) {
      _showErrorToast(context, 'Failed to complete setup: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    // Loading state
    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    // New user state
    if (_isNewUser) {
      return Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppLogo(),
                const SizedBox(height: 20),
                CustomTitleText(text: 'WELCOME!'),
                const SizedBox(height: 10),
                Text(
                  'Let\'s set up your cycling profile',
                  style: AppFonts.bold.copyWith(fontSize: 22),
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.directions_bike,
                            size: 120,
                            color: isDarkMode ? Colors.white60 : Colors.grey[600],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Tell us about your bike',
                            style: AppFonts.bold.copyWith(fontSize: 24),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'We\'ll customize your experience based on your preferences',
                            style: AppFonts.regular.copyWith(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: 'START SETUP',
                    onPressed: _goToSetup,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    // Existing user with preferences
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppLogo(),
                const SizedBox(height: 20),
                CustomTitleText(text: 'WELCOME!'),
                const SizedBox(height: 10),
                Text(
                  'SEEMS LIKE YOU LOVE:',
                  style: AppFonts.bold.copyWith(fontSize: 22),
                ),
                const SizedBox(height: 20),
                if (_bikeType != null) _buildBikeCard(_bikeType!, isDarkMode),
                const SizedBox(height: 20),
                if (_timePrefs.isNotEmpty) _buildPreferencesCard('To Ride During:', _timePrefs, isDarkMode),
                const SizedBox(height: 20),
                if (_locationPrefs.isNotEmpty) _buildLocationCard('In The:', _locationPrefs, isDarkMode),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: 'START',
                    onPressed: _goToHome,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildBikeCard(String bikeType, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Image.asset(
            'assets/images/${bikeType.toLowerCase()}.png',
            width: double.infinity,
            height: 150,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              debugPrint("Error loading image: $error for bike type: $bikeType");
              return const Icon(Icons.directions_bike, size: 100, color: Colors.grey);
            },
          ),
          const SizedBox(height: 8),
          Text(
            bikeType,
            style: AppFonts.bold.copyWith(fontSize: 22),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPreferencesCard(String title, Map<String, dynamic> preferences, bool isDarkMode) {
    final selectedItems = preferences.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .toList();
    
    if (selectedItems.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppFonts.semibold.copyWith(
            fontSize: 16,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: selectedItems.map((item) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF4A3B7C) : AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                item,
                style: AppFonts.medium.copyWith(color: Colors.white),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildLocationCard(String title, List<String> locations, bool isDarkMode) {
    if (locations.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppFonts.semibold.copyWith(
            fontSize: 16,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: locations.map((location) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF4A3B7C) : AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                location,
                style: AppFonts.medium.copyWith(color: Colors.white),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showErrorToast(BuildContext context, String message) {
    debugPrint("Error: $message");
    
    DelightToastBar(
      builder: (context) {
        return ToastCard(
          title: const Text('Error'),
          subtitle: Text(message),
          leading: const Icon(Icons.error, color: Colors.red),
        );
      },
      position: DelightSnackbarPosition.top,
      autoDismiss: true,
      snackbarDuration: const Duration(seconds: 2),
      animationDuration: const Duration(milliseconds: 300),
    ).show(context);
  }
}
