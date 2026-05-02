enum InvoiceType {
  cash,
  credit;

  String label(bool isArabic) {
    switch (this) {
      case InvoiceType.cash:
        return isArabic ? 'نقدي' : 'Cash';
      case InvoiceType.credit:
        return isArabic ? 'آجل' : 'Credit';
    }
  }
}

enum PaymentMethod {
  cash,
  bankTransfer;

  String label(bool isArabic) {
    switch (this) {
      case PaymentMethod.cash:
        return isArabic ? 'نقد' : 'Cash';
      case PaymentMethod.bankTransfer:
        return isArabic ? 'تحويل بنكي' : 'Bank Transfer';
    }
  }
}
