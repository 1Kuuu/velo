import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:velora/core/configs/theme/app_fonts.dart';
import 'dart:io';

import 'package:velora/data/sources/firebase_service.dart';
// Import the Firebase services
// import 'path_to_your_services/firebase_services.dart';

class ProfilePage extends StatefulWidget {
  final String? userId;
  const ProfilePage({super.key, this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isLoading = true, isCurrentUser = false, isFollowing = false;
  Map<String, dynamic> userData = {};
  List<Map<String, dynamic>> posts = [];
  final TextEditingController _postController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<File> _mediaFiles = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      // Use Firebase Services to check if the user is logged in
      if (FirebaseServices.currentUserId == null) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      String targetUserId = widget.userId ?? FirebaseServices.currentUserId!;
      isCurrentUser = targetUserId == FirebaseServices.currentUserId;

      // Fetch user data using the Firebase Services
      var userDoc = await FirebaseServices.getUserData(targetUserId);
      
      if (userDoc != null && userDoc.exists) {
        setState(() {
          userData = userDoc.data() as Map<String, dynamic>;
          // Ensure we have all required fields with the correct field names from your FirebaseServices
          userData['name'] = userData['userName'] ?? 'User Name';
          userData['bio'] = userData['bio'] ?? 'No bio available';
          userData['profileUrl'] = userData['profileUrl'] ?? '';
          userData['followers'] = userData['followers'] ?? [];
          userData['following'] = userData['following'] ?? [];
        });
      } else {
        // If no user data exists, get profile using Firebase Services which will create a default one
        userData = await FirebaseServices.getUserProfile(targetUserId);
        setState(() {
          userData['name'] = userData['userName'] ?? 'User Name';
        });
      }

      // Fetch user posts using Firebase Services
      posts = await FirebaseServices.getUserPosts(targetUserId);

      // Check if the current user is following this profile
      if (!isCurrentUser && userData.containsKey('followers')) {
        List<dynamic> followers = userData['followers'] ?? [];
        setState(() {
          isFollowing = followers.contains(FirebaseServices.currentUserId);
        });
      }
    } catch (e) {
      _showSnackbar('Error loading data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _toggleFollow() async {
    if (widget.userId == null) return;
    setState(() => isLoading = true);
    try {
      if (FirebaseServices.currentUserId == null) return;

      // Get the current user data to update following list
      Map<String, dynamic> currentUserData = await FirebaseServices.getUserProfile();
      List<dynamic> following = currentUserData['following'] ?? [];

      // Get the target user data to update followers list
      Map<String, dynamic> targetUserData = await FirebaseServices.getUserProfile(widget.userId);
      List<dynamic> followers = targetUserData['followers'] ?? [];

      if (isFollowing) {
        // Remove from lists
        following.remove(widget.userId);
        followers.remove(FirebaseServices.currentUserId);
      } else {
        // Add to lists
        following.add(widget.userId);
        followers.add(FirebaseServices.currentUserId);
      }

      // Update both users
      await FirebaseServices.updateUserData(
        FirebaseServices.currentUserId!,
        {'following': following}
      );
      
      await FirebaseServices.updateUserData(
        widget.userId!,
        {'followers': followers}
      );

      setState(() => isFollowing = !isFollowing);
      _showSnackbar(isFollowing ? 'Started following' : 'Unfollowed');
    } catch (e) {
      _showSnackbar('Failed to toggle follow: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _pickMedia(bool isImage) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Compress images to save storage
      );
      
      if (file != null) {
        setState(() => _mediaFiles.add(File(file.path)));
      }
    } catch (e) {
      _showSnackbar('Failed to pick media: $e');
    }
  }

  Future<void> _createPost() async {
    if (_postController.text.trim().isEmpty && _mediaFiles.isEmpty) {
      _showSnackbar('Please add some content to your post');
      return;
    }
    
    setState(() => isLoading = true);

    try {
      if (FirebaseServices.currentUserId == null) return;

      // In a real app, you would upload the media files to Firebase Storage
      // and use the URLs instead of local paths
      List<String> images = _mediaFiles
          .where((file) => !file.path.endsWith('.mp4'))
          .map((file) => file.path)
          .toList();
      
      // Using the Firebase Services to create a post
      await FirebaseServices.createPost(
        content: _postController.text.trim(),
        images: images,
      );

      _postController.clear();
      setState(() => _mediaFiles.clear());
      
      await _loadData();
      _showSnackbar('Post created successfully');
    } catch (e) {
      _showSnackbar('Failed to create post: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _likePost(String postId) async {
    if (postId.isEmpty) {
      _showSnackbar('Invalid post ID');
      return;
    }
    
    try {
      // Use Firebase Services to toggle like
      bool liked = await FirebaseServices.toggleLikePost(postId);
      _showSnackbar(liked ? 'Post liked' : 'Post unliked');
      
      await _loadData(); // Refresh data
    } catch (e) {
      _showSnackbar('Failed to like post: $e');
    }
  }

  void _showSnackbar(String message) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message, style: AppFonts.medium)),
      );

  // Updated method for navigating to EditProfile
  void _navigateToEditProfile() async {
    // Create a map with all the user data needed for editing
    Map<String, dynamic> profileData = {
      'name': userData['name'] ?? '',
      'bio': userData['bio'] ?? '',
      'profileUrl': userData['profileUrl'] ?? '',
    };
    
    // Navigate to edit profile and wait for result
    final result = await Navigator.pushNamed(
      context, 
      '/edit-profile',
      arguments: profileData, // Pass the prepared user data
    );
    
    // If the result is not null (edit was successful), reload data
    if (result != null) {
      await _loadData(); // Reload data to show the updated profile
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: AppFonts.semibold.copyWith(fontWeight: FontWeight.w600)),
        actions: isCurrentUser
            ? [
                IconButton(icon: const Icon(Icons.edit), onPressed: _navigateToEditProfile),
                IconButton(icon: const Icon(Icons.settings), onPressed: () => Navigator.pushNamed(context, '/settings')),
              ]
            : [],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  _buildProfileHeader(),
                  _buildProfileStats(),
                  if (isCurrentUser) _buildPostCreation(),
                  _buildPostsSection(),
                ],
              ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundImage: userData['profileUrl'] != null && userData['profileUrl'].toString().isNotEmpty
                ? NetworkImage(userData['profileUrl'])
                : null,
            child: userData['profileUrl'] == null || userData['profileUrl'].toString().isEmpty
                ? const Icon(Icons.person, size: 60, color: Colors.white)
                : null,
          ),
          const SizedBox(height: 16),
          Text(userData['name'] ?? 'User Name', style: AppFonts.bold.copyWith(fontSize: 22)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
            child: Text(
              userData['bio'] ?? 'No bio available',
              style: AppFonts.medium.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
          if (!isCurrentUser) _buildInteractionButtons(),
        ],
      ),
    );
  }

  Widget _buildProfileStats() {
    final followingCount = (userData['following'] as List?)?.length ?? 0;
    final followersCount = (userData['followers'] as List?)?.length ?? 0;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      margin: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStat('Following', followingCount.toString()),
          _buildStat('Followers', followersCount.toString()),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: AppFonts.bold.copyWith(fontSize: 20, color: Colors.white)),
        Text(label, style: AppFonts.medium.copyWith(color: Colors.white, fontSize: 14)),
      ],
    );
  }

  Widget _buildInteractionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: _toggleFollow,
          icon: Icon(isFollowing ? Icons.check : Icons.person_add_outlined),
          label: Text(isFollowing ? 'Following' : 'Follow'),
          style: ElevatedButton.styleFrom(
            backgroundColor: isFollowing ? Colors.grey[300] : AppColors.primary,
            foregroundColor: isFollowing ? Colors.black : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
      ],
    );
  }

  Widget _buildPostCreation() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Create Post', style: AppFonts.bold.copyWith(fontSize: 20)),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: _postController,
                    maxLines: 3,
                    style: AppFonts.medium,
                    decoration: InputDecoration(
                      hintText: "What's on your mind?",
                      hintStyle: AppFonts.medium,
                      border: InputBorder.none,
                    ),
                  ),
                  if (_mediaFiles.isNotEmpty)
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _mediaFiles.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(4),
                                child: _mediaFiles[index].path.endsWith('.mp4')
                                    ? Icon(Icons.videocam, size: 80, color: Colors.red)
                                    : Image.file(_mediaFiles[index], width: 80, height: 80, fit: BoxFit.cover),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _mediaFiles.removeAt(index);
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.all(2),
                                    child: const Icon(Icons.close, size: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.image, color: Colors.green),
                            onPressed: () => _pickMedia(true),
                          ),
                          IconButton(
                            icon: const Icon(Icons.videocam, color: Colors.red),
                            onPressed: () => _pickMedia(false),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: _createPost,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: Text('Post', style: AppFonts.medium),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Posts', style: AppFonts.bold.copyWith(fontSize: 20)),
          const SizedBox(height: 16),
          if (posts.isEmpty)
            Center(
              child: Column(
                children: [
                  const Icon(Icons.feed_outlined, size: 48, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text('No posts yet', style: AppFonts.medium.copyWith(color: Colors.grey)),
                ],
              ),
            )
          else
            ...posts.map((post) => _buildPostCard(post)),
        ],
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final bool isLiked = post['isLiked'] ?? false;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: userData['profileUrl'] != null && userData['profileUrl'].toString().isNotEmpty
                      ? NetworkImage(userData['profileUrl'])
                      : null,
                  child: userData['profileUrl'] == null || userData['profileUrl'].toString().isEmpty
                      ? const Icon(Icons.person, size: 20, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userData['name'] ?? 'User', style: AppFonts.bold.copyWith(fontSize: 16)),
                      Text(_formatTimestamp(post['createdAt']), style: AppFonts.medium.copyWith(color: Colors.grey)),
                    ],
                  ),
                ),
                if (isCurrentUser)
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showPostOptions(post),
                  ),
              ],
            ),
            if (post['content'] != null && post['content'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(post['content'] ?? '', style: AppFonts.medium.copyWith(fontSize: 16)),
              ),
            if (post['images'] != null && (post['images'] as List).isNotEmpty)
              Column(
                children: (post['images'] as List).map<Widget>((imageUrl) {
                  return _buildPostImage(imageUrl);
                }).toList(),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Text('${post['likesCount'] ?? 0} likes', style: AppFonts.medium.copyWith(color: Colors.grey)),
                  const SizedBox(width: 16),
                  Text('${post['commentsCount'] ?? 0} comments', style: AppFonts.medium.copyWith(color: Colors.grey)),
                ],
              ),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPostAction(
                  icon: isLiked ? Icons.favorite : Icons.favorite_border,
                  label: 'Like',
                  color: isLiked ? Colors.red : Colors.grey,
                  onTap: () => _likePost(post['id']),
                ),
                _buildPostAction(
                  icon: Icons.comment_outlined,
                  label: 'Comment',
                  onTap: () => _showSnackbar('Comments coming soon'),
                ),
                _buildPostAction(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  onTap: () => _showSnackbar('Share functionality coming soon'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPostOptions(Map<String, dynamic> post) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text('Edit Post', style: AppFonts.medium),
              onTap: () {
                Navigator.pop(context);
                _showSnackbar('Edit post functionality coming soon');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text('Delete Post', style: AppFonts.medium.copyWith(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDeletePost(post['id']);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeletePost(String postId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Post', style: AppFonts.bold),
        content: Text('Are you sure you want to delete this post?', style: AppFonts.medium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppFonts.medium),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // Delete post functionality would be implemented in FirebaseServices
                await FirebaseFirestore.instance.collection(FirebaseServices.POSTS_COLLECTION).doc(postId).delete();
                _showSnackbar('Post deleted successfully');
                await _loadData();
              } catch (e) {
                _showSnackbar('Failed to delete post: $e');
              }
            },
            child: Text('Delete', style: AppFonts.medium.copyWith(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildPostImage(String imageUrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 200,
              color: Colors.grey[200],
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
          errorBuilder: (_, __, ___) => Container(
            height: 200,
            color: Colors.grey[200],
            child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
          ),
        ),
      ),
    );
  }

  Widget _buildPostAction({required IconData icon, required String label, Color? color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, color: color ?? Colors.grey, size: 20),
            const SizedBox(width: 4),
            Text(label, style: AppFonts.medium.copyWith(color: color ?? Colors.grey)),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Just now';
    
    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is String) {
      try {
        dateTime = DateTime.parse(timestamp);
      } catch (e) {
        return 'Recently';
      }
    } else {
      return 'Just now';
    }
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return DateFormat('EEEE').format(dateTime);
    if (difference.inDays < 365) return DateFormat('MMM d').format(dateTime);
    return DateFormat('MMM d, yyyy').format(dateTime);
  }
}