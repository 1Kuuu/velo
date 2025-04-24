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
import 'package:velora/presentation/screens/Notifications/notifications_screen.dart';
import 'package:velora/presentation/widgets/reusable_wdgts.dart';
import 'package:provider/provider.dart';
import 'package:velora/core/configs/theme/theme_provider.dart';
import 'event_modal.dart';
import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:weather/weather.dart';
import 'dart:async';
import 'dart:math';

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
  List<Event> _events = []; // Current day's events
  List<Event> _monthEvents = []; // All events for the month
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  bool _isTransitioning = false;

  // Add cache for events
  final Map<String, List<Event>> _eventCache = {};

  // Weekly progress tracking with cache
  int _weeklyActivities = 0;
  Duration _weeklyTime = Duration.zero;
  double _weeklyDistance = 0.0;
  DateTime? _lastWeeklyProgressUpdate;

  // Weather data with cache duration
  final WeatherFactory wf = WeatherFactory(OPENWEATHER_API_KEY);
  Weather? _currentWeather;
  Timer? _weatherTimer;
  DateTime _currentTime = DateTime.now();
  Timer? _timeTimer;
  DateTime? _lastWeatherUpdate;

  // Add new fields for weekly progress optimization
  final Map<String, List<Event>> _weeklyEventsCache = {};
  DateTime? _weekStartDate;

  // Helper method to get week key
  String _getWeekKey(DateTime date) {
    final startOfWeek = date.subtract(Duration(days: date.weekday % 7));
    return "${startOfWeek.year}-${startOfWeek.month}-${startOfWeek.day}";
  }

  // Helper method to calculate event duration in minutes
  int _calculateEventDuration(Event event) {
    final startMinutes = event.startTime.hour * 60 + event.startTime.minute;
    final endMinutes = event.endTime.hour * 60 + event.endTime.minute;
    return endMinutes < startMinutes
        ? (24 * 60 - startMinutes) + endMinutes
        : endMinutes - startMinutes;
  }

  // Helper method to update weekly progress with a single event
  void _updateWeeklyProgressWithEvent(Event event, {bool isAdd = true}) {
    final now = DateTime.now();
    final weekKey = _getWeekKey(now);

    _weekStartDate ??= now.subtract(Duration(days: now.weekday % 7));

    // Check if event is in current week
    if (event.date.isBefore(_weekStartDate!) ||
        event.date.isAfter(_weekStartDate!.add(const Duration(days: 7)))) {
      return;
    }

    setState(() {
      if (isAdd) {
        _weeklyActivities++;
        _weeklyTime += Duration(minutes: _calculateEventDuration(event));
        if (event.distance != null) {
          _weeklyDistance += event.distance!;
        }

        // Update weekly events cache
        if (_weeklyEventsCache.containsKey(weekKey)) {
          _weeklyEventsCache[weekKey]!.add(event);
        } else {
          _weeklyEventsCache[weekKey] = [event];
        }
      } else {
        _weeklyActivities--;
        _weeklyTime -= Duration(minutes: _calculateEventDuration(event));
        if (event.distance != null) {
          _weeklyDistance -= event.distance!;
        }

        // Update weekly events cache
        if (_weeklyEventsCache.containsKey(weekKey)) {
          _weeklyEventsCache[weekKey]!.removeWhere((e) => e.id == event.id);
        }
      }
    });
  }

  String _getDateKey(DateTime date) {
    return "${date.year}-${date.month}-${date.day}";
  }

  @override
  void initState() {
    super.initState();
    _fetchInitialEvents();
    _fetchWeeklyProgress();
    _fetchWeatherData();

    // Update time every minute and check for completed tasks
    _timeTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
      _checkAndUpdateEventCompletions();
    });
  }

  @override
  void dispose() {
    _weatherTimer?.cancel();
    _timeTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchInitialEvents() async {
    if (_auth.currentUser == null) return;

    final dateKey = _getDateKey(_selectedDate);

    // First try to get current day's events from cache
    if (_eventCache.containsKey(dateKey)) {
      setState(() {
        _events = List.from(_eventCache[dateKey]!);
      });
    }

    // Fetch events for the entire month
    final startOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final endOfMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);

    try {
      final snapshot = await _firestore
          .collection('events')
          .where('userId', isEqualTo: _auth.currentUser?.uid)
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('date',
              isLessThan:
                  Timestamp.fromDate(endOfMonth.add(const Duration(days: 1))))
          .get();

      final fetchedMonthEvents =
          snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList();

      // Update month events
      setState(() {
        _monthEvents = fetchedMonthEvents;
      });

      // Cache events by day
      for (var event in fetchedMonthEvents) {
        final eventDateKey = _getDateKey(event.date);
        if (!_eventCache.containsKey(eventDateKey)) {
          _eventCache[eventDateKey] = [];
        }
        _eventCache[eventDateKey]!.add(event);
      }

      // Update current day's events if not already set from cache
      if (!_eventCache.containsKey(dateKey)) {
        setState(() {
          _events = fetchedMonthEvents
              .where((event) =>
                  event.date.year == _selectedDate.year &&
                  event.date.month == _selectedDate.month &&
                  event.date.day == _selectedDate.day)
              .toList();
          _eventCache[dateKey] = _events;
        });
      }
    } catch (e) {
      print('Error fetching initial events: $e');
    }
  }

  Future<void> _fetchWeeklyProgress() async {
    if (_auth.currentUser == null) return;

    final now = DateTime.now();
    _weekStartDate = now.subtract(Duration(days: now.weekday % 7));
    final weekKey = _getWeekKey(now);

    // Return cached data if available and less than an hour old
    if (_lastWeeklyProgressUpdate != null &&
        now.difference(_lastWeeklyProgressUpdate!) < const Duration(hours: 1) &&
        _weeklyEventsCache.containsKey(weekKey)) {
      return;
    }

    try {
      final snapshot = await _firestore
          .collection('events')
          .where('userId', isEqualTo: _auth.currentUser?.uid)
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(_weekStartDate!))
          .where('date',
              isLessThan: Timestamp.fromDate(
                  _weekStartDate!.add(const Duration(days: 7))))
          .get();

      final events =
          snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList();

      // Cache the weekly events
      _weeklyEventsCache[weekKey] = events;

      // Calculate totals
      int totalMinutes = 0;
      double totalDistance = 0.0;

      for (var event in events) {
        totalMinutes += _calculateEventDuration(event);
        if (event.distance != null) {
          totalDistance += event.distance!;
        }
      }

      setState(() {
        _weeklyActivities = events.length;
        _weeklyTime = Duration(minutes: totalMinutes);
        _weeklyDistance = totalDistance;
        _lastWeeklyProgressUpdate = now;
      });
    } catch (e) {
      print('Error fetching weekly progress: $e');
    }
  }

  Future<void> _fetchWeatherData() async {
    // Check if we need to update weather (update once per hour)
    final now = DateTime.now();
    if (_lastWeatherUpdate != null &&
        now.difference(_lastWeatherUpdate!) < const Duration(hours: 1)) {
      return;
    }

    try {
      final weather = await wf.currentWeatherByCityName("Caloocan");
      setState(() {
        _currentWeather = weather;
        _lastWeatherUpdate = now;
      });

      // Update weather every 30 minutes
      _weatherTimer?.cancel();
      _weatherTimer =
          Timer.periodic(const Duration(minutes: 30), (timer) async {
        _fetchWeatherData();
      });
    } catch (e) {
      print('Error fetching weather data: $e');
    }
  }

  List<DateTime> getWeekDays(DateTime date) {
    int weekday = date.weekday;
    DateTime sunday = date.subtract(Duration(days: weekday % 7));
    return List.generate(7, (index) => sunday.add(Duration(days: index)));
  }

  Future<void> _onDateSelected(DateTime date) async {
    if (_isTransitioning) return;
    _isTransitioning = true;

    final dateKey = _getDateKey(date);

    setState(() {
      _selectedDate = date;
    });

    // Check cache first
    if (_eventCache.containsKey(dateKey)) {
      setState(() {
        _events = List.from(_eventCache[dateKey]!);
      });
      _isTransitioning = false;
      return;
    }

    // Fetch from Firestore if not in cache
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    try {
      final snapshot = await _firestore
          .collection('events')
          .where('userId', isEqualTo: _auth.currentUser?.uid)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      final newEvents =
          snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList();

      // Cache the fetched events
      _eventCache[dateKey] = newEvents;

      setState(() {
        _events = List.from(newEvents);
      });
    } catch (e) {
      print('Error fetching events: $e');
    } finally {
      _isTransitioning = false;
    }
  }

  Widget _buildEventCard(Event event) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: event.color.withOpacity(isDarkMode ? 0.8 : 1.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (event.isCompleted)
                        const Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          child: Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          event.title,
                          style: AppFonts.bold.copyWith(
                            fontSize: 16,
                            color: Colors.white,
                            decoration: event.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.white70,
                  ),
                  onSelected: (String choice) {
                    if (choice == 'Edit') {
                      _editEvent(event);
                    } else if (choice == 'Delete') {
                      _showDeleteConfirmation(context, event);
                    } else if (choice == 'ToggleComplete') {
                      _toggleEventCompletion(event);
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem<String>(
                      value: 'ToggleComplete',
                      child: Row(
                        children: [
                          Icon(
                            event.isCompleted
                                ? Icons.remove_done
                                : Icons.check_circle_outline,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(event.isCompleted
                              ? 'Mark Incomplete'
                              : 'Mark Complete'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'Edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
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
                color: Colors.white.withOpacity(0.9),
                decoration:
                    event.isCompleted ? TextDecoration.lineThrough : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            if (event.distance != null && event.distance! > 0) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.directions_bike,
                    size: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "Distance: ${event.distance!.toStringAsFixed(1)}km",
                    style: AppFonts.regular.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      decoration:
                          event.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Text(
              event.description,
              style: AppFonts.regular.copyWith(
                color: Colors.white.withOpacity(0.9),
                decoration:
                    event.isCompleted ? TextDecoration.lineThrough : null,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteEvent(String eventId) async {
    try {
      final event = _events.firstWhere((e) => e.id == eventId);
      final dateKey = _getDateKey(event.date);

      await _firestore.collection('events').doc(eventId).delete();

      // Update cache and current events list
      setState(() {
        if (_eventCache.containsKey(dateKey)) {
          _eventCache[dateKey] = List<Event>.from(
              _eventCache[dateKey]!.where((e) => e.id != eventId));
        }
        _events = List<Event>.from(_events.where((e) => e.id != eventId));
        // Also update _monthEvents list
        _monthEvents =
            List<Event>.from(_monthEvents.where((e) => e.id != eventId));
      });

      // Update weekly progress immediately
      _updateWeeklyProgressWithEvent(event, isAdd: false);

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
      onEventCreated: _handleEventCreated,
      onEventUpdated: _handleEventUpdated,
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

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF121212) : AppColors.lightBackground,
      appBar: MyAppBar(
        title: "Home",
        actions: const [
          _NotificationIcon(),
          _ProfileIconWidget(),
        ],
      ),
      floatingActionButton: TheFloatingActionButton(
        svgAsset: 'assets/svg/add.svg',
        onPressed: _showAddEventModal,
        backgroundColor: isDarkMode ? AppColors.primary : Colors.black,
        heroTag: "fab_add_event",
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          _WeeklyProgressSection(
            weeklyActivities: _weeklyActivities,
            weeklyTime: _weeklyTime,
            weeklyDistance: _weeklyDistance,
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 16),
          _WeatherAndWidgetsRow(
            currentWeather: _currentWeather,
            currentTime: _currentTime,
            isDarkMode: isDarkMode,
            onWeatherTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const WeatherScreen()),
            ),
          ),
          const SizedBox(height: 16),
          _CalendarHeader(
            selectedDate: _selectedDate,
            onDateSelected: _onDateSelected,
            isDarkMode: isDarkMode,
          ),
          _CalendarDaysView(
            selectedDate: _selectedDate,
            events: _monthEvents,
            onDateSelected: _onDateSelected,
            isDarkMode: isDarkMode,
          ),
          _EventsList(
            events: _events,
            selectedDate: _selectedDate,
            listKey: _listKey,
            onDeleteEvent: _deleteEvent,
            buildEventCard: _buildEventCard,
            isDarkMode: isDarkMode,
          ),
        ],
      ),
    );
  }

  void _showAddEventModal() {
    if (_auth.currentUser == null) {
      _showToast('Please log in to create events');
      return;
    }

    EventModalHelper.showNewEventModal(
      context,
      selectedDate: _selectedDate,
      onEventCreated: _handleEventCreated,
      onEventUpdated: _handleEventUpdated,
    );
  }

  Future<void> _handleEventCreated(Event newEvent) async {
    try {
      final docRef =
          await _firestore.collection('events').add(newEvent.toFirestore());

      final createdEvent = Event(
        id: docRef.id,
        title: newEvent.title,
        description: newEvent.description,
        date: newEvent.date,
        startTime: newEvent.startTime,
        endTime: newEvent.endTime,
        color: newEvent.color,
        distance: newEvent.distance,
        isAllDay: newEvent.isAllDay,
        repeatStatus: newEvent.repeatStatus,
        userId: newEvent.userId,
      );

      final dateKey = _getDateKey(newEvent.date);

      // Update cache
      if (_eventCache.containsKey(dateKey)) {
        _eventCache[dateKey] =
            List<Event>.from([..._eventCache[dateKey]!, createdEvent]);
      } else {
        _eventCache[dateKey] = [createdEvent];
      }

      // Update current events list if the event is for the selected date
      if (newEvent.date.year == _selectedDate.year &&
          newEvent.date.month == _selectedDate.month &&
          newEvent.date.day == _selectedDate.day) {
        setState(() {
          _events = List<Event>.from([..._events, createdEvent]);
        });
      }

      // Update month events list
      setState(() {
        _monthEvents = List<Event>.from([..._monthEvents, createdEvent]);
      });

      // Update weekly progress immediately
      _updateWeeklyProgressWithEvent(createdEvent, isAdd: true);

      _showToast('Event created successfully');
    } catch (e) {
      _showToast('Error creating event: $e', isError: true);
    }
  }

  Future<void> _handleEventUpdated(Event updatedEvent) async {
    try {
      // Find the old event before updating
      final oldEvent = _events.firstWhere(
        (e) => e.id == updatedEvent.id,
        orElse: () => updatedEvent,
      );

      await _firestore
          .collection('events')
          .doc(updatedEvent.id)
          .update(updatedEvent.toFirestore());

      final dateKey = _getDateKey(updatedEvent.date);

      // Update cache
      if (_eventCache.containsKey(dateKey)) {
        final events = List<Event>.from(_eventCache[dateKey]!);
        final index = events.indexWhere((e) => e.id == updatedEvent.id);
        if (index != -1) {
          events[index] = updatedEvent;
          _eventCache[dateKey] = events;
        }
      }

      // Update current events list if it's the selected date
      if (updatedEvent.date.year == _selectedDate.year &&
          updatedEvent.date.month == _selectedDate.month &&
          updatedEvent.date.day == _selectedDate.day) {
        setState(() {
          final index = _events.indexWhere((e) => e.id == updatedEvent.id);
          if (index != -1) {
            final newList = List<Event>.from(_events);
            newList[index] = updatedEvent;
            _events = newList;
          }
        });
      }

      // Update weekly progress immediately
      _updateWeeklyProgressWithEvent(oldEvent, isAdd: false);
      _updateWeeklyProgressWithEvent(updatedEvent, isAdd: true);

      _showToast('Event updated successfully');
    } catch (e) {
      _showToast('Error updating event: $e', isError: true);
    }
  }

  // Add method to check and update event completions
  Future<void> _checkAndUpdateEventCompletions() async {
    if (_auth.currentUser == null) return;

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Get all uncompleted events for today and future
      final snapshot = await _firestore
          .collection('events')
          .where('userId', isEqualTo: _auth.currentUser?.uid)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
          .where('isCompleted', isEqualTo: false)
          .get()
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          // Fallback query if index is not ready
          return _firestore
              .collection('events')
              .where('userId', isEqualTo: _auth.currentUser?.uid)
              .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
              .get();
        },
      );

      for (var doc in snapshot.docs) {
        final event = Event.fromFirestore(doc);
        // Skip if already completed
        if (event.isCompleted) continue;

        if (event.shouldBeCompleted()) {
          // Update the event in Firestore
          await _firestore
              .collection('events')
              .doc(event.id)
              .update({'isCompleted': true});

          // Update local cache and state
          final dateKey = _getDateKey(event.date);
          if (_eventCache.containsKey(dateKey)) {
            final events = List<Event>.from(_eventCache[dateKey]!);
            final index = events.indexWhere((e) => e.id == event.id);
            if (index != -1) {
              events[index] = event.copyWith(isCompleted: true);
              _eventCache[dateKey] = events;
            }
          }

          // Update current events list if it's the selected date
          if (event.date.year == _selectedDate.year &&
              event.date.month == _selectedDate.month &&
              event.date.day == _selectedDate.day) {
            setState(() {
              final index = _events.indexWhere((e) => e.id == event.id);
              if (index != -1) {
                final newList = List<Event>.from(_events);
                newList[index] = event.copyWith(isCompleted: true);
                _events = newList;
              }
            });
          }

          // Update month events
          setState(() {
            final index = _monthEvents.indexWhere((e) => e.id == event.id);
            if (index != -1) {
              final newList = List<Event>.from(_monthEvents);
              newList[index] = event.copyWith(isCompleted: true);
              _monthEvents = newList;
            }
          });

          // Show a notification that the task was automatically completed
          _showToast('Task "${event.title}" automatically marked as complete');
        }
      }
    } catch (e) {
      print('Error checking event completions: $e');
    }
  }

  // Add method to toggle event completion
  Future<void> _toggleEventCompletion(Event event) async {
    try {
      final updatedEvent = event.copyWith(isCompleted: !event.isCompleted);

      // Update Firestore
      await _firestore
          .collection('events')
          .doc(event.id)
          .update({'isCompleted': updatedEvent.isCompleted});

      // Update local state and cache
      final dateKey = _getDateKey(event.date);

      // Update cache
      if (_eventCache.containsKey(dateKey)) {
        final events = List<Event>.from(_eventCache[dateKey]!);
        final index = events.indexWhere((e) => e.id == event.id);
        if (index != -1) {
          events[index] = updatedEvent;
          _eventCache[dateKey] = events;
        }
      }

      // Update current events list if it's the selected date
      if (event.date.year == _selectedDate.year &&
          event.date.month == _selectedDate.month &&
          event.date.day == _selectedDate.day) {
        setState(() {
          final index = _events.indexWhere((e) => e.id == event.id);
          if (index != -1) {
            final newList = List<Event>.from(_events);
            newList[index] = updatedEvent;
            _events = newList;
          }
        });
      }

      // Update month events
      setState(() {
        final index = _monthEvents.indexWhere((e) => e.id == event.id);
        if (index != -1) {
          final newList = List<Event>.from(_monthEvents);
          newList[index] = updatedEvent;
          _monthEvents = newList;
        }
      });

      _showToast(updatedEvent.isCompleted
          ? 'Task completed'
          : 'Task marked incomplete');
    } catch (e) {
      _showToast('Error updating task status: $e', isError: true);
    }
  }
}

class _NotificationIcon extends StatelessWidget {
  const _NotificationIcon();

  @override
  Widget build(BuildContext context) {
    return AppBarIcon(
      icon: Icons.notifications_outlined,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NotificationsScreen()),
        );
      },
    );
  }
}

class _ProfileIconWidget extends StatelessWidget {
  const _ProfileIconWidget();

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

class BikeDisplay extends StatefulWidget {
  final bool isDarkMode;

  const BikeDisplay({
    Key? key,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  _BikeDisplayState createState() => _BikeDisplayState();
}

class _BikeDisplayState extends State<BikeDisplay>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.8);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        final bikeType = userData?['bike_type'] as String? ?? 'MOUNTAINBIKE';
        final bikes = ['ROADBIKE', 'MOUNTAINBIKE', 'FIXIE'];
        _currentPage = bikes.indexOf(bikeType);

        return Container(
          width: 120,
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color:
                widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(widget.isDarkMode ? 0.3 : 0.05),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            children: [
              SizedBox(
                height: 120,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: bikes.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final currentBike = bikes[index];
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          children: [
                            Text(
                              currentBike,
                              style: AppFonts.bold.copyWith(
                                fontSize: 12,
                                color: widget.isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Image.asset(
                              'assets/images/${currentBike.toLowerCase()}.png',
                              height: 80,
                              fit: BoxFit.contain,
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
                  bikes.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == index
                          ? (widget.isDarkMode
                              ? const Color(0xFF4A3B7C)
                              : const Color(0xFF8B1539))
                          : Colors.grey.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WeeklyProgressSection extends StatefulWidget {
  final int weeklyActivities;
  final Duration weeklyTime;
  final double weeklyDistance;
  final bool isDarkMode;

  const _WeeklyProgressSection({
    required this.weeklyActivities,
    required this.weeklyDistance,
    required this.weeklyTime,
    required this.isDarkMode,
  });

  @override
  _WeeklyProgressSectionState createState() => _WeeklyProgressSectionState();
}

class _WeeklyProgressSectionState extends State<_WeeklyProgressSection> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 100,
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: [
              // Weekly Progress Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: widget.isDarkMode
                        ? const Color(0xFF1E1E1E)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(24),
                    border: _currentPage == 0
                        ? Border.all(
                            color: widget.isDarkMode
                                ? const Color(0xFF4A3B7C)
                                : const Color(0xFF8B1539),
                            width: 1.5,
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withOpacity(widget.isDarkMode ? 0.3 : 0.05),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Your Weekly Progress",
                        style: AppFonts.bold.copyWith(
                          fontSize: 14,
                          color:
                              widget.isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Expanded(
                            child: _ProgressItem(
                              title: "Activities",
                              value: widget.weeklyActivities.toString(),
                              isDarkMode: widget.isDarkMode,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 30,
                            color: widget.isDarkMode
                                ? Colors.white.withOpacity(0.1)
                                : Colors.black.withOpacity(0.1),
                          ),
                          Expanded(
                            child: _ProgressItem(
                              title: "Time",
                              value: _formatDuration(widget.weeklyTime),
                              isDarkMode: widget.isDarkMode,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 30,
                            color: widget.isDarkMode
                                ? Colors.white.withOpacity(0.1)
                                : Colors.black.withOpacity(0.1),
                          ),
                          Expanded(
                            child: _ProgressItem(
                              title: "Distance",
                              value:
                                  "${_formatDistance(widget.weeklyDistance)}km",
                              isDarkMode: widget.isDarkMode,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Bike Display Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser?.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final userData =
                        snapshot.data?.data() as Map<String, dynamic>?;
                    final bikeType =
                        userData?['bike_type'] as String? ?? 'MOUNTAINBIKE';

                    return GestureDetector(
                      onTap: () => _showBikeDetailsDialog(context),
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: widget.isDarkMode
                              ? const Color(0xFF1E1E1E)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(24),
                          border: _currentPage == 1
                              ? Border.all(
                                  color: widget.isDarkMode
                                      ? const Color(0xFF4A3B7C)
                                      : const Color(0xFF8B1539),
                                  width: 1.5,
                                )
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withOpacity(widget.isDarkMode ? 0.3 : 0.05),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Your Bike",
                                  style: AppFonts.bold.copyWith(
                                    fontSize: 16,
                                    color: widget.isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  bikeType,
                                  style: AppFonts.medium.copyWith(
                                    fontSize: 14,
                                    color: widget.isDarkMode
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                            Image.asset(
                              'assets/images/${bikeType.toLowerCase()}.png',
                              height: 60,
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        // Dot indicators
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            2,
            (index) => Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentPage == index
                    ? (widget.isDarkMode
                        ? const Color(0xFF4A3B7C)
                        : const Color(0xFF8B1539))
                    : Colors.grey.withOpacity(0.3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours >= 100) {
      return '${hours}h';
    }
    return '${hours}h ${minutes}m';
  }

  String _formatDistance(double distance) {
    if (distance >= 1000) {
      return '${(distance / 1000).toStringAsFixed(1)}k';
    }
    return distance.toStringAsFixed(1);
  }

  void _showBikeDetailsDialog(BuildContext context) {
    final isDarkMode =
        Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('user_preferences')
                .doc(FirebaseAuth.instance.currentUser?.uid)
                .snapshots(),
            builder: (context, prefsSnapshot) {
              if (!prefsSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final prefsData =
                  prefsSnapshot.data?.data() as Map<String, dynamic>?;
              final timePrefs =
                  (prefsData?['time_preferences'] as Map<String, dynamic>?) ??
                      {};
              final locationPrefs =
                  (prefsData?['location_preferences'] as List<dynamic>?)
                          ?.whereType<String>()
                          .toList() ??
                      [];

              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser?.uid)
                    .snapshots(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final userData =
                      userSnapshot.data?.data() as Map<String, dynamic>?;
                  final bikeType =
                      userData?['bike_type'] as String? ?? 'MOUNTAINBIKE';

                  return Container(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Bike Image and Type
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? const Color(0xFF1E1E1E)
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Image.asset(
                                'assets/images/${bikeType.toLowerCase()}.png',
                                height: 120,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                bikeType,
                                style: AppFonts.bold.copyWith(
                                  fontSize: 20,
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Time Preferences
                        Text(
                          'To Ride During:',
                          style: AppFonts.bold.copyWith(
                            fontSize: 16,
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: timePrefs.entries
                              .where((e) => e.value == true)
                              .map((e) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDarkMode
                                          ? const Color(0xFF4A3B7C)
                                          : const Color(0xFF8B1539),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      e.key,
                                      style: AppFonts.medium.copyWith(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 16),
                        // Location Preferences
                        Text(
                          'In The:',
                          style: AppFonts.bold.copyWith(
                            fontSize: 16,
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: locationPrefs
                              .map((location) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDarkMode
                                          ? const Color(0xFF4A3B7C)
                                          : const Color(0xFF8B1539),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      location,
                                      style: AppFonts.medium.copyWith(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 24),
                        // Close Button
                        Align(
                          alignment: Alignment.center,
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Close',
                              style: AppFonts.medium.copyWith(
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _ProgressItem extends StatelessWidget {
  final String title;
  final String value;
  final bool isDarkMode;

  const _ProgressItem({
    required this.title,
    required this.value,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: AppFonts.medium.copyWith(
            color: isDarkMode ? Colors.white70 : Colors.black54,
            fontSize: 11,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: AppFonts.bold.copyWith(
              fontSize: 13,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}

class _WeatherAndWidgetsRow extends StatelessWidget {
  final Weather? currentWeather;
  final DateTime currentTime;
  final bool isDarkMode;
  final VoidCallback onWeatherTap;

  const _WeatherAndWidgetsRow({
    required this.currentWeather,
    required this.currentTime,
    required this.isDarkMode,
    required this.onWeatherTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onWeatherTap,
              child: Container(
                height: 90,
                decoration: BoxDecoration(
                  image: const DecorationImage(
                    image: AssetImage("assets/images/weather-background.png"),
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: currentWeather == null
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on,
                                            color: Colors.white,
                                            size: 12,
                                          ),
                                          const SizedBox(width: 2),
                                          Expanded(
                                            child: Text(
                                              currentWeather?.areaName ??
                                                  "Location",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        "Today, ${DateFormat('MMM d h:mm a').format(currentTime)}",
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 10,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  _getWeatherIcon(currentWeather?.weatherMain),
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${currentWeather?.temperature?.celsius?.toStringAsFixed(0)}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Text(
                                      "°C",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                Expanded(
                                  child: Text(
                                    _capitalizeWeatherDescription(
                                        currentWeather?.weatherDescription),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              height: 90,
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
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
}

class _CalendarHeader extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final bool isDarkMode;

  const _CalendarHeader({
    required this.selectedDate,
    required this.onDateSelected,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1.0, vertical: 1.0),
      child: Row(
        children: [
          CustomDatePicker(
            initialDate: selectedDate,
            onDateSelected: onDateSelected,
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
            initialDate: selectedDate,
            onDateSelected: onDateSelected,
            child: Text(
              DateFormat.yMMMM().format(selectedDate),
              style: AppFonts.bold.copyWith(
                fontSize: 16,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _CalendarDaysView extends StatefulWidget {
  final DateTime selectedDate;
  final List<Event> events;
  final Function(DateTime) onDateSelected;
  final bool isDarkMode;

  const _CalendarDaysView({
    required this.selectedDate,
    required this.events,
    required this.onDateSelected,
    required this.isDarkMode,
  });

  @override
  _CalendarDaysViewState createState() => _CalendarDaysViewState();
}

class _CalendarDaysViewState extends State<_CalendarDaysView> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedDate();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSelectedDate() {
    if (!mounted) return;

    final dayWidth =
        52.0; // Width of each day item (36 + 16 horizontal padding)
    final screenWidth = MediaQuery.of(context).size.width;
    final offset = (widget.selectedDate.day - 1) * dayWidth;
    final maxScroll = _scrollController.position.maxScrollExtent;

    _scrollController.animateTo(
      offset.clamp(0, maxScroll),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void didUpdateWidget(_CalendarDaysView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      _scrollToSelectedDate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: widget.isDarkMode ? Colors.white24 : Colors.grey.shade300,
          ),
        ),
      ),
      child: SizedBox(
        height: 60,
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(
              DateTime(widget.selectedDate.year, widget.selectedDate.month + 1,
                      0)
                  .day,
              (index) {
                DateTime currentDate = DateTime(
                  widget.selectedDate.year,
                  widget.selectedDate.month,
                  index + 1,
                );
                bool hasEvents = widget.events.any((event) {
                  final eventDate = DateTime(
                      event.date.year, event.date.month, event.date.day);
                  final compareDate = DateTime(
                      currentDate.year, currentDate.month, currentDate.day);
                  return eventDate.isAtSameMomentAs(compareDate);
                });

                bool isSelected = widget.selectedDate.day == currentDate.day &&
                    widget.selectedDate.month == currentDate.month &&
                    widget.selectedDate.year == currentDate.year;

                return GestureDetector(
                  onTap: () => widget.onDateSelected(currentDate),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        Text(
                          DateFormat.E().format(currentDate),
                          style: AppFonts.regular.copyWith(
                            fontSize: 13,
                            color: _isPastDate(currentDate)
                                ? Colors.grey.withOpacity(0.5)
                                : (widget.isDarkMode
                                    ? Colors.white70
                                    : Colors.grey),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // Today's indicator (dotted circle)
                            if (_isToday(currentDate))
                              SizedBox(
                                width: 36,
                                height: 36,
                                child: CustomPaint(
                                  painter: DottedCirclePainter(
                                    color: widget.isDarkMode
                                        ? const Color(0xFF4A3B7C)
                                        : const Color(0xFF8B1539),
                                    dottedLength: 2,
                                    spacing: 2,
                                  ),
                                ),
                              ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (widget.isDarkMode
                                        ? const Color(0xFF4A3B7C)
                                            .withOpacity(0.3)
                                        : const Color(0xFF8B1539)
                                            .withOpacity(0.1))
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? (widget.isDarkMode
                                          ? const Color(0xFF4A3B7C)
                                          : const Color(0xFF8B1539))
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  if (hasEvents)
                                    Positioned(
                                      top: 2,
                                      child: Container(
                                        width: 4,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: _isPastDate(currentDate)
                                              ? (widget.isDarkMode
                                                  ? Colors.grey.shade700
                                                  : Colors.grey.shade400)
                                              : (widget.isDarkMode
                                                  ? const Color(0xFF4A3B7C)
                                                  : const Color(0xFF8B1539)),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  Center(
                                    child: AnimatedDefaultTextStyle(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      style: AppFonts.semibold.copyWith(
                                        fontSize: 15,
                                        color: _isPastDate(currentDate)
                                            ? (widget.isDarkMode
                                                ? Colors.grey.shade700
                                                : Colors.grey.shade400)
                                            : (_isToday(currentDate)
                                                ? (widget.isDarkMode
                                                    ? Colors.white
                                                    : const Color(0xFF8B1539))
                                                : (isSelected
                                                    ? (widget.isDarkMode
                                                        ? Colors.white
                                                        : const Color(
                                                            0xFF8B1539))
                                                    : widget.isDarkMode
                                                        ? Colors.white70
                                                        : Colors.black87)),
                                      ),
                                      child: Text(
                                        currentDate.day.toString(),
                                      ),
                                    ),
                                  ),
                                ],
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
    );
  }

  // Helper method to check if a date is in the past
  bool _isPastDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final compareDate = DateTime(date.year, date.month, date.day);
    return compareDate.isBefore(today);
  }

  // Helper method to check if a date is today
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

// Custom painter for dotted circle
class DottedCirclePainter extends CustomPainter {
  final Color color;
  final double dottedLength;
  final double spacing;

  DottedCirclePainter({
    required this.color,
    required this.dottedLength,
    required this.spacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final double radius = size.width / 2;
    final double center = size.width / 2;
    final double totalLength = 2 * pi * radius;
    final int numberOfDots = (totalLength / (dottedLength + spacing)).round();
    final double eachAngle = (2 * pi) / numberOfDots;

    for (int i = 0; i < numberOfDots; i++) {
      final double startAngle = i * eachAngle;
      final double endAngle =
          startAngle + (eachAngle * dottedLength / (dottedLength + spacing));

      canvas.drawArc(
        Rect.fromCircle(center: Offset(center, center), radius: radius),
        startAngle,
        endAngle - startAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(DottedCirclePainter oldDelegate) =>
      color != oldDelegate.color ||
      dottedLength != oldDelegate.dottedLength ||
      spacing != oldDelegate.spacing;
}

class _EventsList extends StatelessWidget {
  final List<Event> events;
  final DateTime selectedDate;
  final GlobalKey<AnimatedListState> listKey;
  final Function(String) onDeleteEvent;
  final Widget Function(Event) buildEventCard;
  final bool isDarkMode;

  const _EventsList({
    required this.events,
    required this.selectedDate,
    required this.listKey,
    required this.onDeleteEvent,
    required this.buildEventCard,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: events.isEmpty
            ? Center(
                key: ValueKey<DateTime>(selectedDate),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_note,
                        size: 48,
                        color: isDarkMode ? Colors.white38 : Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      "No Plans for ${DateFormat('EEEE, MMMM d').format(selectedDate)}",
                      style: AppFonts.medium.copyWith(
                        color: isDarkMode ? Colors.white70 : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Tap + to add a new Plan",
                      style: AppFonts.regular.copyWith(
                        color: isDarkMode ? Colors.white70 : Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                key: PageStorageKey<DateTime>(selectedDate),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  return Dismissible(
                    key: ValueKey(events[index].id),
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) => onDeleteEvent(events[index].id),
                    child: buildEventCard(events[index]),
                  );
                },
              ),
      ),
    );
  }
}
