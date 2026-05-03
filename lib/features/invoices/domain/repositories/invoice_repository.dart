import '../entities/money_collection.dart';
import '../../domain/entities/invoice.dart';

abstract class InvoiceRepository {
  Future<int> saveInvoice(Invoice invoice);
  Future<List<Invoice>> getInvoicesPaginated({
    required int limit,
    required int offset,
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<Invoice?> getInvoiceById(int id);
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
