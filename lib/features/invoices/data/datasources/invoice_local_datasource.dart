import '../../../../core/database/database_helper.dart';
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
  Future<List<InvoiceItem>> getInvoiceItems(int invoiceId);
  Future<void> deleteInvoice(int id);
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
      whereClauses.add('createdAt BETWEEN ? AND ?');
      whereArgs.add(startDate.toIso8601String());
      whereArgs.add(endDate.toIso8601String());
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
  Future<void> deleteInvoice(int id) async {
    await _dbHelper.deleteInvoice(id);
  }
}
