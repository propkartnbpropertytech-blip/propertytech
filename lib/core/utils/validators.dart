import '../constants/app_constants.dart';

class CRMValidators {
  static String? required(String? value, {String message = 'This field is required'}) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

  static String? email(String? value, {String message = 'Enter a valid email address'}) {
    if (value == null || value.trim().isEmpty) return null;
    if (!AppConstants.emailRegex.hasMatch(value.trim())) {
      return message;
    }
    return null;
  }

  static String? phone(String? value, {String message = 'Enter a valid phone number'}) {
    if (value == null || value.trim().isEmpty) return null;
    if (!AppConstants.phoneRegex.hasMatch(value.trim())) {
      return message;
    }
    return null;
  }

  static String? indianMobile(String? value, {String message = 'Enter a valid 10-digit mobile number'}) {
    if (value == null || value.trim().isEmpty) return null;
    if (!AppConstants.indianMobileRegex.hasMatch(value.trim())) {
      return message;
    }
    return null;
  }

  static String? numeric(String? value, {String message = 'Enter numbers only'}) {
    if (value == null || value.trim().isEmpty) return null;
    if (!AppConstants.numericOnlyRegex.hasMatch(value.trim())) {
      return message;
    }
    return null;
  }

  static String? minLength(String? value, int min, {String? message}) {
    if (value == null || value.trim().isEmpty) return null;
    if (value.trim().length < min) {
      return message ?? 'Minimum $min characters required';
    }
    return null;
  }

  static String? maxLength(String? value, int max, {String? message}) {
    if (value == null || value.trim().isEmpty) return null;
    if (value.trim().length > max) {
      return message ?? 'Maximum $max characters allowed';
    }
    return null;
  }
}
