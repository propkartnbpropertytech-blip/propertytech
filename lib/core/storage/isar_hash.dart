// isar_hash.dart
// Conditionally exports the correct hashes based on platform.
// For Web, exports JS-safe rounded representations to satisfy compilation.
// For Mobile (iOS/Android) and desktop, exports original 64-bit precision hashes to satisfy Isar schema validation.

export 'isar_hash_mobile.dart'
    if (dart.library.html) 'isar_hash_web.dart';
