import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:velora/data/sources/firebase_service.dart';
import 'package:velora/presentation/screens/0Auth/login.dart';
import 'package:velora/presentation/screens/5Settings/editprofile.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isDarkMode = false;
  bool isNotificationsEnabled = true;
  User? user;
  Map<String, dynamic> userData = {
    'userName': 'Loading...',
    'email': 'Loading...',
    'bio': 'Loading...',
    'profileUrl': '',
  };
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      if (mounted) {
        setState(() {
          isDarkMode = prefs.getBool('isDarkMode') ?? false;
          isNotificationsEnabled = prefs.getBool('isNotificationsEnabled') ?? true;
        });
      }
    } catch (e) {
      print("Error loading preferences: $e");
    }
  }

  Future<void> _saveUserPreferences() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', isDarkMode);
      await prefs.setBool('isNotificationsEnabled', isNotificationsEnabled);
      
      // Also save to Firebase if user is logged in
      if (FirebaseServices.currentUserId != null) {
        await FirebaseServices.updateUserData(
          FirebaseServices.currentUserId!,
          {
            'preferences': {
              'isDarkMode': isDarkMode,
              'isNotificationsEnabled': isNotificationsEnabled,
            }
          }
        );
      }
    } catch (e) {
      print("Error saving preferences: $e");
    }
  }

  Future<void> _loadUserData() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && mounted) {
        setState(() {
          user = currentUser;
          isLoading = true;
        });
        
        // Use your Firebase service to get user profile data
        Map<String, dynamic> profile = await FirebaseServices.getUserProfile();
        
        if (mounted) {
          setState(() {
            userData = profile;
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            userData = {
              'userName': 'No User Logged In',
              'email': '',
              'bio': 'Please log in to continue.',
              'profileUrl': '',
            };
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error loading user data: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
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
        title: const Text("Settings", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                      _saveUserPreferences();
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
                      _saveUserPreferences();
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
                    iconColor: Colors.red,
                    textColor: Colors.red,
                    onTap: () {
                      _showLogoutConfirmationDialog(context);
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

  Widget buildProfileSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: userData['profileUrl'] != null && userData['profileUrl'].isNotEmpty
                ? NetworkImage(userData['profileUrl'])
                : const AssetImage("assets/profile.jpg") as ImageProvider,
          ),
          const SizedBox(height: 10),
          Text(
            userData['userName'] ?? "User Name",
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            userData['email'] ?? "@luceroindie17",
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 5),
          Text(
            userData['bio'] ?? "No bio available",
            style: const TextStyle(color: Colors.white70, fontSize: 12)
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditProfileScreen()),
              );

              if (result != null && mounted) {
                // Reload user data to reflect changes
                _loadUserData();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text("Edit Profile", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "Confirm Logout",
            style: TextStyle(
              fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 18,
            ),
          ),
          content: const Text(
            "Are you sure you want to log out?",
            style: TextStyle(fontFamily: 'Poppins', fontSize: 16),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
              child: const Text(
                "No",
                style: TextStyle(
                  fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text(
                "Yes",
                style: TextStyle(
                  fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16,
                ),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('hasCompletedOnboarding');
                await FirebaseAuth.instance.signOut();
                await Future.delayed(const Duration(milliseconds: 500));
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget buildListTile({
    required IconData icon,
    required String title,
    String? trailingText,
    Color iconColor = Colors.black,
    Color textColor = Colors.black,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: TextStyle(color: textColor)),
      trailing: trailingText != null
          ? Text(trailingText, style: const TextStyle(color: Colors.grey))
          : const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget buildToggleTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(title),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }

  Widget buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}