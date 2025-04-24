import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:velora/core/configs/theme/app_fonts.dart';
import 'package:velora/core/configs/theme/theme_provider.dart';
import 'package:velora/presentation/widgets/reusable_wdgts.dart';
import 'package:provider/provider.dart';
import 'package:velora/presentation/screens/0Auth/profile.dart';
import 'package:velora/presentation/screens/3News/post_detail_screen.dart';


class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  List<NotificationItem> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        setState(() {
          _isLoading = false;
          _notifications = [];
        });
        return;
      }

      // Get notifications collection
      final notificationsSnapshot = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      // Process notifications
      final List<NotificationItem> notifications = [];
      for (var doc in notificationsSnapshot.docs) {
        final data = doc.data();
        
        // Get user info for sender
        DocumentSnapshot? senderDoc;
        if (data['senderId'] != null) {
          senderDoc = await _firestore
              .collection('users')
              .doc(data['senderId'])
              .get();
        }

        // Build notification item
        notifications.add(
          NotificationItem(
            id: doc.id,
            type: data['type'] ?? 'unknown',
            message: data['message'] ?? 'New notification',
            timestamp: (data['timestamp'] as Timestamp).toDate(),
            isRead: data['isRead'] ?? false,
            senderId: data['senderId'],
            senderName: senderDoc?.get('userName') ?? 'User',
            senderProfileUrl: senderDoc?.get('profileUrl'),
            relatedPostId: data['postId'],
            relatedCommentId: data['commentId'],
          ),
        );
      }

      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching notifications: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});

      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          _notifications[index] = _notifications[index].copyWith(isRead: true);
        }
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Get all unread notifications
      final batch = _firestore.batch();
      final unreadDocs = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      // Batch update all unread notifications
      for (var doc in unreadDocs.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      // Update local state
      setState(() {
        _notifications = _notifications
            .map((notification) => notification.copyWith(isRead: true))
            .toList();
      });
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: MyAppBar(
        title: "Notifications",
        actions: [
          if (_notifications.any((notification) => !notification.isRead))
            AppBarIcon(
              icon: Icons.done_all,
              onTap: _markAllAsRead,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState(isDarkMode)
              : _buildNotificationsList(isDarkMode),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Empty state illustration
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDarkMode 
                  ? const Color(0xFF4A3B7C).withOpacity(0.2) 
                  : AppColors.primary.withOpacity(0.1),
            ),
            child: Icon(
            Icons.notifications_none,
              size: 70,
              color: isDarkMode ? const Color(0xFF4A3B7C) : AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          
          // Title with custom font
          Text(
            "No notifications yet",
            style: AppFonts.bold.copyWith(
              fontSize: 22,
              color: isDarkMode ? Colors.white : AppColors.blacktxt,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Description with custom styling
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              "You'll be notified when someone likes, comments, or follows you",
            textAlign: TextAlign.center,
            style: AppFonts.regular.copyWith(
                fontSize: 16,
                height: 1.4,
              color: isDarkMode ? Colors.white60 : AppColors.lightGrey,
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Action button
          ElevatedButton(
            onPressed: _fetchNotifications,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkMode ? const Color(0xFF4A3B7C) : AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Refresh',
                  style: AppFonts.semibold.copyWith(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(bool isDarkMode) {
    return RefreshIndicator(
      onRefresh: _fetchNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return _buildNotificationTile(notification, isDarkMode);
        },
      ),
    );
  }

  Widget _buildNotificationTile(NotificationItem notification, bool isDarkMode) {
    IconData iconData;
    Color iconColor;
    
    // Determine icon based on notification type
    switch (notification.type) {
      case 'like':
        iconData = Icons.favorite;
        iconColor = Colors.red;
        break;
      case 'comment':
        iconData = Icons.comment;
        iconColor = Colors.blue;
        break;
      case 'follow':
        iconData = Icons.person_add;
        iconColor = Colors.green;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = Colors.orange;
    }

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        // Delete notification from Firestore
        _firestore.collection('notifications').doc(notification.id).delete();
        
        // Remove from local list
        setState(() {
          _notifications.removeAt(_notifications.indexOf(notification));
        });
      },
      child: Card(
        elevation: !notification.isRead ? 2 : 0,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: !notification.isRead
            ? (isDarkMode ? Colors.white.withOpacity(0.05) : Colors.blue.withOpacity(0.05))
            : isDarkMode ? Colors.transparent : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: !notification.isRead
              ? BorderSide(
                  color: isDarkMode 
                      ? const Color(0xFF4A3B7C).withOpacity(0.3) 
                      : AppColors.primary.withOpacity(0.3),
                  width: 1,
                )
              : BorderSide.none,
        ),
      child: InkWell(
        onTap: () {
          // Mark as read if not already read
          if (!notification.isRead) {
            _markAsRead(notification.id);
          }
          
            // Navigate based on notification type
            _navigateToNotificationContent(notification);
          },
          borderRadius: BorderRadius.circular(8),
          splashColor: isDarkMode 
              ? const Color(0xFF4A3B7C).withOpacity(0.2) 
              : AppColors.primary.withOpacity(0.1),
          highlightColor: isDarkMode 
              ? const Color(0xFF4A3B7C).withOpacity(0.1) 
              : AppColors.primary.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile picture or icon with animation
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: iconColor.withOpacity(0.1),
                    boxShadow: !notification.isRead
                        ? [
                            BoxShadow(
                              color: iconColor.withOpacity(0.2),
                              blurRadius: 8,
                              spreadRadius: 1,
                            )
                          ]
                      : null,
                  ),
                  child: notification.senderProfileUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: Image.network(
                            notification.senderProfileUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(iconData, color: iconColor, size: 22);
                            },
                          ),
                        )
                      : Icon(iconData, color: iconColor, size: 22),
                ),
                const SizedBox(width: 15),
                
                // Content with better typography
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Notification text
                      RichText(
                        text: TextSpan(
                          style: AppFonts.regular.copyWith(
                            fontSize: 14,
                            height: 1.3,
                            color: isDarkMode ? Colors.white : AppColors.blacktxt,
                          ),
                          children: [
                            TextSpan(
                              text: notification.senderName,
                              style: AppFonts.semibold.copyWith(
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            TextSpan(text: ' ${notification.message}'),
                          ],
                        ),
                      ),
                      
                      // Time with better formatting
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: isDarkMode ? Colors.white60 : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                      Text(
                        _formatTimestamp(notification.timestamp),
                        style: AppFonts.light.copyWith(
                          fontSize: 12,
                          color: isDarkMode ? Colors.white60 : Colors.grey,
                        ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Unread indicator with animation
                if (!notification.isRead)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDarkMode ? const Color(0xFF4A3B7C) : AppColors.primary,
                      boxShadow: [
                        BoxShadow(
                          color: (isDarkMode ? const Color(0xFF4A3B7C) : AppColors.primary).withOpacity(0.4),
                          blurRadius: 4,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 7) {
      // More than a week ago - show date
      return DateFormat('MMM d, yyyy').format(timestamp);
    } else if (difference.inDays > 0) {
      // Days ago
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      // Hours ago
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      // Minutes ago
      return '${difference.inMinutes}m ago';
    } else {
      // Just now
      return 'Just now';
    }
  }

  void _navigateToNotificationContent(NotificationItem notification) {
    switch (notification.type) {
      case 'like':
        if (notification.relatedPostId != null) {
          _navigateToPost(notification.relatedPostId!);
        }
        break;
      case 'comment':
        if (notification.relatedPostId != null) {
          _navigateToComment(notification.relatedPostId!, notification.relatedCommentId);
        }
        break;
      case 'follow':
        if (notification.senderId != null) {
          _navigateToUserProfile(notification.senderId!);
        }
        break;
      default:
        _showSnackBar('Unknown notification type');
    }
  }

  void _navigateToPost(String postId) {
    // Navigate to the post detail screen with transition
    _firestore.collection('posts').doc(postId).get().then((doc) {
      if (doc.exists) {
        // Use page transition for better UX
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailScreen(postId: postId),
          ),
        );
      } else {
        _showSnackBar('Post no longer exists');
      }
    }).catchError((e) {
      print('Error navigating to post: $e');
      _showSnackBar('Could not load the post');
    });
  }

  void _navigateToComment(String postId, String? commentId) {
    // Show loading indicator while fetching post
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    // Navigate to post detail screen with focus on specific comment
    _firestore.collection('posts').doc(postId).get().then((doc) {
      // First dismiss the loading dialog
      Navigator.pop(context);
      
      if (doc.exists) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailScreen(
              postId: postId,
              focusedCommentId: commentId,
            ),
          ),
        );
      } else {
        _showSnackBar('Post no longer exists');
      }
    }).catchError((e) {
      // Dismiss the loading dialog on error
      Navigator.pop(context);
      print('Error navigating to comment: $e');
      _showSnackBar('Could not load the post');
    });
  }

  void _navigateToUserProfile(String userId) {
    // Navigate to the profile page with a better transition
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    
    // Show loading indicator while fetching user data
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(
            color: isDarkMode ? const Color(0xFF4A3B7C) : AppColors.primary,
          ),
        );
      },
    );
    
    // First check if user exists
    _firestore.collection('users').doc(userId).get().then((doc) {
      // Dismiss the loading dialog
      Navigator.pop(context);
      
      if (doc.exists) {
        // Navigate to profile with hero animation if avatar is available
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilePage(userId: userId),
          ),
        );
      } else {
        _showSnackBar('User profile no longer exists');
      }
    }).catchError((e) {
      // Dismiss the loading dialog on error
      Navigator.pop(context);
      print('Error navigating to user profile: $e');
      _showSnackBar('Could not load the user profile');
    });
  }

  void _showSnackBar(String message) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.white,
          ),
        ),
        backgroundColor: isDarkMode ? const Color(0xFF4A3B7C) : AppColors.primary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

class NotificationItem {
  final String id;
  final String type;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? senderId;
  final String senderName;
  final String? senderProfileUrl;
  final String? relatedPostId;
  final String? relatedCommentId;

  NotificationItem({
    required this.id,
    required this.type,
    required this.message,
    required this.timestamp,
    required this.isRead,
    this.senderId,
    required this.senderName,
    this.senderProfileUrl,
    this.relatedPostId,
    this.relatedCommentId,
  });

  NotificationItem copyWith({
    String? id,
    String? type,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    String? senderId,
    String? senderName,
    String? senderProfileUrl,
    String? relatedPostId,
    String? relatedCommentId,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      type: type ?? this.type,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderProfileUrl: senderProfileUrl ?? this.senderProfileUrl,
      relatedPostId: relatedPostId ?? this.relatedPostId,
      relatedCommentId: relatedCommentId ?? this.relatedCommentId,
    );
  }
} 