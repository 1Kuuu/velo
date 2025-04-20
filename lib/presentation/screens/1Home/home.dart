import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:velora/core/configs/theme/app_fonts.dart';
import 'package:velora/presentation/screens/0Auth/profile.dart';
import 'package:velora/presentation/screens/2ToolBox/toolbox.dart';
import 'package:velora/presentation/screens/3News/newsfeed.dart';
import 'package:velora/presentation/screens/4Chat/chat_list.dart';
import 'package:velora/presentation/screens/5Settings/setting_screen.dart';
import 'package:velora/presentation/screens/Weather/weather.dart';
import 'package:velora/presentation/screens/Weather/const.dart';
import 'package:velora/presentation/widgets/reusable_wdgts.dart';
import 'package:provider/provider.dart';
import 'package:velora/core/configs/theme/theme_provider.dart';
import 'event_modal.dart';
import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:weather/weather.dart';
import 'dart:async';
import 'package:velora/presentation/widgets/notification_app_bar_icon.dart';

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
  List<Event> _events = [];

  // Weather data
  final WeatherFactory wf = WeatherFactory(openWeatherKey ?? '');
  Weather? _currentWeather;
  Timer? _weatherTimer;
  DateTime _currentTime = DateTime.now();
  Timer? _timeTimer;

  @override
  void initState() {
    super.initState();
    _updateEventsStream();
    _fetchWeatherData();

    // Update time every minute
    _timeTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _weatherTimer?.cancel();
    _timeTimer?.cancel();
    super.dispose();
  }

  void _fetchWeatherData() async {
    try {
      final weather = await wf.currentWeatherByCityName("Caloocan");
      setState(() {
        _currentWeather = weather;
      });

      // Refresh weather data every 30 minutes
      _weatherTimer =
          Timer.periodic(const Duration(minutes: 30), (timer) async {
        try {
          final updatedWeather = await wf.currentWeatherByCityName("Caloocan");
          setState(() {
            _currentWeather = updatedWeather;
          });
        } catch (e) {
          print('Error updating weather data: $e');
        }
      });
    } catch (e) {
      print('Error fetching weather data: $e');
    }
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
        .map((snapshot) {
      _events = snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList();
      return _events;
    });
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

  Future<void> _deleteEvent(String eventId) async {
    try {
      await _firestore.collection('events').doc(eventId).delete();
      _showToast('Event deleted successfully');
    } catch (e) {
      _showToast('Error deleting event: $e', isError: true);
    }
  }

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

  void _editEvent(Event event) {
    EventModalHelper.showNewEventModal(
      context,
      existingEvent: event,
      selectedDate: _selectedDate,
      onEventCreated: (newEvent) async {
        try {
          await _firestore.collection('events').add(newEvent.toFirestore());
        } catch (e) {
          _showToast('Error creating event: $e', isError: true);
        }
      },
      onEventUpdated: (updatedEvent) async {
        try {
          await _firestore
              .collection('events')
              .doc(updatedEvent.id)
              .update(updatedEvent.toFirestore());
        } catch (e) {
          _showToast('Error updating event: $e', isError: true);
        }
      },
    );
  }

  void _showToast(String message, {bool isError = false}) {
    DelightToastBar(
      builder: (context) {
        return ToastCard(
          title: Text(message),
          leading: Icon(
            isError ? Icons.error : Icons.check_circle,
            color: isError ? Colors.red : Colors.green,
          ),
        );
      },
      position: DelightSnackbarPosition.top,
      autoDismiss: true,
      snackbarDuration: const Duration(seconds: 2),
      animationDuration: const Duration(milliseconds: 300),
    ).show(context);
  }

  IconData _getWeatherIcon(String? condition) {
    if (condition == null) return Icons.cloud_outlined;

    final weatherMain = condition.toLowerCase();
    if (weatherMain.contains('clear')) {
      return Icons.wb_sunny_outlined;
    } else if (weatherMain.contains('cloud')) {
      return Icons.cloud_outlined;
    } else if (weatherMain.contains('rain')) {
      return Icons.water_drop_outlined;
    } else if (weatherMain.contains('snow')) {
      return Icons.ac_unit_outlined;
    } else if (weatherMain.contains('thunderstorm')) {
      return Icons.flash_on_outlined;
    }
    return Icons.cloud_outlined;
  }

  String _capitalizeWeatherDescription(String? description) {
    if (description == null || description.isEmpty) return "";
    return "${description[0].toUpperCase()}${description.substring(1)}";
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF121212) : AppColors.lightBackground,
      appBar: MyAppBar(
        title: "Home",
        actions: [
          const NotificationAppBarIcon(),
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return AppBarIcon(
                  icon: Icons.person_outline,
                  onTap: () {}, // Empty callback for loading state
                );
              }

              final userData = snapshot.data?.data() as Map<String, dynamic>?;
              return ProfileAppBarIcon(
                profileUrl: userData?['profileUrl'],
                userName: userData?['userName'],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfilePage()),
                  );
                },
              );
            },
          ),
        ],
      ),
      floatingActionButton: TheFloatingActionButton(
        svgAsset: 'assets/svg/add.svg',
        onPressed: () {
          if (_auth.currentUser == null) {
            _showToast('Please log in to create events');
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
                _showToast('Error creating event: $e', isError: true);
              }
            },
            onEventUpdated: (updatedEvent) async {
              try {
                await _firestore
                    .collection('events')
                    .doc(updatedEvent.id)
                    .update(updatedEvent.toFirestore());
              } catch (e) {
                _showToast('Error updating event: $e', isError: true);
              }
            },
          );
        },
        backgroundColor: isDarkMode ? AppColors.primary : Colors.black,
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
              // Weekly Progress Section - Adjusted to match image
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color:
                        isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                        child: Text(
                          "Your Weekly Progress",
                          style: AppFonts.bold.copyWith(
                            fontSize: 18,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _progressItem("Activities", events.length.toString(),
                              isDarkMode),
                          _progressItem("Time", "0h 0m", isDarkMode),
                          _progressItem("Distance", "0.00km", isDarkMode),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Weather and Other Widgets Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    // Weather Widget - Completely redesigned for better layout
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => WeatherScreen()),
                          );
                        },
                        child: Container(
                          height: 120, // Increased height to ensure no overflow
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage(
                                  "assets/images/weather-background.png"), // Correctly use DecorationImage
                              fit: BoxFit.cover, // Adjust the fit as needed
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _currentWeather == null
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                )
                              : Stack(
                                  children: [
                                    // Main content
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Location row
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.location_on,
                                                color: Colors.white,
                                                size: 12,
                                              ),
                                              const SizedBox(width: 2),
                                              Flexible(
                                                child: Text(
                                                  _currentWeather?.areaName ??
                                                      "Location",
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),

                                          // Date and time row
                                          Text(
                                            "Today, ${DateFormat('MMM d h:mm a').format(_currentTime)}",
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 10,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),

                                          const SizedBox(height: 8),

                                          // Temperature and weather condition
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Temperature
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "${_currentWeather?.temperature?.celsius?.toStringAsFixed(0)}",
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize:
                                                          40, // Slightly reduced
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const Text(
                                                    "°C",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ],
                                              ),

                                              // Weather condition
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Icon(
                                                    _getWeatherIcon(
                                                        _currentWeather
                                                            ?.weatherMain),
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                  const SizedBox(height: 2),
                                                  SizedBox(
                                                    width: 80, // Fixed width
                                                    child: Text(
                                                      _capitalizeWeatherDescription(
                                                          _currentWeather
                                                              ?.weatherDescription),
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 11,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      textAlign:
                                                          TextAlign.right,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Empty Container (placeholder for another widget)
                    Expanded(
                      child: Container(
                        height: 120, // Match the height of the weather widget
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? const Color(0xFF1E1E1E)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

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
                        });
                      },
                      child: IconButton(
                        icon: Icon(
                          Icons.menu,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
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
                        style: AppFonts.bold.copyWith(
                          fontSize: 16,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),

              // Weekday Labels + Dates (Clickable)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: isDarkMode ? Colors.white24 : Colors.grey.shade300,
                    ),
                  ),
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
                          DateTime currentDate = DateTime(
                            _selectedDate.year,
                            _selectedDate.month,
                            index + 1,
                          );
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
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Column(
                                children: [
                                  Text(
                                    DateFormat.E().format(currentDate),
                                    style: AppFonts.regular.copyWith(
                                      fontSize: 13,
                                      color: isDarkMode
                                          ? Colors.white70
                                          : Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Stack(
                                    alignment: Alignment.bottomCenter,
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? (isDarkMode
                                                  ? Colors.white24
                                                  : Colors.black12)
                                              : Colors.transparent,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSelected
                                                ? (isDarkMode
                                                    ? Colors.white38
                                                    : Colors.black26)
                                                : Colors.transparent,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            currentDate.day.toString(),
                                            style: AppFonts.semibold.copyWith(
                                              fontSize: 15,
                                              color: isSelected
                                                  ? (isDarkMode
                                                      ? Colors.white
                                                      : Colors.black87)
                                                  : isDarkMode
                                                      ? Colors.white
                                                      : Colors.black87,
                                            ),
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
                                              color: isSelected
                                                  ? (isDarkMode
                                                      ? Colors.white
                                                      : Colors.black87)
                                                  : Colors.red,
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
                            Icon(Icons.event_note,
                                size: 48,
                                color:
                                    isDarkMode ? Colors.white38 : Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              "No Plans for ${DateFormat('EEEE, MMMM d').format(_selectedDate)}",
                              style: AppFonts.medium.copyWith(
                                color:
                                    isDarkMode ? Colors.white70 : Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Tap + to add a new Plan",
                              style: AppFonts.regular.copyWith(
                                color:
                                    isDarkMode ? Colors.white70 : Colors.grey,
                              ),
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
                              color: event.color
                                  .withOpacity(isDarkMode ? 0.8 : 1.0),
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
                                            style: AppFonts.bold.copyWith(
                                              fontSize: 16,
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : Colors.black87,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        PopupMenuButton<String>(
                                          icon: Icon(
                                            Icons.more_vert,
                                            color: isDarkMode
                                                ? Colors.white70
                                                : Colors.black54,
                                          ),
                                          onSelected: (String choice) {
                                            if (choice == 'Edit') {
                                              _editEvent(event);
                                            } else if (choice == 'Delete') {
                                              _showDeleteConfirmation(
                                                  context, event);
                                            }
                                          },
                                          itemBuilder: (BuildContext context) =>
                                              [
                                            PopupMenuItem<String>(
                                              value: 'Edit',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.edit,
                                                    color: isDarkMode
                                                        ? Colors.white70
                                                        : Colors.black54,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text('Edit'),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem<String>(
                                              value: 'Delete',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.delete,
                                                    color: Colors.red[700],
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  const Text('Delete'),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${DateFormat('EEEE, MMMM d').format(event.date)} | ${formatTimeOfDay(event.startTime)} - ${formatTimeOfDay(event.endTime)}",
                                      style: AppFonts.regular.copyWith(
                                        color: isDarkMode
                                            ? Colors.white70
                                            : Colors.black54,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      event.description,
                                      style: AppFonts.regular.copyWith(
                                        color: isDarkMode
                                            ? Colors.white70
                                            : Colors.black87,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
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

  Widget _progressItem(String title, String value, bool isDarkMode) {
    return Column(
      children: [
        Text(
          title,
          style: AppFonts.medium.copyWith(
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppFonts.medium.copyWith(
            fontSize: 16,
            color: isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
      ],
    );
  }
}
