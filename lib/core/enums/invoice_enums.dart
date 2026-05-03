import '../constants/app_strings.dart';

enum InvoiceType {
  cash,
  credit;

  String label(bool isArabic) {
    switch (this) {
      case InvoiceType.cash:
        return AppStrings.cash;
      case InvoiceType.credit:
        return AppStrings.credit;
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
}
