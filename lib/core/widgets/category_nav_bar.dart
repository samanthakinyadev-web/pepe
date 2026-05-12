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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 220;
        final topSpacing = isCompact ? 12.0 : 60.0;
        final titleFontSize = isCompact ? 18.0 : 26.0;
        final titleBottomSpacing = isCompact ? 10.0 : 20.0;
        final horizontalTitlePadding = isCompact ? 16.0 : 24.0;
        final itemVerticalPadding = isCompact ? 4.0 : 6.0;
        final itemIconSize = isCompact ? 16.0 : 18.0;
        final itemTitleFontSize = isCompact ? 13.0 : 15.0;

        if (isDrawer) {
          return Drawer(
            child: isCompact
                ? _buildCompactContent(
                    menuItems: menuItems,
                    topSpacing: topSpacing,
                    titleFontSize: titleFontSize,
                    titleBottomSpacing: titleBottomSpacing,
                    horizontalTitlePadding: horizontalTitlePadding,
                    itemVerticalPadding: itemVerticalPadding,
                    itemIconSize: itemIconSize,
                    itemTitleFontSize: itemTitleFontSize,
                    isCompact: isCompact,
                    onItemTap: onItemTap,
                    onClose: () => Navigator.pop(context),
                  )
                : _buildExpandedContent(
                    menuItems: menuItems,
                    topSpacing: topSpacing,
                    titleFontSize: titleFontSize,
                    titleBottomSpacing: titleBottomSpacing,
                    horizontalTitlePadding: horizontalTitlePadding,
                    itemVerticalPadding: itemVerticalPadding,
                    itemIconSize: itemIconSize,
                    itemTitleFontSize: itemTitleFontSize,
                    isCompact: isCompact,
                    onItemTap: onItemTap,
                    onClose: () => Navigator.pop(context),
                  ),
          );
        }

        return Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width:
                260, // Matches the slide translation of your drawer controller
            child: isCompact
                ? _buildCompactContent(
                    menuItems: menuItems,
                    topSpacing: topSpacing,
                    titleFontSize: titleFontSize,
                    titleBottomSpacing: titleBottomSpacing,
                    horizontalTitlePadding: horizontalTitlePadding,
                    itemVerticalPadding: itemVerticalPadding,
                    itemIconSize: itemIconSize,
                    itemTitleFontSize: itemTitleFontSize,
                    isCompact: isCompact,
                    onItemTap: onItemTap,
                    onClose: () {},
                  )
                : _buildExpandedContent(
                    menuItems: menuItems,
                    topSpacing: topSpacing,
                    titleFontSize: titleFontSize,
                    titleBottomSpacing: titleBottomSpacing,
                    horizontalTitlePadding: horizontalTitlePadding,
                    itemVerticalPadding: itemVerticalPadding,
                    itemIconSize: itemIconSize,
                    itemTitleFontSize: itemTitleFontSize,
                    isCompact: isCompact,
                    onItemTap: onItemTap,
                    onClose: () {},
                  ),
          ),
        );
      },
    );
  }

  Widget _buildCompactContent({
    required List<MenuItem> menuItems,
    required double topSpacing,
    required double titleFontSize,
    required double titleBottomSpacing,
    required double horizontalTitlePadding,
    required double itemVerticalPadding,
    required double itemIconSize,
    required double itemTitleFontSize,
    required bool isCompact,
    required Function(MenuItem) onItemTap,
    required VoidCallback onClose,
  }) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        SizedBox(height: topSpacing),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalTitlePadding),
          child: Text(
            'Explore categories',
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
              color: AppColors.brandGreen,
            ),
          ),
        ),
        SizedBox(height: titleBottomSpacing),
        ...menuItems.map(
          (item) => Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: itemVerticalPadding,
            ),
            child: ElimuCard(
              padding: const EdgeInsets.all(4),
              onTap: () {
                onClose();
                onItemTap(item);
              },
              child: ListTile(
                dense: isCompact,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                leading: Container(
                  width: isCompact ? 34 : 40,
                  height: isCompact ? 34 : 40,
                  decoration: BoxDecoration(
                    color: item.isComingSoon
                        ? Colors.grey.shade100
                        : AppColors.lightGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item.icon,
                    size: itemIconSize,
                    color: item.isComingSoon
                        ? Colors.grey.shade400
                        : AppColors.brandGreen,
                  ),
                ),
                title: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: itemTitleFontSize,
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
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedContent({
    required List<MenuItem> menuItems,
    required double topSpacing,
    required double titleFontSize,
    required double titleBottomSpacing,
    required double horizontalTitlePadding,
    required double itemVerticalPadding,
    required double itemIconSize,
    required double itemTitleFontSize,
    required bool isCompact,
    required Function(MenuItem) onItemTap,
    required VoidCallback onClose,
  }) {
    return Column(
      children: [
        SizedBox(height: topSpacing),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalTitlePadding),
          child: Text(
            'Explore categories',
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
              color: AppColors.brandGreen,
            ),
          ),
        ),
        SizedBox(height: titleBottomSpacing),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: menuItems.length,
            itemBuilder: (context, index) {
              final item = menuItems[index];
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: itemVerticalPadding,
                ),
                child: ElimuCard(
                  padding: const EdgeInsets.all(4),
                  onTap: () {
                    onClose();
                    onItemTap(item);
                  },
                  child: ListTile(
                    dense: isCompact,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    leading: Container(
                      width: isCompact ? 34 : 40,
                      height: isCompact ? 34 : 40,
                      decoration: BoxDecoration(
                        color: item.isComingSoon
                            ? Colors.grey.shade100
                            : AppColors.lightGreen.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item.icon,
                        size: itemIconSize,
                        color: item.isComingSoon
                            ? Colors.grey.shade400
                            : AppColors.brandGreen,
                      ),
                    ),
                    title: Text(
                      item.title,
                      style: TextStyle(
                        fontSize: itemTitleFontSize,
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
  }
}
