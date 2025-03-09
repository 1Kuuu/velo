import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  bool _isLoading = false;
  String? _profileImageUrl;
  File? _imageFile;
  String? _originalName;
  String? _originalBio;
  bool _imageChanged = false;

  // For image picker
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Delay loading to ensure the context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    // Try to get data from arguments first
    final Map<String, dynamic>? args = 
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    if (args != null) {
      // Use data passed from ProfilePage
      setState(() {
        _originalName = args['name'] ?? '';
        _originalBio = args['bio'] ?? '';
        _profileImageUrl = args['profileUrl']; // Use the correct field name
        _nameController.text = _originalName!;
        _bioController.text = _originalBio!;
      });
      
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Fallback to fetching data if no arguments provided
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        // Fetch profile image from FirebaseAuth
        _profileImageUrl = user.photoURL;

        // Fetch name & bio from Firestore
        DocumentSnapshot userDoc = await _firestore.collection('user_profile').doc(user.uid).get();
        if (userDoc.exists) {
          Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _originalName = data['name'] ?? '';
            _originalBio = data['bio'] ?? '';
            // If profileUrl exists in Firestore, prefer it over photoURL
            if (data['profileUrl'] != null) {
              _profileImageUrl = data['profileUrl'];
            }
            _nameController.text = _originalName!;
            _bioController.text = _originalBio!;
          });
        } else {
          print("❌ No user profile data found in Firestore.");
        }
      } catch (e) {
        _showToast("Error loading user data: $e", Icons.error, Colors.red);
      }
    } else {
      print("❌ No authenticated user found.");
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _updateProfile() async {
    String newName = _nameController.text.trim();
    String newBio = _bioController.text.trim();

    if (newName.isEmpty || newBio.isEmpty) {
      _showToast("Fields cannot be empty!", Icons.warning, Colors.orange);
      return;
    }

    if (newName == _originalName && newBio == _originalBio && !_imageChanged) {
      _showToast("Nothing changed  ¯\\_(ツ)_/¯", Icons.sentiment_satisfied, Colors.blue);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    User? user = _auth.currentUser;
    if (user == null) {
      _showToast("User not found. Please re-login.", Icons.error, Colors.red);
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // Upload image if changed
      if (_imageChanged && _imageFile != null) {
        final storageReference = FirebaseStorage.instance.ref().child('user_images/${user.uid}');
        final uploadTask = storageReference.putFile(_imageFile!);
        
        // Wait for the upload to complete
        final TaskSnapshot taskSnapshot = await uploadTask;
        
        // Get the download URL
        final String downloadUrl = await taskSnapshot.ref.getDownloadURL();
        
        // Update profile image URL
        _profileImageUrl = downloadUrl;
        
        // Update Firebase Auth profile photo
        await user.updatePhotoURL(downloadUrl);
      }

      // Make sure we use consistent field names with ProfilePage
      await _firestore.collection('user_profile').doc(user.uid).set(
        {
          'name': newName,
          'userName': newName, // Update both fields for compatibility
          'bio': newBio,
          'profileUrl': _profileImageUrl, // Use profileUrl to match ProfilePage
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      _showToast("Profile updated successfully!", Icons.check_circle, Colors.green);

      setState(() {
        _originalName = newName;
        _originalBio = newBio;
        _imageChanged = false;
      });

      // Return true to indicate successful update
      Navigator.pop(context, {
        'updated': true,
        'name': newName,
        'bio': newBio,
        'profileUrl': _profileImageUrl
      });
    } catch (e) {
      _showToast("Error updating profile: $e", Icons.error, Colors.red);
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _showToast(String message, IconData icon, Color color) {
    DelightToastBar(
      builder: (context) {
        return ToastCard(
          title: const Text('Notification'),
          leading: Icon(icon, color: color),
          subtitle: Text(message),
        );
      },
      position: DelightSnackbarPosition.top,
      autoDismiss: true,
      snackbarDuration: Durations.extralong4,
    ).show(context);
  }

  // Function to pick an image from the gallery or camera
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _imageChanged = true;
        });
      }
    } catch (e) {
      _showToast("Error picking image: $e", Icons.error, Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isLoading ? null : _updateProfile,
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile picture with edit option
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: _getProfileImage(),
                        child: _getProfileImage() == null 
                          ? const Icon(Icons.person, size: 60) 
                          : null,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.white),
                        onPressed: _pickImage,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Name field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Bio field
                TextFormField(
                  controller: _bioController,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 32),
                
                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateProfile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator() 
                      : const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  // Helper method to get appropriate image provider
  ImageProvider? _getProfileImage() {
    if (_imageFile != null) {
      return FileImage(_imageFile!);
    } else if (_profileImageUrl != null) {
      if (_profileImageUrl!.startsWith('http')) {
        return NetworkImage(_profileImageUrl!);
      } else {
        return FileImage(File(_profileImageUrl!));
      }
    }
    return null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}