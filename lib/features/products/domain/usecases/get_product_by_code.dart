import '../entities/product.dart';
import '../repositories/product_repository.dart';

class GetProductByCode {
  final ProductRepository repository;

  GetProductByCode(this.repository);

  Future<Product?> call(String code) {
    return repository.getProductByCode(code);
  }
}
