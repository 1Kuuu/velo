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
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomePageContent(),
    const ToolboxPageContent(),
    const NewsFeedPageContent(),
    const ChatPageContent(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBottomBarButton(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      selectedIndex: _selectedIndex,
      onItemTapped: (index) {
        setState(() {
          _selectedIndex = index;
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
      appBar: MyAppBar(
        title: "Home",
        actions: [
          AppBarIcon(
            icon: Icons.cloud_outlined,
            onTap: () => print("Weather Tapped"),
            showBadge: false,
          ),
          AppBarIcon(
            icon: Icons.notifications_outlined,
            onTap: () => print("Notifications Tapped"),
          ),
          AppBarIcon(
            icon: Icons.person_outline,
            onTap: () => print("Profile Tapped"),
          ),
        ],
      ),
      body: const Center(child: Text("Welcome to Home Page")),
      floatingActionButton: TheFloatingActionButton(
        icon: Icons.add, // Example icon
        onPressed: () {
          print("Floating Action Button Tapped");
          // Handle the action you want when the button is tapped
        },
      ),
    );
  }
}
