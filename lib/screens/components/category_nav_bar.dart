import '../../models/menu_item.dart';
import 'package:flutter/material.dart';
import 'package:loho_ebook_reader/theme/app_theme.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
        DrawerHeader(
          decoration: const BoxDecoration(color: AppColors.surfaceGray),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 15),
                const Text(
                  'All Categories',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandGreen,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: menuItems.length,
            itemBuilder: (context, index) {
              final item = menuItems[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 4,
                ),
                leading: Container(
                  width: 42,
                  height: 42,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: item.isComingSoon
                        ? Colors.grey.shade200
                        : AppColors.lightGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: FaIcon(
                      item.icon,
                      size: 18,
                      color: item.isComingSoon
                          ? Colors.grey.shade500
                          : AppColors.brandGreen,
                    ),
                  ),
                ),
                title: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: item.isComingSoon
                        ? Colors.grey.shade600
                        : Colors.black87,
                  ),
                ),
                trailing: item.isComingSoon
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Soon',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.chevron_right,
                        color: Color(0xFF5C6F8A),
                        size: 20,
                      ),
                onTap: () {
                  if (isDrawer) {
                    Navigator.pop(context); // Close the drawer
                  }
                  onItemTap(item);
                },
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
