import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:printing/printing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/bento_theme_extension.dart';
import '../../../../core/services/invoice_pdf_service.dart';
import '../../../settings/presentation/cubits/settings_cubit.dart';
import '../../domain/entities/invoice.dart';
import 'dart:io';
import 'dart:ui' as ui;

class InvoiceDetailsPage extends StatelessWidget {
  final Invoice invoice;

  const InvoiceDetailsPage({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settingsState) {
        if (settingsState is! SettingsLoaded) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final settings = settingsState.settings;
        final isArabic = settings.language == 'AR';
        final dateFormat = DateFormat('MMM dd, yyyy • HH:mm');

        return Scaffold(
          appBar: AppBar(
            title: Text(isArabic ? 'تفاصيل الفاتورة' : 'Invoice Details'),
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.share2),
                onPressed: () => _shareAsPdf(context, settings),
                tooltip: isArabic ? 'مشاركة كـ PDF' : 'Share as PDF',
              ),
            ],
          ),
          body: Directionality(
            textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildInvoiceHeader(context, isArabic, dateFormat),
                  const Gap(AppSpacing.lg),
                  _buildBrandHeader(context, settings),
                  const Gap(AppSpacing.xl),
                  _buildItemsTable(context, invoice.items, settings.currency, isArabic),
                  const Gap(AppSpacing.xl),
                  _buildTotalsSection(context, invoice, settings, isArabic),
                ],
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _shareAsPdf(context, settings),
                      icon: const Icon(LucideIcons.fileText),
                      label: Text(isArabic ? 'مشاركة كـ PDF' : 'SHARE AS PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      ),
                    ),
                  ),
                  const Gap(AppSpacing.md),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showPrintOptions(context, isArabic),
                      icon: const Icon(LucideIcons.printer),
                      label: Text(isArabic ? 'طباعة الفاتورة' : 'PRINT INVOICE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _shareAsPdf(BuildContext context, dynamic settings) async {
    try {
      final pdfBytes = await InvoicePdfService.generateInvoicePdf(
        invoice: invoice,
        settings: settings,
      );
      
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'invoice_${invoice.id ?? 'new'}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  void _showPrintOptions(BuildContext context, bool isArabic) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isArabic ? 'اختر عرض الطابعة' : 'Select Printer Width',
                  style: AppTypography.h2,
                ),
                const Gap(AppSpacing.xl),
                ListTile(
                  leading: const Icon(LucideIcons.printer),
                  title: Text(isArabic ? '3 بوصة' : '3 Inch'),
                  onTap: () => Navigator.pop(context),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(LucideIcons.printer),
                  title: Text(isArabic ? '4 بوصة' : '4 Inch'),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInvoiceHeader(BuildContext context, bool isArabic, DateFormat dateFormat) {
    final bento = Theme.of(context).extension<BentoThemeExtension>()!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: bento.cardDecoration.copyWith(
        color: AppColors.primary.withValues(alpha: 0.1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${isArabic ? 'فاتورة رقم' : 'Invoice #'} ${invoice.id?.toString().padLeft(4, '0') ?? 'N/A'}',
                style: AppTypography.h2,
              ),
              const Gap(AppSpacing.xs),
              Text(
                dateFormat.format(invoice.createdAt),
                style: AppTypography.bodySm.copyWith(color: AppColors.grey),
              ),
            ],
          ),
          const Icon(LucideIcons.receipt, color: AppColors.secondary, size: 32),
        ],
      ),
    );
  }

  Widget _buildBrandHeader(BuildContext context, dynamic settings) {
    final bento = Theme.of(context).extension<BentoThemeExtension>()!;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: bento.cardDecoration,
      child: Column(
        children: [
          if (settings.logoPath != null && settings.logoPath!.isNotEmpty) ...[
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                image: DecorationImage(
                  image: FileImage(File(settings.logoPath!)),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const Gap(AppSpacing.md),
          ],
          Text(
            settings.brandName,
            style: AppTypography.h1.copyWith(color: AppColors.secondary),
            textAlign: TextAlign.center,
          ),
          if (settings.phone.isNotEmpty) ...[
            const Gap(AppSpacing.xs),
            Text(settings.phone, style: AppTypography.bodySm),
          ],
          if (settings.address.isNotEmpty) ...[
            const Gap(AppSpacing.xs),
            Text(settings.address, style: AppTypography.bodySm, textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }

  Widget _buildItemsTable(BuildContext context, List<InvoiceItem> items, String currency, bool isArabic) {
    final bento = Theme.of(context).extension<BentoThemeExtension>()!;

    return Container(
      decoration: bento.cardDecoration,
      clipBehavior: Clip.antiAlias,
      child: DataTable(
        columnSpacing: 12,
        horizontalMargin: 16,
        headingRowColor: WidgetStateProperty.all(AppColors.primary.withValues(alpha: 0.1)),
        columns: [
          DataColumn(label: Text(isArabic ? 'المنتج' : 'Product', style: AppTypography.label)),
          DataColumn(label: Text(isArabic ? 'الكمية' : 'Qty', style: AppTypography.label), numeric: true),
          DataColumn(label: Text(isArabic ? 'الإجمالي' : 'Total', style: AppTypography.label), numeric: true),
        ],
        rows: items.map((item) {
          return DataRow(cells: [
            DataCell(Text(item.productName, style: AppTypography.bodySm)),
            DataCell(Text('${item.qty}', style: AppTypography.bodySm)),
            DataCell(Text(item.lineTotal.toStringAsFixed(2), style: AppTypography.bodySm)),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildTotalsSection(BuildContext context, Invoice invoice, dynamic settings, bool isArabic) {
    final bento = Theme.of(context).extension<BentoThemeExtension>()!;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: bento.cardDecoration,
      child: Column(
        children: [
          _buildTotalRow(isArabic ? 'المجموع الفرعي' : 'Subtotal', invoice.subtotal, settings.currency),
          const Gap(AppSpacing.sm),
          _buildTotalRow('${isArabic ? 'ضريبة القيمة المضافة' : 'VAT'} (${invoice.vatPercent}%)', invoice.vatAmount, settings.currency),
          const Divider(height: AppSpacing.xl),
          _buildTotalRow(isArabic ? 'الإجمالي النهائي' : 'Grand Total', invoice.total, settings.currency, isBold: true),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double value, String currency, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isBold ? AppTypography.bodyLg.copyWith(fontWeight: FontWeight.bold) : AppTypography.bodyMd,
        ),
        Text(
          '${value.toStringAsFixed(2)} $currency',
          style: isBold 
            ? AppTypography.h2.copyWith(color: AppColors.secondary) 
            : AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
