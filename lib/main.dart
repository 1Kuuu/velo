import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:velora/presentation/intro/onboarding.dart';
import 'package:velora/presentation/intro/welcome_screen.dart';
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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<bool> _isFirstTime;

  @override
  void initState() {
    super.initState();
    _isFirstTime = _checkFirstTime();
  }

  Future<bool> _checkFirstTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool firstTime = prefs.getBool('first_time') ?? true;
    if (firstTime) {
      await prefs.setBool('first_time', false);
    }
    return firstTime;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isFirstTime,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primaryColor: AppColors.primary,
            scaffoldBackgroundColor: Colors.grey[100],
          ),
          home:
              snapshot.data == true ? const GetStarted() : const AuthWrapper(),
          routes: {
            '/getstarted': (context) => const GetStarted(),
            '/home': (context) => const HomePage(),
            '/signup': (context) => const SignupPage(),
            '/login': (context) => const LoginPage(),
          },
        );
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
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          return const LoginPage(); // 🚀 Not logged in? Go to Login
        }

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasData && snapshot.data!.exists) {
              final userData = snapshot.data!.data() as Map<String, dynamic>;
              final bool setupComplete = userData['setupComplete'] ?? false;

              if (setupComplete) {
                return const HomePage();
              } else {
                return FutureBuilder<Widget>(
                  future: _checkLocalOnboarding(),
                  builder: (context, futureSnapshot) {
                    if (futureSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return futureSnapshot.data ?? const WelcomeScreen();
                  },
                );
              }
            } else {
              return FutureBuilder<Widget>(
                future: _checkLocalOnboarding(),
                builder: (context, futureSnapshot) {
                  if (futureSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return futureSnapshot.data ?? const WelcomeScreen();
                },
              );
            }
          },
        );
      },
    );
  }

  /// 🔹 Check if onboarding was completed locally
  Future<Widget> _checkLocalOnboarding() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool onboardingComplete = prefs.getBool('onboardingComplete') ?? false;
    return onboardingComplete ? const HomePage() : const WelcomeScreen();
  }
}
