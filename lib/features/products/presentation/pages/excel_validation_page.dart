import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/bento_theme_extension.dart';
import '../../domain/entities/excel_product.dart';
import '../cubits/products_cubit.dart';

class ExcelValidationPage extends StatelessWidget {
  final List<ExcelProduct> products;

  const ExcelValidationPage({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Import'),
        actions: [
          Builder(
            builder: (context) {
              final hasDuplicates = products.any((p) => p.status == ExcelProductStatus.duplicate);
              return TextButton(
                onPressed: (products.isEmpty || hasDuplicates)
                    ? null
                    : () {
                        context.read<ProductsCubit>().importValidatedProducts();
                        Navigator.pop(context);
                      },
                child: Text(
                  'IMPORT',
                  style: AppTypography.label.copyWith(
                    color: (products.isEmpty || hasDuplicates) ? AppColors.grey : AppColors.secondary,
                  ),
                ),
              );
            },
          ),
          const Gap(AppSpacing.sm),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              margin: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.info, color: AppColors.secondary, size: 20),
                  const Gap(AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '${products.length} products found. Review before importing.',
                      style: AppTypography.bodySm.copyWith(color: AppColors.text),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final product = products[index];
                  return _ExcelProductCard(
                    product: product,
                    onEdit: () => _editProduct(context, index, product),
                    onRemove: () => context.read<ProductsCubit>().removeExcelProduct(index),
                  );
                },
                childCount: products.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editProduct(BuildContext context, int index, ExcelProduct product) {
    final nameController = TextEditingController(text: product.name);
    final codeController = TextEditingController(text: product.code);
    final priceController = TextEditingController(text: product.price.toString());

    showDialog(
      context: context,
      builder: (diagContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        title: const Text('Edit Row', style: AppTypography.h2),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              style: AppTypography.bodyMd,
            ),
            const Gap(AppSpacing.md),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(labelText: 'Code'),
              style: AppTypography.bodyMd,
            ),
            const Gap(AppSpacing.md),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'Price'),
              style: AppTypography.bodyMd,
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(diagContext),
            child: Text('Cancel', style: AppTypography.bodyMd.copyWith(color: AppColors.grey)),
          ),
          TextButton(
            onPressed: () {
              final updated = product.copyWith(
                name: nameController.text,
                code: codeController.text,
                price: double.tryParse(priceController.text) ?? product.price,
              );
              context.read<ProductsCubit>().updateExcelProduct(index, updated);
              Navigator.pop(diagContext);
            },
            child: Text('Save', style: AppTypography.bodyMd.copyWith(color: AppColors.secondary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _ExcelProductCard extends StatelessWidget {
  final ExcelProduct product;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const _ExcelProductCard({
    required this.product,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final bento = Theme.of(context).extension<BentoThemeExtension>()!;
    final statusColor = _getStatusColor(product.status);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: bento.cardDecoration.copyWith(
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatusBadge(status: product.status),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.pencil, size: 18, color: AppColors.grey),
                    onPressed: onEdit,
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                  const Gap(AppSpacing.md),
                  IconButton(
                    icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.danger),
                    onPressed: onRemove,
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ],
          ),
          const Gap(AppSpacing.md),
          Text(
            product.name,
            style: AppTypography.h2.copyWith(fontSize: 16),
          ),
          if ((product.status == ExcelProductStatus.changed || product.status == ExcelProductStatus.duplicate) && 
              product.oldName != null && product.oldName != product.name)
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text(
                'From: ${product.oldName}',
                style: AppTypography.bodySm.copyWith(color: AppColors.grey, decoration: TextDecoration.lineThrough),
              ),
            ),
          const Gap(AppSpacing.sm),
          Row(
            children: [
              Text(
                'SR ${product.price.toStringAsFixed(2)}',
                style: AppTypography.h1.copyWith(fontSize: 17, color: AppColors.secondary),
              ),
              if ((product.status == ExcelProductStatus.changed || product.status == ExcelProductStatus.duplicate) && 
                  product.oldPrice != null && product.oldPrice != product.price)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    '(${product.oldPrice?.toStringAsFixed(2)})',
                    style: AppTypography.bodySm.copyWith(color: AppColors.grey, decoration: TextDecoration.lineThrough),
                  ),
                ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  product.code,
                  style: AppTypography.bodySm.copyWith(
                    color: product.status == ExcelProductStatus.duplicate ? AppColors.danger : AppColors.greyDark,
                    fontWeight: product.status == ExcelProductStatus.duplicate ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ExcelProductStatus? status) {
    switch (status) {
      case ExcelProductStatus.newProduct:
        return AppColors.success;
      case ExcelProductStatus.exists:
        return AppColors.secondary;
      case ExcelProductStatus.changed:
        return AppColors.warning;
      case ExcelProductStatus.duplicate:
        return AppColors.danger;
      default:
        return AppColors.grey;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final ExcelProductStatus? status;
  const _StatusBadge({this.status});

  @override
  Widget build(BuildContext context) {
    String label = 'NEW';
    Color color = AppColors.success;
    IconData icon = LucideIcons.circlePlus;

    if (status == ExcelProductStatus.exists) {
      label = 'EXISTS';
      color = AppColors.secondary;
      icon = LucideIcons.circleCheck;
    } else if (status == ExcelProductStatus.changed) {
      label = 'UPDATED';
      color = AppColors.warning;
      icon = LucideIcons.refreshCw;
    } else if (status == ExcelProductStatus.duplicate) {
      label = 'DUPLICATE';
      color = AppColors.danger;
      icon = LucideIcons.circleAlert;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const Gap(AppSpacing.xs),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
