import 'seo_helper_stub.dart'
    if (dart.library.js_util) 'seo_helper_web.dart'
    if (dart.library.html) 'seo_helper_web.dart' as impl;

class SeoHelper {
  /// Updates the HTML document title, description, robots tags, canonical link,
  /// and Open Graph / Twitter Card meta tags for SEO.
  /// On native platforms (iOS/Android), this is a safe no-op.
  static void updateTags({
    required String title,
    required String description,
    String? imageUrl,
    String? canonicalUrl,
    bool noIndex = false,
  }) {
    impl.updateTagsImpl(
      title: title,
      description: description,
      imageUrl: imageUrl,
      canonicalUrl: canonicalUrl,
      noIndex: noIndex,
    );
  }
}
