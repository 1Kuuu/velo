import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:velora/core/configs/theme/app_fonts.dart';
import 'package:velora/core/configs/theme/theme_provider.dart';
import 'package:velora/presentation/screens/4Chat/chat.dart';
import 'package:velora/presentation/screens/0Auth/profile.dart';
import 'package:velora/presentation/widgets/reusable_wdgts.dart';
import 'package:provider/provider.dart';

class MutedChatsScreen extends StatelessWidget {
  const MutedChatsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : AppColors.lightBackground,
      appBar: MyAppBar(
        title: "Muted Chats",
        actions: [],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chat_preferences')
            .doc(currentUserId)
            .snapshots(),
        builder: (context, prefsSnapshot) {
          if (prefsSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!prefsSnapshot.hasData || !prefsSnapshot.data!.exists) {
            return _buildEmptyState(isDarkMode, "No muted chats", "Muted conversations will appear here");
          }

          final chatPrefs = prefsSnapshot.data!.data() as Map<String, dynamic>?;
          final List<String> mutedChats = List<String>.from(chatPrefs?['muted_chats'] ?? []);

          if (mutedChats.isEmpty) {
            return _buildEmptyState(isDarkMode, "No muted chats", "Muted conversations will appear here");
          }

          return ListView.builder(
            itemCount: mutedChats.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final chatId = mutedChats[index];
              return _buildChatItem(context, chatId, currentUserId, isDarkMode);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 64,
            color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppFonts.semibold.copyWith(
              fontSize: 18,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppFonts.regular.copyWith(
              fontSize: 14,
              color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem(BuildContext context, String chatId, String currentUserId, bool isDarkMode) {
    // Extract the other user's ID from the chat ID format: user1_user2
    final userIds = chatId.split('_');
    final otherUserId = userIds[0] == currentUserId ? userIds[1] : userIds[0];

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final String name = userData['userName'] ?? userData['email']?.split('@')[0] ?? "Unknown";
        final String profileUrl = userData['profileUrl'] ?? "";

        return Dismissible(
          key: Key(chatId),
          background: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.notifications_active, color: Colors.white),
          ),
          secondaryBackground: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.archive, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.endToStart) {
              // Archive without confirmation
              _archiveConversation(chatId);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Conversation with $name archived'),
                  action: SnackBarAction(
                    label: 'UNDO',
                    onPressed: () {
                      _unarchiveConversation(chatId);
                      _muteConversation(chatId); // Restore muted status
                    },
                  ),
                ),
              );
              return true;
            } else {
              // Unmute without confirmation
              _unmuteConversation(chatId);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Notifications enabled for $name')),
              );
              return true;
            }
          },
          onDismissed: (direction) {
            // No additional action needed as we handle all in confirmDismiss
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[900] : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode ? Colors.grey[800]! : Colors.grey[100]!,
              ),
            ),
            child: ListTile(
              leading: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfilePage(userId: otherUserId),
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: _generateRandomColor(name),
                  backgroundImage: _hasProfilePicture(profileUrl)
                      ? NetworkImage(profileUrl)
                      : null,
                  child: !_hasProfilePicture(profileUrl)
                      ? Text(
                          _getInitials(name),
                          style: AppFonts.bold.copyWith(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        )
                      : null,
                ),
              ),
              title: Row(
                children: [
                  Text(
                    name,
                    style: AppFonts.semibold.copyWith(
                      fontSize: 16,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.notifications_off,
                    size: 16,
                    color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                  ),
                ],
              ),
              subtitle: Text(
                "Muted conversation",
                style: AppFonts.regular.copyWith(
                  color: isDarkMode ? Colors.grey[400] : const Color.fromRGBO(158, 158, 158, 1),
                  fontSize: 14,
                ),
              ),
              trailing: Text(
                "Swipe to unmute",
                style: AppFonts.regular.copyWith(
                  color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatPageContent(
                      chatId: chatId,
                      recipientId: otherUserId,
                      recipientName: name,
                      recipientProfileUrl: profileUrl,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _archiveConversation(String chatId) async {
    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;
      
      await FirebaseFirestore.instance
          .collection('chat_preferences')
          .doc(userId)
          .set({
        'archived_chats': FieldValue.arrayUnion([chatId]),
        'muted_chats': FieldValue.arrayRemove([chatId]), // Remove from muted when archiving
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error archiving conversation: $e');
    }
  }

  void _unarchiveConversation(String chatId) async {
    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;
      
      await FirebaseFirestore.instance
          .collection('chat_preferences')
          .doc(userId)
          .update({
        'archived_chats': FieldValue.arrayRemove([chatId])
      });
    } catch (e) {
      print('Error unarchiving conversation: $e');
    }
  }

  void _muteConversation(String chatId) async {
    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;
      
      await FirebaseFirestore.instance
          .collection('chat_preferences')
          .doc(userId)
          .set({
        'muted_chats': FieldValue.arrayUnion([chatId])
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error muting conversation: $e');
    }
  }

  void _unmuteConversation(String chatId) async {
    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;
      
      await FirebaseFirestore.instance
          .collection('chat_preferences')
          .doc(userId)
          .update({
        'muted_chats': FieldValue.arrayRemove([chatId])
      });
    } catch (e) {
      print('Error unmuting conversation: $e');
    }
  }

  bool _hasProfilePicture(String? url) {
    return url != null && url.isNotEmpty;
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return "?";
    return name[0].toUpperCase();
  }

  Color _generateRandomColor(String? text) {
    if (text == null || text.isEmpty) return Colors.grey;
    return Colors.primaries[text.hashCode.abs() % Colors.primaries.length];
  }
} 