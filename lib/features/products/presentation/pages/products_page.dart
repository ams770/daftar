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
      create: (_) => sl<ProductsCubit>()..loadProducts(),
      child: const ProductsView(),
    );
  }
}

class ProductsView extends StatefulWidget {
  const ProductsView({super.key});

  @override
  State<ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends State<ProductsView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
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
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.fileUp),
            onPressed: () => _showImportInstructions(context),
            tooltip: 'Import Excel',
          ),
          IconButton(
            icon: const Icon(LucideIcons.fileDown),
            onPressed: () => context.read<ProductsCubit>().exportToExcel(),
            tooltip: 'Export Excel',
          ),
          const Gap(AppSpacing.sm),
        ],
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: SearchInputField(
              onChanged: (query) {
                context.read<ProductsCubit>().searchProducts(query);
              },
              onScannerTap: () => _openScanner(context),
            ),
          ),
          BlocConsumer<ProductsCubit, ProductsState>(
            listener: (context, state) {
              if (state is ProductScanResult) {
                _handleScanResult(context, state);
              } else if (state is ExcelValidationLoading) {
                _showLoadingDialog(context, 'Validating Excel data...');
              } else if (state is ExcelValidationLoaded) {
                Navigator.pop(context); // Hide loading
                _showValidationPage(context, state.excelProducts);
              } else if (state is ProductsImportSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Products imported successfully!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } else if (state is ProductsExportSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Products exported successfully!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } else if (state is ProductsError) {
                if (Navigator.canPop(context)) Navigator.pop(context); // Hide loading if showing
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.danger,
                  ),
                );
              }
            },
            buildWhen: (previous, current) =>
                current is ProductsLoading || current is ProductsLoaded || current is ProductsError,
            builder: (context, state) {
              if (state is ProductsLoading) {
                return const SliverProductListShimmer();
              }

              if (state is ProductsError) {
                return SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'Error: ${state.message}',
                      style: AppTypography.bodyMd.copyWith(color: AppColors.danger),
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
                          Icon(LucideIcons.package2, size: 64, color: AppColors.grey.withOpacity(0.5)),
                          const Gap(AppSpacing.lg),
                          Text(
                            'No products found.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMd.copyWith(color: AppColors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == state.products.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                            child: ProductShimmer(),
                          );
                        }

                        final product = state.products[index];
                        return _ProductCard(product: product);
                      },
                      childCount: state.products.length + (state.hasMore ? 1 : 0),
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

  void _openScanner(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _ScannerBottomSheet(),
    );

    if (result != null && mounted) {
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
          context.read<ProductsCubit>().saveProduct(product, isUpdate: isUpdate);
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
      context.read<ProductsCubit>().pickAndValidateExcel();
    }
  }

  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const Gap(AppSpacing.xl),
            Expanded(child: Text(message, style: AppTypography.bodyMd)),
          ],
        ),
      ),
    );
  }

  void _showValidationPage(BuildContext context, List<ExcelProduct> products) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<ProductsCubit>(),
          child: ExcelValidationPage(products: products),
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
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: bento.cardDecoration,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.h2.copyWith(fontSize: 16),
                ),
                const Gap(AppSpacing.xs),
                Text(
                  'SR ${product.price.toStringAsFixed(2)}',
                  style: AppTypography.h1.copyWith(
                    fontSize: 18,
                    color: AppColors.secondary,
                  ),
                ),
                const Gap(AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    product.code,
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.greyDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => ProductDialog(
                    product: product,
                    onSave: (updatedProduct, isUpdate) {
                      context.read<ProductsCubit>().saveProduct(updatedProduct, isUpdate: isUpdate);
                    },
                  ),
                );
              },
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Icon(LucideIcons.pencil, size: 20, color: AppColors.grey),
              ),
            ),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
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
            child: const Center(
              child: Text(
                'Center the barcode in the frame',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
