import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:loho_ebook_reader/theme/app_theme.dart';
import 'package:loho_ebook_reader/models/menu_item.dart';
import 'package:loho_ebook_reader/screens/main_view.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:loho_ebook_reader/screens/home_screen.dart';
import 'package:loho_ebook_reader/screens/menu_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:loho_ebook_reader/screens/parental_gate.dart';
import 'package:loho_ebook_reader/screens/profile_screen.dart';
import 'package:loho_ebook_reader/screens/category_items_screen.dart';
import 'package:loho_ebook_reader/screens/webview_content_screen.dart';
import 'package:loho_ebook_reader/services/learner_dashboard_api_service.dart';

class GamifiedDashboardScreen extends StatefulWidget {
  const GamifiedDashboardScreen({super.key});

  @override
  State<GamifiedDashboardScreen> createState() =>
      _GamifiedDashboardScreenState();
}

class _GamifiedDashboardScreenState extends State<GamifiedDashboardScreen> {
  int _selectedIndex = 0; // 0: Home, 1: Quest, 2: Library, 3: Menu, 4: Profile
  final GlobalKey<ScaffoldState> _homeScaffoldKey = GlobalKey<ScaffoldState>();
  late final MenuItem _elimuQuestMenuItem = MenuItem.getDefaultMenuItems()
      .firstWhere((item) => item.id == 'elimu_quest');
  late final MenuItem _leaderboardMenuItem = MenuItem.getDefaultMenuItems()
      .firstWhere((item) => item.id == 'leaderboard');
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
        _userAvatar =
            prefs.getString('profile_image_url') ??
            prefs.getString('user_avatar');
      });
    }
  }

  Future<void> _onItemTapped(int index) async {
    setState(() {
      _selectedIndex = index;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_dashboard_tab_index', index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          MainView(onNavigate: _onItemTapped), // 0: Home
          HomeScreen(scaffoldKey: _homeScaffoldKey), // 1: Library
          _buildDashboardContent(), // 2: Quest
          const MenuScreen(), // 3: Menu
          const ProfileScreen(), // 4: Profile
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.lightGreen,
        unselectedItemColor: Colors.blueGrey.shade300,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined, size: 28),
            activeIcon: Icon(Icons.home_rounded, size: 28),
            label: 'Home',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.local_library_outlined, size: 28),
            activeIcon: Icon(Icons.local_library_rounded, size: 28),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bolt_outlined, size: 28),
            activeIcon: Icon(Icons.bolt_rounded, size: 28),
            label: 'Quest',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_outlined, size: 28),
            activeIcon: Icon(Icons.menu_rounded, size: 28),
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

  // --- UI COMPONENTS ---

  Widget _buildDashboardContent() {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildQuestCard(),
            const SizedBox(height: 30),
            _buildSupportSection(),
            const SizedBox(height: 20),
            _buildLeaderboardCard(),
          ],
        ).animate().fadeIn(duration: 500.ms),
      ),
    );
  }

  // Rest of your helper methods (Header, QuestCard, SupportSection, Update Logic)...
  // (Assuming they remain the same as your original code)

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                Text(
                  "Let's continue your adventure!",
                  style: TextStyle(fontSize: 14, color: Colors.blue.shade600),
                ),
              ],
            ),
          ),
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.blue.shade100,
            backgroundImage: _userAvatar != null
                ? NetworkImage(_userAvatar!)
                : null,
            child: _userAvatar == null
                ? Text(
                    _userName[0].toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
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
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                CategoryItemsScreen(menuItem: _elimuQuestMenuItem),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.brandGreen, AppColors.lightGreen],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                color: AppColors.accentYellow,
                size: 32,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Elimu Quest: Start Today\'s Mission!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupportSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ListTile(
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Need Support?",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text(
          'Chat with us on WhatsApp for help, feedback, or bug reports.',
          style: TextStyle(color: Colors.blueGrey),
        ),
        trailing: const Icon(Icons.chat_rounded, color: AppColors.accentOrange),
        onTap: _launchWhatsApp,
      ),
    );
  }

  Widget _buildLeaderboardCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: () => _openProtectedIntegration(
          title: _leaderboardMenuItem.title,
          intendedPath: '/leaderboard/embed',
        ),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade400, Colors.orange.shade600],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            children: [
              Icon(Icons.emoji_events_rounded, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Leaderboard: See the Top Learners',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openProtectedIntegration({
    required String title,
    required String intendedPath,
  }) async {
    final targetUrl = 'https://elimupepe.loholearning.co.ke$intendedPath';
    final webviewLoginUrl = await LearnerDashboardApiService.instance
        .fetchWebviewLoginUrl(targetUrl: targetUrl);

    if (!mounted) {
      return;
    }

    final finalUrl = webviewLoginUrl ?? targetUrl;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WebViewContentScreen(title: title, url: finalUrl),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning, $_userName!';
    if (hour < 17) return 'Good afternoon, $_userName!';
    return 'Good evening, $_userName!';
  }

  Future<void> _launchWhatsApp() async {
    final passed = await showParentalGate(context);

    if (passed) {
      final Uri url = Uri.parse('https://wa.me/254797349396');
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        debugPrint('Could not launch WhatsApp');
      }
    }
  }

  Future<void> _checkForUpdates() async {
    bool playStoreUpdateTriggered = false;

    // 1. Try Google Play Store Update First (Only if running on an Android device)
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final updateInfo = await InAppUpdate.checkForUpdate();
        if (updateInfo.updateAvailability ==
            UpdateAvailability.updateAvailable) {
          await InAppUpdate.performImmediateUpdate();
          playStoreUpdateTriggered = true; // Update handled by Play Store
        }
      } catch (e) {
        debugPrint(
          'Play Store update check failed (likely sideloaded APK): $e',
        );
      }
    }

    // 2. Fallback: If no Play Store update was triggered, check custom PHP backend
    if (!playStoreUpdateTriggered) {
      try {
        final packageInfo = await PackageInfo.fromPlatform();
        final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

        final dio = Dio();
        final response = await dio.get(
          'https://elimupepe.loholearning.co.ke/api/v1/app/version',
        );

        if (response.statusCode == 200 && response.data != null) {
          final data = response.data;

          final latestBuildNumber = data['build_number'] as int? ?? 0;
          final downloadUrl = data['download_url'] as String? ?? '';
          final isMandatory = data['mandatory'] as bool? ?? false;
          final releaseNotes =
              data['release_notes'] as String? ??
              'A new version is available with bug fixes and improvements.';

          if (latestBuildNumber > currentBuildNumber &&
              downloadUrl.isNotEmpty) {
            if (mounted) {
              _showUpdateDialog(downloadUrl, releaseNotes, isMandatory);
            }
          }
        }
      } catch (e) {
        debugPrint('Failed to check for custom updates: $e');
      }
    }
  }

  void _showUpdateDialog(
    String downloadUrl,
    String releaseNotes,
    bool isMandatory,
  ) {
    showDialog(
      context: context,
      barrierDismissible:
          !isMandatory, // Prevent closing if it's a forced update
      builder: (context) {
        return PopScope(
          canPop: !isMandatory, // Prevent Android back button if mandatory
          child: AlertDialog(
            title: const Text(
              'Update Available',
              style: TextStyle(color: AppColors.brandGreen),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('A new version of the app is ready to install!'),
                const SizedBox(height: 12),
                Text(
                  releaseNotes,
                  style: const TextStyle(color: Colors.blueGrey),
                ),
              ],
            ),
            actions: [
              if (!isMandatory)
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Later',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.lightGreen,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final uri = Uri.parse(downloadUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: const Text('Download Update'),
              ),
            ],
          ),
        );
      },
    );
  }
}
