import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:velora/presentation/screens/0Auth/profile.dart';
import 'package:velora/presentation/screens/2ToolBox/toolbox.dart';
import 'package:velora/presentation/screens/3News/newsfeed.dart';
import 'package:velora/presentation/screens/4Chat/chat.dart';
import 'package:velora/presentation/screens/5Settings/setting_screen.dart';
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


//ANIMATED NAVIGATION BAR
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
//END HERE
}

class HomePageContent extends StatefulWidget {
  const HomePageContent({super.key});

  @override
  _HomePageContentState createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  DateTime? selectedDate;
  bool isAllDay = false;
  String repeatStatus = "Not Repeat"; // Default value for dropdown

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: MyAppBar(
        title: "Home",
        actions: [
          AppBarIcon(
              icon: Icons.cloud_outlined, onTap: () => print("Weather Tapped")),
          AppBarIcon(
              icon: Icons.notifications_outlined,
              onTap: () => print("Notifications Tapped")),
          AppBarIcon(
              icon: Icons.person_outline,
              onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfilePage()),
                  )),
        ],
      ),
      body: const Center(child: Text("Welcome to Home Page")),
      // Floating Action Button (+)
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        child: Icon(Icons.add, color: Colors.white),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) {
              return StatefulBuilder(
                builder: (context, setModalState) {
                  return Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text("Cancel",
                                  style: TextStyle(color: Colors.red)),
                            ),
                            Text("New Event",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            TextButton(
                              onPressed: () {},
                              child: Text("Save",
                                  style: TextStyle(color: Colors.green)),
                            ),
                          ],
                        ),

                        TextField(
                          decoration: InputDecoration(
                            hintText: "Enter plan",
                            border: OutlineInputBorder(),
                          ),
                        ),

                        SizedBox(height: 10),

                        // Event Details Container
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              // Time Row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Chip(label: Text("09:00")),
                                  Icon(Icons.arrow_right_alt),
                                  Chip(label: Text("09:00")),
                                ],
                              ),

                              // Date Picker
                              _buildTile(
                                icon: Icons.calendar_today,
                                text: selectedDate != null
                                    ? DateFormat('EEEE, MMMM d')
                                        .format(selectedDate!)
                                    : "Thursday, December 5",
                                onTap: () async {
                                  DateTime? pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate ?? DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2101),
                                  );

                                  if (pickedDate != selectedDate) {
                                    setModalState(() {
                                      selectedDate = pickedDate;
                                    });
                                  }
                                },
                              ),

                              // All Day Toggle (Now Works!)
                              _buildSwitchTile(
                                icon: Icons.access_time,
                                text: "All day",
                                value: isAllDay,
                                onChanged: (val) {
                                  setModalState(() {
                                    isAllDay = val;
                                  });
                                },
                              ),

                              // Repeat Dropdown (Replaces Old Toggle)
                              _buildDropdownTile(
                                icon: Icons.refresh,
                                selectedValue: repeatStatus,
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setModalState(() {
                                      repeatStatus = newValue;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 10),

                        TextField(
                          decoration: InputDecoration(
                            hintText: "Description",
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // Custom Tile with border styling
  Widget _buildTile(
      {required IconData icon, required String text, VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300), // Adds border
        borderRadius: BorderRadius.circular(10),
      ),
      margin: EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        leading: Icon(icon),
        title: Text(text),
        onTap: onTap,
        trailing: Icon(Icons.arrow_forward_ios, size: 18),
      ),
    );
  }

  // Custom Switch Tile with border
  Widget _buildSwitchTile(
      {required IconData icon,
      required String text,
      required bool value,
      required Function(bool) onChanged}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300), // Adds border
        borderRadius: BorderRadius.circular(10),
      ),
      margin: EdgeInsets.symmetric(vertical: 5),
      child: SwitchListTile(
        title: Text(text),
        value: value,
        onChanged: onChanged,
        secondary: Icon(icon),
      ),
    );
  }

  // Custom Dropdown Tile for "Repeat" selection
  Widget _buildDropdownTile(
      {required IconData icon,
      required String selectedValue,
      required Function(String?) onChanged}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      margin: EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        leading: Icon(icon),
        title: DropdownButton<String>(
          value: selectedValue,
          items: ["Not Repeat", "Repeat"].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: onChanged,
          underline: SizedBox(),
        ),
      ),
    );
  }
}
