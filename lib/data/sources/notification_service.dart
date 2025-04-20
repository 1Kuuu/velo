import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Create a new notification
  Future<void> createNotification({
    required String userId,
    required String type,
    required String message,
    String? postId,
    String? commentId,
    String? likeId,
    String? followerId,
    Map<String, dynamic>? additionalData,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final notificationData = {
      'userId': userId,
      'type': type,
      'message': message,
      'postId': postId,
      'commentId': commentId,
      'likeId': likeId,
      'followerId': followerId,
      'isRead': false,
      'timestamp': FieldValue.serverTimestamp(),
      if (additionalData != null) ...additionalData,
    };

    await _firestore.collection('notifications').add(notificationData);
  }

  /// Create a like notification
  Future<void> createLikeNotification(String postId, String postUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid == postUserId) return;

    await createNotification(
      userId: postUserId,
      type: 'like',
      message: 'liked your post',
      postId: postId,
      likeId: currentUser.uid,
    );
  }

  /// Create a comment notification
  Future<void> createCommentNotification(String postId, String postUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid == postUserId) return;

    await createNotification(
      userId: postUserId,
      type: 'comment',
      message: 'commented on your post',
      postId: postId,
      commentId: currentUser.uid,
    );
  }

  /// Create a follow notification
  Future<void> createFollowNotification(String followedUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid == followedUserId) return;

    await createNotification(
      userId: followedUserId,
      type: 'follow',
      message: 'started following you',
      followerId: currentUser.uid,
    );
  }

  /// Get user's notifications
  Future<QuerySnapshot> getUserNotifications() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Future.value();

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUser.uid)
        .orderBy('timestamp', descending: true)
        .get();
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final batch = _firestore.batch();
    final notifications = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUser.uid)
        .get();

    for (var doc in notifications.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  /// Create event notification
  Future<void> createEventNotification({
    required String eventId,
    required String eventTitle,
    String? message,
  }) async {
    try {
      await createNotification(
        userId: eventId,
        type: 'event',
        message: message ?? 'You have a new event: $eventTitle',
        additionalData: {
          'eventTitle': eventTitle,
        },
      );
    } catch (e) {
      print('Error creating event notification: $e');
      rethrow;
    }
  }

  /// Create message notification
  Future<void> createMessageNotification({
    required String chatId,
    required String senderName,
    required String message,
  }) async {
    try {
      await createNotification(
        userId: chatId,
        type: 'message',
        message: '$senderName: $message',
      );
    } catch (e) {
      print('Error creating message notification: $e');
      rethrow;
    }
  }

  /// Create system notification
  Future<void> createSystemNotification({
    required String message,
    String? category,
  }) async {
    try {
      await createNotification(
        userId: '',
        type: 'system${category != null ? '_$category' : ''}',
        message: message,
        additionalData: category != null ? {'category': category} : null,
      );
    } catch (e) {
      print('Error creating system notification: $e');
      rethrow;
    }
  }

  /// Activity-specific notifications
  Future<void> createActivityNotification({
    required String activityType,
    required String activityId,
    required String message,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      await createNotification(
        userId: activityId,
        type: 'activity_$activityType',
        message: message,
        additionalData: additionalData,
      );
    } catch (e) {
      print('Error creating activity notification: $e');
      rethrow;
    }
  }

  /// Workout notifications
  Future<void> createWorkoutNotification({
    required String workoutId,
    required String message,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      await createNotification(
        userId: workoutId,
        type: 'workout',
        message: message,
        additionalData: additionalData,
      );
    } catch (e) {
      print('Error creating workout notification: $e');
      rethrow;
    }
  }

  /// Route notifications
  Future<void> createRouteNotification({
    required String routeId,
    required String message,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      await createNotification(
        userId: routeId,
        type: 'route',
        message: message,
        additionalData: additionalData,
      );
    } catch (e) {
      print('Error creating route notification: $e');
      rethrow;
    }
  }

  /// Social notifications
  Future<void> createSocialNotification({
    required String type,
    required String targetId,
    required String message,
    String? senderId,
    String? senderName,
    String? senderProfileUrl,
  }) async {
    try {
      await createNotification(
        userId: targetId,
        type: 'social_$type',
        message: message,
        additionalData: {
          if (senderId != null) 'senderId': senderId,
          if (senderName != null) 'senderName': senderName,
          if (senderProfileUrl != null) 'senderProfileUrl': senderProfileUrl,
        },
      );
    } catch (e) {
      print('Error creating social notification: $e');
      rethrow;
    }
  }

  /// Achievement notifications
  Future<void> createAchievementNotification({
    required String achievementId,
    required String message,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      await createNotification(
        userId: achievementId,
        type: 'achievement',
        message: message,
        additionalData: additionalData,
      );
    } catch (e) {
      print('Error creating achievement notification: $e');
      rethrow;
    }
  }
} 