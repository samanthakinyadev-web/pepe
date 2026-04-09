with open('lib/features/profile/update_profile_screen.dart', 'r') as f:
    content = f.read()

# Add imports
if "elimu_button.dart" not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:elimupepe/core/widgets/elimu_button.dart';\nimport 'package:elimupepe/core/widgets/elimu_text_field.dart';")

# 1. Replace Name field
old_name = """              _buildTextField(
                label: 'Full Name',
                controller: _nameController,
                icon: Icons.person_outline_rounded,
              ),"""
new_name = """              ElimuTextField(
                label: 'Full Name',
                hint: 'Enter your full name',
                controller: _nameController,
                icon: Icons.person_outline_rounded,
              ),"""
content = content.replace(old_name, new_name)

# 2. Replace Email field
old_email = """              _buildTextField(
                label: 'Email Address',
                controller: _emailController,
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),"""
new_email = """              ElimuTextField(
                label: 'Email Address',
                hint: 'Enter your email',
                controller: _emailController,
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),"""
content = content.replace(old_email, new_email)

# 3. Replace About field
old_about = """              _buildTextField(
                label: 'Bio / About',
                controller: _aboutController,
                icon: Icons.info_outline_rounded,
                maxLines: 3,
              ),"""
new_about = """              ElimuTextField(
                label: 'Bio / About',
                hint: 'Tell us about yourself',
                controller: _aboutController,
                icon: Icons.info_outline_rounded,
              ),"""
content = content.replace(old_about, new_about)

# 4. Replace Extra field
old_extra = """              _buildTextField(
                label: 'Extra Details',
                controller: _extraController,
                icon: Icons.star_border_rounded,
              ),"""
new_extra = """              ElimuTextField(
                label: 'Extra Details',
                hint: 'Add any extra info',
                controller: _extraController,
                icon: Icons.star_border_rounded,
              ),"""
content = content.replace(old_extra, new_extra)

# 5. Replace Save button
old_save = """              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lightGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  onPressed: _isSaving ? null : _saveProfile,
                  child: _isSaving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              )"""
new_save = """              ElimuButton(
                text: 'Save Changes',
                isLoading: _isSaving,
                onPressed: _saveProfile,
              )"""
content = content.replace(old_save, new_save)

# 6. Delete _buildTextField method
old_build_tf = """  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label cannot be empty';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: maxLines == 1 ? Icon(icon, color: Colors.blueGrey) : null,
        alignLabelWithHint: true,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
    );
  }"""
content = content.replace(old_build_tf, "")

with open('lib/features/profile/update_profile_screen.dart', 'w') as f:
    f.write(content)
