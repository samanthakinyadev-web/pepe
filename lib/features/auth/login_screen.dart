import 'package:flutter/material.dart';
import 'package:elimupepe/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:elimupepe/core/theme/wave_clipper.dart';
import 'package:elimupepe/core/widgets/elimu_button.dart';
import 'package:elimupepe/core/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:elimupepe/core/widgets/elimu_text_field.dart';
import 'package:elimupepe/features/home/dashboard_screen.dart';
import 'package:elimupepe/core/theme/app_page_transitions.dart';
import 'package:elimupepe/features/teacher/teacher_dashboard.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:elimupepe/features/auth/role_selection_screen.dart';
import 'package:elimupepe/features/settings/webview_content_screen.dart';
import 'package:elimupepe/features/parental_control/parent_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool _rememberMe = false;
  bool _isLoading = false;
  bool _hasAgreed = false;

  static const Color _primaryGreen = AppColors.brandGreen;
  static const Color _softBackground = AppColors.brandGreen;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('remember_me') ?? false;

    if (rememberMe) {
      final studentId =
          prefs.getString('saved_student_id') ??
          prefs.getString('saved_email') ??
          '';

      // Try reading from secure storage first
      String? password = await _secureStorage.read(key: 'saved_password');

      // Migration: If not in secure storage, check old insecure storage
      if (password == null) {
        password = prefs.getString('saved_password') ?? '';
        if (password.isNotEmpty) {
          // Move to secure storage and remove from insecure
          await _secureStorage.write(key: 'saved_password', value: password);
          await prefs.remove('saved_password');
        }
      }

      if (mounted) {
        _studentIdController.text = studentId.toUpperCase();
        _passwordController.text = password;
        setState(() => _rememberMe = rememberMe);
      }
    }
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    if (!_hasAgreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please agree to the Terms & Conditions and Privacy Policy to continue.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final loginResult = await AuthService.instance.login(
        studentId: _studentIdController.text,
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      if (!loginResult.success) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(loginResult.message)));
        }
        return;
      }

      // Save or clear credentials based on the "Remember Me" checkbox
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setBool('remember_me', true);
        await prefs.setString(
          'saved_student_id',
          _studentIdController.text.trim().toUpperCase(),
        );
        await prefs.remove('saved_email');
        // Securely store the password
        await _secureStorage.write(
          key: 'saved_password',
          value: _passwordController.text,
        );
        // Clean up old insecure storage if it exists
        await prefs.remove('saved_password');
      } else {
        await prefs.remove('remember_me');
        await prefs.remove('saved_student_id');
        await prefs.remove('saved_email');
        await _secureStorage.delete(key: 'saved_password');
        await prefs.remove('saved_password');
      }

      final normalizedStudentId = _studentIdController.text
          .trim()
          .toUpperCase();
      final fallbackName = normalizedStudentId.isNotEmpty
          ? normalizedStudentId
          : 'Student';
      await prefs.setString('user_name', loginResult.name ?? fallbackName);
      await prefs.setString('user_email', '');
      await prefs.setString(
        'loho_id',
        (loginResult.studentId ?? normalizedStudentId).toUpperCase(),
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => _routeForRole(loginResult)),
        );
      }
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

    return Scaffold(
      backgroundColor: _softBackground,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.brandGreen, AppColors.lightGreen],
                ),
              ),
            ),
          ),

          // Wavy Header Image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: WaveClipper(),
              child: Container(
                height: isTablet ? 350 : 280,
                decoration: const BoxDecoration(color: Colors.white),
                child: Image.asset('assets/images/fam.png', fit: BoxFit.cover)
                    .animate()
                    .fadeIn(duration: 800.ms)
                    .scale(begin: const Offset(1.1, 1.1), duration: 1000.ms),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Spacer for the header image
                        SizedBox(height: isTablet ? 320 : 250),

                        const SizedBox(height: 12),
                        const Text(
                              'Welcome Back!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    offset: Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            )
                            .animate()
                            .fadeIn(delay: 400.ms, duration: 600.ms)
                            .slideY(begin: 0.2),
                        const SizedBox(height: 8),
                        Text(
                              'Enter your details to continue.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            )
                            .animate()
                            .fadeIn(delay: 500.ms, duration: 600.ms)
                            .slideY(begin: 0.2),
                        const SizedBox(height: 24),

                        Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  ElimuTextField(
                                    icon: Icons.person_outline_rounded,
                                    label: 'Student ID',
                                    hint: 'Enter your Student ID (LO-XXXXXXXX)',
                                    controller: _studentIdController,
                                    keyboardType: TextInputType.text,
                                    validator: (value) {
                                      final text = (value ?? '')
                                          .trim()
                                          .toUpperCase();
                                      if (text.isEmpty) {
                                        return 'Please enter your Student ID';
                                      }
                                      if (text.contains('@')) {
                                        return 'Email login is not supported. Use your Student ID.';
                                      }
                                      final isValid = RegExp(
                                        r'^LO-[A-Z0-9]{8}$',
                                        caseSensitive: false,
                                      ).hasMatch(text);
                                      if (!isValid) {
                                        return 'Invalid Student ID format. Expected: LO-XXXXXXXX';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  ElimuTextField(
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
                            )
                            .animate()
                            .fadeIn(delay: 600.ms, duration: 600.ms)
                            .slideY(begin: 0.2),
                        const SizedBox(height: 12),
                        _buildRememberMeRow(),
                        const SizedBox(height: 12),
                        _buildAgreementRow(),
                        const SizedBox(height: 12),
                        ElimuButton(
                              text: 'Login',
                              isLoading: _isLoading,
                              onPressed: _handleLogin,
                            )
                            .animate()
                            .fadeIn(delay: 800.ms, duration: 600.ms)
                            .slideY(begin: 0.2),
                        const SizedBox(height: 10),
                        TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      Navigator.of(context).pushReplacement(
                                        AppPageTransitions.route(
                                          const RoleSelectionScreen(),
                                        ),
                                      );
                                    },
                              child: const Text(
                                'Back to role selection',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                            .animate()
                            .fadeIn(delay: 850.ms, duration: 600.ms)
                            .slideY(begin: 0.2),
                        const SizedBox(height: 32),
                        Text(
                          'No account yet? go back to select your role and register.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 900.ms, duration: 600.ms),
                        const SizedBox(height: 48),
                      ],
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

  Widget _buildRememberMeRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => setState(() => _rememberMe = !_rememberMe),
          child: Row(
            children: [
              Theme(
                data: Theme.of(
                  context,
                ).copyWith(unselectedWidgetColor: Colors.white70),
                child: Checkbox(
                  value: _rememberMe,
                  onChanged: (value) {
                    setState(() {
                      _rememberMe = value ?? false;
                    });
                  },
                  activeColor: Colors.white,
                  checkColor: _primaryGreen,
                  side: const BorderSide(color: Colors.white, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const Text(
                'Remember Me',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please contact admin for password reset.'),
              ),
            );
          },
          child: const Text(
            '',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 700.ms, duration: 600.ms);
  }

  Widget _buildAgreementRow() {
    return Row(
      children: [
        Theme(
          data: Theme.of(
            context,
          ).copyWith(unselectedWidgetColor: Colors.white70),
          child: Checkbox(
            value: _hasAgreed,
            onChanged: (value) {
              setState(() {
                _hasAgreed = value ?? false;
              });
            },
            activeColor: Colors.white,
            checkColor: _primaryGreen,
            side: const BorderSide(color: Colors.white, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        Expanded(
          child: Wrap(
            children: [
              const Text(
                'I agree to the ',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const WebViewContentScreen(
                      title: 'Terms & Conditions',
                      url: 'https://loho-stack.github.io/app-policies/',
                    ),
                  ),
                ),
                child: const Text(
                  'Terms & Conditions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const Text(
                ' and ',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const WebViewContentScreen(
                      title: 'Privacy Policy',
                      url:
                          'https://loho-stack.github.io/app-policies/index.html',
                    ),
                  ),
                ),
                child: const Text(
                  'Privacy Policy',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 750.ms, duration: 600.ms);
  }
}
