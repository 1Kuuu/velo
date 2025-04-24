import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:velora/core/configs/theme/app_fonts.dart';
import 'package:velora/core/configs/theme/theme_provider.dart';
import 'package:velora/presentation/screens/0Auth/profile.dart';
import 'package:velora/presentation/screens/4Chat/chat.dart';
import 'package:velora/presentation/screens/Notifications/notifications_screen.dart';
import 'package:velora/presentation/widgets/reusable_wdgts.dart'; // Import reusable widgets
import 'package:provider/provider.dart';
import 'package:velora/presentation/screens/4Chat/archived_chats_screen.dart';
import 'package:velora/presentation/screens/4Chat/ignored_chats_screen.dart';
import 'package:velora/presentation/screens/4Chat/muted_chats_screen.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : AppColors.lightBackground,
      appBar: MyAppBar(
        title: "Chats",
        actions: [
          AppBarIcon(
            icon: Icons.notifications_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
              );
            },
          ),
          _ProfileIcon(),
        ],
      ),
      body: Column(
        children: [
          // Modern Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 45,
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      style: AppFonts.regular.copyWith(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search conversations',
                        hintStyle: AppFonts.regular.copyWith(
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 45,
                  width: 45,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.menu,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                      size: 20,
                    ),
                    onPressed: () {
                      _showFilterMenu(context);
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Users List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("users")
                  .where('email', isNotEqualTo: '')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 48,
                            color: isDarkMode
                                ? Colors.grey[600]
                                : Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          "No conversations yet",
                          style: AppFonts.semibold.copyWith(
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Start chatting with someone!",
                          style: AppFonts.regular.copyWith(
                            color: isDarkMode
                                ? Colors.grey[600]
                                : Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                var users = snapshot.data!.docs
                    .where((doc) => doc.id != currentUserId)
                    .toList();

                return ListView.builder(
                  itemCount: users.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    var userData = users[index].data() as Map<String, dynamic>;
                    String userId = users[index].id;
                    String name = userData["userName"] ??
                        userData["email"]?.split('@')[0] ??
                        "Unknown";
                    String profileUrl = userData["profileUrl"] ?? "";
                    String lastMessage = "Tap to start chatting";
                    
                    // Chat ID generation for operations
                    final chatId = _generateChatId(currentUserId, userId);

                    return Dismissible(
                      key: Key(userId),
                      background: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 20),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.archive, color: Colors.white),
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
                          // Delete action
                          return await _showDeleteConfirmation(context, name);
                        } else {
                          // Archive action
                          _archiveConversation(chatId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Conversation with $name archived'),
                              action: SnackBarAction(
                                label: 'UNDO',
                                onPressed: () => _unarchiveConversation(chatId),
                              ),
                            ),
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
                            color: isDarkMode
                                ? Colors.grey[800]!
                                : Colors.grey[100]!,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatPageContent(
                                    chatId: chatId,
                                    recipientId: userId,
                                    recipientName: name,
                                    recipientProfileUrl: profileUrl,
                                  ),
                                ),
                              );
                            },
                            onLongPress: () {
                              _showActionMenu(context, chatId, name);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ProfilePage(userId: userId),
                                        ),
                                      );
                                    },
                                    child: Hero(
                                      tag: 'profile_$userId',
                                      child: CircleAvatar(
                                        radius: 28,
                                        backgroundColor:
                                            ChatUtils.generateRandomColor(name),
                                        backgroundImage:
                                            ChatUtils.hasProfilePicture(
                                                    profileUrl)
                                                ? NetworkImage(profileUrl)
                                                : null,
                                        child: !ChatUtils.hasProfilePicture(
                                                profileUrl)
                                            ? Text(
                                                ChatUtils.getInitials(name),
                                                style: AppFonts.bold.copyWith(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                ),
                                              )
                                            : null,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: AppFonts.semibold.copyWith(
                                            fontSize: 16,
                                            color: isDarkMode
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          lastMessage,
                                          style: AppFonts.regular.copyWith(
                                            color: isDarkMode
                                                ? Colors.grey[400]
                                                : const Color.fromRGBO(
                                                    158, 158, 158, 1),
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.more_vert,
                                      size: 18,
                                      color: isDarkMode
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    ),
                                    onPressed: () {
                                      _showActionMenu(context, chatId, name);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Add methods for conversation actions
  Future<bool> _showDeleteConfirmation(BuildContext context, String name) async {
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
  }

  void _showActionMenu(BuildContext context, String chatId, String name) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.archive_outlined, color: Colors.orange),
            title: Text('Archive', style: AppFonts.regular),
            onTap: () {
              Navigator.pop(context);
              _archiveConversation(chatId);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Conversation with $name archived'),
                  action: SnackBarAction(
                    label: 'UNDO',
                    onPressed: () => _unarchiveConversation(chatId),
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.notifications_off_outlined, color: Colors.blue),
            title: Text('Mute', style: AppFonts.regular),
            onTap: () {
              Navigator.pop(context);
              _muteConversation(chatId);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Conversation with $name muted'),
                  action: SnackBarAction(
                    label: 'UNDO',
                    onPressed: () => _unmuteConversation(chatId),
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.visibility_off_outlined, color: Colors.red),
            title: Text('Ignore', style: AppFonts.regular),
            onTap: () {
              Navigator.pop(context);
              _ignoreConversation(chatId);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Conversation with $name ignored'),
                  action: SnackBarAction(
                    label: 'UNDO',
                    onPressed: () => _unignoreConversation(chatId),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
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
        'archived_chats': FieldValue.arrayUnion([chatId])
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

  String _generateChatId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2]..sort();
    return ids.join("_");
  }

  // Add methods for filter menu and ignore functionality
  void _showFilterMenu(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Conversation Filters',
              style: AppFonts.bold.copyWith(
                fontSize: 18,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.archive_outlined, color: Colors.orange),
            title: Text('Archived Chats', style: AppFonts.regular),
            onTap: () {
              Navigator.pop(context);
              _navigateToArchivedChats(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.visibility_off_outlined, color: Colors.red),
            title: Text('Ignored Chats', style: AppFonts.regular),
            onTap: () {
              Navigator.pop(context);
              _navigateToIgnoredChats(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.notifications_off_outlined, color: Colors.blue),
            title: Text('Muted Chats', style: AppFonts.regular),
            onTap: () {
              Navigator.pop(context);
              _navigateToMutedChats(context);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _navigateToArchivedChats(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ArchivedChatsScreen(),
      ),
    );
  }

  void _navigateToIgnoredChats(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const IgnoredChatsScreen(),
      ),
    );
  }

  void _navigateToMutedChats(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MutedChatsScreen(),
      ),
    );
  }

  void _ignoreConversation(String chatId) async {
    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;
      
      await FirebaseFirestore.instance
          .collection('chat_preferences')
          .doc(userId)
          .set({
        'ignored_chats': FieldValue.arrayUnion([chatId])
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error ignoring conversation: $e');
    }
  }

  void _unignoreConversation(String chatId) async {
    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;
      
      await FirebaseFirestore.instance
          .collection('chat_preferences')
          .doc(userId)
          .update({
        'ignored_chats': FieldValue.arrayRemove([chatId])
      });
    } catch (e) {
      print('Error unignoring conversation: $e');
    }
  }
}

class _ProfileIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AppBarIcon(
            icon: Icons.person_outline,
            onTap: () {},
          );
        }

        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        return ProfileAppBarIcon(
          profileUrl: userData?['profileUrl'],
          userName: userData?['userName'],
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
          },
        );
      },
    );
  }
}
