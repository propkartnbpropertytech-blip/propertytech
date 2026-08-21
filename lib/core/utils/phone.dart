class CRMPhoneHelper {
  static String normalize(String phone) {
    String clean = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (clean.length == 10 && !clean.startsWith('+')) {
      return '+91$clean';
    }
    if (clean.startsWith('91') && clean.length == 12) {
      return '+$clean';
    }
    return clean;
  }

  static String formatDisplay(String phone) {
    final String clean = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (clean.length == 10) {
      return '${clean.substring(0, 5)} ${clean.substring(5)}';
    }
    if (clean.length == 12 && clean.startsWith('91')) {
      return '+91 ${clean.substring(2, 7)} ${clean.substring(7)}';
    }
    return phone;
  }
}
