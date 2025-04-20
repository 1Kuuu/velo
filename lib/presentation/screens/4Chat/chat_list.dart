import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:velora/presentation/screens/0Auth/profile.dart';
import 'package:velora/presentation/screens/4Chat/chat.dart';
import 'package:velora/presentation/widgets/reusable_wdgts.dart'; // Import reusable widgets
import 'package:velora/presentation/widgets/notification_app_bar_icon.dart'; // Import notification icon
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:velora/core/configs/theme/app_fonts.dart';
import 'package:provider/provider.dart';
import 'package:velora/core/configs/theme/theme_provider.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : AppColors.lightBackground,
      appBar: MyAppBar(
        title: "Messages",
        actions: [
          const NotificationAppBarIcon(),
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return AppBarIcon(
                  icon: Icons.person_outline,
                  onTap: () {}, // Empty callback for loading state
                );
              }

              final userData = snapshot.data?.data() as Map<String, dynamic>?;
              return ProfileAppBarIcon(
                profileUrl: userData?['profileUrl'],
                userName: userData?['userName'],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ProfilePage()),
                  );
                },
              );
            },
          ),
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
                color: isDarkMode ? const Color(0xFF2D2D2D) : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                style: AppFonts.regular.copyWith(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: 'Search conversations',
                  hintStyle: AppFonts.regular.copyWith(
                    color: isDarkMode ? Colors.white60 : Colors.grey[600],
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: isDarkMode ? Colors.white60 : Colors.grey[600],
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
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
                  return Center(
                    child: CircularProgressIndicator(
                      color: isDarkMode ? Colors.white70 : AppColors.primary,
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 48,
                          color: isDarkMode ? Colors.white60 : Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "No conversations yet",
                          style: AppFonts.semibold.copyWith(
                            color: isDarkMode ? Colors.white70 : Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Start chatting with someone!",
                          style: AppFonts.regular.copyWith(
                            color: isDarkMode ? Colors.white60 : Colors.grey[400],
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

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDarkMode ? const Color(0xFF4A3B7C) : Colors.grey[100]!,
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
                                  chatId:
                                      _generateChatId(currentUserId, userId),
                                  recipientId: userId,
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
                                          color: isDarkMode ? Colors.white60 : Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: isDarkMode ? Colors.white60 : Colors.grey[400],
                                ),
                              ],
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

  String _generateChatId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2]..sort();
    return ids.join("_");
  }
}
