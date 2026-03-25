import 'dart:typed_data';
import '../models/ebook.dart';
import 'package:dio/dio.dart';
import '../models/menu_item.dart';
import 'package:flutter/material.dart';
import '../screens/reader_screen.dart';
import '../screens/settings_screen.dart';
import '../services/storage_service.dart';
import '../services/php_api_service.dart';
import '../services/database_service.dart';
import '../services/thumbnail_service.dart';
import '../services/user_data_service.dart';
import '../screens/category_items_screen.dart';
import '../screens/webview_content_screen.dart';
import '../services/cloud_sync_service_php.dart';
import '../screens/components/category_nav_bar.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:loho_ebook_reader/theme/app_theme.dart';
import '../services/learner_dashboard_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:loho_ebook_reader/screens/dashboard_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.scaffoldKey});

  final GlobalKey<ScaffoldState>? scaffoldKey;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService.instance;
  final StorageService _storageService = StorageService.instance;
  final PhpApiService _apiService = PhpApiService.instance;
  final CloudSyncServicePhp _cloudSyncService = CloudSyncServicePhp.instance;

  late final GlobalKey<ScaffoldState> _scaffoldKey;
  late AnimationController _drawerController;

  late Future<List<Ebook>> _ebooksFuture;
  late Future<List<Ebook>> _cloudBooksFuture;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCourse;
  String? _learnerGrade;
  List<String> _studentCourses = [
    'PP1',
    'PP2',
    'Grade 1',
    'Grade 2',
    'Grade 3',
    'Grade 4',
    'Grade 5',
    'Grade 6',
    'Grade 7',
    'Grade 8',
    'Grade 9',
    'Grade 10',
    'Grade 11',
    'Grade 12',
  ];
  String? _selectedPublisher;
  final bool _showFilters = false;
  // Use ValueNotifier for each download to avoid full page rebuilds
  final Map<String, ValueNotifier<double>> _downloadProgress =
      {}; // Track download progress per book ID

  // Publishers list
  final List<String> _publishers = [
    'Longhorn Publishers',
    'KLB',
    'Moran Publishers',
    'EAEP',
  ];

  @override
  void initState() {
    super.initState();
    _scaffoldKey = widget.scaffoldKey ?? GlobalKey<ScaffoldState>();
    _drawerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _syncAndLoadBooks();
    _loadLearnerGrade();
    _loadStudentCourses();

    // Check for daily reward after the first frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDailyReward();
    });
  }

  @override
  void dispose() {
    _drawerController.dispose();
    // Clean up ValueNotifiers to prevent memory leaks
    for (var notifier in _downloadProgress.values) {
      notifier.dispose();
    }
    _searchController.dispose();
    super.dispose();
  }

  void _toggleDrawer() {
    if (_drawerController.isDismissed) {
      _drawerController.forward();
    } else {
      _drawerController.reverse();
    }
  }

  Future<void> _checkDailyReward() async {
    final prefs = await SharedPreferences.getInstance();
    final lastRewardDateStr = prefs.getString('last_reward_date');

    // Get today's date formatted as YYYY-MM-DD
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    if (lastRewardDateStr != todayStr) {
      // It's a new day! Show the reward dialog
      if (mounted) {
        _showDailyRewardDialog();
      }

      // Save today's date so it doesn't show again today
      await prefs.setString('last_reward_date', todayStr);

      // TODO: Add actual reward logic here (e.g., add points/coins to user's profile in database)
    }
  }

  void _showDailyRewardDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Force them to interact to claim
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: const Text(
          '🌟 Daily Reward! 🌟',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.lightGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
                  Icons.star_rounded,
                  color: AppColors.accentYellow,
                  size: 80,
                )
                .animate(onPlay: (controller) => controller.repeat())
                .shimmer(duration: 1200.ms, color: Colors.white)
                .shake(hz: 4, curve: Curves.easeInOut),
            const SizedBox(height: 16),
            const Text(
              'Welcome back! to Elimu Pepe !',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lightGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'CLAIM REWARD',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
    );
  }

  Future<void> _syncAndLoadBooks() async {
    // Remove bundled books first (offline-safe)
    await _cloudSyncService.removeBundledBooks();
    // Load local books first (always available, offline or online)
    _loadEbooks();
    _loadCloudBooks();

    // Try to sync with Firebase if connected (non-blocking)
    try {
      await _cloudSyncService.syncDownloadedBookMetadata();
    } catch (e) {
      print('Cannot sync metadata (offline or error): $e');
      // Continue anyway - user can still read offline books
    }
  }

  Future<void> _refreshLibrary() async {
    await _loadLearnerGrade();
    await _loadStudentCourses();
    await _syncAndLoadBooks();
  }

  void _loadEbooks() {
    setState(() {
      _ebooksFuture = _databaseService.getAllEbooks();
    });
  }

  void _loadCloudBooks() {
    setState(() {
      _cloudBooksFuture = _fetchLearnerTextbooks();
    });
  }

  Future<List<Ebook>> _fetchLearnerTextbooks() async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');

      List<Ebook> cloudBooks = [];

      if (token != null) {
        final dio = Dio();
        final response = await dio.get(
          'https://elimupepe.loholearning.co.ke/api/student/books',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );

        if (response.statusCode == 200) {
          final data = response.data['data'] ?? response.data;
          if (data is List) {
            cloudBooks = data.map((json) {
              return Ebook(
                id: json['id']?.toString() ?? '',
                title: json['title'] ?? '',
                author: json['author'] ?? json['publisher'] ?? 'Unknown Author',
                serverUrl:
                    json['pdf_url'] ?? json['file_url'] ?? json['url'] ?? '',
                fileSize: json['file_size'] is int
                    ? json['file_size']
                    : int.tryParse(json['file_size']?.toString() ?? '0') ?? 0,
                downloadedDate: null,
                grade:
                    json['grade']?.toString() ??
                    json['course']?.toString() ??
                    '',
                category: json['category'] ?? 'Textbooks',
                coverImagePath: json['cover_url'] ?? json['thumbnail_url'],
                totalPages: json['pages'] ?? json['total_pages'] ?? 0,
                isDownloaded: false,
              );
            }).toList();
          }
        }
      }

      if (cloudBooks.isEmpty) {
        cloudBooks = await _apiService.getBooksByCategory('Textbooks');
      }

      final localBooks = await _databaseService.getAllEbooks();
      final localBookIds = localBooks.map((b) => b.id).toSet();
      return cloudBooks
          .where((book) => !localBookIds.contains(book.id))
          .toList();
    } catch (e) {
      debugPrint('Error fetching learner textbooks: $e');
      return _apiService.getBooksByCategory('Textbooks');
    }
  }

  Future<void> _loadStudentCourses() async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      if (token == null) {
        _setFallbackCourses();
        return;
      }

      final dio = Dio();
      final response = await dio.get(
        'https://elimupepe.loholearning.co.ke/api/student/courses',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        if (data is List) {
          if (mounted) {
            setState(() {
              _studentCourses = data
                  .map(
                    (c) =>
                        c['name']?.toString() ??
                        c['title']?.toString() ??
                        'Unknown',
                  )
                  .where((c) => c != 'Unknown')
                  .toList();

              if (_learnerGrade != null &&
                  _learnerGrade!.isNotEmpty &&
                  !_studentCourses.contains(_learnerGrade)) {
                _studentCourses.insert(0, _learnerGrade!);
              }

              // Automatically filter by the learner's current grade from profile
              if (_selectedCourse == null) {
                if (_learnerGrade != null && _learnerGrade!.isNotEmpty) {
                  _selectedCourse = _learnerGrade;
                } else if (_studentCourses.isNotEmpty) {
                  _selectedCourse = _studentCourses.first;
                }
              }

              // Add bundled offline books to the database specifically for the learner's grade
              final targetGrade = _learnerGrade ?? _selectedCourse;
              if (targetGrade != null && targetGrade.isNotEmpty) {
                _storageService
                    .copyBundledEbooksToStorage(
                      _databaseService,
                      targetGrade: targetGrade,
                    )
                    .then((_) {
                      if (mounted) {
                        _loadEbooks(); // Refresh the database list in the UI
                      }
                    });
              }
            });
          }
          return;
        }
      }
      _setFallbackCourses();
    } catch (e) {
      debugPrint('Error fetching courses dynamically: $e');
      _setFallbackCourses();
    }
  }

  void _setFallbackCourses() {
    // Keeps the fallback grades if API fails so the UI doesn't break
    // Handled inherently by the initial values, but we can call it to refresh
    // if loading states are added later.
  }

  Future<void> _loadLearnerGrade() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('grade');
    if (cached != null &&
        cached.isNotEmpty &&
        cached.toLowerCase() != 'grade ...') {
      if (mounted) {
        setState(() {
          _learnerGrade = cached;
          _selectedCourse = cached;
        });
      } else {
        _learnerGrade = cached;
        _selectedCourse = cached;
      }
    }

    final apiData = await UserDataService.instance.fetchUserProfile();
    if (apiData == null) return;
    final userData = apiData['data'] ?? apiData['user'] ?? apiData;
    if (userData is! Map<String, dynamic>) return;

    final fetched = _extractGradeFromProfile(userData);
    if (fetched == null || fetched.isEmpty) return;

    if (mounted) {
      setState(() {
        _learnerGrade = fetched;
        _selectedCourse = fetched;
      });
    } else {
      _learnerGrade = fetched;
      _selectedCourse = fetched;
    }
    await prefs.setString('grade', fetched);
  }

  String? _extractGradeFromProfile(Map<String, dynamic> userData) {
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

  String _normalizeGrade(String grade) {
    final trimmed = grade.trim();
    if (trimmed.toUpperCase().startsWith('PP')) {
      return trimmed.toUpperCase();
    }
    if (trimmed.toLowerCase().startsWith('grade ')) {
      return trimmed.substring(6).trim();
    }
    return trimmed;
  }

  Future<void> _downloadBook(Ebook cloudBook) async {
    // Create a ValueNotifier for this book's progress
    final progressNotifier = ValueNotifier<double>(0.0);
    if (mounted) {
      setState(() {
        _downloadProgress[cloudBook.id] = progressNotifier;
      });
    } else {
      _downloadProgress[cloudBook.id] = progressNotifier;
    }

    try {
      final success = await _cloudSyncService.downloadBook(
        cloudBook,
        onProgress: (progress) {
          // Only update the ValueNotifier, not the entire widget
          progressNotifier.value = progress;
        },
      );

      if (mounted) {
        setState(() {
          _downloadProgress.remove(cloudBook.id);
        });

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Downloaded: ${cloudBook.title}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          // Refresh books list after download
          _loadEbooks();
          _loadCloudBooks();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '❌ Download failed. Please check your internet and try again.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloadProgress.remove(cloudBook.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _handleCategoryTap(MenuItem item) async {
    if (item.isComingSoon) return;

    // Close the drawer before navigating to prevent routing/rendering issues
    // that can cause a black screen when pressing the back arrow.
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      _scaffoldKey.currentState?.closeDrawer();
    }

    final directIntendedByMenuId = <String, String>{
      'interactive_books': '/interactive-books',
      'esoma_kids': '/esoma',
      'loho_tv': '/loho-tv',
      'data_learning': '/dals',
      'dals_learning': '/dals',
      'virtual_labs': '/phet',
      'games': '/elimu',
      'leaderboard': '/leaderboard/embed',
    };

    final intendedPath = directIntendedByMenuId[item.id];
    if (intendedPath != null) {
      await _openProtectedIntegration(
        title: item.title,
        intendedPath: intendedPath,
      );
      return;
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryItemsScreen(menuItem: item),
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

  void _showFilterSheet() {
    String? tempCourse = _selectedCourse;
    String? tempPublisher = _selectedPublisher;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Library Filters',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.lightGreen,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.close,
                        size: 28,
                        color: AppColors.lightGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Grades Section
                Text(
                  _studentCourses.isNotEmpty ? 'Select Course' : 'Select Grade',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _studentCourses.map((course) {
                    final isSelected = tempCourse == course;
                    return GestureDetector(
                      onTap: () {
                        setModalState(() {
                          tempCourse = isSelected ? null : course;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.lightGreen
                              : Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: AppColors.lightGreen,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          course,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : AppColors.lightGreen,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),

                // Publishers Section
                const Text(
                  'Select Publisher',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  children: _publishers.map((publisher) {
                    final isSelected = tempPublisher == publisher;
                    return GestureDetector(
                      onTap: () {
                        setModalState(() {
                          tempPublisher = isSelected ? null : publisher;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.lightGreen,
                            width: 2,
                          ),
                          color: isSelected
                              ? AppColors.lightGreen.withOpacity(0.1)
                              : Colors.white,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.lightGreen,
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? Center(
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.lightGreen,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              publisher,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),

                // Apply Filters Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedCourse = tempCourse;
                        _selectedPublisher = tempPublisher;
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lightGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'APPLY FILTERS',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Reset Filters Button
                Center(
                  child: GestureDetector(
                    onTap: () {
                      setModalState(() {
                        tempCourse = null;
                        tempPublisher = null;
                      });
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Reset Filters',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.lightGreen,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: AppColors.lightGreen,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.surfaceGray,
      body: Stack(
        children: [
          // Background Hidden Drawer Menu
          Container(
            width: double.infinity,
            height: double.infinity,
            color: AppColors.surfaceGray,
            child: SafeArea(
              child: Theme(
                data: Theme.of(
                  context,
                ).copyWith(canvasColor: Colors.transparent),
                child: CategoryNavBar(
                  isDrawer: false,
                  onItemTap: (item) {
                    _toggleDrawer();
                    _handleCategoryTap(item);
                  },
                ),
              ),
            ),
          ),

          // Foreground Main Content
          AnimatedBuilder(
            animation: _drawerController,
            builder: (context, child) {
              final double slide = 260.0 * _drawerController.value;
              final double scale = 1.0 - (_drawerController.value * 0.12);
              final double radius = _drawerController.value * 32.0;

              return Transform(
                transform: Matrix4.identity()
                  ..translate(slide)
                  ..scale(scale),
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius),
                    boxShadow: [
                      if (_drawerController.value > 0)
                        BoxShadow(
                          color: Colors.blueGrey.withOpacity(0.2),
                          blurRadius: 24,
                          spreadRadius: 8,
                          offset: const Offset(-5, 0),
                        ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(radius),
                    child: Stack(
                      children: [
                        child ?? const SizedBox.shrink(),

                        // Edge swipe detector to open the drawer
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: 24,
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onHorizontalDragUpdate: (details) {
                              _drawerController.value +=
                                  details.primaryDelta! / 260.0;
                            },
                            onHorizontalDragEnd: (details) {
                              if (details.primaryVelocity! > 300) {
                                _drawerController.forward();
                              } else if (details.primaryVelocity! < -300) {
                                _drawerController.reverse();
                              } else if (_drawerController.value > 0.5) {
                                _drawerController.forward();
                              } else {
                                _drawerController.reverse();
                              }
                            },
                          ),
                        ),

                        // Full overlay to capture gestures when drawer is partially/fully open
                        if (_drawerController.value > 0)
                          Positioned.fill(
                            child: GestureDetector(
                              onTap: _toggleDrawer,
                              onHorizontalDragUpdate: (details) {
                                _drawerController.value +=
                                    details.primaryDelta! / 260.0;
                              },
                              onHorizontalDragEnd: (details) {
                                if (details.primaryVelocity! > 300) {
                                  _drawerController.forward();
                                } else if (details.primaryVelocity! < -300) {
                                  _drawerController.reverse();
                                } else if (_drawerController.value > 0.5) {
                                  _drawerController.forward();
                                } else {
                                  _drawerController.reverse();
                                }
                              },
                              child: Container(color: Colors.transparent),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
            child: _buildMainScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildMainScreen() {
    return Scaffold(
      backgroundColor: AppColors.surfaceGray,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.surfaceGray,
        leading: IconButton(
          icon: const Icon(
            Icons.menu_rounded,
            color: AppColors.brandGreen,
            size: 28,
          ),
          onPressed: _toggleDrawer,
        ),
        title: const Text(
          'Elimu Library',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.brandGreen, // Gamified header color
          ),
        ),
        actions: [
          // Library filter icon with circular background

          // Settings with circular background
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.lightGreen,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.settings_rounded,
                  size: 24,
                  color: Colors.white,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: null,
      // SUGGESTION: To add a mascot, you could wrap the body in a Stack
      // and place the Rive animation in a corner.
      // body: Stack(
      //   children: [
      //     _buildBody(), // The main content, wrapped in a function
      //     Positioned(
      //       bottom: 16,
      //       right: 16,
      //       child: SizedBox(
      //         width: 120,
      //         height: 120,
      //         child: RiveAnimation.asset('assets/animations/mascot.riv'),
      //       ),
      //     ),
      //   ],
      // ),
      body: FutureBuilder<List<List<Ebook>>>(
        future: Future.wait([_ebooksFuture, _cloudBooksFuture]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.lightGreen),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.black45,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            );
          }

          final allBooks = snapshot.data?[0] ?? [];
          final cloudBooks = snapshot.data?[1] ?? [];

          var myBooks = allBooks.toList();
          var discoverBooks = cloudBooks.toList();

          // Move learner's grade cloud books to My Books (keep Discover full)
          final learnerCourse =
              _learnerGrade ??
              _selectedCourse ??
              (_studentCourses.isNotEmpty ? _studentCourses.first : null);
          if (learnerCourse != null && learnerCourse.isNotEmpty) {
            final normalizedLearnerCourse = _normalizeGrade(learnerCourse);

            final learnerCloudBooks = discoverBooks
                .where(
                  (e) =>
                      e.category == learnerCourse ||
                      e.grade == learnerCourse ||
                      _normalizeGrade(e.grade) == normalizedLearnerCourse,
                )
                .toList();

            for (var book in learnerCloudBooks) {
              if (!myBooks.any((b) => b.id == book.id)) {
                myBooks.add(book);
              }
            }
          }

          // Apply active UI filters

          // My Books always constrained to learner grade
          if (learnerCourse != null && learnerCourse.isNotEmpty) {
            final normalizedLearnerCourse = _normalizeGrade(learnerCourse);
            myBooks = myBooks
                .where(
                  (e) =>
                      e.category == learnerCourse ||
                      e.grade == learnerCourse ||
                      _normalizeGrade(e.grade) == normalizedLearnerCourse,
                )
                .toList();
          }

          // Search & publisher filter only apply to Discover
          if (_searchQuery.isNotEmpty) {
            discoverBooks = discoverBooks
                .where(
                  (e) =>
                      e.title.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      e.author.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ),
                )
                .toList();
          }

          if (_selectedPublisher != null) {
            discoverBooks = discoverBooks
                .where((e) => e.author == _selectedPublisher)
                .toList();
          }

          return DefaultTabController(
            length: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar and Publisher Filter
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search books...',
                            prefixIcon: const Icon(
                              Icons.search,
                              color: AppColors.lightGreen,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 0,
                              horizontal: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide(
                                color: AppColors.darkGray.withOpacity(0.5),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide(
                                color: AppColors.darkGray.withOpacity(0.5),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: const BorderSide(
                                color: AppColors.lightGreen,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: AppColors.darkGray.withOpacity(0.5),
                          ),
                        ),
                        child: PopupMenuButton<String>(
                          tooltip: 'Filter by Publisher',
                          icon: const Icon(
                            Icons.filter_list,
                            color: AppColors.lightGreen,
                          ),
                          onSelected: (String? value) {
                            setState(() {
                              _selectedPublisher = value;
                            });
                          },
                          itemBuilder: (BuildContext context) => [
                            const PopupMenuItem<String>(
                              value: null,
                              child: Text('All Publishers'),
                            ),
                            ..._publishers.map(
                              (publisher) => PopupMenuItem<String>(
                                value: publisher,
                                child: Text(publisher),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Tabs
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TabBar(
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      color: AppColors.lightGreen,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.lightGreen.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.black54,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    tabs: const [
                      Tab(text: 'My Books'),
                      Tab(text: 'Discover'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Tab Views
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.lightGreen,
                    onRefresh: _refreshLibrary,
                    child: TabBarView(
                      children: [
                        _buildBookGrid(myBooks),
                        _buildBookGrid(discoverBooks),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBookGrid(List<Ebook> books) {
    if (books.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/app_icon.png', width: 64, height: 64),
                const SizedBox(height: 16),
                const Text(
                  'No books available',
                  style: TextStyle(fontSize: 16, color: Colors.black45),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        80,
      ), // Padding at bottom for FAB
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.52, // adjust for download and read buttons
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return _buildBookCard(book)
            .animate()
            .fadeIn(duration: 400.ms, delay: (50 * index).ms)
            .slideY(begin: 0.1, duration: 400.ms, curve: Curves.easeOut);
      },
    );
  }

  Widget _buildBookCard(Ebook book) {
    final isDownloading = _downloadProgress.containsKey(book.id);
    final progressNotifier = _downloadProgress[book.id];
    final isDownloaded = book.isDownloaded;

    return GestureDetector(
      onTap: isDownloaded
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReaderScreen(ebook: book),
                ),
              );
            }
          : null,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book cover/thumbnail
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: FutureBuilder<Uint8List?>(
                    future: isDownloaded && book.localPath != null
                        ? _getThumbnail(
                            book.localPath!,
                            coverImagePath: book.coverImagePath,
                          )
                        : Future.value(null),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        return Image.memory(
                          snapshot.data!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        );
                      } else if (!isDownloaded && book.coverImagePath != null) {
                        // Show network image for cloud books
                        return Image.network(
                          book.coverImagePath!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.lightGreen.withOpacity(0.3),
                                  AppColors.lightGreen.withOpacity(0.3),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Image.asset(
                                'assets/images/app_icon.png',
                                width: 60,
                                height: 60,
                              ),
                            ),
                          ),
                        );
                      }
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.lightGreen.withOpacity(0.3),
                              AppColors.lightGreen.withOpacity(0.3),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/images/app_icon.png',
                            width: 60,
                            height: 60,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            // Book info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),

                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: !isDownloaded
                        ? (isDownloading && progressNotifier != null
                              ? ListenableBuilder(
                                  listenable: progressNotifier,
                                  builder: (context, child) {
                                    final progress = progressNotifier.value;
                                    return Column(
                                      children: [
                                        LinearProgressIndicator(
                                          value: progress,
                                          backgroundColor: Colors.grey[300],
                                          valueColor:
                                              const AlwaysStoppedAnimation<
                                                Color
                                              >(AppColors.lightGreen),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${(progress * 100).toStringAsFixed(0)}%',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                )
                              : ElevatedButton.icon(
                                  onPressed: () => _downloadBook(book),
                                  icon: const Icon(Icons.download, size: 16),
                                  label: const Text('Download'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.lightGreen,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    textStyle: const TextStyle(fontSize: 12),
                                  ),
                                ))
                        : ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ReaderScreen(ebook: book),
                                ),
                              );
                            },
                            icon: const Icon(Icons.menu_book, size: 16),
                            label: const Text('Read'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.lightGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Uint8List?> _getThumbnail(
    String localPath, {
    String? coverImagePath,
  }) async {
    try {
      final storageDir = await _storageService.getEbooksDirectory();
      final fullPath = '${storageDir.path}/$localPath';
      final thumbnailService = ThumbnailService();
      return await thumbnailService.getThumbnail(
        fullPath,
        coverImagePath: coverImagePath,
      );
    } catch (e) {
      return null;
    }
  }
}
