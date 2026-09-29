import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../tokens/app_motion.dart';

/// Smooth pop-in for shell routes opened from the sidebar.
CustomTransitionPage<T> crmFadeSlidePage<T>({
  required LocalKey key,
  required Widget child,
  String? name,
}) {
  return CustomTransitionPage<T>(
    key: key,
    name: name,
    child: child,
    transitionDuration: CRMMotion.medium,
    reverseTransitionDuration: CRMMotion.fast,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: const Cubic(0.22, 1.0, 0.36, 1.0),
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.03),
            end: Offset.zero,
          ).animate(curved),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.97, end: 1.0).animate(curved),
            alignment: Alignment.center,
            child: child,
          ),
        ),
      );
    },
  );
}
