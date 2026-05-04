import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:products_printer/core/constants/app_strings.dart';
import '../../../../core/enums/invoice_enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/daftar_theme_extension.dart';
import '../../domain/entities/invoice.dart';
import '../pages/invoice_details_page.dart';

class InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  const InvoiceCard({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final daftar = Theme.of(context).extension<DaftarThemeExtension>()!;
    final dateFormat = DateFormat('MMM dd, yyyy • HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: daftar.cardDecoration.copyWith(
        boxShadow: [
          BoxShadow(
            color: AppColors.text.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => InvoiceDetailsPage(invoice: invoice),
              ),
            );
          },
          child: Stack(
            children: [
              // Positioned(
              //   left: 0,
              //   top: 0,
              //   bottom: 0,
              //   width: 4,
              //   child: Container(
              //     color: invoice.remainingAmount > 0
              //         ? AppColors.danger
              //         : AppColors.secondary,
              //   ),
              // ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                      child: const Icon(
                        LucideIcons.receipt,
                        color: AppColors.secondary,
                        size: 24,
                      ),
                    ),
                    const Gap(AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Invoice #${invoice.id.toString().padLeft(4, '0')}',
                            style: AppTypography.h2.copyWith(
                              fontSize: 17,
                              letterSpacing: -0.5,
                            ),
                          ),
                          if (invoice.clientName != null &&
                              invoice.clientName!.isNotEmpty) ...[
                            const Gap(2),
                            Text(
                              invoice.clientName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodySm.copyWith(
                                color: AppColors.greyDark,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          const Gap(AppSpacing.xs),
                          Row(
                            children: [
                              _StatusBadge(
                                label: invoice.type.label(
                                  context.locale.languageCode == 'ar',
                                ),
                                color: AppColors.grey,
                              ),
                              if (invoice.remainingAmount > 0) ...[
                                const Gap(4),
                                _StatusBadge(
                                  label: AppStrings.remaining,
                                  color: AppColors.danger,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${invoice.total.toStringAsFixed(2)} ${invoice.currency}',
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Gap(AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.greyLight.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${invoice.items.length} ${AppStrings.items}',
                            style: AppTypography.label.copyWith(
                              fontSize: 10,
                              color: AppColors.greyDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: AppTypography.label.copyWith(
          fontSize: 8,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
