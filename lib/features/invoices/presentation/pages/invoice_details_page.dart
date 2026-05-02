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
import '../widgets/brand_header.dart';
import '../widgets/invoice_detail_header.dart';
import '../widgets/invoice_items_table.dart';
import '../widgets/invoice_totals_section.dart';
import '../widgets/section_title.dart';

class InvoiceDetailsPage extends StatelessWidget {
  final Invoice invoice;

  const InvoiceDetailsPage({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settingsState) {
        if (settingsState is! SettingsLoaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
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
            textDirection: isArabic
                ? ui.TextDirection.rtl
                : ui.TextDirection.ltr,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InvoiceDetailHeader(
                    invoiceId: invoice.id,
                    createdAt: invoice.createdAt,
                    isArabic: isArabic,
                    dateFormat: dateFormat,
                    type: invoice.type,
                    paymentMethod: invoice.paymentMethod,
                    remainingAmount: invoice.remainingAmount,
                  ),

                  const Gap(AppSpacing.xl),
                  SectionTitle(
                    title: isArabic ? 'الأصناف' : 'Items',
                    icon: LucideIcons.box,
                  ),
                  const Gap(AppSpacing.sm),
                  InvoiceItemsTable(
                    items: invoice.items,
                    currency: settings.currency,
                    isArabic: isArabic,
                  ),
                  const Gap(AppSpacing.xl),
                  SectionTitle(
                    title: isArabic ? 'الملخص' : 'Summary',
                    icon: LucideIcons.calculator,
                  ),
                  const Gap(AppSpacing.sm),
                  InvoiceTotalsSection(
                    subtotal: invoice.subtotal,
                    vatAmount: invoice.vatAmount,
                    total: invoice.total,
                    vatPercent: invoice.vatPercent,
                    currency: settings.currency,
                    isArabic: isArabic,
                    paidAmount: invoice.paidAmount,
                    remainingAmount: invoice.remainingAmount,
                  ),
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
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                      ),
                    ),
                  ),
                  const Gap(AppSpacing.md),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showPrintOptions(context, isArabic),
                      icon: const Icon(LucideIcons.printer),
                      label: Text(
                        isArabic ? 'طباعة الفاتورة' : 'PRINT INVOICE',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
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
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _showPrintOptions(BuildContext context, bool isArabic) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
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
}
