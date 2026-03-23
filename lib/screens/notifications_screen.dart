import 'package:flutter/material.dart';
import 'package:loho_ebook_reader/theme/app_theme.dart';
import '../services/user_data_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final fetchedNotifications =
          await UserDataService.instance.fetchNotifications();

      if (mounted) {
        setState(() {
          if (fetchedNotifications != null) {
            _notifications = fetchedNotifications;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load notifications: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: AppColors.brandGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFF0F8FF),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.brandGreen),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.lightGreen),
            )
          : _notifications.isEmpty
          ? const Center(
              child: Text(
                'No notifications yet!',
                style: TextStyle(fontSize: 18, color: Colors.blueGrey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                // Safely check if a notification is read/unread depending on your API structure
                final isUnread = notification['is_read'] == false;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isUnread
                        ? AppColors.lightGreen.withOpacity(0.05)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isUnread
                          ? AppColors.lightGreen.withOpacity(0.3)
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: isUnread
                            ? AppColors.lightGreen.withOpacity(0.2)
                            : const Color(0xFFF0F8FF),
                        child: Icon(
                          Icons.notifications_rounded,
                          color: isUnread
                              ? AppColors.lightGreen
                              : AppColors.lightGreen,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  notification['title'] ?? 'Notification',
                                  style: TextStyle(
                                    fontWeight: isUnread
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    fontSize: 16,
                                    color: const Color(0xFF333333),
                                  ),
                                ),
                                Text(
                                  notification['time'] ?? '',
                                  style: TextStyle(
                                    color: isUnread
                                        ? AppColors.lightGreen
                                        : Colors.grey.shade500,
                                    fontSize: 12,
                                    fontWeight: isUnread
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notification['message'] ?? '',
                              style: TextStyle(
                                color: Colors.blueGrey.shade700,
                                fontSize: 14,
                                fontWeight: isUnread
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: (50 * index).ms).slideX(begin: 0.1);
              },
            ),
    );
  }
}
