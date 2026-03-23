import 'package:flutter/material.dart';
import 'package:loho_ebook_reader/theme/app_theme.dart';
import '../services/php_api_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
      final data = await PhpApiService.instance.getLeaderboard();
      if (mounted) {
        setState(() {
          if (data.isNotEmpty) {
            _users = data;
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
          ? const Center(child: CircularProgressIndicator(color: AppColors.lightGreen))
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
            cardColor = const Color(0xFFCD7F32).withOpacity(0.1);
          }

          return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: isTop3
                      ? Border.all(color: rankColor.withOpacity(0.5), width: 2)
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
                            user['avatar']?.toString() ?? 'https://i.pravatar.cc/150?u=${index + 1}'),
                      ),
                    ],
                  ),
                  title: Text(
                    user['name']?.toString() ?? user['username']?.toString() ?? 'Student',
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
                        user['points']?.toString() ?? user['score']?.toString() ?? '0',
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
