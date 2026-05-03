import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/enums/invoice_enums.dart';
import '../../../../core/presentation/widgets/app_selection_group.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class InvoiceTypeSelection extends StatelessWidget {
  final bool isArabic;
  final InvoiceType selectedType;
  final Function(InvoiceType) onSelect;

  const InvoiceTypeSelection({
    super.key,
    required this.isArabic,
    required this.selectedType,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return AppSelectionGroup<InvoiceType>(
      title: AppStrings.invoiceType,
      items: InvoiceType.values,
      selectedItem: selectedType,
      itemLabel: (item) => item.label(isArabic),
      itemIcon: (item) => item.icon,
      onSelect: (val) {
        if (val != null) onSelect(val);
      },
    );
  }
}

class PaymentMethodSelection extends StatelessWidget {
  final bool isArabic;
  final PaymentMethod selectedMethod;
  final Function(PaymentMethod) onSelect;

  const PaymentMethodSelection({
    super.key,
    required this.isArabic,
    required this.selectedMethod,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return AppSelectionGroup<PaymentMethod>(
      title: AppStrings.paymentMethod,
      items: PaymentMethod.values,
      selectedItem: selectedMethod,
      itemLabel: (item) => item.label(isArabic),
      itemIcon: (item) => item.icon,
      onSelect: (val) {
        if (val != null) onSelect(val);
      },
    );
  }
}

class PaidAmountField extends StatelessWidget {
  final bool isArabic;
  final String currency;
  final double total;
  final TextEditingController controller;
  final VoidCallback onChanged;

  const PaidAmountField({
    super.key,
    required this.isArabic,
    required this.currency,
    required this.total,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
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
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          decoration: InputDecoration(hintText: AppStrings.enterPaidAmount),
          onChanged: (v) {
            final val = double.tryParse(v) ?? 0;
            if (val > total) {
              controller.text = total.toStringAsFixed(2);
              controller.selection = TextSelection.fromPosition(
                TextPosition(offset: controller.text.length),
              );
            }
            onChanged();
          },
        ),
      ],
    );
  }
}
