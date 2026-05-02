import '../entities/product.dart';

abstract class ProductRepository {
  Future<List<Product>> getProductsPaginated(int limit, int offset, {String? query});
  Future<Product?> getProductByCode(String code);
  Future<void> addProduct(Product product);
  Future<void> updateProduct(Product product);
  Future<void> saveBulkProducts(List<Product> products);
  Future<List<Product>> getAllProducts();
  Future<List<Product>> getProductsByCodes(List<String> codes);
}
