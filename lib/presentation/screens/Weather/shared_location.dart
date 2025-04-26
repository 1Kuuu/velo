import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/sources/location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'location_history_service.dart';

class SharedLocationScreen extends StatefulWidget {
  const SharedLocationScreen({Key? key}) : super(key: key);

  @override
  State<SharedLocationScreen> createState() => _SharedLocationScreenState();
}

class _SharedLocationScreenState extends State<SharedLocationScreen>
    with SingleTickerProviderStateMixin {
  final LocationHistoryService _locationService = LocationHistoryService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TabController _tabController;
  List<Map<String, dynamic>> _sharedLocations = [];
  List<Map<String, dynamic>> _locationsSharedWithMe = [];
  bool _isLoading = true;
  String _errorMessage = '';

  Future<void> _shareMyLocation() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      setState(() {
        _errorMessage = 'You need to be logged in to share your location';
      });
      return;
    }

    // Show friend selection dialog
    final friends = await _getFriendsList();
    if (friends.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('You need to add friends first to share your location')),
      );
      return;
    }

    final selectedFriends = await _showFriendSelectionDialog(friends);
    if (selectedFriends.isEmpty) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Save to Firebase
      await _locationService.saveSharedLocation(
        location: LatLng(position.latitude, position.longitude),
        locationName: 'Current Location', // Ideally use reverse geocoding
        sharedWithUserIds: selectedFriends,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location shared successfully')),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Error sharing location: $e';
        _isLoading = false;
      });
    }
  }

  Future<List<Map<String, String>>> _getFriendsList() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return [];

    try {
      final snapshot =
          await _firestore.collection('users').doc(currentUser.uid).get();

      List<Map<String, String>> friends = [];

      for (var doc in snapshot.docs) {
        final friendId = doc.data()['userId'];
        final friendDoc =
            await _firestore.collection('users').doc(friendId).get();

        if (friendDoc.exists) {
          final userData = friendDoc.data() as Map<String, dynamic>;
          friends.add({
            'id': friendId,
            'name': userData['displayName'] ?? 'Unknown User',
          });
        }
      }

      return friends;
    } catch (e) {
      print('Error getting friends list: $e');
      return [];
    }
  }

  Future<List<String>> _showFriendSelectionDialog(
      List<Map<String, String>> friends) async {
    List<String> selectedFriends = [];
    List<bool> selections = List.generate(friends.length, (_) => false);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share with friends'),
        content: Container(
          width: double.maxFinite,
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Select friends to share your location with:'),
                  const SizedBox(height: 10),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: friends.length,
                      itemBuilder: (context, index) {
                        return CheckboxListTile(
                          title: Text(friends[index]['name']!),
                          value: selections[index],
                          onChanged: (value) {
                            setState(() {
                              selections[index] = value!;
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              for (int i = 0; i < selections.length; i++) {
                if (selections[i]) {
                  selectedFriends.add(friends[i]['id']!);
                }
              }
              Navigator.pop(context);
            },
            child: const Text('SHARE'),
          ),
        ],
      ),
    );

    return selectedFriends;
  }

  void _viewLocationOnMap(Map<String, dynamic> location,
      {bool isFromFriend = false}) {
    if (location['latitude'] == null || location['longitude'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location data is not available')),
      );
      return;
    }

    String title = isFromFriend
        ? '${location['fromUserName']}\'s Location'
        : 'Your Shared Location';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          height: 300,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      location['latitude'],
                      location['longitude'],
                    ),
                    zoom: 15,
                  ),
                  markers: {
                    Marker(
                      markerId: MarkerId(location['id']),
                      position: LatLng(
                        location['latitude'],
                        location['longitude'],
                      ),
                      infoWindow: InfoWindow(
                        title: isFromFriend ? location['fromUserName'] : 'You',
                        snippet: location['locationName'],
                      ),
                    ),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'My Shared Locations'),
              Tab(text: 'Shared with Me'),
            ],
          ),
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // My shared locations tab
                      _sharedLocations.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.location_off,
                                      size: 60, color: Colors.grey),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'You haven\'t shared any locations yet',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: _shareMyLocation,
                                    icon: const Icon(Icons.share_location),
                                    label: const Text('Share My Location'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(context).primaryColor,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _sharedLocations.length,
                              itemBuilder: (context, index) {
                                final location = _sharedLocations[index];
                                final timestamp =
                                    location['timestamp'] as Timestamp;
                                final datetime =
                                    DateTime.fromMillisecondsSinceEpoch(
                                        timestamp.millisecondsSinceEpoch);

                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 8.0,
                                  ),
                                  elevation: 2,
                                  child: ListTile(
                                    leading: const CircleAvatar(
                                      backgroundColor: Colors.blue,
                                      child: Icon(Icons.location_on,
                                          color: Colors.white),
                                    ),
                                    title: Text(location['locationName']),
                                    subtitle: Text(
                                      'Shared on ${_formatDate(datetime)} • With ${(location['sharedWith'] as List).length} people',
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.map),
                                      onPressed: () =>
                                          _viewLocationOnMap(location),
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    onTap: () => _viewLocationOnMap(location),
                                  ),
                                );
                              },
                            ),

                      // Shared with me tab
                      _locationsSharedWithMe.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person_pin_circle,
                                      size: 60, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text(
                                    'No locations have been shared with you yet',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _locationsSharedWithMe.length,
                              itemBuilder: (context, index) {
                                final location = _locationsSharedWithMe[index];
                                final timestamp =
                                    location['timestamp'] as Timestamp;
                                final datetime =
                                    DateTime.fromMillisecondsSinceEpoch(
                                        timestamp.millisecondsSinceEpoch);

                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 8.0,
                                  ),
                                  elevation: 2,
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundImage:
                                          location['fromUserPhoto'].isNotEmpty
                                              ? NetworkImage(
                                                  location['fromUserPhoto'])
                                              : null,
                                      child: location['fromUserPhoto'].isEmpty
                                          ? Text(location['fromUserName'][0]
                                              .toUpperCase())
                                          : null,
                                    ),
                                    title: Text(location['fromUserName']),
                                    subtitle: Text(
                                      '${location['locationName']} • ${_formatTimeAgo(datetime)}',
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.map),
                                      onPressed: () => _viewLocationOnMap(
                                          location,
                                          isFromFriend: true),
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    onTap: () => _viewLocationOnMap(location,
                                        isFromFriend: true),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _shareMyLocation,
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.share_location),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
}

extension on DocumentSnapshot<Map<String, dynamic>> {
  get docs => null;
}
