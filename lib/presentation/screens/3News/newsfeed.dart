import 'package:flutter/material.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:velora/presentation/screens/0Auth/profile.dart';
import 'package:velora/presentation/screens/3News/search_view.dart';
import 'package:velora/presentation/widgets/reusable_wdgts.dart';

class NewsFeedPageContent extends StatelessWidget {
  const NewsFeedPageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: MyAppBar(
        title: "Velora",
        actions: [
          AppBarIcon(
            icon: Icons.search,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SearchView()),
            ),
            showBadge: false,
          ),
          AppBarIcon(
            icon: Icons.notifications_outlined,
            onTap: () => print("Notifications Tapped"),
          ),
          AppBarIcon(
              icon: Icons.person_outline,
              onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfilePage()),
                  )),
        ],
      ),
      body: const Center(child: Text("Welcome to News Feed")),
    );
  }
}
