import 'package:flutter/material.dart';
import '../services/user_data_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:loho_ebook_reader/theme/app_theme.dart';

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
      final fetchedNotifications = await UserDataService.instance
          .fetchNotifications();

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

  Future<void> _markAllAsRead() async {
    try {
      final success = await UserDataService.instance.markNotificationsAsRead();
      if (success && mounted) {
        setState(() {
          // Safely map and clone the list items to avoid immutable map errors
          _notifications = _notifications.map((n) {
            if (n is Map) {
              final map = Map<String, dynamic>.from(n);
              map['is_read'] = true;
              return map;
            }
            return n;
          }).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to mark as read: $e')));
      }
    }
  }

  Future<void> _deleteAllNotifications() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All'),
        content: const Text(
          'Are you sure you want to delete all notifications?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() {
        _notifications.clear();
      });
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
        actions: [
          if (_notifications.any((n) => n is Map && n['is_read'] == false))
            IconButton(
              icon: const Icon(Icons.done_all_rounded),
              tooltip: 'Mark all as read',
              onPressed: _markAllAsRead,
            ),
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: 'Delete all notifications',
              onPressed: _deleteAllNotifications,
            ),
        ],
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
                final uniqueKeyId =
                    notification is Map && notification.containsKey('id')
                    ? notification['id'].toString()
                    : notification.hashCode.toString();

                return Dismissible(
                  key: Key(uniqueKeyId),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.centerRight,
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  onDismissed: (direction) {
                    setState(() {
                      _notifications.removeAt(index);
                    });
                  },
                  child: Container(
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                  ),
                ).animate().fadeIn(delay: (50 * index).ms).slideX(begin: 0.1);
              },
            ),
    );
  }
}
