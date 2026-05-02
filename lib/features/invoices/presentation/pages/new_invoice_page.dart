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
import '../widgets/product_selection_card.dart';
import '../widgets/scanner_bottom_sheet.dart';
import '../widgets/new_invoice_search_header.dart';
import '../widgets/new_invoice_bottom_bar.dart';

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
          NewInvoiceSearchHeader(
            controller: _searchController,
            onChanged: (v) => context.read<ProductsCubit>().searchProducts(v),
            onScanTap: () => _openScanner(context),
          ),
          Expanded(
            child: BlocBuilder<ProductsCubit, ProductsState>(
              builder: (context, state) {
                if (state is ProductsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is ProductsLoaded) {
                  return BlocBuilder<InvoiceCubit, InvoiceState>(
                    builder: (context, invState) {
                      final Map<int, int> cart = (invState is InvoiceCreating) ? invState.cartItems : {};

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        itemCount: state.products.length,
                        separatorBuilder: (_, __) => const Gap(AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final product = state.products[index];
                          final qty = cart[product.id] ?? 0;
                          return ProductSelectionCard(
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
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const NewInvoiceBottomBar(),
    );
  }

  void _openScanner(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ScannerBottomSheet(),
    );

    if (result != null) {
      _searchController.text = result;
      if (mounted) {
        context.read<ProductsCubit>().searchProducts(result);
      }
    }
  }
}

