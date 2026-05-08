import 'package:flutter/foundation.dart';

import '../entities/excel_product.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

class ImportExcelProductsUseCase {
  final ProductRepository repository;

  ImportExcelProductsUseCase(this.repository);

  Future<void> call(List<ExcelProduct> excelProducts) async {
    // Mapping potentially thousands of items can be done in an isolate
    final productsToSave = await compute(_transformToProducts, excelProducts);

    await repository.saveBulkProducts(productsToSave);
  }

  static List<Product> _transformToProducts(List<ExcelProduct> excelProducts) {
    return excelProducts
        .map((e) => Product(name: e.name, code: e.code, price: e.price))
        .toList();
  }
}
