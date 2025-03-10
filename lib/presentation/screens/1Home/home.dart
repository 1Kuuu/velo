import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:velora/presentation/screens/0Auth/profile.dart';
import 'package:velora/presentation/screens/2ToolBox/toolbox.dart';
import 'package:velora/presentation/screens/3News/newsfeed.dart';
import 'package:velora/presentation/screens/4Chat/chat_list.dart';
import 'package:velora/presentation/screens/5Settings/setting_screen.dart';
import 'package:velora/presentation/widgets/reusable_wdgts.dart';
import 'event_modal.dart';

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
  DateTime _selectedDate = DateTime.now();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Stream<List<Event>>? _eventsStream;

  @override
  void initState() {
    super.initState();
    _updateEventsStream();
  }

  void _updateEventsStream() {
    if (_auth.currentUser == null) return;

    final startOfDay =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    _eventsStream = _firestore
        .collection('events')
        .where('userId', isEqualTo: _auth.currentUser?.uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList());
  }

  List<DateTime> getWeekDays(DateTime date) {
    int weekday = date.weekday;
    DateTime sunday = date.subtract(Duration(days: weekday % 7));
    return List.generate(7, (index) => sunday.add(Duration(days: index)));
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      _updateEventsStream();
    });
  }

  // Delete an event
  Future<void> _deleteEvent(String eventId) async {
    try {
      await _firestore.collection('events').doc(eventId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting event: $e')),
      );
    }
  }

  // Show delete confirmation dialog
  Future<void> _showDeleteConfirmation(
      BuildContext context, Event event) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Event'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete "${event.title}"?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteEvent(event.id);
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
      onEventCreated: (newEvent) async {
        try {
          await _firestore.collection('events').add(newEvent.toFirestore());
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error creating event: $e')),
            );
          }
        }
      },
      onEventUpdated: (updatedEvent) async {
        try {
          await _firestore
              .collection('events')
              .doc(updatedEvent.id)
              .update(updatedEvent.toFirestore());
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error updating event: $e')),
            );
          }
        }
      },
    );
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
          if (_auth.currentUser == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please log in to create events')),
            );
            return;
          }

          EventModalHelper.showNewEventModal(
            context,
            selectedDate: _selectedDate,
            onEventCreated: (newEvent) async {
              try {
                await _firestore
                    .collection('events')
                    .add(newEvent.toFirestore());
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error creating event: $e')),
                  );
                }
              }
            },
            onEventUpdated: (updatedEvent) async {
              try {
                await _firestore
                    .collection('events')
                    .doc(updatedEvent.id)
                    .update(updatedEvent.toFirestore());
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating event: $e')),
                  );
                }
              }
            },
          );
        },
        backgroundColor: Colors.black,
        heroTag: "fab_add_event",
      ),
      body: StreamBuilder<List<Event>>(
        stream: _eventsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final events = snapshot.data ?? [];

          return Column(
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
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _progressItem("Activities", events.length.toString()),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 1.0, vertical: 1.0),
                child: Row(
                  children: [
                    CustomDatePicker(
                      initialDate: _selectedDate,
                      onDateSelected: (newDate) {
                        setState(() {
                          _selectedDate = newDate;
                          _updateEventsStream();
                        });
                      },
                      child: IconButton(
                        icon: const Icon(Icons.menu),
                        color: AppColors.primary,
                        onPressed: null,
                      ),
                    ),
                    const SizedBox(width: 4),
                    CustomDatePicker(
                      initialDate: _selectedDate,
                      onDateSelected: (newDate) {
                        setState(() {
                          _selectedDate = newDate;
                          _updateEventsStream();
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
                  color: Colors.white,
                  border:
                      Border(bottom: BorderSide(color: Colors.grey.shade300)),
                ),
                child: SizedBox(
                  height: 60,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(
                        DateTime(_selectedDate.year, _selectedDate.month + 1, 0)
                            .day,
                        (index) {
                          DateTime currentDate = DateTime(_selectedDate.year,
                              _selectedDate.month, index + 1);
                          bool isSelected =
                              _selectedDate.day == currentDate.day &&
                                  _selectedDate.month == currentDate.month &&
                                  _selectedDate.year == currentDate.year;

                          bool hasEvents = events.any((event) =>
                              event.date.day == currentDate.day &&
                              event.date.month == currentDate.month &&
                              event.date.year == currentDate.year);

                          return GestureDetector(
                            onTap: () => _onDateSelected(currentDate),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Column(
                                children: [
                                  Text(
                                    DateFormat.E().format(currentDate),
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 4),
                                  Stack(
                                    alignment: Alignment.bottomCenter,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color.fromARGB(
                                                  255, 140, 55, 24)
                                              : Colors.transparent,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          currentDate.day.toString(),
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        ),
                                      ),
                                      if (hasEvents)
                                        Positioned(
                                          bottom: 0,
                                          child: Container(
                                            width: 4,
                                            height: 4,
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

              // Display Events for the Selected Date
              Expanded(
                child: events.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.event_note,
                                size: 48, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              "No Plans for ${DateFormat('EEEE, MMMM d').format(_selectedDate)}",
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Tap + to add a new Plan",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: events.length,
                        itemBuilder: (context, index) {
                          Event event = events[index];
                          return Dismissible(
                            key: Key(event.id),
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child:
                                  const Icon(Icons.delete, color: Colors.white),
                            ),
                            direction: DismissDirection.endToStart,
                            onDismissed: (direction) => _deleteEvent(event.id),
                            child: Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              color: event.color,
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
                                            IconButton(
                                              icon: const Icon(Icons.edit,
                                                  size: 20),
                                              onPressed: () =>
                                                  _editEvent(event),
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(),
                                            ),
                                            const SizedBox(width: 16),
                                            IconButton(
                                              icon: const Icon(Icons.delete,
                                                  size: 20),
                                              onPressed: () =>
                                                  _showDeleteConfirmation(
                                                      context, event),
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(),
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
          );
        },
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
