import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/product.dart';

class ProductDialog extends StatefulWidget {
  final Product? product;
  final String? initialCode;
  final void Function(Product product, bool isUpdate) onSave;

  const ProductDialog({
    super.key,
    this.product,
    this.initialCode,
    required this.onSave,
  });

  @override
  State<ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<ProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _codeController = TextEditingController(text: widget.product?.code ?? widget.initialCode ?? '');
    _priceController = TextEditingController(text: widget.product?.price.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isUpdate = widget.product != null;
    final bool fromScan = widget.initialCode != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
        ),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.greyLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Gap(AppSpacing.xl),
              Text(
                isUpdate ? 'Edit Product' : (fromScan ? 'Add New Product' : 'Add Product'),
                style: AppTypography.h1,
                textAlign: TextAlign.center,
              ),
              if (fromScan && !isUpdate) ...[
                const Gap(AppSpacing.sm),
                Text(
                  'Barcode "${widget.initialCode}" not found.',
                  style: AppTypography.bodyMd.copyWith(color: AppColors.warning, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ],
              const Gap(AppSpacing.xl),
              TextFormField(
                controller: _nameController,
                maxLength: 100,
                style: AppTypography.bodyMd,
                decoration: InputDecoration(
                  labelText: 'Product Name',
                  prefixIcon: const Icon(LucideIcons.shoppingBag, size: 20),
                  counterText: '',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (value.length > 100) return 'Too long (max 100 chars)';
                  return null;
                },
              ),
              const Gap(AppSpacing.lg),
              TextFormField(
                controller: _codeController,
                style: AppTypography.bodyMd,
                decoration: const InputDecoration(
                  labelText: 'Product Code',
                  prefixIcon: Icon(LucideIcons.qrCode, size: 20),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const Gap(AppSpacing.lg),
              TextFormField(
                controller: _priceController,
                style: AppTypography.bodyMd,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Price',
                  prefixIcon: Icon(LucideIcons.dollarSign, size: 20),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (double.tryParse(value) == null) return 'Invalid number';
                  return null;
                },
              ),
              const Gap(AppSpacing.xxl),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final product = Product(
                      id: widget.product?.id,
                      name: _nameController.text,
                      code: _codeController.text,
                      price: double.parse(_priceController.text),
                    );
                    widget.onSave(product, isUpdate);
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  elevation: 8,
                  shadowColor: AppColors.secondary.withValues(alpha: 0.4),
                ),
                child: Text(
                  isUpdate ? 'Update Product' : 'Save Product',
                  style: AppTypography.label.copyWith(
                    color: AppColors.white,
                    fontSize: 16,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
