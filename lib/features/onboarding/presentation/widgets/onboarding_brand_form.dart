import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';
import 'onboarding_logo_picker.dart';
import 'onboarding_text_field.dart';

class OnboardingBrandForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final FocusNode nameFocus;
  final FocusNode phoneFocus;
  final FocusNode addressFocus;
  final String? logoPath;
  final String? logoFileName;
  final VoidCallback onPickLogo;
  final VoidCallback onStateChanged;
  final VoidCallback onNext;

  const OnboardingBrandForm({
    super.key,
    required this.nameController,
    required this.phoneController,
    required this.addressController,
    required this.nameFocus,
    required this.phoneFocus,
    required this.addressFocus,
    this.logoPath,
    this.logoFileName,
    required this.onPickLogo,
    required this.onStateChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        OnboardingLogoPicker(
          logoPath: logoPath,
          logoFileName: logoFileName,
          onTap: onPickLogo,
        ),
        const Gap(AppSpacing.xxl),
        OnboardingTextField(
          controller: nameController,
          focusNode: nameFocus,
          label: AppStrings.brandName,
          icon: LucideIcons.building,
          action: TextInputAction.next,
          onSubmitted: (_) => FocusScope.of(context).requestFocus(phoneFocus),
          onChanged: (_) => onStateChanged(),
        ),
        const Gap(AppSpacing.lg),
        OnboardingTextField(
          controller: phoneController,
          focusNode: phoneFocus,
          label: AppStrings.phoneNumber,
          icon: LucideIcons.phone,
          action: TextInputAction.next,
          keyboardType: TextInputType.phone,
          onSubmitted: (_) => FocusScope.of(context).requestFocus(addressFocus),
          onChanged: (_) => onStateChanged(),
        ),
        const Gap(AppSpacing.lg),
        OnboardingTextField(
          controller: addressController,
          focusNode: addressFocus,
          label: AppStrings.address,
          icon: LucideIcons.mapPin,
          action: TextInputAction.done,
          onSubmitted: (_) {
            FocusScope.of(context).unfocus();
            // onNext();
          },
          onChanged: (_) => onStateChanged(),
        ),
      ],
    );
  }
}
