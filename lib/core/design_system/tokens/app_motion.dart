import 'package:flutter/animation.dart';

/// Animation duration and curve tokens — premium, restrained motion.
class CRMMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 420);

  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve bounce = Curves.easeOutBack;
  static const Curve emphasized = Curves.easeOutCubic;

  static const SpringDescription spring = SpringDescription(
    mass: 1,
    stiffness: 180,
    damping: 20,
  );

  static const SpringDescription interactiveSpring = SpringDescription(
    mass: 0.8,
    stiffness: 300,
    damping: 22,
  );

  static const Duration pageTransition = Duration(milliseconds: 360);
  static const Duration tabSwitch = Duration(milliseconds: 260);
  static const Duration atmosphere = Duration(milliseconds: 420);
  static const Duration dialog = Duration(milliseconds: 240);
  static const Duration sheet = Duration(milliseconds: 320);
  static const Duration skeleton = Duration(milliseconds: 1400);
  static const Duration press = Duration(milliseconds: 100);
  static const Duration entrySettle = Duration(milliseconds: 700);
  static const Duration nameShimmer = Duration(milliseconds: 1600);
}
