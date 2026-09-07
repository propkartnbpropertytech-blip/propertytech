import 'dart:ui';
import 'package:flutter/material.dart';
import '../tokens/app_blur.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_shadows.dart';
import '../tokens/app_spacing.dart';

/// Translucent glass panel with backdrop blur.
class CRMGlassSurface extends StatelessWidget {
  final Widget child;
  final double blurSigma;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final List<BoxShadow>? boxShadow;
  final Border? border;

  const CRMGlassSurface({
    super.key,
    required this.child,
    this.blurSigma = CRMBlur.navigation,
    this.borderRadius,
    this.padding,
    this.color,
    this.boxShadow,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final sigma = reduceMotion ? CRMBlur.reduced : blurSigma;
    final radius = borderRadius ?? BorderRadius.circular(CRMBorderRadius.xl);

    final surface = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? CRMColors.glassOf(context),
        borderRadius: radius,
        border: border ??
            Border.all(
              color: CRMColors.borderOf(context),
              width: 1.0,
            ),
        boxShadow: boxShadow ?? CRMShadows.glass,
      ),
      child: child,
    );

    if (sigma <= 0) {
      return ClipRRect(borderRadius: radius, child: surface);
    }

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: surface,
        ),
      ),
    );
  }
}
