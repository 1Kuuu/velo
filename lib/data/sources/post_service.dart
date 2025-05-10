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
      final user = _auth.currentUser;
      if (user == null) return null;

      if (content.length > 1000) {
        throw Exception('Content exceeds 1000 character limit');
      }

      String? mediaUrl;
      String mediaType = 'none';

      if (image != null) {
        try {
          if (!await image.exists()) {
            throw Exception('Image file does not exist');
          }

          final fileSize = await image.length();
          if (fileSize > 10 * 1024 * 1024) {
            throw Exception('Image size exceeds 10MB limit');
          }

          final token = await user.getIdToken();
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final fileName = '${user.uid}_$timestamp.jpg';
          final ref = _storage.ref('images/$fileName');

          final metadata = SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'userId': user.uid,
              'timestamp': DateTime.now().toIso8601String(),
              if (token != null) 'authToken': token,
            },
          );

          final extension = image.path.split('.').last.toLowerCase();
          if (extension != 'jpg' && extension != 'jpeg') {
            throw Exception('Only JPG/JPEG images are allowed');
          }

          final task = ref.putFile(image, metadata);
          final snapshot = await task;
          mediaUrl = await snapshot.ref.getDownloadURL();
          mediaType = 'image';
        } catch (e) {
          if (e is FirebaseException) {
            throw Exception('Failed to upload image: ${e.message}');
          }
          rethrow;
        }
      } else if (video != null) {
        try {
          if (!await video.exists()) {
            throw Exception('Video file does not exist');
          }

          final fileSize = await video.length();
          if (fileSize > 100 * 1024 * 1024) {
            throw Exception('Video size exceeds 100MB limit');
          }

          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final fileName = '${user.uid}_$timestamp.mp4';
          final ref = _storage.ref('videos/$fileName');

          final metadata = SettableMetadata(
            contentType: 'video/mp4',
            customMetadata: {
              'userId': user.uid,
              'timestamp': DateTime.now().toIso8601String(),
              'originalFileName': video.path.split('/').last,
              'fileSize': fileSize.toString(),
              'uploadType': 'video',
            },
            cacheControl: 'public, max-age=31536000',
          );

          final extension = video.path.split('.').last.toLowerCase();
          if (!['mp4'].contains(extension)) {
            throw Exception('Only MP4 videos are supported');
          }

          final task = ref.putFile(video, metadata);
          final snapshot = await task;
          mediaUrl = await snapshot.ref.getDownloadURL();
          mediaType = 'video';
        } catch (e) {
          if (e is FirebaseException) {
            throw Exception('Failed to upload video: ${e.message}');
          }
          rethrow;
        }
      }

      final userData = await getUserData(user.uid);
      Map<String, dynamic> postData = {
        'content': content.trim(),
        'userId': user.uid,
        'authorId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'likesCount': 0,
        'commentsCount': 0,
        'mediaUrl': mediaUrl ?? '',
        'mediaType': mediaType,
        'route': rideData?['route'] ?? '',
        'distance': rideData?['distance'] ?? 0,
        'duration': rideData?['duration'] ?? '',
        'authorName': userData['userName'] ?? user.displayName ?? 'Anonymous',
        'authorAvatar': userData['profileUrl'] ?? user.photoURL ?? '',
        'authorEmail': userData['email'] ?? user.email ?? '',
      };

      final postRef =
          await _firestore.collection(postsCollection).add(postData);
      await _firestore.collection(usersCollection).doc(user.uid).update({
        'postsCount': FieldValue.increment(1),
      });

      return postRef.id;
    } catch (e) {
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

      if (postData['mediaUrl'] != null) {
        try {
          final ref = _storage.refFromURL(postData['mediaUrl']);
          await ref.delete();
        } catch (e) {
          // Ignore media deletion errors
        }
      }

      await _firestore.collection(postsCollection).doc(postId).delete();
      await _firestore.collection(usersCollection).doc(user.uid).update({
        'postsCount': FieldValue.increment(-1),
      });

      return true;
    } catch (e) {
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

      final postDoc = await postRef.get();
      if (!postDoc.exists) return false;
      
      // Get post data for notification
      final postData = postDoc.data()!;
      final postOwnerId = postData['userId'];

      final likeDoc = await likeRef.get();

      if (likeDoc.exists) {
        await postRef.update({'likesCount': FieldValue.increment(-1)});
        await likeRef.delete();
        return false;
      } else {
        await likeRef.set(
            {'userId': user.uid, 'timestamp': FieldValue.serverTimestamp()});
        await postRef.update({'likesCount': FieldValue.increment(1)});
        
        // Create notification for the post owner (if it's not the same user)
        if (postOwnerId != user.uid) {
          // Get user data for the notification
          final userData = await getUserData(user.uid);
          
          await _firestore.collection('notifications').add({
            'type': 'like',
            'senderId': user.uid,
            'senderName': userData['userName'] ?? user.displayName ?? 'User',
            'recipientId': postOwnerId,
            'postId': postId,
            'message': 'liked your post',
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
          });
        }
        
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

      final userData = await getUserData(user.uid);
      final commentRef = await _firestore
          .collection(postsCollection)
          .doc(postId)
          .collection(commentsCollection)
          .add({
        'text': comment.trim(),
        'userId': user.uid,
        'userName': userData['userName'] ?? 'Anonymous',
        'userAvatar': userData['profileUrl'] ?? '',
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (commentRef.id.isNotEmpty) {
        await _firestore
            .collection(postsCollection)
            .doc(postId)
            .update({'commentsCount': FieldValue.increment(1)});
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Delete a comment
  static Future<bool> deleteComment(String postId, String commentId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final postRef = _firestore.collection(postsCollection).doc(postId);
      final commentRef = postRef.collection(commentsCollection).doc(commentId);

      final commentDoc = await commentRef.get();
      if (!commentDoc.exists) return false;

      final commentData = commentDoc.data()!;
      if (commentData['userId'] == user.uid) {
        await commentRef.delete();
        await postRef.update({'commentsCount': FieldValue.increment(-1)});
        return true;
      }

      final postDoc = await postRef.get();
      if (!postDoc.exists) return false;

      final postData = postDoc.data()!;
      if (postData['userId'] == user.uid) {
        await commentRef.delete();
        await postRef.update({'commentsCount': FieldValue.increment(-1)});
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  // Mark post as viewed
  static Future<void> markPostAsViewed(String postId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userProfileRef =
          _firestore.collection(usersCollection).doc(user.uid);
      final viewedPostRef =
          userProfileRef.collection(viewedPostsCollection).doc(postId);
      final viewedDoc = await viewedPostRef.get();

      if (viewedDoc.exists) return;

      await viewedPostRef.set({
        'timestamp': FieldValue.serverTimestamp(),
        'userId': user.uid,
        'postId': postId,
      });
    } catch (e) {
      if (e is FirebaseException && e.code == 'permission-denied') {
        final user = _auth.currentUser;
        if (user == null) return;

        final userProfileRef =
            _firestore.collection(usersCollection).doc(user.uid);
        await userProfileRef.set({
          'userId': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'userName': user.displayName ?? 'Anonymous',
          'email': user.email ?? '',
          'profileUrl': user.photoURL ?? '',
        }, SetOptions(merge: true));

        await userProfileRef.collection(viewedPostsCollection).doc(postId).set({
          'timestamp': FieldValue.serverTimestamp(),
          'userId': user.uid,
          'postId': postId,
        });
      }
    }
  }

  // Get viewed post IDs with error handling
  static Future<List<String>> getViewedPostIds() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final twoHoursAgo = DateTime.now().subtract(const Duration(hours: 2));
      final timestamp = Timestamp.fromDate(twoHoursAgo);

      final snapshot = await _firestore
          .collection(usersCollection)
          .doc(user.uid)
          .collection(viewedPostsCollection)
          .where('timestamp', isGreaterThan: timestamp)
          .orderBy('timestamp', descending: true)
          .limit(1000)
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      return [];
    }
  }

  // Clear viewed posts history
  static Future<void> clearViewedPosts() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection(usersCollection)
          .doc(user.uid)
          .collection(viewedPostsCollection)
          .limit(500)
          .get();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      // Handle error silently
    }
  }

  // Get post stream with error handling
  static Stream<QuerySnapshot> getPostsStream({String? tab}) {
    final user = _auth.currentUser;
    if (user == null) {
      return _firestore
          .collection(postsCollection)
          .orderBy('createdAt', descending: true)
          .snapshots();
    }

    if (tab == "Following") {
      return Stream.periodic(const Duration(seconds: 1)).asyncMap((_) async {
        try {
          final userDoc =
              await _firestore.collection(usersCollection).doc(user.uid).get();
          if (!userDoc.exists) {
            return await _firestore
                .collection(postsCollection)
                .where('userId', isEqualTo: 'no_posts')
                .get();
          }

          final userData = userDoc.data() ?? {};
          List<String> following =
              List<String>.from(userData['following'] ?? []);
          following.add(user.uid);

          if (following.isEmpty) {
            return await _firestore
                .collection(postsCollection)
                .where('userId', isEqualTo: 'no_posts')
                .get();
          }

          return await _firestore
              .collection(postsCollection)
              .where('userId', whereIn: following)
              .orderBy('createdAt', descending: true)
              .get();
        } catch (e) {
          return await _firestore
              .collection(postsCollection)
              .where('userId', isEqualTo: 'no_posts')
              .get();
        }
      });
    }

    return Stream.periodic(const Duration(seconds: 1)).asyncMap((_) async {
      try {
        final viewedPosts = await getViewedPostIds();
        var query = _firestore
            .collection(postsCollection)
            .orderBy('likesCount', descending: true)
            .limit(50);

        if (viewedPosts.isNotEmpty) {
          query = query.where(FieldPath.documentId, whereNotIn: viewedPosts);
        }

        final snapshot = await query.get();

        if (snapshot.docs.isEmpty && viewedPosts.isNotEmpty) {
          await clearViewedPosts();
        }

        return snapshot;
      } catch (e) {
        return await _firestore.collection(postsCollection).limit(1).get();
      }
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
      return false;
    }
  }
}
