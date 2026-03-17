import 'update_profile_screen.dart';
import 'package:flutter/material.dart';
import '../services/user_data_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = 'Loading...';
  String _lohoId = 'LOHO-...';
  String _grade = 'Grade 4';
  String _profileImageUrl = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // 1. Immediately load whatever cached info we have locally
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'Alex Learner';
      _lohoId = prefs.getString('loho_id') ?? 'LOHO-12345';
      _grade = prefs.getString('grade') ?? 'Grade 4';
      _profileImageUrl = prefs.getString('profile_image_url') ?? '';
    });

    // 2. Fetch fresh dynamic data from our API
    final apiData = await UserDataService.instance.fetchUserProfile();
    if (apiData != null && mounted) {
      final userData = apiData['data'] ?? apiData['user'] ?? apiData;

      setState(() {
        // Pick out fields from API. Update 'name' or 'first_name' depending on your JSON structure
        _userName = userData['name'] ?? userData['first_name'] ?? _userName;

        // Fetch Loho ID or fallback to standard ID/student_id
        _lohoId =
            userData['loho_id']?.toString() ??
            userData['student_id']?.toString() ??
            _lohoId;

        // Fetch grade and format it if necessary
        final fetchedGrade = userData['grade'] ?? userData['grade_level'];
        if (fetchedGrade != null) {
          _grade = fetchedGrade.toString().toLowerCase().startsWith('grade')
              ? fetchedGrade.toString()
              : 'Grade $fetchedGrade';
        }

        // Fetch profile image URL
        _profileImageUrl =
            userData['profile_image'] ??
            userData['avatar'] ??
            userData['avatar_url'] ??
            _profileImageUrl;
      });

      // Update local storage so the next immediate load displays the correct fresh data
      await prefs.setString('user_name', _userName);
      await prefs.setString('loho_id', _lohoId);
      await prefs.setString('grade', _grade);
      await prefs.setString('profile_image_url', _profileImageUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF0F8FF),
        title: const Text(
          'My Profile',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D47A1),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Badge(
              label: Text('3'),
              child: Icon(
                Icons.notifications_rounded,
                color: Color(0xFF36a4da),
              ),
            ),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: Color(0xFF36a4da)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UpdateProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Avatar and Name
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFe85021),
                        width: 4,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(
                        _profileImageUrl.isNotEmpty
                            ? _profileImageUrl
                            : 'https://i.pravatar.cc/150?img=12',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D47A1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Loho ID: $_lohoId',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D47A1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$_grade • Explorer',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.blueGrey,
                    ),
                  ),
                ],
              ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
            ),
            const SizedBox(height: 32),

            // Subscription Plan
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF36a4da), Color(0xFF0D47A1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D47A1).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: Colors.amber,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Premium Plan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Active until Dec 2025',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // TODO: Manage subscription
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0D47A1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Manage',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.2),

            const SizedBox(height: 32),

            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard(
                  '2450',
                  'Points',
                  Icons.star_rounded,
                  Colors.amber,
                ),
                _buildStatCard(
                  '12',
                  'Books',
                  Icons.menu_book_rounded,
                  const Color(0xFF36a4da),
                ),
                _buildStatCard(
                  '34',
                  'Quests',
                  Icons.local_fire_department_rounded,
                  const Color(0xFFe85021),
                ),
              ],
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),

            const SizedBox(height: 40),

            // Badges Section
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'My Badges',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D47A1),
                ),
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.8,
              children: [
                _buildBadge(
                  Icons.science_rounded,
                  Colors.green,
                  'Science Whiz',
                ),
                _buildBadge(
                  Icons.calculate_rounded,
                  Colors.lightBlue,
                  'Math Guru',
                ),
                _buildBadge(
                  Icons.auto_stories_rounded,
                  Colors.orange,
                  'Bookworm',
                ),
                _buildBadge(Icons.emoji_events_rounded, Colors.amber, 'Top 10'),
                _buildBadge(Icons.code_rounded, Colors.purple, 'Coder'),
                _buildBadge(
                  Icons.lock_outline_rounded,
                  Colors.grey.shade400,
                  'Locked',
                ),
              ],
            ).animate().fadeIn(delay: 500.ms),

            const SizedBox(height: 40),

            // Messages Section
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Recent Messages',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D47A1),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                _buildMessageCard(
                  'Teacher Sarah',
                  'Great job on your math assignment! Keep it up.',
                  '2h ago',
                  Icons.person_rounded,
                  true, // isUnread
                ),
                const SizedBox(height: 12),
                _buildMessageCard(
                  'System Notification',
                  'New Grade 4 revision books are now available in your library.',
                  '1d ago',
                  Icons.info_rounded,
                  false, // isUnread
                ),
              ],
            ).animate().fadeIn(delay: 700.ms),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.blueGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, Color color, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 40),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMessageCard(
    String sender,
    String message,
    String time,
    IconData icon,
    bool isUnread,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnread
            ? const Color(0xFFe85021).withOpacity(0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnread
              ? const Color(0xFFe85021).withOpacity(0.3)
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isUnread
                ? const Color(0xFFe85021).withOpacity(0.2)
                : const Color(0xFFF0F8FF),
            child: Icon(
              icon,
              color: isUnread
                  ? const Color(0xFFe85021)
                  : const Color(0xFF36a4da),
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
                      sender,
                      style: TextStyle(
                        fontWeight: isUnread
                            ? FontWeight.bold
                            : FontWeight.w600,
                        fontSize: 16,
                        color: const Color(0xFF333333),
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        color: isUnread
                            ? const Color(0xFFe85021)
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
                  message,
                  style: TextStyle(
                    color: Colors.blueGrey.shade700,
                    fontSize: 14,
                    fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
