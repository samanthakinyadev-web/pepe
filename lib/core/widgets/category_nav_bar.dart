import 'package:elimupepe/models/menu_item.dart';
import 'package:flutter/material.dart';
import 'package:elimupepe/core/widgets/elimu_card.dart';
import 'package:elimupepe/core/theme/app_theme.dart';

class CategoryNavBar extends StatelessWidget {
  final Function(MenuItem) onItemTap;
  final bool isDrawer;

  const CategoryNavBar({
    super.key,
    required this.onItemTap,
    this.isDrawer = true,
  });

  @override
  Widget build(BuildContext context) {
    final menuItems = MenuItem.getDefaultMenuItems();

    final content = Column(
      children: [
        const SizedBox(height: 60),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Explore categories',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.brandGreen,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: menuItems.length,
            itemBuilder: (context, index) {
              final item = menuItems[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: ElimuCard(
                  padding: const EdgeInsets.all(4),
                  onTap: () {
                    if (isDrawer) {
                      Navigator.pop(context);
                    }
                    onItemTap(item);
                  },
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: item.isComingSoon
                            ? Colors.grey.shade100
                            : AppColors.lightGreen.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item.icon,
                        size: 18,
                        color: item.isComingSoon
                            ? Colors.grey.shade400
                            : AppColors.brandGreen,
                      ),
                    ),
                    title: Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: item.isComingSoon
                            ? Colors.grey.shade400
                            : AppColors.textMain,
                      ),
                    ),
                    trailing: item.isComingSoon
                        ? null
                        : const Icon(Icons.chevron_right_rounded, size: 18),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );

    if (isDrawer) {
      return Drawer(child: content);
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: 260, // Matches the slide translation of your drawer controller
        child: content,
      ),
    );
  }
}
