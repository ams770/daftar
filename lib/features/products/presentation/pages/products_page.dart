import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:gap/gap.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/bento_theme_extension.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/loading_dialog.dart';
import '../../../settings/presentation/cubits/settings_cubit.dart';
import '../../domain/entities/excel_product.dart';
import '../../domain/entities/product.dart';
import '../widgets/product_dialog.dart';
import '../widgets/product_shimmer.dart';
import '../widgets/search_input_field.dart';
import '../widgets/import_instructions_dialog.dart';
import 'excel_validation_page.dart';
import '../cubits/products_cubit.dart';
import '../cubits/products_state.dart';

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<ProductsCubit>()..loadProducts(),
      child: const ProductsView(),
    );
  }
}

class ProductsView extends StatelessWidget {
  const ProductsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<ProductsCubit>(),
      child: const _ProductsViewContent(),
    );
  }
}

class _ProductsViewContent extends StatefulWidget {
  const _ProductsViewContent();

  @override
  State<_ProductsViewContent> createState() => _ProductsViewContentState();
}

class _ProductsViewContentState extends State<_ProductsViewContent> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ProductsCubit>().loadProducts();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.secondary,
            actions: [
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.white,
                  foregroundColor: AppColors.secondary,
                ),
                icon: const Icon(LucideIcons.plus),
                onPressed: () => _showAddProductDialog(context),
                tooltip: AppStrings.addProduct,
              ),
              const Gap(AppSpacing.md),
            ],
            title: Text(AppStrings.inventory),
          ),
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.secondary,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                children: [
                  SearchInputField(
                    onChanged: (query) {
                      context.read<ProductsCubit>().searchProducts(query);
                    },
                    onScannerTap: () => _openScanner(context),
                  ),
                  const Gap(AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          onPressed: () => _showImportInstructions(context),
                          icon: LucideIcons.fileSpreadsheet,
                          label: 'Import Excel',
                          color: AppColors.white,
                        ),
                      ),
                      const Gap(AppSpacing.md),
                      Expanded(
                        child: _ActionButton(
                          onPressed: () =>
                              context.read<ProductsCubit>().exportToExcel(),
                          icon: LucideIcons.fileDown,
                          label: 'Export Excel',
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          BlocConsumer<ProductsCubit, ProductsState>(
            listener: (context, state) {
              if (state is ProductScanResult) {
                _handleScanResult(context, state);
              } else if (state is ProductsExportLoading) {
                LoadingDialog.show(context, message: AppStrings.extractingData);
              } else if (state is ProductsExportSuccess) {
                LoadingDialog.hide(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppStrings.productsExported),
                    backgroundColor: AppColors.success,
                  ),
                );
              } else if (state is ProductsImportSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppStrings.productsImported),
                    backgroundColor: AppColors.success,
                  ),
                );
              } else if (state is ProductsError) {
                // If we were showing a dialog, hide it
                // We use a try-catch or just pop if we are in a loading state that uses a dialog
                if (Navigator.canPop(context)) {
                  // This is still not perfect but better
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.danger,
                  ),
                );
              }
            },
            buildWhen: (previous, current) =>
                current is ProductsLoading ||
                current is ProductsLoaded ||
                current is ProductsError,
            builder: (context, state) {
              if (state is ProductsInitial || state is ProductsLoading) {
                return const SliverProductListShimmer();
              }

              if (state is ProductsError) {
                return SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'Error: ${state.message}',
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                );
              }

              if (state is ProductsLoaded) {
                if (state.products.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            LucideIcons.box,
                            size: 48,
                            color: AppColors.grey,
                          ),
                          const Gap(AppSpacing.md),
                          Text(
                            AppStrings.noProducts,
                            style: AppTypography.bodyMd,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverSafeArea(
                  top: false,
                  sliver: SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 500,
                            mainAxisExtent: 80,
                            crossAxisSpacing: AppSpacing.xxs,
                            mainAxisSpacing: AppSpacing.xxs,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        return _ProductCard(product: state.products[index]);
                      }, childCount: state.products.length),
                    ),
                  ),
                );
              }

              return const SliverToBoxAdapter(child: SizedBox());
            },
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductDialog(
        onSave: (product, isUpdate) {
          context.read<ProductsCubit>().saveProduct(
            product,
            isUpdate: isUpdate,
          );
        },
      ),
    );
  }

  void _openScanner(BuildContext context) async {
    final String? result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ScannerBottomSheet(),
    );

    if (result != null && context.mounted) {
      context.read<ProductsCubit>().scanBarcode(result);
    }
  }

  void _handleScanResult(BuildContext context, ProductScanResult result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductDialog(
        product: result.product,
        initialCode: result.code,
        onSave: (product, isUpdate) {
          context.read<ProductsCubit>().saveProduct(
            product,
            isUpdate: isUpdate,
          );
        },
      ),
    );
  }

  void _showImportInstructions(BuildContext context) async {
    final shouldPick = await showDialog<bool>(
      context: context,
      builder: (_) => const ImportInstructionsDialog(),
    );

    if (shouldPick == true && mounted) {
      final path = await context.read<ProductsCubit>().pickExcelFile();
      if (path != null && mounted) {
        _navigateToValidationPage(context, path);
      }
    }
  }

  void _navigateToValidationPage(BuildContext context, String path) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<ProductsCubit>(),
          child: ExcelValidationPage(filePath: path),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color color;

  const _ActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const Gap(AppSpacing.sm),
            Text(
              label,
              style: AppTypography.bodySm.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final bento = Theme.of(context).extension<BentoThemeExtension>()!;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: bento.cardDecoration,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyLg.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                const Gap(AppSpacing.xxs),
                Row(
                  children: [
                    Text(
                      product.price.toStringAsFixed(2),
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Gap(AppSpacing.md),
                    Icon(LucideIcons.barcode, size: 12, color: AppColors.grey),
                    const Gap(AppSpacing.xxs),
                    Text(
                      product.code,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.greyDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _showDeleteConfirmation(context),
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
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => ProductDialog(
                      product: product,
                      onSave: (updatedProduct, isUpdate) {
                        context.read<ProductsCubit>().saveProduct(
                          updatedProduct,
                          isUpdate: isUpdate,
                        );
                      },
                    ),
                  );
                },
                icon: const Icon(
                  LucideIcons.pencilLine,
                  size: 18,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppStrings.deleteProduct),
        content: Text(AppStrings.deleteProductConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppStrings.cancel.toUpperCase()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<ProductsCubit>().removeProduct(product.id!);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(AppStrings.delete.toUpperCase()),
          ),
        ],
      ),
    );
  }
}

class _ScannerBottomSheet extends StatelessWidget {
  const _ScannerBottomSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? code = barcodes.first.rawValue;
                if (code != null) {
                  Navigator.pop(context, code);
                }
              }
            },
          ),
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                AppStrings.centerBarcode,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
