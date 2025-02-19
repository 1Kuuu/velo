import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:velo/presentation/screens/home.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('user_preferences')
              .doc('current_user')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;
            final bikeType = data['bike_type'] as String;
            final timePrefs = data['time_preferences'] as Map<String, dynamic>;
            final locationPrefs =
                data['location_preferences'] as Map<String, dynamic>;

            return Padding(
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
                    'WELCOME!',
                    style: TextStyle(
                      fontSize: 36,
                      color: Color(0xFFB22222),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'SEEMS LIKE YOU LOVE:',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  const SizedBox(height: 20),
                  _buildSummaryCard(bikeType),
                  const SizedBox(height: 20),
                  _buildPreferenceSection('To Ride During:', timePrefs),
                  const SizedBox(height: 20),
                  _buildPreferenceSection('In The:', locationPrefs),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HomePage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A1818),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'START',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String bikeType) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Image.asset(
            'assets/images/${bikeType.toLowerCase()}.png',
            width: double.infinity, // Adjust width as needed
            fit: BoxFit.cover, // Ensures the image fills the box
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
          ),
          Text(
            bikeType,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceSection(
      String title, Map<String, dynamic> preferences) {
    final selectedPreferences = preferences.entries
        .where((e) => e.value == true)
        .map((e) => e.key)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: selectedPreferences.map((pref) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(pref),
            );
          }).toList(),
        ),
      ],
    );
  }
}
