import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:gap/gap.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/bento_theme_extension.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/presentation/cubits/products_cubit.dart';
import '../../../products/presentation/cubits/products_state.dart';
import '../cubits/invoice_cubit.dart';
import 'invoice_summary_page.dart';

class NewInvoicePage extends StatefulWidget {
  const NewInvoicePage({super.key});

  @override
  State<NewInvoicePage> createState() => _NewInvoicePageState();
}

class _NewInvoicePageState extends State<NewInvoicePage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final productsState = context.read<ProductsCubit>().state;
    if (productsState is ProductsLoaded) {
      context.read<InvoiceCubit>().startNewInvoice(productsState.products);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Products'),
      ),
      body: Column(
        children: [
          _buildSearchAndScan(context),
          Expanded(
            child: BlocBuilder<ProductsCubit, ProductsState>(
              builder: (context, state) {
                if (state is ProductsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is ProductsLoaded) {
                  return _buildProductList(context, state.products);
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildSearchAndScan(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(LucideIcons.search),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
              onChanged: (v) => context.read<ProductsCubit>().searchProducts(v),
            ),
          ),
          const Gap(AppSpacing.md),
          GestureDetector(
            onTap: () => _openScanner(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: const Icon(LucideIcons.scanLine, color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList(BuildContext context, List<Product> products) {
    return BlocBuilder<InvoiceCubit, InvoiceState>(
      builder: (context, state) {
        final Map<int, int> cart = (state is InvoiceCreating) ? state.cartItems : {};

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          itemCount: products.length,
          separatorBuilder: (_, __) => const Gap(AppSpacing.sm),
          itemBuilder: (context, index) {
            final product = products[index];
            final qty = cart[product.id] ?? 0;
            return _ProductSelectionCard(
              product: product,
              qty: qty,
              onAdd: () => context.read<InvoiceCubit>().updateProductQty(product, 1),
              onRemove: () => context.read<InvoiceCubit>().updateProductQty(product, -1),
            );
          },
        );
      },
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return BlocBuilder<InvoiceCubit, InvoiceState>(
      builder: (context, state) {
        if (state is! InvoiceCreating) return const SizedBox();
        
        final cart = state.cartItems;
        if (cart.isEmpty) return const SizedBox();

        final totalItems = cart.values.fold(0, (sum, q) => sum + q);

        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.white,
            boxShadow: [
              BoxShadow(
                color: AppColors.text.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InvoiceSummaryPage()),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('CONTINUE TO SUMMARY'),
                  const Gap(AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$totalItems items', style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openScanner(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _ScannerBottomSheet(),
    );

    if (result != null) {
      _searchController.text = result;
      if (mounted) {
        context.read<ProductsCubit>().searchProducts(result);
      }
    }
  }
}

class _ProductSelectionCard extends StatelessWidget {
  final Product product;
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _ProductSelectionCard({
    required this.product,
    required this.qty,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final bento = Theme.of(context).extension<BentoThemeExtension>()!;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: bento.cardDecoration,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: AppTypography.bodyLg.copyWith(fontWeight: FontWeight.w600)),
                const Gap(AppSpacing.xs),
                Text(
                  '${product.price.toStringAsFixed(2)}',
                  style: AppTypography.bodySm.copyWith(color: AppColors.secondary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Row(
            children: [
              if (qty > 0) ...[
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(LucideIcons.circleMinus, color: AppColors.danger),
                ),
                Text('$qty', style: AppTypography.h2.copyWith(fontSize: 16)),
              ],
              IconButton(
                onPressed: onAdd,
                icon: const Icon(LucideIcons.circlePlus, color: AppColors.success),
              ),
            ],
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
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
