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

class ArchivedChatsScreen extends StatelessWidget {
  const ArchivedChatsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : AppColors.lightBackground,
      appBar: MyAppBar(
        title: "Archived Chats",
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
            return _buildEmptyState(isDarkMode, "No archived chats", "Archived conversations will appear here");
          }

          final chatPrefs = prefsSnapshot.data!.data() as Map<String, dynamic>?;
          final List<String> archivedChats = List<String>.from(chatPrefs?['archived_chats'] ?? []);

          if (archivedChats.isEmpty) {
            return _buildEmptyState(isDarkMode, "No archived chats", "Archived conversations will appear here");
          }

          return ListView.builder(
            itemCount: archivedChats.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final chatId = archivedChats[index];
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
            Icons.archive_outlined,
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
            child: const Icon(Icons.unarchive, color: Colors.white),
          ),
          secondaryBackground: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.endToStart) {
              // Delete confirmation
              return await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Delete Conversation'),
                  content: Text('Are you sure you want to delete your conversation with $name?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('CANCEL'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text('DELETE', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ) ?? false;
            } else {
              // Unarchive without confirmation
              _unarchiveConversation(chatId);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Conversation with $name unarchived')),
              );
              return true;
            }
          },
          onDismissed: (direction) {
            if (direction == DismissDirection.endToStart) {
              _deleteConversation(chatId);
            }
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
              title: Text(
                name,
                style: AppFonts.semibold.copyWith(
                  fontSize: 16,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              subtitle: Text(
                "Archived conversation",
                style: AppFonts.regular.copyWith(
                  color: isDarkMode ? Colors.grey[400] : const Color.fromRGBO(158, 158, 158, 1),
                  fontSize: 14,
                ),
              ),
              trailing: Text(
                "Swipe to unarchive",
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

  void _deleteConversation(String chatId) async {
    try {
      // Delete messages in this conversation
      final messagesRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages');
          
      // Get all messages
      final messages = await messagesRef.get();
      
      // Delete each message
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in messages.docs) {
        batch.delete(doc.reference);
      }
      
      // Commit batch delete
      await batch.commit();
      
      // Remove chat from preferences
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final userPrefsRef = FirebaseFirestore.instance
            .collection('chat_preferences')
            .doc(userId);
            
        await userPrefsRef.update({
          'archived_chats': FieldValue.arrayRemove([chatId]),
          'muted_chats': FieldValue.arrayRemove([chatId]),
          'deleted_chats': FieldValue.arrayUnion([chatId])
        });
      }
    } catch (e) {
      print('Error deleting conversation: $e');
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