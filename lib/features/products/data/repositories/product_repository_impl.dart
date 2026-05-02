import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_local_datasource.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductLocalDataSource localDataSource;

  ProductRepositoryImpl(this.localDataSource);

  @override
  Future<List<Product>> getProductsPaginated(int limit, int offset, {String? query}) async {
    return await localDataSource.getProductsPaginated(limit, offset, query: query);
  }

  @override
  Future<Product?> getProductByCode(String code) async {
    return await localDataSource.getProductByCode(code);
  }

  @override
  Future<void> addProduct(Product product) async {
    await localDataSource.addProduct(ProductModel.fromEntity(product));
  }

  @override
  Future<void> updateProduct(Product product) async {
    await localDataSource.updateProduct(ProductModel.fromEntity(product));
  }

  @override
  Future<void> saveBulkProducts(List<Product> products) async {
    final models = products.map((e) => ProductModel.fromEntity(e)).toList();
    await localDataSource.saveBulkProducts(models);
  }

  @override
  Future<List<Product>> getAllProducts() async {
    return await localDataSource.getAllProducts();
  }

  @override
  Future<List<Product>> getProductsByCodes(List<String> codes) async {
    return await localDataSource.getProductsByCodes(codes);
  }
}
