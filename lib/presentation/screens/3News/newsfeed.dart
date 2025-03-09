import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:velora/presentation/screens/0Auth/profile.dart';
import 'package:velora/presentation/screens/3News/search_view.dart';
import 'package:velora/presentation/widgets/reusable_wdgts.dart';

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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: MyAppBar(
        title: "Velora",
        actions: [
          AppBarIcon(
            icon: Icons.search,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SearchView()),
            ),
            showBadge: false,
          ),
          AppBarIcon(
            icon: Icons.notifications_outlined,
            onTap: () => print("Notifications Tapped"),
          ),
          AppBarIcon(
            icon: Icons.person_outline,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfilePage()),
            ),
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
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: "Following"),
                Tab(text: "Discover"),
              ],
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.primary,
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
  final picker = ImagePicker();
  final user = FirebaseAuth.instance.currentUser;

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  Future<void> _postRide() async {
    if (user == null || _controller.text.isEmpty) return;
    String? imageUrl;

    if (_image != null) {
      Reference ref = FirebaseStorage.instance
          .ref()
          .child('ride_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(_image!);
      imageUrl = await ref.getDownloadURL();
    }

    await FirebaseFirestore.instance.collection('post').add({
      'content': _controller.text,
      'authorId': user!.uid,
      'imageUrl': imageUrl,
      'route': 'Sample Route',
      'distance': 10.5,
      'duration': '1h 30m',
      'timestamp': FieldValue.serverTimestamp(),
      'likesCount': 0,
      'commentsCount': 0,
    });

    _controller.clear();
    setState(() => _image = null);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          // User avatar
          CircleAvatar(
            backgroundImage: NetworkImage(user?.photoURL ?? ''),
            radius: 22,
          ),
          const SizedBox(width: 12),
          // Input field
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: "What's on your mind?",
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          // Image picker and send button
          IconButton(
            icon: const Icon(Icons.image),
            onPressed: _pickImage,
            iconSize: 28,
            color: AppColors.primary,
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _postRide,
            iconSize: 28,
            color: AppColors.primary,
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
      stream: FirebaseFirestore.instance
          .collection('rides')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text("No rides yet. Be the first to post a ride!"));
        }

        final posts = snapshot.data!.docs.where((post) {
          return true;
        }).toList();

        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) {
            var ride = posts[index];
            return RideFeedItem(ride: ride);
          },
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
  late String rideId;
  late String authorId;
  int likes = 0;
  bool isLiked = false;
  String userName = "Loading...";
  String? avatarUrl;
  final user = FirebaseAuth.instance.currentUser;
  bool _showComments = false;

  @override
  void initState() {
    super.initState();
    rideId = widget.ride.id;
    var data = widget.ride.data() as Map<String, dynamic>;
    authorId = data['authorId'];
    likes = data['likesCount'] ?? 0;
    _fetchUserDetails();
    _checkIfLiked();
  }

  void _fetchUserDetails() async {
    var userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(authorId)
        .get();
    if (userDoc.exists) {
      setState(() {
        userName = userDoc['userName'] ?? "Anonymous";
        avatarUrl = userDoc['avatarUrl'];
      });
    }
  }

  void _checkIfLiked() async {
    var likeDoc = await FirebaseFirestore.instance
        .collection('rides')
        .doc(rideId)
        .collection('likes')
        .doc(user!.uid)
        .get();
    if (likeDoc.exists) {
      setState(() => isLiked = true);
    }
  }

  void _toggleLike() async {
    var likesRef = FirebaseFirestore.instance
        .collection('rides')
        .doc(rideId)
        .collection('likes')
        .doc(user!.uid);
    setState(() => isLiked = !isLiked);

    if (isLiked) {
      await likesRef.set({'userId': user!.uid});
      await FirebaseFirestore.instance
          .collection('rides')
          .doc(rideId)
          .update({'likesCount': FieldValue.increment(1)});
    } else {
      await likesRef.delete();
      await FirebaseFirestore.instance
          .collection('rides')
          .doc(rideId)
          .update({'likesCount': FieldValue.increment(-1)});
    }

    var rideDoc =
        await FirebaseFirestore.instance.collection('rides').doc(rideId).get();
    var updatedLikes = rideDoc['likesCount'] ?? 0;

    setState(() {
      likes = updatedLikes;
    });
  }

  void _toggleComments() {
    setState(() {
      _showComments = !_showComments;
    });
  }

  @override
  Widget build(BuildContext context) {
    var rideData = widget.ride.data() as Map<String, dynamic>;
    String content = rideData['content'] ?? '';
    String? imageUrl = rideData.containsKey('imageUrl') ? rideData['imageUrl'] : null;
    String route = rideData['route'] ?? '';
    double distance = rideData['distance'] ?? 0.0;
    String duration = rideData['duration'] ?? '';

    return Card(
      margin: const EdgeInsets.all(12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User avatar and name
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(avatarUrl ?? ''),
                  radius: 22,
                ),
                const SizedBox(width: 12),
                Text(userName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            // Post content
            Text(content, style: const TextStyle(fontSize: 15)),
            if (imageUrl != null && imageUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(imageUrl),
                ),
              ),
            const SizedBox(height: 12),
            // Ride details
            Text("Route: $route", style: const TextStyle(fontSize: 14)),
            Text("Distance: ${distance.toStringAsFixed(1)} km",
                style: const TextStyle(fontSize: 14)),
            Text("Duration: $duration", style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            // Like button and count
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "$likes ${likes == 1 ? 'like' : 'likes'}",
                  style: TextStyle(color: Colors.grey[600]),
                ),
                IconButton(
                  icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : Colors.grey),
                  onPressed: _toggleLike,
                  iconSize: 30,
                ),
              ],
            ),
            // Comments section
            IconButton(
              icon: const Icon(Icons.comment),
              onPressed: _toggleComments,
              iconSize: 30,
            ),
            if (_showComments)
              CommentsSection(postId: rideId),
          ],
        ),
      ),
    );
  }
}

class CommentsSection extends StatelessWidget {
  final String postId;
  const CommentsSection({required this.postId, super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('rides')
          .doc(postId)
          .collection('comments')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var comment = snapshot.data!.docs[index];
            return ListTile(
              title: Text(comment['userName']),
              subtitle: Text(comment['text']),
            );
          },
        );
      },
    );
  }
}