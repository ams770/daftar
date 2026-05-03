import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/enums/invoice_enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../settings/presentation/cubits/settings_cubit.dart';
import '../cubits/invoice_cubit.dart';
import '../cubits/add_invoice_cubit.dart';
import '../../domain/entities/invoice.dart';
import '../widgets/invoice_items_table.dart';
import '../widgets/invoice_totals_section.dart';
import '../widgets/section_title.dart';
import '../widgets/invoice_summary_widgets.dart';

class InvoiceSummaryPage extends StatefulWidget {
  const InvoiceSummaryPage({super.key});

  @override
  State<InvoiceSummaryPage> createState() => _InvoiceSummaryPageState();
}

class _InvoiceSummaryPageState extends State<InvoiceSummaryPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
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

            double paidAmountValue = _type == InvoiceType.paid 
                ? total 
                : (double.tryParse(_paidController.text) ?? 0.0);
            final remainingAmountValue = total - paidAmountValue;

            return Scaffold(
              appBar: AppBar(title: Text(AppStrings.invoiceSummary)),
              body: Directionality(
                textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SectionTitle(
                          title: AppStrings.clientDetails,
                          icon: LucideIcons.user,
                        ),
                        const Gap(AppSpacing.sm),
                        TextFormField(
                          controller: _clientNameController,
                          decoration: InputDecoration(
                            hintText: AppStrings.enterClientName,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return AppStrings.required;
                            }
                            return null;
                          },
                          onChanged: (v) => context.read<AddInvoiceCubit>().updateClientName(v),
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
                        InvoiceTypeSelection(
                          isArabic: isArabic,
                          selectedType: _type,
                          onSelect: (val) {
                            setState(() {
                              _type = val;
                              if (_type == InvoiceType.paid) _paidController.clear();
                            });
                          },
                        ),
                        if (_type == InvoiceType.credit) ...[
                          const Gap(AppSpacing.lg),
                          PaidAmountField(
                            isArabic: isArabic,
                            currency: settings.currency,
                            total: total,
                            controller: _paidController,
                            onChanged: () => setState(() {}),
                          ),
                        ],
                        if (_type == InvoiceType.paid || _paidController.text.isNotEmpty) ...[
                          const Gap(AppSpacing.lg),
                          PaymentMethodSelection(
                            isArabic: isArabic,
                            selectedMethod: _method,
                            onSelect: (val) => setState(() => _method = val),
                          ),
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
                          paidAmount: _type == InvoiceType.credit ? paidAmountValue : null,
                          remainingAmount: _type == InvoiceType.credit ? remainingAmountValue : null,
                        ),
                        const Gap(AppSpacing.tripleXl),
                        const Gap(AppSpacing.tripleXl),
                      ],
                    ),
                  ),
                ),
              ),
              bottomSheet: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                color: Theme.of(context).scaffoldBackgroundColor,
                child: SafeArea(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
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
                          clientName: _clientNameController.text.trim(),
                        );
                        context.read<AddInvoiceCubit>().saveInvoice(invoice);
                      }
                    },
                    child: Text(AppStrings.saveInvoice),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
