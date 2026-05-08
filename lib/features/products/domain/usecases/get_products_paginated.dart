import '../entities/product.dart';
import '../repositories/product_repository.dart';

class GetProductsPaginated {
  final ProductRepository repository;

  GetProductsPaginated(this.repository);

  Future<List<Product>> call(int limit, int offset, {String? query}) {
    return repository.getProductsPaginated(limit, offset, query: query);
  }
}
