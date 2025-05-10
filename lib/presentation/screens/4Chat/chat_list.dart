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

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<QueryDocumentSnapshot> _newUserResults = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  String _generateChatId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2]..sort();
    return ids.join("_");
  }

  Future<Map<String, dynamic>> _getChatInfo(String chatId, String currentUserId) async {
    try {
      // Initialize return values
      String lastMessage = "Tap to start chatting";
      bool hasUnread = false;
      
      // Query the last message from the chat
      final messagesSnapshot = await FirebaseFirestore.instance
          .collection("chats/$chatId/messages")
          .orderBy("timestamp", descending: true)
          .limit(5) // Get a few to check for unread
          .get();

      // If there's a message, get its text
      if (messagesSnapshot.docs.isNotEmpty) {
        final lastMessageDoc = messagesSnapshot.docs.first;
        final lastMessageData = lastMessageDoc.data();
        final String message = lastMessageData["text"] ?? "";
        final String senderId = lastMessageData["senderId"] ?? "";
        
        // Check if the current user is the sender
        final bool isMe = senderId == currentUserId;
        
        // Truncate if message is too long
        if (message.length > 30) {
          lastMessage = isMe 
              ? "You: ${message.substring(0, 27)}..." 
              : message.substring(0, 27) + "...";
        } else {
          lastMessage = isMe ? "You: $message" : message;
        }
        
        // Check for unread messages (any message not from currentUser with status not "seen")
        hasUnread = messagesSnapshot.docs.any((doc) {
          final data = doc.data();
          return data["senderId"] != currentUserId && data["status"] != "seen";
        });
      }
      
      return {
        'lastMessage': lastMessage,
        'hasUnread': hasUnread,
      };
    } catch (e) {
      print("Error fetching chat info: $e");
      return {
        'lastMessage': "Tap to start chatting",
        'hasUnread': false,
      };
    }
  }

  Future<String> _getLastMessage(String chatId) async {
    try {
      // Query the last message from the chat
      final messagesSnapshot = await FirebaseFirestore.instance
          .collection("chats/$chatId/messages")
          .orderBy("timestamp", descending: true)
          .limit(1)
          .get();

      // If there's a message, return its text
      if (messagesSnapshot.docs.isNotEmpty) {
        final lastMessageDoc = messagesSnapshot.docs.first;
        final lastMessageData = lastMessageDoc.data();
        final String message = lastMessageData["text"] ?? "";
        final String senderId = lastMessageData["senderId"] ?? "";
        
        // Check if the current user is the sender
        final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
        final bool isMe = senderId == currentUserId;
        
        // Truncate if message is too long
        if (message.length > 30) {
          return isMe ? "You: ${message.substring(0, 27)}..." : message.substring(0, 27) + "...";
        }
        
        return isMe ? "You: $message" : message;
      }
      
      // No messages yet
      return "Tap to start chatting";
    } catch (e) {
      print("Error fetching last message: $e");
      return "Tap to start chatting";
    }
  }

  Future<List<QueryDocumentSnapshot>> getVisibleChats() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return [];
    
    try {
      // Get all chats where the current user is a participant
      QuerySnapshot chatsSnapshot = await FirebaseFirestore.instance
          .collection("chats")
          .where('participants', arrayContains: currentUserId)
          .get();
      
      // Filter out chats that have been deleted by the current user
      List<QueryDocumentSnapshot> visibleChats = chatsSnapshot.docs.where((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('deletedBy') && data['deletedBy'] is List) {
          List<dynamic> deletedBy = data['deletedBy'];
          return !deletedBy.contains(currentUserId);
        }
        return true;
      }).toList();
      
      return visibleChats;
    } catch (e) {
      print("Error fetching visible chats: $e");
      return [];
    }
  }

  // Add a new method to filter chats by user names/info that match the search query
  Future<List<QueryDocumentSnapshot>> getFilteredChats() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return [];
    
    // If no search query, just return all visible chats
    if (_searchQuery.isEmpty) {
      _newUserResults = []; // Clear any previous search results
      return getVisibleChats();
    }

    try {
      // First, get all chats where the current user is a participant
      final chats = await getVisibleChats();
      
      // Get all users matching the search query
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection("users")
          .get();
      
      // Filter users based on search query (excluding current user)
      List<QueryDocumentSnapshot> matchingUsers = userSnapshot.docs
          .where((doc) {
            if (doc.id == currentUserId) return false;
            
            final userData = doc.data() as Map<String, dynamic>;
            final userName = (userData["userName"] ?? "").toString().toLowerCase();
            final email = (userData["email"] ?? "").toString().toLowerCase();
            
            return userName.contains(_searchQuery) || 
                   email.contains(_searchQuery);
          })
          .toList();
      
      // Create a map of matching user IDs for quick lookup
      Set<String> matchingUserIds = matchingUsers.map((doc) => doc.id).toSet();
      
      // Filter existing chats to only include those with matching users
      List<QueryDocumentSnapshot> matchingChats = chats.where((chatDoc) {
        Map<String, dynamic> chatData = chatDoc.data() as Map<String, dynamic>;
        List<dynamic> participants = chatData['participants'] ?? [];
        
        // Check if any participant (except current user) is in the matching users list
        for (var participantId in participants) {
          if (participantId != currentUserId && matchingUserIds.contains(participantId)) {
            return true;
          }
        }
        
        return false;
      }).toList();
      
      // Find users who match the search but don't have an existing chat
      List<String> existingChatUserIds = [];
      for (var chatDoc in matchingChats) {
        Map<String, dynamic> chatData = chatDoc.data() as Map<String, dynamic>;
        List<dynamic> participants = chatData['participants'] ?? [];
        for (var participantId in participants) {
          if (participantId != currentUserId) {
            existingChatUserIds.add(participantId.toString());
          }
        }
      }
      
      // Store users without existing chats to display separately
      _newUserResults = matchingUsers
          .where((userDoc) => !existingChatUserIds.contains(userDoc.id))
          .toList();
      
      return matchingChats;
    } catch (e) {
      print("Error filtering chats: $e");
      _newUserResults = [];
      return [];
    }
  }

  // Add a method to start a new chat with a user
  Future<void> _startNewChat(String recipientId, String recipientName, String recipientProfileUrl) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      // Generate a chat ID based on both user IDs
      final chatId = _generateChatId(currentUserId, recipientId);
      
      // Check if chat already exists
      final chatDoc = await FirebaseFirestore.instance.collection("chats").doc(chatId).get();
      
      if (!chatDoc.exists) {
        // Create a new chat document
        await FirebaseFirestore.instance.collection("chats").doc(chatId).set({
          'participants': [currentUserId, recipientId],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      // Navigate to the chat page
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPageContent(
              chatId: chatId,
              recipientId: recipientId,
              recipientName: recipientName,
              recipientProfileUrl: recipientProfileUrl,
            ),
          ),
        );
      }
    } catch (e) {
      print("Error starting new chat: $e");
      // Show error message if needed
    }
  }

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
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
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
                  suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                          size: 20,
                        ),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          
          // Users List
          Expanded(
            child: FutureBuilder<List<QueryDocumentSnapshot>>(
              future: getFilteredChats(),
              builder: (context, chatSnapshot) {
                if (chatSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                // No results case - both existing chats and new user results are empty
                if ((!chatSnapshot.hasData || chatSnapshot.data!.isEmpty) && _newUserResults.isEmpty) {
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
                          _searchQuery.isEmpty 
                              ? "No conversations yet" 
                              : "No results found",
                          style: AppFonts.semibold.copyWith(
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isEmpty 
                              ? "Start chatting with someone!" 
                              : "Try a different search term",
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

                // Build user data map for existing chats
                Set<String> participantIds = {};
                
                if (chatSnapshot.hasData && chatSnapshot.data!.isNotEmpty) {
                  for (var chatDoc in chatSnapshot.data!) {
                    Map<String, dynamic> chatData = chatDoc.data() as Map<String, dynamic>;
                    if (chatData.containsKey('participants') && chatData['participants'] is List) {
                      List<dynamic> participants = chatData['participants'];
                      for (var participant in participants) {
                        if (participant != currentUserId) {
                          participantIds.add(participant.toString());
                        }
                      }
                    }
                  }
                }
                
                // Handle the case where we only have search results but no existing chats
                if (participantIds.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      // Display new user search results if we have any
                      if (_searchQuery.isNotEmpty && _newUserResults.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8, top: 8),
                          child: Text(
                            "People",
                            style: AppFonts.semibold.copyWith(
                              color: isDarkMode ? Colors.white70 : Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        
                        // Display new users that match search
                        ..._newUserResults.map((userDoc) {
                          final userData = userDoc.data() as Map<String, dynamic>;
                          final String userId = userDoc.id;
                          final String name = userData["userName"] ?? 
                              userData["email"]?.split('@')[0] ?? 
                              "Unknown";
                          final String profileUrl = userData["profileUrl"] ?? "";
                          
                          return Container(
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
                                onTap: () => _startNewChat(userId, name, profileUrl),
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
                                              "Tap to start chatting",
                                              style: AppFonts.regular.copyWith(
                                                color: isDarkMode
                                                    ? Colors.grey[400]
                                                    : const Color.fromRGBO(
                                                        158, 158, 158, 1),
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.chat_bubble_outline,
                                        color: isDarkMode
                                            ? const Color(0xFF4A3B7C)
                                            : AppColors.primary,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ],
                  );
                }

                return FutureBuilder<QuerySnapshot?>(
                  future: participantIds.isEmpty 
                      ? Future.value(null)  // Skip the query if no participants
                      : FirebaseFirestore.instance
                          .collection("users")
                          .where(FieldPath.documentId, whereIn: participantIds.toList())
                          .get(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // Create a map of user IDs to user data for easy lookup
                    Map<String, Map<String, dynamic>> userDataMap = {};
                    if (userSnapshot.hasData && userSnapshot.data != null && userSnapshot.data!.docs.isNotEmpty) {
                      for (var userDoc in userSnapshot.data!.docs) {
                        userDataMap[userDoc.id] = userDoc.data() as Map<String, dynamic>;
                      }
                    }

                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        // Display new user search results if we have any
                        if (_searchQuery.isNotEmpty && _newUserResults.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 8, top: 8),
                            child: Text(
                              "People",
                              style: AppFonts.semibold.copyWith(
                                color: isDarkMode ? Colors.white70 : Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          
                          // Display new users that match search
                          ..._newUserResults.map((userDoc) {
                            final userData = userDoc.data() as Map<String, dynamic>;
                            final String userId = userDoc.id;
                            final String name = userData["userName"] ?? 
                                userData["email"]?.split('@')[0] ?? 
                                "Unknown";
                            final String profileUrl = userData["profileUrl"] ?? "";
                            
                            return Container(
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
                                  onTap: () => _startNewChat(userId, name, profileUrl),
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
                                                "Tap to start chatting",
                                                style: AppFonts.regular.copyWith(
                                                  color: isDarkMode
                                                      ? Colors.grey[400]
                                                      : const Color.fromRGBO(
                                                          158, 158, 158, 1),
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          Icons.chat_bubble_outline,
                                          color: isDarkMode
                                              ? const Color(0xFF4A3B7C)
                                              : AppColors.primary,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                        
                        // Display existing chats header if we have both types of results
                        if (_searchQuery.isNotEmpty && 
                            _newUserResults.isNotEmpty && 
                            chatSnapshot.hasData && 
                            chatSnapshot.data!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 4, top: 16, bottom: 8),
                            child: Text(
                              "Existing Chats",
                              style: AppFonts.semibold.copyWith(
                                color: isDarkMode ? Colors.white70 : Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        
                        // Display existing chat items 
                        if (chatSnapshot.hasData && chatSnapshot.data!.isNotEmpty)
                          ...chatSnapshot.data!.map((chatDoc) {
                            String chatId = chatDoc.id;
                            
                            // Find the other participant (not current user)
                            Map<String, dynamic> chatData = chatDoc.data() as Map<String, dynamic>;
                            List<dynamic> participants = chatData['participants'] ?? [];
                            String recipientId = "";
                            
                            for (var participant in participants) {
                              if (participant != currentUserId) {
                                recipientId = participant.toString();
                                break;
                              }
                            }
                            
                            // If we don't have recipient ID or user data, skip
                            if (recipientId.isEmpty || !userDataMap.containsKey(recipientId)) {
                              return const SizedBox.shrink();
                            }
                            
                            // Get user data for the recipient
                            Map<String, dynamic> userData = userDataMap[recipientId]!;
                            String name = userData["userName"] ??
                                userData["email"]?.split('@')[0] ??
                                "Unknown";
                            String profileUrl = userData["profileUrl"] ?? "";

                            return FutureBuilder<Map<String, dynamic>>(
                              future: _getChatInfo(chatId, currentUserId),
                              builder: (context, chatInfoSnapshot) {
                                // Default values while loading
                                String lastMessage = "Tap to start chatting";
                                bool hasUnread = false;
                                
                                if (chatInfoSnapshot.connectionState == ConnectionState.done && 
                                    chatInfoSnapshot.hasData) {
                                  lastMessage = chatInfoSnapshot.data!['lastMessage'];
                                  hasUnread = chatInfoSnapshot.data!['hasUnread'];
                                }

                                return Container(
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
                                              recipientId: recipientId,
                                              recipientName: name,
                                              recipientProfileUrl: profileUrl,
                                            ),
                                          ),
                                        );
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
                                                        ProfilePage(userId: recipientId),
                                                  ),
                                                );
                                              },
                                              child: Hero(
                                                tag: 'profile_$recipientId',
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
                                            if (hasUnread)
                                              Container(
                                                width: 12,
                                                height: 12,
                                                decoration: BoxDecoration(
                                                  color: isDarkMode 
                                                      ? const Color(0xFF4A3B7C) 
                                                      : AppColors.primary,
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: (isDarkMode 
                                                          ? const Color(0xFF4A3B7C) 
                                                          : AppColors.primary).withOpacity(0.4),
                                                      blurRadius: 4,
                                                      spreadRadius: 1,
                                                    )
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                      ],
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

// ChatUtils class for helper methods
class ChatUtils {
  static Color generateRandomColor(String input) {
    // Simple hash function to generate a consistent color for a name
    int hash = 0;
    for (var i = 0; i < input.length; i++) {
      hash = input.codeUnitAt(i) + ((hash << 5) - hash);
    }
    
    // Convert to RGB value
    final int r = (hash & 0xFF0000) >> 16;
    final int g = (hash & 0x00FF00) >> 8;
    final int b = hash & 0x0000FF;
    
    return Color.fromRGBO(r, g, b, 1);
  }
  
  static String getInitials(String name) {
    List<String> nameParts = name.split(" ");
    String initials = "";
    
    if (nameParts.isNotEmpty) {
      initials += nameParts[0][0];
      
      if (nameParts.length > 1) {
        initials += nameParts[1][0];
      }
    }
    
    return initials.toUpperCase();
  }
  
  static bool hasProfilePicture(String? url) {
    return url != null && url.isNotEmpty;
  }
}
