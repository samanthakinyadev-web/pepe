with open('lib/features/home/category_items_screen.dart', 'r') as f:
    content = f.read()

if "elimu_button.dart" not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:elimupepe/core/widgets/elimu_button.dart';\nimport 'package:elimupepe/core/widgets/elimu_card.dart';")

# 1. Replace retry ElevatedButton with ElimuButton
old_retry_btn = """                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _itemsFuture = LearnerDashboardApiService.instance
                            .fetchMenuItems(menuId: widget.menuItem.id);
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lightGreen,
                      foregroundColor: Colors.white,
                    ),
                  ),"""
new_retry_btn = """                  ElimuButton(
                    text: 'Retry',
                    icon: Icons.refresh,
                    width: 150,
                    onPressed: () {
                      setState(() {
                        _itemsFuture = LearnerDashboardApiService.instance
                            .fetchMenuItems(menuId: widget.menuItem.id);
                      });
                    },
                  ),"""
content = content.replace(old_retry_btn, new_retry_btn)

# 2. Replace Card with ElimuCard in ListView.builder
old_card = """            return Card(
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile("""
new_card = """            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ElimuCard(
                padding: const EdgeInsets.all(4),
                child: ListTile("""
content = content.replace(old_card, new_card)

# Close ElimuCard and Padding
content = content.replace("""),
              ),
            );
          },""", """),
              ),
            );
          },""") # No change needed here if matching correctly, but let's check closing braces

with open('lib/features/home/category_items_screen.dart', 'w') as f:
    f.write(content)
