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
  final IconData Function(T) itemIcon;
  final Function(T?) onSelect;
  final String? title;

  const AppSelectionGroup({
    super.key,
    required this.items,
    this.selectedItem,
    required this.itemLabel,
    required this.itemIcon,
    required this.onSelect,
    this.title,
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
        Row(
          children: items.map((item) {
            final isSelected = item == selectedItem;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: item == items.last ? 0 : AppSpacing.md,
                ),
                child: _SelectionItem(
                  label: itemLabel(item),
                  icon: itemIcon(item),
                  isSelected: isSelected,
                  onTap: () => onSelect(item),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _SelectionItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectionItem({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.success.withValues(alpha: 0.1) : AppColors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: isSelected ? AppColors.success : AppColors.greyLight.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.success : AppColors.grey,
              size: 28,
            ),
            const Gap(AppSpacing.sm),
            Text(
              label,
              style: AppTypography.label.copyWith(
                color: isSelected ? AppColors.success : AppColors.greyDark,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
