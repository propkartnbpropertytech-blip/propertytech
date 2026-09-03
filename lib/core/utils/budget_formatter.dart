class BudgetFormatter {
  static String format(double value) {
    if (value >= 10000000) {
      double crVal = value / 10000000;
      return '${crVal.toStringAsFixed(crVal % 1 == 0 ? 0 : 2)} Cr';
    } else if (value >= 100000) {
      double lVal = value / 100000;
      return '${lVal.toStringAsFixed(lVal % 1 == 0 ? 0 : 2)} L';
    } else if (value >= 1000) {
      double kVal = value / 1000;
      return '${kVal.toStringAsFixed(kVal % 1 == 0 ? 0 : 2)} K';
    }
    return value.toStringAsFixed(0);
  }

  static double parse(String input) {
    final cleaned = input.trim().toLowerCase().replaceAll(',', '');
    if (cleaned.endsWith('cr') || cleaned.endsWith('crore')) {
      final valStr = cleaned.replaceAll('crore', '').replaceAll('cr', '').trim();
      return (double.tryParse(valStr) ?? 0.0) * 10000000;
    } else if (cleaned.endsWith('l') || cleaned.endsWith('lakh')) {
      final valStr = cleaned.replaceAll('lakh', '').replaceAll('l', '').trim();
      return (double.tryParse(valStr) ?? 0.0) * 100000;
    } else if (cleaned.endsWith('k') || cleaned.endsWith('thousand')) {
      final valStr = cleaned.replaceAll('thousand', '').replaceAll('k', '').trim();
      return (double.tryParse(valStr) ?? 0.0) * 1000;
    }
    return double.tryParse(cleaned) ?? 0.0;
  }
}
