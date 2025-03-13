import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class PostService {
  static final PostService _instance = PostService._internal();
  factory PostService() => _instance;
  PostService._internal();

  // Error handling for API calls
  Future<T?> handleApiCall<T>({
    required Future<T> Function() apiCall,
    required String errorMessage,
    BuildContext? context,
  }) async {
    try {
      return await apiCall();
    } catch (e) {
      debugPrint('$errorMessage: $e');
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$errorMessage: $e')),
        );
      }
      return null;
    }
  }

  // Shared location-related functionality
  Future<Map<String, dynamic>?> getLocationName(
      LatLng location, String apiKey) async {
    return handleApiCall(
      apiCall: () async {
        final response = await http.get(
          Uri.parse('https://maps.googleapis.com/maps/api/geocode/json'
              '?latlng=${location.latitude},${location.longitude}'
              '&key=$apiKey'),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'OK' && data['results'].isNotEmpty) {
            final components = data['results'][0]['address_components'];
            String locationName = '';
            String fullAddress = data['results'][0]['formatted_address'];

            for (var component in components) {
              final types = component['types'] as List;
              if (types.contains('sublocality_level_1')) {
                locationName = component['long_name'];
                break;
              } else if (types.contains('locality')) {
                locationName = component['long_name'];
                break;
              }
            }

            return {
              'locationName': locationName,
              'fullAddress': fullAddress,
              'components': components,
            };
          }
        }
        throw Exception('Failed to get location name');
      },
      errorMessage: 'Error getting location name',
    );
  }

  // Shared navigation-related functionality
  Future<Map<String, dynamic>?> processDirectionsResponse(
    http.Response response,
    String errorMessage,
  ) async {
    return handleApiCall(
      apiCall: () async {
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
            final route = data['routes'][0];
            final leg = route['legs'][0];

            return {
              'duration': leg['duration']['text'],
              'distance': leg['distance']['text'],
              'start_location': leg['start_location'],
              'end_location': leg['end_location'],
              'steps': leg['steps'],
              'bounds': route['bounds'],
              'overview_polyline': route['overview_polyline'],
            };
          }
        }
        throw Exception(errorMessage);
      },
      errorMessage: errorMessage,
    );
  }

  // Shared polyline functionality
  List<LatLng> decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  // Shared styling for polylines
  Set<Polyline> createPolylines(List<LatLng> points) {
    return {
      Polyline(
        polylineId: const PolylineId('route_outline'),
        points: points,
        color: Colors.black54,
        width: 8,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ),
      Polyline(
        polylineId: const PolylineId('route_main'),
        points: points,
        color: Colors.blue,
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ),
    };
  }

  // Error messages
  static const String locationError = 'Error getting location';
  static const String directionsError = 'Error getting directions';
  static const String searchError = 'Error searching places';
  static const String networkError = 'Network error occurred';
  static const String permissionError = 'Location permission denied';
}
