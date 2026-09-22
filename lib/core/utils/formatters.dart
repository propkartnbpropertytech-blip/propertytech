import 'package:flutter/services.dart';
import 'currency.dart';

class NumericOnlyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final clean = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    return newValue.copyWith(
      text: clean,
      selection: TextSelection.collapsed(offset: clean.length),
    );
  }
}

class IndianCurrencyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    
    // Allow typing only numbers
    final String clean = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    final double val = double.tryParse(clean) ?? 0.0;
    
    if (val == 0.0) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    
    final formatted = CRMCurrencyFormatter.format(val);
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class CsvSanitizer {
  /// Neutralize CSV/Excel formula injection (DDE injection).
  /// If a string starts with =, +, -, @, \t, or \r, prefix with a single quote (').
  /// Also escapes internal double quotes.
  static String sanitize(dynamic value) {
    if (value == null) return '';
    var str = value.toString();
    if (str.isEmpty) return '';
    final firstChar = str[0];
    if (firstChar == '=' ||
        firstChar == '+' ||
        firstChar == '-' ||
        firstChar == '@' ||
        firstChar == '\t' ||
        firstChar == '\r') {
      str = "'$str";
    }
    return str.replaceAll('"', '""');
  }
}
