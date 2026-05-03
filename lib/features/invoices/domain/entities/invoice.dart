import 'package:equatable/equatable.dart';

import '../../../../core/enums/invoice_enums.dart';


class Invoice extends Equatable {
  final int? id;
  final DateTime createdAt;
  final List<InvoiceItem> items;
  final double subtotal;
  final double vatAmount;
  final double total;
  final int vatPercent;
  final String currency;
  final String? clientName;

  final InvoiceType type;
  final PaymentMethod paymentMethod;
  final double paidAmount;
  final double remainingAmount;

  const Invoice({
    this.id,
    required this.createdAt,
    required this.items,
    required this.subtotal,
    required this.vatAmount,
    required this.total,
    required this.vatPercent,
    required this.currency,
    required this.type,
    required this.paymentMethod,
    required this.paidAmount,
    required this.remainingAmount,
    this.clientName,
  });

  @override
  List<Object?> get props => [
        id,
        createdAt,
        items,
        subtotal,
        vatAmount,
        total,
        vatPercent,
        currency,
        type,
        paymentMethod,
        paidAmount,
        remainingAmount,
        clientName,
      ];

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'createdAt': createdAt.toIso8601String(),
      'subtotal': subtotal,
      'vatAmount': vatAmount,
      'total': total,
      'vatPercent': vatPercent,
      'currency': currency,
      'type': type.name,
      'paymentMethod': paymentMethod.name,
      'paidAmount': paidAmount,
      'remainingAmount': remainingAmount,
      'clientName': clientName,
    };
  }

  factory Invoice.fromJson(Map<String, dynamic> json, List<InvoiceItem> items) {
    return Invoice(
      id: json['id'],
      createdAt: DateTime.parse(json['createdAt']),
      items: items,
      subtotal: json['subtotal'],
      vatAmount: json['vatAmount'],
      total: json['total'],
      vatPercent: json['vatPercent'],
      currency: json['currency'],
      type: InvoiceType.values.byName(json['type'] ?? 'paid'),
      paymentMethod: PaymentMethod.values.byName(json['paymentMethod'] ?? 'cash'),
      paidAmount: json['paidAmount'] ?? json['total'],
      remainingAmount: json['remainingAmount'] ?? 0.0,
      clientName: json['clientName'],
    );
  }
}

class InvoiceItem extends Equatable {
  final int? id;
  final int? invoiceId;
  final int? productId;
  final String productName;
  final String productCode;
  final int qty;
  final double unitPrice;
  final double lineTotal;

  const InvoiceItem({
    this.id,
    this.invoiceId,
    this.productId,
    required this.productName,
    required this.productCode,
    required this.qty,
    required this.unitPrice,
    required this.lineTotal,
  });

  @override
  List<Object?> get props => [id, invoiceId, productId, productName, productCode, qty, unitPrice, lineTotal];

  Map<String, dynamic> toJson(int? invoiceId) {
    return {
      if (id != null) 'id': id,
      'invoiceId': invoiceId,
      'productId': productId,
      'productName': productName,
      'productCode': productCode,
      'qty': qty,
      'unitPrice': unitPrice,
      'lineTotal': lineTotal,
    };
  }

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      id: json['id'],
      invoiceId: json['invoiceId'],
      productId: json['productId'],
      productName: json['productName'],
      productCode: json['productCode'],
      qty: json['qty'],
      unitPrice: json['unitPrice'],
      lineTotal: json['lineTotal'],
    );
  }
}
