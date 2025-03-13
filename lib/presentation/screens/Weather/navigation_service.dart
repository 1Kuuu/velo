import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class NavigationService {
  final String _apiKey;

  NavigationService({required String apiKey}) : _apiKey = apiKey;

  Future<Map<String, dynamic>?> getDirections(
      LatLng origin, LatLng destination) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&mode=driving'
          '&key=$_apiKey',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          final steps = _processSteps(leg['steps']);
          final encodedPolyline = route['overview_polyline']['points'];

          return {
            'polylines': [
              {
                'id': 'route_outline',
                'points': encodedPolyline,
                'color': Colors.black54,
                'width': 8,
              },
              {
                'id': 'route_main',
                'points': encodedPolyline,
                'color': Colors.blue,
                'width': 5,
              },
            ],
            'bounds': route['bounds'],
            'duration': leg['duration']['text'],
            'distance': leg['distance']['text'],
            'steps': steps,
          };
        }
      }
    } catch (e) {
      debugPrint('Error getting directions: $e');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> searchPlaces(
      String query, LatLng? location) async {
    if (query.isEmpty) return [];

    try {
      final locationParam = location != null
          ? '&location=${location.latitude},${location.longitude}&rankby=distance'
          : '';
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/place/autocomplete/json'
          '?input=${Uri.encodeComponent(query)}'
          '$locationParam'
          '&key=$_apiKey',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return List<Map<String, dynamic>>.from(
            data['predictions'].map((prediction) => {
                  'place_id': prediction['place_id'],
                  'description': prediction['description'],
                  'mainText': prediction['structured_formatting']['main_text'],
                  'secondaryText': prediction['structured_formatting']
                      ['secondary_text'],
                }),
          );
        }
      }
    } catch (e) {
      debugPrint('Error searching places: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/place/details/json'
          '?place_id=$placeId'
          '&fields=name,rating,formatted_address,formatted_phone_number,website,opening_hours,types,reviews'
          '&key=$_apiKey',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final result = data['result'];
          return {
            'name': result['name'],
            'rating': result['rating'],
            'address': result['formatted_address'],
            'phone': result['formatted_phone_number'],
            'website': result['website'],
            'isOpen': result['opening_hours']?['open_now'],
            'types': result['types'],
            'reviews': result['reviews'],
          };
        }
      }
    } catch (e) {
      debugPrint('Error getting place details: $e');
    }
    return null;
  }

  double calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    // Convert latitude and longitude from degrees to radians
    final lat1 = point1.latitude * pi / 180;
    final lon1 = point1.longitude * pi / 180;
    final lat2 = point2.latitude * pi / 180;
    final lon2 = point2.longitude * pi / 180;

    // Haversine formula
    final dLat = lat2 - lat1;
    final dLon = lon2 - lon1;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    // Calculate distance in kilometers
    return earthRadius * c;
  }

  Color getNavigationStatusColor(String maneuver) {
    switch (maneuver.toLowerCase()) {
      case 'turn-right':
      case 'turn-left':
        return Colors.blue.shade700;
      case 'roundabout':
      case 'rotary':
        return Colors.orange.shade700;
      case 'merge':
      case 'ramp':
        return Colors.green.shade700;
      case 'arrive':
        return Colors.red.shade700;
      default:
        return Colors.blue.shade700;
    }
  }

  List<Map<String, dynamic>> _processSteps(List<dynamic> steps) {
    return steps.map<Map<String, dynamic>>((step) {
      final maneuver = step['maneuver'] ?? '';
      String maneuverIcon = '⬆';
      bool isSpecial = false;

      switch (maneuver.toLowerCase()) {
        case 'turn-right':
          maneuverIcon = '➡';
          isSpecial = true;
          break;
        case 'turn-left':
          maneuverIcon = '⬅';
          isSpecial = true;
          break;
        case 'roundabout':
        case 'rotary':
          maneuverIcon = '🔄';
          isSpecial = true;
          break;
        case 'merge':
          maneuverIcon = '↱';
          isSpecial = true;
          break;
        case 'ramp':
          maneuverIcon = '⤴';
          isSpecial = true;
          break;
        case 'arrive':
          maneuverIcon = '📍';
          isSpecial = true;
          break;
      }

      return {
        'instruction': step['html_instructions']
            .toString()
            .replaceAll(RegExp(r'<[^>]*>'), ''),
        'distance': step['distance']['text'],
        'duration': step['duration']['text'],
        'maneuver': maneuver,
        'maneuverIcon': maneuverIcon,
        'isSpecial': isSpecial,
        'startLocation': step['start_location'],
        'endLocation': step['end_location'],
      };
    }).toList();
  }
}
