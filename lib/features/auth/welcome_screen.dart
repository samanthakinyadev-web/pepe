import 'role_selection_screen.dart';
import 'package:elimupepe/core/theme/app_theme.dart';
import 'package:elimupepe/core/theme/app_page_transitions.dart';
import 'package:elimupepe/core/widgets/elimu_button.dart';
import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  void _navigateToLogin() {
    Navigator.of(
      context,
    ).pushReplacement(AppPageTransitions.route(const RoleSelectionScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandGreen,
      body: Stack(
        children: [
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
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              height: 220,
              width: 220,
              decoration: BoxDecoration(
                color: AppColors.brandGreen.withValues(alpha: 0.08),
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
                color: AppColors.brandGreen.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          PageView(
            controller: _controller,
            onPageChanged: (int page) => setState(() => _currentPage = page),
            children: const [
              WelcomePage(
                icon: Icons.school,
                title: "Welcome to Elimu Pepe",
                description: "SMART LEARNING. for a Smarter Generation..",
              ),
              WelcomePage(
                icon: Icons.auto_stories,
                title: "Learn Anywhere",
                description: "Access lessons from any device at any time.",
              ),
              WelcomePage(
                icon: Icons.rocket_launch,
                title: "Start Your Journey",
                description: "Ready to boost your skills? Let's go!",
              ),
            ],
          ),

          // Skip Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 20,
            child: TextButton(
              onPressed: _navigateToLogin,
              child: Text(
                "Skip",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),

          // Bottom Controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) => _buildDot(index)),
                    ),
                    const SizedBox(height: 24),
                    ElimuButton(
                      text: _currentPage == 2 ? "Get Started" : "Next",
                      onPressed: () {
                        if (_currentPage < 2) {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _navigateToLogin();
                        }
                      },
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

  Widget _buildDot(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 10,
      width: _currentPage == index ? 20 : 10,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? AppColors.accentCoral
            : Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}

class WelcomePage extends StatefulWidget {
  final IconData? icon;
  final String? imagePath;
  final String title;
  final String description;

  const WelcomePage({
    super.key,
    this.icon,
    this.imagePath,
    required this.title,
    required this.description,
  });

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildAnimatedWidget(Widget child, Interval interval) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _controller, curve: interval),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _controller, curve: interval)),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget topWidget;

    if (widget.imagePath != null) {
      topWidget = Image.asset(
        widget.imagePath!,
        height: MediaQuery.of(context).size.height * 0.3,
        fit: BoxFit.contain,
      );
    } else {
      topWidget = Icon(
        widget.icon ?? Icons.school,
        size: 100,
        color: Colors.white,
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 180), // Added large bottom padding to avoid controls
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildAnimatedWidget(
            topWidget,
            const Interval(0.0, 0.6, curve: Curves.easeOut),
          ),
          const SizedBox(height: 32),
          _buildAnimatedWidget(
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Interval(0.2, 0.8, curve: Curves.easeOut),
          ),
          const SizedBox(height: 16),
          _buildAnimatedWidget(
            Text(
              widget.description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const Interval(0.4, 1.0, curve: Curves.easeOut),
          ),
        ],
      ),
    );
  }
}
