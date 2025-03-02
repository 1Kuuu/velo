import 'package:flutter/material.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:velora/presentation/screens/0Auth/profile.dart';
import 'package:velora/presentation/widgets/reusable_wdgts.dart';

class ToolboxPageContent extends StatelessWidget {
  const ToolboxPageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: MyAppBar(
        title: "Toolbox",
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
            onTap: () =>Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProfilePage()),
        )
          ),
        ],
      ),
      body: const Center(child: Text("Welcome to Toolbox")),
    );
  }
}

