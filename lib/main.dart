import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:elimupepe/firebase_options.dart';
import 'package:elimupepe/core/theme/app_theme.dart';
import 'package:elimupepe/features/auth/auth_gate.dart';
import 'package:elimupepe/core/theme/app_page_transitions.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with the generated options
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // Lock orientation to portrait for a better, more consistent experience for kids
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const SecureElimupepeApp());
}

class SecureElimupepeApp extends StatelessWidget {
  const SecureElimupepeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Elimu Pepe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.brandGreen,
          primary: AppColors.brandGreen,
          secondary: AppColors.lightGreen,
        ),
        pageTransitionsTheme: AppPageTransitions.theme,
        scaffoldBackgroundColor: AppColors.surfaceGray,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.brandGreen,
          foregroundColor: AppColors.textLight,
        ),
      ),
      home: const AuthGate(),
    );
  }
}
