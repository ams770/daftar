import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class OnboardingStep extends StatelessWidget {
  final String svg;
  final String title;
  final String desc;
  final Widget content;

  const OnboardingStep({
    super.key,
    required this.svg,
    required this.title,
    required this.desc,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              60,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            child: Column(
              children: [
                SvgPicture.asset(svg, height: 180),
                const Gap(AppSpacing.xl),
                Text(
                  title,
                  style: AppTypography.h1,
                  textAlign: TextAlign.center,
                ),
                const Gap(AppSpacing.sm),
                Text(
                  desc,
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.greyDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Gap(AppSpacing.xxl),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 500),
                  child: content,
                ),
                const Gap(100),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
