import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../products/domain/entities/product.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../../../products/domain/repositories/product_repository.dart';

abstract class AddInvoiceState extends Equatable {
  const AddInvoiceState();
  @override
  List<Object?> get props => [];
}

class AddInvoiceInitial extends AddInvoiceState {}

class AddInvoiceLoading extends AddInvoiceState {}

class AddInvoiceCreating extends AddInvoiceState {
  final Map<int, int> cartItems; // productId -> qty
  final List<Product> availableProducts;
  
  const AddInvoiceCreating({
    this.cartItems = const {},
    this.availableProducts = const [],
  });

  @override
  List<Object?> get props => [cartItems, availableProducts];

  AddInvoiceCreating copyWith({
    Map<int, int>? cartItems,
    List<Product>? availableProducts,
  }) {
    return AddInvoiceCreating(
      cartItems: cartItems ?? this.cartItems,
      availableProducts: availableProducts ?? this.availableProducts,
    );
  }
}

class AddInvoiceSaveSuccess extends AddInvoiceState {
  final int invoiceId;
  const AddInvoiceSaveSuccess(this.invoiceId);
  @override
  List<Object?> get props => [invoiceId];
}

class AddInvoiceError extends AddInvoiceState {
  final String message;
  const AddInvoiceError(this.message);
  @override
  List<Object?> get props => [message];
}

class AddInvoiceCubit extends Cubit<AddInvoiceState> {
  final InvoiceRepository _repository;

  AddInvoiceCubit(this._repository) : super(AddInvoiceInitial());

  void startNewInvoice(List<Product> products) {
    emit(AddInvoiceCreating(availableProducts: products));
  }

  void updateProductQty(Product product, int delta) {
    if (state is AddInvoiceCreating) {
      final currentState = state as AddInvoiceCreating;
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

  Future<bool> addProductByCode(String code, ProductRepository productRepo) async {
    if (state is! AddInvoiceCreating) return false;
    final currentState = state as AddInvoiceCreating;

    // 1. Check if already in cart (by checking availableProducts first to find the product object)
    Product? product;
    try {
      product = currentState.availableProducts.firstWhere((p) => p.code == code);
    } catch (_) {
      // Not in current list, fetch from repo
      product = await productRepo.getProductByCode(code);
      if (product != null) {
        // Add to available products so we can track it
        final newList = List<Product>.from(currentState.availableProducts)..add(product);
        emit(currentState.copyWith(availableProducts: newList));
      }
    }

    if (product != null) {
      updateProductQty(product, 1);
      return true;
    }
    return false;
  }

  Future<void> saveInvoice(Invoice invoice) async {
    emit(AddInvoiceLoading());
    try {
      final id = await _repository.saveInvoice(invoice);
      emit(AddInvoiceSaveSuccess(id));
    } catch (e) {
      emit(AddInvoiceError(e.toString()));
    }
  }

  void reset() {
    emit(AddInvoiceInitial());
  }
}
