import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // For Web Support

class FirebaseServices {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// ✅ **Google Sign-In (Web + Mobile)**
  static Future<UserCredential?> signInWithGoogle(BuildContext context) async {
    try {
      if (kIsWeb) {
        // Web Google Sign-In
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        return await _auth.signInWithPopup(googleProvider);
      } else {
        // Native Google Sign-In (Android/iOS)
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null;

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential = await _auth.signInWithCredential(credential);

        // Store user in Firestore
        await _saveUserToFirestore(userCredential.user);

        return userCredential;
      }
    } catch (e) {
      _showErrorSnackbar(context, "Google Sign-In failed: $e");
      return null;
    }
  }

  /// ✅ **Email & Password Login**
  static Future<void> login({
    required BuildContext context,
    required TextEditingController emailController,
    required TextEditingController passwordController,
  }) async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showErrorSnackbar(context, "Please fill in all fields");
      return;
    }

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      _showSuccessSnackbar(context, "Login successful!");
    } on FirebaseAuthException catch (e) {
      _showErrorSnackbar(context, _getFirebaseAuthErrorMessage(e.code));
    }
  }

  /// ✅ **Email & Password Signup with Firestore Storage**
  static Future<void> signup({
    required BuildContext context,
    required TextEditingController usernameController,
    required TextEditingController emailController,
    required TextEditingController passwordController,
    required TextEditingController confirmPasswordController,
  }) async {
    String username = usernameController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();

    if (username.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showErrorSnackbar(context, "Please fill in all fields");
      return;
    }

    if (password != confirmPassword) {
      _showErrorSnackbar(context, "Passwords do not match");
      return;
    }

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _saveUserToFirestore(userCredential.user, username);

      _showSuccessSnackbar(context, "Signup successful!");
    } on FirebaseAuthException catch (e) {
      _showErrorSnackbar(context, _getFirebaseAuthErrorMessage(e.code));
    }
  }

  /// ✅ **Logout Function**
  static Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  /// ✅ **Helper: Store User Data in Firestore**
  static Future<void> _saveUserToFirestore(User? user,
      [String? username]) async {
    if (user == null) return;

    final userData = {
      "uid": user.uid,
      "username": username ?? user.displayName ?? "Unknown",
      "email": user.email,
      "photoUrl": user.photoURL ?? "",
      "createdAt": DateTime.now(),
    };

    await _firestore
        .collection("users")
        .doc(user.uid)
        .set(userData, SetOptions(merge: true));
  }

  /// ✅ **Helper: Error Handling Messages**
  static String _getFirebaseAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'email-already-in-use':
        return "This email is already in use.";
      case 'weak-password':
        return "The password is too weak.";
      case 'user-not-found':
        return "No account found for this email.";
      case 'wrong-password':
        return "Incorrect password.";
      case 'invalid-email':
        return "Invalid email address.";
      default:
        return "An error occurred. Please try again.";
    }
  }

  /// ✅ **Helper: Show Success Snackbar**
  static void _showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  /// ✅ **Helper: Show Error Snackbar**
  static void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
