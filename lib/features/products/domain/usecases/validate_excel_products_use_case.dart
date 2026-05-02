import '../entities/excel_product.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

class ValidateExcelProductsUseCase {
  final ProductRepository repository;

  ValidateExcelProductsUseCase(this.repository);

  Future<List<ExcelProduct>> call(List<ExcelProduct> rawProducts) async {
    if (rawProducts.isEmpty) return [];

    final List<ExcelProduct> validated = [];
    
    // 1. Count occurrences of each code in the raw list to find internal duplicates (O(N))
    final Map<String, int> codeCounts = {};
    for (final raw in rawProducts) {
      codeCounts[raw.code] = (codeCounts[raw.code] ?? 0) + 1;
    }

    // 2. Fetch all potentially existing products in one bulk query (O(BulkQuery))
    final List<String> uniqueCodes = rawProducts.map((e) => e.code).toSet().toList();
    final existingProducts = await repository.getProductsByCodes(uniqueCodes);
    final Map<String, Product> existingMap = {for (var p in existingProducts) p.code: p};

    // 3. Validate each product (O(N))
    for (final raw in rawProducts) {
      // Check for internal duplicates first
      if ((codeCounts[raw.code] ?? 0) > 1) {
        validated.add(raw.copyWith(
          status: ExcelProductStatus.duplicate,
          isValidating: false,
        ));
        continue;
      }

      // If not an internal duplicate, check against cached existing products (external)
      final existingProduct = existingMap[raw.code];
      
      if (existingProduct == null) {
        validated.add(raw.copyWith(
          status: ExcelProductStatus.newProduct,
          isValidating: false,
        ));
      } else {
        final isChanged = existingProduct.name != raw.name || existingProduct.price != raw.price;
        
        validated.add(raw.copyWith(
          status: ExcelProductStatus.duplicate, // Marking external as duplicate per user request
          oldName: existingProduct.name,
          oldPrice: existingProduct.price,
          isValidating: false,
        ));
      }
    }
    
    return validated;
  }
}
