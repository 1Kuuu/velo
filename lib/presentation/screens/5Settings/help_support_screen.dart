import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:velora/core/configs/theme/theme_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@velora.com',
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: const Text(
          "Help & Support",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor:
            isDarkMode ? const Color(0xFF4A3B7C) : AppColors.primary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            context,
            "Frequently Asked Questions",
            [
              _buildExpandableFAQ(
                context,
                "How do I create an account?",
                "To create an account, click on the 'Sign Up' button on the login screen. Fill in your email, create a password, and follow the verification steps.",
                isDarkMode,
              ),
              _buildExpandableFAQ(
                context,
                "How can I reset my password?",
                "Click on 'Forgot Password?' on the login screen. Enter your email address, and we'll send you instructions to reset your password.",
                isDarkMode,
              ),
              _buildExpandableFAQ(
                context,
                "How do I update my profile?",
                "Go to Settings, tap on 'Edit Profile' under your profile picture. Here you can update your name, bio, and profile picture.",
                isDarkMode,
              ),
              _buildExpandableFAQ(
                context,
                "How do I enable/disable notifications?",
                "Go to Settings and use the Notifications toggle to enable or disable notifications for the app.",
                isDarkMode,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            "Contact Us",
            [
              _buildContactTile(
                context,
                "Email Support",
                "support@velora.com",
                Icons.email_outlined,
                _launchEmail,
                isDarkMode,
              ),
              _buildContactTile(
                context,
                "Customer Service",
                "Available 24/7",
                Icons.support_agent_outlined,
                () {},
                isDarkMode,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            "Additional Resources",
            [
              _buildResourceTile(
                context,
                "User Guide",
                "Learn how to use Velora",
                Icons.book_outlined,
                isDarkMode,
              ),
              _buildResourceTile(
                context,
                "Video Tutorials",
                "Watch helpful tutorials",
                Icons.play_circle_outline,
                isDarkMode,
              ),
              _buildResourceTile(
                context,
                "Community Forum",
                "Connect with other users",
                Icons.forum_outlined,
                isDarkMode,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, String title, List<Widget> children) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: themeProvider.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildExpandableFAQ(
    BuildContext context,
    String question,
    String answer,
    bool isDarkMode,
  ) {
    return Card(
      color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(
          question,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              answer,
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
    bool isDarkMode,
  ) {
    return Card(
      color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDarkMode ? AppColors.primary : AppColors.primary,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildResourceTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    bool isDarkMode,
  ) {
    return Card(
      color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDarkMode ? AppColors.primary : AppColors.primary,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: isDarkMode ? Colors.white70 : Colors.black54,
        ),
        onTap: () {
          // Implement navigation to respective resources
        },
      ),
    );
  }
}
