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

class NewsFeedPageContent extends StatelessWidget {
  const NewsFeedPageContent({super.key});

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
          const Expanded(child: NewsFeedList()),
          PostInputField(),
        ],
      ),
    );
  }
}

class NewsFeedList extends StatelessWidget {
  const NewsFeedList({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text("No posts yet. Be the first to post!"));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var post = snapshot.data!.docs[index];
            return NewsFeedItem(post: post);
          },
        );
      },
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

  Future<void> _postMessage() async {
    if (user == null || _controller.text.isEmpty) return;
    String? imageUrl;

    if (_image != null) {
      Reference ref = FirebaseStorage.instance
          .ref()
          .child('post_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(_image!);
      imageUrl = await ref.getDownloadURL();
    }

    await FirebaseFirestore.instance.collection('posts').add({
      'content': _controller.text,
      'authorId': user!.uid,
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _controller.clear();
    setState(() => _image = null);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.image),
            onPressed: _pickImage,
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: "Write something...",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _postMessage,
          ),
        ],
      ),
    );
  }
}

class CommentsSection extends StatelessWidget {
  final String postId;
  const CommentsSection({super.key, required this.postId});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('posts')
                .doc(postId)
                .collection('comments')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              return ListView.builder(
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
          ),
        ),
        CommentInputField(postId: postId),
      ],
    );
  }
}

class CommentInputField extends StatefulWidget {
  final String postId;
  const CommentInputField({super.key, required this.postId});

  @override
  _CommentInputFieldState createState() => _CommentInputFieldState();
}

class _CommentInputFieldState extends State<CommentInputField> {
  final TextEditingController _controller = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;

  void _postComment() async {
    if (user == null || _controller.text.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .add({
      'userId': user!.uid,
      'userName': user!.displayName ?? 'Anonymous',
      'text': _controller.text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: const InputDecoration(hintText: "Write a comment..."),
      onSubmitted: (_) => _postComment(),
    );
  }
}

class NewsFeedItem extends StatefulWidget {
  final QueryDocumentSnapshot post;
  const NewsFeedItem({required this.post, super.key});

  @override
  _NewsFeedItemState createState() => _NewsFeedItemState();
}

class _NewsFeedItemState extends State<NewsFeedItem> {
  late String postId;
  late String authorId;
  int likes = 0;
  bool isLiked = false;
  String userName = "Loading...";
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    postId = widget.post.id;
    var data = widget.post.data() as Map<String, dynamic>;
    authorId = data['authorId'];
    likes = data['likes'] ?? 0;
    _fetchUserName(); // Get the userName of the currently logged-in user
    _checkIfLiked();
  }

  void _fetchUserName() async {
    var userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid) // Get the userName of the current authenticated user
        .get();
    if (userDoc.exists) {
      setState(() => userName = userDoc['userName'] ?? "Anonymous");
    }
  }

  void _checkIfLiked() async {
    var likeDoc = await FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('likes')
        .doc(user!.uid)
        .get();
    if (likeDoc.exists) {
      setState(() => isLiked = true);
    }
  }

  void _toggleLike() async {
    var likesRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('likes')
        .doc(user!.uid);
    setState(() => isLiked = !isLiked);

    if (isLiked) {
      await likesRef.set({'userId': user!.uid});
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .update({'likes': FieldValue.increment(1)});
    } else {
      await likesRef.delete();
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .update({'likes': FieldValue.increment(-1)});
    }

    // Fetch the updated like count and update the UI
    var postDoc =
        await FirebaseFirestore.instance.collection('posts').doc(postId).get();
    var updatedLikes = postDoc['likes'] ?? 0;

    setState(() {
      likes = updatedLikes; // Update the likes count in the UI
    });
  }

  @override
  Widget build(BuildContext context) {
    var postData = widget.post.data() as Map<String, dynamic>;
    String content = postData['content'] ?? '';
    String? imageUrl =
        postData.containsKey('imageUrl') ? postData['imageUrl'] : null;

    return Card(
      margin: const EdgeInsets.all(8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(userName,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 5),
            Text(content, style: const TextStyle(fontSize: 14)),
            if (imageUrl != null && imageUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(imageUrl),
                ),
              ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "$likes ${likes == 1 ? 'liked' : 'likes'}",
                  style: TextStyle(color: Colors.grey[600]),
                ),
                IconButton(
                  icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : Colors.grey),
                  onPressed: _toggleLike,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
