import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:elimupepe/features/auth/welcome_screen.dart';
import 'package:elimupepe/features/home/dashboard_screen.dart';
import 'package:elimupepe/features/parental_control/parent_dashboard.dart';
import 'package:elimupepe/features/teacher/teacher_dashboard.dart';
import 'package:elimupepe/core/services/auth_service.dart';
import 'package:elimupepe/core/theme/app_theme.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Widget? _home;

  @override
  void initState() {
    super.initState();
    _resolveHome();
  }

  Future<void> _resolveHome() async {
    try {
      final auth = AuthService.instance;
      final loggedIn = await auth.isLoggedIn();

      if (!loggedIn) {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
        if (mounted) {
          setState(() => _home = const WelcomeScreen());
        }
        return;
      }

      int? roleId = await auth.getSavedRoleId();
      String? roleName = await auth.getSavedRoleName();

      if (roleId == null && (roleName == null || roleName.isEmpty)) {
        final user = await auth.getCurrentUser();
        roleId = _extractRoleId(user);
        roleName = _extractRoleName(user);
      }

      final destination = _routeForRole(roleId, roleName);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      if (mounted) {
        setState(() => _home = destination);
      }
    } catch (_) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      if (mounted) {
        setState(() => _home = const WelcomeScreen());
      }
    }
  }

  int? _extractRoleId(Map<String, dynamic> user) {
    final roleRaw = user['role_id'] ?? user['roleId'];
    if (roleRaw is int) return roleRaw;
    if (roleRaw is String) return int.tryParse(roleRaw);
    return null;
  }

  String? _extractRoleName(Map<String, dynamic> user) {
    final direct = user['role_name'] ?? user['roleName'] ?? user['role'];
    if (direct is String && direct.trim().isNotEmpty) {
      return direct.trim().toLowerCase();
    }
    if (direct is Map<String, dynamic>) {
      final nested =
          direct['name'] ??
          direct['slug'] ??
          direct['title'] ??
          direct['label'];
      if (nested is String && nested.trim().isNotEmpty) {
        return nested.trim().toLowerCase();
      }
    }
    final type = user['role_type'] ?? user['roleType'];
    if (type is String && type.trim().isNotEmpty) {
      return type.trim().toLowerCase();
    }
    return null;
  }

  Widget _routeForRole(int? roleId, String? roleName) {
    if (roleId == 2 || roleName == 'teacher' || roleName == 'educator') {
      return const TeacherDashboard();
    }

    if (roleId == 7 || roleName == 'parent' || roleName == 'guardian') {
      return const ParentDashboard();
    }

    return const GamifiedDashboardScreen(
      initialIndex: 0,
      restoreLastTab: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_home == null) {
      return const Scaffold(
        backgroundColor: AppColors.surfaceGray,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppColors.brandGreen),
          ),
        ),
      );
    }

    return _home!;
  }
}
