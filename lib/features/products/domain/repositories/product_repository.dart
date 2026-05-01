import '../entities/product.dart';

abstract class ProductRepository {
  Future<List<Product>> getProductsPaginated(int limit, int offset);
  Future<Product?> getProductByCode(String code);
  Future<void> addProduct(Product product);
  Future<void> updateProduct(Product product);
}
