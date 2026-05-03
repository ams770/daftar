import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class BentoAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showShadow;

  const BentoAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondary,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: AppColors.text.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const Gap(AppSpacing.md)],
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.h1.copyWith(
                    fontSize: 28,
                    letterSpacing: -1.2,
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (actions != null) ...actions!,
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(80);
}
