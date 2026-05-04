import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:printing/printing.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/daftar_theme_extension.dart';
import '../../../../core/services/pdf/invoice_pdf_service.dart';
import '../../../printer/presentation/cubits/printer_cubit.dart';
import '../../../printer/presentation/cubits/printer_state.dart';
import '../../../printer/presentation/widgets/printer_status_indicator.dart';
import '../../../settings/presentation/cubits/settings_cubit.dart';
import '../../domain/entities/money_collection.dart';
import '../cubits/money_collection_cubit.dart';
import '../cubits/invoice_cubit.dart';
import 'invoice_details_page.dart';

class MoneyCollectionDetailsPage extends StatelessWidget {
  final MoneyCollection collection;

  const MoneyCollectionDetailsPage({super.key, required this.collection});

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
        // final isArabic = settings.language == 'AR';
        final daftar = Theme.of(context).extension<DaftarThemeExtension>()!;

        return Scaffold(
          appBar: AppBar(title: Text(AppStrings.collections)),
          body: BlocListener<PrinterCubit, PrinterState>(
            listener: (context, state) {
              if (state is PrinterPrinting) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("printing".tr()),
                    duration: const Duration(seconds: 1),
                  ),
                );
              } else if (state is PrinterPrintSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("print_success".tr()),
                    backgroundColor: AppColors.success,
                  ),
                );
              } else if (state is PrinterError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.danger,
                  ),
                );
              }
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildActionGrid(context, settings),
                  const Gap(AppSpacing.lg),
                  _buildMainCard(context, daftar),
                  const Gap(AppSpacing.lg),
                  _buildInvoiceRefCard(context, daftar),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionGrid(BuildContext context, dynamic settings) {
    final daftar = Theme.of(context).extension<DaftarThemeExtension>()!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: daftar.cardDecoration,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppStrings.summary, style: AppTypography.h3),
              const PrinterStatusIndicator(),
            ],
          ),
          const Gap(AppSpacing.xl),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.5,
            children: [
              BlocBuilder<PrinterCubit, PrinterState>(
                builder: (context, state) {
                  Color buttonColor = AppColors.secondary;
                  String buttonLabel = AppStrings.print;

                  if (state is PrinterPrinting) {
                    buttonColor = AppColors.warning;
                    buttonLabel = 'printing'.tr();
                  } else if (state is PrinterGeneratingInvoice) {
                    buttonColor = AppColors.warning;
                    buttonLabel = AppStrings.generating;
                  } else if (state is PrinterConnecting ||
                      state is PrinterSearching) {
                    buttonColor = AppColors.warning;
                    buttonLabel = AppStrings.connecting;
                  } else if (state is! PrinterConnected &&
                      state is! PrinterPrintSuccess) {
                    buttonColor = AppColors.grey;
                  }

                  return _buildActionButton(
                    icon: LucideIcons.printer,
                    label: buttonLabel,
                    color: buttonColor,
                    onTap: () => context.read<PrinterCubit>().printCollection(
                      collection,
                    ),
                  );
                },
              ),
              _buildActionButton(
                icon: LucideIcons.share2,
                label: AppStrings.share,
                color: AppColors.success,
                onTap: () => _shareAsPdf(context, settings),
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
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const Gap(4),
            Text(
              label,
              style: AppTypography.label.copyWith(color: color, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainCard(BuildContext context, DaftarThemeExtension daftar) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: daftar.cardDecoration,
      child: Column(
        children: [
          Text(
            AppStrings.collected,
            style: AppTypography.bodySm.copyWith(color: AppColors.grey),
          ),
          const Gap(4),
          Text(
            '${collection.amount.toStringAsFixed(2)}',
            style: AppTypography.h1.copyWith(
              color: AppColors.success,
              fontSize: 32,
            ),
          ),
          const Gap(AppSpacing.xl),
          const Divider(),
          const Gap(AppSpacing.xl),
          _buildDetailRow(
            AppStrings.remainingBefore,
            collection.remainingBefore.toStringAsFixed(2),
          ),
          const Gap(AppSpacing.md),
          _buildDetailRow(
            AppStrings.remainingAfter,
            collection.remainingAfter.toStringAsFixed(2),
            isBold: true,
          ),
          const Gap(AppSpacing.xl),
          const Divider(),
          const Gap(AppSpacing.xl),
          _buildDetailRow(AppStrings.date, collection.formattedDate),
        ],
      ),
    );
  }

  Widget _buildInvoiceRefCard(
    BuildContext context,
    DaftarThemeExtension daftar,
  ) {
    return InkWell(
      onTap: () => _navigateToInvoice(context),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: daftar.cardDecoration,
        child: Row(
          children: [
            const Icon(LucideIcons.fileText, color: AppColors.secondary),
            const Gap(AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.invoice,
                    style: AppTypography.label.copyWith(color: AppColors.grey),
                  ),
                  Text(
                    '${AppStrings.invoice} #${collection.invoiceId}',
                    style: AppTypography.h3,
                  ),
                  if (collection.clientName != null)
                    Text(collection.clientName!, style: AppTypography.bodySm),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: AppColors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodyMd),
        Text(
          value,
          style: isBold
              ? AppTypography.h3
              : AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  void _navigateToInvoice(BuildContext context) async {
    final invoice = await context.read<InvoiceCubit>().getInvoiceById(
      collection.invoiceId,
    );
    if (invoice != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InvoiceDetailsPage(invoice: invoice),
        ),
      );
    }
  }

  Future<void> _shareAsPdf(BuildContext context, dynamic settings) async {
    try {
      final pdfBytes = await InvoicePdfService.generateCollectionPdf(
        collection: collection,
        settings: settings,
      );

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'receipt_${collection.id ?? 'new'}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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
        content: const Text(
          'Are you sure you want to delete this collection? This will increase the invoice remaining amount.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<MoneyCollectionCubit>().deleteCollection(
                collection.id!,
              );
              // Refresh invoice list in case we go back to it
              context.read<InvoiceCubit>().loadInvoices(refresh: true);
              Navigator.pop(context);
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
}
