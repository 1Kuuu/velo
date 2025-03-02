import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:velora/presentation/intro/welcome_screen.dart';


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
    // Store preferences in Firebase
    await _firestore.collection('user_preferences').doc('current_user').set({
      'location_preferences': locationPreferences,
    }, SetOptions(merge: true));

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      );
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
