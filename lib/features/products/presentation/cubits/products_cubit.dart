import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/excel_service.dart';
import '../../domain/entities/excel_product.dart';
import '../../domain/entities/product.dart';
import '../../domain/usecases/add_product.dart';
import '../../domain/usecases/get_product_by_code.dart';
import '../../domain/usecases/get_products_paginated.dart';
import '../../domain/usecases/update_product.dart';
import '../../domain/usecases/validate_excel_products_use_case.dart';
import '../../domain/usecases/import_excel_products_use_case.dart';
import '../../domain/usecases/export_products_to_excel_use_case.dart';
import 'products_state.dart';

class ProductsCubit extends Cubit<ProductsState> {
  final GetProductsPaginated getProductsPaginated;
  final GetProductByCode getProductByCode;
  final AddProduct addProduct;
  final UpdateProduct updateProduct;
  final ValidateExcelProductsUseCase validateExcelProducts;
  final ImportExcelProductsUseCase importExcelProducts;
  final ExportProductsToExcelUseCase exportProductsToExcel;
  final ExcelService excelService;

  bool _isPickingFile = false;
  static const int _pageSize = 20;
  int _currentOffset = 0;
  String? _query;

  ProductsCubit({
    required this.getProductsPaginated,
    required this.getProductByCode,
    required this.addProduct,
    required this.updateProduct,
    required this.validateExcelProducts,
    required this.importExcelProducts,
    required this.exportProductsToExcel,
    required this.excelService,
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
      await loadProducts(refresh: true);
    } catch (e) {
      emit(ProductsError(e.toString()));
    }
  }

  // --- Excel Features ---

  Future<void> pickAndValidateExcel() async {
    if (_isPickingFile) return;
    _isPickingFile = true;

    try {
      await Future.delayed(const Duration(milliseconds: 500));
      print('DEBUG: Calling FilePicker.platform.pickFiles()...');
      
      // Attempting the simplest possible call
      final result = await FilePicker.pickFiles();
      
      print('DEBUG: FilePicker returned: ${result == null ? "null" : "result with ${result.files.length} files"}');

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        if (!path.toLowerCase().endsWith('.xlsx')) {
          emit(const ProductsError('Please select a valid .xlsx file.'));
          return;
        }
        emit(ExcelValidationLoading());
        
        final file = File(path);
        final rawProducts = await excelService.readProductsFromExcel(file);
        
        if (rawProducts.isEmpty) {
          emit(const ProductsError('The Excel file is empty or invalid.'));
          return;
        }

        final validatedProducts = await validateExcelProducts(rawProducts);
        emit(ExcelValidationLoaded(validatedProducts));
      }
    } catch (e) {
      emit(ProductsError('Failed to pick or process file: $e'));
    } finally {
      _isPickingFile = false;
    }
  }

  Future<void> updateExcelProduct(int index, ExcelProduct updated) async {
    if (state is ExcelValidationLoaded) {
      final products = List<ExcelProduct>.from((state as ExcelValidationLoaded).excelProducts);
      products[index] = updated;
      
      final validated = await validateExcelProducts(products);
      emit(ExcelValidationLoaded(validated));
    }
  }

  Future<void> removeExcelProduct(int index) async {
    if (state is ExcelValidationLoaded) {
      final products = List<ExcelProduct>.from((state as ExcelValidationLoaded).excelProducts);
      products.removeAt(index);
      
      final validated = await validateExcelProducts(products);
      emit(ExcelValidationLoaded(validated));
    }
  }

  Future<void> importValidatedProducts() async {
    if (state is ExcelValidationLoaded) {
      final products = (state as ExcelValidationLoaded).excelProducts;
      try {
        emit(ProductsLoading());
        await importExcelProducts(products);
        emit(ProductsImportSuccess());
        await loadProducts(refresh: true);
      } catch (e) {
        emit(ProductsError('Failed to import products: $e'));
      }
    }
  }

  Future<void> exportToExcel() async {
    try {
      await exportProductsToExcel();
      emit(ProductsExportSuccess());
    } catch (e) {
      emit(ProductsError('Failed to export products: $e'));
    }
  }
}
