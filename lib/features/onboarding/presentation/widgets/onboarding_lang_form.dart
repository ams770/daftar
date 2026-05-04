import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_strings.dart';
import 'onboarding_selection_card.dart';

class OnboardingLangForm extends StatelessWidget {
  final String selectedLang;
  final String selectedPrintLang;
  final Function(String) onAppLangChanged;
  final Function(String) onPrintLangChanged;

  const OnboardingLangForm({
    super.key,
    required this.selectedLang,
    required this.selectedPrintLang,
    required this.onAppLangChanged,
    required this.onPrintLangChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSelectionTitle(
          AppStrings.appLanguage,
          AppStrings.appLanguageDesc,
        ),
        const Gap(AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: OnboardingSelectionCard(
                label: AppStrings.english,
                isSelected: selectedLang == 'EN',
                onTap: () => onAppLangChanged('EN'),
              ),
            ),
            const Gap(AppSpacing.md),
            Expanded(
              child: OnboardingSelectionCard(
                label: AppStrings.arabic,
                isSelected: selectedLang == 'AR',
                onTap: () => onAppLangChanged('AR'),
              ),
            ),
          ],
        ),
        const Gap(AppSpacing.xl),
        _buildSelectionTitle(
          AppStrings.printingLanguage,
          AppStrings.printingLanguageDesc,
        ),
        const Gap(AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: OnboardingSelectionCard(
                label: AppStrings.english,
                isSelected: selectedPrintLang == 'EN',
                onTap: () => onPrintLangChanged('EN'),
              ),
            ),
            const Gap(AppSpacing.md),
            Expanded(
              child: OnboardingSelectionCard(
                label: AppStrings.arabic,
                isSelected: selectedPrintLang == 'AR',
                onTap: () => onPrintLangChanged('AR'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectionTitle(String title, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.h3),
        Text(
          desc,
          style: AppTypography.bodySm.copyWith(color: AppColors.greyDark),
        ),
      ],
    );
  }
}
