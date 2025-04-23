import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:velora/core/configs/theme/theme_provider.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:velora/providers/language_provider.dart';
import 'package:velora/core/configs/language/app_localizations.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeProvider.isDarkMode
            ? const Color(0xFF4A3B7C)
            : AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pop(context, languageProvider.selectedLanguage);
          },
        ),
        title: Text(
          localizations.translate('language'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.translate('suggestedLanguages'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            // First container with English Default
            InkWell(
              onTap: () async {
                await languageProvider.setLanguage('English');
                if (mounted) {
                  Navigator.pop(context, 'English');
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: themeProvider.isDarkMode
                      ? const Color(0xFF1E1E1E)
                      : const Color(0xFFE6E6E6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildDefaultLanguageTile(
                    'English',
                    localizations.translate('default'),
                    languageProvider.selectedLanguage == 'English'),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                localizations.translate('languageReminder'),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ),

            Container(
              decoration: BoxDecoration(
                color: themeProvider.isDarkMode
                    ? const Color(0xFF1E1E1E)
                    : const Color(0xFFE6E6E6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: () async {
                      await languageProvider.setLanguage('English (UK)');
                      if (mounted) {
                        Navigator.pop(context, 'English (UK)');
                      }
                    },
                    child: _buildSelectionLanguageTile('English (UK)',
                        languageProvider.selectedLanguage == 'English (UK)'),
                  ),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.grey,
                    indent: 0,
                    endIndent: 0,
                  ),
                  InkWell(
                    onTap: () async {
                      await languageProvider.setLanguage('Filipino/Tagalog');
                      if (mounted) {
                        Navigator.pop(context, 'Filipino/Tagalog');
                      }
                    },
                    child: _buildSelectionLanguageTile(
                        'Filipino/Tagalog',
                        languageProvider.selectedLanguage ==
                            'Filipino/Tagalog'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultLanguageTile(
      String language, String subtitle, bool isSelected) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                language,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          if (isSelected)
            Icon(
              Icons.check,
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
            ),
        ],
      ),
    );
  }

  Widget _buildSelectionLanguageTile(String language, bool isSelected) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                language,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                language,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          if (isSelected)
            Icon(
              Icons.check,
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
            ),
        ],
      ),
    );
  }
}
