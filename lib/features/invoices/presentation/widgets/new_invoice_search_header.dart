import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class NewInvoiceSearchHeader extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onScanTap;

  const NewInvoiceSearchHeader({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onScanTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: AppStrings.searchProducts,
          prefixIcon: const Icon(LucideIcons.search),
          suffixIcon: IconButton(
            icon: const Icon(LucideIcons.scanLine),
            onPressed: onScanTap,
            color: AppColors.secondary,
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0,
            horizontal: 16,
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
