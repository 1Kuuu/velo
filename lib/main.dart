import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:velora/core/configs/theme/theme_provider.dart';
import 'package:velora/core/configs/language/app_localizations.dart';
import 'package:velora/firebase_options.dart';
import 'package:velora/presentation/intro/onboarding.dart';
import 'package:velora/presentation/intro/welcome_screen.dart';
import 'package:velora/presentation/intro/what_screen.dart';
import 'package:velora/presentation/screens/1Home/home.dart';
import 'package:velora/presentation/screens/0Auth/signup.dart';
import 'package:velora/presentation/screens/0Auth/login.dart';
import 'package:velora/presentation/screens/3News/newsfeed.dart';
import 'package:velora/presentation/screens/5Settings/editprofile.dart';
import 'package:velora/presentation/screens/5Settings/setting_screen.dart';
import 'package:velora/providers/language_provider.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set default locale for Firebase Auth
  FirebaseAuth.instance.setLanguageCode('en');

  // Initialize App Check with proper error handling
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider:
          kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
    );

    // Set up token refresh listener
    FirebaseAppCheck.instance.onTokenChange.listen(
      (token) {
        print('App Check token refreshed successfully');
      },
      onError: (error) {
        print('App Check token refresh error: $error');
        // Continue without App Check in case of error
      },
    );
  } catch (e) {
    print('Error initializing App Check: $e');
    // Continue without App Check in case of error
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
            create: (_) => LanguageProvider()..loadLanguage()),
      ],
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
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: themeProvider.themeData,
      locale: languageProvider.locale,
      supportedLocales: const [
        Locale('en'),
        Locale('en', 'UK'),
        Locale('fil'),
      ],
      localizationsDelegates: [
        const AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SplashScreen(),
      routes: {
        '/getstarted': (context) => const GetStarted(),
        '/home': (context) => const HomePage(),
        '/signup': (context) => const SignupPage(),
        '/login': (context) => const LoginPage(),
        '/settings': (context) => const SettingsScreen(),
        '/edit-profile': (context) => const EditProfileScreen(),
        '/newsfeed': (context) => const NewsFeedPageContent(),
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
    await Future.delayed(const Duration(seconds: 2));
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
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data;
          if (user == null) {
            return FutureBuilder<SharedPreferences>(
                future: SharedPreferences.getInstance(),
                builder: (context, prefsSnapshot) {
                  if (!prefsSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final bool onboardingComplete =
                      prefsSnapshot.data!.getBool('onboardingComplete') ??
                          false;
                  if (!onboardingComplete) {
                    return const GetStarted();
                  }
                  return const LoginPage();
                });
          }

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const LoginPage();
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
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
                return const WhatScreen();
              }

              final userData = snapshot.data!.data() as Map<String, dynamic>;
              final bool setupComplete = userData['setupComplete'] ?? false;

              if (!setupComplete) {
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
                      return const WhatScreen();
                    }

                    return const WelcomeScreen();
                  },
                );
              }

              return const HomePage();
            },
          );
        },
      ),
    );
  }
}
