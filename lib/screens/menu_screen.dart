import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:loho_ebook_reader/models/menu_item.dart';
import 'package:loho_ebook_reader/screens/category_items_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = MenuItem.getDefaultMenuItems();

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Explore Menu',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0D47A1),
                  letterSpacing: -0.5,
                ),
              ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2),
              const SizedBox(height: 8),
              Text(
                'Discover more learning resources and activities.',
                style: TextStyle(fontSize: 16, color: Colors.blueGrey.shade600),
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
              const SizedBox(height: 24),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.82,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _MenuTile(
                        item: item,
                        onTap: item.isComingSoon
                            ? null
                            : () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        CategoryItemsScreen(menuItem: item),
                                  ),
                                );
                              },
                      )
                      .animate()
                      .fadeIn(delay: (100 * index).ms)
                      .scale(
                        begin: const Offset(0.9, 0.9),
                        duration: 400.ms,
                        curve: Curves.easeOutBack,
                      );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.item, this.onTap});

  final MenuItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDisabled = item.isComingSoon;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          splashColor: Colors.blue.withOpacity(0.1),
          highlightColor: Colors.blue.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDisabled
                        ? Colors.grey.shade100
                        : Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    item.icon,
                    style: TextStyle(
                      fontSize: 28,
                      color: isDisabled
                          ? Colors.blueGrey.shade300
                          : Colors.blue.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDisabled
                        ? Colors.blueGrey.shade400
                        : const Color(0xFF0D47A1),
                  ),
                ),
                if (isDisabled) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Coming Soon',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
