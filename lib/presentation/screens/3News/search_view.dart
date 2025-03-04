import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: SizedBox(
          height: 40,
          child: TextField(
            onChanged: (value) {
              setState(() {
                searchName = value
                    .toLowerCase(); // 🔹 Convert to lowercase for better search
              });
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              filled: true,
              fillColor: Color.fromARGB(255, 39, 39, 39),
              hintText: 'Search users...',
              hintStyle: TextStyle(color: Colors.grey),
              prefixIcon: Icon(Icons.search, color: Colors.grey),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
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
                child: Text("No users found",
                    style: TextStyle(color: Colors.grey)));
          }

          // 🔥 Filtering results based on search input
          var filteredUsers = snapshot.data!.docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            String name = (data['name'] ?? "").toLowerCase();
            return name.contains(searchName) &&
                data['uid'] != currentUserId; // Exclude current user
          }).toList();

          if (filteredUsers.isEmpty) {
            return Center(
                child: Text("No matching users found",
                    style: TextStyle(color: Colors.grey)));
          }

          return ListView.builder(
            itemCount: filteredUsers.length,
            itemBuilder: (context, index) {
              var data = filteredUsers[index].data() as Map<String, dynamic>;

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage:
                      data['profileUrl'] != null && data['profileUrl'] != ""
                          ? NetworkImage(data['profileUrl'])
                          : AssetImage("assets/profile.jpg") as ImageProvider,
                ),
                title: Text(data['name'] ?? "Unknown User",
                    style: TextStyle(color: Colors.white)),
                subtitle: Text(data['email'] ?? "No email available",
                    style: TextStyle(color: Colors.grey)),
              );
            },
          );
        },
      ),
    );
  }
}
