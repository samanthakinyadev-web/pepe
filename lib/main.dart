import 'screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:loho_ebook_reader/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const SecureEbookReaderApp());
}

class SecureEbookReaderApp extends StatelessWidget {
  const SecureEbookReaderApp({super.key});

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
        scaffoldBackgroundColor: AppColors.surfaceGray,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.brandGreen,
          foregroundColor: AppColors.textLight,
        ),
      ),
      home: WelcomeScreen(),
    );
  }
}
