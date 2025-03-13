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

      // Validate content length
      if (content.length > 1000) {
        throw Exception('Content exceeds 1000 character limit');
      }

      String? mediaUrl;
      String mediaType = 'none';

      if (image != null) {
        print('Uploading image...');
        try {
          // First verify the file exists and is readable
          if (!await image.exists()) {
            throw Exception('Image file does not exist');
          }

          // Validate file size (10MB limit)
          final fileSize = await image.length();
          if (fileSize > 10 * 1024 * 1024) {
            throw Exception('Image size exceeds 10MB limit');
          }

          print('File path: ${image.path}');
          print('User authenticated: ${_auth.currentUser != null}');
          print('User ID: ${_auth.currentUser?.uid}');
          print('Storage bucket: ${_storage.bucket}');

          // Get user token for additional auth verification
          final token = await user.getIdToken();
          print('User token available: ${token != null}');

          // Create a unique filename that matches storage rules pattern exactly
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final fileName = '${user.uid}_$timestamp.jpg';

          // Create storage reference
          final ref = _storage.ref('images/$fileName');
          print('Uploading to: ${ref.fullPath}');
          print('Full storage path: ${ref.toString()}');
          print('File exists: ${await image.exists()}');
          print('File size: ${await image.length()} bytes');
          print('Content type: image/jpeg');
          final pattern = RegExp('^${user.uid}_[0-9]+\\.jpg\$');
          print('Filename pattern check: ${pattern.hasMatch(fileName)}');

          // Create metadata with exact content type required by rules
          final metadata = SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'userId': user.uid,
              'timestamp': DateTime.now().toIso8601String(),
              if (token != null) 'authToken': token,
            },
          );

          try {
            // Verify file type and size
            final extension = image.path.split('.').last.toLowerCase();
            print('File extension: $extension');
            final fileSize = await image.length();
            print('File size in MB: ${fileSize / (1024 * 1024)}');

            if (extension != 'jpg' && extension != 'jpeg') {
              throw Exception('Only JPG/JPEG images are allowed');
            }

            print('Starting upload...');
            print('Reference path: ${ref.fullPath}');
            print('Auth state before upload:');
            print('- User signed in: ${_auth.currentUser != null}');
            print('- User email verified: ${_auth.currentUser?.emailVerified}');
            print('- User anonymous: ${_auth.currentUser?.isAnonymous}');

            final task = ref.putFile(
              image,
              metadata,
            );

            // Monitor upload progress
            task.snapshotEvents.listen(
              (TaskSnapshot snapshot) {
                final progress =
                    snapshot.bytesTransferred / snapshot.totalBytes;
                print(
                    'Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
              },
              onError: (error) {
                print('Upload progress monitoring error: $error');
              },
            );

            // Wait for upload to complete
            final snapshot = await task;
            print('Upload completed. Getting download URL...');

            // Get download URL
            mediaUrl = await snapshot.ref.getDownloadURL();
            mediaType = 'image';
            print('Image uploaded successfully: $mediaUrl');
          } catch (e) {
            print('Error uploading image: $e');
            if (e is FirebaseException) {
              print('Firebase error code: ${e.code}');
              print('Firebase error message: ${e.message}');
              throw Exception('Failed to upload image: ${e.message}');
            }
            rethrow;
          }
        } catch (e) {
          print('Error uploading image: $e');
          if (e is FirebaseException) {
            print('Firebase error code: ${e.code}');
            print('Firebase error message: ${e.message}');
            throw Exception('Failed to upload image: ${e.message}');
          }
          rethrow;
        }
      } else if (video != null) {
        print('Uploading video...');
        try {
          // First verify the file exists and is readable
          if (!await video.exists()) {
            throw Exception('Video file does not exist');
          }

          // Validate file size (100MB limit)
          final fileSize = await video.length();
          final fileSizeInMB = fileSize / (1024 * 1024);
          print('Video file size: ${fileSizeInMB.toStringAsFixed(2)} MB');

          if (fileSize > 100 * 1024 * 1024) {
            throw Exception(
                'Video size exceeds 100MB limit. Your video is ${fileSizeInMB.toStringAsFixed(2)} MB');
          }

          print('File path: ${video.path}');
          print('User authenticated: ${_auth.currentUser != null}');
          print('User ID: ${_auth.currentUser?.uid}');
          print('Storage bucket: ${_storage.bucket}');

          // Create a unique filename that matches storage rules pattern exactly
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final fileName = '${user.uid}_$timestamp.mp4';

          // Create storage reference with a more specific path
          final ref = _storage.ref('videos/$fileName');
          print('Uploading to: ${ref.fullPath}');
          print('Full storage path: ${ref.toString()}');
          print('File exists: ${await video.exists()}');
          print('File size: ${await video.length()} bytes');

          // Enhanced metadata for better video playback compatibility
          final metadata = SettableMetadata(
            contentType: 'video/mp4',
            customMetadata: {
              'userId': user.uid,
              'timestamp': DateTime.now().toIso8601String(),
              'originalFileName': video.path.split('/').last,
              'fileSize': fileSize.toString(),
              'uploadType': 'video',
              'duration': '0', // Will be updated by Firebase
              'width': '0', // Will be updated by Firebase
              'height': '0', // Will be updated by Firebase
            },
            cacheControl: 'public, max-age=31536000',
            contentEncoding: 'identity',
            contentLanguage: 'en',
          );

          try {
            // Enhanced file type verification
            final extension = video.path.split('.').last.toLowerCase();
            print('File extension: $extension');
            print('File size in MB: ${fileSize / (1024 * 1024)}');

            if (!['mp4'].contains(extension)) {
              throw Exception(
                  'Only MP4 videos are supported for best compatibility');
            }

            print('Starting upload...');
            print('Reference path: ${ref.fullPath}');
            print('Content type: video/mp4');

            final task = ref.putFile(
              video,
              metadata,
            );

            // Enhanced upload progress monitoring with state checks
            task.snapshotEvents.listen(
              (TaskSnapshot snapshot) {
                final progress =
                    snapshot.bytesTransferred / snapshot.totalBytes;
                print(
                    'Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
                print('Bytes transferred: ${snapshot.bytesTransferred}');
                print('Total bytes: ${snapshot.totalBytes}');
                print('Upload state: ${snapshot.state}');

                // Check for paused or error states
                if (snapshot.state == TaskState.paused) {
                  print('Upload is paused. Resuming...');
                  task.resume();
                }
              },
              onError: (error) {
                print('Upload progress monitoring error: $error');
                if (error is FirebaseException) {
                  print('Firebase error code: ${error.code}');
                  print('Firebase error message: ${error.message}');
                }
              },
            );

            // Wait for upload to complete
            final snapshot = await task;
            print('Upload completed. Getting download URL...');
            print('Final upload state: ${snapshot.state}');
            print(
                'Content type after upload: ${snapshot.metadata?.contentType}');

            // Verify the upload was successful
            if (snapshot.state != TaskState.success) {
              throw Exception(
                  'Upload did not complete successfully. State: ${snapshot.state}');
            }

            // Get download URL with additional verification
            mediaUrl = await snapshot.ref.getDownloadURL();
            if (mediaUrl.isEmpty) {
              throw Exception('Failed to get download URL');
            }

            // Verify the uploaded file exists and is accessible
            final uploadedMetadata = await snapshot.ref.getMetadata();
            print('Uploaded file size: ${uploadedMetadata.size} bytes');
            print('Uploaded content type: ${uploadedMetadata.contentType}');
            print('Upload time: ${uploadedMetadata.timeCreated}');

            mediaType = 'video';
            print('Video uploaded successfully');
            print('Download URL: $mediaUrl');
            print('Final metadata: ${uploadedMetadata.toString()}');
          } catch (e) {
            print('Error uploading video: $e');
            if (e is FirebaseException) {
              print('Firebase error code: ${e.code}');
              print('Firebase error message: ${e.message}');
              throw Exception('Failed to upload video: ${e.message}');
            }
            rethrow;
          }
        } catch (e) {
          print('Error uploading video: $e');
          if (e is FirebaseException) {
            print('Firebase error code: ${e.code}');
            print('Firebase error message: ${e.message}');
            throw Exception('Failed to upload video: ${e.message}');
          }
          rethrow;
        }
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
        // Optional fields
        'mediaUrl': mediaUrl ?? '',
        'mediaType': mediaType,
        'route': rideData?['route'] ?? '',
        'distance': rideData?['distance'] ?? 0,
        'duration': rideData?['duration'] ?? '',
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
    } catch (e, stackTrace) {
      print('Error creating post: $e');
      print('Stack trace: $stackTrace');
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
      final userData = await getUserData(user.uid);
      print('User data fetched: $userData');

      // Create the comment with all required fields
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
        print('Comment created successfully');
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
      if (user == null) {
        print('No authenticated user found');
        return false;
      }

      print('Attempting to delete comment...');
      print('Post ID: $postId');
      print('Comment ID: $commentId');
      print('User ID: ${user.uid}');

      // Get references
      final postRef = _firestore.collection(postsCollection).doc(postId);
      final commentRef = postRef.collection(commentsCollection).doc(commentId);

      // Get comment document first
      final commentDoc = await commentRef.get();
      if (!commentDoc.exists) {
        print('Comment does not exist');
        return false;
      }

      final commentData = commentDoc.data()!;
      print('Comment owner ID: ${commentData['userId']}');

      // If user is comment owner, delete directly
      if (commentData['userId'] == user.uid) {
        print('User is comment owner, proceeding with deletion');
        await commentRef.delete();
        await postRef.update({'commentsCount': FieldValue.increment(-1)});
        print('Comment deleted successfully by comment owner');
        return true;
      }

      // If not comment owner, check if user is post owner
      final postDoc = await postRef.get();
      if (!postDoc.exists) {
        print('Post does not exist');
        return false;
      }

      final postData = postDoc.data()!;
      print('Post owner ID: ${postData['userId']}');

      if (postData['userId'] == user.uid) {
        print('User is post owner, proceeding with deletion');
        await commentRef.delete();
        await postRef.update({'commentsCount': FieldValue.increment(-1)});
        print('Comment deleted successfully by post owner');
        return true;
      }

      print('User does not have permission to delete this comment');
      return false;
    } catch (e) {
      print('Error deleting comment: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  // Mark post as viewed
  static Future<void> markPostAsViewed(String postId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('Cannot mark post as viewed: No authenticated user');
        return;
      }

      // First ensure the user profile document exists
      final userProfileRef =
          _firestore.collection(usersCollection).doc(user.uid);

      try {
        // Check if the post is already viewed to avoid unnecessary writes
        final viewedPostRef =
            userProfileRef.collection(viewedPostsCollection).doc(postId);
        final viewedDoc = await viewedPostRef.get();

        if (viewedDoc.exists) {
          print('Post $postId is already marked as viewed');
          return;
        }

        // Create the viewed post document with required fields
        await viewedPostRef.set({
          'timestamp': FieldValue.serverTimestamp(),
          'userId': user.uid,
          'postId': postId,
        });

        print('Successfully marked post $postId as viewed');
      } catch (e) {
        print('Error marking post as viewed: $e');
        if (e is FirebaseException && e.code == 'permission-denied') {
          // Create user profile if it doesn't exist and try again
          await userProfileRef.set({
            'userId': user.uid,
            'createdAt': FieldValue.serverTimestamp(),
            'userName': user.displayName ?? 'Anonymous',
            'email': user.email ?? '',
            'profileUrl': user.photoURL ?? '',
          }, SetOptions(merge: true));

          // Try marking as viewed again
          await userProfileRef
              .collection(viewedPostsCollection)
              .doc(postId)
              .set({
            'timestamp': FieldValue.serverTimestamp(),
            'userId': user.uid,
            'postId': postId,
          });
          print(
              'Successfully marked post $postId as viewed after creating profile');
        } else {
          rethrow;
        }
      }
    } catch (e) {
      print('Error marking post as viewed: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  // Get viewed post IDs with error handling
  static Future<List<String>> getViewedPostIds() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      // Calculate timestamp from 2 hours ago
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
      print('Error getting viewed posts: $e');
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
          .limit(500) // Process in batches of 500
          .get();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Error clearing viewed posts: $e');
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

          print('Fetching Following tab posts for user: ${user.uid}');

          if (!userDoc.exists) {
            print('User document does not exist');
            return await _firestore
                .collection(postsCollection)
                .where('userId', isEqualTo: 'no_posts')
                .get();
          }

          // Get list of users being followed
          final userData = userDoc.data() ?? {};
          print('User data: $userData');

          List<String> following =
              List<String>.from(userData['following'] ?? []);
          print('Following list: $following');

          // If not following anyone, return empty result
          if (following.isEmpty) {
            print('Following list is empty');
            return await _firestore
                .collection(postsCollection)
                .where('userId', isEqualTo: 'no_posts')
                .get();
          }

          print('Fetching posts for followed users: $following');

          // Get posts from followed users only
          final querySnapshot = await _firestore
              .collection(postsCollection)
              .where('userId', whereIn: following)
              .orderBy('createdAt', descending: true)
              .get();

          print('Found ${querySnapshot.docs.length} posts from followed users');
          querySnapshot.docs.forEach((doc) {
            final data = doc.data();
            print(
                'Post: ID=${doc.id}, UserID=${data['userId']}, Content=${data['content']}');
          });

          return querySnapshot;
        } catch (e) {
          print('Error getting following posts: $e');
          print('Stack trace: ${StackTrace.current}');
          return await _firestore
              .collection(postsCollection)
              .where('userId', isEqualTo: 'no_posts')
              .get();
        }
      });
    }

    // For Discover tab, show posts that haven't been viewed by the current user
    return Stream.periodic(const Duration(seconds: 1)).asyncMap((_) async {
      try {
        // Get only the current user's viewed post IDs
        final viewedPosts = await getViewedPostIds();
        print('Current user viewed posts count: ${viewedPosts.length}');

        // Get posts ordered by likes, excluding only the current user's viewed posts
        var query = _firestore
            .collection(postsCollection)
            .orderBy('likesCount', descending: true)
            .limit(50);

        // Only apply whereNotIn filter if the current user has viewed posts
        if (viewedPosts.isNotEmpty) {
          query = query.where(FieldPath.documentId, whereNotIn: viewedPosts);
        }

        final snapshot = await query.get();
        print('Retrieved ${snapshot.docs.length} posts for Discover tab');

        // If no new posts found and the current user has viewed posts, clear only their viewed posts history
        if (snapshot.docs.isEmpty && viewedPosts.isNotEmpty) {
          print(
              'No new posts found for current user, clearing their viewed posts history');
          await clearViewedPosts();
        }

        return snapshot;
      } catch (e) {
        print('Error getting discover posts: $e');
        // Return empty snapshot on error
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
