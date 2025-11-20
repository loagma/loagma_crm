import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(dynamic amount, {String symbol = '₹'}) {
    if (amount == null) return '$symbol 0.00';
    
    final formatter = NumberFormat('#,##,##0.00', 'en_IN');
    final value = amount is String ? double.tryParse(amount) ?? 0 : amount;
    
    return '$symbol ${formatter.format(value)}';
  }

  static String formatWithoutSymbol(dynamic amount) {
    if (amount == null) return '0.00';
    
    final formatter = NumberFormat('#,##,##0.00', 'en_IN');
    final value = amount is String ? double.tryParse(amount) ?? 0 : amount;
    
    return formatter.format(value);
  }
}
