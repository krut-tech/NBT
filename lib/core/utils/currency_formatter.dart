import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _inrFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final NumberFormat _compactInrFormatter = NumberFormat.compactCurrency(
    locale: 'en_IN',
    symbol: '₹',
  );

  static String format(dynamic amount) {
    if (amount == null) return '₹0.00';
    double val = 0.0;
    if (amount is num) {
      val = amount.toDouble();
    } else if (amount is String) {
      val = double.tryParse(amount) ?? 0.0;
    }
    return _inrFormatter.format(val);
  }

  static String formatCompact(dynamic amount) {
    if (amount == null) return '₹0';
    double val = 0.0;
    if (amount is num) {
      val = amount.toDouble();
    } else if (amount is String) {
      val = double.tryParse(amount) ?? 0.0;
    }
    return _compactInrFormatter.format(val);
  }
}
