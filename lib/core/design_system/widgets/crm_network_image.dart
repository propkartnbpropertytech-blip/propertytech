import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../network/crm_image_delivery.dart';
export '../../network/crm_image_delivery.dart' show CrmImageVariant, CrmImageDelivery;

/// Network/base64 image helper that applies server-side Cloudinary transformations
/// and decodes at display size to slash network bandwidth, memory, and scroll jank.
class CrmNetworkImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext context)? placeholder;
  final Widget Function(BuildContext context)? error;

  /// Logical pixel size used to derive decode cache dimensions.
  /// Prefer the on-screen thumbnail size (e.g. 110 for a 110px-wide thumb).
  final double? cacheLogicalWidth;
  final double? cacheLogicalHeight;

  /// Delivery variant (thumbnail, preview, fullscreen, or original).
  /// Defaults to [CrmImageVariant.thumbnail] for safe, high-speed card/list delivery.
  final CrmImageVariant variant;

  const CrmNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.error,
    this.cacheLogicalWidth,
    this.cacheLogicalHeight,
    this.variant = CrmImageVariant.thumbnail,
  });

  Widget _defaultPlaceholder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: (width != null && width! < 60) ? 14 : 20,
          color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String cleanUrl = url.trim();
    if (cleanUrl.isEmpty) {
      return error?.call(context) ??
          const Icon(Icons.broken_image_outlined, size: 16);
    }

    // Handle data/base64 images
    if (cleanUrl.startsWith('data:image') || cleanUrl.contains('base64')) {
      final decode = CrmImageDelivery.getDecodeDimensions(
        context: context,
        variant: variant,
        logicalWidth: cacheLogicalWidth ?? width,
        logicalHeight: cacheLogicalHeight ?? height,
      );
      try {
        final base64Str = cleanUrl.split(',').last;
        return Image.memory(
          base64Decode(base64Str),
          fit: fit,
          width: width,
          height: height,
          cacheWidth: decode.width,
          cacheHeight: decode.height,
          gaplessPlayback: true,
        );
      } catch (_) {
        return error?.call(context) ??
            const Icon(Icons.broken_image_outlined, size: 16);
      }
    }

    final rawNormalizedUrl = cleanUrl.startsWith('//') ? 'https:$cleanUrl' : cleanUrl;

    // Apply Cloudinary URL optimization for the specified variant
    final optimizedUrl = CrmImageDelivery.transformUrl(
      rawNormalizedUrl,
      variant: variant,
    );

    // Calculate decode dimensions respecting DPR and variant bounds
    final decode = CrmImageDelivery.getDecodeDimensions(
      context: context,
      variant: variant,
      logicalWidth: cacheLogicalWidth ?? width,
      logicalHeight: cacheLogicalHeight ?? height,
    );

    final bool useImageNetwork = kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;

    if (useImageNetwork) {
      return Image.network(
        optimizedUrl,
        fit: fit,
        width: width,
        height: height,
        cacheWidth: decode.width,
        cacheHeight: decode.height,
        gaplessPlayback: true,
        errorBuilder: (context, err, stackTrace) {
          debugPrint('⚠️ [CrmNetworkImage] Error loading: $optimizedUrl -> $err');
          return error?.call(context) ??
              const Icon(Icons.broken_image_outlined, size: 16);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder?.call(context) ?? _defaultPlaceholder(context);
        },
      );
    }

    return CachedNetworkImage(
      imageUrl: optimizedUrl,
      fit: fit,
      width: width,
      height: height,
      memCacheWidth: decode.width,
      memCacheHeight: decode.height,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholder: (context, url) =>
          placeholder?.call(context) ?? _defaultPlaceholder(context),
      errorWidget: (context, url, error) =>
          this.error?.call(context) ??
          const Icon(Icons.broken_image_outlined, size: 16),
    );
  }
}
