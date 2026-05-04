import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class OnboardingTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? action;
  final TextAlign textAlign;
  final void Function(String)? onSubmitted;
  final void Function(String)? onChanged;

  const OnboardingTextField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.action,
    this.textAlign = TextAlign.start,
    this.onSubmitted,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: action,
      textAlign: textAlign,
      onFieldSubmitted: onSubmitted,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: AppColors.white,
        floatingLabelStyle: const TextStyle(color: AppColors.secondary),
        prefixIconColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.focused)
              ? AppColors.secondary
              : AppColors.grey,
        ),
      ),
    );
  }
}
