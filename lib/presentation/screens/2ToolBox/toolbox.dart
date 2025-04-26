import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:velora/core/configs/theme/app_fonts.dart';
import 'package:velora/core/configs/theme/theme_provider.dart';
import 'package:velora/core/services/ai_chat_screen.dart';
import 'package:velora/presentation/screens/Notifications/notifications_screen.dart';
import 'package:velora/presentation/screens/0Auth/profile.dart';
import 'package:velora/presentation/widgets/reusable_wdgts.dart';
import 'package:provider/provider.dart';


class ToolboxPageContent extends StatelessWidget {
  const ToolboxPageContent({super.key});

  Future<String?> getSelectedBike() async {
    var user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Try from users collection first (where we store bike_type initially)
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
          
      if (userDoc.exists && userDoc.data()?['bike_type'] != null) {
        return userDoc.data()?['bike_type'];
      }
      
      // Fall back to user_preferences if not found in users collection
      var prefDoc = await FirebaseFirestore.instance
          .collection('user_preferences')
          .doc(user.uid)
          .get();

      return prefDoc.data()?['bike_type'];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF121212) : AppColors.lightBackground,
      appBar: MyAppBar(
        title: "Toolbox",
        actions: [
          AppBarIcon(
            icon: Icons.notifications,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
              );
            },
          ),
          _ProfileIcon(),
        ],
      ),
      body: FutureBuilder<String?>(
        future: getSelectedBike(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasData && snapshot.data != null) {
            return BikeScreens(bikeType: snapshot.data!);
          }
          
          // No bike selected - show bike selection UI instead of just an error message
          return BikeSelectionScreen(
            onBikeSelected: (bikeType) async {
              // Save bike selection to both locations
              try {
                var user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                    'bike_type': bikeType,
                    'lastUpdated': FieldValue.serverTimestamp(),
                  }, SetOptions(merge: true));
                  
                  // Refresh the screen
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const ToolboxPageContent()),
                  );
                }
              } catch (e) {
                print("Error saving bike selection: $e");
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error saving selection: $e")),
                );
              }
            },
          );
        },
      ),
      floatingActionButton: TheFloatingActionButton(
        svgAsset: 'assets/svg/white-m.svg',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AIChatScreen()),
          );
        },
        backgroundColor: isDarkMode ? const Color(0xFF4A3B7C) : Colors.black,
        heroTag: 'openai_fab',
      ),
    );
  }
}

class BikeScreens extends StatefulWidget {
  final String bikeType;

  const BikeScreens({Key? key, required this.bikeType}) : super(key: key);

  @override
  _BikeScreenState createState() => _BikeScreenState();
}

class _BikeScreenState extends State<BikeScreens>
    with SingleTickerProviderStateMixin {
  late String selectedBike;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    selectedBike = widget.bikeType.toLowerCase();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void changeBike(String newBike) async {
    setState(() {
      _isLoading = true;
      _controller.reverse();
    });

    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      selectedBike = newBike.toLowerCase();
      _isLoading = false;
      _controller.forward();
    });
  }

  // Get parts based on bike type
  List<String> getTitles() {
    if (selectedBike.toLowerCase() == 'roadbike') {
      return ['HANDLE', 'WHEELS', 'FRAME', 'SADDLE', 'CRANK', 'SHIFTER'];
    } else if (selectedBike.toLowerCase() == 'mountainbike') {
      return ['HANDLE', 'WHEELS', 'FRAME', 'SADDLE', 'CRANK', 'SHIFTER'];
    } else if (selectedBike.toLowerCase() == 'fixie') {
      return ['HANDLE', 'WHEELS', 'FRAME', 'SADDLE', 'CRANK', 'BRAKE'];
    }
    return [
      'HANDLE',
      'WHEELS',
      'FRAME',
      'SADDLE',
      'CRANK',
      'SHIFTER'
    ]; // Default
  }

  // Get images based on bike type
  List<String> getImages() {
    String prefix = '';
    if (selectedBike.toLowerCase() == 'roadbike') {
      prefix = 'rd';
    } else if (selectedBike.toLowerCase() == 'mountainbike') {
      prefix = 'mb';
    } else if (selectedBike.toLowerCase() == 'fixie') {
      prefix = 'fx';
    } else {
      prefix = 'rd'; // Default
    }

    String capitalizeFirst(String text) {
      if (text.isEmpty) return text;
      return "${text[0].toUpperCase()}${text.substring(1).toLowerCase()}";
    }

    List<String> parts = getTitles();
    List<String> images = parts.map((part) {
      if (part == 'BRAKE') {
        return 'assets/images/$prefix-Break.png';
      }
      return 'assets/images/$prefix-${capitalizeFirst(part)}.png';
    }).toList();

    return images;
  }

  void navigateToPartInfo(BuildContext context, int index) {
    String partName = BikeUtils.getTitles(selectedBike)[index].toLowerCase();
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    String title = '';
    String imagePath = '';
    String description = '';
    List<Map<String, String>> maintenanceTips = [];

    if (selectedBike.toLowerCase() == 'roadbike') {
      switch (partName) {
        case 'handle':
          title = 'Handle Bar';
          imagePath = 'assets/images/rd-Handle.png';
          description =
              'A curved handlebar with a downward sloping design that allows cyclists to grip the bars in multiple positions (on the tops, hoods, or drops) depending on the terrain and desired riding posture.';
          maintenanceTips = [
            {
              'title': 'Regular Inspection',
              'description':
                  'Check handlebar tape for wear and replace when it becomes worn or loose. Inspect for any cracks or damage in the handlebar itself.',
            },
            {
              'title': 'Cleaning',
              'description':
                  'Clean handlebars and tape regularly with a mild soap solution. Dry thoroughly to prevent corrosion.',
            },
            {
              'title': 'Tightness Check',
              'description':
                  'Ensure all bolts are properly torqued. Check stem bolts and handlebar clamp bolts monthly.',
            },
          ];
          break;
        case 'wheels':
          title = 'Wheels';
          imagePath = 'assets/images/rd-Wheels.png';
          description =
              'Rims for road bikes play a crucial role in performance, durability, and weight. They are the structural component of the wheel that holds the tire and connects to the spokes and hub.';
          maintenanceTips = [
            {
              'title': 'Tire Pressure',
              'description':
                  'Check tire pressure before every ride. Road bike tires typically need 80-130 PSI. Inspect tires for cuts or wear.',
            },
            {
              'title': 'Wheel Truing',
              'description':
                  'Check wheel trueness monthly. Use a truing stand or have a shop true wheels if they wobble. Tighten loose spokes.',
            },
            {
              'title': 'Hub Maintenance',
              'description':
                  'Clean and lubricate hub bearings every 3-6 months. Check for play in the hub by wiggling the wheel side to side.',
            },
          ];
          break;
        case 'frame':
          title = 'Frame';
          imagePath = 'assets/images/rd-Frame.png';
          description =
              'The "Frame" of a road bike refers to its frame and key structural components like the fork, seatpost, handlebars, bottom bracket, and wheel stays. These parts provide support, stability, and allow the bike to function.';
          maintenanceTips = [
            {
              'title': 'Regular Inspection',
              'description':
                  'Check for cracks, especially around welds and stress points. Look for paint chips that might indicate impact damage.',
            },
            {
              'title': 'Cleaning',
              'description':
                  'Clean the frame regularly with a mild soap solution. Dry thoroughly and apply frame protectors to prevent cable rub.',
            },
            {
              'title': 'Bolt Check',
              'description':
                  'Check all frame bolts monthly for proper torque. This includes water bottle cages, rack mounts, and other accessories.',
            },
          ];
          break;
        case 'saddle':
          title = 'Saddle';
          imagePath = 'assets/images/rd-Saddle.png';
          description =
              'A good saddle is crucial for a comfortable and efficient riding experience, as it supports the riders weight and helps maintain proper riding posture.';
          maintenanceTips = [
            {
              'title': 'Position Check',
              'description':
                  'Check saddle position and angle monthly. Ensure it\'s level and at the correct height for your riding style.',
            },
            {
              'title': 'Cleaning',
              'description':
                  'Clean the saddle regularly with a mild soap solution. For leather saddles, use appropriate leather care products.',
            },
            {
              'title': 'Inspection',
              'description':
                  'Inspect for wear, especially in high-contact areas. Check rails for damage and ensure clamp is properly tightened.',
            },
          ];
          break;
        case 'crank':
          title = 'Crank';
          imagePath = 'assets/images/rd-Crank.png';
          description =
              'The crank is part of the bike drivetrain that connects the pedals to the bikes bottom bracket, allowing the rider to transfer power to the wheels.';
          maintenanceTips = [
            {
              'title': 'Bottom Bracket',
              'description':
                  'Check for play in the bottom bracket monthly. Clean and regrease sealed bearings every 6-12 months.',
            },
            {
              'title': 'Chainring Inspection',
              'description':
                  'Inspect chainrings for wear. Replace when teeth become hooked or sharp. Check bolt tightness monthly.',
            },
            {
              'title': 'Cleaning',
              'description':
                  'Clean crank arms and chainrings regularly. Remove and clean bottom bracket area every 3-6 months.',
            },
          ];
          break;
        case 'shifter':
          title = 'Shifter';
          imagePath = 'assets/images/rd-Shifter.png';
          description =
              'The shifter is a component on a road bike that allows the rider to change gears, controlling the bike speed and cadence. It is typically integrated into the handlebars and works in conjunction with the derailleur and chainrings.';
          maintenanceTips = [
            {
              'title': 'Cable Maintenance',
              'description':
                  'Replace shift cables and housing every 1-2 years. Lubricate cable ends and check for fraying monthly.',
            },
            {
              'title': 'Adjustment',
              'description':
                  'Check indexing monthly. Adjust barrel adjusters if shifting becomes inconsistent.',
            },
            {
              'title': 'Cleaning',
              'description':
                  'Clean shifters regularly. Use a light lubricant on moving parts. Check for proper engagement of shift levers.',
            },
          ];
          break;
      }
    } else if (selectedBike.toLowerCase() == 'mountainbike') {
      switch (partName) {
        case 'handle':
          title = 'Handle Bar';
          imagePath = 'assets/images/mb-Handle.png';
          description =
              'The MTB (mountain bike) handlebar is designed for off-road cycling and provides control, stability, and comfort on rough terrain.';
          maintenanceTips = [
            {
              'title': 'Grip Maintenance',
              'description':
                  'Check grips for wear and replace when they become smooth or torn. Clean grips regularly with soap and water.',
            },
            {
              'title': 'Stem Check',
              'description':
                  'Inspect stem bolts monthly for proper torque. Check for any play in the headset.',
            },
            {
              'title': 'Bar Inspection',
              'description':
                  'Look for cracks or damage, especially after crashes. Check bar ends are properly installed.',
            },
          ];
          break;
        case 'wheels':
          title = 'Wheels';
          imagePath = 'assets/images/mb-Wheels.png';
          description =
              'The MTB (mountain bike) wheel is designed to handle the challenges of off-road terrain, providing strength, durability, and traction.';
          maintenanceTips = [
            {
              'title': 'Tire Pressure',
              'description':
                  'Adjust pressure based on terrain: 25-35 PSI for trails, lower for technical terrain. Check for cuts and wear regularly.',
            },
            {
              'title': 'Hub Service',
              'description':
                  'Service hub bearings every 3-6 months. Clean and regrease freehub body regularly.',
            },
            {
              'title': 'Spoke Check',
              'description':
                  'Check spoke tension monthly. True wheels if they develop wobble. Inspect for broken spokes.',
            },
          ];
          break;
        case 'frame':
          title = 'Frame';
          imagePath = 'assets/images/mb-Frame.png';
          description =
              'The "Frame" of a mountainbike refers to its frame and key structural components like the fork, seatpost, handlebars, bottom bracket, and wheel stays. These parts provide support, stability, and allow the bike to function.';
          maintenanceTips = [
            {
              'title': 'Suspension Pivot',
              'description':
                  'Check pivot bearings every 3-6 months. Clean and regrease as needed. Look for play in pivots.',
            },
            {
              'title': 'Frame Inspection',
              'description':
                  'Inspect for cracks after crashes. Check all welded areas and stress points regularly.',
            },
            {
              'title': 'Cleaning',
              'description':
                  'Clean frame thoroughly after muddy rides. Check for cable rub and apply frame protectors.',
            },
          ];
          break;
        case 'saddle':
          title = 'Saddle';
          imagePath = 'assets/images/mb-Saddle.png';
          description =
              'A good saddle is crucial for a comfortable and efficient riding experience, as it supports the riders weight and helps maintain proper riding posture.';
          maintenanceTips = [
            {
              'title': 'Position Check',
              'description':
                  'Adjust saddle height and angle for optimal comfort. Check position after crashes or long rides.',
            },
            {
              'title': 'Cleaning',
              'description':
                  'Clean saddle after muddy rides. Check for damage from impacts or crashes.',
            },
            {
              'title': 'Rail Inspection',
              'description':
                  'Check rails for damage. Ensure clamp is properly tightened and aligned.',
            },
          ];
          break;
        case 'crank':
          title = 'Crank';
          imagePath = 'assets/images/mb-Crank.png';
          description =
              'The crank is part of the bike drivetrain that connects the pedals to the bikes bottom bracket, allowing the rider to transfer power to the wheels.';
          maintenanceTips = [
            {
              'title': 'Bottom Bracket',
              'description':
                  'Check for play monthly. Service sealed bearings every 6-12 months. Clean and regrease as needed.',
            },
            {
              'title': 'Chainring Care',
              'description':
                  'Inspect teeth for wear. Clean after muddy rides. Check bolt tightness regularly.',
            },
            {
              'title': 'Pedal Maintenance',
              'description':
                  'Check pedal bearings monthly. Clean cleats or platform surfaces regularly.',
            },
          ];
          break;
        case 'shifter':
          title = 'Shifter';
          imagePath = 'assets/images/mb-Shifter.png';
          description =
              'The shifter is a component on a road bike that allows the rider to change gears, controlling the bike speed and cadence. It is typically integrated into the handlebars and works in conjunction with the derailleur and chainrings.';
          maintenanceTips = [
            {
              'title': 'Cable Care',
              'description':
                  'Replace cables and housing yearly. Clean and lubricate regularly. Check for fraying.',
            },
            {
              'title': 'Adjustment',
              'description':
                  'Check indexing monthly. Adjust limit screws if needed. Test shifting under load.',
            },
            {
              'title': 'Cleaning',
              'description':
                  'Clean shifters after muddy rides. Lubricate moving parts with appropriate lube.',
            },
          ];
          break;
      }
    } else if (selectedBike.toLowerCase() == 'fixie') {
      switch (partName) {
        case 'handle':
          title = 'Handle Bar';
          imagePath = 'assets/images/fx-Handle.png';
          description =
              'A curved handlebar with a downward sloping design that allows cyclists to grip the bars in multiple positions (on the tops, hoods, or drops) depending on the terrain and desired riding posture.';
          maintenanceTips = [
            {
              'title': 'Grip Check',
              'description':
                  'Inspect bar tape or grips for wear. Replace when worn or loose. Clean regularly.',
            },
            {
              'title': 'Stem Inspection',
              'description':
                  'Check stem bolts monthly. Ensure handlebar is properly aligned and secured.',
            },
            {
              'title': 'Bar Care',
              'description':
                  'Clean handlebars regularly. Check for damage or bends after impacts.',
            },
          ];
          break;
        case 'wheels':
          title = 'Wheels';
          imagePath = 'assets/images/fx-Wheels.png';
          description =
              'Rims for road bikes play a crucial role in performance, durability, and weight. They are the structural component of the wheel that holds the tire and connects to the spokes and hub.';
          maintenanceTips = [
            {
              'title': 'Tire Pressure',
              'description':
                  'Check pressure before every ride. Fixie tires typically need 80-120 PSI. Inspect for wear.',
            },
            {
              'title': 'Hub Maintenance',
              'description':
                  'Check hub bearings monthly. Clean and regrease as needed. Look for play in the hub.',
            },
            {
              'title': 'Spoke Care',
              'description':
                  'Check spoke tension regularly. True wheels if they develop wobble. Inspect for damage.',
            },
          ];
          break;
        case 'frame':
          title = 'Frame';
          imagePath = 'assets/images/fx-Frame.png';
          description =
              'The "Frame" of a road bike refers to its frame and key structural components like the fork, seatpost, handlebars, bottom bracket, and wheel stays. These parts provide support, stability, and allow the bike to function.';
          maintenanceTips = [
            {
              'title': 'Frame Inspection',
              'description':
                  'Check for cracks or damage monthly. Inspect welds and stress points regularly.',
            },
            {
              'title': 'Cleaning',
              'description':
                  'Clean frame regularly. Check for cable rub and apply protectors where needed.',
            },
            {
              'title': 'Bolt Check',
              'description':
                  'Check all frame bolts monthly. Ensure proper torque on all fasteners.',
            },
          ];
          break;
        case 'saddle':
          title = 'Saddle';
          imagePath = 'assets/images/fx-Saddle.png';
          description =
              'A good saddle is crucial for a comfortable and efficient riding experience, as it supports the riders weight and helps maintain proper riding posture.';
          maintenanceTips = [
            {
              'title': 'Position Check',
              'description':
                  'Check saddle height and angle monthly. Adjust for optimal comfort and efficiency.',
            },
            {
              'title': 'Cleaning',
              'description':
                  'Clean saddle regularly. For leather saddles, use appropriate care products.',
            },
            {
              'title': 'Rail Care',
              'description':
                  'Inspect rails for damage. Check clamp tightness and alignment monthly.',
            },
          ];
          break;
        case 'crank':
          title = 'Crank';
          imagePath = 'assets/images/fx-Crank.png';
          description =
              'The crank is part of the bikes drivetrain that connects the pedals to the bikes bottom bracket, allowing the rider to transfer power to the wheels.';
          maintenanceTips = [
            {
              'title': 'Bottom Bracket',
              'description':
                  'Check for play monthly. Clean and regrease bearings every 6-12 months.',
            },
            {
              'title': 'Chainring Care',
              'description':
                  'Inspect teeth for wear. Clean regularly. Check bolt tightness monthly.',
            },
            {
              'title': 'Pedal Maintenance',
              'description':
                  'Check pedal bearings monthly. Clean cleats or platforms regularly.',
            },
          ];
          break;
        case 'brake':
          title = 'Break';
          imagePath = 'assets/images/fx-Break.png';
          description =
              'Brakes on a bike are essential for Stopping: To slow down or bring the bike to a complete stop. Control Helps maintain speed and navigate safely, especially on descents or sharp turns. Safety: Provides the ability to react to obstacles or changes in terrain. Handling: Allows precise adjustments in speed for better bike handling.';
          maintenanceTips = [
            {
              'title': 'Pad Inspection',
              'description':
                  'Check brake pads monthly. Replace when worn to 1mm or less. Clean rims regularly.',
            },
            {
              'title': 'Cable Care',
              'description':
                  'Replace cables yearly. Lubricate cable ends. Check for fraying monthly.',
            },
            {
              'title': 'Adjustment',
              'description':
                  'Check brake alignment monthly. Adjust cable tension if brakes feel spongy.',
            },
          ];
          break;
      }
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                Hero(
                  tag: 'part_$partName',
                  child: Image.asset(
                    imagePath,
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        isDarkMode ? const Color(0xFF2D2D2D) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isDarkMode ? const Color(0xFF4A3B7C) : Colors.brown,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    description,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Maintenance Tips',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                ...maintenanceTips
                    .map((tip) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tip['title']!,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tip['description']!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Close',
                    style: TextStyle(
                      color:
                          isDarkMode ? const Color(0xFF4A3B7C) : Colors.brown,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    List<String> titles = BikeUtils.getTitles(selectedBike);
    List<String> images = BikeUtils.getImages(selectedBike);

    return Container(
      padding: const EdgeInsets.all(16),
      color: isDarkMode ? const Color(0xFF121212) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SwipeableBikeSelector(
            currentBikeType: selectedBike,
            isLoading: _isLoading,
            onBikeChanged: (newBike) async {
              setState(() => _isLoading = true);
              try {
                await FirebaseFirestore.instance
                    .collection('user_preferences')
                    .doc(FirebaseAuth.instance.currentUser?.uid)
                    .update({'bike_type': newBike});
                changeBike(newBike);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating bike type: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() => _isLoading = false);
                }
              }
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: BikePartsGrid(
                        titles: titles,
                        images: images,
                        onPartTap: (index) =>
                            navigateToPartInfo(context, index),
                        isDarkMode: isDarkMode,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class SwipeableBikeSelector extends StatefulWidget {
  final String currentBikeType;
  final Function(String) onBikeChanged;
  final bool isLoading;

  const SwipeableBikeSelector({
    Key? key,
    required this.currentBikeType,
    required this.onBikeChanged,
    required this.isLoading,
  }) : super(key: key);

  @override
  State<SwipeableBikeSelector> createState() => _SwipeableBikeSelectorState();
}

class _SwipeableBikeSelectorState extends State<SwipeableBikeSelector> {
  late PageController _pageController;
  late int _currentPage;
  final List<String> _bikeTypes = ['ROADBIKE', 'MOUNTAINBIKE', 'FIXIE'];

  @override
  void initState() {
    super.initState();
    _currentPage = _bikeTypes.indexOf(widget.currentBikeType.toUpperCase());
    _pageController = PageController(
      initialPage: _currentPage,
      viewportFraction: 0.8,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    widget.onBikeChanged(_bikeTypes[page]);
  }

  String _getBikeDescription(String bikeType) {
    switch (bikeType.toLowerCase()) {
      case 'roadbike':
        return 'Road bikes are designed for speed and efficiency on paved roads. They feature lightweight frames, narrow tires, and drop handlebars for an aerodynamic riding position. Perfect for long-distance riding, racing, and fitness training.';
      case 'mountainbike':
        return 'Mountain bikes are built for off-road cycling on rough terrain. They feature wide, knobby tires, suspension systems, and flat handlebars for better control. Ideal for trail riding, mountain biking, and technical terrain.';
      case 'fixie':
        return 'Fixed-gear bikes, or fixies, are simple and lightweight bicycles with a fixed drivetrain. They have no freewheel mechanism, meaning the pedals are always in motion when the bike is moving. Popular for urban commuting and track cycling.';
      default:
        return 'Select a bike type to view its description.';
    }
  }

  void _showBikeInfo(BuildContext context, String bikeType) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  bikeType,
                  style: AppFonts.bold.copyWith(
                    fontSize: 24,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                Hero(
                  tag: 'bike_${bikeType.toLowerCase()}',
                  child: Image.asset(
                    'assets/images/${bikeType.toLowerCase()}.png',
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        isDarkMode ? const Color(0xFF2D2D2D) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isDarkMode ? const Color(0xFF4A3B7C) : Colors.brown,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getBikeDescription(bikeType),
                    style: AppFonts.regular.copyWith(
                      fontSize: 16,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Maintenance & Repair Tips',
                  style: AppFonts.bold.copyWith(
                    fontSize: 18,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        isDarkMode ? const Color(0xFF2D2D2D) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isDarkMode ? const Color(0xFF4A3B7C) : Colors.brown,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _getMaintenanceTips(bikeType, isDarkMode),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Close',
                    style: AppFonts.bold.copyWith(
                      color:
                          isDarkMode ? const Color(0xFF4A3B7C) : Colors.brown,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _getMaintenanceTips(String bikeType, bool isDarkMode) {
    final List<Map<String, String>> tips = _getBikeMaintenanceTips(bikeType);

    return tips.map((tip) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tip['title']!,
              style: AppFonts.bold.copyWith(
                fontSize: 16,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              tip['description']!,
              style: AppFonts.regular.copyWith(
                fontSize: 14,
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Map<String, String>> _getBikeMaintenanceTips(String bikeType) {
    switch (bikeType.toLowerCase()) {
      case 'roadbike':
        return [
          {
            'title': 'Tire Pressure',
            'description':
                'Road bike tires should be inflated to 80-130 PSI. Check pressure before every ride and top off if needed. Proper inflation reduces rolling resistance and prevents pinch flats.',
          },
          {
            'title': 'Chain Maintenance',
            'description':
                'Clean and lubricate your chain every 200-300 miles. Use a degreaser to clean, then apply a light lubricant. Wipe off excess to prevent dirt buildup. Replace chain every 2,000-3,000 miles.',
          },
          {
            'title': 'Brake Adjustment',
            'description':
                'Check brake pads for wear and alignment. Adjust cable tension if brakes feel spongy. Replace pads when they show significant wear or become glazed. Test brakes before every ride.',
          },
          {
            'title': 'Derailleur Tuning',
            'description':
                'If shifting is inconsistent, check derailleur alignment and cable tension. Clean jockey wheels regularly. Replace cables and housing every 1,000-2,000 miles for smooth shifting.',
          },
          {
            'title': 'Wheel Truing',
            'description':
                'Check wheel trueness monthly. Use a truing stand or have a shop true wheels if they wobble. Loose spokes should be tightened to maintain wheel integrity and prevent further damage.',
          },
        ];
      case 'mountainbike':
        return [
          {
            'title': 'Suspension Maintenance',
            'description':
                'Clean stanchions after every ride. Check air pressure in air-sprung forks monthly. Service suspension every 50-100 hours of riding. Replace seals annually for optimal performance.',
          },
          {
            'title': 'Tire Pressure & Tread',
            'description':
                'Adjust tire pressure based on terrain: 25-35 PSI for trails, lower for technical terrain. Check for cuts and wear regularly. Rotate tires to extend life. Replace when tread is worn.',
          },
          {
            'title': 'Brake Bleeding',
            'description':
                'Hydraulic disc brakes need bleeding every 6-12 months. Check fluid level and condition. Replace pads when they\'re 1mm thick or less. Clean rotors with isopropyl alcohol.',
          },
          {
            'title': 'Frame Inspection',
            'description':
                'Inspect frame for cracks, especially around welds and stress points, after crashes or hard impacts. Check for loose bolts on all components. Tighten to manufacturer specifications.',
          },
          {
            'title': 'Drivetrain Cleaning',
            'description':
                'Clean drivetrain after muddy rides. Use a degreaser and brush to clean chain, cassette, and chainrings. Lubricate with wet or dry lube depending on conditions. Replace worn components.',
          },
        ];
      case 'fixie':
        return [
          {
            'title': 'Chain Tension',
            'description':
                'Fixed-gear chains must be properly tensioned to prevent skipping or derailing. Check tension weekly. Adjust using horizontal dropouts or chain tensioners. Chain should have 1/2" of play.',
          },
          {
            'title': 'Brake Maintenance',
            'description':
                'Even with a fixed drivetrain, brakes are essential for safety. Check brake pads monthly and replace when worn. Adjust cable tension for responsive braking. Test before every ride.',
          },
          {
            'title': 'Cog and Chainring Wear',
            'description':
                'Inspect teeth for wear patterns. Replace cog and chainring when teeth become hooked or sharp. Clean regularly to prevent accelerated wear. Use compatible components for proper engagement.',
          },
          {
            'title': 'Wheel Alignment',
            'description':
                'Check wheel alignment in dropouts. Wheels should be centered and properly secured. Inspect lockring tightness monthly. Use a lockring tool to prevent cog slippage.',
          },
          {
            'title': 'Pedal Maintenance',
            'description':
                'Check pedal bearings for smooth rotation. Tighten pedals to crank arms with proper torque. Replace worn cleats or straps. Clean and lubricate pedal mechanisms regularly.',
          },
        ];
      default:
        return [
          {
            'title': 'General Maintenance',
            'description':
                'Regular maintenance is essential for all bikes. Check tire pressure, chain lubrication, and brake function before every ride. Clean your bike after muddy or wet conditions.',
          },
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Column(
      children: [
        SizedBox(
          height: 120,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: _bikeTypes.length,
            itemBuilder: (context, index) {
              final bikeType = _bikeTypes[index];
              final isSelected = index == _currentPage;

              return GestureDetector(
                onTap: () => _showBikeInfo(context, bikeType),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: isSelected ? 0 : 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: isDarkMode
                                  ? const Color(0xFF4A3B7C).withOpacity(0.3)
                                  : Colors.brown.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : null,
                    border: Border.all(
                      color: isSelected
                          ? (isDarkMode
                              ? const Color(0xFF4A3B7C)
                              : Colors.brown)
                          : (isDarkMode
                              ? Colors.grey[800]!
                              : Colors.grey[300]!),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            bikeType,
                            style: AppFonts.bold.copyWith(
                              fontSize: isSelected ? 18 : 14,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.info_outline,
                            size: isSelected ? 16 : 14,
                            color: isDarkMode
                                ? const Color(0xFF4A3B7C)
                                : Colors.brown,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Hero(
                        tag: 'bike_${bikeType.toLowerCase()}',
                        child: Image.asset(
                          'assets/images/${bikeType.toLowerCase()}.png',
                          height: 60,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _bikeTypes.length,
            (index) => Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index == _currentPage
                    ? (isDarkMode ? const Color(0xFF4A3B7C) : Colors.brown)
                    : (isDarkMode ? Colors.grey[700] : Colors.grey[300]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// New bike selection widget for new users
class BikeSelectionScreen extends StatelessWidget {
  final Function(String) onBikeSelected;
  
  const BikeSelectionScreen({Key? key, required this.onBikeSelected}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Select Your Bike Type",
              style: AppFonts.bold.copyWith(
                fontSize: 24,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Choose the type of bike you're using to see relevant tools and information",
              style: AppFonts.regular.copyWith(
                fontSize: 16,
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 30),
            _buildBikeOption(
              context, 
              "ROADBIKE", 
              "assets/images/roadbike.png",
              "Road bikes are optimized for speed on paved roads",
              isDarkMode
            ),
            const SizedBox(height: 20),
            _buildBikeOption(
              context, 
              "MOUNTAINBIKE", 
              "assets/images/mountainbike.png",
              "Mountain bikes are built for off-road terrain and trails",
              isDarkMode
            ),
            const SizedBox(height: 20),
            _buildBikeOption(
              context, 
              "FIXIE", 
              "assets/images/fixie.png",
              "Fixed-gear bikes (fixies) feature simple, minimalist design",
              isDarkMode
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBikeOption(BuildContext context, String type, String imagePath, String description, bool isDarkMode) {
    return GestureDetector(
      onTap: () => onBikeSelected(type),
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.asset(
                imagePath,
                height: 180,
                width: double.infinity,
                fit: BoxFit.contain,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type,
                    style: AppFonts.bold.copyWith(
                      fontSize: 18,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: AppFonts.regular.copyWith(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF4A3B7C) : AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Select This Bike",
                      style: AppFonts.medium.copyWith(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AppBarIcon(
            icon: Icons.person_outline,
            onTap: () {},
          );
        }

        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        return ProfileAppBarIcon(
          profileUrl: userData?['profileUrl'],
          userName: userData?['userName'],
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
          },
        );
      },
    );
  }
}
