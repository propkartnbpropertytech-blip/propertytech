import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../tokens/app_motion.dart';

/// Lightweight, high-performance page transition for shell routes.
///
/// Implements Option A (Fade):
/// - Replaces the legacy triple-composite transition (Fade + Slide + Scale).
/// - 1 single composited layer during transition (0 layers once settled at opacity 1.0).
/// - 0 matrix transformations (no sub-pixel text anti-aliasing artifacts or jitter).
/// - 150ms forward / 100ms reverse for responsive, immediate navigation.
/// - Full accessibility / reduced-motion support.
CustomTransitionPage<T> crmFadeSlidePage<T>({
  required LocalKey key,
  required Widget child,
  String? name,
}) {
  return CustomTransitionPage<T>(
    key: key,
    name: name,
    child: child,
    transitionDuration: CRMMotion.fast,
    reverseTransitionDuration: CRMMotion.press,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
        return child;
      }
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: CRMMotion.easeOut,
        ),
        child: child,
      );
    },
  );
}
