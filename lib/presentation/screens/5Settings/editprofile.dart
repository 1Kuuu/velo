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
            await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          setState(() {
            _originalName = userDoc['name'] ?? '';
            _originalBio = userDoc['bio'] ?? '';
            _nameController.text = _originalName!;
            _bioController.text = _originalBio!;
          });
        }
      } catch (e) {
        DelightToastBar(
          builder: (context) {
            return ToastCard(
              title: const Text('Error'),
              leading: Icon(Icons.error, color: Colors.red),
              subtitle: Text("Error loading user data: $e"),
            );
          },
          position: DelightSnackbarPosition.top,
          autoDismiss: true,
          snackbarDuration: Durations.extralong4,
        ).show(context);
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
      DelightToastBar(
        builder: (context) {
          return ToastCard(
            title: const Text('Error'),
            leading: Icon(Icons.warning, color: Colors.orange),
            subtitle: const Text("Fields cannot be empty!"),
          );
        },
        position: DelightSnackbarPosition.top,
        autoDismiss: true,
        snackbarDuration: Durations.extralong4,
      ).show(context);
      return;
    }

    if (newName == _originalName && newBio == _originalBio) {
      DelightToastBar(
        builder: (context) {
          return ToastCard(
            title: const Text('Nothing Changed'),
            leading: Icon(Icons.sentiment_satisfied, color: Colors.blue),
            subtitle: const Text("Nothing changed  ¯\\_(ツ)_/¯"),
          );
        },
        position: DelightSnackbarPosition.top,
        autoDismiss: true,
        snackbarDuration: Durations.extralong4,
      ).show(context);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _firestore.collection('users').doc(_auth.currentUser!.uid).set({
        'name': newName,
        'bio': newBio,
      }, SetOptions(merge: true));

      DelightToastBar(
        builder: (context) {
          return ToastCard(
            title: const Text('Success'),
            leading: Icon(Icons.check_circle, color: Colors.green),
            subtitle: const Text("Profile updated successfully!"),
          );
        },
        position: DelightSnackbarPosition.top,
        autoDismiss: true,
        snackbarDuration: Durations.extralong4,
      ).show(context);

      Navigator.pop(context, {'name': newName, 'bio': newBio});
    } catch (e) {
      DelightToastBar(
        builder: (context) {
          return ToastCard(
            title: const Text('Error'),
            leading: Icon(Icons.error, color: Colors.red),
            subtitle: Text("Error updating profile: $e"),
          );
        },
        position: DelightSnackbarPosition.top,
        autoDismiss: true,
        snackbarDuration: Durations.extralong4,
      ).show(context);
    }

    setState(() {
      _isLoading = false;
    });
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
