import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';
import 'social_service.dart';

class RealtimeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();
  final SocialService _socialService = SocialService();

  // Stream of unread notifications count
  Stream<int> getUnreadNotificationsCount() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value(0);

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUser.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Stream of user's notifications
  Stream<QuerySnapshot> getUserNotifications() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.empty();

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUser.uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Stream of post likes
  Stream<QuerySnapshot> getPostLikes(String postId) {
    return _firestore
        .collection('likes')
        .where('postId', isEqualTo: postId)
        .snapshots();
  }

  // Stream of post comments
  Stream<QuerySnapshot> getPostComments(String postId) {
    return _firestore
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Stream of user's liked posts
  Stream<QuerySnapshot> getUserLikedPosts() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.empty();

    return _firestore
        .collection('likes')
        .where('userId', isEqualTo: currentUser.uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Stream of user's followers
  Stream<QuerySnapshot> getUserFollowers(String userId) {
    return _firestore
        .collection('follows')
        .where('followingId', isEqualTo: userId)
        .snapshots();
  }

  // Stream of users that the current user is following
  Stream<QuerySnapshot> getUserFollowing() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.empty();

    return _firestore
        .collection('follows')
        .where('followerId', isEqualTo: currentUser.uid)
        .snapshots();
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    return _notificationService.markNotificationAsRead(notificationId);
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    return _notificationService.deleteNotification(notificationId);
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    return _notificationService.clearAllNotifications();
  }
} 