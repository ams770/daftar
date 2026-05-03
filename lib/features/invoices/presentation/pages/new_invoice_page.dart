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
import '../cubits/add_invoice_cubit.dart';
import 'scanner_invoice_page.dart';
import 'invoice_summary_page.dart';
import '../widgets/product_selection_card.dart';
import '../widgets/scanner_bottom_sheet.dart';
import '../widgets/new_invoice_search_header.dart';
import '../widgets/new_invoice_bottom_bar.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection.dart';

class NewInvoicePage extends StatelessWidget {
  const NewInvoicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<ProductsCubit>()..loadProducts(),
      child: const NewInvoiceView(),
    );
  }
}

class NewInvoiceView extends StatefulWidget {
  const NewInvoiceView({super.key});

  @override
  State<NewInvoiceView> createState() => _NewInvoiceViewState();
}

class _NewInvoiceViewState extends State<NewInvoiceView> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    context.read<AddInvoiceCubit>().startNewInvoice();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ProductsCubit>().loadProducts();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.selectProducts),
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
                  return BlocBuilder<AddInvoiceCubit, AddInvoiceState>(
                    builder: (context, invState) {
                      final cart = (invState is AddInvoiceCreating) ? invState.cartItems : <int, CartItem>{};

                      return ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        itemCount: state.products.length + (state.hasMore ? 1 : 0),
                        separatorBuilder: (_, __) => const Gap(AppSpacing.sm),
                        itemBuilder: (context, index) {
                          if (index == state.products.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(AppSpacing.md),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final product = state.products[index];
                          final qty = cart[product.id]?.quantity ?? 0;
                          return ProductSelectionCard(
                            product: product,
                            qty: qty,
                            onAdd: () => context.read<AddInvoiceCubit>().updateProductQty(product, 1),
                            onRemove: () => context.read<AddInvoiceCubit>().updateProductQty(product, -1),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ScannerInvoicePage(),
            ),
          );
        },
        icon: const Icon(LucideIcons.scanLine),
        label: Text(AppStrings.quickScan),
        backgroundColor: AppColors.success,
        foregroundColor: AppColors.white,
      ),
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

