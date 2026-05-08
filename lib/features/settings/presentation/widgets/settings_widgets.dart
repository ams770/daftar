import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/daftar_theme_extension.dart';

class LogoPreview extends StatelessWidget {
  final String? path;
  const LogoPreview({super.key, this.path});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        image: path != null
            ? DecorationImage(image: FileImage(File(path!)), fit: BoxFit.cover)
            : null,
      ),
      child: path == null
          ? const Icon(LucideIcons.image, color: AppColors.secondary, size: 24)
          : null,
    );
  }
}

class SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const SettingRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Icon(icon, color: AppColors.secondary, size: 18),
        ),
        const Gap(AppSpacing.md),
        Expanded(child: Text(label, style: AppTypography.bodyMd)),
        Text(
          value,
          style: AppTypography.h2.copyWith(
            fontSize: 16,
            color: AppColors.secondary,
          ),
        ),
        const Gap(AppSpacing.md),
        const Icon(LucideIcons.chevronRight, color: AppColors.grey, size: 18),
      ],
    );
  }
}

class SettingsSection extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback onTap;

  const SettingsSection({
    super.key,
    required this.title,
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final daftar = Theme.of(context).extension<DaftarThemeExtension>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.sm,
            bottom: AppSpacing.sm,
          ),
          child: Text(
            title.toUpperCase(),
            style: AppTypography.label.copyWith(
              color: AppColors.grey,
              letterSpacing: 1.2,
            ),
          ),
        ),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: daftar.cardDecoration,
            child: child,
          ),
        ),
      ],
    );
  }
}

class LanguageOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const LanguageOption({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.grey.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTypography.bodyMd.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isSelected)
              const Icon(LucideIcons.check, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
