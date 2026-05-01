import '../../../../core/database/database_helper.dart';
import '../models/product_model.dart';

abstract class ProductLocalDataSource {
  Future<List<ProductModel>> getProductsPaginated(int limit, int offset);
  Future<ProductModel?> getProductByCode(String code);
  Future<void> addProduct(ProductModel product);
  Future<void> updateProduct(ProductModel product);
}

class ProductLocalDataSourceImpl implements ProductLocalDataSource {
  final DatabaseHelper databaseHelper;

  ProductLocalDataSourceImpl(this.databaseHelper);

  @override
  Future<List<ProductModel>> getProductsPaginated(int limit, int offset) async {
    final db = await databaseHelper.database;
    final result = await db.query(
      'products',
      limit: limit,
      offset: offset,
      orderBy: 'id DESC',
    );
    return result.map((json) => ProductModel.fromMap(json)).toList();
  }

  @override
  Future<ProductModel?> getProductByCode(String code) async {
    final db = await databaseHelper.database;
    final result = await db.query(
      'products',
      where: 'code = ?',
      whereArgs: [code],
    );

    if (result.isNotEmpty) {
      return ProductModel.fromMap(result.first);
    } else {
      return null;
    }
  }

  @override
  Future<void> addProduct(ProductModel product) async {
    final db = await databaseHelper.database;
    await db.insert('products', product.toMap());
  }

  @override
  Future<void> updateProduct(ProductModel product) async {
    final db = await databaseHelper.database;
    await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }
}
