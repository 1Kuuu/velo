import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:velora/presentation/screens/3News/event_details_page.dart';
import 'package:velora/presentation/screens/4Chat/chat.dart';
import 'package:velora/presentation/widgets/reusable_wdgts.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:velora/core/configs/theme/app_fonts.dart';
import 'package:provider/provider.dart';
import 'package:velora/core/configs/theme/theme_provider.dart';
import 'package:intl/intl.dart';
import 'package:velora/data/sources/notification_service.dart';
import 'package:velora/data/sources/realtime_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final currentUser = FirebaseAuth.instance.currentUser;
  final NotificationService _notificationService = NotificationService();
  final RealtimeService _realtimeService = RealtimeService();
  bool _isLoading = true;
  String? _errorMessage;
  Stream<QuerySnapshot>? _notificationsStream;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check if user is authenticated
      if (currentUser == null) {
        setState(() {
          _errorMessage = 'Please sign in to view notifications';
          _isLoading = false;
        });
        return;
      }

      // Initialize the notifications stream
      _notificationsStream = _realtimeService.getUserNotifications();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error initializing notifications: ${e.toString()}';
        _isLoading = false;
      });
      print('Error initializing notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      appBar: MyAppBar(
        title: 'Notifications',
      ),
      body: _buildBody(isDarkMode),
    );
  }

  Widget _buildBody(bool isDarkMode) {
    // If user is not authenticated
    if (currentUser == null) {
      return Center(
        child: Text(
          'Please sign in to view notifications',
          style: AppFonts.medium.copyWith(
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      );
    }

    // Show loading indicator
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Show error message if there is one
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading notifications',
              style: AppFonts.medium.copyWith(
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: AppFonts.regular.copyWith(
                color: Colors.red[300],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeNotifications,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Use StreamBuilder to get real-time updates
    return StreamBuilder<QuerySnapshot>(
      stream: _notificationsStream,
      builder: (context, snapshot) {
        // Handle connection states
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Handle errors
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading notifications',
                  style: AppFonts.medium.copyWith(
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: AppFonts.regular.copyWith(
                    color: Colors.red[300],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _initializeNotifications,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Get notifications
        final notifications = snapshot.data?.docs ?? [];

        // Handle empty notifications
        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none,
                  size: 48,
                  color: isDarkMode ? Colors.white70 : Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  'No notifications yet',
                  style: AppFonts.medium.copyWith(
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          );
        }

        // Build notification list
        return RefreshIndicator(
          onRefresh: () async {
            await _initializeNotifications();
            return Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index].data() as Map<String, dynamic>;
              final notificationId = notifications[index].id;
              final isRead = notification['isRead'] ?? false;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                color: isDarkMode
                    ? (isRead ? Colors.grey[900] : const Color(0xFF4A3B7C))
                    : (isRead ? Colors.grey[100] : AppColors.primary.withOpacity(0.1)),
                child: Dismissible(
                  key: Key(notificationId),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (direction) async {
                    return await _showDeleteConfirmation(context);
                  },
                  onDismissed: (direction) async {
                    try {
                      await _notificationService.deleteNotification(notificationId);
                      
                      // Show success message
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Notification deleted'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      // Show error message
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to delete: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        setState(() {}); // Refresh the UI
                      }
                    }
                  },
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isRead
                            ? (isDarkMode ? Colors.grey[800] : Colors.grey[300])
                            : (isDarkMode ? const Color(0xFF4A3B7C) : AppColors.primary),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getNotificationIcon(notification['type']),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      notification['title'] ?? '',
                      style: AppFonts.bold.copyWith(
                        fontSize: 16,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification['message'] ?? '',
                          style: AppFonts.regular.copyWith(
                            fontSize: 14,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTimestamp(notification['timestamp']),
                          style: AppFonts.regular.copyWith(
                            fontSize: 12,
                            color: isDarkMode ? Colors.white60 : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    onTap: () async {
                      // Mark as read if not already
                      if (!isRead) {
                        try {
                          await _notificationService.markNotificationAsRead(notificationId);
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to mark as read: ${e.toString()}'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        }
                      }
                      
                      // Handle notification tap based on type
                      if (mounted) {
                        _handleNotificationTap(notification);
                      }
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification'),
        content: const Text('Are you sure you want to delete this notification?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'event':
        return Icons.event_outlined;
      case 'message':
        return Icons.message_outlined;
      case 'friend_request':
        return Icons.person_add_outlined;
      case 'like':
        return Icons.favorite_outline;
      case 'comment':
        return Icons.comment_outlined;
      case 'follow':
        return Icons.person_add_outlined;
      case 'system':
        return Icons.info_outline;
      case 'achievement':
        return Icons.emoji_events_outlined;
      case 'workout':
        return Icons.fitness_center;
      case 'route':
        return Icons.map_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      return DateFormat('MMM d, y').format(date);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    final type = notification['type'];
    final targetId = notification['targetId'];

    if (targetId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid notification target')),
      );
      return;
    }

    switch (type) {
      case 'event':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailsPage(eventId: targetId),
          ),
        );
        break;
      case 'message':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPageContent(
              chatId: targetId,
              recipientId: notification['senderId'] ?? '',
              recipientName: notification['senderName'] ?? 'Unknown User',
              recipientProfileUrl: notification['senderProfileUrl'] ?? '',
            ),
          ),
        );
        break;
      default:
        // Handle other notification types or show a message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notification type: $type')),
        );
    }
  }
}