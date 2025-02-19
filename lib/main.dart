import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:velo/presentation/intro/pages/onboarding.dart';
import 'package:velo/presentation/screens/home.dart';
import 'package:velo/presentation/screens/signup.dart';
import 'package:velo/presentation/screens/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

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
      home: const SplashScreen(),
      routes: {
        '/getstarted': (context) => const GetStarted(),
        '/home': (context) => const HomePage(),
        '/signup': (context) => const Signup(),
        '/login': (context) => const LoginPage(),
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 2), () {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/getstarted');
      }
    });

    return Scaffold(
      body: Center(
        child: Image.asset('assets/images/logo.png', width: 150, height: 150),
      ),
    );
  }
}
