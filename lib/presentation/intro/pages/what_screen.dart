import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:velo/presentation/intro/pages/when_screen.dart';

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

    // Store selection in Firebase
    await _firestore.collection('user_preferences').doc('current_user').set({
      'bike_type': bikeType,
    }, SetOptions(merge: true));

    // Navigate to next screen
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const WhenScreen()),
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
                'WHAT',
                style: TextStyle(
                  fontSize: 36,
                  color: Color(0xFFB22222),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'TYPE OF BIKE ARE YOU USING?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'SELECT HERE:',
                style: TextStyle(
                  color: Colors.grey,
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
    return GestureDetector(
      onTap: () => _selectBike(title),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: selectedBike == title ? Colors.red : Colors.grey,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
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
  }
}
