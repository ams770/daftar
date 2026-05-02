import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/bento_theme_extension.dart';

class InvoiceTotalsSection extends StatelessWidget {
  final double subtotal;
  final double vatAmount;
  final double total;
  final int vatPercent;
  final String currency;
  final bool isArabic;
  final double? paidAmount;
  final double? remainingAmount;

  const InvoiceTotalsSection({
    super.key,
    required this.subtotal,
    required this.vatAmount,
    required this.total,
    required this.vatPercent,
    required this.currency,
    required this.isArabic,
    this.paidAmount,
    this.remainingAmount,
  });

  @override
  Widget build(BuildContext context) {
    final bento = Theme.of(context).extension<BentoThemeExtension>()!;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: bento.cardDecoration,
      child: Column(
        children: [
          _TotalRow(
            label: isArabic ? 'المجموع الفرعي' : 'Subtotal',
            value: subtotal,
            currency: currency,
          ),
          const Gap(AppSpacing.md),
          _TotalRow(
            label: '${isArabic ? 'ضريبة القيمة المضافة' : 'VAT'} ($vatPercent%)',
            value: vatAmount,
            currency: currency,
          ),
          const Gap(AppSpacing.md),
          const Divider(),
          const Gap(AppSpacing.md),
          _TotalRow(
            label: isArabic ? 'الإجمالي النهائي' : 'Grand Total',
            value: total,
            currency: currency,
            isBold: true,
          ),
          if (paidAmount != null && remainingAmount != null && remainingAmount! > 0) ...[
            const Gap(AppSpacing.md),
            const Divider(),
            const Gap(AppSpacing.md),
            _TotalRow(
              label: isArabic ? 'المدفوع' : 'Paid',
              value: paidAmount!,
              currency: currency,
              color: AppColors.success,
            ),
            const Gap(AppSpacing.md),
            _TotalRow(
              label: isArabic ? 'المتبقي' : 'Remaining',
              value: remainingAmount!,
              currency: currency,
              color: AppColors.danger,
              isBold: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final double value;
  final String currency;
  final bool isBold;
  final Color? color;

  const _TotalRow({
    required this.label,
    required this.value,
    required this.currency,
    this.isBold = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: isBold
                ? AppTypography.h2.copyWith(fontSize: 16, color: color)
                : AppTypography.bodyMd.copyWith(color: color ?? AppColors.greyDark),
          ),
        ),
        const Gap(AppSpacing.md),
        Flexible(
          child: Text(
            '${value.toStringAsFixed(2)} $currency',
            textAlign: TextAlign.end,
            style: isBold
                ? AppTypography.h2.copyWith(
                    color: color ?? AppColors.secondary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  )
                : AppTypography.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
          ),
        ),
      ],
    );
  }
}
