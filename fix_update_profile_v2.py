with open('lib/features/profile/update_profile_screen.dart', 'r') as f:
    content = f.read()

# 1. Replace Save Changes Button
old_save_btn = """              SizedBox(
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
                  onPressed: _saveProfile,
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),"""
new_save_btn = """              ElimuButton(
                text: 'Save Changes',
                onPressed: _saveProfile,
              ),"""
content = content.replace(old_save_btn, new_save_btn)

# 2. Replace Delete Button in dialog
old_delete_btn = """          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lightGreen,
            ),
            onPressed: () {
              // TODO: Implement account deletion logic
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Account deleted.')));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),"""
new_delete_btn = """          ElimuButton(
            text: 'Delete',
            width: 120,
            onPressed: () {
              // TODO: Implement account deletion logic
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Account deleted.')));
            },
          ),"""
content = content.replace(old_delete_btn, new_delete_btn)

with open('lib/features/profile/update_profile_screen.dart', 'w') as f:
    f.write(content)
