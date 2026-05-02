import 'package:equatable/equatable.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/excel_product.dart';

abstract class ProductsState extends Equatable {
  const ProductsState();

  @override
  List<Object?> get props => [];
}

class ProductsInitial extends ProductsState {}

class ProductsLoading extends ProductsState {}

class ProductsLoaded extends ProductsState {
  final List<Product> products;
  final bool hasMore;
  final bool isLoadingMore;

  const ProductsLoaded({
    required this.products,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  ProductsLoaded copyWith({
    List<Product>? products,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return ProductsLoaded(
      products: products ?? this.products,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [products, hasMore, isLoadingMore];
}

class ProductsError extends ProductsState {
  final String message;
  const ProductsError(this.message);

  @override
  List<Object?> get props => [message];
}

class ProductScanResult extends ProductsState {
  final Product? product;
  final String code;

  const ProductScanResult({this.product, required this.code});

  @override
  List<Object?> get props => [product, code];
}

class ExcelValidationLoading extends ProductsState {}

class ExcelValidationLoaded extends ProductsState {
  final List<ExcelProduct> excelProducts;
  const ExcelValidationLoaded(this.excelProducts);

  @override
  List<Object?> get props => [excelProducts];
}

class ProductsImportSuccess extends ProductsState {}
class ProductsExportSuccess extends ProductsState {}
