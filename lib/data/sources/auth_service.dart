import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:velora/data/sources/firebase_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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
    required String confirmPassword,
  }) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        User user = userCredential.user!;

        // ✅ Update Firebase Auth profile
        await user.updateDisplayName(username);
        await user.reload(); // Refresh user info

        print("✅ User profile updated: ${user.displayName}");

        // ✅ Save user info in Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'userName': username,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });

        print("✅ User data stored in Firestore");

        return true;
      } else {
        print("❌ User creation returned null");
        return false;
      }
    } catch (e) {
      print("❌ Signup error: $e");
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

  /// 🔹 Google Sign-In
  Future<UserCredential?> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User canceled sign-in

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      // Save or update user info in Firestore
      await FirebaseServices.createUserDocument(
        uid: userCredential.user!.uid,
        username: userCredential.user!.displayName ?? "User",
        email: userCredential.user!.email!,
        profileUrl: userCredential.user!.photoURL ?? "",
      );

      _showToast(context, "Google Sign-In Successful!", Icons.check_circle,
          Colors.green);
      return userCredential;
    } catch (e) {
      _showToast(context, "Google Sign-In failed: $e", Icons.error, Colors.red);
      return null;
    }
  }

  /// 🔹 Logout
  Future<void> signOut(BuildContext context) async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      _showToast(
          context, "Logged out successfully!", Icons.logout, Colors.blue);
    } catch (e) {
      _showToast(context, "Logout failed: $e", Icons.error, Colors.red);
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
}
