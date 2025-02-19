import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:velo/core/configs/theme/app_fonts.dart';
import 'package:velo/presentation/screens/NewEventScreen.dart';
import 'package:velo/presentation/screens/setting.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<String> timeSlots = [
    '8:00AM', '9:00AM', '10:00AM', '11:00AM', '12:00PM',
    '1:00PM', '2:00PM', '3:00PM', '4:00PM', '5:00PM'
  ];

  late DateTime selectedDate;
  int activities = 0;
  String time = '0h 0m';
  double distance = 0.0;
  Map<String, String> plansByTime = {};

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    _fetchWeeklyProgress();
    _fetchPlansForSelectedDate();
  }

  Future<void> _fetchWeeklyProgress() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final weekStart = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 7));

        final snapshot = await FirebaseFirestore.instance
            .collection('user_activities')
            .doc(user.uid)
            .collection('activities')
            .where('date', isGreaterThanOrEqualTo: weekStart)
            .where('date', isLessThan: weekEnd)
            .get();

        int totalActivities = snapshot.docs.length;
        int totalMinutes = snapshot.docs.fold(0, (sum, doc) => sum + (doc['duration'] as int));
        // ignore: avoid_types_as_parameter_names
        double totalDistance = snapshot.docs.fold(0.0, (sum, doc) => sum + (doc['distance'] as double));

        setState(() {
          activities = totalActivities;
          time = '${totalMinutes ~/ 60}h ${totalMinutes % 60}m';
          distance = totalDistance;
        });
      }
    } catch (e) {
      print('Error fetching weekly progress: $e');
    }
  }

  Future<void> _fetchPlansForSelectedDate() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Create the start and end of the selected day for comparison
        final startOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
        final endOfDay = startOfDay.add(Duration(days: 1));

        // Query to get plans for the selected date
        final snapshot = await FirebaseFirestore.instance
            .collection('user_plans')
            .doc(user.uid)
            .collection('plans')
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('date', isLessThan: Timestamp.fromDate(endOfDay))
            .get();

        setState(() {
          plansByTime = {
            for (var doc in snapshot.docs)
              doc['time'] as String: doc['description'] as String
          };
        });
      } catch (e) {
        // Handle errors (e.g., network issues, permission issues)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching plans: $e")),
        );
      }
    } else {
      // Handle the case where the user is not logged in
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User not logged in")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF561C24),
      appBar: AppBar(
        backgroundColor: const Color(0xFF561C24),
        elevation: 0,
        title: Text('HOME', style: AppFonts.bold.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        )),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_outlined, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildWeeklyProgress(),
              _buildCalendar(),
              Expanded(child: _buildTimeSlots()),
            ],
          ),
          Positioned(
            bottom: 70,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.black,
              child: Icon(Icons.add, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NewEventScreen()),
                );
              },
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: const Color(0xFF561C24),
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Icon(Icons.home, color: Colors.white),
                  Icon(Icons.work, color: Colors.white),
                  Icon(Icons.calendar_today, color: Colors.white),
                  Icon(Icons.chat_bubble_outline, color: Colors.white),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SettingsScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyProgress() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Weekly Progress',
            style: AppFonts.light.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildProgressItem('Activities', activities.toString(), '0'),
              _buildProgressItem('Time', time, '0'),
              _buildProgressItem('Distance', '${distance.toStringAsFixed(2)}km', '0'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem(String label, String value, String delta) {
    return Column(
      children: [
        Text(
          label,
          style: AppFonts.light.copyWith(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppFonts.light.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        Row(
          children: [
            const Icon(Icons.arrow_upward, size: 12, color: Colors.green),
            Text(delta, style: AppFonts.light.copyWith(color: Colors.green)),
          ],
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    final weekStart = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
    final days = List.generate(7, (index) => weekStart.add(Duration(days: index)));

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMMM yyyy').format(selectedDate),
                  style: AppFonts.medium.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.view_list, color: Colors.black),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.search, color: Colors.black),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 7,
              itemBuilder: (context, index) {
                final date = days[index];
                final isSelected = date.day == selectedDate.day;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedDate = date;
                    });
                    _fetchPlansForSelectedDate();
                  },
                  child: Container(
                    width: 50,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: isSelected ? Colors.blue : Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                      color: isSelected ? Colors.blue.withOpacity(0.1) : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('E').format(date).substring(0, 1),
                          style: AppFonts.light.copyWith(
                            fontSize: 12,
                            color: isSelected ? Colors.blue : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          date.day.toString(),
                          style: AppFonts.light.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.blue : Colors.black,
                          ),
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
    );
  }

  Widget _buildTimeSlots() {
    return Container(
      color: Colors.white,
      child: ListView.builder(
        itemCount: timeSlots.length,
        itemBuilder: (context, index) {
          final time = timeSlots[index];
          final plan = plansByTime[time] ?? '';
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 70,
                  child: Text(
                    time,
                    style: AppFonts.light.copyWith(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showAddPlanDialog(time),
                    child: Container(
                      height: 24,
                      decoration: BoxDecoration(
                        color: plan.isNotEmpty ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          plan.isNotEmpty ? plan : 'Add plan',
                          style: AppFonts.regular.copyWith(
                            fontSize: 12,
                            color: plan.isNotEmpty ? Colors.black87 : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddPlanDialog(String time) {
    final TextEditingController controller = TextEditingController(text: plansByTime[time] ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Plan for $time', style: AppFonts.regular.copyWith()),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'Enter your plan'),
          style: AppFonts.regular.copyWith(),
        ),
        actions: [
          TextButton(
            child: Text('Cancel', style: AppFonts.light.copyWith()),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text('Save', style: AppFonts.light.copyWith()),
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                if (controller.text.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('user_plans')
                      .doc(user.uid)
                      .collection('plans')
                      .doc('${selectedDate.toIso8601String()}_$time')
                      .set({
                    'date': Timestamp.fromDate(DateTime(selectedDate.year, selectedDate.month, selectedDate.day)),
                    'time': time,
                    'description': controller.text,
                  });
                } else {
                  await FirebaseFirestore.instance
                      .collection('user_plans')
                      .doc(user.uid)
                      .collection('plans')
                      .doc('${selectedDate.toIso8601String()}_$time')
                      .delete();
                }
                _fetchPlansForSelectedDate();
              }
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}