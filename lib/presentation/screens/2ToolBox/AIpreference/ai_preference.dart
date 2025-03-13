import 'package:flutter/material.dart';

class AIPreference extends StatefulWidget {
  @override
  _AIPreferenceState createState() => _AIPreferenceState();
}

class _AIPreferenceState extends State<AIPreference> {
  int step = 0; // Track UI state

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: step > 0
            ? IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () => setState(() => step--),
              )
            : null,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png', height: 100),
            SizedBox(height: 20),
            if (step == 0) buildIntroScreen(),
            if (step == 1) buildAIInputScreen(),
            if (step == 2) buildAIResponseScreen(),
          ],
        ),
      ),
    );
  }

  Widget buildIntroScreen() {
    return Column(
      children: [
        Image.asset('assets/images/ai-bike.png',
            height: 150), // Replace with actual image
        SizedBox(height: 20),
        Text(
          "CREATE WITH AI",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text("Let’s dive into your personalized set up guide"),
        SizedBox(height: 30),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
          onPressed: () => setState(() => step = 1),
          child: Text("Get started", style: TextStyle(color: Colors.white)),
        )
      ],
    );
  }

  Widget buildAIInputScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Transform your cycling experience with Bike AI",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text("Smarter rides, safer journeys, and endless adventures"),
        SizedBox(height: 20),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text("Ask anything..."),
              ),
              Icon(Icons.mic, color: Colors.grey),
            ],
          ),
        ),
        SizedBox(height: 20),
        buildAIButtons(),
      ],
    );
  }

  Widget buildAIResponseScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Transform your cycling experience with Bike AI",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text("Smarter rides, safer journeys, and endless adventures"),
        SizedBox(height: 20),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("AI Response:"),
              Text("1. Measure bike speed and angle for safety.",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text("2. AI adjusts resistance for efficient riding.",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        SizedBox(height: 20),
        buildAIButtons(),
      ],
    );
  }

  Widget buildAIButtons() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.upload_file, color: Colors.brown),
            SizedBox(width: 10),
            Text("Upload Image"),
            SizedBox(width: 20),
            Icon(Icons.attachment, color: Colors.brown),
            SizedBox(width: 10),
            Text("Add Attachment"),
          ],
        ),
        SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
          onPressed: () => setState(() => step = 2),
          child:
              Text("Generate with AI", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
