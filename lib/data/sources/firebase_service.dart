import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FirebaseServices {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ---------------------- SIGNUP FUNCTION ----------------------
  static Future<void> signup({
    required BuildContext context,
    required TextEditingController usernameController,
    required TextEditingController emailController,
    required TextEditingController passwordController,
    required TextEditingController confirmPasswordController,
  }) async {
    String username = usernameController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();

    if (username.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        await _firestore.collection("users").doc(user.uid).set({
          "uid": user.uid,
          "username": username,
          "email": email,
          "createdAt": DateTime.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Signup successful!")),
        );

        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  // ---------------------- FETCH WEEKLY PROGRESS ----------------------
  static Future<Map<String, dynamic>> fetchWeeklyProgress(
      DateTime selectedDate) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final weekStart =
          selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 7));

      final snapshot = await _firestore
          .collection('user_activities')
          .doc(user.uid)
          .collection('activities')
          .where('date', isGreaterThanOrEqualTo: weekStart)
          .where('date', isLessThan: weekEnd)
          .get();

      int totalActivities = snapshot.docs.length;
      int totalMinutes =
          snapshot.docs.fold(0, (sum, doc) => sum + (doc['duration'] as int));
      double totalDistance = snapshot.docs
          .fold(0.0, (sum, doc) => sum + (doc['distance'] as double));

      return {
        'activities': totalActivities,
        'time': '${totalMinutes ~/ 60}h ${totalMinutes % 60}m',
        'distance': totalDistance,
      };
    } catch (e) {
      print('Error fetching weekly progress: $e');
      return {};
    }
  }

  // ---------------------- FETCH PLANS FOR SELECTED DATE ----------------------
  static Future<Map<String, String>> fetchPlansForSelectedDate(
      DateTime selectedDate) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final startOfDay =
          DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection('user_plans')
          .doc(user.uid)
          .collection('plans')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      return {
        for (var doc in snapshot.docs)
          doc['time'] as String: doc['description'] as String
      };
    } catch (e) {
      print("Error fetching plans: $e");
      return {};
    }
  }
}
