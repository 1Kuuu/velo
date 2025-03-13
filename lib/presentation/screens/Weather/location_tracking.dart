import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:velora/presentation/screens/Weather/navigation_service.dart';

// Add your API key here
const String _googleMapsApiKey = 'AIzaSyCr8zGQrS2vixQewM_TTqVKq4caiA13dmo';

class LocationTracking extends StatefulWidget {
  final String? userId;
  const LocationTracking({this.userId, super.key});

  @override
  State<LocationTracking> createState() => _LocationTrackingState();
}

class _LocationTrackingState extends State<LocationTracking> {
  final loc.Location _locationController = loc.Location();
  final Completer<GoogleMapController> _controller = Completer();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late final NavigationService _navigationService;

  LatLng? _currentLocation;
  LatLng? _destinationLocation;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  StreamSubscription<loc.LocationData>? _locationSubscription;
  double _bearing = 0;
  bool _followUser = false;
  double _zoom = 15;
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _recentSearches = [];
  String? _estimatedDuration;
  String? _estimatedDistance;
  List<Map<String, dynamic>> _directionSteps = [];
  bool _showDirectionsList = false;
  bool _isNavigating = false;
  Timer? _navigationTimer;
  double _remainingDistance = 0;
  String? _nextInstruction;
  int _currentStepIndex = 0;

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(14.5995, 120.9842), // Manila coordinates as fallback
    zoom: 15,
  );

  @override
  void initState() {
    super.initState();
    _navigationService = NavigationService(apiKey: _googleMapsApiKey);
    _initializeLocation();
    if (widget.userId != null) {
      _loadRecentSearches();
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _navigationTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    await _checkLocationPermission();
    final locationData = await _locationController.getLocation();
    if (locationData.latitude != null && locationData.longitude != null) {
      setState(() {
        _currentLocation =
            LatLng(locationData.latitude!, locationData.longitude!);
        _bearing = locationData.heading ?? 0;
      });
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentLocation!,
            zoom: _zoom,
            bearing: _bearing,
            tilt: 45,
          ),
        ),
      );
    }
    await _startLocationUpdates();
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await _locationController.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationController.requestService();
      if (!serviceEnabled) return;
    }

    loc.PermissionStatus permission = await _locationController.hasPermission();
    if (permission == loc.PermissionStatus.denied) {
      permission = await _locationController.requestPermission();
      if (permission != loc.PermissionStatus.granted) return;
    }
  }

  Future<void> _startLocationUpdates() async {
    await _locationController.changeSettings(
      accuracy: loc.LocationAccuracy.high,
      interval: 1000,
      distanceFilter: 5,
    );

    _locationSubscription = _locationController.onLocationChanged.listen(
      (loc.LocationData locationData) async {
        if (locationData.latitude != null && locationData.longitude != null) {
          final newLocation = LatLng(
            locationData.latitude!,
            locationData.longitude!,
          );

          setState(() {
            _currentLocation = newLocation;
            _bearing = locationData.heading ?? _bearing;
            _updateMarkers();
          });

          if (_followUser) {
            final controller = await _controller.future;
            await controller.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: newLocation,
                  zoom: _zoom,
                  bearing: _bearing,
                  tilt: 45,
                ),
              ),
            );
          }
        }
      },
    );
  }

  void _updateMarkers() {
    setState(() {
      _markers = {
        if (_currentLocation != null)
          Marker(
            markerId: const MarkerId('current_location'),
            position: _currentLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure),
            rotation: _bearing,
            flat: true,
            anchor: const Offset(0.5, 0.5),
          ),
        if (_destinationLocation != null && !_isNavigating)
          Marker(
            markerId: const MarkerId('destination'),
            position: _destinationLocation!,
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialPosition,
            markers: _markers,
            polylines: _polylines,
            onMapCreated: (GoogleMapController controller) async {
              _controller.complete(controller);
              if (_isNavigating) {
                await _updateMapStyle();
              }
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            compassEnabled: true,
            tiltGesturesEnabled: true,
            rotateGesturesEnabled: true,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onTap: _handleMapTap,
            mapType: MapType.normal,
          ),
          // Search bar
          if (!_isNavigating)
            Positioned(
              top: isSmallScreen ? 40 : 60,
              left: isSmallScreen ? 20 : screenSize.width * 0.1,
              right: isSmallScreen ? 20 : screenSize.width * 0.1,
              child: _buildSearchBar(),
            ),
          // Navigation banner
          if (_isNavigating && _nextInstruction != null)
            Positioned(
              top: MediaQuery.of(context).padding.top,
              left: 0,
              right: 0,
              child: _buildNavigationBanner(),
            ),
          // Bottom controls
          Positioned(
            bottom: 30,
            right: 20,
            child: _buildNavigationControls(),
          ),
          // Route info
          if (!_isNavigating && _estimatedDuration != null)
            Positioned(
              bottom: 30,
              left: 20,
              child: _buildRouteInfo(),
            ),
        ],
      ),
    );
  }

  void _handleMapTap(LatLng position) async {
    setState(() {
      _destinationLocation = position;
      _updateMarkers();
      _polylines.clear();
      _estimatedDuration = null;
      _estimatedDistance = null;
      _showDirectionsList = false;
      _directionSteps.clear();
    });
  }

  void _updateZoom(double delta) async {
    final controller = await _controller.future;
    final zoom = await controller.getZoomLevel();

    controller
        .animateCamera(CameraUpdate.zoomTo((zoom + delta).clamp(3.0, 20.0)));
  }

  Future<void> _startNavigation() async {
    if (_currentLocation == null || _destinationLocation == null) return;

    setState(() {
      _isNavigating = true;
      _followUser = true;
      _showDirectionsList = false; // Hide the directions list when navigating
    });

    await _updateMapStyle();

    final controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _currentLocation!,
          zoom: 19, // Closer zoom for navigation
          bearing: _bearing,
          tilt: 60, // More tilt for better navigation view
        ),
      ),
    );

    _navigationTimer?.cancel();
    _navigationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_currentLocation != null && _isNavigating) {
        _updateNavigationInfo();
      }
    });

    await _getDirections();
    _updateNavigationInfo();
  }

  void _stopNavigation() {
    setState(() {
      _isNavigating = false;
      _followUser = false;
      _navigationTimer?.cancel();
      _navigationTimer = null;
      _nextInstruction = null;
      _currentStepIndex = 0;
    });
    _updateMapStyle();
  }

  void _updateNavigationInfo() {
    if (_directionSteps.isEmpty || _currentStepIndex >= _directionSteps.length)
      return;

    final currentStep = _directionSteps[_currentStepIndex];
    final stepEndLocation = LatLng(
      currentStep['endLocation']['lat'],
      currentStep['endLocation']['lng'],
    );

    // Calculate distance to next turn
    _remainingDistance = _navigationService.calculateDistance(
      _currentLocation!,
      stepEndLocation,
    );

    // Update next instruction and move to next step if needed
    if (_remainingDistance < 0.05) {
      // 50 meters threshold
      if (_currentStepIndex < _directionSteps.length - 1) {
        _currentStepIndex++;
        setState(() {
          _nextInstruction = _directionSteps[_currentStepIndex]['instruction'];
          _updateNavigationUI();
        });
      }
    } else {
      setState(() {
        _nextInstruction = currentStep['instruction'];
        _updateNavigationUI();
      });
    }
  }

  void _updateNavigationUI() {
    if (!_isNavigating || _currentStepIndex >= _directionSteps.length) return;

    final currentStep = _directionSteps[_currentStepIndex];
    final nextStep = _currentStepIndex + 1 < _directionSteps.length
        ? _directionSteps[_currentStepIndex + 1]
        : null;

    setState(() {
      // Update markers for current navigation step
      _markers = {
        if (_currentLocation != null)
          Marker(
            markerId: const MarkerId('current_location'),
            position: _currentLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure),
            rotation: _bearing,
            flat: true,
            anchor: const Offset(0.5, 0.5),
          ),
        if (nextStep != null)
          Marker(
            markerId: const MarkerId('next_turn'),
            position: LatLng(
              nextStep['startLocation']['lat'],
              nextStep['startLocation']['lng'],
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueOrange),
            anchor: const Offset(0.5, 0.5),
          ),
      };

      // Update the navigation banner
      _nextInstruction =
          '${currentStep['instruction']} (${currentStep['distance']})';
      if (nextStep != null) {
        _estimatedDistance = nextStep['distance'];
        _estimatedDuration = nextStep['duration'];
      }
    });
  }

  Future<void> _getDirections() async {
    if (_currentLocation == null || _destinationLocation == null) {
      return;
    }

    try {
      final result = await _navigationService.getDirections(
        _currentLocation!,
        _destinationLocation!,
      );

      if (result != null) {
        setState(() {
          // Create polylines from the decoded points
          _polylines = result['polylines'].map<Polyline>((polyline) {
            final List<LatLng> points =
                polyline['decoded_points'] as List<LatLng>;
            return Polyline(
              polylineId: PolylineId(polyline['id']),
              points: points,
              color: polyline['color'],
              width: polyline['width'],
              endCap: Cap.roundCap,
              startCap: Cap.roundCap,
              jointType: JointType.round,
            );
          }).toSet();

          _estimatedDuration = result['duration'];
          _estimatedDistance = result['distance'];
          _directionSteps = List<Map<String, dynamic>>.from(result['steps']);
          _showDirectionsList = true;

          if (_directionSteps.length > 1) {
            _nextInstruction = _directionSteps[1]['instruction'];
          }
        });

        // Adjust map view
        final controller = await _controller.future;
        if (_isNavigating) {
          controller.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: _currentLocation!,
                zoom: 18,
                bearing: _bearing,
                tilt: 60,
              ),
            ),
          );
        } else {
          final bounds = LatLngBounds(
            southwest: LatLng(
              result['bounds']['southwest']['lat'],
              result['bounds']['southwest']['lng'],
            ),
            northeast: LatLng(
              result['bounds']['northeast']['lat'],
              result['bounds']['northeast']['lng'],
            ),
          );
          controller.animateCamera(
            CameraUpdate.newLatLngBounds(bounds, 100),
          );
        }
      }
    } catch (e) {
      debugPrint('Navigation update: $e');
    }
  }

  // Direction Steps List Widget
  Widget _buildDirectionsList() {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.directions, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Step-by-Step Directions',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _getDirections,
                          tooltip: 'Refresh directions',
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              _showDirectionsList = false;
                            });
                          },
                          tooltip: 'Close directions',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'From: Current Location',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.flag, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'To: ${_searchController.text}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Icon(Icons.timer_outlined,
                                  color: Colors.blue),
                              const SizedBox(height: 4),
                              Text(
                                _estimatedDuration ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            height: 30,
                            width: 1,
                            color: Colors.blue.withOpacity(0.3),
                          ),
                          Column(
                            children: [
                              const Icon(Icons.route_outlined,
                                  color: Colors.blue),
                              const SizedBox(height: 4),
                              Text(
                                _estimatedDistance ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.all(8),
              itemCount: _directionSteps.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final step = _directionSteps[index];
                final isSpecial = step['isSpecial'] ?? false;

                return InkWell(
                  onTap: () async {
                    final controller = await _controller.future;
                    final stepLocation = LatLng(
                      step['startLocation']['lat'],
                      step['startLocation']['lng'],
                    );
                    controller.animateCamera(
                      CameraUpdate.newLatLngZoom(stepLocation, 18),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12.0, horizontal: 8.0),
                    decoration: BoxDecoration(
                      color: isSpecial ? Colors.blue.withOpacity(0.05) : null,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isSpecial
                                ? Colors.blue
                                : Colors.blue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              step['maneuverIcon'] ?? '•',
                              style: TextStyle(
                                fontSize: 16,
                                color: isSpecial ? Colors.white : Colors.blue,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                step['instruction'] ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSpecial
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              if (!isSpecial &&
                                  step['distance'].isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '${step['distance']} • ${step['duration']}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<LatLng> _decodePolyline(String encoded) {
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

  Future<void> _loadRecentSearches() async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(widget.userId)
          .collection('searches')
          .doc('recent')
          .get();

      if (doc.exists && doc.data() != null) {
        final List<dynamic> searches = doc.data()!['searches'] ?? [];
        setState(() {
          _recentSearches = List<Map<String, dynamic>>.from(searches);
        });
      }
    } catch (e) {
      debugPrint('Error loading r ecent searches: $e');
    }
  }

  Future<void> _saveRecentSearch(Map<String, dynamic> search) async {
    if (widget.userId == null) return;

    try {
      // Add to local list
      setState(() {
        _recentSearches.insert(0, search);
        if (_recentSearches.length > 5) {
          _recentSearches = _recentSearches.take(5).toList();
        }
      });

      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(widget.userId)
          .collection('searches')
          .doc('recent')
          .set({
        'searches': _recentSearches,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error saving recent search: $e');
    }
  }

  // Update the map style when navigation starts
  Future<void> _updateMapStyle() async {
    final controller = await _controller.future;
    final style = _isNavigating
        ? '[{"featureType":"poi","elementType":"labels","stylers":[{"visibility":"off"}]}]'
        : '[]';
    await controller.setMapStyle(style);
  }

  Future<void> _getPlaceDetails(String placeId) async {
    try {
      final placeDetails = await _navigationService.getPlaceDetails(placeId);
      if (placeDetails != null) {
        _showPlaceDetailsSheet(placeDetails);
      }
    } catch (e) {
      debugPrint('Error getting place details: $e');
    }
  }

  void _showPlaceDetailsSheet(Map<String, dynamic> details) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.2,
        maxChildSize: 0.8,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                details['name'] ?? '',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (details['rating'] != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      details['rating'].toString(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < (details['rating'] as num).floor()
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              if (details['isOpen'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        details['isOpen'] ? Colors.green[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    details['isOpen'] ? 'Open Now' : 'Closed',
                    style: TextStyle(
                      color: details['isOpen']
                          ? Colors.green[700]
                          : Colors.red[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              _buildInfoRow(Icons.location_on, details['address'] ?? ''),
              if (details['phone'] != null)
                _buildInfoRow(Icons.phone, details['phone']),
              if (details['website'] != null)
                _buildInfoRow(Icons.language, details['website']),
              if (details['types'] != null) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (details['types'] as List).map((type) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        type.toString().replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              if (details['reviews'] != null) ...[
                const SizedBox(height: 24),
                const Text(
                  'Reviews',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...List.generate(
                  min(3, (details['reviews'] as List).length),
                  (index) {
                    final review = details['reviews'][index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  review['author_name'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${review['rating']}/5',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(review['text'] ?? ''),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> suggestionsCallback(String pattern) async {
    if (pattern.length < 2) {
      return _recentSearches.take(5).toList();
    }

    try {
      final results =
          await _navigationService.searchPlaces(pattern, _currentLocation);

      // Combine with recent searches for short queries
      if (pattern.length < 3) {
        final recentSearches = _recentSearches
            .where((search) => search['description']
                .toString()
                .toLowerCase()
                .contains(pattern.toLowerCase()))
            .take(3)
            .map((search) {
          search['icon'] = '⭐';
          search['isRecentSearch'] = true;
          return search;
        }).toList();

        return [...recentSearches, ...results];
      }

      return results;
    } catch (e) {
      debugPrint('Search error: $e');
      // Return filtered recent searches as fallback
      return _recentSearches
          .where((search) => search['description']
              .toString()
              .toLowerCase()
              .contains(pattern.toLowerCase()))
          .take(5)
          .toList();
    }
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TypeAheadField<Map<String, dynamic>>(
        textFieldConfiguration: TextFieldConfiguration(
          controller: _searchController,
          focusNode: _searchFocusNode,
          decoration: InputDecoration(
            hintText: 'Search location...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchResults.clear();
                      });
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.my_location),
                  onPressed: () async {
                    if (_currentLocation != null) {
                      try {
                        final response = await http.get(
                          Uri.parse(
                              'https://maps.googleapis.com/maps/api/geocode/json'
                              '?latlng=${_currentLocation!.latitude},${_currentLocation!.longitude}'
                              '&key=$_googleMapsApiKey'),
                        );

                        if (response.statusCode == 200) {
                          final data = json.decode(response.body);
                          if (data['status'] == 'OK' &&
                              data['results'].isNotEmpty) {
                            _searchController.text =
                                data['results'][0]['formatted_address'];
                          }
                        }
                      } catch (e) {
                        debugPrint(
                            'Error getting current location address: $e');
                      }
                    }
                  },
                ),
              ],
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          style: const TextStyle(fontSize: 16),
        ),
        suggestionsCallback: suggestionsCallback,
        itemBuilder: (BuildContext context, Map<String, dynamic> suggestion) {
          final bool isRecentSearch = suggestion['isRecentSearch'] ?? false;
          final icon = suggestion['icon'] ?? '📍';

          return ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isRecentSearch
                    ? Colors.grey.withOpacity(0.1)
                    : Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  icon,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            title: Text(
              isRecentSearch
                  ? suggestion['description']
                  : suggestion['mainText'],
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isRecentSearch ? Colors.grey[700] : Colors.black,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRecentSearch
                      ? 'Recent search'
                      : suggestion['secondaryText'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (suggestion['distance'] != null)
                  Text(
                    suggestion['distance'],
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            trailing: isRecentSearch
                ? const Icon(Icons.history, color: Colors.grey, size: 16)
                : const Icon(Icons.arrow_forward_ios,
                    color: Colors.grey, size: 16),
          );
        },
        onSuggestionSelected: (Map<String, dynamic> suggestion) async {
          _searchController.text = suggestion['description'] as String;
          await _getPlaceDetails(suggestion['place_id']);
        },
        noItemsFoundBuilder: (context) => Container(
          height: 60,
          alignment: Alignment.center,
          child: const Text(
            'No locations found',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
        loadingBuilder: (context) => Container(
          height: 60,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildNavigationBanner() {
    final currentStep = _currentStepIndex < _directionSteps.length
        ? _directionSteps[_currentStepIndex]
        : null;

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _navigationService.getNavigationStatusColor(
                    currentStep?['maneuver'] ?? '',
                  ),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  currentStep?['maneuverIcon'] ?? '⬆',
                  style: const TextStyle(fontSize: 24, color: Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nextInstruction ?? '',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${(_remainingDistance * 1000).round()} m',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          color: Colors.grey[100],
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_estimatedDuration • $_estimatedDistance',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'ETA ${TimeOfDay.now().format(context)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationControls() {
    return Column(
      children: [
        if (_destinationLocation != null)
          FloatingActionButton.extended(
            heroTag: 'directions',
            onPressed: () async {
              if (_currentLocation == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Waiting for your current location...'),
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }

              if (_isNavigating) {
                _stopNavigation();
              } else {
                await _startNavigation();
              }
            },
            backgroundColor: _isNavigating ? Colors.red : Colors.blue,
            icon: Icon(_isNavigating ? Icons.stop : Icons.navigation),
            label: Text(_isNavigating ? 'Stop' : 'Start Navigation'),
          ),
        const SizedBox(height: 10),
        FloatingActionButton(
          heroTag: 'follow',
          onPressed: () async {
            setState(() {
              _followUser = !_followUser;
            });
            if (_followUser && _currentLocation != null) {
              final controller = await _controller.future;
              controller.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    target: _currentLocation!,
                    zoom: _zoom,
                    bearing: _bearing,
                    tilt: 45,
                  ),
                ),
              );
            }
          },
          backgroundColor: _followUser ? Colors.blue : Colors.white,
          foregroundColor: _followUser ? Colors.white : Colors.blue,
          child: Icon(_followUser ? Icons.gps_fixed : Icons.gps_not_fixed),
        ),
        const SizedBox(height: 10),
        FloatingActionButton(
          heroTag: 'zoom_in',
          onPressed: () => _updateZoom(1),
          child: const Icon(Icons.add),
        ),
        const SizedBox(height: 10),
        FloatingActionButton(
          heroTag: 'zoom_out',
          onPressed: () => _updateZoom(-1),
          child: const Icon(Icons.remove),
        ),
      ],
    );
  }

  Widget _buildRouteInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Duration: $_estimatedDuration'),
          Text('Distance: $_estimatedDistance'),
        ],
      ),
    );
  }
}
