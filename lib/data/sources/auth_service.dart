import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:firebase_core/firebase_core.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔹 Check if Firebase is initialized
  Future<void> ensureInitialized() async {
    await Firebase.initializeApp();
    try {
      await _firestore.collection('_test_').doc('_test_').get();
    } catch (e) {
      // Firestore permission test failed
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
      await _googleSignIn.signOut();
      await _auth.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        await _handleFirestoreUser(user);
        if (context.mounted) {
          _showToast(context, "Successfully signed in!", Icons.check_circle,
              Colors.green);
        }
        return userCredential;
      }

      throw Exception("Failed to get user after Firebase sign in");
    } catch (e) {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _handleFirestoreUser(currentUser);
        if (context.mounted) {
          _showToast(context, "Successfully signed in!", Icons.check_circle,
              Colors.green);
        }
        return null;
      }

      if (context.mounted) {
        _showToast(context, "Failed to sign in with Google. Please try again.",
            Icons.error, Colors.red);
      }
      return null;
    } finally {
      await _googleSignIn.signOut();
    }
  }

  /// 🔹 Logout function with proper cleanup
  Future<bool> signOut(BuildContext context) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Update user's last logout time in Firestore
        await _firestore.collection('users').doc(user.uid).update({
          'lastLogout': FieldValue.serverTimestamp(),
          'isAuthenticated': false
        });
      }

      // Sign out from authentication providers
      await Future.wait([_googleSignIn.signOut(), _auth.signOut()],
          eagerError: false);

      return true;
    } catch (e) {
      if (context.mounted) {
        _showToast(context, "Error signing out", Icons.error, Colors.red);
      }
      return false;
    }
  }

  Future<void> _handleFirestoreUser(User user) async {
    if (user.isAnonymous || user.uid.isEmpty) {
      throw Exception("Invalid user state: Anonymous or empty UID");
    }

    final DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(user.uid).get();

    try {
      if (!userDoc.exists) {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'userName': user.displayName ?? "Google User",
          'email': user.email,
          'createdAt': FieldValue.serverTimestamp(),
          'setupComplete': false,
          'isAuthenticated': true,
          'authProvider': 'google',
          'lastLogin': FieldValue.serverTimestamp(),
          'profileUrl': user.photoURL,
        });
      } else {
        final existingData = userDoc.data() as Map<String, dynamic>;
        await _firestore.collection('users').doc(user.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
          'isAuthenticated': true,
          'userName': user.displayName ?? existingData['userName'],
          'email': user.email ?? existingData['email'],
          'profileUrl': user.photoURL ?? existingData['profileUrl'],
          'setupComplete': existingData['setupComplete'] ?? false,
          'preferences': existingData['preferences'],
          'bikeType': existingData['bikeType'],
          'experience': existingData['experience'],
          'goals': existingData['goals'],
        });
      }
    } catch (e) {
      throw Exception("Failed to handle Firestore user data: $e");
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
        await _firestore.collection('users').doc(user.uid).update({
          'setupComplete': isComplete,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
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
      return false;
    }
  }
}
