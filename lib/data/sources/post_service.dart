import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class PostService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static const String postsCollection = 'posts';
  static const String likesCollection = 'likes';
  static const String commentsCollection = 'comments';
  static const String usersCollection = 'user_profile';
  static const String viewedPostsCollection = 'viewed_posts';

  // Get user data
  static Future<Map<String, dynamic>> getUserData(String userId) async {
    try {
      final userDoc =
          await _firestore.collection(usersCollection).doc(userId).get();
      if (userDoc.exists) {
        return userDoc.data() ?? {};
      }
      return {};
    } catch (e) {
      print('Error fetching user data: $e');
      return {};
    }
  }

  // Create a new post
  static Future<String?> createPost({
    required String content,
    File? image,
    File? video,
    Map<String, dynamic>? rideData,
  }) async {
    try {
      print('Starting post creation...');
      final user = _auth.currentUser;
      if (user == null) {
        print('Error: No authenticated user found');
        return null;
      }

      String? mediaUrl;
      String mediaType = 'none';

      if (image != null) {
        print('Uploading image...');
        final ref = _storage
            .ref()
            .child('post_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(image);
        mediaUrl = await ref.getDownloadURL();
        mediaType = 'image';
        print('Image uploaded successfully: $mediaUrl');
      } else if (video != null) {
        print('Uploading video...');
        final ref = _storage
            .ref()
            .child('post_videos/${DateTime.now().millisecondsSinceEpoch}.mp4');
        await ref.putFile(video);
        mediaUrl = await ref.getDownloadURL();
        mediaType = 'video';
        print('Video uploaded successfully: $mediaUrl');
      }

      print('Fetching user data...');
      final userData = await getUserData(user.uid);
      print('User data fetched: ${userData['userName']}');

      // Create post data matching exactly with rules requirements
      Map<String, dynamic> postData = {
        // Required fields
        'content': content.trim(),
        'userId': user.uid,
        'authorId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'likesCount': 0,
        'commentsCount': 0,
        // Optional fields with empty defaults
        'mediaUrl': mediaUrl ?? '',
        'mediaType': mediaType,
        'route': '',
        'distance': 0,
        'duration': '',
        'authorName': userData['userName'] ?? user.displayName ?? 'Anonymous',
        'authorAvatar': userData['profileUrl'] ?? user.photoURL ?? '',
        'authorEmail': userData['email'] ?? user.email ?? '',
      };

      print('Attempting to create post with data: $postData');
      final postRef =
          await _firestore.collection(postsCollection).add(postData);
      print('Post created successfully with ID: ${postRef.id}');

      print('Updating user post count...');
      await _firestore.collection(usersCollection).doc(user.uid).update({
        'postsCount': FieldValue.increment(1),
      });
      print('Post count updated successfully');

      return postRef.id;
    } catch (e) {
      print('Error creating post: $e');
      print('Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  // Delete a post
  static Future<bool> deletePost(String postId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final postDoc =
          await _firestore.collection(postsCollection).doc(postId).get();
      if (!postDoc.exists) return false;

      final postData = postDoc.data()!;
      if (postData['userId'] != user.uid) return false;

      // Delete post image if exists
      if (postData['mediaUrl'] != null) {
        try {
          final ref = _storage.refFromURL(postData['mediaUrl']);
          await ref.delete();
        } catch (e) {
          print('Error deleting image: $e');
        }
      }

      // Delete post and its subcollections
      await _firestore.collection(postsCollection).doc(postId).delete();

      // Update user's post count
      await _firestore.collection(usersCollection).doc(user.uid).update({
        'postsCount': FieldValue.increment(-1),
      });

      return true;
    } catch (e) {
      print('Error deleting post: $e');
      return false;
    }
  }

  // Toggle like on a post
  static Future<bool> toggleLike(String postId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final postRef = _firestore.collection(postsCollection).doc(postId);
      final likeRef = postRef.collection(likesCollection).doc(user.uid);

      // First check if the post exists and get current like status
      final postDoc = await postRef.get();
      if (!postDoc.exists) return false;

      final likeDoc = await likeRef.get();

      if (likeDoc.exists) {
        // Unlike - first update the count using increment
        await postRef.update({'likesCount': FieldValue.increment(-1)});
        // Then delete the like document
        await likeRef.delete();
        return false;
      } else {
        // Like - first create the like document
        await likeRef.set(
            {'userId': user.uid, 'timestamp': FieldValue.serverTimestamp()});
        // Then update the count using increment
        await postRef.update({'likesCount': FieldValue.increment(1)});
        return true;
      }
    } catch (e) {
      print('Error toggling like: $e');
      return false;
    }
  }

  // Add a comment
  static Future<bool> addComment(String postId, String comment) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      print('Fetching user data for comment...');
      // Get user data from the correct collection
      final userDoc =
          await _firestore.collection(usersCollection).doc(user.uid).get();
      if (!userDoc.exists) {
        print('User document does not exist');
        return false;
      }

      final userData = userDoc.data() ?? {};
      print('User data fetched: $userData');

      // Get the user's name and avatar from their profile, with fallbacks
      final userName =
          (userData['userName'] as String?) ?? user.displayName ?? 'Anonymous';
      final userAvatar =
          (userData['profileUrl'] as String?) ?? user.photoURL ?? '';

      print('Creating comment with userName: $userName');
      // Create the comment with the verified user data
      final commentRef = await _firestore
          .collection(postsCollection)
          .doc(postId)
          .collection(commentsCollection)
          .add({
        'text': comment.trim(),
        'userId': user.uid,
        'userName': userName,
        'userAvatar': userAvatar,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (commentRef.id.isNotEmpty) {
        print('Comment created successfully with userName: $userName');
        // Update the comment count
        await _firestore
            .collection(postsCollection)
            .doc(postId)
            .update({'commentsCount': FieldValue.increment(1)});
        return true;
      }
      return false;
    } catch (e) {
      print('Error adding comment: $e');
      return false;
    }
  }

  // Delete a comment
  static Future<bool> deleteComment(String postId, String commentId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final commentDoc = await _firestore
          .collection(postsCollection)
          .doc(postId)
          .collection(commentsCollection)
          .doc(commentId)
          .get();

      if (!commentDoc.exists || commentDoc.data()!['userId'] != user.uid) {
        print(
            'Cannot delete comment: either comment does not exist or user is not the owner');
        return false;
      }

      // First update the count
      await _firestore
          .collection(postsCollection)
          .doc(postId)
          .update({'commentsCount': FieldValue.increment(-1)});

      // Then delete the comment
      await _firestore
          .collection(postsCollection)
          .doc(postId)
          .collection(commentsCollection)
          .doc(commentId)
          .delete();

      return true;
    } catch (e) {
      print('Error deleting comment: $e');
      return false;
    }
  }

  // Mark post as viewed
  static Future<void> markPostAsViewed(String postId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection(usersCollection)
          .doc(user.uid)
          .collection(viewedPostsCollection)
          .doc(postId)
          .set({
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error marking post as viewed: $e');
    }
  }

  // Get viewed post IDs
  static Future<List<String>> getViewedPostIds() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection(usersCollection)
          .doc(user.uid)
          .collection(viewedPostsCollection)
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('Error getting viewed posts: $e');
      return [];
    }
  }

  // Get post stream
  static Stream<QuerySnapshot> getPostsStream({String? tab}) {
    final user = _auth.currentUser;
    if (user == null) {
      return _firestore
          .collection(postsCollection)
          .orderBy('createdAt', descending: true)
          .snapshots();
    }

    if (tab == "Following") {
      // Get the user's following list and fetch posts from those users
      return Stream.periodic(const Duration(seconds: 1)).asyncMap((_) async {
        final userDoc =
            await _firestore.collection(usersCollection).doc(user.uid).get();

        if (!userDoc.exists) {
          return await _firestore
              .collection(postsCollection)
              .where('userId', isEqualTo: user.uid)
              .orderBy('createdAt', descending: true)
              .get();
        }

        List<String> following =
            List<String>.from(userDoc.data()?['following'] ?? []);
        following.add(user.uid); // Include user's own posts

        return await _firestore
            .collection(postsCollection)
            .where('userId', whereIn: following)
            .orderBy('createdAt', descending: true)
            .get();
      });
    }

    // For Discover tab, first get viewed posts
    return Stream.periodic(const Duration(seconds: 1)).asyncMap((_) async {
      final viewedPosts = await getViewedPostIds();

      // Get posts sorted by likes
      final query = _firestore
          .collection(postsCollection)
          .orderBy('likesCount', descending: true)
          .limit(100);

      final snapshot = await query.get();

      // If we have viewed posts, filter them out
      if (viewedPosts.isNotEmpty) {
        return await _firestore
            .collection(postsCollection)
            .where(FieldPath.documentId, whereNotIn: viewedPosts)
            .orderBy('likesCount', descending: true)
            .limit(50)
            .get();
      }

      // If no viewed posts, just return top 50
      return await _firestore
          .collection(postsCollection)
          .orderBy('likesCount', descending: true)
          .limit(50)
          .get();
    });
  }

  // Check if post is liked by current user
  static Future<bool> isLikedByUser(String postId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final likeDoc = await _firestore
          .collection(postsCollection)
          .doc(postId)
          .collection(likesCollection)
          .doc(user.uid)
          .get();

      return likeDoc.exists;
    } catch (e) {
      print('Error checking like status: $e');
      return false;
    }
  }

  // Update post content
  static Future<bool> updatePost(String postId, String newContent) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final postDoc =
          await _firestore.collection(postsCollection).doc(postId).get();
      if (!postDoc.exists) return false;

      final postData = postDoc.data()!;
      if (postData['userId'] != user.uid) return false;

      await _firestore.collection(postsCollection).doc(postId).update({
        'content': newContent.trim(),
        'editedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error updating post: $e');
      return false;
    }
  }
}
