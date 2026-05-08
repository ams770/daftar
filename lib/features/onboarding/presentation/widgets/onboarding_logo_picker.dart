import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class OnboardingLogoPicker extends StatelessWidget {
  final String? logoPath;
  final String? logoFileName;
  final VoidCallback onTap;

  const OnboardingLogoPicker({
    super.key,
    this.logoPath,
    this.logoFileName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: AlignmentDirectional.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: logoFileName != null
                    ? AppColors.secondary
                    : AppColors.greyLight,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
              image: logoPath != null && File(logoPath!).existsSync()
                  ? DecorationImage(
                      image: FileImage(File(logoPath!)),
                      fit: BoxFit.contain,
                    )
                  : null,
            ),
            child: logoPath == null
                ? Column(
                    mainAxisAlignment: .center,
                    children: [
                      const Icon(
                        LucideIcons.camera,
                        color: AppColors.grey,
                        size: 32,
                      ),
                      const Gap(AppSpacing.xs),
                      Text(
                        AppStrings.addLogo,
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.grey,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                : null,
          ),
          if (logoFileName != null)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.check,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            )
          else
            Positioned(
              bottom: -10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  AppStrings.addLogoHint,
                  style: AppTypography.bodySm.copyWith(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
