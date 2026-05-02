import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../products/domain/entities/product.dart';
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

class InvoiceCreating extends InvoiceState {
  final Map<int, int> cartItems; // productId -> qty
  final List<Product> availableProducts;
  
  const InvoiceCreating({
    this.cartItems = const {},
    this.availableProducts = const [],
  });

  @override
  List<Object?> get props => [cartItems, availableProducts];

  InvoiceCreating copyWith({
    Map<int, int>? cartItems,
    List<Product>? availableProducts,
  }) {
    return InvoiceCreating(
      cartItems: cartItems ?? this.cartItems,
      availableProducts: availableProducts ?? this.availableProducts,
    );
  }
}

class InvoiceSaveSuccess extends InvoiceState {
  final int invoiceId;
  const InvoiceSaveSuccess(this.invoiceId);
  @override
  List<Object?> get props => [invoiceId];
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

  void startNewInvoice(List<Product> products) {
    emit(InvoiceCreating(availableProducts: products));
  }

  void updateProductQty(Product product, int delta) {
    if (state is InvoiceCreating) {
      final currentState = state as InvoiceCreating;
      final newCart = Map<int, int>.from(currentState.cartItems);
      final currentQty = newCart[product.id] ?? 0;
      final newQty = currentQty + delta;
      
      if (newQty <= 0) {
        newCart.remove(product.id);
      } else {
        newCart[product.id!] = newQty;
      }
      
      emit(currentState.copyWith(cartItems: newCart));
    }
  }

  Future<void> saveInvoice(Invoice invoice) async {
    try {
      final id = await _repository.saveInvoice(invoice);
      emit(InvoiceSaveSuccess(id));
      await loadInvoices();
    } catch (e) {
      emit(InvoiceError(e.toString()));
    }
  }
}
