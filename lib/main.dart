import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:velora/presentation/intro/onboarding.dart';
import 'package:velora/presentation/screens/1Home/home.dart';
import 'package:velora/presentation/screens/0Auth/signup.dart';
import 'package:velora/presentation/screens/0Auth/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF672A2A),
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: AuthWrapper(), // Handles initial navigation
      routes: {
        '/getstarted': (context) => const GetStarted(),
        '/home': (context) => const HomePage(),
        '/signup': (context) => const SignupPage(),
        '/login': (context) => const LoginPage(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          return const HomePage(); // User is logged in
        } else {
          return const GetStarted(); // No user, go to onboarding
        }
      },
    );
  }
}
