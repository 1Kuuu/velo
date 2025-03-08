import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:velora/presentation/screens/0Auth/profile.dart';
import 'package:velora/presentation/screens/4Chat/chat.dart';
import 'package:velora/presentation/widgets/reusable_wdgts.dart'; // Import reusable widgets

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: Colors.white, // You can use AppColors if needed
      appBar: MyAppBar(
        title: "Chats",
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
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("users").snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No users found."));
          }

          var users = snapshot.data!.docs
              .where((doc) => doc.id != currentUserId) // Exclude current user
              .toList();

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var userData = users[index].data() as Map<String, dynamic>;
              String userId = users[index].id;
              String name = userData["userName"] ?? "Unknown";
              String profileUrl = userData["profileUrl"] ?? "";

              return ListTile(
                leading: GestureDetector(
                  onTap: () {
                    // Navigate to profile page when tapping profile picture
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfilePage(userId: userId),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    backgroundColor: _generateRandomColor(name),
                    backgroundImage: _hasProfilePicture(profileUrl)
                        ? NetworkImage(profileUrl)
                        : null,
                    child: !_hasProfilePicture(profileUrl)
                        ? Text(
                            _getInitials(name),
                            style: const TextStyle(
                                fontSize: 20, color: Colors.white),
                          )
                        : null,
                  ),
                ),
                title: Text(name),
                onTap: () {
                  // Navigate to chat page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPageContent(
                        chatId: _generateChatId(currentUserId, userId),
                        recipientId: userId,
                        recipientName: name,
                        recipientProfileUrl: profileUrl,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  /// ✅ **Checks if a profile picture exists**
  bool _hasProfilePicture(String? url) {
    return url != null && url.isNotEmpty;
  }

  /// ✅ **Extracted logic to get initials**
  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return "?";
    return name[0].toUpperCase();
  }

  /// ✅ **Generates a random color based on username**
  Color _generateRandomColor(String? text) {
    return Colors.primaries[text!.hashCode.abs() % Colors.primaries.length];
  }

  /// Generate a unique chat ID for two users
  String _generateChatId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2]..sort();
    return ids.join("_");
  }
}
