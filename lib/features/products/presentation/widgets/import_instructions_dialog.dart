import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

import '../../../../core/constants/app_strings.dart';

class ImportInstructionsDialog extends StatelessWidget {
  const ImportInstructionsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
      backgroundColor: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.info, color: AppColors.secondary, size: 28),
                const Gap(AppSpacing.md),
                Text(
                  AppStrings.instructions,
                  style: AppTypography.h2.copyWith(fontSize: 22),
                ),
              ],
            ),
            const Gap(AppSpacing.xl),
            Text(
              AppStrings.importExcelDesc,
              style: AppTypography.bodyMd.copyWith(color: AppColors.greyDark),
            ),
            const Gap(AppSpacing.lg),
            _buildColumnInfo(AppStrings.columnName, AppStrings.columnNameType),
            _buildColumnInfo(AppStrings.columnCode, AppStrings.columnCodeType),
            _buildColumnInfo(AppStrings.columnPrice, AppStrings.columnPriceType),
            const Gap(AppSpacing.xl),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.primary.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.circleAlert, size: 16, color: AppColors.warning),
                  const Gap(AppSpacing.sm),
                  Expanded(
                    child: Text(
                      AppStrings.importHeaderSkip,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.text,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Gap(AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(AppStrings.pickExcelFile),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColumnInfo(String title, String type) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w600)),
          Text(type, style: AppTypography.bodySm.copyWith(color: AppColors.secondary)),
        ],
      ),
    );
  }
}
