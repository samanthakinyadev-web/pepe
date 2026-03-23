import 'login_screen.dart';
import './home_screen.dart';
import '../../theme/app_theme.dart';
import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 0.1);
          const end = Offset.zero;
          const curve = Curves.easeOut;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: animation.drive(tween),
              child: child,
            ),
          );
        },
        transitionDuration: Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
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
                style: TextStyle(color: AppColors.lightGreen, fontSize: 16),
              ),
            ),
          ),

          // Bottom Controls
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) => _buildDot(index)),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    if (_currentPage < 2) {
                      _controller.nextPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _navigateToLogin();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: AppColors.accentCoral,
                  ),
                  child: Text(
                    _currentPage == 2 ? "Get Started" : "Next",
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
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
            : Colors.grey.shade300,
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
        height: MediaQuery.of(context).size.height * 0.35,
        fit: BoxFit.contain,
      );
    } else {
      topWidget = Icon(
        widget.icon ?? Icons.school,
        size: 100,
        color: AppColors.brandGreen,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
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
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const Interval(0.2, 0.8, curve: Curves.easeOut),
          ),
          const SizedBox(height: 16),
          _buildAnimatedWidget(
            Text(
              widget.description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const Interval(0.4, 1.0, curve: Curves.easeOut),
          ),
        ],
      ),
    );
  }
}
