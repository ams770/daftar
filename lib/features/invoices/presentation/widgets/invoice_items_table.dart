import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/bento_theme_extension.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/invoice.dart';

class InvoiceItemsTable extends StatelessWidget {
  final List<InvoiceItem> items;
  final String currency;
  final bool isArabic;

  const InvoiceItemsTable({
    super.key,
    required this.items,
    required this.currency,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final bento = Theme.of(context).extension<BentoThemeExtension>()!;

    return Container(
      decoration: bento.cardDecoration,
      clipBehavior: Clip.antiAlias,
      child: DataTable(
        columnSpacing: 12,
        horizontalMargin: 16,
        headingRowColor: WidgetStateProperty.all(
          AppColors.primary.withValues(alpha: 0.1),
        ),
        columns: [
          DataColumn(
            label: Text(
              AppStrings.product,
              style: AppTypography.label,
            ),
          ),
          DataColumn(
            label: Text(
              AppStrings.qty,
              style: AppTypography.label,
            ),
            numeric: true,
          ),
          DataColumn(
            label: Text(
              AppStrings.total,
              style: AppTypography.label,
            ),
            numeric: true,
          ),
        ],
        rows: items.map((item) {
          return DataRow(
            cells: [
              DataCell(Text(item.productName, style: AppTypography.bodySm)),
              DataCell(Text('${item.qty}', style: AppTypography.bodySm)),
              DataCell(
                Text(
                  item.lineTotal.toStringAsFixed(2),
                  style: AppTypography.bodySm,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
