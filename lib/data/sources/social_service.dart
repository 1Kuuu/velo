import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:velora/data/sources/notification_service.dart';

class SocialService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  /// Like a post
  Future<void> likePost(String postId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        print('Error liking post: User not authenticated');
        return;
      }

      // Check if already liked
      final likeDoc = await _firestore
          .collection('likes')
          .where('postId', isEqualTo: postId)
          .where('userId', isEqualTo: userId)
          .get();

      if (likeDoc.docs.isNotEmpty) {
        // Unlike - remove the like
        await _firestore.collection('likes').doc(likeDoc.docs.first.id).delete();
        
        // Update post like count
        await _firestore.collection('posts').doc(postId).update({
          'likeCount': FieldValue.increment(-1),
        });
        
        print('Post unliked successfully');
        return;
      }

      // Get post details for notification
      final postDoc = await _firestore.collection('posts').doc(postId).get();
      final postData = postDoc.data();
      final postUserId = postData?['userId'];
      final postTitle = postData?['title'] ?? 'your post';
      
      // Get current user details
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      final userName = userData?['name'] ?? 'A user';
      final userProfileUrl = userData?['profileUrl'] ?? '';

      // Create like document
      await _firestore.collection('likes').add({
        'postId': postId,
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update post like count
      await _firestore.collection('posts').doc(postId).update({
        'likeCount': FieldValue.increment(1),
      });

      // Create notification for post owner if not the same user
      if (postUserId != null && postUserId != userId) {
        await _notificationService.createSocialNotification(
          type: 'like',
          targetId: postUserId,
          message: '$userName liked your post: $postTitle',
          senderId: userId,
          senderName: userName,
          senderProfileUrl: userProfileUrl,
        );
      }

      print('Post liked successfully');
    } catch (e) {
      print('Error liking post: $e');
      rethrow;
    }
  }

  /// Add a comment to a post
  Future<void> addComment(String postId, String commentText) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        print('Error adding comment: User not authenticated');
        return;
      }

      // Get post details for notification
      final postDoc = await _firestore.collection('posts').doc(postId).get();
      final postData = postDoc.data();
      final postUserId = postData?['userId'];
      final postTitle = postData?['title'] ?? 'your post';
      
      // Get current user details
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      final userName = userData?['name'] ?? 'A user';
      final userProfileUrl = userData?['profileUrl'] ?? '';

      // Create comment document
      final commentRef = await _firestore.collection('comments').add({
        'postId': postId,
        'userId': userId,
        'text': commentText,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update post comment count
      await _firestore.collection('posts').doc(postId).update({
        'commentCount': FieldValue.increment(1),
      });

      // Create notification for post owner if not the same user
      if (postUserId != null && postUserId != userId) {
        await _notificationService.createSocialNotification(
          type: 'comment',
          targetId: postUserId,
          message: '$userName commented on your post: $postTitle',
          senderId: userId,
          senderName: userName,
          senderProfileUrl: userProfileUrl,
        );
      }

      print('Comment added successfully');
    } catch (e) {
      print('Error adding comment: $e');
      rethrow;
    }
  }

  /// Get comments for a post
  Stream<QuerySnapshot> getComments(String postId) {
    if (postId.isEmpty) {
      print('Error getting comments: Invalid post ID');
      return Stream.empty();
    }

    return _firestore
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .handleError((error) {
          print('Error getting comments: $error');
          return Stream.empty();
        });
  }

  /// Get likes for a post
  Stream<QuerySnapshot> getLikes(String postId) {
    if (postId.isEmpty) {
      print('Error getting likes: Invalid post ID');
      return Stream.empty();
    }

    return _firestore
        .collection('likes')
        .where('postId', isEqualTo: postId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .handleError((error) {
          print('Error getting likes: $error');
          return Stream.empty();
        });
  }

  /// Check if current user has liked a post
  Future<bool> hasUserLikedPost(String postId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return false;
      }

      final likeDoc = await _firestore
          .collection('likes')
          .where('postId', isEqualTo: postId)
          .where('userId', isEqualTo: userId)
          .get();

      return likeDoc.docs.isNotEmpty;
    } catch (e) {
      print('Error checking if user liked post: $e');
      return false;
    }
  }

  /// Get user's liked posts
  Stream<QuerySnapshot> getUserLikedPosts(String userId) {
    if (userId.isEmpty) {
      print('Error getting user liked posts: Invalid user ID');
      return Stream.empty();
    }

    return _firestore
        .collection('likes')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .handleError((error) {
          print('Error getting user liked posts: $error');
          return Stream.empty();
        });
  }

  /// Delete a comment
  Future<void> deleteComment(String commentId, String postId) async {
    try {
      if (commentId.isEmpty || postId.isEmpty) {
        print('Error deleting comment: Invalid comment ID or post ID');
        return;
      }

      await _firestore.collection('comments').doc(commentId).delete();

      // Update post comment count
      await _firestore.collection('posts').doc(postId).update({
        'commentCount': FieldValue.increment(-1),
      });

      print('Comment deleted successfully');
    } catch (e) {
      print('Error deleting comment: $e');
      rethrow;
    }
  }

  /// Follow a user
  Future<void> followUser(String userToFollowId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        print('Error following user: User not authenticated');
        return;
      }

      if (userId == userToFollowId) {
        print('Error following user: Cannot follow yourself');
        return;
      }

      // Check if already following
      final followDoc = await _firestore
          .collection('follows')
          .where('followerId', isEqualTo: userId)
          .where('followingId', isEqualTo: userToFollowId)
          .get();

      if (followDoc.docs.isNotEmpty) {
        // Unfollow - remove the follow
        await _firestore.collection('follows').doc(followDoc.docs.first.id).delete();
        
        // Update user follower/following counts
        await _firestore.collection('users').doc(userId).update({
          'followingCount': FieldValue.increment(-1),
        });
        
        await _firestore.collection('users').doc(userToFollowId).update({
          'followerCount': FieldValue.increment(-1),
        });
        
        print('User unfollowed successfully');
        return;
      }

      // Get user to follow details
      final userToFollowDoc = await _firestore.collection('users').doc(userToFollowId).get();
      final userToFollowData = userToFollowDoc.data();
      final userToFollowName = userToFollowData?['name'] ?? 'A user';
      final userToFollowProfileUrl = userToFollowData?['profileUrl'] ?? '';
      
      // Get current user details
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      final userName = userData?['name'] ?? 'A user';
      final userProfileUrl = userData?['profileUrl'] ?? '';

      // Create follow document
      await _firestore.collection('follows').add({
        'followerId': userId,
        'followingId': userToFollowId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update user follower/following counts
      await _firestore.collection('users').doc(userId).update({
        'followingCount': FieldValue.increment(1),
      });
      
      await _firestore.collection('users').doc(userToFollowId).update({
        'followerCount': FieldValue.increment(1),
      });

      // Create notification for followed user
      await _notificationService.createFollowNotification(userToFollowId);

      print('User followed successfully');
    } catch (e) {
      print('Error following user: $e');
      rethrow;
    }
  }

  /// Get user's followers
  Stream<QuerySnapshot> getUserFollowers(String userId) {
    if (userId.isEmpty) {
      print('Error getting user followers: Invalid user ID');
      return Stream.empty();
    }

    return _firestore
        .collection('follows')
        .where('followingId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .handleError((error) {
          print('Error getting user followers: $error');
          return Stream.empty();
        });
  }

  /// Get users that the current user is following
  Stream<QuerySnapshot> getUserFollowing(String userId) {
    if (userId.isEmpty) {
      print('Error getting user following: Invalid user ID');
      return Stream.empty();
    }

    return _firestore
        .collection('follows')
        .where('followerId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .handleError((error) {
          print('Error getting user following: $error');
          return Stream.empty();
        });
  }

  /// Check if current user is following another user
  Future<bool> isUserFollowing(String userToCheckId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return false;
      }

      final followDoc = await _firestore
          .collection('follows')
          .where('followerId', isEqualTo: userId)
          .where('followingId', isEqualTo: userToCheckId)
          .get();

      return followDoc.docs.isNotEmpty;
    } catch (e) {
      print('Error checking if user is following: $e');
      return false;
    }
  }
} 