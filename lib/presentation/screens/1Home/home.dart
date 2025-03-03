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

// Task model to store task data
class Task {
  final String title;
  final String description;
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool isAllDay;
  final String repeatStatus;
  final Color color;
  bool completed;

  Task({
    required this.title,
    required this.description,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.isAllDay,
    required this.repeatStatus,
    required this.color,
    this.completed = false,
  });
}

class HomePageContent extends StatefulWidget {
  const HomePageContent({super.key});

  @override
  _HomePageContentState createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  DateTime? selectedDate;
  bool isAllDay = false;
  String repeatStatus = "None"; // Default value for dropdown
  String selectedValue = "Daily"; // Default value for dropdown
  String selectedValue2 = "Weekly"; // Default value for dropdown
  String selectedValue3 = "Monthly"; // Default value for dropdown

  // Add controllers for text fields
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Add time selection variables
  TimeOfDay _startTime = TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = TimeOfDay(hour: 9, minute: 0);

  // Add color selection
  Color _selectedColor = Colors.black;
  final List<Color> _colorOptions = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.brown,
    Colors.black,
  ];

  // List to store tasks
  List<Task> tasks = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

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
      body: tasks.isEmpty
          ? const Center(child: Text("Welcome to Home Page"))
          : ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: task.color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    title: Text(
                      task.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        decoration:
                            task.completed ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: Text(
                      '${DateFormat('EEEE, MMMM d').format(task.date)} • ${_formatTimeOfDay(task.startTime)} - ${_formatTimeOfDay(task.endTime)}',
                      style: TextStyle(
                        color: Colors.white70,
                        decoration:
                            task.completed ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    trailing: Transform.scale(
                      scale: 1.2,
                      child: Checkbox(
                        value: task.completed,
                        onChanged: (bool? value) {
                          setState(() {
                            tasks[index].completed = value ?? false;
                          });
                        },
                        checkColor: task.color,
                        fillColor: MaterialStateProperty.resolveWith<Color>(
                          (Set<MaterialState> states) {
                            if (states.contains(MaterialState.selected)) {
                              return Colors.white;
                            }
                            return Colors.white.withOpacity(0.5);
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
      // Floating Action Button (+)
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        child: Icon(Icons.add, color: Colors.white),
        onPressed: () {
          // Reset values when opening the modal
          _titleController.clear();
          _descriptionController.clear();
          setState(() {
            selectedDate = DateTime.now();
            isAllDay = false;
            repeatStatus = "None";
            _startTime = TimeOfDay(hour: 9, minute: 0);
            _endTime = TimeOfDay(hour: 9, minute: 0);
            _selectedColor = Colors.black;
          });

          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) {
              return StatefulBuilder(
                builder: (context, setModalState) {
                  return SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                        left: 16,
                        right: 16,
                        top: 16,
                      ),
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
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              TextButton(
                                onPressed: () {
                                  // Create a new task and add it to the list
                                  final newTask = Task(
                                    title: _titleController.text.isEmpty
                                        ? "Untitled Task"
                                        : _titleController.text,
                                    description: _descriptionController.text,
                                    date: selectedDate ?? DateTime.now(),
                                    startTime: _startTime,
                                    endTime: _endTime,
                                    isAllDay: isAllDay,
                                    repeatStatus: repeatStatus,
                                    color: _selectedColor,
                                  );

                                  setState(() {
                                    tasks.add(newTask);
                                  });

                                  Navigator.pop(context);
                                },
                                child: Text("Save",
                                    style: TextStyle(color: Colors.green)),
                              ),
                            ],
                          ),

                          TextField(
                            controller: _titleController,
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
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Time Row
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    GestureDetector(
                                      onTap: () async {
                                        final TimeOfDay? picked =
                                            await showTimePicker(
                                          context: context,
                                          initialTime: _startTime,
                                        );
                                        if (picked != null) {
                                          setModalState(() {
                                            _startTime = picked;
                                          });
                                        }
                                      },
                                      child: Chip(
                                        label:
                                            Text(_formatTimeOfDay(_startTime)),
                                      ),
                                    ),
                                    Icon(Icons.arrow_right_alt),
                                    GestureDetector(
                                      onTap: () async {
                                        final TimeOfDay? picked =
                                            await showTimePicker(
                                          context: context,
                                          initialTime: _endTime,
                                        );
                                        if (picked != null) {
                                          setModalState(() {
                                            _endTime = picked;
                                          });
                                        }
                                      },
                                      child: Chip(
                                        label: Text(_formatTimeOfDay(_endTime)),
                                      ),
                                    ),
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
                                      initialDate:
                                          selectedDate ?? DateTime.now(),
                                      firstDate: DateTime(1999),
                                      lastDate: DateTime(
                                          2030), // Changed from 2025 to 2030 to ensure it's after any possible initialDate
                                    );

                                    if (pickedDate != null) {
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

                                // Color Selection
                                Container(
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  margin: EdgeInsets.symmetric(vertical: 5),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              left: 8.0, bottom: 8.0),
                                          child: Row(
                                            children: [
                                              Icon(Icons.color_lens),
                                              SizedBox(width: 16),
                                              Text("Color",
                                                  style:
                                                      TextStyle(fontSize: 16)),
                                            ],
                                          ),
                                        ),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: _colorOptions.map((color) {
                                            return GestureDetector(
                                              onTap: () {
                                                setModalState(() {
                                                  _selectedColor = color;
                                                });
                                              },
                                              child: Container(
                                                width: 36,
                                                height: 36,
                                                decoration: BoxDecoration(
                                                  color: color,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: _selectedColor ==
                                                            color
                                                        ? Colors.white
                                                        : Colors.transparent,
                                                    width: 2,
                                                  ),
                                                  boxShadow: _selectedColor ==
                                                          color
                                                      ? [
                                                          BoxShadow(
                                                            color: Colors.black
                                                                .withOpacity(
                                                                    0.3),
                                                            blurRadius: 4,
                                                            spreadRadius: 1,
                                                          )
                                                        ]
                                                      : null,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 10),

                          TextField(
                            controller: _descriptionController,
                            decoration: InputDecoration(
                              hintText: "Description",
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
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

  // Helper method to format TimeOfDay
  String _formatTimeOfDay(TimeOfDay timeOfDay) {
    final now = DateTime.now();
    final dateTime = DateTime(
        now.year, now.month, now.day, timeOfDay.hour, timeOfDay.minute);
    final format =
        DateFormat.jm(); // This will give you the time in AM/PM format
    return format.format(dateTime);
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
          items: ["None", "Daily", "Weekly", "Monthly"].map((String value) {
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
