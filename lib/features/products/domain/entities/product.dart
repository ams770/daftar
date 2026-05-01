import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final int? id;
  final String name;
  final String code;
  final double price;

  const Product({
    this.id,
    required this.name,
    required this.code,
    required this.price,
  });

  @override
  List<Object?> get props => [id, name, code, price];
}
