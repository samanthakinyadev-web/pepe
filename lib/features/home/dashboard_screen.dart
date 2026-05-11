import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:elimupepe/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:elimupepe/core/widgets/elimu_card.dart';
import 'package:elimupepe/core/config/app_endpoints.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:elimupepe/features/home/main_view.dart';
import 'package:elimupepe/features/home/home_screen.dart';
import 'package:elimupepe/features/home/menu_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:elimupepe/core/utils/image_url_resolver.dart';
import 'package:elimupepe/features/profile/profile_screen.dart';
import 'package:elimupepe/features/parental_control/parental_gate.dart';
import 'package:elimupepe/features/settings/webview_content_screen.dart';
import 'package:elimupepe/features/quiz/learner_dashboard_api_service.dart';
import 'package:elimupepe/core/utils/error_feedback.dart';

class GamifiedDashboardScreen extends StatefulWidget {
  const GamifiedDashboardScreen({
    super.key,
    this.initialIndex = 0,
    this.restoreLastTab = true,
  });

  final int initialIndex;
  final bool restoreLastTab;

  @override
  State<GamifiedDashboardScreen> createState() =>
      _GamifiedDashboardScreenState();
}

class _GamifiedDashboardScreenState extends State<GamifiedDashboardScreen> {
  static const String _avatarCacheKeyPref = 'profile_image_cache_key';
  int _selectedIndex = 0; // 0: Home, 1: Library, 2: Quest, 3: Menu, 4: Profile
  final GlobalKey<ScaffoldState> _homeScaffoldKey = GlobalKey<ScaffoldState>();
  final List<Widget?> _tabCache = List<Widget?>.filled(5, null);
  String _userName = 'Learner';
  String? _userAvatar;
  bool _isOpeningStudentDashboard = false;
  bool _questLoading = true;
  int _coins = 0;
  int _streakDays = 0;
  int _badgeCount = 0;
  int _leaderboardRank = 0;
  int _questCount = 0;

  @override
  void initState() {
    super.initState();
    _loadLastSessionState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
      _loadQuestData();
    });
  }

  Future<void> _loadLastSessionState() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _selectedIndex = widget.restoreLastTab
            ? prefs.getInt('last_dashboard_tab_index') ?? widget.initialIndex
            : widget.initialIndex;
        _userName = prefs.getString('user_name') ?? 'Learner';
        _userAvatar = ImageUrlResolver.withCacheBuster(
          prefs.getString('profile_image_url') ??
              prefs.getString('user_avatar'),
          cacheKey: prefs.getString(_avatarCacheKeyPref),
        );
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

  Future<void> _openProtectedWebView({
    required String title,
    required String intendedPath,
  }) async {
    if (_isOpeningStudentDashboard) {
      return;
    }
    setState(() {
      _isOpeningStudentDashboard = true;
    });
    try {
      final targetUrl = '${AppEndpoints.webBaseUrl}$intendedPath';
      final webviewLoginUrl = await LearnerDashboardApiService.instance
          .fetchWebviewLoginUrl(targetUrl: targetUrl);

      if (!mounted) {
        return;
      }

      if (webviewLoginUrl == null) {
        await ErrorFeedback.showErrorDialog(
          context,
          title: 'Secure access unavailable',
          error: 'Please check your network connection and try again.',
          fallback: 'Could not open this area securely. Please try again.',
        );
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              WebViewContentScreen(title: title, url: webviewLoginUrl),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isOpeningStudentDashboard = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = List<Widget>.generate(5, (index) {
      final cached = _tabCache[index];
      if (cached != null) {
        return cached;
      }

      if (index != _selectedIndex) {
        return const SizedBox.shrink();
      }

      final tab = _buildTab(index);
      _tabCache[index] = tab;
      return tab;
    });

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF0F8FF),
          body: IndexedStack(index: _selectedIndex, children: tabs),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.accentCoral,
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
        ),
        if (_isOpeningStudentDashboard)
          Container(
            color: Colors.black.withValues(alpha: 0.5),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.lightGreen),
            ),
          ),
      ],
    );
  }

  Widget _buildTab(int index) {
    switch (index) {
      case 0:
        return MainView(onNavigate: _onItemTapped);
      case 1:
        return HomeScreen(scaffoldKey: _homeScaffoldKey);
      case 2:
        return _buildDashboardContent();
      case 3:
        return const MenuScreen();
      case 4:
        return const ProfileScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  // --- UI COMPONENTS ---

  Widget _buildDashboardContent() {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadQuestData,
        color: AppColors.brandGreen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildQuestSummary(),
              const SizedBox(height: 20),
              _buildQuestCard(),
              const SizedBox(height: 30),
              _buildSupportSection(),
              const SizedBox(height: 20),
              _buildLeaderboardCard(),
              const SizedBox(height: 80),
            ],
          ).animate().fadeIn(duration: 500.ms),
        ),
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
      child: ElimuCard(
        onTap: () => _openProtectedWebView(
          title: 'Elimu Quest',
          intendedPath: '/my-quizzes',
        ),
        backgroundColor: AppColors.brandGreen,
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(
              Icons.local_fire_department_rounded,
              color: AppColors.accentYellow,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Elimu Quest',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _questCount > 0
                        ? 'You have $_questCount quiz challenges ready.'
                        : 'Start today\'s mission and earn LohoCoins!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestSummary() {
    if (_questLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: SizedBox(
          height: 130,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.lightGreen),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildQuestStatTile(
                  label: 'Coins',
                  value: _coins.toString(),
                  icon: Icons.monetization_on_rounded,
                  color: AppColors.accentYellow,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuestStatTile(
                  label: 'Streak',
                  value: '$_streakDays d',
                  icon: Icons.local_fire_department_rounded,
                  color: AppColors.accentOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuestStatTile(
                  label: 'Badges',
                  value: _badgeCount.toString(),
                  icon: Icons.workspace_premium_rounded,
                  color: AppColors.lightGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuestStatTile(
                  label: 'Rank',
                  value: _leaderboardRank > 0 ? '#$_leaderboardRank' : '-',
                  icon: Icons.emoji_events_rounded,
                  color: Colors.orange.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestStatTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return ElimuCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textMain,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(color: Colors.blueGrey, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
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
      child: ElimuCard(
        onTap: () => _openProtectedWebView(
          title: 'Leaderboard',
          intendedPath: '/leaderboard/embed',
        ),
        backgroundColor: Colors.orange.shade500,
        padding: const EdgeInsets.all(18),
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
    );
  }

  Future<void> _loadQuestData() async {
    if (mounted) {
      setState(() {
        _questLoading = true;
      });
    }

    try {
      final results = await Future.wait<dynamic>([
        LearnerDashboardApiService.instance.fetchGamificationDashboard(),
        LearnerDashboardApiService.instance.fetchWallet(),
        LearnerDashboardApiService.instance.fetchStreaks(),
        LearnerDashboardApiService.instance.fetchBadges(),
        LearnerDashboardApiService.instance.fetchLeaderboard(),
        LearnerDashboardApiService.instance.fetchQuizzes(),
      ]);

      final dashboard = results[0] as Map<String, dynamic>?;
      final wallet = results[1] as Map<String, dynamic>?;
      final streaks = results[2] as Map<String, dynamic>?;
      final badges = results[3] as List<dynamic>;
      final leaderboard = results[4] as List<dynamic>;
      final quizzes = results[5] as List<dynamic>;

      final coins = _firstInt([
        wallet?['balance'],
        wallet?['coins'],
        wallet?['loho_coins'],
        dashboard?['coins'],
        dashboard?['wallet_balance'],
      ]);
      final streak = _firstInt([
        streaks?['current_streak'],
        streaks?['streak'],
        streaks?['days'],
        dashboard?['streak'],
      ]);
      final rank = _firstInt([
        dashboard?['rank'],
        dashboard?['leaderboard_rank'],
      ]);

      if (mounted) {
        setState(() {
          _coins = coins;
          _streakDays = streak;
          _badgeCount = badges.length;
          _leaderboardRank = rank > 0
              ? rank
              : _inferLeaderboardRank(leaderboard);
          _questCount = quizzes.length;
          _questLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _questLoading = false;
        });
      }
    }
  }

  int _firstInt(List<dynamic> values) {
    for (final value in values) {
      if (value is int) return value;
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;
      }
      if (value is double) return value.round();
    }
    return 0;
  }

  int _inferLeaderboardRank(List<dynamic> leaderboard) {
    final normalizedName = _userName.trim().toLowerCase();
    for (var i = 0; i < leaderboard.length; i++) {
      final item = leaderboard[i];
      if (item is! Map<String, dynamic>) continue;
      final name =
          [
            item['name']?.toString(),
            item['username']?.toString(),
            [item['first_name']?.toString(), item['last_name']?.toString()]
                .whereType<String>()
                .where((part) => part.trim().isNotEmpty)
                .join(' '),
          ].whereType<String>().firstWhere(
            (candidate) => candidate.trim().isNotEmpty,
            orElse: () => '',
          );
      if (name.trim().toLowerCase() == normalizedName) {
        return i + 1;
      }
    }
    return 0;
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
    // Only perform this check if NOT on Android or if the app was NOT installed from the Play Store
    bool shouldCheckCustom = !playStoreUpdateTriggered;
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final packageInfo = await PackageInfo.fromPlatform();
        final installer = packageInfo.installerStore;
        if (installer != null &&
            (installer.contains('vending') || installer.contains('google'))) {
          shouldCheckCustom = false;
          debugPrint(
            'App installed via Play Store. Skipping custom update check.',
          );
        }
      } catch (e) {
        debugPrint('Could not determine installer store: $e');
      }
    }

    if (shouldCheckCustom) {
      try {
        final packageInfo = await PackageInfo.fromPlatform();
        final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

        final dio = Dio();
        final response = await dio.get(
          '${AppEndpoints.apiBaseUrl}/v1/app/version',
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
              downloadUrl.isNotEmpty &&
              _isValidUpdateUrl(downloadUrl)) {
            if (mounted) {
              _showUpdateDialog(downloadUrl, releaseNotes, isMandatory);
            }
          } else if (latestBuildNumber > currentBuildNumber) {
            debugPrint(
              'Update available but download URL is invalid or insecure: $downloadUrl',
            );
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
                  if (!mounted) return;
                  final messenger = ScaffoldMessenger.of(context);
                  final passed = await showParentalGate(context);
                  if (!mounted) return;
                  if (!passed) return;

                  final uri = Uri.tryParse(downloadUrl);
                  if (uri == null || !_isValidUpdateUrl(downloadUrl)) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Update URL is invalid or untrusted.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

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

  bool _isValidUpdateUrl(String url) {
    return AppEndpoints.isTrustedUpdateUrl(url);
  }
}
