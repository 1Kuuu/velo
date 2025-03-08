import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:velora/presentation/widgets/reusable_wdgts.dart';

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
      docRef.update({"status": "delivered"});
      _messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send message: ${e.toString()}")),
      );
    }
  }

  void _markMessagesAsSeen() async {
    var currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Mark all messages from recipient as seen
    var query = FirebaseFirestore.instance
        .collection("chats/${widget.chatId}/messages")
        .where("senderId", isEqualTo: widget.recipientId)
        .where("status", isNotEqualTo: "seen");

    var snapshot = await query.get();
    var batch = FirebaseFirestore.instance.batch();

    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {"status": "seen"});
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: ChatAppBar(
          recipientName: widget.recipientName,
          recipientProfileUrl: widget.recipientProfileUrl,
          recipientId: widget.recipientId,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _messageStream,
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
                Map<String, List<QueryDocumentSnapshot>> groupedMessages = {};

                for (var message in messages) {
                  var timestamp =
                      (message["timestamp"] as Timestamp?)?.toDate();
                  if (timestamp == null) continue;
                  String dateKey = _formatDateKey(timestamp);
                  groupedMessages.putIfAbsent(dateKey, () => []).add(message);
                }

                return ListView(
                  reverse: true,
                  children: groupedMessages.entries.expand((entry) {
                    return [
                      DateHeader(dateKey: entry.key),
                      ...entry.value.map((msg) {
                        final data = msg.data() as Map<String, dynamic>;
                        final isMe = data["senderId"] == _auth.currentUser?.uid;
                        return MessageBubble(data: data, isMe: isMe);
                      })
                    ];
                  }).toList(),
                );
              },
            ),
          ),
          MessageInputField(
            controller: _messageController,
            onSendPressed: _sendMessage,
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
