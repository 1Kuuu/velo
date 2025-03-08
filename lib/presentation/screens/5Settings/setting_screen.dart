import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:velora/presentation/screens/0Auth/login.dart';
import 'package:velora/presentation/screens/5Settings/editprofile.dart';
import 'package:velora/presentation/widgets/widgets.dart'; // Import the extracted widgets

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isDarkMode = false;
  bool isNotificationsEnabled = true; // Notification toggle state
  final User? user = FirebaseAuth.instance.currentUser;

  String displayName = "Loading...";
  String bio = "Loading...";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user != null) {
      setState(() {
        displayName = user?.displayName ?? "User Name";
        bio = user?.email ?? "No bio available";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Settings"),
          backgroundColor: AppColors.primary,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text("Settings",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: Column(
        children: [
          buildProfileSection(),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                children: [
                  const SizedBox(height: 20),
                  buildSectionTitle("Content"),
                  buildListTile(
                    icon: Icons.bookmark_border,
                    title: "Saved",
                    onTap: () {
                      // Navigate to Saved Page
                      Navigator.pushNamed(context, '/saved');
                    },
                  ),
                  buildToggleTile(
                    title: "Dark Mode",
                    value: isDarkMode,
                    onChanged: (value) {
                      setState(() {
                        isDarkMode = value;
                      });
                    },
                    icon: Icons.dark_mode_outlined,
                  ),
                  buildToggleTile(
                    title: "Notification",
                    value: isNotificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        isNotificationsEnabled = value;
                      });
                    },
                    icon: Icons.notifications_none,
                  ),
                  const SizedBox(height: 10),
                  buildSectionTitle("General"),
                  buildListTile(
                    icon: Icons.language,
                    title: "Language",
                    trailingText: "English",
                    onTap: () {
                      Navigator.pushNamed(context, '/language');
                    },
                  ),
                  buildListTile(
                    icon: Icons.help_outline,
                    title: "Help & Support",
                    onTap: () {
                      Navigator.pushNamed(context, '/help_support');
                    },
                  ),
                  buildListTile(
                    icon: Icons.description_outlined,
                    title: "Terms & Conditions",
                    onTap: () {
                      Navigator.pushNamed(context, '/terms_conditions');
                    },
                  ),
                  buildListTile(
                    icon: Icons.info_outline,
                    title: "About",
                    onTap: () {
                      Navigator.pushNamed(context, '/about');
                    },
                  ),
                  buildListTile(
                    icon: Icons.logout,
                    title: "Logout",
                    onTap: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove(
                          'hasCompletedOnboarding'); // Clear onboarding flag

                      await FirebaseAuth.instance.signOut();

                      // Ensure auth state change is processed
                      await Future.delayed(Duration(milliseconds: 500));

                      if (mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginPage()),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Profile Section
  Widget buildProfileSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: user?.photoURL != null
                ? NetworkImage(user!.photoURL!)
                : const AssetImage("assets/profile.jpg") as ImageProvider,
          ),
          const SizedBox(height: 10),
          Text(
            displayName,
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            user?.email ?? "@luceroindie17",
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 5),
          Text(bio,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () async {
              final updatedUser = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const EditProfileScreen()),
              );

              if (updatedUser != null && updatedUser is Map<String, String>) {
                setState(() {
                  displayName = updatedUser['name'] ?? "User Name";
                  bio = updatedUser['bio'] ?? "No bio available";
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text("Edit Profile",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
