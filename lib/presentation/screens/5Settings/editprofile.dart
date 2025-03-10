import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:velora/core/configs/theme/app_fonts.dart';
import 'package:velora/presentation/widgets/reusable_wdgts.dart';

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
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: MyAppBar(
        title: "Edit Profile",
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 30),
                        Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primary,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.2),
                                    blurRadius: 5,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 75,
                                backgroundColor: Colors.grey[200],
                                backgroundImage: _getProfileImage(),
                                child: _getProfileImage() == null
                                    ? Icon(Icons.person,
                                        size: 70, color: Colors.grey[400])
                                    : null,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                height: 40,
                                width: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.camera_alt,
                                      size: 20, color: Colors.white),
                                  onPressed: () => _pickImage(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(26.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "Personal Information",
                              style: AppFonts.bold.copyWith(
                                fontSize: 18,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildInputField(
                          "Name",
                          _nameController,
                          "Enter your name",
                          Icons.person_outline,
                        ),
                        const SizedBox(height: 24),
                        _buildInputField(
                          "Bio",
                          _bioController,
                          "Write something about yourself",
                          Icons.description_outlined,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 36),
                        Center(
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.7,
                            child: CustomButton(
                              text: "Save Changes",
                              onPressed: _handleUpdateProfile,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    String hint,
    IconData icon, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppFonts.semibold.copyWith(
            fontSize: 16,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            style: AppFonts.regular.copyWith(fontSize: 16),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppFonts.regular.copyWith(
                fontSize: 16,
                color: Colors.grey[400],
              ),
              prefixIcon: Icon(icon, color: AppColors.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.transparent),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.transparent),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: maxLines > 1 ? 16 : 0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showToast(String message, IconData icon, Color color) {
    DelightToastBar(
      builder: (context) => ToastCard(
        title: Text('Notification',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        leading: Icon(icon, color: color),
        subtitle: Text(message, style: const TextStyle(fontSize: 14)),
      ),
      position: DelightSnackbarPosition.top,
      autoDismiss: true,
      snackbarDuration: Durations.extralong4,
    ).show(context);
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    final Map<String, dynamic>? args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      setState(() {
        _originalName = args['name'] ?? '';
        _originalBio = args['bio'] ?? '';
        _profileImageUrl = args['profileUrl'];
        _nameController.text = _originalName!;
        _bioController.text = _originalBio!;
        _isLoading = false;
      });
      return;
    }

    User? user = _auth.currentUser;
    if (user != null) {
      try {
        _profileImageUrl = user.photoURL;
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _originalName = data['userName'] ?? '';
            _originalBio = data['bio'] ?? '';
            if (data['profileUrl'] != null) {
              _profileImageUrl = data['profileUrl'];
            }
            _nameController.text = _originalName!;
            _bioController.text = _originalBio!;
          });
        }
      } catch (e) {
        _showToast("Error loading user data: $e", Icons.error, Colors.red);
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _updateProfile() async {
    String newName = _nameController.text.trim();
    String newBio = _bioController.text.trim();

    if (newName.isEmpty || newBio.isEmpty) {
      _showToast("Fields cannot be empty!", Icons.warning, Colors.orange);
      return;
    }

    if (newName == _originalName && newBio == _originalBio && !_imageChanged) {
      _showToast("Nothing changed", Icons.info, Colors.blue);
      return;
    }

    setState(() => _isLoading = true);

    try {
      User? user = _auth.currentUser;
      if (user == null) throw Exception("User not found");

      if (_imageChanged && _imageFile != null) {
        final storageRef =
            FirebaseStorage.instance.ref().child('user_images/${user.uid}');
        final uploadTask = storageRef.putFile(_imageFile!);
        final snapshot = await uploadTask;
        _profileImageUrl = await snapshot.ref.getDownloadURL();
        await user.updatePhotoURL(_profileImageUrl);
      }

      await _firestore.collection('users').doc(user.uid).update({
        'userName': newName,
        'bio': newBio,
        'profileUrl': _profileImageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _originalName = newName;
        _originalBio = newBio;
        _imageChanged = false;
      });

      _showToast(
          "Profile updated successfully!", Icons.check_circle, Colors.green);
      Navigator.pop(context, {
        'updated': true,
        'name': newName,
        'bio': newBio,
        'profileUrl': _profileImageUrl
      });
    } catch (e) {
      _showToast("Error updating profile: $e", Icons.error, Colors.red);
    }

    setState(() => _isLoading = false);
  }

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

  ImageProvider? _getProfileImage() {
    if (_imageFile != null) {
      return FileImage(_imageFile!);
    } else if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      return NetworkImage(_profileImageUrl!);
    }
    return null;
  }

  void _handleUpdateProfile() {
    if (!_isLoading) {
      _updateProfile();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}
