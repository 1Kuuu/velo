import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:velora/presentation/intro/welcome_screen.dart';
import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WhereScreen extends StatefulWidget {
  const WhereScreen({super.key});

  @override
  State<WhereScreen> createState() => _WhereScreenState();
}

class _WhereScreenState extends State<WhereScreen> {
  final Map<String, bool> locationPreferences = {
    'Coastal Routes': false,
    'City Streets': false,
    'Parks': false,
    'Mountains': false,
    'Country Routes': false,
  };

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _saveAndNavigate() async {
    try {
      // Store preferences in Firestore
      await _firestore
          .collection('user_preferences')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .set({
        'location_preferences': locationPreferences,
      }, SetOptions(merge: true));

      // 🎉 Show success toast
      if (mounted) {
        DelightToastBar(
          builder: (context) {
            return ToastCard(
              title: const Text('Saved!'),
              subtitle:
                  const Text("Your location preferences have been saved."),
              leading: const Icon(Icons.check_circle, color: Colors.green),
            );
          },
          position: DelightSnackbarPosition.top,
          autoDismiss: true,
          snackbarDuration: const Duration(seconds: 2),
          animationDuration: const Duration(milliseconds: 300),
        ).show(context);
      }

      // Navigate to WelcomeScreen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
      }
    } catch (e) {
      // ❌ Show error toast
      if (mounted) {
        DelightToastBar(
          builder: (context) {
            return ToastCard(
              title: const Text('Error'),
              subtitle: Text("Failed to save: $e"),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Positioned(
                top: 52.5,
                left: 15,
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 30,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'WHERE',
                style: TextStyle(
                  fontSize: 36,
                  color: Color(0xFFB22222),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'DO YOU LIKE TO RIDE?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: ListView(
                  children: locationPreferences.keys.map((String key) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 15.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: CheckboxListTile(
                          title: Text(
                            key,
                            style: const TextStyle(fontSize: 22),
                          ),
                          value: locationPreferences[key],
                          onChanged: (bool? value) {
                            setState(() {
                              locationPreferences[key] = value!;
                            });
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveAndNavigate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A1818),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
