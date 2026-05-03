import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:printing/printing.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/services/invoice_pdf_service.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/bento_theme_extension.dart';
import '../../../settings/presentation/cubits/settings_cubit.dart';
import '../../domain/entities/invoice.dart';
import 'dart:ui' as ui;
import '../cubits/invoice_cubit.dart';
import '../widgets/invoice_items_table.dart';
import '../widgets/invoice_totals_section.dart';
import '../widgets/section_title.dart';

import '../widgets/collect_money_bottom_sheet.dart';
import '../../domain/entities/money_collection.dart';
import '../cubits/money_collection_cubit.dart';

class InvoiceDetailsPage extends StatefulWidget {
  final Invoice invoice;

  const InvoiceDetailsPage({super.key, required this.invoice});

  @override
  State<InvoiceDetailsPage> createState() => _InvoiceDetailsPageState();
}

class _InvoiceDetailsPageState extends State<InvoiceDetailsPage> {
  late Invoice _invoice;
  List<MoneyCollection> _collections = [];
  bool _isLoadingCollections = true;

  @override
  void initState() {
    super.initState();
    _invoice = widget.invoice;
    _loadCollections();
  }

  Future<void> _loadCollections() async {
    // Reload invoice to get updated paid/remaining amounts
    final updatedInvoice = await context.read<InvoiceCubit>().getInvoiceById(_invoice.id!);
    final collections = await context
        .read<MoneyCollectionCubit>()
        .getCollectionsByInvoice(_invoice.id!);
    if (mounted) {
      setState(() {
        if (updatedInvoice != null) {
          _invoice = updatedInvoice;
        }
        _collections = collections;
        _isLoadingCollections = false;
      });
    }
  }

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
          appBar: AppBar(title: Text(AppStrings.invoiceDetails)),
          body: Directionality(
            textDirection: isArabic
                ? ui.TextDirection.rtl
                : ui.TextDirection.ltr,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildActionGrid(context, settings, isArabic),
                  const Gap(AppSpacing.lg),
                  _buildInfoCard(context, isArabic, dateFormat),

                  const Gap(AppSpacing.xl),
                  SectionTitle(title: AppStrings.items, icon: LucideIcons.box),
                  const Gap(AppSpacing.sm),
                  InvoiceItemsTable(
                    items: _invoice.items,
                    currency: settings.currency,
                    isArabic: isArabic,
                  ),
                  const Gap(AppSpacing.xl),
                  SectionTitle(
                    title: AppStrings.summary,
                    icon: LucideIcons.calculator,
                  ),
                  const Gap(AppSpacing.sm),
                  InvoiceTotalsSection(
                    subtotal: _invoice.subtotal,
                    vatAmount: _invoice.vatAmount,
                    total: _invoice.total,
                    vatPercent: _invoice.vatPercent,
                    currency: settings.currency,
                    isArabic: isArabic,
                    paidAmount: _invoice.paidAmount,
                    remainingAmount: _invoice.remainingAmount,
                  ),
                  if (_collections.isNotEmpty) ...[
                    const Gap(AppSpacing.xl),
                    SectionTitle(
                      title: AppStrings.collections,
                      icon: LucideIcons.history,
                    ),
                    const Gap(AppSpacing.sm),
                    _buildCollectionsList(settings.currency),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCollectionsList(String currency) {
    final bento = Theme.of(context).extension<BentoThemeExtension>()!;
    return Container(
      decoration: bento.cardDecoration,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _collections.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final collection = _collections[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  collection.formattedDate,
                  style: AppTypography.bodySm.copyWith(color: AppColors.grey),
                ),
                Text(
                  '+${collection.amount.toStringAsFixed(2)} $currency',
                  style: AppTypography.h3.copyWith(color: AppColors.success),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${AppStrings.remainingBefore}: ${collection.remainingBefore.toStringAsFixed(2)}',
                    style: AppTypography.label.copyWith(fontSize: 10),
                  ),
                  Text(
                    '${AppStrings.remainingAfter}: ${collection.remainingAfter.toStringAsFixed(2)}',
                    style: AppTypography.label.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionGrid(
    BuildContext context,
    dynamic settings,
    bool isArabic,
  ) {
    final bento = Theme.of(context).extension<BentoThemeExtension>()!;
    final canCollect = _invoice.remainingAmount > 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: bento.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppStrings.invoiceDetails, style: AppTypography.h2),
              _buildConnectionStatus(),
            ],
          ),
          const Gap(AppSpacing.xl),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 2.5,
            children: [
              _buildActionButton(
                icon: LucideIcons.printer,
                label: AppStrings.print,
                color: AppColors.danger,
                onTap: () => _showPrintOptions(context, isArabic),
              ),
              _buildActionButton(
                icon: LucideIcons.share2,
                label: AppStrings.shareAsPdf,
                color: AppColors.secondary,
                onTap: () => _shareAsPdf(context, settings),
              ),
              _buildActionButton(
                icon: LucideIcons.wallet,
                label: AppStrings.collectMoney,
                color: canCollect ? AppColors.warning : AppColors.grey,
                onTap: canCollect ? () => _showCollectMoney(context) : () {},
              ),
              _buildActionButton(
                icon: LucideIcons.trash2,
                label: AppStrings.delete,
                color: AppColors.danger,
                onTap: () => _showDeleteConfirmation(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCollectMoney(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (context) => CollectMoneyBottomSheet(invoice: _invoice),
    );

    if (result == true) {
      _loadCollections();
    }
  }

  Widget _buildConnectionStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.greyLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.greyLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const Gap(AppSpacing.xs),
          Text(
            'No Connection',
            style: AppTypography.label.copyWith(
              color: AppColors.greyDark,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const Gap(AppSpacing.md),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: AppTypography.bodySm.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    bool isArabic,
    DateFormat dateFormat,
  ) {
    final bento = Theme.of(context).extension<BentoThemeExtension>()!;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: bento.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Invoice #',
                    style: AppTypography.label.copyWith(color: AppColors.grey),
                  ),
                  const Gap(4),
                  Text(
                    widget.invoice.id?.toString().padLeft(3, '0') ?? '-',
                    style: AppTypography.h1,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    DateFormat('dd/MM/yyyy').format(_invoice.createdAt),
                    style: AppTypography.bodyMd.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    DateFormat('hh:mm a').format(_invoice.createdAt),
                    style: AppTypography.label.copyWith(color: AppColors.grey),
                  ),
                ],
              ),
            ],
          ),
          const Gap(AppSpacing.lg),
          const Divider(),
          const Gap(AppSpacing.lg),
          Text('Client Information', style: AppTypography.h3),
          const Gap(AppSpacing.lg),
          _buildInfoRow(
            LucideIcons.user,
            _invoice.clientName ?? 'Unknown Client',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.secondary),
        const Gap(AppSpacing.md),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySm.copyWith(color: AppColors.greyDark),
          ),
        ),
      ],
    );
  }

  Future<void> _shareAsPdf(BuildContext context, dynamic settings) async {
    try {
      final pdfBytes = await InvoicePdfService.generateInvoicePdf(
        invoice: _invoice,
        settings: settings,
      );

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'invoice_${_invoice.id ?? 'new'}.pdf',
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

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppStrings.delete),
        content: const Text('Are you sure you want to delete this invoice?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext); // Close dialog
              context.read<InvoiceCubit>().deleteInvoice(_invoice.id!);
              Navigator.pop(context); // Close details page
            },
            child: Text(
              AppStrings.delete,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
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
                Text(AppStrings.selectPrinterWidth, style: AppTypography.h2),
                const Gap(AppSpacing.xl),
                ListTile(
                  leading: const Icon(LucideIcons.printer),
                  title: Text(AppStrings.threeInch),
                  onTap: () => Navigator.pop(context),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(LucideIcons.printer),
                  title: Text(AppStrings.fourInch),
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
