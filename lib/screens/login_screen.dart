import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:loho_ebook_reader/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:loho_ebook_reader/screens/dashboard_screen.dart';
import 'package:loho_ebook_reader/screens/parents/parent_dashboard.dart';
import 'package:loho_ebook_reader/screens/teachers/teacher_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  static const Color _primaryGreen = AppColors.brandGreen;
  static const Color _accentOrange = AppColors.accentOrange;
  static const Color _softBackground = AppColors.brandGreen;
  static const Color _cardBorder = AppColors.darkGray;
  static const Color _textDark = AppColors.textMain;
  static const Color _textMuted = AppColors.textMuted;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final loginResult = await AuthService.instance.login(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      if (!loginResult.success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(loginResult.message)));
        return;
      }

      // Save basic dynamic info for the profile screen to read
      final prefs = await SharedPreferences.getInstance();
      final emailPrefix = _emailController.text.split('@').first;
      final capitalizedName = emailPrefix.isNotEmpty
          ? emailPrefix[0].toUpperCase() + emailPrefix.substring(1)
          : 'Student';
      await prefs.setString('user_name', capitalizedName);
      await prefs.setString('user_email', _emailController.text);
      await prefs.setString(
        'loho_id',
        'LOHO-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => _routeForRole(loginResult)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login error: $e')));
    }
  }

  Widget _routeForRole(LoginResult loginResult) {
    final roleId = loginResult.roleId;
    final roleName = loginResult.roleName?.toLowerCase();

    if (roleId == 2 || roleName == 'teacher' || roleName == 'educator') {
      return const TeacherDashboard();
    }

    if (roleId == 7 || roleName == 'parent' || roleName == 'guardian') {
      return const ParentDashboard();
    }

    return const GamifiedDashboardScreen();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final shortestSide = screenSize.shortestSide;
    final isTablet = shortestSide >= 600;
    final isLandscape = screenSize.width > screenSize.height;
    final heroAspectRatio = isTablet ? (isLandscape ? 2.4 : 1.5) : 1.5;
    final heroFit = isTablet ? BoxFit.contain : BoxFit.cover;
    final contentWidth = isTablet ? 560.0 : (screenSize.width - 48);

    return Scaffold(
      backgroundColor: _softBackground,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  // TODO: Update these colors to match fam1.png if needed
                  colors: [AppColors.brandGreen, AppColors.lightGreen],
                ),
              ),
            ),
          ),
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              height: 220,
              width: 220,
              decoration: BoxDecoration(
                color: _primaryGreen.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -140,
            left: -60,
            child: Container(
              height: 260,
              width: 260,
              decoration: BoxDecoration(
                color: _primaryGreen.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isTablet ? 560 : double.infinity,
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildWavyHeader(
                            isTablet: isTablet,
                            heroAspectRatio: heroAspectRatio,
                            heroFit: heroFit,
                            contentWidth: contentWidth,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'SMART LEARNING',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'for a Smarter Generation',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  _buildInputField(
                                    icon: Icons.email_outlined,
                                    label: 'Email address/loho ID',
                                    hint: 'name@example.com',
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      final text = value?.trim() ?? '';
                                      if (text.isEmpty) {
                                        return 'Email or Loho ID is required';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  _buildInputField(
                                    icon: Icons.lock_outline,
                                    label: 'Password',
                                    hint: 'Enter your password',
                                    controller: _passwordController,
                                    isPassword: true,
                                    validator: (value) {
                                      if ((value ?? '').isEmpty) {
                                        return 'Password is required';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: AppColors.accentCoral,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.6,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Login',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please contact admin for password reset.',
                                  ),
                                ),
                              );
                            },
                            child: const Text(
                              'Forgot password?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'No account yet? Contact admin for access',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () async {
                              // TODO: Replace with your actual Privacy Policy URL from GitHub Pages
                              final url = Uri.parse(
                                'https://your-username.github.io/loho-reader-policy/',
                              );
                              if (await canLaunchUrl(url)) {
                                await launchUrl(
                                  url,
                                  mode: LaunchMode.externalApplication,
                                );
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Could not open privacy policy.',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            child: Text(
                              'Privacy Policy',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWavyHeader({
    required bool isTablet,
    required double heroAspectRatio,
    required BoxFit heroFit,
    required double contentWidth,
  }) {
    final imageHeight = contentWidth / heroAspectRatio;
    final headerHeight = imageHeight + (isTablet ? 92.0 : 76.0);
    return SizedBox(
      height: headerHeight,
      child: Stack(
        children: [
          ClipPath(
            clipper: _WavyHeaderClipper(),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                // TODO: Update this hex color to exactly match the background color of fam1.png
                color: Color(0xFFE8F6F3),
              ),
              child: Image.asset(
                'assets/images/fam.png',
                fit: heroFit,
                alignment: isTablet ? Alignment.center : Alignment.bottomCenter,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    'assets/images/kid_reading.png',
                    fit: heroFit,
                    alignment: isTablet
                        ? Alignment.center
                        : Alignment.bottomCenter,
                  );
                },
              ),
            ),
          ),
          Positioned(
            top: 14,
            right: -8,
            child: Container(
              height: 90,
              width: 90,
              decoration: BoxDecoration(
                color: _primaryGreen.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            left: -24,
            child: Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                color: _primaryGreen.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required IconData icon,
    required String label,
    required String hint,
    required TextEditingController controller,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: isPassword ? _obscurePassword : false,
          validator: validator,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 22),
            suffixIcon: isPassword
                ? IconButton(
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: Colors.grey.shade600,
                      size: 22,
                    ),
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.lightGreen,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class _WavyHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.72);
    path.quadraticBezierTo(
      size.width * 0.18,
      size.height * 0.88,
      size.width * 0.38,
      size.height * 0.78,
    );
    path.quadraticBezierTo(
      size.width * 0.62,
      size.height * 0.65,
      size.width * 0.82,
      size.height * 0.74,
    );
    path.quadraticBezierTo(
      size.width * 0.95,
      size.height * 0.8,
      size.width,
      size.height * 0.7,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_WavyHeaderClipper oldClipper) => false;
}
