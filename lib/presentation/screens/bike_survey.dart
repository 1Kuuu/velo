import 'package:flutter/material.dart';
import 'signup.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bike Preferences',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: Signup(),
    );
  }
}

class BikeSelectionScreen extends StatefulWidget {
  const BikeSelectionScreen({super.key});
  @override
  _BikeSelectionScreenState createState() => _BikeSelectionScreenState();
}

class _BikeSelectionScreenState extends State<BikeSelectionScreen> {
  String selectedBike = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 40),
            Text(
              'VELCRA',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'WHAT',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade900,
              ),
            ),
            Text(
              'TYPE OF BIKE ARE YOU USING?',
              style: TextStyle(
                fontSize: 36,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'SELECT HERE:',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            SizedBox(height: 30),
            buildBikeOption('Roadbike', 'assets/images/mb.png'),
            buildBikeOption('Mountainbike', 'assets/images/mb1.png'),
            buildBikeOption('Fixie', 'assets/images/fx1.png'),
          ],
        ),
      ),
    );
  }

  Widget buildBikeOption(String bikeType, String imagePath) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RidingTimeScreen()),
        );
        setState(() {
          selectedBike = bikeType;
        });
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8),
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selectedBike == bikeType
                ? Colors.red.shade900
                : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Image.asset(imagePath, height: 100),
            SizedBox(height: 5),
            Text(
              bikeType.toUpperCase(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: selectedBike == bikeType
                    ? Colors.red.shade900
                    : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RidingTimeScreen extends StatelessWidget {
  const RidingTimeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Velora',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: RidingScheduleScreen(),
    );
  }
}

class RidingScheduleScreen extends StatefulWidget {
  @override
  _RidingScheduleScreen createState() => _RidingScheduleScreen();
}

class _RidingScheduleScreen extends State<RidingScheduleScreen> {
  Map<String, bool> preferences = {
    'Morning': false,
    'Afternoon': false,
    'Night': false,
    'Weekdays': false,
    'Weekends': false,
    'Fitness': false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 40),
            Text(
              'VELCRA',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'WHEN',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade900,
              ),
            ),
            Text(
              'DO YOU USUALLY RIDE?',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 20),
            ...preferences.keys.map((key) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5.0),
                  child: CheckboxListTile(
                    title: Text(
                      key,
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                    value: preferences[key],
                    onChanged: (bool? value) {
                      setState(() {
                        preferences[key] = value!;
                      });
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    tileColor: Colors.grey.shade200,
                    checkColor: Colors.white,
                    activeColor: Colors.red.shade900,
                  ),
                )),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => RidingLocationScreen()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade900,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 50),
                ),
                child: Text(
                  'Next',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TimeOption extends StatelessWidget {
  final String label;
  const TimeOption(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      title: Text(label),
      value: false,
      onChanged: (bool? value) {},
    );
  }
}

class RidingLocationScreen extends StatelessWidget {
  const RidingLocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("WHERE")),
      body: Column(
        children: [
          Text("DO YOU LIKE TO RIDE?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Expanded(
            child: ListView(
              children: [
                TimeOption("Coastal Routes"),
                TimeOption("City Streets"),
                TimeOption("Parks"),
                TimeOption("Mountains"),
                TimeOption("Country Routes"),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SummaryScreen()),
            ),
            child: Text("Done"),
          ),
        ],
      ),
    );
  }
}

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("WELCOME!")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("SEEMS LIKE YOU LOVE:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(
              width: 100,
              height: 100,
              child: Image.asset("assets/fx1.png", fit: BoxFit.cover),
            ),
            ElevatedButton(
              onPressed: () {},
              child: Text("START"),
            ),
          ],
        ),
      ),
    );
  }
}
