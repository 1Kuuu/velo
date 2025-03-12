import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:velora/presentation/screens/0Auth/profile.dart';
import 'package:velora/presentation/screens/Weather/weather.dart';
import 'package:velora/presentation/widgets/reusable_wdgts.dart';
import 'package:velora/core/configs/theme/theme_provider.dart';

class RoadbikeInfo extends StatelessWidget {
  final Widget part;

  static List<Map<String, String>> parts = [];
  const RoadbikeInfo({super.key, required this.part});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: MyAppBar(
        title: "Toolbox",
        actions: [
          AppBarIcon(
            icon: Icons.cloud_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => WeatherScreen()),
              );
            },
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
            ),
          ),
        ],
      ),
      body: Center(child: part), // Using the new widget here
      floatingActionButton: TheFloatingActionButton(
        svgAsset: 'assets/svg/white-m.svg',
        onPressed: () => print("FAB Pressed"),
        backgroundColor: isDark ? Colors.black : Color(0xFF4A3B7C),
        heroTag: 'openai_fab',
      ),
    );
  }
}

class RoadbikeHandlePart extends StatelessWidget {
  const RoadbikeHandlePart({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Image.asset(
          'assets/images/rd-Handle.png', // Replace with your actual image path
          height: 120,
        ),
        SizedBox(height: 10),
        Text(
          'Handle Bar',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(height: 10),
        Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Color(0xFF1E1E1E) : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'A curved handlebar with a downward sloping design that allows cyclists to grip the bars in multiple positions (on the tops, hoods, or drops) depending on the terrain and desired riding posture.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

class RoadbikeWheelPart extends StatelessWidget {
  const RoadbikeWheelPart({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Image.asset(
          'assets/images/rd-Wheels.png', // Replace with your actual image path
          height: 120,
        ),
        SizedBox(height: 10),
        Text(
          'Wheels',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(height: 10),
        Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Color(0xFF1E1E1E) : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Rims for road bikes play a crucial role in performance, durability, and weight. They are the structural component of the wheel that holds the tire and connects to the spokes and hub.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

class RoadbikeFramePart extends StatelessWidget {
  const RoadbikeFramePart({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Image.asset(
          'assets/images/rd-Frame.png', // Replace with your actual image path
          height: 120,
        ),
        SizedBox(height: 10),
        Text(
          'Frame',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(height: 10),
        Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Color(0xFF1E1E1E) : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'The "Frame" of a road bike refers to its frame and key structural components like the fork, seatpost, handlebars, bottom bracket, and wheel stays. These parts provide support, stability, and allow the bike to function.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

class RoadbikeSaddlePart extends StatelessWidget {
  const RoadbikeSaddlePart({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Image.asset(
          'assets/images/rd-Saddle.png', // Replace with your actual image path
          height: 120,
        ),
        SizedBox(height: 10),
        Text(
          'Saddle',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(height: 10),
        Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Color(0xFF1E1E1E) : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'A good saddle is crucial for a comfortable and efficient riding experience, as it supports the riders weight and helps maintain proper riding posture.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

class RoadbikeCrankPart extends StatelessWidget {
  const RoadbikeCrankPart({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Image.asset(
          'assets/images/rd-Crank.png', // Replace with your actual image path
          height: 120,
        ),
        SizedBox(height: 10),
        Text(
          'Crank',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(height: 10),
        Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Color(0xFF1E1E1E) : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'The crank is part of the bike drivetrain that connects the pedals to the bikes bottom bracket, allowing the rider to transfer power to the wheels.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

class RoadbikeShifterPart extends StatelessWidget {
  const RoadbikeShifterPart({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Image.asset(
          'assets/images/rd-Shifter.png', // Replace with your actual image path
          height: 120,
        ),
        SizedBox(height: 10),
        Text(
          'shifter',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(height: 10),
        Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Color(0xFF1E1E1E) : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'The shifter is a component on a road bike that allows the rider to change gears, controlling the bike speed and cadence. It is typically integrated into the handlebars and works in conjunction with the derailleur and chainrings.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
