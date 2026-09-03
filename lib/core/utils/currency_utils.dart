import 'package:intl/intl.dart';

class CurrencyUtils {
  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static String format(double amount, [String symbol = '₹']) {
    if (symbol == '₹') {
      return _currencyFormatter.format(amount);
    }
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  static String formatQty(double qty) {
    if (qty == qty.roundToDouble()) {
      return qty.toInt().toString();
    }
    return qty.toStringAsFixed(1);
  }
}
