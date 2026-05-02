import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class InvoiceEmptyState extends StatelessWidget {
  const InvoiceEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.fileX2,
            size: 64,
            color: AppColors.grey.withValues(alpha: 0.5),
          ),
          const Gap(AppSpacing.lg),
          Text(
            'No invoices found.',
            style: AppTypography.bodyMd.copyWith(color: AppColors.grey),
          ),
          const Gap(AppSpacing.sm),
          Text(
            'Tap + to create your first invoice.',
            style: AppTypography.bodySm.copyWith(color: AppColors.grey),
          ),
        ],
      ),
    );
  }
}
