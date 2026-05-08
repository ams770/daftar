import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:lottie/lottie.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/daftar_theme_extension.dart';
import '../../domain/entities/excel_product.dart';
import '../cubits/products_cubit.dart';
import '../cubits/products_state.dart';

class ExcelValidationPage extends StatefulWidget {
  final String filePath;

  const ExcelValidationPage({super.key, required this.filePath});

  @override
  State<ExcelValidationPage> createState() => _ExcelValidationPageState();
}

class _ExcelValidationPageState extends State<ExcelValidationPage> {
  @override
  void initState() {
    super.initState();
    // Start validation as soon as page is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductsCubit>().validateExcel(widget.filePath);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductsCubit, ProductsState>(
      buildWhen: (previous, current) =>
          current is ExcelValidationLoading ||
          current is ExcelValidationLoaded ||
          current is ProductsError,
      builder: (context, state) {
        bool isLoading = state is ExcelValidationLoading;
        List<ExcelProduct> products = [];
        if (state is ExcelValidationLoaded) {
          products = state.excelProducts;
        }

        return Scaffold(
          appBar: AppBar(title: Text(AppStrings.importExcel)),
          body: _buildBody(context, state, products, isLoading),
          bottomNavigationBar: _buildBottomBar(context, products, isLoading),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    ProductsState state,
    List<ExcelProduct> products,
    bool isLoading,
  ) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/lottie/loading-data.json',
              width: 250,
              height: 250,
            ),
            const Gap(AppSpacing.lg),
            Text(
              AppStrings.extractingData,
              style: AppTypography.h3.copyWith(color: AppColors.secondary),
            ),
          ],
        ),
      );
    }

    if (state is ProductsError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                LucideIcons.circleAlert,
                size: 64,
                color: AppColors.danger,
              ),
              const Gap(AppSpacing.lg),
              Text(
                state.message,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd,
              ),
              const Gap(AppSpacing.xl),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppStrings.confirm),
              ),
            ],
          ),
        ),
      );
    }

    if (products.isEmpty) {
      return Center(child: Text(AppStrings.noProducts));
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            margin: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.info,
                  color: AppColors.secondary,
                  size: 18,
                ),
                const Gap(AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${products.length} products found. Review before importing.',
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.text,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (products.any(
                        (p) => p.status == ExcelProductStatus.duplicate,
                      )) ...[
                        const Gap(AppSpacing.xxs),
                        InkWell(
                          onTap: () =>
                              context.read<ProductsCubit>().removeDuplicates(),
                          child: Text(
                            'Click here to remove duplicated records',
                            style: AppTypography.bodySm.copyWith(
                              color: AppColors.danger,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 500,
              mainAxisExtent: 80,
              crossAxisSpacing: AppSpacing.xxs,
              mainAxisSpacing: AppSpacing.xxs,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final product = products[index];
              return _ExcelProductCard(
                product: product,
                onEdit: () => _editProduct(context, index, product),
                onRemove: () =>
                    context.read<ProductsCubit>().removeExcelProduct(index),
              );
            }, childCount: products.length),
          ),
        ),
      ],
    );
  }

  void _editProduct(BuildContext context, int index, ExcelProduct product) {
    final nameController = TextEditingController(text: product.name);
    final codeController = TextEditingController(text: product.code);
    final priceController = TextEditingController(
      text: product.price.toString(),
    );

    showDialog(
      context: context,
      builder: (diagContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        title: Text(AppStrings.editProduct, style: AppTypography.h2),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: AppStrings.productName),
              style: AppTypography.bodyMd,
            ),
            const Gap(AppSpacing.md),
            TextField(
              controller: codeController,
              decoration: InputDecoration(labelText: AppStrings.productCode),
              style: AppTypography.bodyMd,
            ),
            const Gap(AppSpacing.md),
            TextField(
              controller: priceController,
              decoration: InputDecoration(labelText: AppStrings.price),
              style: AppTypography.bodyMd,
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(diagContext),
            child: Text(
              AppStrings.cancel,
              style: AppTypography.bodyMd.copyWith(color: AppColors.grey),
            ),
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
            child: Text(
              AppStrings.save,
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildBottomBar(
    BuildContext context,
    List<ExcelProduct> products,
    bool isLoading,
  ) {
    if (isLoading || products.isEmpty) return null;

    final hasDuplicates = products.any(
      (p) => p.status == ExcelProductStatus.duplicate,
    );

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        MediaQuery.of(context).padding.bottom + AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 54),
          backgroundColor: hasDuplicates
              ? AppColors.greyLight
              : AppColors.secondary,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
        onPressed: hasDuplicates
            ? null
            : () {
                context.read<ProductsCubit>().importValidatedProducts();
                Navigator.pop(context);
              },
        child: Text(
          AppStrings.import.toUpperCase(),
          style: AppTypography.label.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
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
    final daftar = Theme.of(context).extension<DaftarThemeExtension>()!;
    final statusColor = _getStatusColor(product.status);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xxs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: daftar.cardDecoration.copyWith(
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyLg.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Gap(AppSpacing.sm),
                    _StatusBadge(status: product.status),
                  ],
                ),
                const Gap(AppSpacing.xxs),
                Row(
                  children: [
                    Text(
                      product.price.toStringAsFixed(2),
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    if ((product.status == ExcelProductStatus.changed ||
                            product.status == ExcelProductStatus.duplicate) &&
                        product.oldPrice != null &&
                        product.oldPrice != product.price) ...[
                      const Gap(AppSpacing.xs),
                      Text(
                        '(${product.oldPrice?.toStringAsFixed(2)})',
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.grey,
                          decoration: TextDecoration.lineThrough,
                          fontSize: 10,
                        ),
                      ),
                    ],
                    const Gap(AppSpacing.md),
                    Icon(LucideIcons.barcode, size: 12, color: AppColors.grey),
                    const Gap(AppSpacing.xxs),
                    Expanded(
                      child: Text(
                        product.code,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySm.copyWith(
                          color: product.status == ExcelProductStatus.duplicate
                              ? AppColors.danger
                              : AppColors.greyDark,
                          fontWeight:
                              product.status == ExcelProductStatus.duplicate
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Gap(AppSpacing.sm),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onRemove,
                icon: const Icon(
                  LucideIcons.trash2,
                  size: 18,
                  color: AppColors.danger,
                ),
              ),
              const Gap(AppSpacing.sm),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onEdit,
                icon: const Icon(
                  LucideIcons.pencil,
                  size: 18,
                  color: AppColors.grey,
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
