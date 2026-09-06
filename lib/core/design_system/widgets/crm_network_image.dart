import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Network/base64 image helper that decodes at display size to cut memory and jank.
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
  });

  int? _cachePx(BuildContext context, double? logical) {
    if (logical == null || logical <= 0) return null;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return (logical * dpr).round().clamp(1, 4096);
  }

  @override
  Widget build(BuildContext context) {
    final cacheW = _cachePx(context, cacheLogicalWidth ?? width);
    final cacheH = _cachePx(context, cacheLogicalHeight ?? height);

    if (url.startsWith('data:image') || url.contains('base64')) {
      try {
        final base64Str = url.split(',').last;
        return Image.memory(
          base64Decode(base64Str),
          fit: fit,
          width: width,
          height: height,
          cacheWidth: cacheW,
          cacheHeight: cacheH,
          gaplessPlayback: true,
        );
      } catch (_) {
        return error?.call(context) ??
            const Icon(Icons.broken_image_outlined, size: 16);
      }
    }

    if (kIsWeb) {
      return Image.network(
        url,
        fit: fit,
        width: width,
        height: height,
        cacheWidth: cacheW,
        cacheHeight: cacheH,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) =>
            this.error?.call(context) ??
            const Icon(Icons.broken_image_outlined, size: 16),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder?.call(context) ??
              const Center(
                child: SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                ),
              );
        },
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: width,
      height: height,
      memCacheWidth: cacheW,
      memCacheHeight: cacheH,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholder: (context, url) =>
          placeholder?.call(context) ??
          const Center(
            child: SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            ),
          ),
      errorWidget: (context, url, error) =>
          this.error?.call(context) ??
          const Icon(Icons.broken_image_outlined, size: 16),
    );
  }
}
