import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:velora/core/configs/theme/app_fonts.dart';
import 'package:velora/presentation/screens/0Auth/profile.dart';

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

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    var currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Fetch sender's info
    var userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(currentUser.uid)
        .get();

    String senderName = userDoc.data()?["userName"] ?? "Unknown";
    String senderProfileUrl = userDoc.data()?["profileUrl"] ?? "";

    // Save message to Firestore
    FirebaseFirestore.instance
        .collection("chats/${widget.chatId}/messages")
        .add({
      "text": _messageController.text.trim(),
      "senderId": currentUser.uid,
      "senderName": senderName,
      "senderProfileUrl": senderProfileUrl,
      "timestamp": FieldValue.serverTimestamp(),
    });

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            // Navigate to recipient's profile
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfilePage(userId: widget.recipientId),
              ),
            );
          },
          child: Row(
            children: [
              Transform.translate(
                offset: const Offset(-25, 0), // Moves it left by 3 pixels
                child: CircleAvatar(
                  backgroundColor: _generateRandomColor(widget.recipientName),
                  backgroundImage:
                      _hasProfilePicture(widget.recipientProfileUrl)
                          ? NetworkImage(widget.recipientProfileUrl)
                          : null,
                  child: !_hasProfilePicture(widget.recipientProfileUrl)
                      ? Text(
                          _getInitials(widget.recipientName),
                          style: const TextStyle(
                              fontSize: 20, color: Colors.white),
                        )
                      : null,
                ),
              ),
              Transform.translate(
                offset: const Offset(-18, 0), // Moves text closer to avatar
                child: Flexible(
                  child: Text(
                    widget.recipientName,
                    style: AppFonts.bold.copyWith(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("chats/${widget.chatId}/messages")
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No messages yet.",
                      style: TextStyle(fontSize: 14),
                    ),
                  );
                }

                var messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var data = messages[index].data() as Map<String, dynamic>?;

                    if (data == null) return const SizedBox();

                    String senderId = data["senderId"] ?? "";
                    String senderName = data["senderName"] ?? "Unknown";
                    String senderProfileUrl = data["senderProfileUrl"] ?? "";
                    String messageText = data["text"] ?? "";
                    bool isMe = senderId == _auth.currentUser!.uid;

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 10),
                        child: Row(
                          mainAxisAlignment: isMe
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          children: [
                            if (!isMe)
                              GestureDetector(
                                onTap: () {
                                  // Navigate to sender's profile
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ProfilePage(userId: senderId),
                                    ),
                                  );
                                },
                                child: CircleAvatar(
                                  radius: 16,
                                  backgroundColor:
                                      _generateRandomColor(senderName),
                                  backgroundImage:
                                      _hasProfilePicture(senderProfileUrl)
                                          ? NetworkImage(senderProfileUrl)
                                          : null,
                                  child: !_hasProfilePicture(senderProfileUrl)
                                      ? Text(
                                          _getInitials(senderName),
                                          style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.white),
                                        )
                                      : null,
                                ),
                              ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? AppColors.primary
                                      : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (!isMe)
                                      Text(
                                        senderName,
                                        style: AppFonts.medium.copyWith(
                                            fontSize: 12,
                                            color: Colors.grey[700]),
                                      ),
                                    Text(
                                      messageText,
                                      style: AppFonts.regular.copyWith(
                                          fontSize: 14,
                                          color: isMe
                                              ? Colors.white
                                              : Colors.black),
                                    ),
                                  ],
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
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: AppFonts.regular.copyWith(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      hintStyle: AppFonts.light.copyWith(fontSize: 14),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                            color: AppColors.hintText, width: 1),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: AppColors.primary),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
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
}
