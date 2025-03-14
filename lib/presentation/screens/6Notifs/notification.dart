import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:velora/core/configs/theme/app_fonts.dart';
import 'package:velora/core/models/notification_model.dart';
import 'package:velora/core/services/notification_service.dart';
import 'package:velora/presentation/widgets/reusable_wdgts.dart';
import 'package:provider/provider.dart';
import 'package:velora/core/configs/theme/theme_provider.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final NotificationService _notificationService = NotificationService();

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF121212) : AppColors.lightBackground,
      appBar: MyAppBar(
        title: "Notifications",
        actions: [
          TextButton(
            onPressed: () async {
              await _notificationService.markAllAsRead();
            },
            child: Text(
              "Mark all as read",
              style: AppFonts.medium.copyWith(
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _notificationService.getNotifications(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: isDarkMode ? Colors.white38 : Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No notifications yet",
                    style: AppFonts.medium.copyWith(
                      fontSize: 18,
                      color: isDarkMode ? Colors.white70 : Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return Dismissible(
                key: Key(notification.id),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  _notificationService.deleteNotification(notification.id);
                },
                child: ListTile(
                  onTap: () {
                    _notificationService.markAsRead(notification.id);
                  },
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getNotificationColor(notification.type),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getNotificationIcon(notification.type),
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    notification.title,
                    style: AppFonts.semibold.copyWith(
                      color: isDarkMode ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.message,
                        style: AppFonts.regular.copyWith(
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      Text(
                        DateFormat('MMM d, h:mm a')
                            .format(notification.timestamp),
                        style: AppFonts.regular.copyWith(
                          color: isDarkMode ? Colors.white38 : Colors.black38,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  trailing: !notification.isRead
                      ? Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'event':
        return Colors.blue;
      case 'alert':
        return Colors.red;
      case 'info':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'event':
        return Icons.event;
      case 'alert':
        return Icons.warning;
      case 'info':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }
}
