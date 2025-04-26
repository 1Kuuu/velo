import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'const.dart';

void main() {
  runApp(const RideHailingApp());
}

class RideHailingApp extends StatelessWidget {
  const RideHailingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Navigation App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MapScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();

  LatLng? _currentPosition;
  LatLng? _destination;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final List<LatLng> _polylineCoordinates = [];

  String _distance = '';
  String _duration = '';

  StreamSubscription<Position>? _positionStream;
  bool _isMapCreated = false;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      bool serviceEnabled;
      LocationPermission permission;

      // Check if location services are enabled
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage =
              'Location services are disabled. Please enable location services in your device settings.';
          _isLoading = false;
        });
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _isLoading = true;
          _errorMessage = 'Requesting location permission...';
        });

        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage =
                'Location permissions denied. Maps require location access to show your position.';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage =
              'Location permissions permanently denied. Please enable them in app settings to use navigation features.';
          _isLoading = false;
        });
        return;
      }

      try {
        print("Getting current position...");
        // Get the current position with higher accuracy but with longer timeout
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.bestForNavigation,
            timeLimit:
                const Duration(seconds: 60), // Increased from 30 to 60 seconds
            forceAndroidLocationManager: false);

        print("Position obtained: ${position.latitude}, ${position.longitude}");

        if (mounted) {
          setState(() {
            _currentPosition = LatLng(position.latitude, position.longitude);
            _markers.add(Marker(
              markerId: const MarkerId('currentLocation'),
              position: _currentPosition!,
              infoWindow: const InfoWindow(title: 'Your Location'),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed),
            ));
            _isLoading = false;
          });

          // Move camera to current position if map is already created
          if (_isMapCreated) {
            final GoogleMapController controller = await _controller.future;
            controller.animateCamera(CameraUpdate.newCameraPosition(
              CameraPosition(
                target: _currentPosition!,
                zoom: 15.0,
              ),
            ));
          }
        }

        // Listen to position updates with higher accuracy and longer timeout
        _positionStream = Geolocator.getPositionStream(
                locationSettings: const LocationSettings(
                    accuracy: LocationAccuracy.bestForNavigation,
                    distanceFilter: locationUpdateMinimumDistanceMeters,
                    timeLimit: Duration(seconds: 60)))
            .listen((Position position) {
          print("Position update: ${position.latitude}, ${position.longitude}");
          if (mounted) {
            setState(() {
              _currentPosition = LatLng(position.latitude, position.longitude);

              // Update current location marker
              _markers.removeWhere(
                  (marker) => marker.markerId.value == 'currentLocation');
              _markers.add(Marker(
                markerId: const MarkerId('currentLocation'),
                position: _currentPosition!,
                infoWindow: const InfoWindow(title: 'Your Location'),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed),
              ));

              // Update route if destination is set
              if (_destination != null) {
                _getRoute();
              }
            });
          }
        }, onError: (error) {
          print("Position stream error: $error");
          setState(() {
            _errorMessage = 'Error tracking location: $error';
          });

          // If we got a timeout error, try to restart location tracking
          if (error is TimeoutException) {
            // Restart position stream with even longer timeout
            _positionStream?.cancel();

            // Only try to restart if mounted
            if (mounted) {
              Future.delayed(Duration(seconds: 3), () {
                if (mounted) {
                  // Clear error message
                  setState(() {
                    _errorMessage = 'Reconnecting to location service...';
                  });

                  // Restart position stream
                  _positionStream = Geolocator.getPositionStream(
                          locationSettings: const LocationSettings(
                              accuracy: LocationAccuracy.bestForNavigation,
                              distanceFilter:
                                  locationUpdateMinimumDistanceMeters,
                              timeLimit: Duration(seconds: 120)))
                      .listen(
                    (Position position) {
                      print(
                          "Position update after reconnect: ${position.latitude}, ${position.longitude}");
                      if (mounted) {
                        setState(() {
                          _errorMessage = '';
                          _currentPosition =
                              LatLng(position.latitude, position.longitude);

                          // Update marker
                          _markers.removeWhere((marker) =>
                              marker.markerId.value == 'currentLocation');
                          _markers.add(Marker(
                            markerId: const MarkerId('currentLocation'),
                            position: _currentPosition!,
                            infoWindow:
                                const InfoWindow(title: 'Your Location'),
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueRed),
                          ));

                          // Update route if destination is set
                          if (_destination != null) {
                            _getRoute();
                          }
                        });
                      }
                    },
                    onError: (error) {
                      print("Position stream error after reconnect: $error");
                      if (mounted) {
                        setState(() {
                          _errorMessage = 'Error tracking location: $error';
                        });
                      }
                    },
                  );
                }
              });
            }
          }
        });
      } catch (e) {
        print('Error getting location: $e');
        setState(() {
          _errorMessage = 'Error accessing location: $e';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error in determinePosition: $e');
      setState(() {
        _errorMessage = 'Error initializing location services: $e';
        _isLoading = false;
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    if (!_controller.isCompleted) {
      _controller.complete(controller);
      setState(() {
        _isMapCreated = true;
      });

      // Move to current location after map is created
      if (_currentPosition != null) {
        controller.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentPosition!,
            zoom: 15.0,
          ),
        ));
      }
    }
  }

  void _onTap(LatLng tappedPoint) {
    setState(() {
      _destination = tappedPoint;
      // Remove previous destination marker if exists
      _markers.removeWhere((marker) => marker.markerId.value == 'destination');

      _markers.add(Marker(
        markerId: const MarkerId('destination'),
        position: _destination!,
        infoWindow: const InfoWindow(title: 'Destination'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ));
    });
    _getRoute();
  }

  Future<void> _getRoute() async {
    if (_currentPosition == null || _destination == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Use Google Directions API directly
      final String apiKey = googleMapsApiKey;
      final String baseUrl =
          'https://maps.googleapis.com/maps/api/directions/json';

      print('Requesting directions using key: ${apiKey.substring(0, 5)}...');

      final Uri requestUri = Uri.parse(
          '$baseUrl?origin=${_currentPosition!.latitude},${_currentPosition!.longitude}'
          '&destination=${_destination!.latitude},${_destination!.longitude}'
          '&mode=driving'
          '&key=$apiKey');

      print(
          'Making request to Directions API: ${requestUri.toString().replaceAll(apiKey, 'AIzaSyD-SrXNRibNUlS9eZVbihFjx0bcdIMP06E')}');

      final response = await http.get(requestUri).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Directions API request timed out');
        },
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        var data = json.decode(response.body);

        if (data['status'] == 'OK') {
          _polylineCoordinates.clear();

          // Decode polyline
          List<PointLatLng> points = PolylinePoints()
              .decodePolyline(data['routes'][0]['overview_polyline']['points']);

          for (var point in points) {
            _polylineCoordinates.add(LatLng(point.latitude, point.longitude));
          }

          setState(() {
            _polylines.clear();
            _polylines.add(Polyline(
              polylineId: const PolylineId("route"),
              color: Colors.blue,
              width: 5,
              points: _polylineCoordinates,
            ));

            // Extract distance and duration from response
            if (data['routes'].isNotEmpty &&
                data['routes'][0]['legs'].isNotEmpty) {
              _distance = data['routes'][0]['legs'][0]['distance']['text'];
              _duration = data['routes'][0]['legs'][0]['duration']['text'];
            }
          });
        } else {
          print('Directions API returned status: ${data['status']}');
          String errorMessage = 'Directions request failed: ${data['status']}';

          // Provide more specific error messages based on status
          switch (data['status']) {
            case 'INVALID_REQUEST':
              errorMessage =
                  'Invalid request to Directions API. Please try again.';
              break;
            case 'OVER_QUERY_LIMIT':
              errorMessage =
                  'Direction service quota exceeded. Please try again later.';
              break;
            case 'REQUEST_DENIED':
              errorMessage =
                  'Direction service access denied. API key may be invalid or restricted.';
              break;
            case 'ZERO_RESULTS':
              errorMessage =
                  'No route found between these points. Try different locations.';
              break;
            case 'UNKNOWN_ERROR':
              errorMessage = 'Server error occurred. Please try again later.';
              break;
          }

          setState(() {
            _errorMessage = errorMessage;
          });

          print(
              'Directions API error details: ${data['error_message'] ?? 'No detailed error message'}');
        }
      } else {
        print('HTTP Error: ${response.statusCode}, Body: ${response.body}');
        setState(() {
          _errorMessage =
              'Error getting directions: ${response.statusCode} ${response.reasonPhrase}';
        });
      }
    } catch (e) {
      print('Exception getting route: $e');
      setState(() {
        _errorMessage = 'Error getting route: $e';
        _isLoading = false;
      });
    }
  }

  void _goToCurrentLocation() async {
    if (_isMapCreated && _currentPosition != null) {
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _currentPosition!,
          zoom: 15.0,
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _currentPosition == null && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition ?? const LatLng(0, 0),
                    zoom: 15,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  markers: _markers,
                  polylines: _polylines,
                  onTap: _onTap,
                  zoomControlsEnabled: false,
                ),

                // Instructions
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.black.withOpacity(0.7)
                          : Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                    child: Text(
                      'Tap anywhere on the map to set a destination',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),

                // Custom buttons
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingActionButton(
                        heroTag: "btn_my_location",
                        mini: true,
                        backgroundColor:
                            isDarkMode ? Colors.grey[800] : Colors.white,
                        foregroundColor:
                            isDarkMode ? Colors.white : Colors.black87,
                        onPressed: _goToCurrentLocation,
                        child: const Icon(Icons.my_location),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton(
                        heroTag: "btn_zoom_in",
                        mini: true,
                        backgroundColor:
                            isDarkMode ? Colors.grey[800] : Colors.white,
                        foregroundColor:
                            isDarkMode ? Colors.white : Colors.black87,
                        onPressed: () async {
                          final GoogleMapController controller =
                              await _controller.future;
                          controller.animateCamera(CameraUpdate.zoomIn());
                        },
                        child: const Icon(Icons.add),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton(
                        heroTag: "btn_zoom_out",
                        mini: true,
                        backgroundColor:
                            isDarkMode ? Colors.grey[800] : Colors.white,
                        foregroundColor:
                            isDarkMode ? Colors.white : Colors.black87,
                        onPressed: () async {
                          final GoogleMapController controller =
                              await _controller.future;
                          controller.animateCamera(CameraUpdate.zoomOut());
                        },
                        child: const Icon(Icons.remove),
                      ),
                    ],
                  ),
                ),

                // Trip info
                if (_distance.isNotEmpty && _duration.isNotEmpty)
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 100,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.black.withOpacity(0.7)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(blurRadius: 10, color: Colors.black26)
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Distance: $_distance",
                              style: TextStyle(
                                fontSize: 16,
                                color:
                                    isDarkMode ? Colors.white : Colors.black87,
                              )),
                          Text("Duration: $_duration",
                              style: TextStyle(
                                fontSize: 16,
                                color:
                                    isDarkMode ? Colors.white : Colors.black87,
                              )),
                        ],
                      ),
                    ),
                  ),

                // Loading indicator
                if (_isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),

                // Error message
                if (_errorMessage.isNotEmpty)
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _MapScreen extends StatelessWidget {
  const _MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Navigation App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MapScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

@override
State<MapScreen> createState() => _MapScreenState();

class MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();

  LatLng? _currentPosition;
  LatLng? _destination;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final List<LatLng> _polylineCoordinates = [];

  String _distance = '';
  String _duration = '';

  StreamSubscription<Position>? _positionStream;
  bool _isMapCreated = false;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      bool serviceEnabled;
      LocationPermission permission;

      // Check if location services are enabled
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage =
              'Location services are disabled. Please enable location services in your device settings.';
          _isLoading = false;
        });
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _isLoading = true;
          _errorMessage = 'Requesting location permission...';
        });

        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage =
                'Location permissions denied. Maps require location access to show your position.';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage =
              'Location permissions permanently denied. Please enable them in app settings to use navigation features.';
          _isLoading = false;
        });
        return;
      }

      try {
        print("Getting current position...");
        // Get the current position with higher accuracy but with longer timeout
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.bestForNavigation,
            timeLimit:
                const Duration(seconds: 60), // Increased from 30 to 60 seconds
            forceAndroidLocationManager: false);

        print("Position obtained: ${position.latitude}, ${position.longitude}");

        if (mounted) {
          setState(() {
            _currentPosition = LatLng(position.latitude, position.longitude);
            _markers.add(Marker(
              markerId: const MarkerId('currentLocation'),
              position: _currentPosition!,
              infoWindow: const InfoWindow(title: 'Your Location'),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed),
            ));
            _isLoading = false;
          });

          // Move camera to current position if map is already created
          if (_isMapCreated) {
            final GoogleMapController controller = await _controller.future;
            controller.animateCamera(CameraUpdate.newCameraPosition(
              CameraPosition(
                target: _currentPosition!,
                zoom: 15.0,
              ),
            ));
          }
        }

        // Listen to position updates with higher accuracy and longer timeout
        _positionStream = Geolocator.getPositionStream(
                locationSettings: const LocationSettings(
                    accuracy: LocationAccuracy.bestForNavigation,
                    distanceFilter: locationUpdateMinimumDistanceMeters,
                    timeLimit: Duration(seconds: 60)))
            .listen((Position position) {
          print("Position update: ${position.latitude}, ${position.longitude}");
          if (mounted) {
            setState(() {
              _currentPosition = LatLng(position.latitude, position.longitude);

              // Update current location marker
              _markers.removeWhere(
                  (marker) => marker.markerId.value == 'currentLocation');
              _markers.add(Marker(
                markerId: const MarkerId('currentLocation'),
                position: _currentPosition!,
                infoWindow: const InfoWindow(title: 'Your Location'),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed),
              ));

              // Update route if destination is set
              if (_destination != null) {
                _getRoute();
              }
            });
          }
        }, onError: (error) {
          print("Position stream error: $error");
          setState(() {
            _errorMessage = 'Error tracking location: $error';
          });

          // If we got a timeout error, try to restart location tracking
          if (error is TimeoutException) {
            // Restart position stream with even longer timeout
            _positionStream?.cancel();

            // Only try to restart if mounted
            if (mounted) {
              Future.delayed(Duration(seconds: 3), () {
                if (mounted) {
                  // Clear error message
                  setState(() {
                    _errorMessage = 'Reconnecting to location service...';
                  });

                  // Restart position stream
                  _positionStream = Geolocator.getPositionStream(
                          locationSettings: const LocationSettings(
                              accuracy: LocationAccuracy.bestForNavigation,
                              distanceFilter:
                                  locationUpdateMinimumDistanceMeters,
                              timeLimit: Duration(seconds: 120)))
                      .listen(
                    (Position position) {
                      print(
                          "Position update after reconnect: ${position.latitude}, ${position.longitude}");
                      if (mounted) {
                        setState(() {
                          _errorMessage = '';
                          _currentPosition =
                              LatLng(position.latitude, position.longitude);

                          // Update marker
                          _markers.removeWhere((marker) =>
                              marker.markerId.value == 'currentLocation');
                          _markers.add(Marker(
                            markerId: const MarkerId('currentLocation'),
                            position: _currentPosition!,
                            infoWindow:
                                const InfoWindow(title: 'Your Location'),
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueRed),
                          ));

                          // Update route if destination is set
                          if (_destination != null) {
                            _getRoute();
                          }
                        });
                      }
                    },
                    onError: (error) {
                      print("Position stream error after reconnect: $error");
                      if (mounted) {
                        setState(() {
                          _errorMessage = 'Error tracking location: $error';
                        });
                      }
                    },
                  );
                }
              });
            }
          }
        });
      } catch (e) {
        print('Error getting location: $e');
        setState(() {
          _errorMessage = 'Error accessing location: $e';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error in determinePosition: $e');
      setState(() {
        _errorMessage = 'Error initializing location services: $e';
        _isLoading = false;
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    if (!_controller.isCompleted) {
      _controller.complete(controller);
      setState(() {
        _isMapCreated = true;
      });

      // Move to current location after map is created
      if (_currentPosition != null) {
        controller.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentPosition!,
            zoom: 15.0,
          ),
        ));
      }
    }
  }

  void _onTap(LatLng tappedPoint) {
    setState(() {
      _destination = tappedPoint;
      // Remove previous destination marker if exists
      _markers.removeWhere((marker) => marker.markerId.value == 'destination');

      _markers.add(Marker(
        markerId: const MarkerId('destination'),
        position: _destination!,
        infoWindow: const InfoWindow(title: 'Destination'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ));
    });
    _getRoute();
  }

  Future<void> _getRoute() async {
    if (_currentPosition == null || _destination == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Use Google Directions API directly
      final String apiKey = googleMapsApiKey;
      final String baseUrl =
          'https://maps.googleapis.com/maps/api/directions/json';

      print('Requesting directions using key: ${apiKey.substring(0, 5)}...');

      final Uri requestUri = Uri.parse(
          '$baseUrl?origin=${_currentPosition!.latitude},${_currentPosition!.longitude}'
          '&destination=${_destination!.latitude},${_destination!.longitude}'
          '&mode=driving'
          '&key=$apiKey');

      print(
          'Making request to Directions API: ${requestUri.toString().replaceAll(apiKey, 'AIzaSyD-SrXNRibNUlS9eZVbihFjx0bcdIMP06E')}');

      final response = await http.get(requestUri).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Directions API request timed out');
        },
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        var data = json.decode(response.body);

        if (data['status'] == 'OK') {
          _polylineCoordinates.clear();

          // Decode polyline
          List<PointLatLng> points = PolylinePoints()
              .decodePolyline(data['routes'][0]['overview_polyline']['points']);

          for (var point in points) {
            _polylineCoordinates.add(LatLng(point.latitude, point.longitude));
          }

          setState(() {
            _polylines.clear();
            _polylines.add(Polyline(
              polylineId: const PolylineId("route"),
              color: Colors.blue,
              width: 5,
              points: _polylineCoordinates,
            ));

            // Extract distance and duration from response
            if (data['routes'].isNotEmpty &&
                data['routes'][0]['legs'].isNotEmpty) {
              _distance = data['routes'][0]['legs'][0]['distance']['text'];
              _duration = data['routes'][0]['legs'][0]['duration']['text'];
            }
          });
        } else {
          print('Directions API returned status: ${data['status']}');
          String errorMessage = 'Directions request failed: ${data['status']}';

          // Provide more specific error messages based on status
          switch (data['status']) {
            case 'INVALID_REQUEST':
              errorMessage =
                  'Invalid request to Directions API. Please try again.';
              break;
            case 'OVER_QUERY_LIMIT':
              errorMessage =
                  'Direction service quota exceeded. Please try again later.';
              break;
            case 'REQUEST_DENIED':
              errorMessage =
                  'Direction service access denied. API key may be invalid or restricted.';
              break;
            case 'ZERO_RESULTS':
              errorMessage =
                  'No route found between these points. Try different locations.';
              break;
            case 'UNKNOWN_ERROR':
              errorMessage = 'Server error occurred. Please try again later.';
              break;
          }

          setState(() {
            _errorMessage = errorMessage;
          });

          print(
              'Directions API error details: ${data['error_message'] ?? 'No detailed error message'}');
        }
      } else {
        print('HTTP Error: ${response.statusCode}, Body: ${response.body}');
        setState(() {
          _errorMessage =
              'Error getting directions: ${response.statusCode} ${response.reasonPhrase}';
        });
      }
    } catch (e) {
      print('Exception getting route: $e');
      setState(() {
        _errorMessage = 'Error getting route: $e';
        _isLoading = false;
      });
    }
  }

  void _goToCurrentLocation() async {
    if (_isMapCreated && _currentPosition != null) {
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _currentPosition!,
          zoom: 15.0,
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _currentPosition == null && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition ?? const LatLng(0, 0),
                    zoom: 15,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  markers: _markers,
                  polylines: _polylines,
                  onTap: _onTap,
                  zoomControlsEnabled: false,
                ),

                // Instructions
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.black.withOpacity(0.7)
                          : Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                    child: Text(
                      'Tap anywhere on the map to set a destination',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),

                // Custom buttons
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingActionButton(
                        heroTag: "btn_my_location",
                        mini: true,
                        backgroundColor:
                            isDarkMode ? Colors.grey[800] : Colors.white,
                        foregroundColor:
                            isDarkMode ? Colors.white : Colors.black87,
                        onPressed: _goToCurrentLocation,
                        child: const Icon(Icons.my_location),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton(
                        heroTag: "btn_zoom_in",
                        mini: true,
                        backgroundColor:
                            isDarkMode ? Colors.grey[800] : Colors.white,
                        foregroundColor:
                            isDarkMode ? Colors.white : Colors.black87,
                        onPressed: () async {
                          final GoogleMapController controller =
                              await _controller.future;
                          controller.animateCamera(CameraUpdate.zoomIn());
                        },
                        child: const Icon(Icons.add),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton(
                        heroTag: "btn_zoom_out",
                        mini: true,
                        backgroundColor:
                            isDarkMode ? Colors.grey[800] : Colors.white,
                        foregroundColor:
                            isDarkMode ? Colors.white : Colors.black87,
                        onPressed: () async {
                          final GoogleMapController controller =
                              await _controller.future;
                          controller.animateCamera(CameraUpdate.zoomOut());
                        },
                        child: const Icon(Icons.remove),
                      ),
                    ],
                  ),
                ),

                // Trip info
                if (_distance.isNotEmpty && _duration.isNotEmpty)
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 100,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.black.withOpacity(0.7)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(blurRadius: 10, color: Colors.black26)
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Distance: $_distance",
                              style: TextStyle(
                                fontSize: 16,
                                color:
                                    isDarkMode ? Colors.white : Colors.black87,
                              )),
                          Text("Duration: $_duration",
                              style: TextStyle(
                                fontSize: 16,
                                color:
                                    isDarkMode ? Colors.white : Colors.black87,
                              )),
                        ],
                      ),
                    ),
                  ),

                // Loading indicator
                if (_isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),

                // Error message
                if (_errorMessage.isNotEmpty)
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
