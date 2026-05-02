import '../../../../core/database/database_helper.dart';
import '../../domain/entities/invoice.dart';

abstract class InvoiceLocalDataSource {
  Future<int> saveInvoice(Invoice invoice);
  Future<List<Invoice>> getAllInvoices();
  Future<List<InvoiceItem>> getInvoiceItems(int invoiceId);
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
  Future<List<Invoice>> getAllInvoices() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('invoices', orderBy: 'createdAt DESC');
    
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
}
