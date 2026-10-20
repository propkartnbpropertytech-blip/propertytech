import 'package:flutter/widgets.dart';

/// Standard delivery variants for responsive, bandwidth-efficient image loading.
enum CrmImageVariant {
  /// Small thumbnail for lists, cards, search results, avatars, and compact grids (~400px max width).
  thumbnail,

  /// Medium preview for detail drawers, expanded cards, modal previews, and gallery cards (~800px max width).
  preview,

  /// High-resolution image for pinch-to-zoom viewer and fullscreen lightboxes (~1920px max width).
  fullscreen,

  /// Raw, un-transformed source asset.
  original,
}

/// Centralized utility for Cloudinary delivery transformations, decode dimension sizing,
/// and bandwidth/memory optimization across Web, Mobile, and Desktop.
class CrmImageDelivery {
  const CrmImageDelivery._();

  static final RegExp _cloudinaryUploadSplitRegex = RegExp(
    r'/(image|video)/upload/',
    caseSensitive: false,
  );

  /// Returns true if [url] is a Cloudinary CDN delivery URL.
  static bool isCloudinaryUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    final clean = url.trim().toLowerCase();
    return clean.contains('cloudinary.com') && clean.contains('/upload/');
  }

  /// Transforms a raw Cloudinary URL into an optimized delivery URL for [variant].
  /// Non-Cloudinary, base64, or local URLs are returned unchanged.
  static String transformUrl(
    String url, {
    CrmImageVariant variant = CrmImageVariant.thumbnail,
    int? customWidth,
    int? customHeight,
    String? crop,
    String? quality,
    String? format,
  }) {
    final clean = url.trim();
    if (clean.isEmpty) return clean;
    if (clean.startsWith('data:') || clean.contains('base64')) return clean;
    if (!isCloudinaryUrl(clean)) return clean;
    if (variant == CrmImageVariant.original && customWidth == null && customHeight == null) {
      return clean;
    }

    // Determine transformation parameters based on variant
    final int targetW;
    final int? targetH;
    final String targetCrop = crop ?? 'c_limit';
    final String targetQuality;
    final String targetFormat = format ?? 'f_auto';

    switch (variant) {
      case CrmImageVariant.thumbnail:
        targetW = customWidth ?? 400;
        targetH = customHeight;
        targetQuality = quality ?? 'q_auto';
        break;
      case CrmImageVariant.preview:
        targetW = customWidth ?? 800;
        targetH = customHeight;
        targetQuality = quality ?? 'q_auto';
        break;
      case CrmImageVariant.fullscreen:
        targetW = customWidth ?? 1920;
        targetH = customHeight;
        targetQuality = quality ?? 'q_auto:good';
        break;
      case CrmImageVariant.original:
        targetW = customWidth ?? 0;
        targetH = customHeight;
        targetQuality = quality ?? 'q_auto';
        break;
    }

    final List<String> params = [];
    if (targetW > 0) params.add('w_$targetW');
    if (targetH != null && targetH > 0) params.add('h_$targetH');
    params.add(targetCrop);
    params.add(targetQuality);
    params.add(targetFormat);

    final transformStr = params.join(',');

    // Inject transformation segment immediately following '/upload/'
    return _injectTransformation(clean, transformStr);
  }

  /// Transforms a video URL to generate a high-efficiency video poster image (.jpg).
  static String transformVideoPoster(
    String videoUrl, {
    CrmImageVariant variant = CrmImageVariant.thumbnail,
    int? customWidth,
    int? customHeight,
  }) {
    final clean = videoUrl.trim();
    if (clean.isEmpty) return clean;

    // Replace video file extension with .jpg for Cloudinary video snapshot
    String posterUrl = clean.replaceAll(
      RegExp(r'\.(mp4|mov|webm|avi|mkv|m4v)$', caseSensitive: false),
      '.jpg',
    );

    return transformUrl(
      posterUrl,
      variant: variant,
      customWidth: customWidth,
      customHeight: customHeight,
      format: 'f_jpg',
    );
  }

  static String _injectTransformation(String url, String transformStr) {
    final match = _cloudinaryUploadSplitRegex.firstMatch(url);
    if (match == null) return url;

    final uploadEnd = match.end; // index right after '/upload/'
    final prefix = url.substring(0, uploadEnd);
    final rest = url.substring(uploadEnd);

    // If there is an existing transformation before version/public_id, replace it
    // Transformations don't start with 'v[0-9]' and don't end with file extension
    final segments = rest.split('/');
    if (segments.isNotEmpty) {
      final first = segments.first;
      final isVersionOrPublicId = RegExp(r'^v\d+$').hasMatch(first) ||
          first.contains('.') ||
          (!first.contains('_') && !first.contains(','));

      if (!isVersionOrPublicId) {
        // First segment is an existing transformation — replace it
        segments[0] = transformStr;
        return '$prefix${segments.join('/')}';
      }
    }

    // No existing transformation segment — insert new one
    return '$prefix$transformStr/$rest';
  }

  /// Calculates bounded pixel decode dimensions respecting Device Pixel Ratio (DPR).
  /// DPR is capped at 2.5 to avoid excessive allocations on ultra-high density displays.
  static ({int? width, int? height}) getDecodeDimensions({
    BuildContext? context,
    CrmImageVariant variant = CrmImageVariant.thumbnail,
    double? logicalWidth,
    double? logicalHeight,
    double? devicePixelRatio,
  }) {
    if (variant == CrmImageVariant.original) {
      return (width: null, height: null);
    }

    double dpr = devicePixelRatio ?? 2.0;
    if (context != null && devicePixelRatio == null) {
      try {
        dpr = MediaQuery.devicePixelRatioOf(context);
      } catch (_) {
        dpr = 2.0;
      }
    }
    dpr = dpr.clamp(1.0, 2.5);

    final int maxVariantWidth;
    switch (variant) {
      case CrmImageVariant.thumbnail:
        maxVariantWidth = 400;
        break;
      case CrmImageVariant.preview:
        maxVariantWidth = 800;
        break;
      case CrmImageVariant.fullscreen:
        maxVariantWidth = 1920;
        break;
      case CrmImageVariant.original:
        maxVariantWidth = 4096;
        break;
    }

    int? targetW;
    int? targetH;

    if (logicalWidth != null && logicalWidth > 0) {
      targetW = (logicalWidth * dpr).round().clamp(1, maxVariantWidth);
    } else {
      targetW = maxVariantWidth;
    }

    if (logicalHeight != null && logicalHeight > 0) {
      targetH = (logicalHeight * dpr).round().clamp(1, (maxVariantWidth * 1.5).round());
    }

    return (width: targetW, height: targetH);
  }

  /// Creates an optimized [ImageProvider] for use with [CircleAvatar], [DecorationImage], etc.
  static ImageProvider imageProvider(
    String url, {
    CrmImageVariant variant = CrmImageVariant.thumbnail,
    double? logicalWidth,
    double? logicalHeight,
    BuildContext? context,
  }) {
    final transformedUrl = transformUrl(url, variant: variant);
    final decode = getDecodeDimensions(
      context: context,
      variant: variant,
      logicalWidth: logicalWidth,
      logicalHeight: logicalHeight,
    );

    final provider = NetworkImage(transformedUrl);

    if (decode.width != null || decode.height != null) {
      return ResizeImage(
        provider,
        width: decode.width,
        height: decode.height,
        allowUpscaling: false,
      );
    }

    return provider;
  }
}
