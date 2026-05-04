import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/enums/invoice_enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/daftar_theme_extension.dart';
import '../../../../core/constants/app_strings.dart';

class InvoiceDetailHeader extends StatelessWidget {
  final int? invoiceId;
  final DateTime createdAt;
  final bool isArabic;
  final DateFormat dateFormat;
  final InvoiceType type;
  final PaymentMethod paymentMethod;
  final double remainingAmount;
  final String? clientName;

  const InvoiceDetailHeader({
    super.key,
    required this.invoiceId,
    required this.createdAt,
    required this.isArabic,
    required this.dateFormat,
    required this.type,
    required this.paymentMethod,
    required this.remainingAmount,
    this.clientName,
  });

  @override
  Widget build(BuildContext context) {
    final daftar = Theme.of(context).extension<DaftarThemeExtension>()!;
    final isFullyPaid = remainingAmount <= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: daftar.cardDecoration.copyWith(
        gradient: LinearGradient(
          colors: [
            AppColors.secondary,
            AppColors.secondary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${AppStrings.invoice} ${type.label(isArabic)}',
                    style: AppTypography.label.copyWith(
                      color: AppColors.white.withValues(alpha: 0.8),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    '#${invoiceId?.toString().padLeft(4, '0') ?? 'N/A'}',
                    style: AppTypography.h1.copyWith(color: AppColors.white),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.receipt,
                  color: AppColors.white,
                  size: 32,
                ),
              ),
            ],
          ),
          if (clientName != null && clientName!.isNotEmpty) ...[
            const Gap(AppSpacing.lg),
            Row(
              children: [
                Icon(
                  LucideIcons.user,
                  size: 14,
                  color: AppColors.white.withValues(alpha: 0.7),
                ),
                const Gap(AppSpacing.xs),
                Text(
                  clientName!,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
          const Gap(AppSpacing.xl),
          Row(
            children: [
              Icon(
                LucideIcons.calendar,
                size: 14,
                color: AppColors.white.withValues(alpha: 0.7),
              ),
              const Gap(AppSpacing.xs),
              Text(
                dateFormat.format(createdAt),
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.white.withValues(alpha: 0.9),
                ),
              ),
              const Spacer(),
              _buildStatusBadge(isFullyPaid),
            ],
          ),
          const Gap(AppSpacing.md),
          Row(
            children: [
              Icon(
                LucideIcons.wallet,
                size: 14,
                color: AppColors.white.withValues(alpha: 0.7),
              ),
              const Gap(AppSpacing.xs),
              Text(
                paymentMethod.label(isArabic),
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isFullyPaid) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isFullyPaid ? AppColors.success : AppColors.danger).withValues(
          alpha: 0.3,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.2)),
      ),
      child: Text(
        isFullyPaid ? AppStrings.fullyPaid : AppStrings.remaining,
        style: AppTypography.label.copyWith(
          color: AppColors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
