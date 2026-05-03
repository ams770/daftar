import 'package:equatable/equatable.dart';
import 'package:products_printer/features/invoices/domain/entities/invoice.dart';

abstract class InvoiceState extends Equatable {
  final String? searchQuery;
  final DateTime startDate;
  final DateTime endDate;

  const InvoiceState({
    this.searchQuery,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [searchQuery, startDate, endDate];
}

class InvoiceInitial extends InvoiceState {
  InvoiceInitial()
      : super(
          startDate: DateTime.now().subtract(const Duration(days: 30)),
          endDate: DateTime.now(),
        );
}

class InvoiceLoading extends InvoiceState {
  const InvoiceLoading({
    super.searchQuery,
    required super.startDate,
    required super.endDate,
  });
}

class InvoiceLoaded extends InvoiceState {
  final List<Invoice> invoices;
  final bool hasMore;
  final bool isLoadingMore;

  const InvoiceLoaded({
    required this.invoices,
    required this.hasMore,
    this.isLoadingMore = false,
    super.searchQuery,
    required super.startDate,
    required super.endDate,
  });

  @override
  List<Object?> get props => [...super.props, invoices, hasMore, isLoadingMore];

  InvoiceLoaded copyWith({
    List<Invoice>? invoices,
    bool? hasMore,
    bool? isLoadingMore,
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return InvoiceLoaded(
      invoices: invoices ?? this.invoices,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      searchQuery: searchQuery ?? this.searchQuery,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

class InvoiceError extends InvoiceState {
  final String message;
  const InvoiceError({
    required this.message,
    super.searchQuery,
    required super.startDate,
    required super.endDate,
  });

  @override
  List<Object?> get props => [...super.props, message];
}
