import 'package:flutter/material.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:velora/presentation/screens/0Auth/profile.dart';
import 'package:velora/presentation/screens/Weather/weather.dart';
import 'package:velora/presentation/widgets/reusable_wdgts.dart';
import 'package:velora/presentation/widgets/notification_app_bar_icon.dart';
import 'package:provider/provider.dart';
import 'package:velora/core/configs/theme/theme_provider.dart';

// Base class for all bike info screens
class BikeInfoScreen extends StatelessWidget {
  final Widget part;
  final String title;

  const BikeInfoScreen({
    super.key,
    required this.part,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: MyAppBar(
        title: title,
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
          const NotificationAppBarIcon(),
          AppBarIcon(
            icon: Icons.person_outline,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            },
          ),
        ],
      ),
      body: Center(child: part),
      floatingActionButton: TheFloatingActionButton(
        svgAsset: 'assets/svg/white-m.svg',
        onPressed: () => print("FAB Pressed"),
        backgroundColor: isDark ? Colors.black : Color(0xFF4A3B7C),
        heroTag: 'openai_fab',
      ),
    );
  }
}

// Base class for all bike parts
class BikePart extends StatelessWidget {
  final String title;
  final String imagePath;
  final String description;

  const BikePart({
    super.key,
    required this.title,
    required this.imagePath,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Image.asset(
          imagePath,
          height: 120,
        ),
        SizedBox(height: 10),
        Text(
          title,
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
            description,
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

// Road Bike Parts
class RoadbikeInfo extends BikeInfoScreen {
  const RoadbikeInfo({super.key, required Widget part})
      : super(part: part, title: "Road Bike");
}

class RoadbikeHandlePart extends BikePart {
  const RoadbikeHandlePart({super.key})
      : super(
          title: 'Handle Bar',
          imagePath: 'assets/images/rd-Handle.png',
          description:
              'A curved handlebar with a downward sloping design that allows cyclists to grip the bars in multiple positions (on the tops, hoods, or drops) depending on the terrain and desired riding posture.',
        );
}

class RoadbikeWheelPart extends BikePart {
  const RoadbikeWheelPart({super.key})
      : super(
          title: 'Wheels',
          imagePath: 'assets/images/rd-Wheels.png',
          description:
              'Rims for road bikes play a crucial role in performance, durability, and weight. They are the structural component of the wheel that holds the tire and connects to the spokes and hub.',
        );
}

class RoadbikeFramePart extends BikePart {
  const RoadbikeFramePart({super.key})
      : super(
          title: 'Frame',
          imagePath: 'assets/images/rd-Frame.png',
          description:
              'The "Frame" of a road bike refers to its frame and key structural components like the fork, seatpost, handlebars, bottom bracket, and wheel stays. These parts provide support, stability, and allow the bike to function.',
        );
}

class RoadbikeSaddlePart extends BikePart {
  const RoadbikeSaddlePart({super.key})
      : super(
          title: 'Saddle',
          imagePath: 'assets/images/rd-Saddle.png',
          description:
              'A good saddle is crucial for a comfortable and efficient riding experience, as it supports the riders weight and helps maintain proper riding posture.',
        );
}

class RoadbikeCrankPart extends BikePart {
  const RoadbikeCrankPart({super.key})
      : super(
          title: 'Crank',
          imagePath: 'assets/images/rd-Crank.png',
          description:
              'The crank is part of the bike drivetrain that connects the pedals to the bikes bottom bracket, allowing the rider to transfer power to the wheels.',
        );
}

class RoadbikeShifterPart extends BikePart {
  const RoadbikeShifterPart({super.key})
      : super(
          title: 'Shifter',
          imagePath: 'assets/images/rd-Shifter.png',
          description:
              'The shifter is a component on a road bike that allows the rider to change gears, controlling the bike speed and cadence. It is typically integrated into the handlebars and works in conjunction with the derailleur and chainrings.',
        );
}

// Mountain Bike Parts
class MountainbikeInfo extends BikeInfoScreen {
  const MountainbikeInfo({super.key, required Widget part})
      : super(part: part, title: "Mountain Bike");
}

class MountainbikeHandlePart extends BikePart {
  const MountainbikeHandlePart({super.key})
      : super(
          title: 'Handle Bar',
          imagePath: 'assets/images/mb-Handle.png',
          description:
              'The MTB (mountain bike) handlebar is designed for off-road cycling and provides control, stability, and comfort on rough terrain.',
        );
}

class MountainbikeWheelPart extends BikePart {
  const MountainbikeWheelPart({super.key})
      : super(
          title: 'Wheels',
          imagePath: 'assets/images/mb-Wheels.png',
          description:
              'The MTB (mountain bike) wheel is designed to handle the challenges of off-road terrain, providing strength, durability, and traction.',
        );
}

class MountainbikeFramePart extends BikePart {
  const MountainbikeFramePart({super.key})
      : super(
          title: 'Frame',
          imagePath: 'assets/images/mb-Frame.png',
          description:
              'The "Frame" of a mountainbike refers to its frame and key structural components like the fork, seatpost, handlebars, bottom bracket, and wheel stays. These parts provide support, stability, and allow the bike to function.',
        );
}

class MountainbikeSaddlePart extends BikePart {
  const MountainbikeSaddlePart({super.key})
      : super(
          title: 'Saddle',
          imagePath: 'assets/images/mb-Saddle.png',
          description:
              'A good saddle is crucial for a comfortable and efficient riding experience, as it supports the riders weight and helps maintain proper riding posture.',
        );
}

class MountainbikeCrankPart extends BikePart {
  const MountainbikeCrankPart({super.key})
      : super(
          title: 'Crank',
          imagePath: 'assets/images/mb-Crank.png',
          description:
              'The crank is part of the bike drivetrain that connects the pedals to the bikes bottom bracket, allowing the rider to transfer power to the wheels.',
        );
}

class MountainbikeShifterPart extends BikePart {
  const MountainbikeShifterPart({super.key})
      : super(
          title: 'Shifter',
          imagePath: 'assets/images/mb-Shifter.png',
          description:
              'The shifter is a component on a road bike that allows the rider to change gears, controlling the bike speed and cadence. It is typically integrated into the handlebars and works in conjunction with the derailleur and chainrings.',
        );
}

// Fixie Bike Parts
class FixiebikeInfo extends BikeInfoScreen {
  const FixiebikeInfo({super.key, required Widget part})
      : super(part: part, title: "Fixie Bike");
}

class FixieHandlePart extends BikePart {
  const FixieHandlePart({super.key})
      : super(
          title: 'Handle Bar',
          imagePath: 'assets/images/fx-Handle.png',
          description:
              'A curved handlebar with a downward sloping design that allows cyclists to grip the bars in multiple positions (on the tops, hoods, or drops) depending on the terrain and desired riding posture.',
        );
}

class FixieWheelPart extends BikePart {
  const FixieWheelPart({super.key})
      : super(
          title: 'Wheels',
          imagePath: 'assets/images/fx-Wheels.png',
          description:
              'Rims for road bikes play a crucial role in performance, durability, and weight. They are the structural component of the wheel that holds the tire and connects to the spokes and hub.',
        );
}

class FixieFramePart extends BikePart {
  const FixieFramePart({super.key})
      : super(
          title: 'Frame',
          imagePath: 'assets/images/fx-Frame.png',
          description:
              'The "Frame" of a road bike refers to its frame and key structural components like the fork, seatpost, handlebars, bottom bracket, and wheel stays. These parts provide support, stability, and allow the bike to function.',
        );
}

class FixieSaddlePart extends BikePart {
  const FixieSaddlePart({super.key})
      : super(
          title: 'Saddle',
          imagePath: 'assets/images/fx-Saddle.png',
          description:
              'A good saddle is crucial for a comfortable and efficient riding experience, as it supports the riders weight and helps maintain proper riding posture.',
        );
}

class FixieCrankPart extends BikePart {
  const FixieCrankPart({super.key})
      : super(
          title: 'Crank',
          imagePath: 'assets/images/fx-Break.png',
          description:
              'The crank is part of the bikes drivetrain that connects the pedals to the bikes bottom bracket, allowing the rider to transfer power to the wheels.',
        );
}

class FixieBreakPart extends BikePart {
  const FixieBreakPart({super.key})
      : super(
          title: 'Break',
          imagePath: 'assets/images/fx-Break.png',
          description:
              'Brakes on a bike are essential for Stopping: To slow down or bring the bike to a complete stop. Control Helps maintain speed and navigate safely, especially on descents or sharp turns. Safety: Provides the ability to react to obstacles or changes in terrain. Handling: Allows precise adjustments in speed for better bike handling.',
        );
}
