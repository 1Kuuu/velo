import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
  String? _originalName;
  String? _originalBio;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    User? user = _auth.currentUser;
    if (user != null) {
      try {
        _profileImageUrl = user.photoURL;

        DocumentSnapshot userDoc =
            await _firestore.collection('user_profile').doc(user.uid).get();
        if (userDoc.exists) {
          setState(() {
            _originalName = userDoc['name'] ?? '';
            _originalBio = userDoc['bio'] ?? '';
            _nameController.text = _originalName!;
            _bioController.text = _originalBio!;
          });
        }
      } catch (e) {
        _showToast("Error loading user data: $e", Icons.error, Colors.red);
      }
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

    if (newName == _originalName && newBio == _originalBio) {
      _showToast("Nothing changed  ¯\\_(ツ)_/¯", Icons.sentiment_satisfied,
          Colors.blue);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    User? user = _auth.currentUser;
    if (user == null) {
      _showToast("User not found. Please re-login.", Icons.error, Colors.red);
      return;
    }

    try {
      await _firestore.collection('user_profile').doc(user.uid).set(
        {'name': newName, 'bio': newBio},
        SetOptions(merge: true),
      );

      _showToast(
          "Profile updated successfully!", Icons.check_circle, Colors.green);

      setState(() {
        _originalName = newName;
        _originalBio = newBio;
      });

      Navigator.pop(context, {'name': newName, 'bio': newBio});
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(title: "Edit Profile"),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[300],
              backgroundImage: _profileImageUrl != null
                  ? NetworkImage(_profileImageUrl!)
                  : const AssetImage("assets/profile.jpg") as ImageProvider,
              child: _profileImageUrl == null
                  ? const Icon(Icons.account_circle,
                      size: 50, color: Colors.black54)
                  : null,
            ),
            const SizedBox(height: 30),
            _buildTextField("Name", _nameController),
            const SizedBox(height: 16),
            _buildTextField("Bio", _bioController),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4d1c1c),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text(
                      "Save Changes",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: label == "Bio" ? 3 : 1,
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: Colors.white,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: "Enter your $label",
              hintStyle: const TextStyle(
                fontFamily: 'Poppins',
                color: Colors.white,
                fontSize: 14,
              ),
              filled: true,
              fillColor: const Color(0xFF4d1c1c),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            ),
          ),
        ],
      ),
    );
  }
}
