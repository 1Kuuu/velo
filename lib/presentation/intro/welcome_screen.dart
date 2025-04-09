import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:velora/presentation/screens/1Home/home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velora/presentation/widgets/reusable_wdgts.dart';
import 'package:velora/core/configs/theme/theme_provider.dart';
import 'package:provider/provider.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Welcome'),
        titleTextStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 36,
            fontWeight: FontWeight.w600,
            color: Colors.white),
        backgroundColor:
            isDarkMode ? const Color(0xFF4A3B7C) : AppColors.primary,
      ),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('user_preferences')
              .doc(FirebaseAuth.instance.currentUser?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              _showErrorToast(context, 'Failed to load data.');
              return const Center(child: Text('Something went wrong!'));
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              _showErrorToast(context, 'User preferences not found.');
              return const Center(child: Text('No data available!'));
            }

            final rawData = snapshot.data!.data();

            if (rawData is! Map<String, dynamic>) {
              _showErrorToast(context, "Unexpected data format.");
              return const Center(
                  child: Text("Invalid Firestore data format."));
            }

            final data = rawData;
            final bikeType = data['bike_type'] as String? ?? 'Unknown';
            final timePrefs =
                (data['time_preferences'] as Map<String, dynamic>?) ?? {};
            final locationPrefs =
                (data['location_preferences'] as List<dynamic>?)
                        ?.whereType<String>()
                        .toList() ??
                    [];

            return SizedBox(
              height: MediaQuery.of(context).size.height,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppLogo(),
                      CustomTitleText(
                        text: 'WELCOME!',
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'SEEMS LIKE YOU LOVE:',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildSummaryCard(bikeType),
                      const SizedBox(height: 20),
                      _buildPreferenceSection('To Ride During:', timePrefs),
                      const SizedBox(height: 20),
                      _buildPreferenceSection('In The:', locationPrefs),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          text: 'START',
                          onPressed: () async {
                            try {
                              final user = FirebaseAuth.instance.currentUser;
                              if (user != null) {
                                final userRef = FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user.uid);

                                final docSnapshot = await userRef.get();
                                if (!docSnapshot.exists) {
                                  await userRef.set({
                                    'uid': user.uid,
                                    'userName': user.displayName ?? 'New User',
                                    'email': user.email,
                                    'createdAt': FieldValue.serverTimestamp(),
                                    'setupComplete': true,
                                    'lastUpdated': FieldValue.serverTimestamp(),
                                  });
                                } else {
                                  await userRef.update({
                                    'setupComplete': true,
                                    'lastUpdated': FieldValue.serverTimestamp(),
                                  });
                                }

                                final prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.setBool('onboardingComplete', true);

                                if (context.mounted) {
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                      builder: (context) => const HomePage(),
                                    ),
                                    (route) => false,
                                  );
                                }
                              } else {
                                _showErrorToast(
                                    context, 'Please sign in to continue');
                              }
                            } catch (e) {
                              _showErrorToast(
                                  context, 'Failed to complete setup: $e');
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showErrorToast(BuildContext context, String message) {
    DelightToastBar(
      builder: (context) {
        return ToastCard(
          title: const Text('Error'),
          subtitle: Text(message),
          leading: const Icon(Icons.error, color: Colors.red),
        );
      },
      position: DelightSnackbarPosition.top,
      autoDismiss: true,
      snackbarDuration: const Duration(seconds: 2),
      animationDuration: const Duration(milliseconds: 300),
    ).show(context);
  }

  Widget _buildSummaryCard(String bikeType) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: themeProvider.isDarkMode
                ? const Color(0xFF1E1E1E)
                : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Image.asset(
                'assets/images/${bikeType.toLowerCase()}.png',
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.directions_bike,
                      size: 100, color: Colors.grey);
                },
              ),
              const SizedBox(height: 8),
              Text(
                bikeType,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPreferenceSection(String title, dynamic preferences) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDarkMode = themeProvider.isDarkMode;
        List<String> selectedPreferences = [];

        if (preferences is Map<String, dynamic>) {
          selectedPreferences = preferences.entries
              .where((entry) => entry.value == true)
              .map((entry) => entry.key)
              .toList();
        } else if (preferences is List<dynamic>) {
          selectedPreferences = preferences.whereType<String>().toList();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: selectedPreferences.map((pref) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  decoration: BoxDecoration(
                    color:
                        isDarkMode ? const Color(0xFF4A3B7C) : Colors.grey[400],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    pref,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}
