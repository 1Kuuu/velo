import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:velora/presentation/widgets/reusable_wdgts.dart';

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

// Helper function to format TimeOfDay
String formatTimeOfDay(TimeOfDay timeOfDay) {
  final now = DateTime.now();
  final dateTime =
      DateTime(now.year, now.month, now.day, timeOfDay.hour, timeOfDay.minute);
  final format = DateFormat.jm(); // This will give you the time in AM/PM format
  return format.format(dateTime);
}

// Event Modal functionality
class EventModalHelper {
  // Show new event modal
  static void showNewEventModal(
    BuildContext context, {
    Event? existingEvent,
    required DateTime selectedDate,
    required Function(Event) onEventCreated,
    required Function(Event) onEventUpdated,
  }) {
    // If editing an existing event, use its values, otherwise use defaults
    DateTime? eventDate = existingEvent?.date ?? selectedDate;
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
                                date: eventDate ?? DateTime.now(),
                                startTime: startTime,
                                endTime: endTime,
                                isAllDay: isAllDay,
                                repeatStatus: repeatStatus,
                                color: selectedColor, // Use the selected color
                              );

                              onEventUpdated(updatedEvent);
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
                                date: eventDate ?? DateTime.now(),
                                startTime: startTime,
                                endTime: endTime,
                                isAllDay: isAllDay,
                                repeatStatus: repeatStatus,
                                color: selectedColor, // Use the selected color
                              );

                              onEventCreated(newEvent);
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
                          CustomDatePicker(
                            initialDate: eventDate!,
                            onDateSelected: (DateTime pickedDate) {
                              setModalState(() {
                                eventDate = pickedDate;
                              });
                            },
                            child: _buildTile(
                              icon: Icons.calendar_today,
                              text:
                                  DateFormat('EEEE, MMMM d').format(eventDate!),
                            ),
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
                              _buildColorOption(
                                Colors.red,
                                selectedColor,
                                () {
                                  setModalState(() {
                                    selectedColor = Colors.red;
                                  });
                                },
                              ),
                              _buildColorOption(
                                Colors.blue,
                                selectedColor,
                                () {
                                  setModalState(() {
                                    selectedColor = Colors.blue;
                                  });
                                },
                              ),
                              _buildColorOption(
                                Colors.green,
                                selectedColor,
                                () {
                                  setModalState(() {
                                    selectedColor = Colors.green;
                                  });
                                },
                              ),
                              _buildColorOption(
                                Colors.orange,
                                selectedColor,
                                () {
                                  setModalState(() {
                                    selectedColor = Colors.orange;
                                  });
                                },
                              ),
                              _buildColorOption(
                                Colors.purple,
                                selectedColor,
                                () {
                                  setModalState(() {
                                    selectedColor = Colors.purple;
                                  });
                                },
                              ),
                              _buildColorOption(
                                Colors.teal,
                                selectedColor,
                                () {
                                  setModalState(() {
                                    selectedColor = Colors.teal;
                                  });
                                },
                              ),
                              _buildColorOption(
                                Colors.brown,
                                selectedColor,
                                () {
                                  setModalState(() {
                                    selectedColor = Colors.brown;
                                  });
                                },
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

  // Helper widgets for the modal
  static Widget _buildTimeButton(String time, {required VoidCallback onTap}) {
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

  static Widget _buildTile(
      {required IconData icon, required String text, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(text),
      onTap: onTap,
      trailing: const Icon(Icons.arrow_drop_down),
    );
  }

  static Widget _buildSwitchTile({
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

  static Widget _buildDropdownTile({
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

  static Widget _buildColorOption(
      Color color, Color selectedColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selectedColor == color ? Colors.white : Colors.transparent,
            width: 2,
          ),
          boxShadow: selectedColor == color
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
      ),
    );
  }
}
