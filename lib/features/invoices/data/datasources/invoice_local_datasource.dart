import '../../../../core/database/database_helper.dart';
import '../../domain/entities/money_collection.dart';
import '../../domain/entities/invoice.dart';

abstract class InvoiceLocalDataSource {
  Future<int> saveInvoice(Invoice invoice);
  Future<List<Invoice>> getInvoicesPaginated({
    required int limit,
    required int offset,
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<Invoice?> getInvoiceById(int id);
  Future<List<InvoiceItem>> getInvoiceItems(int invoiceId);
  Future<void> deleteInvoice(int id);

  // Money Collection
  Future<int> saveMoneyCollection(MoneyCollection collection);
  Future<List<MoneyCollection>> getCollectionsPaginated({
    required int limit,
    required int offset,
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<List<MoneyCollection>> getCollectionsByInvoice(int invoiceId);
  Future<void> deleteMoneyCollection(int id);
}

class InvoiceLocalDataSourceImpl implements InvoiceLocalDataSource {
  final DatabaseHelper _dbHelper;

  InvoiceLocalDataSourceImpl(this._dbHelper);

  @override
  Future<int> saveInvoice(Invoice invoice) async {
    final db = await _dbHelper.database;
    return await db.transaction((txn) async {
      // Save invoice
      final invoiceId = await txn.insert('invoices', invoice.toJson());
      
      // Save items
      for (final item in invoice.items) {
        await txn.insert('invoice_items', item.toJson(invoiceId));
      }
      
      return invoiceId;
    });
  }

  @override
  Future<List<Invoice>> getInvoicesPaginated({
    required int limit,
    required int offset,
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _dbHelper.database;
    
    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClauses.add('clientName LIKE ?');
      whereArgs.add('%$searchQuery%');
    }
    
    if (startDate != null && endDate != null) {
      final start = DateTime(startDate.year, startDate.month, startDate.day);
      final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      whereClauses.add('createdAt BETWEEN ? AND ?');
      whereArgs.add(start.toIso8601String());
      whereArgs.add(end.toIso8601String());
    }
    
    final String? where = whereClauses.isEmpty ? null : whereClauses.join(' AND ');

    final List<Map<String, dynamic>> maps = await db.query(
      'invoices',
      where: where,
      whereArgs: whereArgs,
      limit: limit,
      offset: offset,
      orderBy: 'createdAt DESC',
    );
    
    List<Invoice> invoices = [];
    for (final map in maps) {
      final items = await getInvoiceItems(map['id']);
      invoices.add(Invoice.fromJson(map, items));
    }
    return invoices;
  }

  @override
  Future<List<InvoiceItem>> getInvoiceItems(int invoiceId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'invoice_items',
      where: 'invoiceId = ?',
      whereArgs: [invoiceId],
    );
    
    return maps.map((item) => InvoiceItem.fromJson(item)).toList();
  }

  @override
  Future<Invoice?> getInvoiceById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'invoices',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    final items = await getInvoiceItems(id);
    return Invoice.fromJson(maps.first, items);
  }

  @override
  Future<void> deleteInvoice(int id) async {
    await _dbHelper.deleteInvoice(id);
  }

  @override
  Future<int> saveMoneyCollection(MoneyCollection collection) async {
    final db = await _dbHelper.database;
    return await db.transaction((txn) async {
      // 1. Save collection
      final collectionId = await txn.insert('money_collections', collection.toJson());

      // 2. Get current invoice data to update it correctly
      final List<Map<String, dynamic>> invoiceMaps = await txn.query(
        'invoices',
        where: 'id = ?',
        whereArgs: [collection.invoiceId],
      );

      if (invoiceMaps.isNotEmpty) {
        final currentPaid = invoiceMaps.first['paidAmount'] as double;
        final currentRemaining = invoiceMaps.first['remainingAmount'] as double;

        // 3. Update invoice
        await txn.update(
          'invoices',
          {
            'paidAmount': currentPaid + collection.amount,
            'remainingAmount': currentRemaining - collection.amount,
          },
          where: 'id = ?',
          whereArgs: [collection.invoiceId],
        );
      }

      return collectionId;
    });
  }

  @override
  Future<List<MoneyCollection>> getCollectionsPaginated({
    required int limit,
    required int offset,
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _dbHelper.database;
    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    if (searchQuery != null && searchQuery.isNotEmpty) {
      // Try to search by invoice ID or client name
      whereClauses.add('(clientName LIKE ? OR invoiceId = ?)');
      whereArgs.add('%$searchQuery%');
      whereArgs.add(int.tryParse(searchQuery) ?? -1);
    }

    if (startDate != null && endDate != null) {
      final start = DateTime(startDate.year, startDate.month, startDate.day);
      final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      whereClauses.add('createdAt BETWEEN ? AND ?');
      whereArgs.add(start.toIso8601String());
      whereArgs.add(end.toIso8601String());
    }

    final String? where = whereClauses.isEmpty ? null : whereClauses.join(' AND ');

    final List<Map<String, dynamic>> maps = await db.query(
      'money_collections',
      where: where,
      whereArgs: whereArgs,
      limit: limit,
      offset: offset,
      orderBy: 'createdAt DESC',
    );

    return maps.map((m) => MoneyCollection.fromJson(m)).toList();
  }

  @override
  Future<List<MoneyCollection>> getCollectionsByInvoice(int invoiceId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'money_collections',
      where: 'invoiceId = ?',
      whereArgs: [invoiceId],
      orderBy: 'createdAt DESC',
    );
    return maps.map((m) => MoneyCollection.fromJson(m)).toList();
  }

  @override
  Future<void> deleteMoneyCollection(int id) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // 1. Get collection info to know which invoice and how much
      final List<Map<String, dynamic>> collectionMaps = await txn.query(
        'money_collections',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (collectionMaps.isNotEmpty) {
        final collection = MoneyCollection.fromJson(collectionMaps.first);

        // 2. Delete collection
        await txn.delete(
          'money_collections',
          where: 'id = ?',
          whereArgs: [id],
        );

        // 3. Update invoice
        final List<Map<String, dynamic>> invoiceMaps = await txn.query(
          'invoices',
          where: 'id = ?',
          whereArgs: [collection.invoiceId],
        );

        if (invoiceMaps.isNotEmpty) {
          final currentPaid = invoiceMaps.first['paidAmount'] as double;
          final currentRemaining = invoiceMaps.first['remainingAmount'] as double;

          await txn.update(
            'invoices',
            {
              'paidAmount': currentPaid - collection.amount,
              'remainingAmount': currentRemaining + collection.amount,
            },
            where: 'id = ?',
            whereArgs: [collection.invoiceId],
          );
        }
      }
    });
  }
}
