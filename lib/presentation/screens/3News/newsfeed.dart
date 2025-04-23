import 'dart:io';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:velora/core/configs/theme/app_fonts.dart';
import 'package:velora/core/configs/theme/theme_provider.dart';
import 'package:velora/data/sources/post_service.dart';
import 'package:velora/presentation/screens/0Auth/profile.dart';
import 'package:velora/presentation/screens/3News/search_view.dart';
import 'package:velora/presentation/widgets/reusable_wdgts.dart';
import 'package:provider/provider.dart';
import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:flutter/services.dart'; // Add this import for DeviceOrientation
import 'package:visibility_detector/visibility_detector.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';

class NewsFeedPageContent extends StatefulWidget {
  const NewsFeedPageContent({super.key});

  @override
  _NewsFeedPageContentState createState() => _NewsFeedPageContentState();
}

class _NewsFeedPageContentState extends State<NewsFeedPageContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        // Update your state here
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF121212) : AppColors.lightBackground,
      appBar: MyAppBar(
        title: "Velora",
        actions: [
          AppBarIcon(
            icon: Icons.search,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SearchView()),
            ),
          ),
          AppBarIcon(
            icon: Icons.notifications_outlined,
            onTap: () => print("Notifications Tapped"),
          ),
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
                    MaterialPageRoute(builder: (context) => ProfilePage()),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // "What's on your mind?" input field
          PostInputField(),
          // Following/Discover tab bar
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDarkMode ? Colors.white24 : Colors.grey.shade300,
                ),
              ),
            ),
            child: Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) => TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: "Following"),
                  Tab(text: "Discover"),
                ],
                labelColor: themeProvider.isDarkMode
                    ? const Color(0xFF4A3B7C)
                    : AppColors.primary,
                unselectedLabelColor:
                    themeProvider.isDarkMode ? Colors.white60 : Colors.grey,
                indicatorColor: themeProvider.isDarkMode
                    ? const Color(0xFF4A3B7C)
                    : AppColors.primary,
                labelStyle: AppFonts.semibold.copyWith(fontSize: 16),
                unselectedLabelStyle: AppFonts.regular.copyWith(fontSize: 16),
              ),
            ),
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                NewsFeedList(tab: "Following"),
                NewsFeedList(tab: "Discover"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PostInputField extends StatefulWidget {
  const PostInputField({super.key});

  @override
  _PostInputFieldState createState() => _PostInputFieldState();
}

class _PostInputFieldState extends State<PostInputField> {
  final TextEditingController _controller = TextEditingController();
  File? _image;
  File? _video;
  final picker = ImagePicker();
  final user = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {}); // Rebuild widget when text changes
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        // Update your state here
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _video = null; // Clear video when image is selected
      });
    }
  }

  Future<void> _pickVideo() async {
    final pickedFile = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 5),
    );
    if (pickedFile != null) {
      setState(() {
        _video = File(pickedFile.path);
        _image = null; // Clear image when video is selected
      });
    }
  }

  Future<void> _postRide() async {
    if (user == null ||
        (_controller.text.trim().isEmpty && _image == null && _video == null)) {
      DelightToastBar(
        builder: (context) => const ToastCard(
          title: Text('Please add some content to your post'),
          leading: Icon(Icons.warning, color: Colors.orange),
        ),
        autoDismiss: true,
      ).show(context);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final postId = await PostService.createPost(
        content: _controller.text,
        image: _image,
        video: _video,
        rideData: {
          'route': 'Sample Route',
          'distance': 10.5,
          'duration': '1h 30m',
        },
      );

      if (postId != null) {
        _controller.clear();
        setState(() {
          _image = null;
          _video = null;
          _isLoading = false;
        });

        if (mounted) {
          DelightToastBar(
            builder: (context) => const ToastCard(
              title: Text('Post created successfully'),
              leading: Icon(Icons.check_circle, color: Colors.green),
            ),
            autoDismiss: true,
          ).show(context);
        }
      }
    } catch (e) {
      print('Error creating post: $e');
      if (mounted) {
        DelightToastBar(
          builder: (context) => ToastCard(
            title: Text('Failed to create post: ${e.toString()}'),
            leading: Icon(Icons.error, color: Colors.red),
          ),
          autoDismiss: true,
        ).show(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDarkMode ? Colors.white24 : Colors.grey.shade200,
          ),
        ),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(user?.photoURL ?? ''),
                    radius: 20,
                    backgroundColor:
                        isDarkMode ? Colors.grey[800] : Colors.grey[300],
                    child: user?.photoURL == null
                        ? Icon(Icons.person,
                            color:
                                isDarkMode ? Colors.white70 : Colors.grey[600])
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLines: null,
                      style: AppFonts.regular.copyWith(
                        fontSize: 16,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: "What's on your mind?",
                        hintStyle: AppFonts.regular.copyWith(
                          color: isDarkMode ? Colors.white60 : Colors.grey[500],
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
              if (_image != null) ...[
                const SizedBox(height: 12),
                Stack(
                  children: [
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: FileImage(_image!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => setState(() => _image = null),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (_video != null) ...[
                const SizedBox(height: 12),
                Stack(
                  children: [
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.black87,
                      ),
                      child: const Center(
                        child: Icon(Icons.video_file,
                            size: 64, color: Colors.white),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => setState(() => _video = null),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          TextButton.icon(
                            onPressed: _isLoading ? null : _pickImage,
                            icon: Icon(Icons.image,
                                color: isDarkMode
                                    ? Colors.white
                                    : AppColors.primary),
                            label: Text(
                              'Photo',
                              style: AppFonts.medium.copyWith(
                                color: isDarkMode
                                    ? Colors.white
                                    : AppColors.primary,
                                fontSize: 14,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              backgroundColor: isDarkMode
                                  ? Colors.white.withOpacity(0.1)
                                  : AppColors.primary.withOpacity(0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: _isLoading ? null : _pickVideo,
                            icon: Icon(Icons.videocam,
                                color: isDarkMode
                                    ? Colors.white
                                    : AppColors.primary),
                            label: Text(
                              'Video',
                              style: AppFonts.medium.copyWith(
                                color: isDarkMode
                                    ? Colors.white
                                    : AppColors.primary,
                                fontSize: 14,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              backgroundColor: isDarkMode
                                  ? Colors.white.withOpacity(0.1)
                                  : AppColors.primary.withOpacity(0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: ElevatedButton(
                      onPressed: _isLoading ||
                              (_controller.text.trim().isEmpty &&
                                  _image == null &&
                                  _video == null)
                          ? null
                          : _postRide,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDarkMode
                            ? const Color(0xFF4A3B7C)
                            : AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Post',
                              style: AppFonts.semibold.copyWith(fontSize: 14),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class NewsFeedList extends StatelessWidget {
  final String tab;
  const NewsFeedList({required this.tab, super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: PostService.getPostsStream(tab: tab),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          print('Error loading posts: ${snapshot.error}');
          return Center(
            child: Text(
              "Error loading posts. Please try again.",
              style: AppFonts.medium.copyWith(color: Colors.grey),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          if (tab == "Following") {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, _) => Text(
                      "Follow people to see their posts here!",
                      style: AppFonts.medium.copyWith(
                        color: themeProvider.isDarkMode
                            ? Colors.white70
                            : Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.post_add_outlined,
                    size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, _) => Text(
                    "No new posts to show. Try again later!",
                    style: AppFonts.medium.copyWith(
                      color: themeProvider.isDarkMode
                          ? Colors.white70
                          : Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final posts = snapshot.data!.docs.toList();

        // Mark posts as viewed when they are rendered in Discover tab
        if (tab == "Discover") {
          // Use a post-frame callback to ensure the posts are rendered
          WidgetsBinding.instance.addPostFrameCallback((_) {
            for (var post in posts) {
              PostService.markPostAsViewed(post.id).then((_) {
                print('Successfully marked post ${post.id} as viewed');
              }).catchError((error) {
                print('Error marking post ${post.id} as viewed: $error');
              });
            }
          });
        }

        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) => RideFeedItem(ride: posts[index]),
        );
      },
    );
  }
}

class RideFeedItem extends StatefulWidget {
  final QueryDocumentSnapshot ride;
  const RideFeedItem({required this.ride, super.key});

  @override
  _RideFeedItemState createState() => _RideFeedItemState();
}

class _RideFeedItemState extends State<RideFeedItem> {
  late String postId;
  bool isLiked = false;
  final user = FirebaseAuth.instance.currentUser;
  bool _showComments = false;
  Map<String, dynamic>? authorData;
  // Cached post data to prevent UI flickering and owner changes
  late Map<String, dynamic> _cachedPostData;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    postId = widget.ride.id;
    _cachedPostData = widget.ride.data() as Map<String, dynamic>;
    _checkIfLiked();
    _loadAuthorData();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadAuthorData() async {
    final authorId = _cachedPostData['authorId'];
    if (authorId != null) {
      final userData = await PostService.getUserData(authorId);
      if (mounted) {
        setState(() => authorData = userData);
      }
    }
  }

  void _navigateToProfile(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePage(userId: userId),
      ),
    );
  }

  Future<void> _checkIfLiked() async {
    final liked = await PostService.isLikedByUser(postId);
    if (mounted) setState(() => isLiked = liked);
  }

  Future<void> _toggleLike() async {
    // Only toggle isLiked state without refreshing the entire post
    final success = await PostService.toggleLike(postId);
    if (mounted) {
      setState(() {
        isLiked = success;
        // Update only the likes count in the cached data
        if (success) {
          _cachedPostData['likesCount'] =
              (_cachedPostData['likesCount'] ?? 0) + 1;
        } else {
          _cachedPostData['likesCount'] =
              math.max<int>(0, (_cachedPostData['likesCount'] ?? 0) - 1);
        }
      });
    }
  }

  Future<void> _deletePost() async {
    final success = await PostService.deletePost(postId);
    if (success) {
      DelightToastBar(
        builder: (context) {
          return const ToastCard(
            title: Text('Post deleted successfully'),
            leading: Icon(Icons.check_circle, color: Colors.green),
          );
        },
        position: DelightSnackbarPosition.top,
        autoDismiss: true,
        snackbarDuration: const Duration(seconds: 2),
        animationDuration: const Duration(milliseconds: 300),
      ).show(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    // Use cached post data instead of re-reading from widget.ride
    String content = _cachedPostData['content'] ?? '';
    String? mediaUrl = _cachedPostData['mediaUrl'];
    String mediaType = _cachedPostData['mediaType'] ?? 'none';
    Map<String, dynamic>? rideData = _cachedPostData['rideData'];
    int likesCount = _cachedPostData['likesCount'] ?? 0;
    int commentsCount = _cachedPostData['commentsCount'] ?? 0;
    String userId = _cachedPostData['userId'] ?? '';

    // Use author data from loaded data if available, fall back to cached values
    String authorName =
        authorData?['userName'] ?? _cachedPostData['authorName'] ?? 'Anonymous';
    String authorAvatar =
        authorData?['profileUrl'] ?? _cachedPostData['authorAvatar'] ?? '';
    String authorEmail =
        authorData?['email'] ?? _cachedPostData['authorEmail'] ?? '';

    return Card(
      margin: const EdgeInsets.all(12.0),
      color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      elevation: isDarkMode ? 0 : 5,
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => _navigateToProfile(userId),
                  child: CircleAvatar(
                    backgroundImage: authorAvatar.isNotEmpty
                        ? NetworkImage(authorAvatar)
                        : null,
                    radius: 22,
                    backgroundColor: Colors.grey[300],
                    child: authorAvatar.isEmpty
                        ? Icon(Icons.person, color: Colors.grey[600])
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _navigateToProfile(userId),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authorName,
                          style: AppFonts.bold.copyWith(
                            fontSize: 16,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        if (authorEmail.isNotEmpty)
                          Text(
                            authorEmail,
                            style: AppFonts.regular.copyWith(
                              color: isDarkMode
                                  ? Colors.white60
                                  : Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        Text(
                          _formatTimestamp(
                              _cachedPostData['createdAt'] as Timestamp?),
                          style: AppFonts.regular.copyWith(
                            color:
                                isDarkMode ? Colors.white60 : Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (userId == user?.uid)
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showPostOptions(context),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  content,
                  style: AppFonts.medium.copyWith(
                    fontSize: 16,
                    color: isDarkMode ? Colors.white : Colors.black87,
                    height: 1.4,
                  ),
                ),
              ),
            if (mediaUrl != null && mediaUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: mediaType == 'video'
                      ? AspectRatio(
                          aspectRatio: 16 / 9,
                          child: VideoPlayer(mediaUrl),
                        )
                      : GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  FullscreenImageViewer(imageUrl: mediaUrl),
                            ),
                          ),
                          child: Hero(
                            tag: 'image_$mediaUrl',
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Image.network(
                                mediaUrl,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: isDarkMode
                                        ? Colors.grey[900]
                                        : Colors.grey[200],
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                        color: isDarkMode
                                            ? Colors.white70
                                            : Colors.grey[600],
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildErrorImage(isDarkMode),
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            if (rideData != null) ...[
              const SizedBox(height: 12),
              Text(
                "Route: ${rideData['route']}",
                style: AppFonts.medium.copyWith(
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.black87,
                ),
              ),
              Text(
                "Distance: ${rideData['distance']} km",
                style: AppFonts.medium.copyWith(
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.black87,
                ),
              ),
              Text(
                "Duration: ${rideData['duration']}",
                style: AppFonts.medium.copyWith(
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.black87,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  "$likesCount ${likesCount == 1 ? 'like' : 'likes'}",
                  style: AppFonts.regular.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white60
                        : Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 16),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .doc(postId)
                      .collection('comments')
                      .snapshots(),
                  builder: (context, snapshot) {
                    final count =
                        snapshot.hasData ? snapshot.data!.size : commentsCount;
                    return Text(
                      "$count ${count == 1 ? 'comment' : 'comments'}",
                      style: AppFonts.regular.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white60
                            : Colors.grey[600],
                        fontSize: 14,
                      ),
                    );
                  },
                ),
              ],
            ),
            Divider(
              height: 24,
              color: isDarkMode ? Colors.white24 : Colors.grey[300],
            ),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: isLiked ? Icons.favorite : Icons.favorite_border,
                    label: 'Like',
                    color: isLiked ? Colors.red : Colors.grey,
                    onTap: _toggleLike,
                  ),
                ),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.comment_outlined,
                    label: 'Comment',
                    onTap: () => setState(() => _showComments = !_showComments),
                  ),
                ),
              ],
            ),
            if (_showComments) ...[
              const Divider(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: 'Write a comment...',
                          hintStyle: AppFonts.regular.copyWith(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white60
                                    : Colors.grey[600],
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                        ),
                        style: AppFonts.regular.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Consumer<ThemeProvider>(
                      builder: (context, themeProvider, _) => IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () async {
                          if (_commentController.text.trim().isEmpty) return;

                          final success = await PostService.addComment(
                              postId, _commentController.text);
                          _commentController.clear();
                        },
                        color: themeProvider.isDarkMode
                            ? const Color(0xFF4A3B7C)
                            : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              CommentsSection(postId: postId, onDeleteComment: _deleteComment),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.grey,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppFonts.medium.copyWith(
                color: color,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPostOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: Text(
              'Delete Post',
              style: AppFonts.medium.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _deletePost();
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: Text(
              'Edit Post',
              style: AppFonts.medium.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
            onTap: () async {
              Navigator.pop(context);
              final postData = widget.ride.data() as Map<String, dynamic>;
              final TextEditingController contentController =
                  TextEditingController(text: postData['content']);

              final bool? result = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Edit Post'),
                  content: TextField(
                    controller: contentController,
                    decoration: const InputDecoration(
                      hintText: 'Edit your post...',
                    ),
                    maxLines: null,
                  ),
                  actions: [
                    Consumer<ThemeProvider>(
                      builder: (context, themeProvider, _) => TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(
                          'Cancel',
                          style: AppFonts.medium.copyWith(
                            color: themeProvider.isDarkMode
                                ? Colors.white70
                                : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                    Consumer<ThemeProvider>(
                      builder: (context, themeProvider, _) => TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(
                          'Save',
                          style: AppFonts.medium.copyWith(
                            color: themeProvider.isDarkMode
                                ? const Color(0xFF4A3B7C)
                                : AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );

              if (result == true && contentController.text.trim().isNotEmpty) {
                final success = await PostService.updatePost(
                    postId, contentController.text.trim());
                if (success && mounted) {
                  DelightToastBar(
                    builder: (context) {
                      return const ToastCard(
                        title: Text(
                          'Post updated successfully',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                        leading: Icon(Icons.check_circle, color: Colors.green),
                      );
                    },
                    position: DelightSnackbarPosition.top,
                    autoDismiss: true,
                    snackbarDuration: const Duration(seconds: 2),
                    animationDuration: const Duration(milliseconds: 300),
                  ).show(context);
                }
              }
            },
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';

    final now = DateTime.now();
    final dateTime = timestamp.toDate();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return DateFormat('EEEE').format(dateTime);
    if (difference.inDays < 365) return DateFormat('MMM d').format(dateTime);
    return DateFormat('MMM d, yyyy').format(dateTime);
  }

  Future<void> _deleteComment(String commentId) async {
    final success = await PostService.deleteComment(postId, commentId);
  }

  Widget _buildErrorImage(bool isDarkMode) {
    return Container(
      color: isDarkMode ? Colors.grey[900] : Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.broken_image,
              color: isDarkMode ? Colors.white70 : Colors.grey[600],
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'Failed to load image',
              style: AppFonts.regular.copyWith(
                color: isDarkMode ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CommentsSection extends StatefulWidget {
  final String postId;
  final Function(String) onDeleteComment;

  const CommentsSection(
      {required this.postId, required this.onDeleteComment, super.key});

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  Stream<QuerySnapshot>? _commentsStream;

  @override
  void initState() {
    super.initState();
    try {
      _commentsStream = FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .limit(50) // Add a reasonable limit
          .snapshots();
    } catch (e) {
      print('Error initializing comments stream: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: _commentsStream,
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          print('Comments stream error: ${snapshot.error}');
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Error loading comments. Please try again later.',
              style: AppFonts.regular.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white60
                    : Colors.grey[600],
                fontSize: 14,
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final comments = snapshot.data!.docs.toList()
            ..sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;

              final aTimestamp = aData['timestamp'] as Timestamp?;
              final bTimestamp = bData['timestamp'] as Timestamp?;

              // If either timestamp is null, put it at the end
              if (aTimestamp == null) return 1;
              if (bTimestamp == null) return -1;

              return bTimestamp.compareTo(aTimestamp); // Sort newest first
            });

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    'Comments',
                    style: AppFonts.bold.copyWith(
                      fontSize: 16,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    var comment = comments[index];
                    var data = comment.data() as Map<String, dynamic>;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: ListTile(
                        leading: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProfilePage(userId: data['userId']),
                            ),
                          ),
                          child: CircleAvatar(
                            backgroundImage:
                                data['userAvatar']?.isNotEmpty == true
                                    ? NetworkImage(data['userAvatar'])
                                    : null,
                            backgroundColor: Colors.grey[300],
                            child: data['userAvatar']?.isEmpty ?? true
                                ? Icon(Icons.person, color: Colors.grey[600])
                                : null,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ProfilePage(userId: data['userId']),
                                  ),
                                ),
                                child: Text(
                                  data['userName'] ?? 'Anonymous',
                                  style: AppFonts.bold.copyWith(
                                    fontSize: 14,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatTimestamp(data['timestamp'] as Timestamp?),
                              style: AppFonts.regular.copyWith(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white60
                                    : Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          data['text'] ?? '',
                          style: AppFonts.regular.copyWith(
                            fontSize: 14,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black87,
                          ),
                        ),
                        trailing: data['userId'] == currentUser?.uid
                            ? IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red),
                                onPressed: () => _confirmDeleteComment(
                                  context,
                                  comment.id,
                                  data['text'] ?? '',
                                ),
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'No comments yet. Be the first to comment!',
            style: AppFonts.regular.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white60
                  : Colors.grey[600],
              fontSize: 14,
            ),
          ),
        );
      },
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';

    final now = DateTime.now();
    final dateTime = timestamp.toDate();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return DateFormat('EEEE').format(dateTime);
    if (difference.inDays < 365) return DateFormat('MMM d').format(dateTime);
    return DateFormat('MMM d, yyyy').format(dateTime);
  }

  // Show confirmation dialog before deleting comment
  Future<void> _confirmDeleteComment(
      BuildContext context, String commentId, String commentText) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Comment?', style: AppFonts.bold),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to delete this comment?',
                  style: AppFonts.regular),
              const SizedBox(height: 8),
              Text(
                commentText,
                style: AppFonts.regular.copyWith(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          actions: [
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) => TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: AppFonts.medium.copyWith(
                    color: themeProvider.isDarkMode
                        ? Colors.white70
                        : Colors.grey[600],
                  ),
                ),
              ),
            ),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) => TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'Delete',
                  style: AppFonts.medium.copyWith(color: Colors.red),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await widget.onDeleteComment(commentId);
    }
  }
}

class VideoControllerManager {
  static VideoControllerManager? _instance;
  final Map<String, VideoPlayerController> _controllers = {};
  VideoPlayerController? _currentController;
  ChewieController? _currentChewieController;

  static VideoControllerManager get instance {
    _instance ??= VideoControllerManager();
    return _instance!;
  }

  VideoPlayerController? getCachedController(String url) {
    return _controllers[url];
  }

  void setCurrentController(
      VideoPlayerController controller, ChewieController chewieController) {
    if (_currentController != null && _currentController != controller) {
      _currentController!.pause();
      _currentChewieController?.pause();
    }
    _currentController = controller;
    _currentChewieController = chewieController;
    _controllers[controller.dataSource] = controller;
  }

  void pauseCurrentVideo() {
    if (_currentController != null) {
      _currentController!.pause();
      _currentChewieController?.pause();
    }
  }

  void dispose() {
    _currentController?.pause();
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    _currentController = null;
    _currentChewieController?.dispose();
    _currentChewieController = null;
  }
}

class VideoPlayer extends StatefulWidget {
  final String url;
  const VideoPlayer(this.url, {Key? key}) : super(key: key);

  @override
  _VideoPlayerState createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayer> with WidgetsBindingObserver {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  String? _errorMessage;
  bool _isDisposed = false;
  bool _isLoading = true;
  bool _isVideoFinished = false;
  bool _wasFullScreen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializePlayer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _videoController != null) {
      _videoController!.pause();
    }
  }

  Future<void> _initializePlayer() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _isVideoFinished = false;
      _wasFullScreen = false;
    });

    try {
      // Check if we have a cached controller
      final cachedController =
          VideoControllerManager.instance.getCachedController(widget.url);
      if (cachedController != null && !_isDisposed) {
        _videoController = cachedController;
        // Force reset position if video was at the end
        if (_videoController!.value.position >=
            _videoController!.value.duration - const Duration(seconds: 1)) {
          _videoController!.seekTo(Duration.zero);
        }
        _setupVideoListeners();
        _initializeChewieController();

        // Force loading to false for cached controllers
        if (mounted && !_isDisposed) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      _videoController = VideoPlayerController.network(
        widget.url,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
      );

      // Add value listener to handle loading state
      _setupVideoListeners();

      await _videoController!.initialize();
      if (_isDisposed || !mounted) return;

      _initializeChewieController();
      if (_videoController != null && _chewieController != null) {
        VideoControllerManager.instance
            .setCurrentController(_videoController!, _chewieController!);
      }

      // Force loading to false after initialization
      if (mounted && !_isDisposed) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (error) {
      if (!_isDisposed && mounted) {
        setState(() {
          _errorMessage = error.toString();
          _isInitialized = false;
          _isLoading = false;
        });
      }
    }
  }

  void _setupVideoListeners() {
    if (_videoController == null) return;

    // Force loading to false immediately on initialization
    if (mounted && !_isDisposed) {
      Future.microtask(() {
        setState(() {
          _isLoading = false;
        });
      });
    }

    // Create a separate listener function that we can reference later for removal
    void videoListener() {
      if (!mounted || _isDisposed) return;

      // Always ensure loading is false in the listener
      if (_isLoading) {
        if (mounted && !_isDisposed) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      // Only update video finished state
      bool needsUpdate = false;
      bool newFinished = _isVideoFinished;

      // Check if video has reached the end
      final position = _videoController!.value.position;
      final duration = _videoController!.value.duration;

      // Prevent division by zero or comparison with zero duration
      if (duration.inMilliseconds > 0) {
        // Check if video is finished (position is at 99% or more of duration)
        final percentComplete =
            position.inMilliseconds / duration.inMilliseconds;
        final isAtEnd = percentComplete >= 0.99;

        // Only update if the finished state changed
        if (isAtEnd != _isVideoFinished) {
          newFinished = isAtEnd;
          needsUpdate = true;
        }
      }

      // Reset finished state when video is playing and not near end
      if (_isVideoFinished &&
          _videoController!.value.isPlaying &&
          position < duration - const Duration(seconds: 3)) {
        newFinished = false;
        needsUpdate = true;
      }

      // Only call setState if state actually changed
      if (needsUpdate && mounted && !_isDisposed) {
        setState(() {
          _isVideoFinished = newFinished;
        });
      }
    }

    // Store the listener function on the controller
    _videoController!.addListener(videoListener);

    // Force loading to false after a very short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && !_isDisposed) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  void _initializeChewieController() {
    if (_videoController == null || _isDisposed || !mounted) return;

    try {
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        aspectRatio: _videoController!.value.aspectRatio,
        autoPlay: false,
        looping: false,
        showControlsOnInitialize: false,
        showControls: true,
        allowPlaybackSpeedChanging: true,
        allowFullScreen: true,
        deviceOrientationsOnEnterFullScreen: const [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ],
        deviceOrientationsAfterFullScreen: const [DeviceOrientation.portraitUp],
        placeholder: Container(
          color: Colors.black,
          // Remove loading indicator from placeholder
          child: const Center(),
        ),
        errorBuilder: (context, errorMessage) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 42),
              const SizedBox(height: 8),
              Text(
                'Error playing video: $errorMessage',
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              TextButton(
                onPressed: _initializePlayer,
                child:
                    const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
        fullScreenByDefault: false,
        allowMuting: true,
        zoomAndPan: true,
        // Don't show loading spinner on initialization
        showOptions: false,
        // Custom controls
        customControls: const CupertinoControls(
          backgroundColor: Color.fromRGBO(41, 41, 41, 0.7),
          iconColor: Color.fromARGB(255, 200, 200, 200),
        ),
        routePageBuilder: (context, animation, secondaryAnimation, provider) {
          _wasFullScreen = true;
          // When entering fullscreen, reset video if it was at the end
          if (_isVideoFinished && _videoController != null) {
            _videoController!.seekTo(Duration.zero);
            setState(() {
              _isVideoFinished = false;
              _isLoading = false;
            });
          }

          return AnimatedBuilder(
            animation: animation,
            builder: (BuildContext context, Widget? child) {
              return WillPopScope(
                // Handle back button press in fullscreen to update our state when exiting
                onWillPop: () async {
                  _onExitFullScreen();
                  return true;
                },
                child: Scaffold(
                  resizeToAvoidBottomInset: false,
                  body: Container(
                    alignment: Alignment.center,
                    color: Colors.black,
                    child: provider,
                  ),
                ),
              );
            },
          );
        },
      );

      // Listen for fullscreen state changes
      Future.microtask(() {
        if (_chewieController != null) {
          _chewieController!.addListener(_handleFullscreenChange);
        }
      });

      // Add specific video completion listener
      _videoController!.addListener(_handleVideoCompletion);

      if (!_isDisposed && mounted) {
        setState(() {
          _isInitialized = true;
          _errorMessage = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to initialize video: ${e.toString()}";
          _isInitialized = false;
          _isLoading = false;
        });
      }
    }
  }

  void _handleVideoCompletion() {
    if (!mounted || _isDisposed || _videoController == null) return;

    // Check if video has reached the end
    final position = _videoController!.value.position;
    final duration = _videoController!.value.duration;

    // If video is at the end
    if (duration.inMilliseconds > 0 &&
        position.inMilliseconds >= duration.inMilliseconds - 500) {
      // Immediately pause the video to prevent loading indicators
      _videoController!.pause();

      // Force update state
      if (mounted && !_isDisposed) {
        setState(() {
          _isVideoFinished = true;
          _isLoading = false;

          // If using ChewieController, remove any loading indicators
          if (_chewieController != null) {
            // Force rebuild Chewie to clear any loading indicators
            _chewieController = ChewieController(
              videoPlayerController: _videoController!,
              aspectRatio: _videoController!.value.aspectRatio,
              autoPlay: false,
              looping: false,
              showControls: true,
              // Use same control type as main controller
              customControls: const CupertinoControls(
                backgroundColor: Color.fromRGBO(41, 41, 41, 0.7),
                iconColor: Color.fromARGB(255, 200, 200, 200),
              ),
              placeholder: Container(color: Colors.black),
            );
          }
        });
      }
    }
  }

  void _handleFullscreenChange() {
    if (_chewieController == null || !mounted || _isDisposed) return;

    final isFullScreen = _chewieController!.isFullScreen;

    // If we were fullscreen but now we're not, handle exit
    if (_wasFullScreen && !isFullScreen) {
      _onExitFullScreen();
    }

    // Update our tracking of fullscreen state
    _wasFullScreen = isFullScreen;
  }

  void _onExitFullScreen() {
    _wasFullScreen = false;
    // If video was finished in fullscreen, ensure UI state reflects this
    if (_videoController != null &&
        _videoController!.value.position >=
            _videoController!.value.duration - const Duration(seconds: 1)) {
      if (mounted && !_isDisposed) {
        setState(() {
          _isVideoFinished = true;
          _isLoading = false;
        });
      }
    }
  }

  void _restartVideo() {
    if (_videoController != null && !_isDisposed && mounted) {
      setState(() {
        _isVideoFinished = false;
        _isLoading = true; // Show loading briefly while seeking
      });
      _videoController!.seekTo(Duration.zero);
      _videoController!.play().then((_) {
        if (mounted && !_isDisposed) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _isDisposed = true;

    // Remove video completion listener
    if (_videoController != null) {
      _videoController!.removeListener(_handleVideoCompletion);
    }

    // Clear all listeners first
    if (_chewieController != null) {
      _chewieController!.removeListener(_handleFullscreenChange);
      _chewieController!.dispose();
      _chewieController = null;
    }

    if (_videoController != null) {
      // Remove all listeners to avoid callbacks after dispose
      _videoController!.removeListener(() {});

      // Don't dispose the controller if it's cached
      if (VideoControllerManager.instance.getCachedController(widget.url) !=
          _videoController) {
        _videoController!.dispose();
      }
      _videoController = null;
    }

    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 42),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error playing video: $_errorMessage',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
              TextButton(
                onPressed: _initializePlayer,
                child:
                    const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized ||
        _videoController == null ||
        _chewieController == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    // Force isLoading to false before rendering
    _isLoading = false;

    return VisibilityDetector(
      key: Key('video-${widget.url}'),
      onVisibilityChanged: (visibilityInfo) {
        if (visibilityInfo.visibleFraction < 0.5 && _videoController != null) {
          _videoController!.pause();
        }
      },
      child: Chewie(
        controller: _chewieController!,
      ),
    );
  }
}

class FullscreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const FullscreenImageViewer({Key? key, required this.imageUrl})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: PhotoView(
        imageProvider: NetworkImage(imageUrl),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 2,
        loadingBuilder: (context, event) => Center(
          child: CircularProgressIndicator(
            value: event?.expectedTotalBytes != null
                ? event!.cumulativeBytesLoaded / event.expectedTotalBytes!
                : null,
          ),
        ),
        errorBuilder: (context, error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 42),
              const SizedBox(height: 8),
              Text(
                'Error loading image',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
