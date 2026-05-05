import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../products/domain/repositories/product_repository.dart';
import '../cubits/add_invoice_cubit.dart';
import '../../../../core/di/injection.dart' as di;
import 'invoice_summary_page.dart';
import '../widgets/product_selection_card.dart';
import '../../../../core/services/sound_service.dart';

class ScannerInvoicePage extends StatefulWidget {
  const ScannerInvoicePage({super.key});

  @override
  State<ScannerInvoicePage> createState() => _ScannerInvoicePageState();
}

class _ScannerInvoicePageState extends State<ScannerInvoicePage> {
  final MobileScannerController _controller = MobileScannerController();
  String? _lastScannedCode;
  Timer? _resetTimer;
  bool _isProcessing = false;

  @override
  void dispose() {
    _resetTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final code = capture.barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    if (code == _lastScannedCode) {
      // Reset the timer as long as we keep seeing the same code
      _resetTimer?.cancel();
      _resetTimer = Timer(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() => _lastScannedCode = null);
        }
      });
      return;
    }

    // New code detected
    setState(() {
      _lastScannedCode = code;
      _isProcessing = true;
    });

    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _lastScannedCode = null);
      }
    });

    final success = await context.read<AddInvoiceCubit>().addProductByCode(
      code,
      di.sl<ProductRepository>(),
    );

    if (success) {
      SoundService.playScanSound();
      HapticFeedback.mediumImpact();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.productNotFoundInInventory),
            backgroundColor: AppColors.danger,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.quickScan)),
      body: Column(
        children: [
          // Scanner View at the top
          Container(
            height: MediaQuery.sizeOf(context).height * 0.35,
            constraints: const BoxConstraints(maxHeight: 250, maxWidth: 500),
            margin: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: _onDetect,
                ),              
                Center(
                  child: Container(
                    width: 200,
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.white.withValues(alpha: 0.5),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                ),
                if (_isProcessing)
                  const Center(
                    child: CircularProgressIndicator(color: AppColors.white),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.shoppingCart,
                  size: 20,
                  color: AppColors.grey,
                ),
                const Gap(AppSpacing.sm),
                Text(
                  AppStrings.items,
                  style: AppTypography.bodyLg.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Gap(AppSpacing.md),

          // List of scanned products
          Expanded(
            child: BlocBuilder<AddInvoiceCubit, AddInvoiceState>(
              builder: (context, state) {
                if (state is! AddInvoiceCreating) return const SizedBox();

                final cart = state.cartItems;
                final cartItemsList = cart.values.toList();

                if (cartItemsList.isEmpty) {
                  return Center(
                    child: Text(
                      AppStrings.centerBarcode,
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.grey,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  itemCount: cartItemsList.length,
                  separatorBuilder: (_, __) => const Gap(AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final item = cartItemsList[index];
                    final product = item.product;
                    final qty = item.quantity;

                    return ProductSelectionCard(
                      product: product,
                      qty: qty,
                      onAdd: () => context
                          .read<AddInvoiceCubit>()
                          .updateProductQty(product, 1),
                      onRemove: () => context
                          .read<AddInvoiceCubit>()
                          .updateProductQty(product, -1),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BlocBuilder<AddInvoiceCubit, AddInvoiceState>(
        builder: (context, state) {
          final hasItems =
              (state is AddInvoiceCreating) && state.cartItems.isNotEmpty;

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
                onPressed: hasItems
                    ? () {
                        _controller.stop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const InvoiceSummaryPage(),
                          ),
                        ).then((_) {
                          if (mounted) {
                            _controller.start();
                          }
                        });
                      }
                    : null,
                child: Text(AppStrings.confirm.toUpperCase()),
              ),
            ),
          );
        },
      ),
    );
  }
}
