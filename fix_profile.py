import sys

with open('lib/features/profile/profile_screen.dart', 'r') as f:
    content = f.read()

# Add imports
if "elimu_button.dart" not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:elimupepe/core/widgets/elimu_button.dart';\nimport 'package:elimupepe/core/widgets/elimu_card.dart';")

# 1. Replace _buildStatCard body
old_stat_card = """    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column("""
new_stat_card = """    return ElimuCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column("""
content = content.replace(old_stat_card, new_stat_card)

# 2. Replace Subscription Plan Container
old_sub_card = """              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.lightGreen, AppColors.brandGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandGreen.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row("""
new_sub_card = """              ElimuCard(
                padding: const EdgeInsets.all(20),
                backgroundColor: AppColors.lightGreen,
                child: Row("""
content = content.replace(old_sub_card, new_sub_card)

# 3. Replace Message Card
old_msg_card = """    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnread
            ? AppColors.lightGreen.withValues(alpha: 0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnread
              ? AppColors.lightGreen.withValues(alpha: 0.3)
              : Colors.grey.shade200,
        ),
      ),
      child: Row("""
new_msg_card = """    return ElimuCard(
      padding: const EdgeInsets.all(16),
      backgroundColor: isUnread ? AppColors.lightGreen.withValues(alpha: 0.05) : Colors.white,
      child: Row("""
content = content.replace(old_msg_card, new_msg_card)

# 4. Replace Logout Button
old_logout = """              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _confirmLogout(context),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text(
                    'Logout',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.lightGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(
                        color: AppColors.lightGreen,
                        width: 2,
                      ),
                    ),
                    elevation: 0,
                  ),
                ),
              )"""
new_logout = """              ElimuButton(
                text: 'Logout',
                type: ElimuButtonType.outline,
                icon: Icons.logout_rounded,
                onPressed: () => _confirmLogout(context),
              )"""
content = content.replace(old_logout, new_logout)

with open('lib/features/profile/profile_screen.dart', 'w') as f:
    f.write(content)
