import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../tokens/app_motion.dart';

/// Light fade for shell routes — keep short to avoid mobile lag/stuck feel.
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
    reverseTransitionDuration: CRMMotion.fast,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(opacity: curved, child: child);
    },
  );
}
