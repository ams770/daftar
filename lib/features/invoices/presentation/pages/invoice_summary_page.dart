import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/enums/invoice_enums.dart';
import '../../../../core/presentation/widgets/app_selection_group.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/bento_theme_extension.dart';
import '../../../settings/presentation/cubits/settings_cubit.dart';
import '../cubits/invoice_cubit.dart';
import '../../domain/entities/invoice.dart';
import '../widgets/invoice_items_table.dart';
import '../widgets/invoice_totals_section.dart';
import '../widgets/section_title.dart';

class InvoiceSummaryPage extends StatefulWidget {
  const InvoiceSummaryPage({super.key});

  @override
  State<InvoiceSummaryPage> createState() => _InvoiceSummaryPageState();
}

class _InvoiceSummaryPageState extends State<InvoiceSummaryPage> {
  InvoiceType _type = InvoiceType.cash;
  PaymentMethod _method = PaymentMethod.cash;
  final TextEditingController _paidController = TextEditingController();

  @override
  void dispose() {
    _paidController.dispose();
    super.dispose();
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

        return BlocConsumer<InvoiceCubit, InvoiceState>(
          listener: (context, state) {
            if (state is InvoiceSaveSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isArabic ? 'تم حفظ الفاتورة بنجاح!' : 'Invoice saved successfully!'),
                  backgroundColor: AppColors.success,
                ),
              );
              Navigator.popUntil(context, (route) => route.isFirst);
            }
          },
          builder: (context, state) {
            if (state is! InvoiceCreating) {
              return Scaffold(
                body: Center(child: Text(isArabic ? 'لا توجد فاتورة قيد التنفيذ' : 'No invoice in progress')),
              );
            }

            final cart = state.cartItems;
            final products = state.availableProducts;

            double subtotal = 0;
            final List<InvoiceItem> items = [];

            cart.forEach((productId, qty) {
              final product = products.firstWhere((p) => p.id == productId);
              final lineTotal = product.price * qty;
              subtotal += lineTotal;
              items.add(
                InvoiceItem(
                  productId: product.id,
                  productName: product.name,
                  productCode: product.code,
                  qty: qty,
                  unitPrice: product.price,
                  lineTotal: lineTotal,
                ),
              );
            });

            final vatAmount = subtotal * (settings.vatPercent / 100);
            final total = subtotal + vatAmount;

            // Logic for paid amount
            double paidAmountValue;
            if (_type == InvoiceType.cash) {
              paidAmountValue = total;
            } else {
              paidAmountValue = double.tryParse(_paidController.text) ?? 0.0;
            }
            final remainingAmountValue = total - paidAmountValue;

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
                      SectionTitle(
                        title: isArabic ? 'الأصناف' : 'Items',
                        icon: LucideIcons.box,
                      ),
                      const Gap(AppSpacing.sm),
                      InvoiceItemsTable(
                        items: items,
                        currency: settings.currency,
                        isArabic: isArabic,
                      ),
                      const Gap(AppSpacing.xl),
                      SectionTitle(
                        title: isArabic ? 'خيارات الدفع' : 'Payment Options',
                        icon: LucideIcons.creditCard,
                      ),
                      const Gap(AppSpacing.md),
                      _buildPaymentOptions(isArabic),
                      if (_type == InvoiceType.credit) ...[
                        const Gap(AppSpacing.lg),
                        _buildPaidAmountField(isArabic, settings.currency),
                      ],
                      const Gap(AppSpacing.xl),
                      SectionTitle(
                        title: isArabic ? 'الملخص' : 'Summary',
                        icon: LucideIcons.calculator,
                      ),
                      const Gap(AppSpacing.sm),
                      InvoiceTotalsSection(
                        subtotal: subtotal,
                        vatAmount: vatAmount,
                        total: total,
                        vatPercent: settings.vatPercent,
                        currency: settings.currency,
                        isArabic: isArabic,
                      ),
                      if (_type == InvoiceType.credit) ...[
                        const Gap(AppSpacing.md),
                        _buildRemainingSection(isArabic, remainingAmountValue, settings.currency),
                      ],
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
                      type: _type,
                      paymentMethod: _method,
                      paidAmount: paidAmountValue,
                      remainingAmount: remainingAmountValue,
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

  Widget _buildPaymentOptions(bool isArabic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSelectionGroup<InvoiceType>(
          title: isArabic ? 'نوع الفاتورة' : 'Invoice Type',
          items: InvoiceType.values,
          selectedItem: _type,
          itemLabel: (item) => item.label(isArabic),
          onSelect: (val) {
            if (val != null) {
              setState(() {
                _type = val;
                if (_type == InvoiceType.cash) {
                  _paidController.clear();
                }
              });
            }
          },
        ),
        const Gap(AppSpacing.lg),
        AppSelectionGroup<PaymentMethod>(
          title: isArabic ? 'طريقة الدفع' : 'Payment Method',
          items: PaymentMethod.values,
          selectedItem: _method,
          itemLabel: (item) => item.label(isArabic),
          onSelect: (val) {
            if (val != null) {
              setState(() => _method = val);
            }
          },
        ),
      ],
    );
  }

  Widget _buildPaidAmountField(bool isArabic, String currency) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isArabic ? 'المبلغ المدفوع ($currency)' : 'Paid Amount ($currency)',
          style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.bold, color: AppColors.greyDark),
        ),
        const Gap(AppSpacing.sm),
        TextField(
          controller: _paidController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          decoration: InputDecoration(
            hintText: isArabic ? 'أدخل المبلغ المدفوع' : 'Enter paid amount',
          ),
          onChanged: (v) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildRemainingSection(bool isArabic, double remaining, String currency) {
    final bento = Theme.of(context).extension<BentoThemeExtension>()!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: bento.cardDecoration.copyWith(
        color: AppColors.danger.withValues(alpha: 0.05),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isArabic ? 'المبلغ المتبقي' : 'Remaining Amount',
            style: AppTypography.bodyMd.copyWith(color: AppColors.danger, fontWeight: FontWeight.bold),
          ),
          Text(
            '${remaining.toStringAsFixed(2)} $currency',
            style: AppTypography.h2.copyWith(color: AppColors.danger),
          ),
        ],
      ),
    );
  }
}
