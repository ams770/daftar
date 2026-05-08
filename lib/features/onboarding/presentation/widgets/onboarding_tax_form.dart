import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/daftar_theme_extension.dart';
import 'onboarding_text_field.dart';

class OnboardingTaxForm extends StatelessWidget {
  final TextEditingController vatController;
  final TextEditingController currencyController;
  final FocusNode vatFocus;
  final FocusNode currencyFocus;
  final VoidCallback onStateChanged;
  final VoidCallback onNext;

  const OnboardingTaxForm({
    super.key,
    required this.vatController,
    required this.currencyController,
    required this.vatFocus,
    required this.currencyFocus,
    required this.onStateChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final daftar = Theme.of(context).extension<DaftarThemeExtension>()!;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: daftar.cardDecoration,
      child: Column(
        children: [
          Text(
            AppStrings.vatPercentage,
            style: AppTypography.bodyLg.copyWith(fontWeight: FontWeight.bold),
          ),
          const Gap(AppSpacing.lg),
          OnboardingTextField(
            controller: vatController,
            focusNode: vatFocus,
            label: "%",
            icon: LucideIcons.percent,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            action: TextInputAction.next,
            onChanged: (_) => onStateChanged(),
            onSubmitted: (_) =>
                FocusScope.of(context).requestFocus(currencyFocus),
          ),
          const Gap(AppSpacing.xl),
          Text(
            AppStrings.currency,
            style: AppTypography.bodyLg.copyWith(fontWeight: FontWeight.bold),
          ),
          const Gap(AppSpacing.lg),
          OnboardingTextField(
            controller: currencyController,
            focusNode: currencyFocus,
            label: AppStrings.currencyCode,
            icon: LucideIcons.coins,
            textAlign: TextAlign.center,
            action: TextInputAction.done,
            onChanged: (_) => onStateChanged(),
            onSubmitted: (_) {
              FocusScope.of(context).unfocus();
              // onNext();
            },
          ),
        ],
      ),
    );
  }
}
