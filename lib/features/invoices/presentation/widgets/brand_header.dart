import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/models/app_settings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/bento_theme_extension.dart';

class BrandHeader extends StatelessWidget {
  final AppSettings settings;

  const BrandHeader({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    final bento = Theme.of(context).extension<BentoThemeExtension>()!;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: bento.cardDecoration.copyWith(
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          if (settings.logoPath != null && settings.logoPath!.isNotEmpty) ...[
            Container(
              width: 70,
              height: 70,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: Image.file(File(settings.logoPath!), fit: BoxFit.contain),
              ),
            ),
            const Gap(AppSpacing.md),
          ],
          Text(
            settings.brandName,
            style: AppTypography.h2.copyWith(color: AppColors.text, fontSize: 20),
            textAlign: TextAlign.center,
          ),
          const Gap(AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (settings.phone.isNotEmpty) ...[
                const Icon(LucideIcons.phone, size: 12, color: AppColors.grey),
                const Gap(4),
                Text(settings.phone, style: AppTypography.bodySm.copyWith(color: AppColors.greyDark)),
              ],
              if (settings.phone.isNotEmpty && settings.address.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text('|', style: TextStyle(color: AppColors.grey.withValues(alpha: 0.3))),
                ),
              if (settings.address.isNotEmpty) ...[
                const Icon(LucideIcons.mapPin, size: 12, color: AppColors.grey),
                const Gap(4),
                Flexible(
                  child: Text(
                    settings.address,
                    style: AppTypography.bodySm.copyWith(color: AppColors.greyDark),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
