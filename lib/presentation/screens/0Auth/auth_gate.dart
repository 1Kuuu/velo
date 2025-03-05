import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:velora/data/sources/firebase_service.dart';
import 'package:velora/presentation/intro/what_screen.dart';
import 'package:velora/presentation/screens/0Auth/login.dart';
import 'package:velora/presentation/screens/1Home/home.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 🔹 Show loading indicator while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 🔹 If user is NOT logged in, show Login Page
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginPage();
        }

        // 🔹 User is authenticated, now check Firestore profile data
        return FutureBuilder(
          future: FirebaseServices.getUserData(snapshot.data!.uid),
          builder: (context, AsyncSnapshot userSnapshot) {
            // 🔸 Show loading while fetching user data
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            /* 🔸 If user document does NOT exist or is incomplete, go to WelcomePage
            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              return const WhatScreen();
            }*/

            // 🔸 Check if user has complete user_preference data
            var userData = userSnapshot.data!.data();
            if (userData == null ||
                !userData.containsKey('user_preference') ||
                userData['user_preference'] == null) {
              return const WhatScreen();
            }

            // 🔸 If user has a complete profile, go to HomePage
            return const HomePage();
          },
        );
      },
    );
  }
}
