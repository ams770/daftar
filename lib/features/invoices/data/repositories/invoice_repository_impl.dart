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
  Future<void> deleteInvoice(int id) async {
    await localDataSource.deleteInvoice(id);
  }
}
