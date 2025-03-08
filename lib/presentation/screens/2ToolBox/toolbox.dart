import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:velora/presentation/screens/0Auth/profile.dart';
import 'package:velora/presentation/screens/2ToolBox/Roadbike/roadbike_info.dart';
import 'package:velora/presentation/widgets/reusable_wdgts.dart';

class ToolboxPageContent extends StatelessWidget {
  const ToolboxPageContent({super.key});

  Future<String?> getSelectedBike() async {
    var user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var doc = await FirebaseFirestore.instance
          .collection('user_preferences')
          .doc(user.uid)
          .get();

      return doc.data()?['bike_type'];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: MyAppBar(
        title: "Toolbox",
        actions: [
          AppBarIcon(
            icon: Icons.cloud_outlined,
            onTap: () => print("Weather Tapped"),
            showBadge: false,
          ),
          AppBarIcon(
            icon: Icons.notifications_outlined,
            onTap: () => print("Notifications Tapped"),
          ),
          AppBarIcon(
            icon: Icons.person_outline,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfilePage()),
            ),
          ),
        ],
      ),
      body: FutureBuilder<String?>(
        future: getSelectedBike(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            return BikeScreen(bikeType: snapshot.data!);
          }
          return Center(child: Text("No Bike Selected"));
        },
      ),
      floatingActionButton: TheFloatingActionButton(
        svgAsset: 'assets/svg/white-m.svg',
        onPressed: () => print("FAB Pressed"),
        backgroundColor: Colors.black,
        heroTag: 'openai_fab',
      ),
    );
  }
}

class BikeScreen extends StatefulWidget {
  final String bikeType;

  const BikeScreen({super.key, required this.bikeType});

  @override
  _BikeScreenState createState() => _BikeScreenState();
}

class _BikeScreenState extends State<BikeScreen> {
  late String selectedBike;
  double opacity = 1.0;

  @override
  void initState() {
    super.initState();
    selectedBike = widget.bikeType.toLowerCase();
  }

  void changeBike(String newBike) async {
    setState(() {
      opacity = 0.0; // Start Fade Out
    });

    await Future.delayed(
        Duration(milliseconds: 300)); // Wait for fade-out animation

    setState(() {
      selectedBike = newBike.toLowerCase();
      opacity = 1.0; // Start Fade In
    });
  }

  final List<String> titles = [
    'HANDLE',
    'WHEELS',
    'FRAME',
    'SADDLE',
    'CRANK',
    'SHIFTER'
  ];

  final List<String> images = [
    'assets/images/rd-Handle.png',
    'assets/images/rd-Wheels.png',
    'assets/images/rd-Frame.png',
    'assets/images/rd-Sadle.png',
    'assets/images/rd-Crank.png',
    'assets/images/rd-Shifter.png',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.brown,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                height: 200,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      selectedBike,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    SizedBox(height: 16),
                    Expanded(
                      child: Image.asset(
                        'assets/images/${selectedBike.toLowerCase()}.png',
                        width: 250,
                        height: 150,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 150,
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Sorting Dropdown & "Change" Buttonflu
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey, width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.swap_vert, size: 18, color: Colors.black),
                    SizedBox(width: 5),
                    DropdownButton<String>(
                      value: 'Most Recent',
                      underline: SizedBox(),
                      items: ['Most Recent', 'Previous', 'Old']
                          .map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: TextStyle(fontSize: 10, color: Colors.black),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {},
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          backgroundColor: Colors.grey[800],
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(20), // Rounded box
                          ),
                          content: Container(
                            height: 535,
                            width: 535,
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    FirebaseFirestore.instance
                                        .collection('user_preferences')
                                        .doc(FirebaseAuth
                                            .instance.currentUser?.uid)
                                        .update({'bike_type': 'ROADBIKE'});
                                    changeBike('ROADBIKE'.toUpperCase());
                                    (context as Element).markNeedsBuild();
                                  },
                                  child: Container(
                                    margin: EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(
                                          255, 255, 255, 255),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: ListTile(
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 15), // Larger padding
                                      title: Text(
                                        'ROAD BIKE',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize:
                                              14, // Adjust text size to fit better
                                        ),
                                      ),
                                      subtitle: Container(
                                        height:
                                            105, // Box height large enough to fit the image
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                              20), // Rounded corners
                                          color: Colors.grey[
                                              300], // Background like in your image
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          child: Image.asset(
                                            'assets/images/roadbike.png',
                                            fit: BoxFit
                                                .contain, // Make the image fit perfectly
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    FirebaseFirestore.instance
                                        .collection('user_preferences')
                                        .doc(FirebaseAuth
                                            .instance.currentUser?.uid)
                                        .update({'bike_type': 'MOUNTAINBIKE'});
                                    changeBike('MOUNTAINBIKE'.toUpperCase());
                                    (context as Element).markNeedsBuild();
                                  },
                                  child: Container(
                                    margin: EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(
                                          255, 255, 255, 255),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: ListTile(
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 15), // Larger padding
                                      title: Text(
                                        'MOUNTAIN BIKE',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize:
                                              14, // Adjust text size to fit better
                                        ),
                                      ),
                                      subtitle: Container(
                                        height:
                                            105, // Box height large enough to fit the image
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                              20), // Rounded corners
                                          color: Colors.grey[
                                              300], // Background like in your image
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          child: Image.asset(
                                            'assets/images/mountainbike.png',
                                            fit: BoxFit
                                                .cover, // Make the image fit perfectly
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    FirebaseFirestore.instance
                                        .collection('user_preferences')
                                        .doc(FirebaseAuth
                                            .instance.currentUser?.uid)
                                        .update({'bike_type': 'FIXIE'});
                                    changeBike('FIXIE'.toUpperCase());
                                    (context as Element).markNeedsBuild();
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(
                                          255, 255, 255, 255),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: ListTile(
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 15), // Larger padding
                                      title: Text(
                                        'FIXIE',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize:
                                              14, // Adjust text size to fit better
                                        ),
                                      ),
                                      subtitle: Container(
                                        height:
                                            105, // Box height large enough to fit the image
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                              20), // Rounded corners
                                          color: Colors.grey[
                                              300], // Background like in your image
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          child: Image.asset(
                                            'assets/images/fixie.png',
                                            fit: BoxFit
                                                .cover, // Make the image fit perfectly
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  child: Text(
                    'Change',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                )
              ],
            ),
          ),
          SizedBox(height: 2),

          // GridView for Components
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(8),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.2,
              ),
              itemCount: titles.length,
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () {
                    print('${titles[index]} Tapped');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RoadbikeInfo(
                            title: titles[index]), // Replace with your page
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.brown, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(images[index], height: 60),
                        SizedBox(height: 6),
                        Text(
                          titles[index],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
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
}
