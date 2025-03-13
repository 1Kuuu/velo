import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:velora/core/configs/theme/theme_provider.dart';
import 'package:velora/core/configs/theme/app_fonts.dart';
import 'package:velora/presentation/screens/0Auth/login.dart';
import 'package:velora/presentation/screens/5Settings/editprofile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:velora/presentation/screens/5Settings/language_screen.dart';
import 'package:velora/presentation/screens/5Settings/about_screen.dart';
import 'package:velora/presentation/screens/5Settings/terms_condition.dart';
import 'package:velora/presentation/screens/5Settings/help_support_screen.dart';
import 'package:velora/data/sources/auth_service.dart';

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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
          isNotificationsEnabled =
              prefs.getBool('isNotificationsEnabled') ?? true;
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

      // Save to Firebase if user is logged in
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await _firestore.collection('users').doc(currentUser.uid).update({
          'preferences': {
            'isDarkMode': isDarkMode,
            'isNotificationsEnabled': isNotificationsEnabled,
          }
        });
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

        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(currentUser.uid).get();

        if (userDoc.exists && mounted) {
          Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
          setState(() {
            userData = {
              'userName':
                  data['userName'] ?? currentUser.displayName ?? 'No Name',
              'email': data['email'] ?? currentUser.email ?? 'No Email',
              'bio': data['bio'] ?? 'No bio available',
              'profileUrl': data['profileUrl'] ?? currentUser.photoURL ?? '',
              'preferences': data['preferences'] ?? {},
            };

            // Update preferences if they exist in Firestore
            if (data['preferences'] != null) {
              isDarkMode = data['preferences']['isDarkMode'] ?? isDarkMode;
              isNotificationsEnabled = data['preferences']
                      ['isNotificationsEnabled'] ??
                  isNotificationsEnabled;
            }

            isLoading = false;
          });
        } else {
          // Create user document if it doesn't exist
          await _firestore.collection('users').doc(currentUser.uid).set({
            'userName': currentUser.displayName ?? 'No Name',
            'email': currentUser.email ?? 'No Email',
            'bio': 'No bio available',
            'profileUrl': currentUser.photoURL ?? '',
            'preferences': {
              'isDarkMode': isDarkMode,
              'isNotificationsEnabled': isNotificationsEnabled,
            },
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          if (mounted) {
            setState(() {
              userData = {
                'userName': currentUser.displayName ?? 'No Name',
                'email': currentUser.email ?? 'No Email',
                'bio': 'No bio available',
                'profileUrl': currentUser.photoURL ?? '',
              };
              isLoading = false;
            });
          }
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
    final themeProvider = Provider.of<ThemeProvider>(context);

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Settings",
              style: AppFonts.bold.copyWith(color: Colors.white)),
          backgroundColor: themeProvider.isDarkMode
              ? const Color(0xFF4A3B7C)
              : AppColors.primary,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: themeProvider.isDarkMode
          ? const Color(0xFF121212)
          : AppColors.primary,
      appBar: AppBar(
        title: Text("Settings",
            style: AppFonts.bold.copyWith(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          buildProfileSection(),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: themeProvider.isDarkMode
                    ? const Color(0xFF1E1E1E)
                    : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
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
                    value: themeProvider.isDarkMode,
                    onChanged: (value) async {
                      await themeProvider.toggleTheme();
                      setState(() {
                        isDarkMode = themeProvider.isDarkMode;
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => LanguageScreen()),
                      );
                    },
                  ),
                  buildListTile(
                    icon: Icons.help_outline,
                    title: "Help & Support",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const HelpSupportScreen()),
                      );
                    },
                  ),
                  buildListTile(
                    icon: Icons.info_outline,
                    title: "Terms & Condition",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const TermsConditionScreen()),
                      );
                    },
                  ),
                  buildListTile(
                    icon: Icons.info_outline,
                    title: "About",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AboutScreen()),
                      );
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _getProfileImage(),
                  child: _getProfileImage() == null
                      ? const Icon(Icons.person, size: 50, color: Colors.grey)
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            userData['userName'] ?? "User Name",
            style: AppFonts.bold.copyWith(
              color: Colors.white,
              fontSize: 18,
              shadows: [
                Shadow(
                  offset: Offset(0, 1),
                  blurRadius: 3.0,
                  color: Color.fromARGB(100, 0, 0, 0),
                ),
              ],
            ),
          ),
          Text(
            userData['email'] ?? "No email",
            style: AppFonts.regular.copyWith(
              color: Colors.white70,
              fontSize: 14,
              shadows: [
                Shadow(
                  offset: Offset(0, 1),
                  blurRadius: 2.0,
                  color: Color.fromARGB(70, 0, 0, 0),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            userData['bio'] ?? "No bio available",
            style: AppFonts.light.copyWith(
              color: Colors.white70,
              fontSize: 12,
              shadows: [
                Shadow(
                  offset: Offset(0, 1),
                  blurRadius: 2.0,
                  color: Color.fromARGB(70, 0, 0, 0),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                  settings: RouteSettings(
                    arguments: {
                      'name': userData['userName'],
                      'email': userData['email'],
                      'bio': userData['bio'],
                      'profileUrl': userData['profileUrl'],
                    },
                  ),
                ),
              );

              if (result != null && result['updated'] == true && mounted) {
                setState(() {
                  userData = {
                    'userName': result['name'],
                    'email': result['email'],
                    'bio': result['bio'],
                    'profileUrl': result['profileUrl'],
                  };
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isDarkMode ? const Color(0xFF4A3B7C) : Colors.white,
              foregroundColor: isDarkMode ? Colors.white : AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: isDarkMode ? 0 : 3,
            ),
            child: Text(
              "Edit Profile",
              style: AppFonts.bold.copyWith(
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider? _getProfileImage() {
    if (userData['profileUrl'] != null && userData['profileUrl'].isNotEmpty) {
      return NetworkImage(userData['profileUrl']);
    }
    return null;
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            "Confirm Logout",
            style: AppFonts.bold.copyWith(
              fontSize: 18,
            ),
          ),
          content: Text(
            "Are you sure you want to log out?",
            style: AppFonts.regular.copyWith(fontSize: 16),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
              child: Text(
                "No",
                style: AppFonts.bold.copyWith(
                  fontSize: 16,
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: Text(
                "Yes",
                style: AppFonts.bold.copyWith(
                  fontSize: 16,
                ),
              ),
              onPressed: () async {
                // Close the dialog first
                Navigator.of(dialogContext).pop();

                try {
                  if (context.mounted) {
                    final success = await AuthService().signOut(context);

                    if (success && context.mounted) {
                      // Navigate to login page and clear navigation stack
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (context) => const LoginPage()),
                        (Route<dynamic> route) => false,
                      );
                    }
                  }
                } catch (e) {
                  print("Error during logout process: $e");
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Failed to log out. Please try again."),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
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
    Color? iconColor,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final defaultColor = themeProvider.isDarkMode ? Colors.white : Colors.black;

    return ListTile(
      leading: Icon(icon, color: iconColor ?? defaultColor),
      title: Text(title,
          style: AppFonts.regular.copyWith(color: textColor ?? defaultColor)),
      trailing: trailingText != null
          ? Text(trailingText,
              style: AppFonts.regular.copyWith(
                  color: themeProvider.isDarkMode
                      ? Colors.grey[400]
                      : Colors.grey))
          : Icon(Icons.arrow_forward_ios,
              size: 16,
              color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey),
      onTap: onTap,
    );
  }

  Widget buildToggleTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final defaultColor = themeProvider.isDarkMode ? Colors.white : Colors.black;

    return ListTile(
      leading: Icon(icon, color: defaultColor),
      title: Text(title, style: AppFonts.regular.copyWith(color: defaultColor)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }

  Widget buildSectionTitle(String title) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: AppFonts.bold.copyWith(
          fontSize: 16,
          color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}
