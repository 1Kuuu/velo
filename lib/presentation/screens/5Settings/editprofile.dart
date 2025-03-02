import 'package:cloud_firestore/cloud_firestore.dart';
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
  String? _profileImageUrl; // To hold the user's profile image URL

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
        // Fetch the user's profile image from FirebaseAuth
        _profileImageUrl = user.photoURL;

        // Fetch additional user data (name and bio) from Firestore
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          setState(() {
            _nameController.text = userDoc['name'] ?? '';
            _bioController.text = userDoc['bio'] ?? '';
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error loading user data: $e")));
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _updateProfile() async {
    setState(() {
      _isLoading = true;
    });

    User? user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'name': _nameController.text.trim(),
          'bio': _bioController.text.trim(),
        }, SetOptions(merge: true));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully!")),
        );

        Navigator.pop(context, {
          'name': _nameController.text.trim(),
          'bio': _bioController.text.trim(),
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error updating profile: $e")));
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: MyAppBar(title: "Edit Profile"),  // Use MyAppBar instead of the default AppBar
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Profile Picture Section
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey[300],
            backgroundImage: _profileImageUrl != null
                ? NetworkImage(_profileImageUrl!)
                : const AssetImage("assets/profile.jpg") as ImageProvider,
            child: _profileImageUrl == null
                ? const Icon(Icons.account_circle, size: 50, color: Colors.black54)
                : null,
          ),
          const SizedBox(height: 30),
          _buildTextField("Name", _nameController),  // Your reusable _buildTextField widget
          const SizedBox(height: 16),
          _buildTextField("Bio", _bioController),   // Your reusable _buildTextField widget
          const SizedBox(height: 20),
          _isLoading
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4d1c1c),  // Background color of the button
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    "Save Changes",
                    style: TextStyle(
                      fontFamily: 'Poppins', // Apply Poppins font to the button text
                      fontSize: 12,
                      color: Colors.white, // Text color set to white
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
    padding: const EdgeInsets.only(bottom: 2), // Add bottom padding between text fields
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, // Align label to the left
      children: [
        // Label positioned at the top-left of the text field
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins', // Use Poppins font for the label
            color: Colors.black,   // Label text color
            fontWeight: FontWeight.w600, // Bold label text for visibility
            fontSize: 14,          // Label font size
          ),
        ),
        const SizedBox(height: 8), // Add a small space between the label and text field
        // TextField
        TextField(
          controller: controller,
          maxLines: label == "Bio" ? 3 : 1,
          style: const TextStyle(
            fontFamily: 'Poppins', // Apply Poppins font for text inside the box
            color: Color.fromARGB(255, 255, 255, 255),   // Text color inside the box
            fontSize: 14,          // Font size for input text
          ),
          decoration: InputDecoration(
            hintText: "Enter your $label",
            hintStyle: const TextStyle(
              fontFamily: 'Poppins', // Hint text font
              color: Color.fromARGB(255, 255, 255, 255),   // Hint text color
              fontSize: 14,          // Hint text size
            ),
            filled: true,
            fillColor: const Color(0xFF4d1c1c), // Background color of the text box
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16), // Padding inside the text box
          ),
        ),
      ],
    ),
  );
}


}
