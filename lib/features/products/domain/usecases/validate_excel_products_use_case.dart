import 'package:flutter/foundation.dart';

import '../entities/excel_product.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

class ValidateExcelProductsUseCase {
  final ProductRepository repository;

  ValidateExcelProductsUseCase(this.repository);

  Future<List<ExcelProduct>> call(List<ExcelProduct> rawProducts) async {
    if (rawProducts.isEmpty) return [];

    // 1. Fetch all potentially existing products in one bulk query (O(BulkQuery))
    // This part must stay in the main isolate as it involves repository/DB calls
    final List<String> uniqueCodes = rawProducts
        .map((e) => e.code)
        .toSet()
        .toList();
    final existingProducts = await repository.getProductsByCodes(uniqueCodes);
    final Map<String, Product> existingMap = {
      for (var p in existingProducts) p.code: p,
    };

    // 2. Use compute for the heavy lifting of validation logic (comparing lists/maps)
    return await compute(_validateIsolate, {
      'raw': rawProducts,
      'existing': existingMap,
    });
  }

  static List<ExcelProduct> _validateIsolate(Map<String, dynamic> data) {
    final List<ExcelProduct> rawProducts = data['raw'] as List<ExcelProduct>;
    final Map<String, Product> existingMap =
        data['existing'] as Map<String, Product>;
    final List<ExcelProduct> validated = [];

    // Count occurrences of each code in the raw list to find internal duplicates
    final Map<String, int> codeCounts = {};
    for (final raw in rawProducts) {
      codeCounts[raw.code] = (codeCounts[raw.code] ?? 0) + 1;
    }

    // Validate each product
    for (final raw in rawProducts) {
      // Check for internal duplicates first
      if ((codeCounts[raw.code] ?? 0) > 1) {
        validated.add(
          raw.copyWith(
            status: ExcelProductStatus.duplicate,
            isValidating: false,
          ),
        );
        continue;
      }

      // If not an internal duplicate, check against existing products
      final existingProduct = existingMap[raw.code];

      if (existingProduct == null) {
        validated.add(
          raw.copyWith(
            status: ExcelProductStatus.newProduct,
            isValidating: false,
          ),
        );
      } else {
        // Check if data changed
        final bool isChanged =
            raw.name != existingProduct.name ||
            (raw.price - existingProduct.price).abs() > 0.01;

        validated.add(
          raw.copyWith(
            status: isChanged
                ? ExcelProductStatus.changed
                : ExcelProductStatus.exists,
            oldName: existingProduct.name,
            oldPrice: existingProduct.price,
            isValidating: false,
          ),
        );
      }
    }

    return validated;
  }
}
