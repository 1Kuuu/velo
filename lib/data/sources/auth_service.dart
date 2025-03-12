import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velora/presentation/screens/0Auth/login.dart';
import 'package:firebase_core/firebase_core.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔹 Check if Firebase is initialized
  Future<void> ensureInitialized() async {
    try {
      print("🔥 Checking Firebase initialization status...");
      await Firebase.initializeApp();

      // Test Firestore permissions
      print("🔥 Testing Firestore permissions...");
      try {
        final testDoc =
            await _firestore.collection('_test_').doc('_test_').get();
        print("✅ Firestore read permission test passed");
      } catch (e) {
        print("❌ Firestore permission test failed: $e");
      }

      print("✅ Firebase is ready");
    } catch (e) {
      print("❌ Firebase initialization check failed: $e");
    }
  }

  /// 🔹 Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// 🔹 Sign up with email & password
  Future<bool> signUpWithEmail({
    required BuildContext context,
    required String username,
    required String email,
    required String password,
    required String confirmPassword, // 👈 Added confirmPassword parameter
  }) async {
    try {
      // 🔹 Validate Password Match
      if (password != confirmPassword) {
        _showToast(context, "Passwords do not match!", Icons.error, Colors.red);
        return false;
      }

      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        User user = userCredential.user!;

        // ✅ Update Firebase Auth profile
        await user.updateDisplayName(username);
        await user.reload(); // Refresh user info

        // ✅ Save user info in Firestore (Unified Collection)
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'userName': username,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'setupComplete':
              false, // 👈 Ensure this is false for onboarding logic
        });

        return true;
      }
      return false;
    } catch (e) {
      _showToast(context, "Signup failed: $e", Icons.error, Colors.red);
      return false;
    }
  }

  /// 🔹 Log in with email & password
  Future<UserCredential?> loginWithEmail({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _showToast(
          context, "Login Successful!", Icons.check_circle, Colors.green);
      return userCredential;
    } catch (e) {
      _showToast(context, "Login failed: $e", Icons.error, Colors.red);
      return null;
    }
  }

  /// 🔹 Check if user is authenticated
  bool isUserAuthenticated() {
    return _auth.currentUser != null;
  }

  /// 🔹 Get authentication state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// 🔹 Google Sign-In
  Future<UserCredential?> signInWithGoogle(BuildContext context) async {
    try {
      print("🔐 Starting Google Sign-In process...");
      await ensureInitialized();
      await _googleSignIn.signOut();

      print("🔐 Requesting Google account...");
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print("❌ Google Sign-In cancelled by user");
        return null;
      }

      print("🔐 Getting Google auth details...");
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      print(
          "✅ Got Google auth tokens - Access Token: ${googleAuth.accessToken != null}, ID Token: ${googleAuth.idToken != null}");

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print("🔐 Signing in to Firebase...");
      UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        print("✅ Firebase Auth successful - UID: ${user.uid}");
        print("📧 Email: ${user.email}");
        print("🔒 Email Verified: ${user.emailVerified}");
        print("👤 Display Name: ${user.displayName}");
        print(
            "🔑 Provider ID: ${user.providerData.map((e) => e.providerId).join(', ')}");

        if (!user.isAnonymous && user.uid.isNotEmpty) {
          print("🔐 Checking Firestore user document...");
          DocumentSnapshot userDoc =
              await _firestore.collection('users').doc(user.uid).get();

          if (!userDoc.exists) {
            print("📝 Creating new user document in Firestore...");
            try {
              await _firestore.collection('users').doc(user.uid).set({
                'uid': user.uid,
                'userName': user.displayName ?? "Google User",
                'email': user.email,
                'createdAt': FieldValue.serverTimestamp(),
                'setupComplete': false,
                'isAuthenticated': true,
                'authProvider': 'google',
                'lastLogin': FieldValue.serverTimestamp(),
              });
              print("✅ User document created successfully");
            } catch (e) {
              print("❌ Error creating user document: $e");
              rethrow;
            }
          } else {
            print("📝 Updating existing user document...");
            try {
              await _firestore.collection('users').doc(user.uid).update({
                'lastLogin': FieldValue.serverTimestamp(),
                'isAuthenticated': true,
              });
              print("✅ User document updated successfully");
            } catch (e) {
              print("❌ Error updating user document: $e");
              rethrow;
            }
          }

          _showToast(context, "Successfully signed in!", Icons.check_circle,
              Colors.green);
          return userCredential;
        } else {
          print("❌ User is anonymous or has empty UID");
        }
      } else {
        print("❌ No user returned from Firebase Auth");
      }

      _showToast(context, "Authentication failed", Icons.error, Colors.red);
      return null;
    } catch (e) {
      print("❌ Google Sign-In error: $e");
      if (e is FirebaseAuthException) {
        print("🔥 Firebase Auth Error Code: ${e.code}");
        print("🔥 Firebase Auth Error Message: ${e.message}");
      }
      _showToast(context, "Google Sign-In failed: $e", Icons.error, Colors.red);
      return null;
    }
  }

  /// 🔹 Logout function (Now handles onboarding reset)
  Future<void> signOut(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('hasCompletedOnboarding'); // ✅ Clear onboarding flag

    await _auth.signOut();
    await _googleSignIn.signOut();

    // ✅ Ensure auth state change is processed
    await Future.delayed(const Duration(milliseconds: 500));

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  /// 🔹 Show DelightToastBar notifications
  void _showToast(
      BuildContext context, String message, IconData icon, Color color) {
    DelightToastBar(
      builder: (context) {
        return ToastCard(
          title: Text(message),
          leading: Icon(icon, color: color),
        );
      },
      position: DelightSnackbarPosition.top,
      autoDismiss: true,
      snackbarDuration: const Duration(seconds: 2),
      animationDuration: const Duration(milliseconds: 300),
    ).show(context);
  }

  /// 🔹 Update setup completion status
  Future<void> updateSetupStatus({required bool isComplete}) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        print("📝 Updating setup status to: $isComplete");
        await _firestore.collection('users').doc(user.uid).update({
          'setupComplete': isComplete,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        print("✅ Setup status updated successfully");
      } else {
        print("❌ Cannot update setup status: No authenticated user");
      }
    } catch (e) {
      print("❌ Error updating setup status: $e");
      rethrow;
    }
  }

  /// 🔹 Check setup status
  Future<bool> isSetupComplete() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        return doc.data()?['setupComplete'] ?? false;
      }
      return false;
    } catch (e) {
      print("❌ Error checking setup status: $e");
      return false;
    }
  }
}
