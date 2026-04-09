import 'package:flutter/material.dart';
import 'package:elimupepe/core/theme/app_theme.dart';

class ElimuCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;

  const ElimuCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: AppStyles.radiusLarge,
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 2)
            : Border.all(
                color: AppColors.darkGray.withValues(alpha: 0.2),
                width: 1.5,
              ),
        boxShadow: AppStyles.playfulShadow,
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: cardContent);
    }

    return cardContent;
  }
}
