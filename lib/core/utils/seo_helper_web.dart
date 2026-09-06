import 'dart:html' as html;

void updateTagsImpl({
  required String title,
  required String description,
  String? imageUrl,
  String? canonicalUrl,
  bool noIndex = false,
}) {
  // 1. Update the document title
  html.document.title = title;

  // Helper to find or create a meta tag
  void setMetaTag(String attribute, String attrVal, String contentVal) {
    var element = html.document.querySelector('meta[$attribute="$attrVal"]');
    if (element == null) {
      element = html.document.createElement('meta');
      element.setAttribute(attribute, attrVal);
      html.document.head?.append(element);
    }
    element.setAttribute('content', contentVal);
  }

  // Helper to find or create a link tag
  void setLinkTag(String rel, String href) {
    var element = html.document.querySelector('link[rel="$rel"]');
    if (element == null) {
      element = html.document.createElement('link');
      element.setAttribute('rel', rel);
      html.document.head?.append(element);
    }
    element.setAttribute('href', href);
  }

  // 2. Set Robots tag (noindex for admin routes to prevent index polling)
  setMetaTag('name', 'robots', noIndex ? 'noindex, nofollow' : 'index, follow');

  // 3. Set standard description
  setMetaTag('name', 'description', description);

  // 4. Set Open Graph (Facebook / LinkedIn / WhatsApp)
  setMetaTag('property', 'og:title', title);
  setMetaTag('property', 'og:description', description);
  setMetaTag('property', 'og:type', 'website');
  if (imageUrl != null && imageUrl.isNotEmpty) {
    setMetaTag('property', 'og:image', imageUrl);
  }
  if (canonicalUrl != null && canonicalUrl.isNotEmpty) {
    setMetaTag('property', 'og:url', canonicalUrl);
    setLinkTag('canonical', canonicalUrl);
  }

  // 5. Set Twitter Card metadata
  setMetaTag('name', 'twitter:card', 'summary_large_image');
  setMetaTag('name', 'twitter:title', title);
  setMetaTag('name', 'twitter:description', description);
  if (imageUrl != null && imageUrl.isNotEmpty) {
    setMetaTag('name', 'twitter:image', imageUrl);
  }
}
