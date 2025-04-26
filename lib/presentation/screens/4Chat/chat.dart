import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:velora/core/configs/theme/app_fonts.dart';
import 'package:velora/core/configs/theme/theme_provider.dart';
import 'package:velora/presentation/screens/4Chat/chat_list.dart';


class ChatPageContent extends StatefulWidget {
  final String chatId;
  final String recipientId;
  final String recipientName;
  final String recipientProfileUrl;

  const ChatPageContent({
    super.key,
    required this.chatId,
    required this.recipientId,
    required this.recipientName,
    required this.recipientProfileUrl,
  });

  @override
  _ChatPageContentState createState() => _ChatPageContentState();
}

class _ChatPageContentState extends State<ChatPageContent> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _senderName;
  String? _senderProfileUrl;
  late Stream<QuerySnapshot> _messageStream;

  @override
  void initState() {
    super.initState();
    _fetchSenderInfo();
    _markMessagesAsSeen();
    _setupMessageStream();
  }

  void _setupMessageStream() {
    _messageStream = FirebaseFirestore.instance
        .collection("chats/${widget.chatId}/messages")
        .orderBy("timestamp", descending: true)
        .snapshots();
  }

  Future<void> _fetchSenderInfo() async {
    var currentUser = _auth.currentUser;
    if (currentUser == null) return;
    var userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(currentUser.uid)
        .get();
    setState(() {
      _senderName = userDoc.data()?["userName"] ?? "Unknown";
      _senderProfileUrl = userDoc.data()?["profileUrl"] ?? "";
    });
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    var currentUser = _auth.currentUser;
    if (currentUser == null ||
        _senderName == null ||
        _senderProfileUrl == null) {
      return;
    }

    try {
      // Add message to chat collection
      var docRef = await FirebaseFirestore.instance
          .collection("chats/${widget.chatId}/messages")
          .add({
        "text": _messageController.text.trim(),
        "senderId": currentUser.uid,
        "senderName": _senderName,
        "senderProfileUrl": _senderProfileUrl,
        "timestamp": FieldValue.serverTimestamp(),
        "status": "sent",
      });

      // Update to delivered after server confirmation
      await docRef.update({"status": "delivered"});

      // Send notification to recipient
      await FirebaseFirestore.instance
          .collection("notifications")
          .add({
        "type": "message",
        "message": "sent you a message",
        "timestamp": FieldValue.serverTimestamp(),
        "isRead": false,
        "senderId": currentUser.uid,
        "recipientId": widget.recipientId,
        "messageText": _messageController.text.trim(),
      });

      _messageController.clear();
    } catch (e) {
      DelightToastBar(
        builder: (context) {
          return const ToastCard(
            title: Text('Failed to send message'),
            leading: Icon(Icons.error, color: Colors.red),
          );
        },
        position: DelightSnackbarPosition.top,
        autoDismiss: true,
        snackbarDuration: const Duration(seconds: 2),
        animationDuration: const Duration(milliseconds: 300),
      ).show(context);
    }
  }

  void _markMessagesAsSeen() async {
    var currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      // Instead of using batch, update messages one by one to comply with rules
      var query = FirebaseFirestore.instance
          .collection("chats/${widget.chatId}/messages")
          .where("senderId", isEqualTo: widget.recipientId)
          .where("status", isNotEqualTo: "seen");

      var snapshot = await query.get();
      
      // Update each message individually to comply with security rules
      for (var doc in snapshot.docs) {
        await doc.reference.update({"status": "seen"});
      }
    } catch (e) {
      print("Error marking messages as seen: $e");
      // We don't show an error to the user as this is a background operation
    }
  }

  // Add a method to delete a message
  Future<void> _deleteMessage(String messageId) async {
    try {
      await FirebaseFirestore.instance
          .collection("chats/${widget.chatId}/messages")
          .doc(messageId)
          .delete();
      
      // Show success toast
      if (mounted) {
        DelightToastBar(
          builder: (context) {
            return const ToastCard(
              title: Text('Message deleted'),
              leading: Icon(Icons.check_circle, color: Colors.green),
            );
          },
          position: DelightSnackbarPosition.top,
          autoDismiss: true,
          snackbarDuration: const Duration(seconds: 2),
          animationDuration: const Duration(milliseconds: 300),
        ).show(context);
      }
    } catch (e) {
      print("Error deleting message: $e");
      if (mounted) {
        DelightToastBar(
          builder: (context) {
            return const ToastCard(
              title: Text('Failed to delete message'),
              leading: Icon(Icons.error, color: Colors.red),
            );
          },
          position: DelightSnackbarPosition.top,
          autoDismiss: true,
          snackbarDuration: const Duration(seconds: 2),
          animationDuration: const Duration(milliseconds: 300),
        ).show(context);
      }
    }
  }

  // Add a method to confirm message deletion
  void _confirmDeleteMessage(String messageId, String messageText) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
        title: Text(
          'Delete Message',
          style: AppFonts.bold.copyWith(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this message?',
          style: AppFonts.regular.copyWith(
            color: isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppFonts.medium.copyWith(
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMessage(messageId);
            },
            child: Text(
              'Delete',
              style: AppFonts.medium.copyWith(
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteConversation() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
        title: Text(
          'Delete Conversation',
          style: AppFonts.bold.copyWith(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this entire conversation? This action cannot be undone.',
          style: AppFonts.regular.copyWith(
            color: isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppFonts.medium.copyWith(
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteConversation();
            },
            child: Text(
              'Delete',
              style: AppFonts.medium.copyWith(
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteConversation() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          ),
        );
      },
    );
    
    try {
      // Get all messages for this chat
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection("chats/${widget.chatId}/messages")
          .get();
      
      // Delete each message
      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        await FirebaseFirestore.instance
            .collection("chats/${widget.chatId}/messages")
            .doc(doc.id)
            .delete();
      }
      
      // Check if we need to delete the chat document itself
      // We'll add a field to mark it as deleted by the current user
      DocumentSnapshot chatDoc = await FirebaseFirestore.instance
          .collection("chats")
          .doc(widget.chatId)
          .get();
      
      if (chatDoc.exists) {
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        if (currentUserId != null) {
          // Create or update a "deletedBy" array field
          Map<String, dynamic> chatData = chatDoc.data() as Map<String, dynamic>;
          List<String> deletedBy = [];
          
          if (chatData.containsKey('deletedBy') && chatData['deletedBy'] is List) {
            deletedBy = List<String>.from(chatData['deletedBy']);
          }
          
          // Add current user to deletedBy list if not already there
          if (!deletedBy.contains(currentUserId)) {
            deletedBy.add(currentUserId);
          }
          
          // Update the chat document
          await FirebaseFirestore.instance
              .collection("chats")
              .doc(widget.chatId)
              .update({'deletedBy': deletedBy});
        }
      }
      
      // Dismiss loading dialog if it's still showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      if (mounted) {
        DelightToastBar(
          builder: (context) {
            return const ToastCard(
              title: Text('Conversation deleted'),
              leading: Icon(Icons.check_circle, color: Colors.green),
            );
          },
          position: DelightSnackbarPosition.top,
          autoDismiss: true,
          snackbarDuration: const Duration(seconds: 2),
          animationDuration: const Duration(milliseconds: 300),
        ).show(context);
        
        // Navigate back to chat list with replacement to force a refresh
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ChatListPage()),
        );
      }
    } catch (e) {
      // Dismiss loading dialog if it's still showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      print("Error deleting conversation: $e");
      if (mounted) {
        DelightToastBar(
          builder: (context) {
            return const ToastCard(
              title: Text('Failed to delete conversation'),
              leading: Icon(Icons.error, color: Colors.red),
            );
          },
          position: DelightSnackbarPosition.top,
          autoDismiss: true,
          snackbarDuration: const Duration(seconds: 2),
          animationDuration: const Duration(milliseconds: 300),
        ).show(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF1A1A1A) : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDarkMode ? const Color(0xFF4A3B7C) : AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
        title: Text(
          widget.recipientName,
          style: AppFonts.bold.copyWith(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        actions: [
          // Delete Conversation Button
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.white,
            ),
            onPressed: () => _confirmDeleteConversation(),
            tooltip: 'Delete Conversation',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _messageStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: isDarkMode ? Colors.white70 : AppColors.primary,
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      "No messages yet.",
                      style: AppFonts.regular.copyWith(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  );
                }

                var messages = snapshot.data!.docs;
                Map<String, List<QueryDocumentSnapshot>> groupedMessages = {};

                for (var message in messages) {
                  var timestamp =
                      (message["timestamp"] as Timestamp?)?.toDate();
                  if (timestamp == null) continue;
                  String dateKey = _formatDateKey(timestamp);
                  groupedMessages.putIfAbsent(dateKey, () => []).add(message);
                }

                return Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF212121) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView(
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    children: groupedMessages.entries.expand((entry) {
                      return [
                        DateHeader(dateKey: entry.key),
                        ...entry.value.map((msg) {
                          final data = msg.data() as Map<String, dynamic>;
                          final isMe =
                              data["senderId"] == _auth.currentUser?.uid;
                          return MessageBubble(
                            data: data,
                            isMe: isMe,
                            messageId: msg.id,
                            onDelete: isMe ? _confirmDeleteMessage : null,
                          );
                        })
                      ];
                    }).toList(),
                  ),
                );
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: MessageInputField(
              controller: _messageController,
              onSendPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateKey(DateTime timestamp) {
    String year = timestamp.year.toString();
    String month = timestamp.month.toString().padLeft(2, '0');
    String day = timestamp.day.toString().padLeft(2, '0');
    return "$year-$month-$day";
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}

class DateHeader extends StatelessWidget {
  final String dateKey;

  const DateHeader({Key? key, required this.dateKey}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    DateTime date = DateTime.parse(dateKey);
    String displayDate = _formatDisplayDate(date);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF4A3B7C).withOpacity(0.3) : Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            displayDate,
            style: AppFonts.medium.copyWith(
              fontSize: 12,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDisplayDate(DateTime date) {
    DateTime now = DateTime.now();
    DateTime yesterday = DateTime(now.year, now.month, now.day - 1);
    
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return "Today";
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      return "Yesterday";
    } else {
      return "${date.day}/${date.month}/${date.year}";
    }
  }
}

class MessageBubble extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isMe;
  final String messageId;
  final Function(String, String)? onDelete;

  const MessageBubble({
    Key? key,
    required this.data,
    required this.isMe,
    required this.messageId,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    final text = data["text"] as String;
    final timestamp = data["timestamp"] as Timestamp?;
    final status = data["status"] as String?;
    
    // Format time
    String time = "";
    if (timestamp != null) {
      final dateTime = timestamp.toDate();
      final hours = dateTime.hour.toString().padLeft(2, '0');
      final minutes = dateTime.minute.toString().padLeft(2, '0');
      time = "$hours:$minutes";
    }

    // Get status icon
    IconData? statusIcon;
    Color statusColor = Colors.grey;
    if (isMe) {
      switch (status) {
        case "sent":
          statusIcon = Icons.check;
          statusColor = Colors.grey;
          break;
        case "delivered":
          statusIcon = Icons.done_all;
          statusColor = Colors.grey;
          break;
        case "seen":
          statusIcon = Icons.done_all;
          statusColor = Colors.blue;
          break;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Delete button for user's messages
          if (isMe && onDelete != null)
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                size: 20,
                color: isDarkMode ? Colors.white70 : Colors.grey[600],
              ),
              onPressed: () => onDelete!(messageId, text),
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
              splashRadius: 20,
            ),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isMe
                  ? (isDarkMode ? const Color(0xFF4A3B7C) : AppColors.primary)
                  : (isDarkMode ? const Color(0xFF3D3D3D) : Colors.grey[200]),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(0),
                bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  text,
                  style: AppFonts.regular.copyWith(
                    fontSize: 14,
                    color: isMe
                        ? Colors.white
                        : (isDarkMode ? Colors.white : Colors.black87),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      time,
                      style: AppFonts.regular.copyWith(
                        fontSize: 10,
                        color: isMe
                            ? Colors.white70
                            : (isDarkMode ? Colors.white54 : Colors.black54),
                      ),
                    ),
                    if (isMe && statusIcon != null) ...[
                      const SizedBox(width: 4),
                      Icon(
                        statusIcon,
                        size: 12,
                        color: statusColor,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // Spacing after the message when it's not the user's message
          if (!isMe)
            const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class MessageInputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSendPressed;

  const MessageInputField({
    Key? key,
    required this.controller,
    required this.onSendPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF3D3D3D) : Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: controller,
                style: AppFonts.regular.copyWith(
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: "Type a message...",
                  hintStyle: AppFonts.regular.copyWith(
                    color: isDarkMode ? Colors.white54 : Colors.black38,
                  ),
                  border: InputBorder.none,
                ),
                minLines: 1,
                maxLines: 5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            onPressed: onSendPressed,
            backgroundColor: isDarkMode ? const Color(0xFF4A3B7C) : AppColors.primary,
            mini: true,
            elevation: 2,
            child: const Icon(
              Icons.send,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}