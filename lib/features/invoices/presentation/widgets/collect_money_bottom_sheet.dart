import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/money_collection.dart';
import '../cubits/invoice_cubit.dart';
import '../cubits/money_collection_cubit.dart';
import '../pages/money_collection_details_page.dart';

class CollectMoneyBottomSheet extends StatefulWidget {
  final Invoice invoice;

  const CollectMoneyBottomSheet({super.key, required this.invoice});

  @override
  State<CollectMoneyBottomSheet> createState() =>
      _CollectMoneyBottomSheetState();
}

class _CollectMoneyBottomSheetState extends State<CollectMoneyBottomSheet> {
  final TextEditingController _amountController = TextEditingController();
  double _amount = 0.0;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
  }

  void _onAmountChanged() {
    final text = _amountController.text;
    if (text.isEmpty) {
      setState(() => _amount = 0.0);
      return;
    }

    double? val = double.tryParse(text);
    if (val == null) return;

    if (val > widget.invoice.remainingAmount) {
      val = widget.invoice.remainingAmount;
      _amountController.value = TextEditingValue(
        text: val.toStringAsFixed(2),
        selection: TextSelection.collapsed(
          offset: val.toStringAsFixed(2).length,
        ),
      );
    }

    setState(() {
      _amount = val!;
    });
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    super.dispose();
  }

  double get _newRemaining {
    final res = widget.invoice.remainingAmount - _amount;
    return res < 0.001 ? 0.0 : res; // Handle potential precision issues
  }

  bool get _isValid =>
      _amount > 0 && _amount <= (widget.invoice.remainingAmount + 0.001);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.collectMoney,
            style: AppTypography.h2,
            textAlign: TextAlign.center,
          ),
          const Gap(AppSpacing.xl),
          _buildSummaryRow(
            AppStrings.remainingAmount,
            widget.invoice.remainingAmount,
            AppColors.greyDark,
          ),
          const Gap(AppSpacing.sm),
          _buildSummaryRow(
            AppStrings.remainingAfter,
            _newRemaining,
            AppColors.success,
          ),
          const Gap(AppSpacing.xl),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            autofocus: true,
            decoration: InputDecoration(
              labelText: AppStrings.amountToCollect,
              hintText: '0.00',
              prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              suffixText: widget.invoice.currency,
            ),
          ),
          const Gap(AppSpacing.xl),
          ElevatedButton(
            onPressed: _isValid ? _submit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
            child: Text(AppStrings.confirm.toUpperCase()),
          ),
          const Gap(AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, Color amountColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodyMd),
        Text(
          '${amount.toStringAsFixed(2)} ${widget.invoice.currency}',
          style: AppTypography.h3.copyWith(color: amountColor),
        ),
      ],
    );
  }

  void _submit() {
    final collection = MoneyCollection(
      invoiceId: widget.invoice.id!,
      amount: _amount,
      remainingBefore: widget.invoice.remainingAmount,
      remainingAfter: _newRemaining,
      createdAt: DateTime.now(),
      clientName: widget.invoice.clientName,
    );

    context.read<MoneyCollectionCubit>().addCollection(collection).then((id) {
      if (mounted) {
        // Refresh invoices in the main list
        context.read<InvoiceCubit>().loadInvoices(refresh: true);

        if (id != null) {
          final savedCollection = collection.copyWith(id: id);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  MoneyCollectionDetailsPage(collection: savedCollection),
            ),
          );
        } else {
          Navigator.pop(context, true);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.moneyCollectedSuccess),
            backgroundColor: AppColors.success,
          ),
        );
      }
    });
  }
}
