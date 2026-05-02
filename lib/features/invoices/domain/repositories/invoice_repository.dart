import '../../domain/entities/invoice.dart';

abstract class InvoiceRepository {
  Future<int> saveInvoice(Invoice invoice);
  Future<List<Invoice>> getAllInvoices();
}
