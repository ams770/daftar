import '../repositories/product_repository.dart';
import '../entities/product.dart';

class AddProduct {
  final ProductRepository repository;

  AddProduct(this.repository);

  Future<void> call(Product product) {
    return repository.addProduct(product);
  }
}
