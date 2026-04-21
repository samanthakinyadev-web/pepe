import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:elimupepe/core/theme/app_theme.dart';
import 'package:elimupepe/features/auth/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:elimupepe/core/theme/app_page_transitions.dart';

enum _SelectedRole { student, teacher, parent }

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  static const String parentPlansUrl =
      'https://elimupepe.loholearning.co.ke/subscription/plans';

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  _SelectedRole? _loadingRole;
  static const String _iconAssetPath = 'assets/images/f.png';

  // --- Helper Methods ---
  Future<void> _contactAdmin() async {
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

  @override
  Widget build(BuildContext context) {
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
                  padding: const EdgeInsets.all(24),
                  children: [
                    const SizedBox(height: 40),
                    _buildHeader(context),
                    const SizedBox(height: 40),

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

                    // Teacher Role
                          _buildOption(
                            title: 'I am a Teacher',
                            subtitle: 'Access your teaching account',
                            color: AppColors.primaryBlue,
                            icon: Icons.menu_book_rounded,
                            role: _SelectedRole.teacher,
                            onTap: () => _handleRole(
                              role: _SelectedRole.teacher,
                        action: () async {
                          final uri = Uri.parse(
                            RoleSelectionScreen.parentPlansUrl,
                          );
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Parent Role
                          _buildOption(
                            title: 'I am a Parent',
                            subtitle: 'Manage subscriptions and learners',
                            color: AppColors.accentCoral,
                            icon: Icons.family_restroom_rounded,
                            role: _SelectedRole.parent,
                            onTap: () => _handleRole(
                              role: _SelectedRole.parent,
                        action: () async {
                          final uri = Uri.parse(
                            RoleSelectionScreen.parentPlansUrl,
                          );
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 28),

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
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
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

  Widget _buildHeader(BuildContext context) {
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
                width: 64,
                height: 64,
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
