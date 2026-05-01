import '../repositories/product_repository.dart';
import '../entities/product.dart';

class GetProductsPaginated {
  final ProductRepository repository;

  GetProductsPaginated(this.repository);

  Future<List<Product>> call(int limit, int offset) {
    return repository.getProductsPaginated(limit, offset);
  }
}
