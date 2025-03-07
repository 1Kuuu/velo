import 'dart:math'; // For random color generation
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:velora/presentation/widgets/reusable_wdgts.dart' show MyAppBar;

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  String searchName = "";
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(
        title: '',
        automaticallyImplyLeading: true, // Enables default back button
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10, left: 10),
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.85,
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    searchName = value.toLowerCase();
                  });
                },
                style: TextStyle(
                    color: Colors.white), // 🔹 Set text color to white
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  filled: true,
                  fillColor: Color.fromARGB(255, 39, 39, 39),
                  hintText: 'Search users...',
                  hintStyle: TextStyle(color: Colors.grey),
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _buildUserList(),
    );
  }

  /// 🔹 Extracted method for fetching and displaying users
  Widget _buildUserList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Something went wrong'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text("No users found", style: TextStyle(color: Colors.grey)),
          );
        }

        var filteredUsers = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          String name = (data['userName'] ?? "").toLowerCase();
          return name.contains(searchName) && data['uid'] != currentUserId;
        }).toList();

        if (filteredUsers.isEmpty) {
          return Center(
            child: Text("No matching users found",
                style: TextStyle(color: Colors.grey)),
          );
        }

        return ListView(
          children: filteredUsers.map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            return _buildUserTile(data);
          }).toList(),
        );
      },
    );
  }

  /// 🔹 Extracted method for rendering each user tile
  Widget _buildUserTile(Map<String, dynamic> data) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _generateRandomColor(data['userName']), // Random color
        backgroundImage: data['profileUrl'] != null && data['profileUrl'] != ""
            ? NetworkImage(data['profileUrl'])
            : null,
        child: data['profileUrl'] == null || data['profileUrl'] == ""
            ? Text(
                (data['userName'] != null && data['userName'].isNotEmpty)
                    ? data['userName'][0].toUpperCase()
                    : "?",
                style: TextStyle(fontSize: 20, color: Colors.white),
              )
            : null,
      ),
      title: Text(data['userName'] ?? "Unknown User",
          style: TextStyle(color: Colors.black)),
      subtitle: Text(data['email'] ?? "No email available",
          style: TextStyle(color: Colors.grey)),
    );
  }

  /// 🎨 Generates a random color for each user based on their username
  Color _generateRandomColor(String? userName) {
    if (userName == null || userName.isEmpty) {
      return Colors.grey; // Default color if name is missing
    }
    final Random random = Random(userName.hashCode); // Hash ensures consistency
    return Color.fromARGB(
      255,
      100 + random.nextInt(156), // Not too dark
      100 + random.nextInt(156),
      100 + random.nextInt(156),
    );
  }
}
