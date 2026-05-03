import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../constants/app_strings.dart';

enum InvoiceType {
  paid,
  credit;

  String label(bool isArabic) {
    switch (this) {
      case InvoiceType.paid:
        return AppStrings.paid;
      case InvoiceType.credit:
        return AppStrings.credit;
    }
  }

  IconData get icon {
    switch (this) {
      case InvoiceType.paid:
        return LucideIcons.listCheck;
      case InvoiceType.credit:
        return LucideIcons.clock;
    }
  }
}

enum PaymentMethod {
  cash,
  bankTransfer;

  String label(bool isArabic) {
    switch (this) {
      case PaymentMethod.cash:
        return AppStrings.cash;
      case PaymentMethod.bankTransfer:
        return AppStrings.bankTransfer;
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethod.cash:
        return LucideIcons.banknote;
      case PaymentMethod.bankTransfer:
        return LucideIcons.landmark;
    }
  }
}
