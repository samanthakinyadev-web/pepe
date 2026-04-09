import 'package:flutter/material.dart';
import 'package:elimupepe/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:elimupepe/features/quiz/learner_dashboard_api_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    try {
      final data = await LearnerDashboardApiService.instance.fetchLeaderboard();
      if (mounted) {
        setState(() {
          final normalized = data
              .whereType<Map<String, dynamic>>()
              .map(_normalizeLeaderboardUser)
              .toList();
          if (normalized.isNotEmpty) {
            _users = normalized;
          } else {
            _loadDummyData();
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadDummyData();
          _isLoading = false;
        });
      }
    }
  }

  void _loadDummyData() {
    _users = [
      {
        'name': 'Alex (You)',
        'points': 2450,
        'avatar': 'https://i.pravatar.cc/150?img=12',
      },
      {
        'name': 'Sarah',
        'points': 2100,
        'avatar': 'https://i.pravatar.cc/150?img=5',
      },
      {
        'name': 'John',
        'points': 1850,
        'avatar': 'https://i.pravatar.cc/150?img=8',
      },
      {
        'name': 'Emma',
        'points': 1600,
        'avatar': 'https://i.pravatar.cc/150?img=1',
      },
      {
        'name': 'Michael',
        'points': 1420,
        'avatar': 'https://i.pravatar.cc/150?img=11',
      },
      {
        'name': 'Lisa',
        'points': 1200,
        'avatar': 'https://i.pravatar.cc/150?img=9',
      },
    ];
  }

  Map<String, dynamic> _normalizeLeaderboardUser(Map<String, dynamic> user) {
    final firstName = user['first_name']?.toString().trim();
    final lastName = user['last_name']?.toString().trim();
    final fullName = [
      firstName,
      lastName,
    ].whereType<String>().where((part) => part.isNotEmpty).join(' ');

    return {
      ...user,
      'name':
          user['name']?.toString() ??
          user['username']?.toString() ??
          (fullName.isNotEmpty ? fullName : 'Student'),
      'points': user['points'] ?? user['score'] ?? user['coins'] ?? 0,
      'avatar':
          user['avatar'] ??
          user['avatar_url'] ??
          user['profile_photo'] ??
          user['profile_photo_url'],
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF0F8FF),
        title: const Text(
          'Top Scholars',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.brandGreen,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.lightGreen),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                final isTop3 = index < 3;

                Color cardColor = Colors.white;
                Color rankColor = AppColors.lightGreen;

                if (index == 0) {
                  rankColor = Colors.amber.shade400; // Gold
                  cardColor = Colors.amber.shade50;
                } else if (index == 1) {
                  rankColor = Colors.blueGrey.shade300; // Silver
                  cardColor = Colors.blueGrey.shade50;
                } else if (index == 2) {
                  rankColor = const Color(0xFFCD7F32); // Bronze
                  cardColor = const Color(0xFFCD7F32).withValues(alpha: 0.1);
                }

                return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: isTop3
                            ? Border.all(
                                color: rankColor.withValues(alpha: 0.5),
                                width: 2,
                              )
                            : null,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '#${index + 1}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: rankColor,
                              ),
                            ),
                            const SizedBox(width: 16),
                            CircleAvatar(
                              radius: 24,
                              backgroundImage: NetworkImage(
                                user['avatar']?.toString() ??
                                    'https://i.pravatar.cc/150?u=${index + 1}',
                              ),
                            ),
                          ],
                        ),
                        title: Text(
                          user['name']?.toString() ??
                              user['username']?.toString() ??
                              'Student',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              user['points']?.toString() ??
                                  user['score']?.toString() ??
                                  '0',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.lightGreen,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(delay: (100 * index).ms)
                    .slideX(begin: 0.2, curve: Curves.easeOut);
              },
            ),
    );
  }
}
