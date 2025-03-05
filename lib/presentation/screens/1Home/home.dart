import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:velora/presentation/screens/0Auth/profile.dart';
import 'package:velora/presentation/screens/2ToolBox/toolbox.dart';
import 'package:velora/presentation/screens/3News/newsfeed.dart';
import 'package:velora/presentation/screens/4Chat/chat_list.dart';
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
    const ChatListPage(),
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

// Event model to store event data
class Event {
  final String title;
  final String description;
  final DateTime date; // The date associated with the event
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool isAllDay;
  final String repeatStatus;
  final Color color;
  final String id; // Add an ID to uniquely identify each event

  Event({
    required this.title,
    required this.description,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.isAllDay,
    required this.repeatStatus,
    required this.color,
    required this.id,
  });

  // Create a copy of the event with updated fields
  Event copyWith({
    String? title,
    String? description,
    DateTime? date,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    bool? isAllDay,
    String? repeatStatus,
    Color? color,
  }) {
    return Event(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isAllDay: isAllDay ?? this.isAllDay,
      repeatStatus: repeatStatus ?? this.repeatStatus,
      color: color ?? this.color,
    );
  }
}

class HomePageContent extends StatefulWidget {
  const HomePageContent({super.key});

  @override
  _HomePageContentState createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  DateTime _selectedDate = DateTime.now(); // Default to today's date
  final List<Event> _events = []; // List to store all events

  List<DateTime> getWeekDays(DateTime date) {
    int weekday = date.weekday; // Monday = 1, Sunday = 7
    DateTime sunday = date.subtract(Duration(days: weekday % 7));
    return List.generate(7, (index) => sunday.add(Duration(days: index)));
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date; // Update selected date
    });
  }

  Future<void> _pickDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked; // Updates the selected date from picker
      });
    }
  }

  // Delete an event
  void _deleteEvent(String eventId) {
    setState(() {
      _events.removeWhere((event) => event.id == eventId);
    });
  }

  // Show delete confirmation dialog
  Future<void> _showDeleteConfirmation(
      BuildContext context, Event event) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button to close dialog
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Event'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete "${event.title}"?'),
                Text('This action cannot be undone.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                _deleteEvent(event.id);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${event.title} deleted'),
                    action: SnackBarAction(
                      label: 'UNDO',
                      onPressed: () {
                        setState(() {
                          _events.add(event);
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // Edit an event
  void _editEvent(Event event) {
    showNewEventModal(context, existingEvent: event);
  }

  @override
  Widget build(BuildContext context) {
    List<DateTime> weekDays = getWeekDays(_selectedDate);

    // Filter events for the currently selected date
    List<Event> filteredEvents = _events.where((event) {
      return event.date.year == _selectedDate.year &&
          event.date.month == _selectedDate.month &&
          event.date.day == _selectedDate.day;
    }).toList();

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
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showNewEventModal(context);
        },
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Weekly Progress Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 211, 209, 209),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Your Weekly Progress",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _progressItem("Activities", "0"),
                      _progressItem("Time", "0h 0m"),
                      _progressItem("Distance", "0.00km"),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Calendar Header with Menu Icon & Clickable Date
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.0, vertical: 1.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => print("Menu Clicked"),
                ),
                GestureDetector(
                  onTap: () => _pickDate(context), // Opens Date Picker
                  child: Row(
                    children: [
                      const SizedBox(width: 4), // Small spacing
                      Text(
                        DateFormat.yMMMM()
                            .format(_selectedDate), // Example: "March 2025"
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Icon(Icons.arrow_drop_down), // Dropdown indicator
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Weekday Labels + Dates (Clickable)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 255, 255, 255),
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (index) {
                DateTime currentDate = weekDays[index];
                bool isSelected = _selectedDate.day == currentDate.day &&
                    _selectedDate.month == currentDate.month &&
                    _selectedDate.year == currentDate.year;

                // Check if there are events on this day
                bool hasEvents = _events.any((event) =>
                    event.date.day == currentDate.day &&
                    event.date.month == currentDate.month &&
                    event.date.year == currentDate.year);

                return GestureDetector(
                  onTap: () => _onDateSelected(currentDate),
                  child: Column(
                    children: [
                      Text(
                        DateFormat.E()
                            .format(currentDate), // "Sun", "Mon", etc.
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.brown
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              currentDate.day.toString(), // "20", "21", etc.
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          if (hasEvents)
                            Positioned(
                              bottom: 0,
                              child: Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),

          // Display Events for the Selected Date
          Expanded(
            child: filteredEvents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_note, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          "No Tasks for ${DateFormat('EEEE, MMMM d').format(_selectedDate)}",
                          style: TextStyle(color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Tap + to add a new Task",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredEvents.length,
                    itemBuilder: (context, index) {
                      Event event = filteredEvents[index];
                      return Dismissible(
                        key: Key(event.id),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.only(right: 20),
                          child: Icon(Icons.delete, color: Colors.white),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) {
                          _deleteEvent(event.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${event.title} deleted'),
                              action: SnackBarAction(
                                label: 'UNDO',
                                onPressed: () {
                                  setState(() {
                                    _events.add(event);
                                  });
                                },
                              ),
                            ),
                          );
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          color: event
                              .color, // Use the event's color as the card background
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        event.title,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        // Edit button
                                        IconButton(
                                          icon: Icon(Icons.edit, size: 20),
                                          onPressed: () => _editEvent(event),
                                          padding: EdgeInsets.zero,
                                          constraints: BoxConstraints(),
                                        ),
                                        SizedBox(
                                            width: 16), // Space between buttons
                                        // Delete button
                                        IconButton(
                                          icon: Icon(Icons.delete, size: 20),
                                          onPressed: () =>
                                              _showDeleteConfirmation(
                                                  context, event),
                                          padding: EdgeInsets.zero,
                                          constraints: BoxConstraints(),
                                          color: Colors.red[700],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                    "${DateFormat('EEEE, MMMM d').format(event.date)} | ${_formatTimeOfDay(event.startTime)} - ${_formatTimeOfDay(event.endTime)}"),
                                const SizedBox(height: 4),
                                Text(event.description),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _progressItem(String title, String value) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16)),
        const Icon(Icons.arrow_drop_up, color: Colors.black54),
        const Text("0"),
      ],
    );
  }

  String _formatTimeOfDay(TimeOfDay timeOfDay) {
    final now = DateTime.now();
    final dateTime = DateTime(
        now.year, now.month, now.day, timeOfDay.hour, timeOfDay.minute);
    final format =
        DateFormat.jm(); // This will give you the time in AM/PM format
    return format.format(dateTime);
  }

  void showNewEventModal(BuildContext context, {Event? existingEvent}) {
    // If editing an existing event, use its values, otherwise use defaults
    DateTime selectedDate = existingEvent?.date ?? _selectedDate;
    bool isAllDay = existingEvent?.isAllDay ?? false;
    String repeatStatus = existingEvent?.repeatStatus ?? "None";
    TimeOfDay startTime = existingEvent?.startTime ?? TimeOfDay.now();
    TimeOfDay endTime = existingEvent?.endTime ??
        TimeOfDay(
            hour: TimeOfDay.now().hour + 1, minute: TimeOfDay.now().minute);
    Color selectedColor = existingEvent?.color ?? Colors.blue; // Default color

    // Controllers for text fields
    final TextEditingController titleController =
        TextEditingController(text: existingEvent?.title ?? "");
    final TextEditingController descriptionController =
        TextEditingController(text: existingEvent?.description ?? "");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
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
                          child: const Text("Cancel",
                              style: TextStyle(color: Colors.red)),
                        ),
                        Text(
                          existingEvent != null ? "Edit Task" : "New Task",
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () {
                            if (existingEvent != null) {
                              // Update existing event
                              final updatedEvent = existingEvent.copyWith(
                                title: titleController.text.isEmpty
                                    ? "Untitled Task"
                                    : titleController.text,
                                description: descriptionController.text,
                                date: selectedDate,
                                startTime: startTime,
                                endTime: endTime,
                                isAllDay: isAllDay,
                                repeatStatus: repeatStatus,
                                color: selectedColor,
                              );

                              setState(() {
                                // Find and replace the existing event
                                final index = _events.indexWhere(
                                    (e) => e.id == existingEvent.id);
                                if (index != -1) {
                                  _events[index] = updatedEvent;
                                }
                              });
                            } else {
                              // Create a new event
                              final newEvent = Event(
                                id: DateTime.now()
                                    .millisecondsSinceEpoch
                                    .toString(), // Generate a unique ID
                                title: titleController.text.isEmpty
                                    ? "Untitled Task"
                                    : titleController.text,
                                description: descriptionController.text,
                                date: selectedDate,
                                startTime: startTime,
                                endTime: endTime,
                                isAllDay: isAllDay,
                                repeatStatus: repeatStatus,
                                color: selectedColor, // Save the selected color
                              );

                              setState(() {
                                _events.add(
                                    newEvent); // Add the new event to the list
                              });
                            }

                            Navigator.pop(context);
                          },
                          child: const Text("Save",
                              style: TextStyle(color: Colors.green)),
                        ),
                      ],
                    ),

                    // Event Title Input
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        hintText: "Enter event title",
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Event Details Container
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          // Time Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildTimeButton(
                                startTime.format(context),
                                onTap: () async {
                                  TimeOfDay? pickedTime = await showTimePicker(
                                    context: context,
                                    initialTime: startTime,
                                  );
                                  if (pickedTime != null) {
                                    setModalState(() {
                                      startTime = pickedTime;
                                    });
                                  }
                                },
                              ),
                              const Icon(Icons.arrow_right_alt),
                              _buildTimeButton(
                                endTime.format(context),
                                onTap: () async {
                                  TimeOfDay? pickedTime = await showTimePicker(
                                    context: context,
                                    initialTime: endTime,
                                  );
                                  if (pickedTime != null) {
                                    setModalState(() {
                                      endTime = pickedTime;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),

                          // Date Picker
                          _buildTile(
                            icon: Icons.calendar_today,
                            text:
                                DateFormat('EEEE, MMMM d').format(selectedDate),
                            onTap: () async {
                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (pickedDate != null &&
                                  pickedDate != selectedDate) {
                                setModalState(() {
                                  selectedDate = pickedDate;
                                });
                              }
                            },
                          ),

                          // All Day Toggle
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

                          // Repeat Dropdown
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

                    const SizedBox(height: 10),

                    // Description Field
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          hintText: "Description",
                          border: InputBorder.none,
                        ),
                        maxLines: 3,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Color Selection
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Select Task Color",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    selectedColor = Colors.red;
                                  });
                                },
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: selectedColor == Colors.red
                                          ? Colors.white
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                    boxShadow: selectedColor == Colors.red
                                        ? [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.3),
                                              blurRadius: 4,
                                              spreadRadius: 1,
                                            )
                                          ]
                                        : null,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    selectedColor = Colors.blue;
                                  });
                                },
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: selectedColor == Colors.blue
                                          ? Colors.white
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                    boxShadow: selectedColor == Colors.blue
                                        ? [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.3),
                                              blurRadius: 4,
                                              spreadRadius: 1,
                                            )
                                          ]
                                        : null,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    selectedColor = Colors.green;
                                  });
                                },
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: selectedColor == Colors.green
                                          ? Colors.white
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                    boxShadow: selectedColor == Colors.green
                                        ? [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.3),
                                              blurRadius: 4,
                                              spreadRadius: 1,
                                            )
                                          ]
                                        : null,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    selectedColor = Colors.orange;
                                  });
                                },
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: selectedColor == Colors.orange
                                          ? Colors.white
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                    boxShadow: selectedColor == Colors.orange
                                        ? [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.3),
                                              blurRadius: 4,
                                              spreadRadius: 1,
                                            )
                                          ]
                                        : null,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    selectedColor = Colors.purple;
                                  });
                                },
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.purple,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: selectedColor == Colors.purple
                                          ? Colors.white
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                    boxShadow: selectedColor == Colors.purple
                                        ? [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.3),
                                              blurRadius: 4,
                                              spreadRadius: 1,
                                            )
                                          ]
                                        : null,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    selectedColor = Colors.teal;
                                  });
                                },
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.teal,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: selectedColor == Colors.teal
                                          ? Colors.white
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                    boxShadow: selectedColor == Colors.teal
                                        ? [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.3),
                                              blurRadius: 4,
                                              spreadRadius: 1,
                                            )
                                          ]
                                        : null,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    selectedColor = Colors.brown;
                                  });
                                },
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.brown,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: selectedColor == Colors.brown
                                          ? Colors.white
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                    boxShadow: selectedColor == Colors.brown
                                        ? [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.3),
                                              blurRadius: 4,
                                              spreadRadius: 1,
                                            )
                                          ]
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTimeButton(String time, {required VoidCallback onTap}) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time, color: Colors.black),
          const SizedBox(width: 5),
          Text(time, style: const TextStyle(color: Colors.black)),
        ],
      ),
    );
  }

  Widget _buildTile(
      {required IconData icon, required String text, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(text),
      onTap: onTap,
      trailing: const Icon(Icons.arrow_drop_down),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String text,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      title: Text(text),
      value: value,
      onChanged: onChanged,
      secondary: Icon(icon),
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required String selectedValue,
    required Function(String?) onChanged,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: DropdownButton(
        value: selectedValue,
        items: ["None", "Daily", "Weekly", "Monthly"].map((String value) {
          return DropdownMenuItem(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: onChanged,
        underline: const SizedBox(),
      ),
    );
  }
}
