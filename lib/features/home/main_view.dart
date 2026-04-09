// import 'dart:math' as math;
// import 'package:flutter/material.dart';
// import 'package:elimupepe/core/theme/app_theme.dart';
// import 'package:elimupepe/core/widgets/elimu_button.dart';
// import 'package:elimupepe/core/widgets/elimu_card.dart';
// import 'package:elimupepe/models/menu_item.dart';
// import 'package:elimupepe/core/services/auth_service.dart';
// import 'package:elimupepe/core/services/database_service.dart';
// import 'package:elimupepe/features/home/category_items_screen.dart';
// import 'package:elimupepe/features/settings/webview_content_screen.dart';
// import 'package:elimupepe/features/quiz/learner_dashboard_api_service.dart';
// import 'package:elimupepe/core/services/user_data_service.dart';
// import 'package:elimupepe/core/utils/image_url_resolver.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class MainView extends StatefulWidget {
//   final Function(int) onNavigate;

//   const MainView({super.key, required this.onNavigate});

//   @override
//   State<MainView> createState() => _MainViewState();
// }

// class _MainViewState extends State<MainView> {
//   static const String _avatarCacheKeyPref = 'profile_image_cache_key';
//   String _userName = "Learner";
//   String _profileImageUrl = '';
//   final TextEditingController _searchController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     _fetchUserProfile();
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   Future<void> _fetchUserProfile() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       if (mounted) {
//         setState(() {
//           _profileImageUrl = ImageUrlResolver.withCacheBuster(
//                 prefs.getString('profile_image_url') ?? '',
//                 cacheKey: prefs.getString(_avatarCacheKeyPref),
//               ) ??
//               '';
//           _userName = prefs.getString('user_name') ?? _userName;
//         });
//       }

//       final user = await AuthService.instance.getCurrentUser();
//       if (mounted) {
//         setState(() {
//           _userName = user['name'] ?? "Learner";
//           final avatar = ImageUrlResolver.fromMap(user);
//           if (avatar != null && avatar.isNotEmpty) {
//             _profileImageUrl =
//                 ImageUrlResolver.withCacheBuster(
//                   avatar,
//                   cacheKey: prefs.getString(_avatarCacheKeyPref),
//                 ) ??
//                 avatar;
//           }
//         });
//       }
//     } catch (e) {
//       // Fallback for Guest mode
//     }
//   }

//   Future<void> _onSelectItem(MenuItem item) async {
//     if (item.isComingSoon) return;

//     final intendedPath = MenuItem.directIntendedPathFor(item.id);
//     if (intendedPath != null) {
//       final targetUrl = 'https://elimupepe.loholearning.co.ke$intendedPath';
//       final webviewLoginUrl = await LearnerDashboardApiService.instance
//           .fetchWebviewLoginUrl(targetUrl: targetUrl);

//       if (!mounted) return;

//       if (webviewLoginUrl == null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text(
//               'Could not open this area securely. Please try again.',
//             ),
//           ),
//         );
//         return;
//       }

//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) =>
//               WebViewContentScreen(title: item.title, url: webviewLoginUrl),
//         ),
//       );
//       return;
//     }

//     if (!mounted) return;

//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => CategoryItemsScreen(menuItem: item),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: AppColors.brandGreen,
//         elevation: 0,
//         title: const Text("Dashboard"),
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 16),
//             child: GestureDetector(
//               onTap: () =>
//                   widget.onNavigate(4), // Navigate to Profile Tab (index 4)
//               child: CircleAvatar(
//                 radius: 16,
//                 backgroundImage: _profileImageUrl.isNotEmpty
//                     ? NetworkImage(_profileImageUrl)
//                     : null,
//                 backgroundColor: Colors.white,
//                 child: _profileImageUrl.isEmpty
//                     ? const Icon(Icons.person, size: 18)
//                     : null,
//               ),
//             ),
//           ),
//         ],
//       ),
//       body: _buildBody(),
//     );
//   }

//   // --- MAIN DASHBOARD BODY ---
//   Widget _buildBody() {
//     final menuItems = MenuItem.getDefaultMenuItems();
//     return Container(
//       color: AppColors.surfaceGray,
//       child: DefaultTabController(
//         length: 3,
//         child: RefreshIndicator(
//           color: AppColors.lightGreen,
//           onRefresh: _fetchUserProfile,
//           child: ListView(
//             padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
//             children: [
//               _buildHeaderCard(),
//               const SizedBox(height: 20),
//               _buildSectionHeader("Quick Access"),
//               const SizedBox(height: 12),
//               _buildQuickAccessTabs(menuItems),
//               const SizedBox(height: 20),
//               _buildDailyProgressCard(),
//               const SizedBox(height: 24),
//               _buildSectionHeader(
//                 "Overview",
//                 onTap: () => _openMenuItem(menuItems),
//               ),
//               const SizedBox(height: 16),
//               _buildStatsGrid(),
//               const SizedBox(height: 24),
//               _buildSectionHeader(
//                 "My Learning Areas",
//                 onTap: () => _openMenuItem(menuItems),
//               ),
//               const SizedBox(height: 16),
//               _buildRecentActivitiesSection(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   void _openMenuItem(List<MenuItem> menuItems) {
//     if (menuItems.isEmpty) return;
//     _onSelectItem(menuItems.first);
//   }

//   Widget _buildHeaderCard() {
//     return ElimuCard(
//       padding: const EdgeInsets.all(20),
//       backgroundColor: AppColors.brandGreen,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             "Welcome back,",
//             style: TextStyle(
//               color: Colors.white.withValues(alpha: 0.85),
//               fontSize: 14,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             _userName,
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 16),
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               Expanded(
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 12),
//                   decoration: BoxDecoration(
//                     color: Colors.white.withValues(alpha: 0.18),
//                     borderRadius: BorderRadius.circular(14),
//                   ),
//                   child: TextField(
//                     controller: _searchController,
//                     style: const TextStyle(color: Colors.white),
//                     textInputAction: TextInputAction.search,
//                     onSubmitted: (query) {
//                       if (query.trim().isNotEmpty) {
//                         widget.onNavigate(1); // Navigate to Library Tab
//                       }
//                     },
//                     decoration: const InputDecoration(
//                       hintText: "Search your library",
//                       hintStyle: TextStyle(color: Colors.white70),
//                       border: InputBorder.none,
//                       icon: Icon(Icons.search, color: AppColors.white),
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               GestureDetector(
//                 onTap: () {
//                   if (_searchController.text.trim().isNotEmpty) {
//                     widget.onNavigate(1); // Navigate to Library Tab
//                   }
//                 },
//                 child: Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: Colors.white.withValues(alpha: 0.2),
//                     borderRadius: BorderRadius.circular(14),
//                   ),
//                   child: const Icon(
//                     Icons.auto_stories,
//                     color: AppColors.white,
//                     size: 24,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 14),
//           ElimuButton(
//             text: "Start Learning",
//             onPressed: () => widget.onNavigate(1), // Navigate to Library Tab
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildQuickAccessTabs(List<MenuItem> menuItems) {
//     final quickItems = menuItems;
//     return ElimuCard(
//       padding: const EdgeInsets.all(12),
//       child: Column(
//         children: [
//           const TabBar(
//             labelColor: AppColors.brandGreen,
//             unselectedLabelColor: AppColors.textMuted,
//             indicatorColor: AppColors.brandGreen,
//             indicatorSize: TabBarIndicatorSize.label,
//             indicatorWeight: 3,
//             tabs: [
//               Tab(text: "Continue"),
//               Tab(text: "Bookmarks"),
//               Tab(text: "Explore"),
//             ],
//           ),
//           const SizedBox(height: 12),
//           SizedBox(
//             height: 140,
//             child: TabBarView(
//               children: [
//                 _buildQuickAccessRow(quickItems),
//                 _buildQuickAccessRow(quickItems.reversed.toList()),
//                 _buildQuickAccessRow(quickItems),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildQuickAccessRow(List<MenuItem> items) {
//     return ListView.separated(
//       scrollDirection: Axis.horizontal,
//       itemCount: items.length,
//       separatorBuilder: (context, index) => const SizedBox(width: 12),
//       itemBuilder: (context, index) {
//         final item = items[index];
//         return ElimuCard(
//           padding: const EdgeInsets.all(14),
//           backgroundColor: AppColors.brandGreen.withValues(alpha: 0.08),
//           borderColor: AppColors.brandGreen.withValues(alpha: 0.1),
//           onTap: item.isComingSoon ? null : () => _onSelectItem(item),
//           child: SizedBox(
//             width:
//                 100, // Reduced from 140 since padding/border might take space
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Icon(item.icon, color: AppColors.brandGreen),
//                 const SizedBox(height: 8),
//                 Text(
//                   item.title,
//                   style: const TextStyle(
//                     fontWeight: FontWeight.w600,
//                     color: AppColors.brandGreen,
//                   ),
//                 ),
//                 Text(
//                   item.isComingSoon ? "Coming soon" : "Open",
//                   style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildDailyProgressCard() {
//     return ElimuCard(
//       padding: const EdgeInsets.all(20),
//       child: Row(
//         children: [
//           SizedBox(
//             height: 75,
//             width: 75,
//             child: CustomPaint(
//               painter: RingProgressPainter(
//                 progress: 0.75,
//                 color: AppColors.accentOrange,
//               ),
//               child: const Center(
//                 child: Text(
//                   "75%",
//                   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(width: 20),
//           const Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   "Daily Goal",
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//                 Text(
//                   "Keep it up! You're almost at your target for today.",
//                   style: TextStyle(color: AppColors.textMuted, fontSize: 13),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSectionHeader(String title, {VoidCallback? onTap}) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(
//           title,
//           style: const TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//             color: AppColors.brandGreen,
//           ),
//         ),
//         InkWell(
//           onTap: onTap,
//           borderRadius: BorderRadius.circular(8),
//           child: const Padding(
//             padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
//             child: Text(
//               "See All",
//               style: TextStyle(
//                 color: AppColors.primaryBlue,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Future<Map<String, String>> _fetchInsights() async {
//     try {
//       final dbService = DatabaseService.instance;
//       final localBooks = await dbService.getAllEbooks();
//       final results = await Future.wait<dynamic>([
//         LearnerDashboardApiService.instance.fetchWallet(),
//         UserDataService.instance.fetchGrades(),
//         LearnerDashboardApiService.instance.fetchQuizzes(),
//         LearnerDashboardApiService.instance.fetchStreaks(),
//       ]);

//       final wallet = results[0] as Map<String, dynamic>?;
//       final grades = results[1] as List<dynamic>?;
//       final quizzes = results[2] as List<dynamic>;
//       final streaks = results[3] as Map<String, dynamic>?;

//       final points = _readInt([
//         wallet?['balance'],
//         wallet?['coins'],
//         wallet?['loho_coins'],
//       ]);
//       final completed = grades?.length ?? 0;
//       final totalQuizzes = quizzes.length;
//       final progress = totalQuizzes > 0
//           ? ((completed / totalQuizzes).clamp(0, 1) * 100).round()
//           : _readInt([streaks?['progress'], streaks?['completion_rate']]) ?? 0;
//       final averageScore = completed > 0
//           ? _readInt([
//                   (grades!
//                               .whereType<Map<String, dynamic>>()
//                               .map(
//                                 (grade) => _readInt([
//                                   grade['score'],
//                                   grade['marks'],
//                                   grade['percentage'],
//                                 ]),
//                               )
//                               .whereType<int>()
//                               .fold<int>(0, (sum, item) => sum + item) /
//                           completed)
//                       .round(),
//                 ]) ??
//                 0
//           : 0;

//       return {
//         'courses': localBooks.length.toString(),
//         'progress': '$progress%',
//         'points': points?.toString() ?? '0',
//         'score': '$averageScore%',
//       };
//     } catch (e) {
//       return {'courses': '0', 'progress': '0%', 'points': '0', 'score': '0%'};
//     }
//   }

//   int? _readInt(List<dynamic> values) {
//     for (final value in values) {
//       if (value is int) return value;
//       if (value is double) return value.round();
//       if (value is String) {
//         final parsed = int.tryParse(value);
//         if (parsed != null) return parsed;
//       }
//     }
//     return null;
//   }

//   Widget _buildStatsGrid() {
//     return FutureBuilder<Map<String, String>>(
//       future: _fetchInsights(),
//       builder: (context, snapshot) {
//         final data =
//             snapshot.data ??
//             {'courses': '-', 'progress': '-', 'points': '-', 'score': '-'};
//         return LayoutBuilder(
//           builder: (context, constraints) {
//             const crossAxisSpacing = 12.0;
//             const mainAxisSpacing = 12.0;
//             final textScale = MediaQuery.textScalerOf(context).scale(1);
//             final tileWidth = (constraints.maxWidth - crossAxisSpacing) / 2;
//             final desiredHeight = 124.0 * textScale.clamp(1.0, 1.4);
//             final childAspectRatio = tileWidth / desiredHeight;

//             return GridView.builder(
//               gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                 crossAxisCount: 2,
//                 mainAxisSpacing: mainAxisSpacing,
//                 crossAxisSpacing: crossAxisSpacing,
//                 childAspectRatio: childAspectRatio,
//               ),
//               physics: const NeverScrollableScrollPhysics(),
//               shrinkWrap: true,
//               itemCount: 4,
//               itemBuilder: (context, index) {
//                 switch (index) {
//                   case 0:
//                     return _buildStatTile(
//                       "Library Books",
//                       data['courses']!,
//                       Icons.menu_book_rounded,
//                       AppColors.primaryBlue,
//                     );
//                   case 1:
//                     return _buildStatTile(
//                       "Progress",
//                       data['progress']!,
//                       Icons.trending_up,
//                       AppColors.brandGreen,
//                     );
//                   case 2:
//                     return _buildStatTile(
//                       "Points",
//                       data['points']!,
//                       Icons.stars_rounded,
//                       AppColors.accentOrange,
//                     );
//                   default:
//                     return _buildStatTile(
//                       "Avg Score",
//                       data['score']!,
//                       Icons.score,
//                       AppColors.accentPurple,
//                     );
//                 }
//               },
//             );
//           },
//         );
//       },
//     );
//   }

//   Future<List<dynamic>> _fetchRecentActivities() async {
//     try {
//       final items = await LearnerDashboardApiService.instance.fetchMenuItems(
//         menuId: 'learning_areas',
//       );
//       // Safely handle if items is null or not strictly recognized as a List by the analyzer
//       return (items as List?)?.take(3).toList() ?? [];
//     } catch (e) {
//       return [];
//     }
//   }

//   Widget _buildRecentActivitiesSection() {
//     return FutureBuilder<List<dynamic>>(
//       future: _fetchRecentActivities(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(
//             child: Padding(
//               padding: EdgeInsets.all(16.0),
//               child: CircularProgressIndicator(),
//             ),
//           );
//         }
//         final items = snapshot.data ?? [];
//         if (items.isEmpty) {
//           return const Padding(
//             padding: EdgeInsets.all(16.0),
//             child: Text(
//               "No recent activities found.",
//               style: TextStyle(color: Colors.grey),
//             ),
//           );
//         }
//         return Column(
//           children: items.map((item) {
//             final itemMap = item as Map<String, dynamic>? ?? {};
//             final title =
//                 itemMap['title'] ??
//                 itemMap['course_name'] ??
//                 itemMap['name'] ??
//                 'Unknown Course';
//             final subtitle = itemMap['subtitle'] ?? 'In Progress';
//             return _buildActivityCard(
//               title,
//               subtitle.toString(),
//               Icons.menu_book_rounded,
//               AppColors.primaryBlue,
//             );
//           }).toList(),
//         );
//       },
//     );
//   }

//   Widget _buildStatTile(
//     String label,
//     String value,
//     IconData icon,
//     Color color,
//   ) {
//     return ElimuCard(
//       backgroundColor: color.withValues(alpha: 0.1),
//       borderColor: color.withValues(alpha: 0.2),
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(icon, color: color, size: 24),
//           const SizedBox(height: 12),
//           Text(
//             value,
//             style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//           ),
//           Text(
//             label,
//             style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildActivityCard(
//     String title,
//     String subtitle,
//     IconData icon,
//     Color color,
//   ) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: ElimuCard(
//         padding: const EdgeInsets.all(4),
//         child: ListTile(
//           leading: CircleAvatar(
//             backgroundColor: color.withValues(alpha: 0.1),
//             child: Icon(icon, color: color),
//           ),
//           title: Text(
//             title,
//             style: const TextStyle(fontWeight: FontWeight.bold),
//           ),
//           subtitle: Text(subtitle),
//           trailing: const Icon(Icons.chevron_right, size: 18),
//         ),
//       ),
//     );
//   }
// }

// // --- CUSTOM PAINTER FOR CIRCULAR CHART ---
// class RingProgressPainter extends CustomPainter {
//   final double progress;
//   final Color color;

//   RingProgressPainter({required this.progress, required this.color});

//   @override
//   void paint(Canvas canvas, Size size) {
//     final strokeWidth = 8.0;
//     final center = Offset(size.width / 2, size.height / 2);
//     final radius = (size.width - strokeWidth) / 2;

//     final bgPaint = Paint()
//       ..color = color.withValues(alpha: 0.1)
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = strokeWidth;

//     final pgPaint = Paint()
//       ..color = color
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = strokeWidth
//       ..strokeCap = StrokeCap.round;

//     canvas.drawCircle(center, radius, bgPaint);
//     canvas.drawArc(
//       Rect.fromCircle(center: center, radius: radius),
//       -math.pi / 2,
//       2 * math.pi * progress,
//       false,
//       pgPaint,
//     );
//   }

//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) => true;
// }
