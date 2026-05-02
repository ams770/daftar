import '../entities/excel_product.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

class ImportExcelProductsUseCase {
  final ProductRepository repository;

  ImportExcelProductsUseCase(this.repository);

  Future<void> call(List<ExcelProduct> excelProducts) async {
    final productsToSave = excelProducts.map((e) => Product(
      name: e.name,
      code: e.code,
      price: e.price,
    )).toList();

    await repository.saveBulkProducts(productsToSave);
  }
}
