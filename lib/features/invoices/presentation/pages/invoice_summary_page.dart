import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/bento_theme_extension.dart';
import '../../../settings/presentation/cubits/settings_cubit.dart';
import '../cubits/invoice_cubit.dart';
import '../../domain/entities/invoice.dart';

class InvoiceSummaryPage extends StatelessWidget {
  const InvoiceSummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settingsState) {
        if (settingsState is! SettingsLoaded) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final settings = settingsState.settings;
        final isArabic = settings.language == 'AR';

        return BlocConsumer<InvoiceCubit, InvoiceState>(
          listener: (context, state) {
            if (state is InvoiceSaveSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invoice saved successfully!'), backgroundColor: AppColors.success),
              );
              Navigator.popUntil(context, (route) => route.isFirst);
            }
          },
          builder: (context, state) {
            if (state is! InvoiceCreating) {
              return const Scaffold(body: Center(child: Text('No invoice in progress')));
            }

            final cart = state.cartItems;
            final products = state.availableProducts;
            
            double subtotal = 0;
            final List<InvoiceItem> items = [];

            cart.forEach((productId, qty) {
              final product = products.firstWhere((p) => p.id == productId);
              final lineTotal = product.price * qty;
              subtotal += lineTotal;
              items.add(InvoiceItem(
                productId: product.id,
                productName: product.name,
                productCode: product.code,
                qty: qty,
                unitPrice: product.price,
                lineTotal: lineTotal,
              ));
            });

            final vatAmount = subtotal * (settings.vatPercent / 100);
            final total = subtotal + vatAmount;

            return Scaffold(
              appBar: AppBar(
                title: Text(isArabic ? 'ملخص الفاتورة' : 'Invoice Summary'),
              ),
              body: Directionality(
                textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildBrandHeader(context, settings),
                      const Gap(AppSpacing.xl),
                      _buildItemsTable(context, items, settings.currency, isArabic),
                      const Gap(AppSpacing.xl),
                      _buildTotalsSection(context, subtotal, vatAmount, total, settings, isArabic),
                    ],
                  ),
                ),
              ),
              bottomNavigationBar: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: ElevatedButton(
                  onPressed: () {
                    final invoice = Invoice(
                      createdAt: DateTime.now(),
                      items: items,
                      subtotal: subtotal,
                      vatAmount: vatAmount,
                      total: total,
                      vatPercent: settings.vatPercent,
                      currency: settings.currency,
                    );
                    context.read<InvoiceCubit>().saveInvoice(invoice);
                  },
                  child: Text(isArabic ? 'حفظ الفاتورة' : 'SAVE INVOICE'),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBrandHeader(BuildContext context, dynamic settings) {
    final bento = Theme.of(context).extension<BentoThemeExtension>()!;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: bento.cardDecoration,
      child: Column(
        children: [
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

  Widget _buildTotalsSection(BuildContext context, double subtotal, double vatAmount, double total, dynamic settings, bool isArabic) {
    final bento = Theme.of(context).extension<BentoThemeExtension>()!;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: bento.cardDecoration,
      child: Column(
        children: [
          _buildTotalRow(isArabic ? 'المجموع الفرعي' : 'Subtotal', subtotal, settings.currency),
          const Gap(AppSpacing.sm),
          _buildTotalRow('${isArabic ? 'ضريبة القيمة المضافة' : 'VAT'} (${settings.vatPercent}%)', vatAmount, settings.currency),
          const Divider(height: AppSpacing.xl),
          _buildTotalRow(isArabic ? 'الإجمالي النهائي' : 'Grand Total', total, settings.currency, isBold: true),
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
