with open('lib/core/widgets/category_nav_bar.dart', 'r') as f:
    content = f.read()

if "elimu_card.dart" not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:elimupepe/core/widgets/elimu_card.dart';")

# 1. Update DrawerHeader
old_header = """        DrawerHeader(
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
        ),"""
new_header = """        const SizedBox(height: 60),
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
        const SizedBox(height: 20),"""
content = content.replace(old_header, new_header)

# 2. Replace ListTile with ElimuCard wrapper
old_list_item = """              return ListTile(
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
              );"""
new_list_item = """              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                            : AppColors.lightGreen.withOpacity(0.1),
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
              );"""
content = content.replace(old_list_item, new_list_item)

with open('lib/core/widgets/category_nav_bar.dart', 'w') as f:
    f.write(content)
