  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:flutter/material.dart';
  import 'package:velora/presentation/screens/Home/home.dart';
  import 'package:velora/presentation/screens/Auth/login.dart';

  class AuthGate extends StatelessWidget {
    const AuthGate({super.key});

    @override
    Widget build(BuildContext context) {
      return StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return const HomePage();
          } else {
            return const LoginPage();
          }
        },
      );
    }
  }
