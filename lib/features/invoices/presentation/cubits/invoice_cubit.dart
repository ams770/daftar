import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/repositories/invoice_repository.dart';

abstract class InvoiceState extends Equatable {
  const InvoiceState();
  @override
  List<Object?> get props => [];
}

class InvoiceInitial extends InvoiceState {}

class InvoiceLoading extends InvoiceState {}

class InvoiceLoaded extends InvoiceState {
  final List<Invoice> invoices;
  const InvoiceLoaded(this.invoices);
  @override
  List<Object?> get props => [invoices];
}

class InvoiceError extends InvoiceState {
  final String message;
  const InvoiceError(this.message);
  @override
  List<Object?> get props => [message];
}

class InvoiceCubit extends Cubit<InvoiceState> {
  final InvoiceRepository _repository;

  InvoiceCubit(this._repository) : super(InvoiceInitial());

  Future<void> loadInvoices() async {
    emit(InvoiceLoading());
    try {
      final invoices = await _repository.getAllInvoices();
      emit(InvoiceLoaded(invoices));
    } catch (e) {
      emit(InvoiceError(e.toString()));
    }
  }
}
