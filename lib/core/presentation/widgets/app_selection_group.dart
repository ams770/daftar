import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/bento_theme_extension.dart';

class AppSelectionGroup<T> extends StatelessWidget {
  final List<T> items;
  final T? selectedItem;
  final String Function(T) itemLabel;
  final Function(T?) onSelect;
  final String? title;
  final bool isArabic;

  const AppSelectionGroup({
    super.key,
    required this.items,
    this.selectedItem,
    required this.itemLabel,
    required this.onSelect,
    this.title,
    this.isArabic = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: AppTypography.bodyMd.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.greyDark,
            ),
          ),
          const Gap(AppSpacing.sm),
        ],
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: items.map((item) {
            final isSelected = item == selectedItem;
            return _SelectionItem(
              label: itemLabel(item),
              isSelected: isSelected,
              onTap: () {
                if (isSelected) {
                  onSelect(null);
                } else {
                  onSelect(item);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _SelectionItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectionItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bento = Theme.of(context).extension<BentoThemeExtension>()!;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondary : AppColors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected ? AppColors.secondary : AppColors.greyLight,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          style: AppTypography.label.copyWith(
            color: isSelected ? AppColors.white : AppColors.greyDark,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
