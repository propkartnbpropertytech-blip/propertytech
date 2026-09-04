class AppConstants {
  // App Info
  static const String appVersion = '2.0.0';
  static const String buildNumber = '8';

  // API Config
  static const String baseUrl = 'https://api-propkart.nbpropertytech.com/api/v1';
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // Storage Paths
  static const String profileBucket = 'profile';
  static const String importBucket = 'import-file';
  static const String propertyMediaBucket = 'property-media';

  // Places Cache TTL
  static const int placesCacheTtlDays = 30;

  // Responsive Breakpoints
  static const double mobileMax = 600.0;
  static const double tabletMax = 1024.0;

  // Regex Patterns
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  static final RegExp phoneRegex = RegExp(r'^\+?[0-9]{10,14}$');
  static final RegExp indianMobileRegex = RegExp(r'^\d{10}$');
  static final RegExp numericOnlyRegex = RegExp(r'^[0-9]+$');

  // Format Patterns
  static const String dateFormat = 'dd-MM-yyyy';
  static const String timeFormat = 'hh:mm a';
  static const String dateTimeFormat = 'dd-MM-yyyy hh:mm a';
  static const String currencyLocale = 'en_IN';
}
