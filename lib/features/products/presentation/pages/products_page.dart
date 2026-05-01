import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/product.dart';
import '../cubits/products_cubit.dart';
import '../cubits/products_state.dart';
import '../widgets/product_dialog.dart';
import '../widgets/product_shimmer.dart';
import '../widgets/search_input_field.dart';

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
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text(
          'Products Inventory',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
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
              } else if (state is ProductsError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message), backgroundColor: Colors.redAccent),
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
                  child: Center(child: Text('Error: ${state.message}')),
                );
              }

              if (state is ProductsLoaded) {
                if (state.products.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text(
                            'No products found.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == state.products.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
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
}

class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.price.toStringAsFixed(2),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF2D31FA),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  product.code,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.grey),
            onPressed: () {
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
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
          // Custom scanner overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
