import re

with open('lib/features/auth/login_screen.dart', 'r') as f:
    content = f.read()

# 1. Add imports
imports = """import 'package:elimupepe/core/widgets/elimu_button.dart';
import 'package:elimupepe/core/widgets/elimu_text_field.dart';
"""
if "elimu_button.dart" not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\n" + imports)

# 2. Replace _buildInputField usages with ElimuTextField
content = re.sub(
    r'_buildInputField\(\s*icon:\s*(.*?),\s*label:\s*(.*?),\s*hint:\s*(.*?),\s*controller:\s*(.*?),\s*keyboardType:\s*(.*?),\s*validator:\s*(\(value\)\s*\{.*?\}(?:\s*,\s*)?)\s*\)',
    r'''ElimuTextField(
  icon: \1,
  label: \2,
  hint: \3,
  controller: \4,
  keyboardType: \5,
  validator: \6
)''',
    content,
    flags=re.DOTALL
)

content = re.sub(
    r'_buildInputField\(\s*icon:\s*(.*?),\s*label:\s*(.*?),\s*hint:\s*(.*?),\s*controller:\s*(.*?),\s*isPassword:\s*(.*?),\s*validator:\s*(\(value\)\s*\{.*?\}(?:\s*,\s*)?)\s*\)',
    r'''ElimuTextField(
  icon: \1,
  label: \2,
  hint: \3,
  controller: \4,
  isPassword: \5,
  validator: \6
)''',
    content,
    flags=re.DOTALL
)

# 3. Replace ElevatedButton with ElimuButton
content = re.sub(
    r'SizedBox\(\s*width: double\.infinity,\s*height: 52,\s*child: ElevatedButton\(.*?\),\s*\)',
    r"ElimuButton(text: 'Login', isLoading: _isLoading, onPressed: _handleLogin)",
    content,
    flags=re.DOTALL
)

# 4. Remove _buildInputField definition
content = re.sub(
    r'Widget _buildInputField\(\{.*?\}\)\s*\{\s*return Column\(.*?\}\);?\s*\}\s*\}\s*$',
    r'}\n',
    content,
    flags=re.DOTALL
)

with open('lib/features/auth/login_screen.dart', 'w') as f:
    f.write(content)
