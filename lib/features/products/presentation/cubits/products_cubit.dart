import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/product.dart';
import '../../domain/usecases/add_product.dart';
import '../../domain/usecases/get_product_by_code.dart';
import '../../domain/usecases/get_products_paginated.dart';
import '../../domain/usecases/update_product.dart';
import 'products_state.dart';

class ProductsCubit extends Cubit<ProductsState> {
  final GetProductsPaginated getProductsPaginated;
  final GetProductByCode getProductByCode;
  final AddProduct addProduct;
  final UpdateProduct updateProduct;

  static const int _pageSize = 20;
  int _currentOffset = 0;
  String? _query;

  ProductsCubit({
    required this.getProductsPaginated,
    required this.getProductByCode,
    required this.addProduct,
    required this.updateProduct,
  }) : super(ProductsInitial());

  Future<void> searchProducts(String query) async {
    _query = query;
    await loadProducts(refresh: true);
  }

  Future<void> loadProducts({bool refresh = false}) async {
    if (refresh) {
      _currentOffset = 0;
      emit(ProductsLoading());
    } else {
      if (state is ProductsLoaded) {
        final currentState = state as ProductsLoaded;
        if (!currentState.hasMore || currentState.isLoadingMore) return;
        emit(currentState.copyWith(isLoadingMore: true));
      } else {
        emit(ProductsLoading());
      }
    }

    try {
      final products = await getProductsPaginated(_pageSize, _currentOffset, query: _query);
      final hasMore = products.length == _pageSize;

      if (state is ProductsLoaded && !refresh) {
        final currentState = state as ProductsLoaded;
        emit(ProductsLoaded(
          products: currentState.products + products,
          hasMore: hasMore,
          isLoadingMore: false,
        ));
      } else {
        emit(ProductsLoaded(
          products: products,
          hasMore: hasMore,
        ));
      }

      _currentOffset += products.length;
    } catch (e) {
      emit(ProductsError(e.toString()));
    }
  }

  Future<void> scanBarcode(String code) async {
    try {
      final product = await getProductByCode(code);
      emit(ProductScanResult(product: product, code: code));
      // Re-emit the previous loaded state if available so the UI doesn't lose the list
      // Note: In a real app, you might want to use a separate cubit or a stream for events
    } catch (e) {
      emit(ProductsError(e.toString()));
    }
  }

  Future<void> saveProduct(Product product, {bool isUpdate = false}) async {
    try {
      if (isUpdate) {
        await updateProduct(product);
      } else {
        await addProduct(product);
      }
      // Refresh the list after adding/updating
      await loadProducts(refresh: true);
    } catch (e) {
      emit(ProductsError(e.toString()));
    }
  }
}
