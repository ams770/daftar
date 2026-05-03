import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:products_printer/features/invoices/domain/repositories/invoice_repository.dart';
import 'package:products_printer/features/invoices/presentation/cubits/invoice_state.dart';

export 'package:products_printer/features/invoices/presentation/cubits/invoice_state.dart';

class InvoiceCubit extends Cubit<InvoiceState> {
  final InvoiceRepository _repository;
  static const int _limit = 15;

  InvoiceCubit(this._repository) : super(InvoiceInitial());

  Future<void> loadInvoices({
    bool refresh = false,
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final currentSearch = searchQuery ?? state.searchQuery;
    final currentStart = startDate ?? state.startDate;
    final currentEnd = endDate ?? state.endDate;

    if (refresh || state is InvoiceInitial) {
      emit(InvoiceLoading(
        searchQuery: currentSearch,
        startDate: currentStart,
        endDate: currentEnd,
      ));
      try {
        final invoices = await _repository.getInvoicesPaginated(
          limit: _limit,
          offset: 0,
          searchQuery: currentSearch,
          startDate: currentStart,
          endDate: currentEnd,
        );
        emit(InvoiceLoaded(
          invoices: invoices,
          hasMore: invoices.length == _limit,
          searchQuery: currentSearch,
          startDate: currentStart,
          endDate: currentEnd,
        ));
      } catch (e) {
        emit(InvoiceError(
          message: e.toString(),
          searchQuery: currentSearch,
          startDate: currentStart,
          endDate: currentEnd,
        ));
      }
    }
  }

  Future<void> loadMoreInvoices() async {
    if (state is! InvoiceLoaded) return;
    final currentState = state as InvoiceLoaded;
    if (!currentState.hasMore || currentState.isLoadingMore) return;

    emit(currentState.copyWith(isLoadingMore: true));

    try {
      final moreInvoices = await _repository.getInvoicesPaginated(
        limit: _limit,
        offset: currentState.invoices.length,
        searchQuery: currentState.searchQuery,
        startDate: currentState.startDate,
        endDate: currentState.endDate,
      );

      emit(currentState.copyWith(
        invoices: currentState.invoices + moreInvoices,
        hasMore: moreInvoices.length == _limit,
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(InvoiceError(
        message: e.toString(),
        searchQuery: currentState.searchQuery,
        startDate: currentState.startDate,
        endDate: currentState.endDate,
      ));
    }
  }

  void setSearchQuery(String? query) {
    if (state is InvoiceLoaded) {
      final currentState = state as InvoiceLoaded;
      loadInvoices(
        refresh: true,
        searchQuery: query,
        startDate: currentState.startDate,
        endDate: currentState.endDate,
      );
    }
  }

  void setDateRange(DateTime start, DateTime end) {
    if (state is InvoiceLoaded) {
      final currentState = state as InvoiceLoaded;
      loadInvoices(
        refresh: true,
        searchQuery: currentState.searchQuery,
        startDate: start,
        endDate: end,
      );
    }
  }

  Future<void> deleteInvoice(int id) async {
    try {
      await _repository.deleteInvoice(id);
      loadInvoices(refresh: true);
    } catch (e) {
      emit(InvoiceError(
        message: e.toString(),
        searchQuery: state.searchQuery,
        startDate: state.startDate,
        endDate: state.endDate,
      ));
    }
  }
}
