import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class LocationHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID or null if not logged in
  String? get currentUserId => _auth.currentUser?.uid;

  // Check if user is logged in
  bool get isUserLoggedIn => _auth.currentUser != null;

  // Save planned trip to history
  Future<void> savePlannedTrip({
    required LatLng origin,
    required LatLng destination,
    required String originName,
    required String destinationName,
    String? notes,
  }) async {
    if (!isUserLoggedIn) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('trips')
          .add({
        'origin': GeoPoint(origin.latitude, origin.longitude),
        'destination': GeoPoint(destination.latitude, destination.longitude),
        'originName': originName,
        'destinationName': destinationName,
        'notes': notes,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'planned', // planned, ongoing, completed, cancelled
      });
    } catch (e) {
      print('Error saving planned trip: $e');
      rethrow;
    }
  }

  // Save current location
  Future<void> saveCurrentLocation({String? notes}) async {
    if (!isUserLoggedIn) return;

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('locations')
          .add({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'locationName': 'Current Location', // Ideally use geocoding here
        'timestamp': FieldValue.serverTimestamp(),
        'notes': notes,
      });
    } catch (e) {
      print('Error saving current location: $e');
      rethrow;
    }
  }

  // Get user's location history (trips)
  Future<List<Map<String, dynamic>>> getTripsHistory() async {
    if (!isUserLoggedIn) return [];

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('trips')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        final origin = data['origin'] as GeoPoint;
        final destination = data['destination'] as GeoPoint;

        return {
          'id': doc.id,
          'originLatitude': origin.latitude,
          'originLongitude': origin.longitude,
          'destinationLatitude': destination.latitude,
          'destinationLongitude': destination.longitude,
          'originName': data['originName'] ?? 'Unknown origin',
          'destinationName': data['destinationName'] ?? 'Unknown destination',
          'notes': data['notes'],
          'createdAt': data['createdAt'],
          'status': data['status'] ?? 'planned',
        };
      }).toList();
    } catch (e) {
      print('Error getting trips history: $e');
      return [];
    }
  }

  getSharedLocationsHistory() {}

  getSharedWithMeLocations() {}

  saveSharedLocation(
      {required LatLng location,
      required String locationName,
      required List<String> sharedWithUserIds}) {}
}
