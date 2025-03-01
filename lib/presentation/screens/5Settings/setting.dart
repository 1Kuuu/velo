import 'package:flutter/material.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:velora/presentation/screens/0Auth/login.dart';
import 'package:velora/presentation/screens/5Settings/editprofile.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text(
          "SETTINGS",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildProfileSection(),
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
                  _buildSectionTitle("Content"),
                  _buildListTile(Icons.bookmark_border, "Saved"),
                  _buildDarkModeTile(),
                  const SizedBox(height: 10),
                  _buildSectionTitle("General"),
                  _buildListTile(Icons.language, "Language",
                      trailingText: "English"),
                  _buildListTile(Icons.notifications_none, "Notification",
                      trailingText: "Enabled"),
                  _buildListTile(Icons.help_outline, "Help & Support"),
                  _buildListTile(
                      Icons.description_outlined, "Terms & Condition"),
                  _buildListTile(Icons.info_outline, "About"),
                  _buildListTile(Icons.logout, "Logout", onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginPage()),
                    );
                  }),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundImage: AssetImage("assets/profile.jpg"),
          ),
          const SizedBox(height: 10),
          const Text("Indie Lucero",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const Text("@luceroindie17",
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 5),
          const Text("Drop a gear and Disappear.",
              style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const EditProfileScreen()),
              );
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 10, bottom: 5),
      child: Text(title,
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
    );
  }

  Widget _buildListTile(IconData icon, String title,
      {String? trailingText, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: trailingText != null
          ? Text(trailingText,
              style: const TextStyle(fontSize: 14, color: Colors.grey))
          : const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildDarkModeTile() {
    return ListTile(
      leading: const Icon(Icons.dark_mode_outlined, color: Colors.black),
      title: const Text("Dark Mode", style: TextStyle(fontSize: 16)),
      trailing: Switch(
        value: isDarkMode,
        onChanged: (value) {
          setState(() {
            isDarkMode = value;
          });
        },
        activeColor: Colors.black,
      ),
    );
  }
}
