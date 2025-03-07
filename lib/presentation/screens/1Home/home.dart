import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:velora/presentation/screens/0Auth/profile.dart';
import 'package:velora/presentation/screens/2ToolBox/toolbox.dart';
import 'package:velora/presentation/screens/3News/newsfeed.dart';
import 'package:velora/presentation/screens/4Chat/chat_list.dart';
import 'package:velora/presentation/screens/5Settings/setting_screen.dart';
import 'package:velora/presentation/widgets/reusable_wdgts.dart';
import 'event_modal.dart'; // Import the new file

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
    EventModalHelper.showNewEventModal(
      context,
      existingEvent: event,
      selectedDate: _selectedDate,
      onEventCreated: (newEvent) {
        // This won't be called for editing, but we need to provide it
        setState(() {
          _events.add(newEvent);
        });
      },
      onEventUpdated: (updatedEvent) {
        setState(() {
          // Find and replace the existing event
          final index = _events.indexWhere((e) => e.id == updatedEvent.id);
          if (index != -1) {
            _events[index] = updatedEvent;
          }
        });
      },
    );
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
      floatingActionButton: TheFloatingActionButton(
        svgAsset: 'assets/svg/add.svg',
        onPressed: () {
          EventModalHelper.showNewEventModal(
            context,
            selectedDate: _selectedDate,
            onEventCreated: (newEvent) {
              setState(() {
                _events.add(newEvent);
              });
            },
            onEventUpdated: (updatedEvent) {
              // This won't be called for new events, but we need to provide it
              setState(() {
                final index =
                    _events.indexWhere((e) => e.id == updatedEvent.id);
                if (index != -1) {
                  _events[index] = updatedEvent;
                }
              });
            },
          );
        },
        backgroundColor: Colors.black,
        heroTag: "fab_add_event",
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
                CustomDatePicker(
                  initialDate: _selectedDate,
                  onDateSelected: (newDate) {
                    setState(() {
                      _selectedDate = newDate;
                    });
                  },
                  child: IconButton(
                    icon: const Icon(Icons.menu),
                    color: AppColors.primary, // Change icon color
                    onPressed: null,
                  ),
                ),
                const SizedBox(width: 4),
                CustomDatePicker(
                  initialDate: _selectedDate,
                  onDateSelected: (newDate) {
                    setState(() {
                      _selectedDate = newDate;
                    });
                  },
                  child: Text(
                    DateFormat.yMMMM().format(_selectedDate),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
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
                                    "${DateFormat('EEEE, MMMM d').format(event.date)} | ${formatTimeOfDay(event.startTime)} - ${formatTimeOfDay(event.endTime)}"),
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
}
