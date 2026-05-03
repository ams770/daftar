import '../../domain/entities/money_collection.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../datasources/invoice_local_datasource.dart';

class InvoiceRepositoryImpl implements InvoiceRepository {
  final InvoiceLocalDataSource localDataSource;

  InvoiceRepositoryImpl(this.localDataSource);

  @override
  Future<int> saveInvoice(Invoice invoice) async {
    return await localDataSource.saveInvoice(invoice);
  }

  @override
  Future<List<Invoice>> getInvoicesPaginated({
    required int limit,
    required int offset,
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await localDataSource.getInvoicesPaginated(
      limit: limit,
      offset: offset,
      searchQuery: searchQuery,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<Invoice?> getInvoiceById(int id) async {
    return await localDataSource.getInvoiceById(id);
  }

  @override
  Future<void> deleteInvoice(int id) async {
    await localDataSource.deleteInvoice(id);
  }

  @override
  Future<int> saveMoneyCollection(MoneyCollection collection) async {
    return await localDataSource.saveMoneyCollection(collection);
  }

  @override
  Future<List<MoneyCollection>> getCollectionsPaginated({
    required int limit,
    required int offset,
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await localDataSource.getCollectionsPaginated(
      limit: limit,
      offset: offset,
      searchQuery: searchQuery,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<List<MoneyCollection>> getCollectionsByInvoice(int invoiceId) async {
    return await localDataSource.getCollectionsByInvoice(invoiceId);
  }
}
