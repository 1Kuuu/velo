import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:velora/core/configs/theme/theme_provider.dart';
import 'package:velora/core/configs/theme/app_fonts.dart';
import 'package:velora/presentation/widgets/reusable_wdgts.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: MyAppBar(
        title: 'About',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome to VELORA',
              style: AppFonts.bold.copyWith(
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Welcome to VELORA, the ultimate cycling companion that helps you plan, track, and share your cycling adventures. Whether you\'re an experienced cyclist or just starting out, our app is designed to empower you with the tools you need to make the most of every ride.',
              style: AppFonts.regular.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 24),
            Text(
              'What We Do?',
              style: AppFonts.bold.copyWith(
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'At VELORA we\'re passionate about cycling and the freedom it brings. Our app is built to enhance your cycling experience by offering three key features:',
              style: AppFonts.regular.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 12),
            _buildFeatureItem('Plan Your Routes',
                'Easily create custom cycling routes based on your preferences and needs. Whether you\'re looking for a scenic ride, a challenging course, or a quick commute, our route planner helps you map out your perfect cycling journey.'),
            _buildFeatureItem('Track Your Performance',
                'Monitor your progress in real-time with detailed statistics on your speed, distance, elevation, and time. Whether you\'re training for a race or just trying to stay fit, our tracking tools help you keep track of your cycling performance.'),
            _buildFeatureItem('Share Your Journey',
                'Share your rides, achievements, and routes with friends, family, and the cycling community. With the ability to share on social media or within the app, you can inspire others and stay connected with fellow cyclists.'),
            const SizedBox(height: 24),
            Text(
              'Why Choose VELORA?',
              style: AppFonts.bold.copyWith(
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            _buildBenefitItem('User-Friendly Interface',
                'Our intuitive and easy-to-navigate app ensures a seamless experience, whether you\'re planning your next ride or reviewing past performances.'),
            _buildBenefitItem('Personalized Experience',
                'Tailor the app to fit your unique cycling goals, preferences, and training routines.'),
            _buildBenefitItem('Community Engagement',
                'Join a vibrant community of cyclists. Share tips, explore new routes, and celebrate your cycling milestones with others.'),
            _buildBenefitItem('Reliable Tracking',
                'Our precise tracking system gives you accurate data, so you can monitor your progress and make improvements over time.'),
            const SizedBox(height: 24),
            Text(
              'Join the VELORA Community',
              style: AppFonts.bold.copyWith(
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Cycling is more than just a sport—it\'s a lifestyle. Whether you\'re commuting, training, or exploring, VELORA is here to support you on every ride. Join our growing community of cycling enthusiasts and take your cycling journey to the next level!',
              style: AppFonts.regular.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 24),
            Text(
              'Thank you for choosing VELORA. We\'re excited to be part of your cycling adventure!',
              style: AppFonts.bold.copyWith(
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppFonts.bold.copyWith(
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: AppFonts.regular.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppFonts.bold.copyWith(
                    fontSize: 15,
                  ),
                ),
                Text(
                  description,
                  style: AppFonts.regular.copyWith(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
