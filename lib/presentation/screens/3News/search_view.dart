import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:velora/presentation/widgets/reusable_wdgts.dart' show MyAppBar;
import 'package:velora/presentation/screens/0Auth/profile.dart';
import 'package:provider/provider.dart';
import 'package:velora/core/configs/theme/theme_provider.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:velora/core/configs/theme/app_fonts.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  String searchName = "";
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      appBar: MyAppBar(
        title: 'Search',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 40, left: 10),
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.75,
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    searchName = value.toLowerCase().trim();
                  });
                },
                style: AppFonts.regular.copyWith(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  filled: true,
                  fillColor:
                      isDarkMode ? const Color(0xFF2D2D2D) : Colors.grey[100],
                  hintText: 'Search users by name...',
                  hintStyle: AppFonts.regular.copyWith(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600],
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              searchName = "";
                            });
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
      body: searchName.isEmpty
          ? _buildEmptyState(isDarkMode)
          : _buildUserList(isDarkMode),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            "Search for other users",
            style: AppFonts.medium.copyWith(
              fontSize: 18,
              color: isDarkMode ? Colors.white70 : Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Enter a name to find people",
            style: AppFonts.regular.copyWith(
              fontSize: 14,
              color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(bool isDarkMode) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  "Something went wrong",
                  style: AppFonts.semibold.copyWith(
                    fontSize: 16,
                    color: isDarkMode ? Colors.white70 : Colors.grey[800],
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              "No users found",
              style: AppFonts.regular.copyWith(
                color: isDarkMode ? Colors.white70 : Colors.grey[800],
                fontSize: 16,
              ),
            ),
          );
        }

        var filteredUsers = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          String name = (data['userName'] ?? "").toLowerCase();
          String email = (data['email'] ?? "").toLowerCase();
          String bio = (data['bio'] ?? "").toLowerCase();
          String userId = doc.id; // Get the document ID which is the user ID
          
          // Search in multiple fields
          return (name.contains(searchName) || 
                 email.contains(searchName) || 
                 bio.contains(searchName)) && 
                 userId != currentUserId;
        }).toList();

        if (filteredUsers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_off,
                  size: 48,
                  color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  "No users found matching '$searchName'",
                  style: AppFonts.semibold.copyWith(
                    fontSize: 16,
                    color: isDarkMode ? Colors.white70 : Colors.grey[800],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredUsers.length,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemBuilder: (context, index) {
            var doc = filteredUsers[index];
            var data = doc.data() as Map<String, dynamic>;
            return _buildUserTile(data, doc.id, isDarkMode);
          },
        );
      },
    );
  }

  Widget _buildUserTile(
      Map<String, dynamic> data, String userId, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[100]!,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        leading: Hero(
          tag: 'profile_$userId',
          child: CircleAvatar(
            radius: 28,
            backgroundColor: _generateRandomColor(data['userName']),
            backgroundImage: _hasProfilePicture(data['profileUrl'])
                ? NetworkImage(data['profileUrl'])
                : null,
            child: !_hasProfilePicture(data['profileUrl'])
                ? Text(
                    _getInitials(data['userName']),
                    style: AppFonts.bold.copyWith(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
        ),
        title: Text(
          data['userName'] ?? "Unknown User",
          style: AppFonts.semibold.copyWith(
            color: isDarkMode ? Colors.white : Colors.black,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          data['bio'] ?? "No bio available",
          style: AppFonts.regular.copyWith(
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfilePage(userId: userId),
            ),
          );
        },
        trailing: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(currentUserId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 24, 
                width: 24, 
                child: CircularProgressIndicator(strokeWidth: 2)
              );
            }
            
            if (!snapshot.hasData || snapshot.data == null) {
              return const SizedBox.shrink();
            }
            
            final userData = snapshot.data!.data() as Map<String, dynamic>?;
            final List<dynamic> following = userData?['following'] ?? [];
            final bool isFollowing = following.contains(userId);
            
            return ElevatedButton(
              onPressed: () => _toggleFollow(userId, isFollowing),
              style: ElevatedButton.styleFrom(
                backgroundColor: isFollowing 
                    ? (isDarkMode ? Colors.grey[700] : Colors.grey[200])
                    : (isDarkMode ? const Color(0xFF4A3B7C) : AppColors.primary),
                foregroundColor: isFollowing
                    ? (isDarkMode ? Colors.white70 : Colors.black54)
                    : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                minimumSize: const Size(80, 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                isFollowing ? 'Following' : 'Follow',
                style: AppFonts.regular.copyWith(fontSize: 12),
              ),
            );
          },
        ),
      ),
    );
  }
  
  Future<void> _toggleFollow(String userId, bool isCurrentlyFollowing) async {
    if (currentUserId == null) return;
    
    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(currentUserId);
      final targetUserRef = FirebaseFirestore.instance.collection('users').doc(userId);
      
      // Get current data
      final userDoc = await userRef.get();
      final targetUserDoc = await targetUserRef.get();
      
      if (!userDoc.exists || !targetUserDoc.exists) return;
      
      List<dynamic> currentFollowing = userDoc.data()?['following'] ?? [];
      List<dynamic> targetFollowers = targetUserDoc.data()?['followers'] ?? [];
      
      // Update in a transaction to ensure consistency
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        if (isCurrentlyFollowing) {
          // Unfollow
          currentFollowing.remove(userId);
          targetFollowers.remove(currentUserId);
        } else {
          // Follow
          if (!currentFollowing.contains(userId)) currentFollowing.add(userId);
          if (!targetFollowers.contains(currentUserId)) targetFollowers.add(currentUserId);
          
          // Create follow notification (outside of transaction)
          final userName = userDoc.data()?['userName'] ?? 'User';
          FirebaseFirestore.instance.collection('notifications').add({
            'type': 'follow',
            'senderId': currentUserId,
            'senderName': userName,
            'recipientId': userId,
            'message': 'started following you',
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
          });
        }
        
        transaction.update(userRef, {'following': currentFollowing});
        transaction.update(targetUserRef, {'followers': targetFollowers});
      });
      
      // Show a toast or feedback if desired
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isCurrentlyFollowing 
            ? 'Unfollowed ${targetUserDoc.data()?['userName'] ?? "user"}'
            : 'Following ${targetUserDoc.data()?['userName'] ?? "user"}'),
          duration: const Duration(seconds: 2),
        ),
      );
      
    } catch (e) {
      print('Error toggling follow: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error updating follow status'),
          duration: Duration(seconds: 2),
        ),
      );
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
