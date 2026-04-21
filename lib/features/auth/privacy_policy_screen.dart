import 'package:flutter/material.dart';
import 'package:elimupepe/core/theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF0F8FF),
        foregroundColor: AppColors.brandGreen,
        title: const Text(
          'Privacy Policy',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Policy',
              style: TextStyle(fontSize: 28, color: AppColors.brandGreen),
            ),
            const SizedBox(height: 12),
            Container(
              height: 4,
              width: 60,
              decoration: BoxDecoration(
                color: AppColors.lightGreen,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _buildInfoCard(
              context,
              'Effective Date: April 8, 2026\nLast Updated: April 8, 2026',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '1. Introduction',
              'Loho Learning Ltd ("we", "us", or "our") operates the Elimu Pepe mobile application (the "App"). This Privacy Policy explains how we collect, use, disclose, and protect information about users of our App, including parents, guardians, and children.\n\nElimu Pepe is an educational platform designed to support Kenya\'s Competency Based Curriculum (CBC). Our App is intended for use by learners of all ages, including children under the age of 13, under parental or guardian supervision.',
            ),
            _buildSection(
              '2. Information We Collect',
              'We collect the following categories of information:\n\n'
                  '• Full name and profile information (parent/guardian or learner)\n'
                  '• Profile photos and images (if you choose to upload a custom avatar)\n'
                  '• Phone number (used for Safaricom carrier billing / subscription authentication)\n'
                  '• School name and grade/class level\n'
                  '• Account credentials (username and password)\n'
                  '• Device information: type, OS version, unique identifiers\n'
                  '• Learning progress and quiz scores\n'
                  '• App usage data and error logs',
            ),
            _buildSection(
              '3. How We Use Your Information',
              'We use the information we collect to:\n\n'
                  '• Create and manage your account\n'
                  '• Process and verify your Safaricom subscription\n'
                  '• Personalise the learning experience based on grade level\n'
                  '• Track and display achievements and leaderboard rankings\n'
                  '• Improve App performance and ensure platform safety\n\n'
                  'We do NOT sell your personal data or use it for targeted advertising within the App.',
            ),
            _buildSection(
              '4. Children\'s Privacy (Under 13)',
              'Elimu Pepe is an educational platform designed for learners, including children under 13. We are committed to protecting their privacy in compliance with the Google Play Families Policy and COPPA.\n\n'
                  '• Account Creation: Accounts cannot be created within the mobile app. All learner accounts must be created and managed by a parent or guardian via our secure web platform.\n'
                  '• Parental Control: Parents/guardians have full control over the child\'s profile and can monitor progress or delete the account at any time through the web dashboard.\n'
                  '• Minimal Data: We collect only the minimum data necessary for educational purposes (name, grade, and learning progress).\n'
                  '• Safety: No behavioural or targeted advertising is served to children within the App.',
            ),
            _buildSection(
              '5. Data Deletion',
              'You have the right to delete your account and all associated data at any time. You can do this directly within the app by navigating to Profile -> Update Profile -> Delete Account. This action is permanent and will remove all your personal data, progress, and history.',
            ),
            _buildSection(
              '6. Contact Us',
              'If you have any questions about this privacy policy, please contact us:\n\n'
                  'Email: support@loholearning.co.ke\n'
                  'Address: Loho Learning Ltd, Funzi Road, Industrial Area, Nairobi, Kenya\n'
                  'Phone: +254 797 349 396',
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.blueGrey,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
