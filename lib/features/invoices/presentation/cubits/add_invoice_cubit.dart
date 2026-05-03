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

class CartItem extends Equatable {
  final Product product;
  final int quantity;

  const CartItem({required this.product, required this.quantity});

  @override
  List<Object?> get props => [product, quantity];

  CartItem copyWith({Product? product, int? quantity}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}

class AddInvoiceCreating extends AddInvoiceState {
  final Map<int, CartItem> cartItems; // productId -> CartItem
  final String? clientName;
  
  const AddInvoiceCreating({
    this.cartItems = const {},
    this.clientName,
  });

  @override
  List<Object?> get props => [cartItems, clientName];

  AddInvoiceCreating copyWith({
    Map<int, CartItem>? cartItems,
    String? clientName,
  }) {
    return AddInvoiceCreating(
      cartItems: cartItems ?? this.cartItems,
      clientName: clientName ?? this.clientName,
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

  void startNewInvoice() {
    emit(const AddInvoiceCreating());
  }

  void updateClientName(String? name) {
    if (state is AddInvoiceCreating) {
      final currentState = state as AddInvoiceCreating;
      emit(currentState.copyWith(clientName: name));
    }
  }

  void updateProductQty(Product product, int delta) {
    if (state is AddInvoiceCreating) {
      final currentState = state as AddInvoiceCreating;
      final newCart = Map<int, CartItem>.from(currentState.cartItems);
      final currentItem = newCart[product.id];
      
      if (currentItem == null) {
        if (delta > 0) {
          newCart[product.id!] = CartItem(product: product, quantity: delta);
        }
      } else {
        final newQty = currentItem.quantity + delta;
        if (newQty <= 0) {
          newCart.remove(product.id);
        } else {
          newCart[product.id!] = currentItem.copyWith(quantity: newQty);
        }
      }
      
      emit(currentState.copyWith(cartItems: newCart));
    }
  }

  Future<bool> addProductByCode(String code, ProductRepository productRepo) async {
    if (state is! AddInvoiceCreating) return false;

    // Always fetch from repo to ensure we have the latest data and handle cases where it's not in a local list
    final product = await productRepo.getProductByCode(code);
    
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
