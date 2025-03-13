import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:velora/services/post_service.dart';

class NavigationService {
  final String _apiKey;
  final PostService _postService = PostService();

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
          '&alternatives=true'
          '&key=$_apiKey',
        ),
      );

      final directionsData = await _postService.processDirectionsResponse(
        response,
        PostService.directionsError,
      );

      if (directionsData != null) {
        final decodedPoints = _postService.decodePolyline(
          directionsData['overview_polyline']['points'],
        );

        final polylines = _postService.createPolylines(decodedPoints);

        return {
          'polylines': polylines
              .map((polyline) => {
                    'id': polyline.polylineId.value,
                    'points': decodedPoints,
                    'color': polyline.color,
                    'width': polyline.width,
                    'decoded_points': decodedPoints,
                  })
              .toList(),
          'bounds': directionsData['bounds'],
          'duration': directionsData['duration'],
          'distance': directionsData['distance'],
          'steps': _processSteps(directionsData['steps']),
          'start_location': directionsData['start_location'],
          'end_location': directionsData['end_location'],
        };
      }
    } catch (e) {
      debugPrint('${PostService.directionsError}: $e');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> searchPlaces(
      String query, LatLng? location) async {
    return await _postService.handleApiCall(
          apiCall: () async {
            if (query.isEmpty) return <Map<String, dynamic>>[];

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
                  data['predictions'].map((prediction) => <String, dynamic>{
                        'place_id': prediction['place_id'],
                        'description': prediction['description'],
                        'mainText': prediction['structured_formatting']
                            ['main_text'],
                        'secondaryText': prediction['structured_formatting']
                            ['secondary_text'],
                      }),
                );
              }
            }
            throw Exception(PostService.searchError);
          },
          errorMessage: PostService.searchError,
        ) ??
        <Map<String, dynamic>>[];
  }

  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    return await _postService.handleApiCall(
      apiCall: () async {
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
        throw Exception('Failed to get place details');
      },
      errorMessage: 'Error getting place details',
    );
  }

  double calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final lat1 = point1.latitude * pi / 180;
    final lon1 = point1.longitude * pi / 180;
    final lat2 = point2.latitude * pi / 180;
    final lon2 = point2.longitude * pi / 180;

    final dLat = lat2 - lat1;
    final dLon = lon2 - lon1;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

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
        'polyline': step['polyline'],
      };
    }).toList();
  }
}
