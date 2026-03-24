import 'login_screen.dart';
import 'about_screen.dart';
import 'parental_gate.dart';
import 'notifications_screen.dart';
import 'update_profile_screen.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/user_data_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:loho_ebook_reader/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = 'Loading...';
  String _lohoId = 'LOHO-...';
  String _grade = 'Grade ...';
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
      _grade = prefs.getString('grade') ?? 'Grade ...';
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
        final fetchedGrade = _extractGrade(userData);
        if (fetchedGrade != null && fetchedGrade.isNotEmpty) {
          _grade = fetchedGrade;
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

  String? _extractGrade(Map<String, dynamic> userData) {
    final direct = _readGradeField(userData);
    if (direct != null) return direct;

    final possibleNestedKeys = [
      'student',
      'learner',
      'profile',
      'child',
      'user',
      'data',
    ];

    for (final key in possibleNestedKeys) {
      final nested = userData[key];
      if (nested is Map<String, dynamic>) {
        final nestedGrade = _readGradeField(nested);
        if (nestedGrade != null) return nestedGrade;
      }
    }

    return null;
  }

  String? _readGradeField(Map<String, dynamic> data) {
    final raw =
        data['grade'] ??
        data['grade_level'] ??
        data['gradeLevel'] ??
        data['class'] ??
        data['class_name'] ??
        data['level'] ??
        data['course'] ??
        data['current_grade'] ??
        data['current_grade_level'];

    if (raw == null) return null;
    final text = raw.toString().trim();
    if (text.isEmpty) return null;

    return text.toLowerCase().startsWith('grade') ? text : 'Grade $text';
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lightGreen,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true && context.mounted) {
      // 1. Clear tokens securely
      await AuthService.instance.logout();

      // 2. Clear locally cached profile information
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (!context.mounted) return;
      // 3. Navigate back to login
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
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
            color: AppColors.brandGreen,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Badge(
              label: Text('3'),
              child: Icon(
                Icons.notifications_rounded,
                color: AppColors.lightGreen,
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.settings_rounded,
              color: AppColors.lightGreen,
            ),
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
                      border: Border.all(color: AppColors.lightGreen, width: 4),
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
                      color: AppColors.brandGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Loho ID: $_lohoId',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.brandGreen,
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
                  colors: [AppColors.lightGreen, AppColors.brandGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brandGreen.withOpacity(0.3),
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
                      color: AppColors.accentYellow,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ' Plan',
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
                    onPressed: () async {
                      final passed = await showParentalGate(context);

                      if (passed && context.mounted) {
                        // TODO: Manage subscription
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Parental gate passed. Open subscription manager here.',
                            ),
                          ),
                        );
                      }
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.brandGreen,
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
                  AppColors.accentYellow,
                ),
                _buildStatCard(
                  '12',
                  'Books',
                  Icons.menu_book_rounded,
                  AppColors.lightGreen,
                ),
                _buildStatCard(
                  '34',
                  'Quests',
                  Icons.local_fire_department_rounded,
                  AppColors.lightGreen,
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
                  color: AppColors.brandGreen,
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
                  AppColors.accentOrange,
                  'Bookworm',
                ),
                _buildBadge(
                  Icons.emoji_events_rounded,
                  AppColors.accentYellow,
                  'Top 10',
                ),
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
                  color: AppColors.brandGreen,
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
                  'New Grade 4 coderevision books are now available in your library.',
                  '1d ago',
                  Icons.info_rounded,
                  false, // isUnread
                ),
              ],
            ).animate().fadeIn(delay: 700.ms),
            const SizedBox(height: 32),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _confirmLogout(context),
                icon: const Icon(Icons.logout_rounded),
                label: const Text(
                  'Logout',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.lightGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(
                      color: AppColors.lightGreen,
                      width: 2,
                    ),
                  ),
                  elevation: 0,
                ),
              ),
            ).animate().fadeIn(delay: 800.ms),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(
                Icons.info_outline_rounded,
                color: Colors.blueGrey,
              ),
              title: const Text('About this App'),
              trailing: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.blueGrey,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutScreen()),
                );
              },
            ),
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

  Widget _buildBadge(IconData icon, Color color, [String? label]) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(label == 'Locked' ? 0.05 : 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 40),
        ),
        if (label != null) ...[
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: label == 'Locked' ? Colors.grey.shade500 : Colors.blueGrey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
        color: isUnread ? AppColors.lightGreen.withOpacity(0.05) : Colors.white,
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
              icon,
              color: isUnread ? AppColors.lightGreen : AppColors.lightGreen,
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
