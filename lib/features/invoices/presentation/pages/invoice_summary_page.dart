import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/enums/invoice_enums.dart';
import '../../../../core/presentation/widgets/app_selection_group.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/bento_theme_extension.dart';
import '../../../settings/presentation/cubits/settings_cubit.dart';
import '../cubits/invoice_cubit.dart';
import '../cubits/add_invoice_cubit.dart';
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
  InvoiceType _type = InvoiceType.paid;
  PaymentMethod _method = PaymentMethod.cash;
  final TextEditingController _paidController = TextEditingController();
  final TextEditingController _clientNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final cubit = context.read<AddInvoiceCubit>();
    if (cubit.state is AddInvoiceCreating) {
      _clientNameController.text =
          (cubit.state as AddInvoiceCreating).clientName ?? '';
    }
  }

  @override
  void dispose() {
    _paidController.dispose();
    _clientNameController.dispose();
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

        return BlocConsumer<AddInvoiceCubit, AddInvoiceState>(
          listener: (context, state) {
            if (state is AddInvoiceSaveSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppStrings.invoiceSavedSuccess),
                  backgroundColor: AppColors.success,
                ),
              );
              // Refresh the invoices list
              context.read<InvoiceCubit>().loadInvoices();
              Navigator.popUntil(context, (route) => route.isFirst);
            }
          },
          builder: (context, state) {
            if (state is! AddInvoiceCreating) {
              return Scaffold(
                body: Center(child: Text(AppStrings.noInvoiceInProgress)),
              );
            }

            final cart = state.cartItems;

            double subtotal = 0;
            final List<InvoiceItem> items = [];

            cart.forEach((productId, cartItem) {
              final product = cartItem.product;
              final qty = cartItem.quantity;
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
            if (_type == InvoiceType.paid) {
              paidAmountValue = total;
            } else {
              paidAmountValue = double.tryParse(_paidController.text) ?? 0.0;
            }
            final remainingAmountValue = total - paidAmountValue;

            return Scaffold(
              appBar: AppBar(title: Text(AppStrings.invoiceSummary)),
              body: Directionality(
                textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SectionTitle(
                        title: AppStrings.clientDetails,
                        icon: LucideIcons.user,
                      ),
                      const Gap(AppSpacing.sm),
                      TextField(
                        controller: _clientNameController,
                        decoration: InputDecoration(
                          hintText: AppStrings.enterClientName,
                        ),
                        onChanged: (v) =>
                            context.read<AddInvoiceCubit>().updateClientName(v),
                      ),
                      const Gap(AppSpacing.xl),
                      SectionTitle(
                        title: AppStrings.items,
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
                        title: AppStrings.paymentOptions,
                        icon: LucideIcons.creditCard,
                      ),
                      const Gap(AppSpacing.md),
                      _buildInvoiceTypeSelection(isArabic),
                      if (_type == InvoiceType.credit) ...[
                        const Gap(AppSpacing.lg),
                        _buildPaidAmountField(
                          isArabic,
                          settings.currency,
                          total,
                        ),
                      ],
                      if (_type == InvoiceType.paid ||
                          _paidController.text.isNotEmpty) ...[
                        const Gap(AppSpacing.lg),
                        _buildPaymentMethodSelection(isArabic),
                      ],
                      const Gap(AppSpacing.xl),
                      SectionTitle(
                        title: AppStrings.summary,
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
                        _buildRemainingSection(
                          isArabic,
                          remainingAmountValue,
                          settings.currency,
                        ),
                      ],

                      const SizedBox(height: 200),
                    ],
                  ),
                ),
              ),
              bottomSheet: SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: SafeArea(
                    child: ElevatedButton(
                      onPressed: () {
                        if (state.clientName == null ||
                            state.clientName!.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(AppStrings.required),
                              backgroundColor: AppColors.danger,
                            ),
                          );
                          return;
                        }
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
                          clientName: state.clientName,
                        );
                        context.read<AddInvoiceCubit>().saveInvoice(invoice);
                      },
                      child: Text(AppStrings.saveInvoice),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInvoiceTypeSelection(bool isArabic) {
    return AppSelectionGroup<InvoiceType>(
      title: AppStrings.invoiceType,
      items: InvoiceType.values,
      selectedItem: _type,
      itemLabel: (item) => item.label(isArabic),
      itemIcon: (item) => item.icon,
      onSelect: (val) {
        if (val != null) {
          setState(() {
            _type = val;
            if (_type == InvoiceType.paid) {
              _paidController.clear();
            }
          });
        }
      },
    );
  }

  Widget _buildPaymentMethodSelection(bool isArabic) {
    return AppSelectionGroup<PaymentMethod>(
      title: AppStrings.paymentMethod,
      items: PaymentMethod.values,
      selectedItem: _method,
      itemLabel: (item) => item.label(isArabic),
      itemIcon: (item) => item.icon,
      onSelect: (val) {
        if (val != null) {
          setState(() => _method = val);
        }
      },
    );
  }

  Widget _buildPaidAmountField(bool isArabic, String currency, double total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${AppStrings.paidAmount} ($currency)',
          style: AppTypography.bodyMd.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.greyDark,
          ),
        ),
        const Gap(AppSpacing.sm),
        TextField(
          controller: _paidController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          decoration: InputDecoration(hintText: AppStrings.enterPaidAmount),
          onChanged: (v) {
            final val = double.tryParse(v) ?? 0;
            if (val > total) {
              _paidController.text = total.toStringAsFixed(2);
              _paidController.selection = TextSelection.fromPosition(
                TextPosition(offset: _paidController.text.length),
              );
            }
            setState(() {});
          },
        ),
      ],
    );
  }

  Widget _buildRemainingSection(
    bool isArabic,
    double remaining,
    String currency,
  ) {
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
            AppStrings.remainingAmount,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.danger,
              fontWeight: FontWeight.bold,
            ),
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
