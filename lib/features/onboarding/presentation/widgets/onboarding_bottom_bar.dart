import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class OnboardingBottomBar extends StatelessWidget {
  final int currentPage;
  final bool isCurrentPageValid;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const OnboardingBottomBar({
    super.key,
    required this.currentPage,
    required this.isCurrentPageValid,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (currentPage > 0)
              IconButton(
                onPressed: onPrevious,
                icon: const Icon(LucideIcons.arrowLeft),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.secondary,
                  padding: const EdgeInsets.all(AppSpacing.md),
                ),
              ),
            const Gap(AppSpacing.md),
            Expanded(
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  gradient: isCurrentPageValid
                      ? const LinearGradient(
                          colors: AppColors.secondaryGradient,
                        )
                      : null,
                  color: isCurrentPageValid ? null : AppColors.greyLight,
                  boxShadow: isCurrentPageValid
                      ? [
                          BoxShadow(
                            color: AppColors.secondary.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : [],
                ),
                child: ElevatedButton(
                  onPressed: isCurrentPageValid ? onNext : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    disabledForegroundColor: AppColors.greyDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  child: Text(
                    currentPage == 2
                        ? AppStrings.onboardingFinish
                        : AppStrings.onboardingNext,
                    style: AppTypography.bodyLg.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isCurrentPageValid
                          ? Colors.white
                          : AppColors.greyDark,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
