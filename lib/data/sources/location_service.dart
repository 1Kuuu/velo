import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../presentation/screens/Weather/const.dart';

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<Position>? _positionStream;

  late String locationShareRequestsCollection;

  String? get userLocationsCollection => null;

  // Check and request location permissions
  Future<bool> checkAndRequestPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // User still denied after prompt
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are permanently denied
      return false;
    }

    // Permission is granted (either whenInUse or always)
    return true;
  }

  // Start sharing current user's location

  // Stop sharing location
  Future<void> stopSharingLocation(String userLocationsCollection) async {
    await _positionStream?.cancel();
    _positionStream = null;

    // Update isSharing status in Firestore
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await _firestore
          .collection(userLocationsCollection)
          .doc(currentUser.uid)
          .update({
        'isSharing': false,
      });
    } catch (e) {
      print('Error updating sharing status: $e');
      // Don't rethrow here to ensure stream is still canceled
    }
  }

  // Update user location in Firestore
  Future<void> _updateUserLocation({
    required double latitude,
    required double longitude,
    required double heading,
    required double speed,
    required DateTime timestamp,
    required String userLocationsCollection,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await _firestore
          .collection(userLocationsCollection)
          .doc(currentUser.uid)
          .set({
        'userId': currentUser.uid,
        'displayName': currentUser.displayName ?? 'Anonymous User',
        'email': currentUser.email,
        'photoURL': currentUser.photoURL,
        'position': GeoPoint(latitude, longitude),
        'heading': heading,
        'speed': speed,
        'lastUpdated': Timestamp.fromDate(timestamp),
        'isSharing': true,
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating user location: $e');
    }
  }

  // Get a specific user's location
  Stream<DocumentSnapshot> getUserLocation(String userId) {
    return _firestore
        .collection(userLocationsCollection!)
        .doc(userId)
        .snapshots();
  }

  // Convert Firestore Document to LatLng
  LatLng? documentToLatLng(DocumentSnapshot doc) {
    if (!doc.exists) return null;

    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return null;

    final GeoPoint? position = data['position'] as GeoPoint?;
    if (position == null) return null;

    return LatLng(position.latitude, position.longitude);
  }

  // Calculate distance between two points
  double calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
        point1.latitude, point1.longitude, point2.latitude, point2.longitude);
  }

  // Request location sharing with another user
  Future<void> requestLocationSharing(String targetUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not logged in');

    try {
      await _firestore.collection(locationShareRequestsCollection).add({
        'fromUserId': currentUser.uid,
        'fromUserName': currentUser.displayName ?? 'Unknown User',
        'toUserId': targetUserId,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error requesting location sharing: $e');
      rethrow;
    }
  }

  // Accept location sharing request
  Future<void> acceptLocationSharingRequest(String requestId) async {
    try {
      await _firestore
          .collection(locationShareRequestsCollection)
          .doc(requestId)
          .update({
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error accepting location request: $e');
      rethrow;
    }
  }

  // Reject location sharing request
  Future<void> rejectLocationSharingRequest(String requestId) async {
    try {
      await _firestore
          .collection(locationShareRequestsCollection)
          .doc(requestId)
          .update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error rejecting location request: $e');
      rethrow;
    }
  }

  // Get pending location sharing requests
  Stream<QuerySnapshot> getPendingLocationRequests() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.empty();

    return _firestore
        .collection(locationShareRequestsCollection)
        .where('toUserId', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }
}
