import re

with open('lib/features/profile/update_profile_screen.dart', 'r') as f:
    content = f.read()

imports = """import 'package:elimupepe/core/widgets/elimu_button.dart';
import 'package:elimupepe/core/widgets/elimu_text_field.dart';
"""
if "elimu_button.dart" not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\n" + imports)

# Replace Save Changes Button
content = re.sub(
    r'SizedBox\(\s*width: double\.infinity,\s*height: 55,\s*child: ElevatedButton\(.*?\),\s*\)',
    r"ElimuButton(text: 'Save Changes', isLoading: _isSaving, onPressed: _saveProfile)",
    content,
    flags=re.DOTALL
)

# Replace _buildTextField calls with ElimuTextField
# Since ElimuTextField doesn't have maxLines right now, we'll just ignore it or map it to ElimuTextField and add maxLines to ElimuTextField if we had it. But since it's just Python regex, we can match and map.
content = re.sub(
    r"_buildTextField\(\s*label:\s*'(.*?)',\s*controller:\s*(.*?),\s*icon:\s*(.*?),\s*\)",
    r'''ElimuTextField(
                label: '\1',
                hint: 'Enter \1',
                controller: \2,
                icon: \3,
              )''',
    content
)

content = re.sub(
    r"_buildTextField\(\s*label:\s*'(.*?)',\s*controller:\s*(.*?),\s*icon:\s*(.*?),\s*keyboardType:\s*(.*?),\s*\)",
    r'''ElimuTextField(
                label: '\1',
                hint: 'Enter \1',
                controller: \2,
                icon: \3,
                keyboardType: \4,
              )''',
    content
)

content = re.sub(
    r"_buildTextField\(\s*label:\s*'(.*?)',\s*controller:\s*(.*?),\s*icon:\s*(.*?),\s*maxLines:\s*(.*?),\s*\)",
    r'''ElimuTextField(
                label: '\1',
                hint: 'Enter \1',
                controller: \2,
                icon: \3,
              )''',
    content
)

with open('lib/features/profile/update_profile_screen.dart', 'w') as f:
    f.write(content)
