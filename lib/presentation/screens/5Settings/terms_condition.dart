import 'package:flutter/material.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:velora/core/configs/theme/theme_provider.dart';

class TermsConditionScreen extends StatelessWidget {
  const TermsConditionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Flexible(
          child: Text(
            'Terms & Condition',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        centerTitle: false,
        backgroundColor: themeProvider.isDarkMode
            ? const Color(0xFF4A3B7C)
            : AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 16,
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
            ),
            children: const <TextSpan>[
              TextSpan(
                text: 'Terms & Condition\n',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              TextSpan(
                text: 'Effective Date: December 5th, 2024\n\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: 'Welcome to ',
              ),
              TextSpan(
                text: 'VELORA',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text:
                    '! These Terms and Conditions ("Terms") govern your access to and use of our cycling app, including its features for planning, tracking, and sharing your cycling activities. By using [App Name], you agree to be bound by these Terms, as well as our Privacy Policy, which is incorporated into these Terms by reference. If you do not agree to these Terms, you must not use our app.\n\n',
              ),
              TextSpan(
                text: '1. Acceptance of Terms\n\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text:
                    'By downloading, installing, or using VELORA ("CYCLIST SMART PLANNER COMMUNITY APP WITH AI"), you acknowledge and agree to abide by these Terms and any future updates or amendments. We may revise these Terms from time to time, and such changes will be effective when posted in the app or on our website. Your continued use of the App after any changes constitutes your acceptance of the updated Terms.\n\n',
              ),
              TextSpan(
                text: '2. Account Registration\n\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text:
                    'To use certain features of VELORA, you may be required to create an account. You agree to provide accurate, current, and complete information during the registration process, and to update such information if it changes. You are responsible for maintaining the confidentiality of your account information, including your password, and for all activities that occur under your account.\n\n',
              ),
              TextSpan(
                text: '3. App Features\n\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text:
                    'VELORA provides the following key features:\n- Plan: Create custom cycling routes and events.\n- Track: Log and track your cycling activities, including distance, speed, time, and elevation.\n- Share: Share your cycling achievements and routes with other users or on social media.\n\n',
              ),
              TextSpan(
                text: '4. User Content\n\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text:
                    'You are responsible for any content you create, upload, or share through the App. By posting content, you grant VELORA a non-exclusive, worldwide, royalty-free license to use, reproduce, modify, and display such content in connection with the App.\n\n',
              ),
              TextSpan(
                text: '5. Privacy\n\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text:
                    'Your use of the App is also governed by our Privacy Policy, which outlines how we collect, use, and protect your personal data. Please read the Privacy Policy carefully before using the App.\n\n',
              ),
              TextSpan(
                text: '6. Prohibited Activities\n\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text:
                    'You agree not to engage in any activity that interferes with or disrupts the App or its servers, including but not limited to hacking, spamming, or transmitting malware. Any violation of these Terms may result in termination of your access to the App.\n\n',
              ),
              TextSpan(
                text: '7. Disclaimer of Warranties\n\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text:
                    'The App is provided "as is" without any warranties, express or implied. VELORA does not guarantee that the App will be error-free or uninterrupted, or that any defects will be corrected.\n\n',
              ),
              TextSpan(
                text: '8. Limitation of Liability\n\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text:
                    'To the fullest extent permitted by law, VELORA, its affiliates, and its employees are not liable for any indirect, incidental, special, or consequential damages, including but not limited to loss of data, business interruption, or personal injury, arising out of or in connection with your use of the App.\n\n',
              ),
              TextSpan(
                text: '9. Termination\n\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text:
                    'We reserve the right to suspend or terminate your access to the App at any time, without notice, if we believe you have violated these Terms. You may also delete your account at any time by following the instructions in the App settings.\n',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(
    home: TermsConditionScreen(),
  ));
}
