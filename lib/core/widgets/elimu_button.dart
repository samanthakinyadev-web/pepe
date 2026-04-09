import 'package:flutter/material.dart';
import 'package:elimupepe/core/theme/app_theme.dart';

enum ElimuButtonType { primary, secondary, outline }

class ElimuButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final ElimuButtonType type;
  final IconData? icon;
  final bool isLoading;
  final double width;

  const ElimuButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = ElimuButtonType.primary,
    this.icon,
    this.isLoading = false,
    this.width = double.infinity,
  });

  @override
  State<ElimuButton> createState() => _ElimuButtonState();
}

class _ElimuButtonState extends State<ElimuButton> {
  bool _isPressed = false;

  Color get _backgroundColor {
    switch (widget.type) {
      case ElimuButtonType.primary:
        return AppColors.accentCoral;
      case ElimuButtonType.secondary:
        return AppColors.lightGreen;
      case ElimuButtonType.outline:
        return Colors.white;
    }
  }

  Color get _foregroundColor {
    switch (widget.type) {
      case ElimuButtonType.primary:
      case ElimuButtonType.secondary:
        return Colors.white;
      case ElimuButtonType.outline:
        return AppColors.brandGreen;
    }
  }

  Color get _borderColor {
    if (widget.type == ElimuButtonType.outline) {
      return AppColors.brandGreen.withValues(alpha: 0.3);
    }
    return Colors.transparent;
  }

  Color get _shadowColor {
    if (widget.type == ElimuButtonType.outline) {
      return Colors.transparent;
    }
    // Darken the background color for the bottom lip shadow
    final hsl = HSLColor.fromColor(_backgroundColor);
    final darker = hsl.withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0));
    return darker.toColor();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;

    return GestureDetector(
      onTapDown: isDisabled ? null : (_) => setState(() => _isPressed = true),
      onTapUp: isDisabled ? null : (_) => setState(() => _isPressed = false),
      onTapCancel: isDisabled ? null : () => setState(() => _isPressed = false),
      onTap: isDisabled ? null : widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: widget.width,
        height: 56, // Chunky height
        margin: EdgeInsets.only(top: _isPressed ? 4.0 : 0.0),
        decoration: BoxDecoration(
          color: isDisabled ? Colors.grey.shade400 : _backgroundColor,
          borderRadius: AppStyles.radiusMedium,
          border: widget.type == ElimuButtonType.outline
              ? Border.all(
                  color: isDisabled ? Colors.grey.shade400 : _borderColor,
                  width: 2,
                )
              : null,
          boxShadow:
              _isPressed || isDisabled || widget.type == ElimuButtonType.outline
              ? AppStyles.noShadow
              : [
                  BoxShadow(
                    color: _shadowColor,
                    blurRadius: 0,
                    offset: const Offset(0, 4), // The "chunky" 3D lip
                  ),
                ],
        ),
        child: Center(
          child: widget.isLoading
              ? SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: _foregroundColor,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: _foregroundColor, size: 22),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.text,
                      style: TextStyle(
                        color: _foregroundColor,
                        fontSize: 18,
                        fontWeight:
                            FontWeight.w800, // Extra bold for playfulness
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
