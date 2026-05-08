import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../models/product_model.dart';

abstract class ProductLocalDataSource {
  Future<List<ProductModel>> getProductsPaginated(
    int limit,
    int offset, {
    String? query,
  });
  Future<ProductModel?> getProductByCode(String code);
  Future<void> addProduct(ProductModel product);
  Future<void> updateProduct(ProductModel product);
  Future<void> saveBulkProducts(List<ProductModel> products);
  Future<List<ProductModel>> getAllProducts();
  Future<List<ProductModel>> getProductsByCodes(List<String> codes);
  Future<void> deleteProduct(int id);
}

class ProductLocalDataSourceImpl implements ProductLocalDataSource {
  final DatabaseHelper databaseHelper;

  ProductLocalDataSourceImpl(this.databaseHelper);

  @override
  Future<List<ProductModel>> getProductsPaginated(
    int limit,
    int offset, {
    String? query,
  }) async {
    final db = await databaseHelper.database;

    String? where;
    List<dynamic>? whereArgs;

    if (query != null && query.isNotEmpty) {
      where = 'name LIKE ? OR code LIKE ?';
      whereArgs = ['%$query%', '%$query%'];
    }

    final result = await db.query(
      'products',
      where: where,
      whereArgs: whereArgs,
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

  @override
  Future<void> saveBulkProducts(List<ProductModel> products) async {
    final db = await databaseHelper.database;
    final batch = db.batch();
    for (var product in products) {
      batch.insert(
        'products',
        product.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<List<ProductModel>> getAllProducts() async {
    final db = await databaseHelper.database;
    final result = await db.query('products', orderBy: 'name ASC');
    return result.map((json) => ProductModel.fromMap(json)).toList();
  }

  @override
  Future<List<ProductModel>> getProductsByCodes(List<String> codes) async {
    if (codes.isEmpty) return [];

    final db = await databaseHelper.database;
    final List<ProductModel> allResults = [];

    // SQLite has a limit on variables (usually 999), so we chunk the request
    const int chunkSize = 500;
    for (var i = 0; i < codes.length; i += chunkSize) {
      final chunk = codes.sublist(
        i,
        i + chunkSize > codes.length ? codes.length : i + chunkSize,
      );
      final placeholders = List.filled(chunk.length, '?').join(',');

      final result = await db.query(
        'products',
        where: 'code IN ($placeholders)',
        whereArgs: chunk,
      );

      allResults.addAll(result.map((json) => ProductModel.fromMap(json)));
    }

    return allResults;
  }

  @override
  Future<void> deleteProduct(int id) async {
    final db = await databaseHelper.database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }
}
