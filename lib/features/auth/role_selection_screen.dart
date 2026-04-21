import 'dart:io';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:elimupepe/core/theme/app_theme.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:elimupepe/features/auth/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:elimupepe/core/theme/app_page_transitions.dart';
import 'package:elimupepe/features/parental_control/parental_gate.dart';

enum _SelectedRole { student, teacher, parent }

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  _SelectedRole? _loadingRole;
  static const String _iconAssetPath = 'assets/images/f.png';

  @override
  void initState() {
    super.initState();
    // Check for app updates as soon as the user reaches this screen.
    _checkForUpdates();
  }

  // --- Helper Methods ---
  Future<void> _contactAdmin() async {
    final passed = await showParentalGate(context);
    if (!mounted || !passed) return;
    final Uri uri = Uri.parse(
      "https://wa.me/254797349396?text=Hello%20Support",
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // --- Role Handlers ---
  Future<void> _handleRole({
    required _SelectedRole role,
    required Future<void> Function() action,
  }) async {
    setState(() => _loadingRole = role);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_pre_login_role', role.name);
    await action();
    if (mounted) setState(() => _loadingRole = null);
  }

  // --- Update Check Methods ---
  Future<void> _checkForUpdates() async {
    // This check is delayed slightly to allow the main UI to build first,
    // preventing the update dialog from appearing too abruptly on app start.
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    bool playStoreUpdateTriggered = false;

    // 1. Try Google Play Store Update First (Only if running on an Android device)
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final updateInfo = await InAppUpdate.checkForUpdate();
        if (updateInfo.updateAvailability ==
            UpdateAvailability.updateAvailable) {
          // For a mandatory update, perform an immediate update.
          // For a flexible update, you could show a snackbar or a different dialog.
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
    // This is for non-Play Store builds (e.g., direct APK downloads from your website)
    bool shouldCheckCustom = !playStoreUpdateTriggered;
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final packageInfo = await PackageInfo.fromPlatform();
        final installer = packageInfo.installerStore;
        // Only skip custom check if we are certain it's a Play Store build.
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
                  final passed = await showParentalGate(context);
                  if (!passed || !mounted) return;

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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/girl.png', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.35)),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: isSmallScreen ? 16 : 32,
                  ),
                  children: [
                    SizedBox(height: isSmallScreen ? 20 : 40),
                    _buildHeader(context, isSmallScreen: isSmallScreen),
                    SizedBox(height: isSmallScreen ? 30 : 40),

                    // Student Role
                    _buildOption(
                      title: 'I am a Student',
                      subtitle: 'Access your learning account',
                      color: const Color.fromARGB(255, 27, 25, 25),
                      icon: Icons.school_rounded,
                      role: _SelectedRole.student,
                      onTap: () => _handleRole(
                        role: _SelectedRole.student,
                        action: () async {
                          Navigator.pushReplacement(
                            context,
                            AppPageTransitions.route(const LoginScreen()),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Teacher & Parent Info
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 22,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.darkGray.withValues(alpha: 0.4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        'Go to elimupepe.loholearning.co.ke to upgrade your subscription.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMain,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                    ),

                    SizedBox(height: isSmallScreen ? 20 : 28),

                    Center(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          foregroundColor: Colors.white.withValues(alpha: 0.75),
                        ),
                        onPressed: _contactAdmin,
                        child: Text(
                          'Need help? Contact Admin',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.28),
                        borderRadius: AppStyles.radiusSmall,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              'You need a Safaricom line to subscribe\n\n'
                              '1️⃣ Choose a plan on the website\n'
                              '2️⃣ Confirm payment via M-Pesa\n'
                              '3️⃣ Start learning 🎉\n\n'
                              '✅ Quick and easy!',
                              textAlign: TextAlign.left,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.92),
                                    height: 1.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Align(
                            alignment: Alignment.center,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                'assets/images/xenye.png',
                                width: 110,
                                height: 110,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, {required bool isSmallScreen}) {
    return ClipRRect(
      borderRadius: AppStyles.radiusMedium,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: AppStyles.radiusMedium,
            color: Colors.black.withValues(alpha: 0.35),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: isSmallScreen ? 56 : 64,
                height: isSmallScreen ? 56 : 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(_iconAssetPath),
                ),
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Welcome to Elimu Pepe',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select your role to continue',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption({
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required _SelectedRole role,
    required VoidCallback onTap,
  }) {
    final isLoading = _loadingRole == role;
    return InkWell(
      onTap: _loadingRole == null ? onTap : null,
      borderRadius: AppStyles.radiusSmall,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.darkGray.withValues(alpha: 0.4)),
          borderRadius: AppStyles.radiusSmall,
          boxShadow: AppStyles.playfulShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            if (isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            else
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
