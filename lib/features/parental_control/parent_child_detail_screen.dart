import 'package:flutter/material.dart';
import 'package:elimupepe/core/theme/app_theme.dart';
import 'package:elimupepe/core/services/parent_api_service.dart';

class ParentChildDetailScreen extends StatefulWidget {
  final ParentLinkedChild child;

  const ParentChildDetailScreen({super.key, required this.child});

  @override
  State<ParentChildDetailScreen> createState() => _ParentChildDetailScreenState();
}

class _ParentChildDetailScreenState extends State<ParentChildDetailScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _overview;
  List<dynamic> _activity = [];
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final api = ParentApiService.instance;
    try {
      final overview = await api.fetchChildOverview(widget.child.id);
      final activity = await api.fetchChildActivity(widget.child.id);
      final notifications = await api.fetchChildNotifications(widget.child.id);

      if (!mounted) return;
      setState(() {
        _overview = overview;
        _activity = activity;
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not load details right now.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.child;
    return Scaffold(
      backgroundColor: AppColors.surfaceGray,
      appBar: AppBar(
        title: Text(child.name),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _load,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.primaryBlue),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primaryBlue,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.orange.shade900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  _profileCard(),
                  const SizedBox(height: 16),
                  _summaryCard(),
                  const SizedBox(height: 16),
                  _section('Recent Activity', _activity, _activityTile),
                  const SizedBox(height: 16),
                  _section('Notifications', _notifications, _notificationTile),
                ],
              ),
            ),
    );
  }

  Widget _profileCard() {
    final child = widget.child;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.accentPurple],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            backgroundImage:
                (child.avatarUrl != null && child.avatarUrl!.isNotEmpty)
                    ? NetworkImage(child.avatarUrl!)
                    : null,
            child: (child.avatarUrl == null || child.avatarUrl!.isEmpty)
                ? Text(
                    child.name.isNotEmpty ? child.name[0].toUpperCase() : 'S',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Student ID: ${child.studentId}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  '${child.grade}${child.className != null ? ' • ${child.className}' : ''}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard() {
    final overview = _overview ?? const {};
    final progress = overview['progress'] ?? overview['completion'] ?? 0;
    final lessons =
        overview['lessons_completed'] ?? overview['lessons_this_week'] ?? 0;
    final points = overview['points'] ?? overview['gamification_points'] ?? 0;
    final streak = overview['streak'] ?? overview['attendance_streak'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progress Snapshot',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (progress is num) ? (progress.clamp(0, 100) / 100) : 0.0,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              color: AppColors.brandGreen,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _miniStat('Lessons', lessons.toString(), Icons.menu_book),
              _miniStat('Points', points.toString(), Icons.star),
              _miniStat('Streak', streak.toString(), Icons.local_fire_department),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primaryBlue),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _section(
    String title,
    List<dynamic> items,
    Widget Function(dynamic) tileBuilder,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(
              'No ${title.toLowerCase()} yet.',
              style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 13),
            )
          else
            ...items.take(6).map(tileBuilder),
        ],
      ),
    );
  }

  Widget _activityTile(dynamic entry) {
    final map = entry is Map<String, dynamic>
        ? entry
        : entry is Map
            ? Map<String, dynamic>.from(entry)
            : <String, dynamic>{};
    final title = (map['title'] ?? map['name'] ?? map['activity'] ?? 'Activity')
        .toString();
    final subtitle =
        (map['description'] ?? map['message'] ?? '').toString();
    final time = (map['time'] ?? map['created_at'] ?? '').toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bolt, color: AppColors.primaryBlue, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
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
                if (subtitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.blueGrey.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _notificationTile(dynamic entry) {
    final map = entry is Map<String, dynamic>
        ? entry
        : entry is Map
            ? Map<String, dynamic>.from(entry)
            : <String, dynamic>{};
    final title =
        (map['title'] ?? map['subject'] ?? 'Notification').toString();
    final message = (map['message'] ?? map['body'] ?? '').toString();
    final time = (map['time'] ?? map['created_at'] ?? '').toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.notifications_active,
              color: AppColors.primaryBlue, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
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
                if (message.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      message,
                      style: TextStyle(
                        color: Colors.blueGrey.shade700,
                        fontSize: 12,
                      ),
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