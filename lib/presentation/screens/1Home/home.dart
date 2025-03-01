import 'package:flutter/material.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:velora/presentation/screens/2ToolBox/toolbox.dart';
import 'package:velora/presentation/screens/3News/newsfeed.dart';
import 'package:velora/presentation/screens/4Chat/chat.dart';
import 'package:velora/presentation/screens/5Settings/setting.dart';
import 'package:velora/presentation/widgets/reusable_wdgts.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; // Track the selected tab

  final List<Widget> _screens = [
    const HomePageContent(),
    const Toolbox(),
    const NewsFeed(),
    const ChatPage(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBottomBarButton(
      body: IndexedStack(
        index: _selectedIndex, // Maintain state of each screen
        children: _screens,
      ),
      selectedIndex: _selectedIndex,
      onItemTapped: (index) {
        setState(() {
          _selectedIndex = index; // Update selected page
        });
      },
    );
  }
}

class HomePageContent extends StatelessWidget {
  const HomePageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(title: const Text("Home")),
      body: const Center(child: Text("Welcome to Home Page")),
    );
  }
}
