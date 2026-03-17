import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:loho_ebook_reader/models/menu_item.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:loho_ebook_reader/screens/home_screen.dart';
import 'package:loho_ebook_reader/screens/menu_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:loho_ebook_reader/screens/profile_screen.dart';
import 'package:loho_ebook_reader/services/php_api_service.dart';
import 'package:loho_ebook_reader/screens/category_items_screen.dart';

class GamifiedDashboardScreen extends StatefulWidget {
  const GamifiedDashboardScreen({super.key});

  @override
  State<GamifiedDashboardScreen> createState() =>
      _GamifiedDashboardScreenState();
}

class _GamifiedDashboardScreenState extends State<GamifiedDashboardScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _homeScaffoldKey = GlobalKey<ScaffoldState>();
  late final MenuItem _elimuQuestMenuItem = MenuItem.getDefaultMenuItems()
      .firstWhere((item) => item.id == 'elimu_quest');
  String _userName = 'Learner';
  String? _userAvatar;

  @override
  void initState() {
    super.initState();
    _loadLastSessionState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
    });
  }

  Future<void> _loadLastSessionState() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _selectedIndex = prefs.getInt('last_dashboard_tab_index') ?? 0;
        _userName = prefs.getString('user_name') ?? 'Learner';
        _userAvatar = prefs.getString('user_avatar');
      });
    }
  }

  Future<void> _onItemTapped(int index) async {
    setState(() {
      _selectedIndex = index;
    });

    // Store the session state to continue where the user left off
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_dashboard_tab_index', index);
  }

  // We wrap the original dashboard design in a helper method so it
  // can be used as the first screen in our IndexedStack.
  Widget _buildDashboardContent() {
    return SafeArea(
      child: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildQuestCard(),
                      const SizedBox(height: 30),
                      _buildSupportSection(),
                      const SizedBox(height: 80), // Padding for mascot
                    ],
                  ).animate().fadeIn(duration: 500.ms),
                ),
              );
            },
          ),
          // Positioned(
          //   bottom: 16,
          //   right: 16,
          //   child: Lottie.asset(
          //     'assets/animations/mascot.json',
          //     width: 120,
          //     height: 120,
          //   ),
          // ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF), // A light, airy background
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboardContent(), // 0: Elimu Quest Dashboard
          HomeScreen(scaffoldKey: _homeScaffoldKey), // 1: The original Library
          const MenuScreen(), // 2: Menu
          const ProfileScreen(), // 3: The New Profile/Badges Screen
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Future<void> _launchWhatsApp() async {
    final Uri url = Uri.parse('https://wa.me/254797349396');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch WhatsApp');
    }
  }

  Future<void> _checkForUpdates() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.version;

      final versionData = await PhpApiService.instance.getLatestAppVersion();
      final String latestVersion =
          versionData['version']?.toString() ?? currentVersion;
      final String updateUrl =
          versionData['url']?.toString() ??
          "https://loholearning.co.ke/app-release.apk";
      final String rawReleaseNotes =
          versionData['release_notes']?.toString() ?? '';
      final bool isMandatory = versionData['force_update'] == true;
      final String releaseNotes = rawReleaseNotes.isNotEmpty
          ? rawReleaseNotes
          : 'A critical new version of the app is available. Please update to continue learning.';

      if (latestVersion != currentVersion) {
        if (!mounted) return;
        _showUpdateDialog(updateUrl, releaseNotes, isMandatory);
      }
    } catch (e) {
      debugPrint('Failed to check for updates: $e');
    }
  }

  void _showUpdateDialog(
    String updateUrl,
    String releaseNotes,
    bool isMandatory,
  ) {
    showDialog(
      context: context,
      barrierDismissible: !isMandatory,
      builder: (context) => PopScope(
        canPop: !isMandatory, // Prevents closing via the Android back button
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            isMandatory ? 'Update Required! 🚀' : 'Update Available! 🚀',
            style: const TextStyle(
              color: Color(0xFF0D47A1),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: MarkdownBody(
                data: releaseNotes,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                  h1: const TextStyle(
                    color: Color(0xFF0D47A1),
                    fontWeight: FontWeight.bold,
                  ),
                  h2: const TextStyle(
                    color: Color(0xFF0D47A1),
                    fontWeight: FontWeight.bold,
                  ),
                  listBullet: const TextStyle(
                    color: Color(0xFFe85021),
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          actions: [
            if (!isMandatory)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Later',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFe85021),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              onPressed: () async {
                if (!isMandatory) {
                  Navigator.pop(context);
                }
                final Uri url = Uri.parse(updateUrl);
                if (!await launchUrl(
                  url,
                  mode: LaunchMode.externalApplication,
                )) {
                  debugPrint('Could not launch update URL');
                }
              },
              child: const Text(
                'Update Now',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning, $_userName!';
    } else if (hour < 17) {
      return 'Good afternoon, $_userName!';
    } else {
      return 'Good evening, $_userName!';
    }
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: Colors.blue.shade800,
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Let's continue your adventure!",
                  style: TextStyle(fontSize: 16, color: Colors.blue.shade600),
                ),
              ],
            ),
          ),
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.blue.shade100,
            backgroundImage: _userAvatar != null && _userAvatar!.isNotEmpty
                ? NetworkImage(_userAvatar!)
                : null,
            child: _userAvatar == null || _userAvatar!.isEmpty
                ? Text(
                    _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildQuestCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child:
          GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CategoryItemsScreen(menuItem: _elimuQuestMenuItem),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFFA726),
                        const Color(0xFFFF7043),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Elimu Quest',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Complete 3 science lessons to earn a badge!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              )
              .animate()
              .slideX(begin: 0.5, duration: 600.ms, curve: Curves.easeOutCubic)
              .shimmer(delay: 1000.ms, duration: 1800.ms),
    );
  }

  Widget _buildSupportSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Need Support?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D47A1),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.support_agent_rounded),
                color: Colors.green.shade600,
                onPressed: _launchWhatsApp,
                tooltip: 'Get Support',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFe85021),
        unselectedItemColor: Colors.blueGrey.shade400,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 12,
        ),
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.flag_outlined, size: 28),
            activeIcon: Icon(Icons.flag_rounded, size: 28),
            label: 'Quest',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_library_outlined, size: 28),
            activeIcon: Icon(Icons.local_library_rounded, size: 28),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events_outlined, size: 28),
            activeIcon: Icon(Icons.emoji_events_rounded, size: 28),
            label: 'Menu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded, size: 28),
            activeIcon: Icon(Icons.person_rounded, size: 28),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
