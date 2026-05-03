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
  Future<void> deleteInvoice(int id);
}
