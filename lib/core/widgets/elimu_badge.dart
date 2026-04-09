import 'package:flutter/material.dart';
import 'package:elimupepe/core/theme/app_theme.dart';

class ElimuBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String? label;
  final String? value;

  const ElimuBadge({
    super.key,
    required this.icon,
    required this.color,
    this.label,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
          ),
          child: Icon(icon, color: color, size: 36),
        ),
        if (value != null || label != null) const SizedBox(height: 8),
        if (value != null)
          Text(
            value!,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
        if (label != null)
          Text(
            label!,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}
