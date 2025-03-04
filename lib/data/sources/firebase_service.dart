import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseServices {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔹 Create or Update User Document in Firestore
  static Future<void> createUserDocument({
    required String uid,
    required String username,
    required String email,
    String profileUrl = "",
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'userName': username,
        'email': email,
        'profileUrl': profileUrl,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // Merge prevents overwriting existing data
    } catch (e) {
      print("❌ Firestore Error (createUserDocument): $e");
    }
  }

  /// 🔹 Get User Data
  static Future<DocumentSnapshot?> getUserData(String uid) async {
    try {
      return await _firestore.collection('users').doc(uid).get();
    } catch (e) {
      print("❌ Firestore Error (getUserData): $e");
      return null;
    }
  }

  /// 🔹 Update User Data (e.g., username, profile picture)
  static Future<void> updateUserData(
      String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      print("❌ Firestore Error (updateUserData): $e");
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
