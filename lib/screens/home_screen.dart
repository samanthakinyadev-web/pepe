import 'dart:typed_data';
import '../models/ebook.dart';
import '../models/menu_item.dart';
import 'package:flutter/material.dart';
import '../screens/reader_screen.dart';
import '../screens/settings_screen.dart';
import '../services/storage_service.dart';
import '../services/php_api_service.dart';
import '../services/database_service.dart';
import '../services/thumbnail_service.dart';
import '../screens/category_items_screen.dart';
import '../screens/webview_content_screen.dart';
import '../services/cloud_sync_service_php.dart';
import '../screens/components/category_nav_bar.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/learner_dashboard_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:loho_ebook_reader/screens/dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.scaffoldKey});

  final GlobalKey<ScaffoldState>? scaffoldKey;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _databaseService = DatabaseService.instance;
  final StorageService _storageService = StorageService.instance;
  final PhpApiService _apiService = PhpApiService.instance;
  final CloudSyncServicePhp _cloudSyncService = CloudSyncServicePhp.instance;

  late final GlobalKey<ScaffoldState> _scaffoldKey;

  late Future<List<Ebook>> _ebooksFuture;
  late Future<List<Ebook>> _cloudBooksFuture;
  String _searchQuery = '';
  String? _selectedGrade;
  String? _selectedCategory;
  final bool _showFilters = false;
  // Use ValueNotifier for each download to avoid full page rebuilds
  final Map<String, ValueNotifier<double>> _downloadProgress =
      {}; // Track download progress per book ID

  // Categories list
  final List<String> _categories = [
    'Textbooks',
    'Revision Books',
    'Readers',
    'Reference Books',
  ];

  @override
  void initState() {
    super.initState();
    _scaffoldKey = widget.scaffoldKey ?? GlobalKey<ScaffoldState>();
    _syncAndLoadBooks();

    // Check for daily reward after the first frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDailyReward();
    });
  }

  @override
  void dispose() {
    // Clean up ValueNotifiers to prevent memory leaks
    for (var notifier in _downloadProgress.values) {
      notifier.dispose();
    }
    super.dispose();
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
          '🌟 Daily Reward! h🌟',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFFe85021),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, color: Colors.amber, size: 80)
                .animate(onPlay: (controller) => controller.repeat())
                .shimmer(duration: 1200.ms, color: Colors.white)
                .shake(hz: 4, curve: Curves.easeInOut),
            const SizedBox(height: 16),
            const Text(
              'Welcome back! You earned 50 Bonus Points for logging in today!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF35a3d9),
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

  void _loadEbooks() {
    setState(() {
      _ebooksFuture = _databaseService.getAllEbooks();
    });
  }

  void _loadCloudBooks() {
    setState(() {
      _cloudBooksFuture = _cloudSyncService.getAvailableCloudBooks();
    });
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

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Search Books'),
        content: TextField(
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter book title or author...',
            prefixIcon: const Icon(Icons.search, color: Color(0xFF36a4da)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFe85021),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFe85021), width: 2),
            ),
          ),
          onSubmitted: (value) {
            setState(() {
              _searchQuery = value;
            });
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
              });
              Navigator.pop(context);
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: Color(0xFFe85021)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCategoryTap(MenuItem item) async {
    if (item.isComingSoon) return;

    // Close the drawer before navigating to prevent routing/rendering issues
    // that can cause a black screen when pressing the back arrow.
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      _scaffoldKey.currentState?.closeDrawer();
    }

    final directIntendedByMenuId = <String, String>{
      'esoma_kids': '/esoma',
      'virtual_labs': '/phet',
      'games': '/elimu',
      'loho_tv': '/loho-tv',
      'leaderboard': '/leaderboard/embed',
      'data_learning': '/dals',
      'dals_learning': '/dals',
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
    String? tempGrade = _selectedGrade;
    String? tempCategory = _selectedCategory;

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
                        color: Color(0xFF36a4da),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.close,
                        size: 28,
                        color: Color(0xFF36a4da),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Grades Section
                const Text(
                  'Select Grade',
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
                  children:
                      [
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
                      ].map((grade) {
                        final isSelected = tempGrade == grade;
                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              tempGrade = isSelected ? null : grade;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFe85021)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: const Color(0xFFe85021),
                                width: 2,
                              ),
                            ),
                            child: Text(
                              grade,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF36a4da),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
                const SizedBox(height: 32),

                // Categories Section
                const Text(
                  'Select Category',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  children: _categories.map((category) {
                    final isSelected = tempCategory == category;
                    return GestureDetector(
                      onTap: () {
                        setModalState(() {
                          tempCategory = isSelected ? null : category;
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
                            color: const Color(0xFFe85021),
                            width: 2,
                          ),
                          color: isSelected
                              ? const Color(0xFFe85021).withOpacity(0.1)
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
                                  color: const Color(0xFFe85021),
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
                                          color: Color(0xFFe85021),
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              category,
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
                        _selectedGrade = tempGrade;
                        _selectedCategory = tempCategory;
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF35a3d9),
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
                        tempGrade = null;
                        tempCategory = null;
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
                            color: Color(0xFF36a4da),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: Color(0xFF36a4da),
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
      backgroundColor: const Color(0xFFF0F8FF), // Updated to match dashboard
      drawer: CategoryNavBar(onItemTap: _handleCategoryTap),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF0F8FF),
        title: const Text(
          'Elimu Library',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D47A1), // Gamified header color
          ),
        ),
        actions: [
          // Search icon
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFFA726),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.search_rounded,
                  size: 24,
                  color: Colors.white,
                ),
                onPressed: _showSearchDialog,
              ),
            ),
          ),
          // Library filter icon with circular background

          // Settings with circular background
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF36a4da),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const GamifiedDashboardScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFFe85021),
        icon: const Icon(Icons.explore_rounded, color: Colors.white),
        label: const Text(
          'Learning Areas',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ).animate().slideY(begin: 1, duration: 800.ms, curve: Curves.easeOutBack),
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
              child: CircularProgressIndicator(color: Color(0xFFe85021)),
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

          // Filter books based on search, grade, and category
          var filteredBooks = allBooks;
          var filteredCloudBooks = cloudBooks;

          if (_searchQuery.isNotEmpty) {
            filteredBooks = filteredBooks
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
            filteredCloudBooks = filteredCloudBooks
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
          if (_selectedGrade != null) {
            final selected = _normalizeGrade(_selectedGrade!);
            filteredBooks = filteredBooks
                .where((e) => _normalizeGrade(e.grade) == selected)
                .toList();
            filteredCloudBooks = filteredCloudBooks
                .where((e) => _normalizeGrade(e.grade) == selected)
                .toList();
          }
          if (_selectedCategory != null) {
            filteredBooks = filteredBooks
                .where((e) => e.category == _selectedCategory)
                .toList();
            filteredCloudBooks = filteredCloudBooks
                .where((e) => e.category == _selectedCategory)
                .toList();
          }

          return DefaultTabController(
            length: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      _buildCategoryChip(
                        'All Categories',
                        _selectedCategory == null,
                        () {
                          setState(() => _selectedCategory = null);
                        },
                      ),
                      ..._categories.map((category) {
                        return _buildCategoryChip(
                          category,
                          _selectedCategory == category,
                          () {
                            setState(() => _selectedCategory = category);
                          },
                        );
                      }),
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
                      color: const Color(0xFFe85021),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFe85021).withOpacity(0.3),
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
                  child: TabBarView(
                    children: [
                      _buildBookGrid(filteredBooks, isDownloaded: true),
                      _buildBookGrid(filteredCloudBooks, isDownloaded: false),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: const Color(0xFF36a4da),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? const Color(0xFF36a4da) : Colors.grey.shade300,
          ),
        ),
      ),
    );
  }

  Widget _buildBookGrid(List<Ebook> books, {required bool isDownloaded}) {
    if (books.isEmpty) {
      return Center(
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
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        80,
      ), // Padding at bottom for FAB
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: isDownloaded
            ? 0.65
            : 0.52, // adjust for download button
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return _buildBookCard(book, isDownloaded: isDownloaded)
            .animate()
            .fadeIn(duration: 400.ms, delay: (50 * index).ms)
            .slideY(begin: 0.1, duration: 400.ms, curve: Curves.easeOut);
      },
    );
  }

  Widget _buildBookCard(Ebook book, {required bool isDownloaded}) {
    final isDownloading = _downloadProgress.containsKey(book.id);
    final progressNotifier = _downloadProgress[book.id];

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
                                  const Color(0xFF36a4da).withOpacity(0.3),
                                  const Color(0xFFe85021).withOpacity(0.3),
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
                              const Color(0xFF36a4da).withOpacity(0.3),
                              const Color(0xFFe85021).withOpacity(0.3),
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

                  // Download button for cloud books
                  if (!isDownloaded) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: isDownloading && progressNotifier != null
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
                                          const AlwaysStoppedAnimation<Color>(
                                            Color(0xFF35a3d9),
                                          ),
                                    ),
                                    // SUGGESTION: Replace LinearProgressIndicator with a Lottie animation
                                    // for a more engaging progress display, like a rocket filling up.
                                    // e.g., Lottie.asset('assets/animations/progress.json', controller: _animationController)
                                    // You would need to manage an AnimationController based on the download progress.
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
                                backgroundColor: const Color(0xFF35a3d9),
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
