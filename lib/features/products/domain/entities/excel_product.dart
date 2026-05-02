import 'package:equatable/equatable.dart';

enum ExcelProductStatus { newProduct, exists, changed, duplicate }

class ExcelProduct extends Equatable {
  final String? id; // Temp ID for the table if needed, or just use code
  final String name;
  final String code;
  final double price;
  final ExcelProductStatus? status;
  final String? oldName;
  final double? oldPrice;
  final bool isValidating;

  const ExcelProduct({
     this.id,
    required this.name,
    required this.code,
    required this.price,
    this.status,
    this.oldName,
    this.oldPrice,
    this.isValidating = false,
  });

  ExcelProduct copyWith({
    String? name,
    String? code,
    double? price,
    ExcelProductStatus? status,
    String? oldName,
    double? oldPrice,
    bool? isValidating,
  }) {
    return ExcelProduct(
      name: name ?? this.name,
      code: code ?? this.code,
      price: price ?? this.price,
      status: status ?? this.status,
      oldName: oldName ?? this.oldName,
      oldPrice: oldPrice ?? this.oldPrice,
      isValidating: isValidating ?? this.isValidating,
    );
  }

  @override
  List<Object?> get props => [name, code, price, status, oldName, oldPrice, isValidating];
}
