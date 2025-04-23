import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:velora/presentation/widgets/reusable_wdgts.dart' show MyAppBar;
import 'package:velora/presentation/screens/0Auth/profile.dart';
import 'package:provider/provider.dart';
import 'package:velora/core/configs/theme/theme_provider.dart';

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
                style: TextStyle(
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
                  hintStyle: TextStyle(
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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white70 : Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Enter a name to find people",
            style: TextStyle(
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.grey[800],
                fontSize: 16,
              ),
            ),
          );
        }

        var filteredUsers = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          String name = (data['userName'] ?? "").toLowerCase();
          String userId = doc.id; // Get the document ID which is the user ID
          return name.contains(searchName) && userId != currentUserId;
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
        ),
        title: Text(
          data['userName'] ?? "Unknown User",
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          data['bio'] ?? "No bio available",
          style: TextStyle(
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
      ),
    );
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
