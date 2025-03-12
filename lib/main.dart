import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:velora/core/configs/theme/theme_provider.dart';
import 'package:velora/presentation/intro/onboarding.dart';
import 'package:velora/presentation/intro/welcome_screen.dart';
import 'package:velora/presentation/intro/what_screen.dart';
import 'package:velora/presentation/screens/1Home/home.dart';
import 'package:velora/presentation/screens/0Auth/signup.dart';
import 'package:velora/presentation/screens/0Auth/login.dart';
import 'package:velora/presentation/screens/3News/newsfeed.dart';
import 'package:velora/presentation/screens/5Settings/editprofile.dart';
import 'package:velora/presentation/screens/5Settings/setting_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable Firebase debug mode
  print("🔥 Initializing Firebase with debug mode...");
  try {
    await Firebase.initializeApp();
    print("✅ Firebase initialized successfully");
  } catch (e) {
    print("❌ Firebase initialization error: $e");
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: themeProvider.themeData,
      home: const SplashScreen(), // Use the new splash screen
      routes: {
        '/getstarted': (context) => const GetStarted(),
        '/home': (context) => const HomePage(),
        '/signup': (context) => const SignupPage(),
        '/login': (context) => const LoginPage(),
        '/settings': (context) => const SettingsScreen(), // ✅ Add this
        '/edit-profile': (context) => const EditProfileScreen(), // ✅ Add this
        '/newsfeed': (context) =>
            const NewsFeedPageContent(), // Add newsfeed route
      },
    );
  }
}

/// 🔹 Simple Splash Screen with app logo
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 2)); // Show logo for 2 seconds
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Image.asset(
          'assets/images/logo.png',
          height: 120,
        ),
      ),
    );
  }
}

/// 🔹 AuthWrapper to handle authentication and navigation
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    print("🔐 AuthWrapper: Starting authentication check...");
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // First check if we're waiting for auth state
          if (snapshot.connectionState == ConnectionState.waiting) {
            print("⏳ AuthWrapper: Waiting for auth state...");
            return const Center(child: CircularProgressIndicator());
          }

          // Check if user is not logged in
          final user = snapshot.data;
          if (user == null) {
            print("❌ AuthWrapper: No authenticated user found");
            // Check if onboarding is completed
            return FutureBuilder<SharedPreferences>(
                future: SharedPreferences.getInstance(),
                builder: (context, prefsSnapshot) {
                  if (!prefsSnapshot.hasData)
                    return const Center(child: CircularProgressIndicator());

                  final bool onboardingComplete =
                      prefsSnapshot.data!.getBool('onboardingComplete') ??
                          false;
                  if (!onboardingComplete) {
                    print("🎯 AuthWrapper: Starting onboarding flow");
                    return const GetStarted();
                  }
                  print("🔑 AuthWrapper: Directing to login");
                  return const LoginPage();
                });
          }

          print("✅ AuthWrapper: User authenticated - UID: ${user.uid}");
          print("📧 AuthWrapper: User email: ${user.email}");

          // Check user's setup status in Firestore
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                print("⏳ AuthWrapper: Loading Firestore user data...");
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                print(
                    "❌ AuthWrapper: Error loading user data - ${snapshot.error}");
                return const LoginPage();
              }

              // If user document doesn't exist, create it and start setup flow
              if (!snapshot.hasData || !snapshot.data!.exists) {
                print("📝 AuthWrapper: Creating new user document...");
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .set({
                  'uid': user.uid,
                  'userName': user.displayName ?? 'New User',
                  'email': user.email,
                  'createdAt': FieldValue.serverTimestamp(),
                  'setupComplete': false,
                  'isAuthenticated': true,
                  'authProvider': user.providerData.first.providerId,
                  'lastLogin': FieldValue.serverTimestamp(),
                });
                print("✅ AuthWrapper: Starting setup flow for new user");
                return const WhatScreen(); // Start the What, When, Where flow
              }

              // User document exists, check setup status
              final userData = snapshot.data!.data() as Map<String, dynamic>;
              final bool setupComplete = userData['setupComplete'] ?? false;

              if (!setupComplete) {
                // Check if user has preferences
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('user_preferences')
                      .doc(user.uid)
                      .get(),
                  builder: (context, prefSnapshot) {
                    if (prefSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!prefSnapshot.hasData || !prefSnapshot.data!.exists) {
                      print(
                          "🎯 AuthWrapper: Starting What screen for preferences setup");
                      return const WhatScreen(); // Start the What, When, Where flow
                    }

                    print(
                        "🎯 AuthWrapper: User has preferences, showing Welcome screen");
                    return const WelcomeScreen(); // Show welcome screen for final setup step
                  },
                );
              }

              // User is fully set up, go to home
              print("🏠 AuthWrapper: Setup complete, navigating to HomePage");
              return const HomePage();
            },
          );
        },
      ),
    );
  }
}
