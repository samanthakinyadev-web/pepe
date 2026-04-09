import re

with open('lib/features/profile/profile_screen.dart', 'r') as f:
    content = f.read()

imports = """import 'package:elimupepe/core/widgets/elimu_button.dart';
import 'package:elimupepe/core/widgets/elimu_card.dart';
"""
if "elimu_button.dart" not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\n" + imports)

# Replace Stat Card Container with ElimuCard
content = re.sub(
    r'Container\(\s*padding: const EdgeInsets\.symmetric\(horizontal: 20,\s*vertical: 16\),\s*decoration: BoxDecoration\(.*?borderRadius: BorderRadius\.circular\(20\).*?\]\s*,\s*\),\s*child:',
    r'ElimuCard(\n      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),\n      child:',
    content,
    flags=re.DOTALL
)

# Replace Subscription Plan Container with ElimuCard
content = re.sub(
    r'Container\(\s*padding: const EdgeInsets\.all\(20\),\s*decoration: BoxDecoration\(\s*gradient: const LinearGradient\(.*?\]\s*,\s*\),\s*child:',
    r'ElimuCard(\n                padding: const EdgeInsets.all(20),\n                backgroundColor: AppColors.lightGreen,\n                child:',
    content,
    flags=re.DOTALL
)

# Replace Message Card Container with ElimuCard
content = re.sub(
    r'Container\(\s*padding: const EdgeInsets\.all\(16\),\s*decoration: BoxDecoration\(\s*color: isUnread.*?border: Border\.all\(.*?\s*,\s*\),\s*\),\s*child:',
    r'ElimuCard(\n      padding: const EdgeInsets.all(16),\n      backgroundColor: isUnread ? AppColors.lightGreen.withOpacity(0.05) : Colors.white,\n      child:',
    content,
    flags=re.DOTALL
)

# Replace Logout Button
content = re.sub(
    r'ElevatedButton\.icon\(\s*onPressed: \(\) => _confirmLogout\(context\),\s*icon: const Icon\(Icons\.logout_rounded\),\s*label: const Text\(\s*\'Logout\'.*?\),\s*style: ElevatedButton\.styleFrom\(.*?\),\s*\)',
    r"ElimuButton(text: 'Logout', type: ElimuButtonType.outline, icon: Icons.logout_rounded, onPressed: () => _confirmLogout(context))",
    content,
    flags=re.DOTALL
)

with open('lib/features/profile/profile_screen.dart', 'w') as f:
    f.write(content)
