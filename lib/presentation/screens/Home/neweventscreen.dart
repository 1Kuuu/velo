import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NewEventScreen extends StatefulWidget {
  const NewEventScreen({super.key});

  @override
  _NewEventScreenState createState() => _NewEventScreenState();
}

class _NewEventScreenState extends State<NewEventScreen> {
  bool isAllDay = false;
  TimeOfDay startTime = TimeOfDay(hour: 9, minute: 0);
  TimeOfDay endTime = TimeOfDay(hour: 9, minute: 0);
  DateTime selectedDate = DateTime.now();
  String repeatOption = "Repeat";
  TextEditingController descriptionController = TextEditingController();
  TextEditingController titleController =
      TextEditingController(); // For event title

  // List of repeat options
  final List<String> repeatOptions = [
    "Does not repeat",
    "Daily",
    "Weekly",
    "Monthly",
    "Yearly",
    "Custom"
  ];

  List<Map<String, dynamic>> savedEvents = []; // To store events

  // Function to Pick Date
  Future<void> _pickDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  // Function to Pick Time
  Future<void> _pickTime(bool isStart) async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: isStart ? startTime : endTime,
    );
    if (pickedTime != null) {
      setState(() {
        if (isStart) {
          startTime = pickedTime;
        } else {
          endTime = pickedTime;
        }
      });
    }
  }

  // Function to Show Repeat Options
  void _selectRepeatOption() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(10),
          height: 300,
          child: Column(
            children: [
              Text(
                "Repeat Options",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: repeatOptions.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(repeatOptions[index]),
                      onTap: () {
                        setState(() {
                          repeatOption = repeatOptions[index];
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Function to Save Event
  void _saveEvent() async {
    if (titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter an event title")),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser; // Get current user
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('user_new_event') // Collection in Firestore
          .add({
        "title": titleController.text,
        "date":
            Timestamp.fromDate(selectedDate), // Store as Firestore Timestamp
        "startTime": startTime.format(context),
        "endTime": endTime.format(context),
        "allDay": isAllDay,
        "repeat": repeatOption,
        "description": descriptionController.text,
      });

      Navigator.pop(context, true); // Return to previous screen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving event: $e")),
      );
    }
  }

  // Function to Build Event Details
  Widget _buildEventDetails() {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          // Time Pickers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => _pickTime(true),
                child: Row(
                  children: [
                    Icon(Icons.access_time),
                    SizedBox(width: 8),
                    Text(startTime.format(context)),
                  ],
                ),
              ),
              Icon(Icons.arrow_right_alt),
              GestureDetector(
                onTap: () => _pickTime(false),
                child: Row(
                  children: [
                    Icon(Icons.access_time),
                    SizedBox(width: 8),
                    Text(endTime.format(context)),
                  ],
                ),
              ),
            ],
          ),
          Divider(),

          // Date Picker
          ListTile(
            leading: Icon(Icons.calendar_today),
            title: Text(
              DateFormat('EEEE, MMMM d')
                  .format(selectedDate), // Format: "Thursday, December 5"
              style: TextStyle(fontSize: 16),
            ),
            trailing: Icon(Icons.arrow_drop_down),
            onTap: () => _pickDate(context),
          ),
          Divider(),

          // All Day Toggle
          SwitchListTile(
            title: Text("All day"),
            value: isAllDay,
            onChanged: (value) {
              setState(() {
                isAllDay = value;
              });
            },
          ),
          Divider(),

          // Repeat Option
          ListTile(
            leading: Icon(Icons.refresh),
            title: Text(repeatOption),
            trailing: Icon(Icons.arrow_drop_down),
            onTap: _selectRepeatOption,
          ),
        ],
      ),
    );
  }

  // Function to Build Description Field
  Widget _buildDescription() {
    return Container(
      height: 100,
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: descriptionController,
        decoration: InputDecoration(
          hintText: "Description",
          border: InputBorder.none,
        ),
        maxLines: null,
        keyboardType: TextInputType.multiline,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Text(
            'Cancel',
            style: TextStyle(
              color: Colors.red,
              fontSize: 14,
            ),
            overflow: TextOverflow.visible,
          ),
          onPressed: () => Navigator.pop(context),
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.zero,
        ),
        title: Text("New Event",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saveEvent, // Call save function here
            child: Text("Save", style: TextStyle(color: Colors.green)),
          )
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Title Input
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  hintText: "HAPPIEST DAY ON EARTH!!",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),

              // Event Details
              _buildEventDetails(),
              SizedBox(height: 20),

              // Description Field
              _buildDescription(),
              SizedBox(height: 20),

              // Saved Events Display
              Text("Saved Events:",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(
                height: 200, // Set a fixed height for the list
                child: ListView.builder(
                  itemCount: savedEvents.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(savedEvents[index]["title"]),
                      subtitle: Text(
                        "${DateFormat('EEEE, MMMM d').format(savedEvents[index]["date"])} - "
                        "${savedEvents[index]["startTime"]} to ${savedEvents[index]["endTime"]}",
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
