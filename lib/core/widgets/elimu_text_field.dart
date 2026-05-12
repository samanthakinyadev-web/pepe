import 'package:flutter/material.dart';
import 'package:elimupepe/core/theme/app_theme.dart';

class ElimuTextField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool isPassword;
  final bool autofocus;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;

  const ElimuTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.focusNode,
    this.isPassword = false,
    this.autofocus = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.validator,
    this.onFieldSubmitted,
  });

  @override
  State<ElimuTextField> createState() => _ElimuTextFieldState();
}

class _ElimuTextFieldState extends State<ElimuTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onFieldSubmitted,
          obscureText: widget.isPassword ? _obscureText : false,
          validator: widget.validator,
          style: const TextStyle(
            color: AppColors.textMain,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(
              widget.icon,
              color: Colors.grey.shade400,
              size: 24,
            ),
            suffixIcon: widget.isPassword
                ? IconButton(
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                    icon: Icon(
                      _obscureText
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: Colors.grey.shade400,
                      size: 22,
                    ),
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
            // Thick, playful borders
            border: OutlineInputBorder(
              borderRadius: AppStyles.radiusMedium,
              borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppStyles.radiusMedium,
              borderSide: BorderSide(color: Colors.grey.shade200, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppStyles.radiusMedium,
              borderSide: const BorderSide(
                color: AppColors.accentYellow,
                width: 3,
              ), // Popping focus color
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: AppStyles.radiusMedium,
              borderSide: const BorderSide(
                color: AppColors.accentCoral,
                width: 2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: AppStyles.radiusMedium,
              borderSide: const BorderSide(
                color: AppColors.accentCoral,
                width: 3,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
