import 'package:intl/intl.dart';

class CRMCurrencyFormatter {
  static final NumberFormat _indianFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static String format(double amount) {
    return _indianFormat.format(amount);
  }

  static double parse(String formattedString) {
    if (formattedString.isEmpty) return 0.0;
    final clean = formattedString.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(clean) ?? 0.0;
  }

  static String formatWords(double amount) {
    if (amount <= 0) return '₹0';
    if (amount >= 10000000) {
      final double cr = amount / 10000000;
      final String crStr = cr.toStringAsFixed(cr == cr.toInt() ? 0 : 2);
      return '₹$crStr Crore';
    } else if (amount >= 100000) {
      final double lakh = amount / 100000;
      final String lakhStr = lakh.toStringAsFixed(lakh == lakh.toInt() ? 0 : 2);
      return '₹$lakhStr Lakh';
    } else if (amount >= 1000) {
      final double k = amount / 1000;
      final String kStr = k.toStringAsFixed(k == k.toInt() ? 0 : 2);
      return '₹${kStr}K';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }

  static String formatShort(double amount) {
    if (amount <= 0) return '₹ 0';
    if (amount >= 10000000) {
      final double cr = amount / 10000000;
      final String crStr = cr.toStringAsFixed(cr == cr.toInt() ? 0 : 2);
      return '₹ $crStr cr';
    } else if (amount >= 100000) {
      final double lakh = amount / 100000;
      final String lakhStr = lakh.toStringAsFixed(lakh == lakh.toInt() ? 0 : 2);
      return '₹ $lakhStr lakh';
    } else if (amount >= 1000) {
      final double k = amount / 1000;
      final String kStr = k.toStringAsFixed(k == k.toInt() ? 0 : 2);
      return '₹ $kStr k';
    }
    return '₹ ${amount.toStringAsFixed(0)}';
  }

  static String previewInputText(String rawText) {
    if (rawText.trim().isEmpty) return '';
    final val = double.tryParse(rawText.replaceAll(RegExp(r'[^\d.]'), ''));
    if (val == null || val == 0.0) return '';
    final formatted = format(val);
    final words = formatWords(val).replaceAll('₹', '');
    return '$formatted ($words)';
  }
}
