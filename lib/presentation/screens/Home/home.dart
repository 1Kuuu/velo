import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:velora/core/configs/theme/app_fonts.dart';
import 'package:velora/presentation/screens/Home/neweventscreen.dart';
import 'package:velora/presentation/screens/Settings/setting.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime selectedDate = DateTime.now();
  int activities = 0;
  String time = '0h 0m';
  double distance = 0.0;
  Map<String, String> plansByTime = {};
  final List<String> timeSlots = [
    '8:00AM',
    '9:00AM',
    '10:00AM',
    '11:00AM',
    '12:00PM',
    '1:00PM',
    '2:00PM',
    '3:00PM',
    '4:00PM',
    '5:00PM'
  ];

  @override
  void initState() {
    super.initState();
    _fetchWeeklyProgress();
  }

  Future<void> _fetchWeeklyProgress() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('user_activities')
            .doc(user.uid)
            .collection('activities')
            .get();

        int totalActivities = snapshot.docs.length;
        int totalMinutes =
            snapshot.docs.fold(0, (sum, doc) => sum + (doc['duration'] as int));
        double totalDistance = snapshot.docs
            .fold(0.0, (sum, doc) => sum + (doc['distance'] as double));

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF561C24),
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Column(
            children: [
              _buildWeeklyProgress(),
              _buildCalendar(),
              Expanded(child: _buildTimeSlots()),
            ],
          ),
          _buildFloatingActionButton(),
          _buildBottomNavigationBar(),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF561C24),
      elevation: 0,
      title: Text('HOME',
          style: AppFonts.bold
              .copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
      actions: [
        IconButton(
            icon: const Icon(Icons.cloud_outlined, color: Colors.white),
            onPressed: () {}),
        IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {}),
        IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            onPressed: () {}),
      ],
    );
  }

  Widget _buildWeeklyProgress() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Weekly Progress',
              style: AppFonts.light.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildProgressItem('Activities', activities.toString()),
              _buildProgressItem('Time', time),
              _buildProgressItem(
                  'Distance', '${distance.toStringAsFixed(2)}km'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem(String label, String value) {
    return Column(
      children: [
        Text(label,
            style:
                AppFonts.light.copyWith(fontSize: 14, color: Colors.black87)),
        const SizedBox(height: 8),
        Text(value,
            style: AppFonts.light.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black)),
      ],
    );
  }

  Widget _buildCalendar() {
    final weekStart =
        selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
    final days =
        List.generate(7, (index) => weekStart.add(Duration(days: index)));

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: days.map((date) => _buildDayWidget(date)).toList(),
      ),
    );
  }

  Widget _buildDayWidget(DateTime date) {
    bool isSelected = date.day == selectedDate.day;
    return GestureDetector(
      onTap: () => setState(() => selectedDate = date),
      child: Container(
        width: 50,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? Colors.blue.withOpacity(0.1) : null,
        ),
        child: Column(
          children: [
            Text(DateFormat('E').format(date),
                style: AppFonts.light
                    .copyWith(color: isSelected ? Colors.blue : Colors.black)),
            const SizedBox(height: 4),
            Text('${date.day}',
                style: AppFonts.light.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.blue : Colors.black)),
          ],
        ),
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
          return ListTile(
            title: Text(time,
                style: AppFonts.light
                    .copyWith(fontSize: 14, color: Colors.black87)),
            trailing: Text(plansByTime[time] ?? 'Add plan',
                style: AppFonts.regular
                    .copyWith(fontSize: 12, color: Colors.grey[600])),
            onTap: () {},
          );
        },
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Positioned(
      bottom: 70,
      right: 20,
      child: FloatingActionButton(
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (context) => NewEventScreen())),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: BottomAppBar(
        color: const Color(0xFF561C24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Icon(Icons.home, color: Colors.white),
            Icon(Icons.work, color: Colors.white),
            Icon(Icons.calendar_today, color: Colors.white),
            Icon(Icons.chat_bubble_outline, color: Colors.white),
            IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (context) => SettingsScreen()))),
          ],
        ),
      ),
    );
  }
}
