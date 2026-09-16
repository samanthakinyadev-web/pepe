import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:elimupepe/core/theme/app_theme.dart';
import 'package:elimupepe/core/config/app_endpoints.dart';

class ParentMessagesScreen extends StatelessWidget {
  final Map<String, dynamic>? dashboard;

  const ParentMessagesScreen({super.key, this.dashboard});

  Future<void> _openSupportChannel(BuildContext context) async {
    final uri = Uri.parse('${AppEndpoints.webBaseUrl}/parent/messages');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open messages.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final recent = dashboard?['recent_messages'];
    final items = recent is List ? recent : const [];

    return Scaffold(
      backgroundColor: AppColors.surfaceGray,
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (items.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primaryBlue.withValues(alpha: 0.12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline,
                          color: AppColors.primaryBlue),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'No messages yet',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'When teachers or the school reach out, their messages will appear here.',
                    style: TextStyle(
                      color: Colors.blueGrey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          else
            ...items.map((entry) {
              final map = entry is Map<String, dynamic>
                  ? entry
                  : entry is Map
                      ? Map<String, dynamic>.from(entry)
                      : <String, dynamic>{};
              final teacherName =
                  (map['sender'] ?? map['from'] ?? 'Teacher').toString();
              final body = (map['message'] ?? map['text'] ?? '').toString();
              final time = (map['time'] ?? map['created_at'] ?? '').toString();

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primaryBlue.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor:
                          AppColors.primaryBlue.withValues(alpha: 0.12),
                      child: Text(
                        teacherName.isNotEmpty
                            ? teacherName[0].toUpperCase()
                            : 'T',
                        style: const TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  teacherName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (time.isNotEmpty)
                                Text(
                                  time,
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            body,
                            style: TextStyle(
                              color: Colors.blueGrey.shade700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryBlue, AppColors.accentPurple],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Need to reach the school?',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Use the secure parent web portal to send direct messages to teachers or the school office.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => _openSupportChannel(context),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open Web Messages'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}