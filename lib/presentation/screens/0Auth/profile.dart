import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatelessWidget {
  final User? user =
      FirebaseAuth.instance.currentUser;

   ProfilePage({super.key}); // Fetch the logged-in user

  @override
  Widget build(BuildContext context) {
    print("User's profile image URL: ${user?.photoURL}"); // Debugging print

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Profile",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Colors.black54),
        ),
      ),
      body: Column(
        children: [
          _buildProfileSection(),
        ],
      ),
      backgroundColor: Colors.white,
    );
  }

  Widget _buildProfileSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor:
                    Colors.grey[300], // Placeholder background color
                backgroundImage: (user?.photoURL != null &&
                        user!.photoURL!.isNotEmpty)
                    ? NetworkImage(
                        user!.photoURL!) // Fetch profile image from Firebase
                    : AssetImage("assets/profile.jpg")
                        as ImageProvider, // Default image
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    size: 18,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user?.displayName ?? "Indie Lucero",
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Manila, Caloocan, Philippines",
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
