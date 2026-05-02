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
  Future<List<Invoice>> getAllInvoices() async {
    return await localDataSource.getAllInvoices();
  }
}
