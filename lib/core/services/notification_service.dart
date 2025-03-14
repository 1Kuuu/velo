import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';

class NotificationService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get user's notifications stream
  Stream<List<NotificationModel>> getNotifications() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _database
        .child('notifications')
        .orderByChild('userId')
        .equalTo(userId)
        .onValue
        .map((event) {
      final Map<dynamic, dynamic>? data =
          event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];

      return data.entries.map((entry) {
        return NotificationModel.fromRTDB(
            Map<String, dynamic>.from(entry.value), entry.key);
      }).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    });
  }

  // Get unread notifications count
  Stream<int> getUnreadCount() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value(0);

    return _database
        .child('notifications')
        .orderByChild('userId')
        .equalTo(userId)
        .onValue
        .map((event) {
      final Map<dynamic, dynamic>? data =
          event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return 0;

      return data.values
          .where((notification) => !(notification['isRead'] ?? false))
          .length;
    });
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _database
        .child('notifications')
        .child(notificationId)
        .update({'isRead': true});
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final notifications = await _database
        .child('notifications')
        .orderByChild('userId')
        .equalTo(userId)
        .get();

    if (notifications.value != null) {
      final Map<dynamic, dynamic> data =
          notifications.value as Map<dynamic, dynamic>;
      final batch = {};
      data.forEach((key, value) {
        (batch as Map<String, Object?>)['/notifications/$key/isRead'] = true;
      });
      await _database.update(batch as Map<String, Object?>);
    }
  }

  // Add a new notification
  Future<void> addNotification({
    required String title,
    required String message,
    required String type,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final notification = NotificationModel(
      id: '',
      title: title,
      message: message,
      timestamp: DateTime.now(),
      isRead: false,
      type: type,
      userId: userId,
    );

    await _database.child('notifications').push().set(notification.toJson());
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    await _database.child('notifications').child(notificationId).remove();
  }
}
