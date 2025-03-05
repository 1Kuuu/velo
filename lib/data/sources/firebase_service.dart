import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseServices {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔹 Get current user ID
  static String? get currentUserId => _auth.currentUser?.uid;

  /// 🔹 Create or Update User Document in Firestore
  static Future<void> createUserDocument({
    required String uid,
    required String username,
    required String email,
    String profileUrl = "",
  }) async {
    try {
      await _firestore.collection('user_profile').doc(uid).set({
        'name': username, // Changed 'userName' to 'name'
        'email': email,
        'profileUrl': profileUrl,
        'bio': "", // Ensure 'bio' field exists
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // Prevents overwriting existing data
    } catch (e) {
      print("❌ Firestore Error (createUserDocument): $e");
    }
  }

  /// 🔹 Get User Data
  static Future<DocumentSnapshot?> getUserData(String uid) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('user_profile').doc(uid).get();

      print("📌 getUserData fetched: ${userDoc.data()}"); // Debugging line

      return userDoc;
    } catch (e) {
      print("❌ Firestore Error (getUserData): $e");
      return null;
    }
  }

  /// 🔹 Update User Data (e.g., username, profile picture, setupComplete)
  static Future<void> updateUserData(
      String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      print("❌ Firestore Error (updateUserData): $e");
    }
  }

  /// 🔹 Check if user has completed onboarding
  static Future<bool> isOnboardingComplete() async {
    if (currentUserId == null) return false;
    DocumentSnapshot<Object?>? userData = await getUserData(currentUserId!);
    return userData?['setupComplete'] ?? false;
  }

  /// 🔹 Mark Setup as Complete
  static Future<void> completeOnboarding() async {
    if (currentUserId == null) return;
    try {
      await _firestore.collection('users').doc(currentUserId).update({
        'setupComplete': true,
      });
    } catch (e) {
      print("❌ Firestore Error (completeOnboarding): $e");
    }
  }

  /// 🔹 Delete User Document (if needed)
  static Future<void> deleteUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
    } catch (e) {
      print("❌ Firestore Error (deleteUser): $e");
    }
  }
}
