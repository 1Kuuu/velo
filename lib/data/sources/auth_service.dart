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
    UserCredential? result;
    // Create a new Google Sign In instance with specific configuration
    final GoogleSignIn googleSignIn = GoogleSignIn(
      signInOption: SignInOption.standard,
      scopes: ['email', 'profile'],
    );

    try {
      print("🔐 Starting Google Sign-In process...");

      // Ensure we're signed out before attempting to sign in
      await googleSignIn.signOut();
      await _auth.signOut();

      print("🔐 Requesting Google account...");

      // Get Google Sign-In authentication directly
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        print("❌ Google Sign-In cancelled or failed");
        return null;
      }

      // Get authentication tokens directly
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print("🔐 Signing in to Firebase...");

      try {
        // Direct Firebase Auth attempt
        result = await _auth.signInWithCredential(credential);
        final User? user = result.user;

        if (user != null) {
          print("✅ Firebase Auth successful - UID: ${user.uid}");

          // Update Firestore
          await _handleFirestoreUser(user);

          if (context.mounted) {
            _showToast(context, "Successfully signed in!", Icons.check_circle,
                Colors.green);
          }
        } else {
          throw Exception("Failed to get user after Firebase sign in");
        }
      } catch (firebaseError) {
        print("❌ Firebase Auth Error: $firebaseError");

        if (firebaseError.toString().contains('PigeonUserDetails')) {
          // If we have a valid Firebase user despite the error, consider it a success
          final currentUser = _auth.currentUser;
          if (currentUser != null) {
            await _handleFirestoreUser(currentUser);
            if (context.mounted) {
              _showToast(context, "Successfully signed in!", Icons.check_circle,
                  Colors.green);
            }
            // Return the existing result or create a new credential
            return result ?? await _auth.signInWithCredential(credential);
          }
        }

        rethrow;
      }

      return result;
    } catch (e) {
      print("❌ Google Sign-In error caught: $e");

      // Check if we still have a valid result despite the PigeonUserDetails error
      if (e.toString().contains('PigeonUserDetails') && result != null) {
        return result;
      }

      if (context.mounted) {
        _showToast(context, "Failed to sign in with Google. Please try again.",
            Icons.error, Colors.red);
      }
      return null;
    } finally {
      // Clean up resources without throwing additional errors
      try {
        await Future.wait([
          googleSignIn.signOut().catchError((e) {
            print("📝 Cleanup signOut error ignored: $e");
            return null;
          }),
          googleSignIn.disconnect().catchError((e) {
            print("📝 Cleanup disconnect error ignored: $e");
            return null;
          })
        ], eagerError: false);
      } catch (e) {
        print("📝 Cleanup errors ignored: $e");
      }
    }
  }

  /// 🔹 Logout function with proper cleanup
  Future<bool> signOut(BuildContext context) async {
    try {
      print("🔐 Starting sign out process...");

      final user = _auth.currentUser;
      if (user != null) {
        // Update user's last logout time in Firestore
        try {
          await _firestore.collection('users').doc(user.uid).update({
            'lastLogout': FieldValue.serverTimestamp(),
            'isAuthenticated': false
          });
          print("✅ Updated user logout status in Firestore");
        } catch (e) {
          print("❌ Error updating logout status: $e");
        }
      }

      // Sign out from authentication providers
      await Future.wait([
        _googleSignIn.signOut().catchError((e) {
          print("📝 Google SignOut error ignored: $e");
          return null;
        }),
        _auth.signOut().catchError((e) {
          print("📝 Firebase SignOut error ignored: $e");
          return null;
        })
      ], eagerError: false);

      print("✅ Signed out from authentication providers");
      return true;
    } catch (e) {
      print("❌ Error during sign out: $e");
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

    print("🔐 Checking Firestore user document...");
    final DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(user.uid).get();

    try {
      if (!userDoc.exists) {
        print("📝 Creating new user document in Firestore...");
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
        print("✅ User document created successfully");
      } else {
        print("📝 Updating existing user document...");
        // Preserve existing setupComplete status and other important fields
        final existingData = userDoc.data() as Map<String, dynamic>;

        await _firestore.collection('users').doc(user.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
          'isAuthenticated': true,
          'userName': user.displayName ?? existingData['userName'],
          'email': user.email ?? existingData['email'],
          'profileUrl': user.photoURL ?? existingData['profileUrl'],
          // Preserve existing setupComplete status
          'setupComplete': existingData['setupComplete'] ?? false,
          // Preserve any other important user data
          'preferences': existingData['preferences'],
          'bikeType': existingData['bikeType'],
          'experience': existingData['experience'],
          'goals': existingData['goals'],
        });
        print("✅ User document updated successfully with preserved data");
      }
    } catch (e) {
      print("❌ Error handling Firestore user: $e");
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
