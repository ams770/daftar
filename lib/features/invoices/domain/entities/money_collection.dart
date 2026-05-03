import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

class MoneyCollection extends Equatable {
  final int? id;
  final int invoiceId;
  final double amount;
  final double remainingBefore;
  final double remainingAfter;
  final DateTime createdAt;
  final String? clientName;

  const MoneyCollection({
    this.id,
    required this.invoiceId,
    required this.amount,
    required this.remainingBefore,
    required this.remainingAfter,
    required this.createdAt,
    this.clientName,
  });

  @override
  List<Object?> get props => [
        id,
        invoiceId,
        amount,
        remainingBefore,
        remainingAfter,
        createdAt,
        clientName,
      ];

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'invoiceId': invoiceId,
      'amount': amount,
      'remainingBefore': remainingBefore,
      'remainingAfter': remainingAfter,
      'createdAt': createdAt.toIso8601String(),
      if (clientName != null) 'clientName': clientName,
    };
  }

  factory MoneyCollection.fromJson(Map<String, dynamic> json) {
    return MoneyCollection(
      id: json['id'] as int?,
      invoiceId: json['invoiceId'] as int,
      amount: json['amount'] as double,
      remainingBefore: json['remainingBefore'] as double,
      remainingAfter: json['remainingAfter'] as double,
      createdAt: DateTime.parse(json['createdAt'] as String),
      clientName: json['clientName'] as String?,
    );
  }

  MoneyCollection copyWith({
    int? id,
    int? invoiceId,
    double? amount,
    double? remainingBefore,
    double? remainingAfter,
    DateTime? createdAt,
    String? clientName,
  }) {
    return MoneyCollection(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      amount: amount ?? this.amount,
      remainingBefore: remainingBefore ?? this.remainingBefore,
      remainingAfter: remainingAfter ?? this.remainingAfter,
      createdAt: createdAt ?? this.createdAt,
      clientName: clientName ?? this.clientName,
    );
  }

  String get formattedDate => DateFormat('MMM dd, yyyy • HH:mm').format(createdAt);
}
