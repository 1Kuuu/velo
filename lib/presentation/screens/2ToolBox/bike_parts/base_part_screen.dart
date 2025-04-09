import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:velora/core/configs/theme/theme_provider.dart';
import 'package:velora/core/configs/theme/app_fonts.dart';

abstract class BasePartScreen extends StatelessWidget {
  final String title;
  final String imagePath;
  final String description;
  final List<String> maintenanceTips;
  final List<String> commonIssues;

  const BasePartScreen({
    Key? key,
    required this.title,
    required this.imagePath,
    required this.description,
    required this.maintenanceTips,
    required this.commonIssues,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        title: Text(
          title,
          style: AppFonts.bold.copyWith(
            fontSize: 20,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'part_$title',
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isDarkMode ? const Color(0xFF4A3B7C) : Colors.brown,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Description',
                style: AppFonts.bold.copyWith(
                  fontSize: 20,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: AppFonts.regular.copyWith(
                  fontSize: 16,
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              _buildSection(
                'Maintenance Tips',
                maintenanceTips,
                isDarkMode,
              ),
              const SizedBox(height: 24),
              _buildSection(
                'Common Issues',
                commonIssues,
                isDarkMode,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> items, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppFonts.bold.copyWith(
            fontSize: 20,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.circle,
                    size: 8,
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: AppFonts.regular.copyWith(
                        fontSize: 16,
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
