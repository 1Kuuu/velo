import 'package:flutter/material.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:velora/presentation/screens/0Auth/profile.dart';
import 'package:velora/presentation/widgets/reusable_wdgts.dart';

class FixiebikeInfo extends StatelessWidget {
  final Widget part;

  static List<Map<String, String>> parts = [];
  const FixiebikeInfo({super.key, required this.part});

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
        backgroundColor: Colors.black,
        heroTag: 'openai_fab',
      ),
    );
  }
}

class FixieHandlePart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Image.asset(
          'assets/images/fx-Handle.png', // Replace with your actual image path
          height: 120,
        ),
        SizedBox(height: 10),
        Text(
          'Handle Bar',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10),
        Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'A curved handlebar with a downward sloping design that allows cyclists to grip the bars in multiple positions (on the tops, hoods, or drops) depending on the terrain and desired riding posture.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class FixieWheelPart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Image.asset(
          'assets/images/fx-Wheels.png', // Replace with your actual image path
          height: 120,
        ),
        SizedBox(height: 10),
        Text(
          'Wheels',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10),
        Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Rims for road bikes play a crucial role in performance, durability, and weight. They are the structural component of the wheel that holds the tire and connects to the spokes and hub.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class FixieFramePart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Image.asset(
          'assets/images/fx-Frame.png', // Replace with your actual image path
          height: 120,
        ),
        SizedBox(height: 10),
        Text(
          'Frame',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10),
        Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'The "Frame" of a road bike refers to its frame and key structural components like the fork, seatpost, handlebars, bottom bracket, and wheel stays. These parts provide support, stability, and allow the bike to function.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class FixieSaddlePart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Image.asset(
          'assets/images/fx-Saddle.png', // Replace with your actual image path
          height: 120,
        ),
        SizedBox(height: 10),
        Text(
          'Saddle',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10),
        Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'A good saddle is crucial for a comfortable and efficient riding experience, as it supports the riders weight and helps maintain proper riding posture.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class FixieCrankPart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Image.asset(
          'assets/images/fx-Break.png', // Replace with your actual image path
          height: 120,
        ),
        SizedBox(height: 10),
        Text(
          'Crank',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10),
        Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'The crank is part of the bikes drivetrain that connects the pedals to the bikes bottom bracket, allowing the rider to transfer power to the wheels.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class FixieBreakPart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
          ),
        ),
        SizedBox(height: 10),
        Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Brakes on a bike are essential for Stopping: To slow down or bring the bike to a complete stop. Control Helps maintain speed and navigate safely, especially on descents or sharp turns. Safety: Provides the ability to react to obstacles or changes in terrain. Handling: Allows precise adjustments in speed for better bike handling.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}
