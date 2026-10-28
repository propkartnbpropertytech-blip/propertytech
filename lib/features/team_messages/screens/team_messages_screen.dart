import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../../core/theme/theme_manager.dart';
import '../../../core/design_system/tokens/app_breakpoints.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../models/team_message_model.dart';
import '../services/team_messages_service.dart';
import '../../../core/services/platform_notifier/platform_notifier.dart';

/// Full dedicated screen for Team Messages with routing (/messages),
/// role categorization, and back navigation.
class TeamMessagesScreen extends StatefulWidget {
  final String? initialUserId;
  const TeamMessagesScreen({super.key, this.initialUserId});

  @override
  State<TeamMessagesScreen> createState() => _TeamMessagesScreenState();
}

class _ChatThemeConfig {
  final String id;
  final String name;
  final String category; // 'color' or 'design'
  final Color badgeColor;
  final Color primaryAccent;
  final Color outgoingBubble;
  final List<Color> lightGradient;
  final List<Color> darkGradient;
  final bool isAlwaysDark;
  final String? patternType;

  const _ChatThemeConfig({
    required this.id,
    required this.name,
    this.category = 'color',
    required this.badgeColor,
    required this.primaryAccent,
    required this.outgoingBubble,
    required this.lightGradient,
    required this.darkGradient,
    this.isAlwaysDark = false,
    this.patternType,
  });
}

class _ChatDesignPainter extends CustomPainter {
  final String patternType;
  final bool isDark;

  const _ChatDesignPainter({
    required this.patternType,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (patternType) {
      case 'doodle_dark':
        _paintDoodles(canvas, size, Colors.white.withValues(alpha: 0.08));
        break;
      case 'doodle_mint':
        _paintDoodles(canvas, size, const Color(0xFF075E54).withValues(alpha: 0.12));
        break;
      case 'wavy_paper':
        _paintWavyPaper(canvas, size);
        break;
      case 'neon_glow':
        _paintNeonGlow(canvas, size);
        break;
      case 'bokeh_bubbles':
        _paintBokehBubbles(canvas, size);
        break;
      case 'pastel_clouds':
        _paintPastelClouds(canvas, size);
        break;
      case 'matrix_grid':
        _paintMatrixGrid(canvas, size);
        break;
      case 'starry_galaxy':
        _paintStarryGalaxy(canvas, size);
        break;
    }
  }

  void _paintDoodles(Canvas canvas, Size size, Color strokeColor) {
    final paint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = strokeColor.withValues(alpha: strokeColor.a * 0.4)
      ..style = PaintingStyle.fill;

    const double stepX = 72;
    const double stepY = 72;
    int index = 0;

    for (double y = 10; y < size.height + 40; y += stepY) {
      for (double x = 10; x < size.width + 40; x += stepX) {
        final double cx = x + ((y / stepY).floor() % 2 == 1 ? 24 : 0);
        final double cy = y;
        final int shape = (index++) % 8;

        canvas.save();
        canvas.translate(cx, cy);

        switch (shape) {
          case 0:
            final rrect = RRect.fromRectAndRadius(
              const Rect.fromLTWH(-12, -9, 24, 18),
              const Radius.circular(5),
            );
            canvas.drawRRect(rrect, paint);
            final tail = Path()
              ..moveTo(-6, 9)
              ..lineTo(-9, 13)
              ..lineTo(-2, 9);
            canvas.drawPath(tail, paint);
            break;

          case 1:
            final cup = RRect.fromRectAndRadius(
              const Rect.fromLTWH(-10, -7, 18, 14),
              const Radius.circular(4),
            );
            canvas.drawRRect(cup, paint);
            final handle = Path()
              ..moveTo(8, -4)
              ..arcToPoint(const Offset(8, 4), radius: const Radius.circular(4));
            canvas.drawPath(handle, paint);
            final steam = Path()
              ..moveTo(-4, -10)
              ..quadraticBezierTo(-2, -13, -4, -16)
              ..moveTo(2, -10)
              ..quadraticBezierTo(4, -13, 2, -16);
            canvas.drawPath(steam, paint);
            break;

          case 2:
            canvas.drawCircle(Offset.zero, 11, paint);
            canvas.drawCircle(const Offset(-4, -3), 1.2, fillPaint);
            canvas.drawCircle(const Offset(4, -3), 1.2, fillPaint);
            final smile = Path()
              ..moveTo(-5, 2)
              ..quadraticBezierTo(0, 6, 5, 2);
            canvas.drawPath(smile, paint);
            break;

          case 3:
            final star = Path()
              ..moveTo(0, -11)
              ..quadraticBezierTo(0, 0, 11, 0)
              ..quadraticBezierTo(0, 0, 0, 11)
              ..quadraticBezierTo(0, 0, -11, 0)
              ..quadraticBezierTo(0, 0, 0, -11);
            canvas.drawPath(star, paint);
            break;

          case 4:
            final heart = Path()
              ..moveTo(0, 8)
              ..cubicTo(-9, 2, -11, -5, -4, -8)
              ..cubicTo(0, -8, 0, -4, 0, -4)
              ..cubicTo(0, -4, 0, -8, 4, -8)
              ..cubicTo(11, -5, 9, 2, 0, 8);
            canvas.drawPath(heart, paint);
            break;

          case 5:
            canvas.drawOval(const Rect.fromLTWH(-8, 2, 6, 5), fillPaint);
            canvas.drawOval(const Rect.fromLTWH(2, 0, 6, 5), fillPaint);
            canvas.drawLine(const Offset(-2, 4), const Offset(-2, -9), paint);
            canvas.drawLine(const Offset(8, 2), const Offset(8, -11), paint);
            canvas.drawLine(const Offset(-2, -9), const Offset(8, -11), paint);
            break;

          case 6:
            final plane = Path()
              ..moveTo(-10, 8)
              ..lineTo(10, -8)
              ..lineTo(-2, 4)
              ..close()
              ..moveTo(-2, 4)
              ..lineTo(-6, 9)
              ..lineTo(-5, 5);
            canvas.drawPath(plane, paint);
            break;

          case 7:
            canvas.drawCircle(const Offset(-2, -2), 7, paint);
            canvas.drawLine(const Offset(3, 3), const Offset(9, 9), paint);
            break;
        }

        canvas.drawCircle(const Offset(18, -14), 1.2, fillPaint);
        canvas.restore();
      }
    }
  }

  void _paintWavyPaper(Canvas canvas, Size size) {
    final colors = [
      const Color(0xFF0D9488).withValues(alpha: 0.18),
      const Color(0xFF10B981).withValues(alpha: 0.22),
      const Color(0xFF059669).withValues(alpha: 0.28),
      const Color(0xFF047857).withValues(alpha: 0.35),
      const Color(0xFF064E3B).withValues(alpha: 0.45),
    ];

    for (int i = 0; i < colors.length; i++) {
      final path = Path();
      final double startY = size.height * (0.15 + (i * 0.16));
      final double endY = size.height * (0.22 + (i * 0.15));
      final double ctrlY1 = startY + (i % 2 == 0 ? 50 : -40);
      final double ctrlY2 = endY + (i % 2 == 0 ? -50 : 60);

      path.moveTo(0, startY);
      path.cubicTo(
        size.width * 0.35, ctrlY1,
        size.width * 0.65, ctrlY2,
        size.width, endY,
      );
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();

      canvas.drawShadow(path, Colors.black.withValues(alpha: 0.4), 6, true);
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, paint);
    }
  }

  void _paintNeonGlow(Canvas canvas, Size size) {
    final glowPaint = Paint()
      ..color = const Color(0xFFA855F7).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final linePaint = Paint()
      ..color = const Color(0xFFEC4899).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final cyanGlow = Paint()
      ..color = const Color(0xFF06B6D4).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final cyanLine = Paint()
      ..color = const Color(0xFF22D3EE).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path()
      ..moveTo(24, 24)
      ..lineTo(size.width - 48, 24)
      ..lineTo(size.width - 24, 48)
      ..lineTo(size.width - 24, size.height - 24)
      ..moveTo(24, 24)
      ..lineTo(24, size.height - 48)
      ..lineTo(48, size.height - 24)
      ..lineTo(size.width - 24, size.height - 24);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, linePaint);

    final p2 = Path()
      ..moveTo(size.width * 0.8, 0)
      ..lineTo(size.width, size.height * 0.25)
      ..moveTo(0, size.height * 0.75)
      ..lineTo(size.width * 0.2, size.height);

    canvas.drawPath(p2, cyanGlow);
    canvas.drawPath(p2, cyanLine);
  }

  void _paintBokehBubbles(Canvas canvas, Size size) {
    final random = math.Random(42);
    final bubblePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.16);

    final glowPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 28; i++) {
      final double x = random.nextDouble() * size.width;
      final double y = random.nextDouble() * size.height;
      final double radius = 10 + random.nextDouble() * 26;
      final double alpha = 0.04 + random.nextDouble() * 0.08;

      glowPaint.color = const Color(0xFF06B6D4).withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), radius, glowPaint);

      if (i % 2 == 0) {
        final rrect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y), width: radius * 1.8, height: radius * 1.3),
          const Radius.circular(8),
        );
        canvas.drawRRect(rrect, bubblePaint);
      }
    }
  }

  void _paintPastelClouds(Canvas canvas, Size size) {
    final cloudPaint = Paint()..style = PaintingStyle.fill;

    final layers = [
      {'color': const Color(0xFFFBCFE8).withValues(alpha: 0.35), 'y': size.height * 0.4},
      {'color': const Color(0xFFFED7AA).withValues(alpha: 0.30), 'y': size.height * 0.6},
      {'color': const Color(0xFFE0E7FF).withValues(alpha: 0.35), 'y': size.height * 0.78},
    ];

    for (final l in layers) {
      cloudPaint.color = l['color'] as Color;
      final double y = l['y'] as double;
      final path = Path()..moveTo(0, y);

      for (double x = 0; x <= size.width; x += 60) {
        path.quadraticBezierTo(
          x + 30, y - 24,
          x + 60, y,
        );
      }

      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();
      canvas.drawPath(path, cloudPaint);
    }
  }

  void _paintMatrixGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final dotPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    const double step = 44;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    for (double x = step; x < size.width; x += step * 2) {
      for (double y = step; y < size.height; y += step * 2) {
        canvas.drawCircle(Offset(x, y), 1.8, dotPaint);
      }
    }
  }

  void _paintStarryGalaxy(Canvas canvas, Size size) {
    final random = math.Random(108);
    final starPaint = Paint()..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = const Color(0xFF818CF8).withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final points = <Offset>[];

    for (int i = 0; i < 45; i++) {
      final double x = random.nextDouble() * size.width;
      final double y = random.nextDouble() * size.height;
      final double radius = 0.8 + random.nextDouble() * 2.2;
      final double alpha = 0.2 + random.nextDouble() * 0.7;

      starPaint.color = Colors.white.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), radius, starPaint);

      if (i < 16) {
        points.add(Offset(x, y));
      }
    }

    for (int i = 0; i < points.length - 1; i += 2) {
      canvas.drawLine(points[i], points[i + 1], linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ChatDesignPainter oldDelegate) {
    return oldDelegate.patternType != patternType || oldDelegate.isDark != isDark;
  }
}

class _TeamMessagesScreenState extends State<TeamMessagesScreen>
    with WidgetsBindingObserver {
  static const List<_ChatThemeConfig> _chatThemes = [
    // ── Color Themes (Solid & Gradients) ────────────────────────
    _ChatThemeConfig(
      id: 'default',
      name: 'Classic Default',
      category: 'color',
      badgeColor: Color(0xFF64748B),
      primaryAccent: Color(0xFF0D9488),
      outgoingBubble: Color(0xFF0D9488),
      lightGradient: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
      darkGradient: [Color(0xFF0F172A), Color(0xFF1E293B)],
    ),
    _ChatThemeConfig(
      id: 'amber',
      name: 'Warm Amber',
      category: 'color',
      badgeColor: Color(0xFFF59E0B),
      primaryAccent: Color(0xFFD97706),
      outgoingBubble: Color(0xFFD97706),
      lightGradient: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
      darkGradient: [Color(0xFF2C1F0E), Color(0xFF17130B)],
    ),
    _ChatThemeConfig(
      id: 'emerald',
      name: 'Emerald Mint',
      category: 'color',
      badgeColor: Color(0xFF10B981),
      primaryAccent: Color(0xFF059669),
      outgoingBubble: Color(0xFF059669),
      lightGradient: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
      darkGradient: [Color(0xFF0F291E), Color(0xFF07140E)],
    ),
    _ChatThemeConfig(
      id: 'ocean',
      name: 'Ocean Sky',
      category: 'color',
      badgeColor: Color(0xFF0EA5E9),
      primaryAccent: Color(0xFF0284C7),
      outgoingBubble: Color(0xFF0284C7),
      lightGradient: [Color(0xFFF0F9FF), Color(0xFFE0F2FE)],
      darkGradient: [Color(0xFF0C2440), Color(0xFF071220)],
    ),
    _ChatThemeConfig(
      id: 'sunset',
      name: 'Sunset Rose',
      category: 'color',
      badgeColor: Color(0xFFEC4899),
      primaryAccent: Color(0xFFDB2777),
      outgoingBubble: Color(0xFFDB2777),
      lightGradient: [Color(0xFFFDF2F8), Color(0xFFFCE7F3)],
      darkGradient: [Color(0xFF3B182C), Color(0xFF1A0A14)],
    ),
    _ChatThemeConfig(
      id: 'violet',
      name: 'Royal Violet',
      category: 'color',
      badgeColor: Color(0xFF8B5CF6),
      primaryAccent: Color(0xFF7C3AED),
      outgoingBubble: Color(0xFF7C3AED),
      lightGradient: [Color(0xFFF5F3FF), Color(0xFFEDE9FE)],
      darkGradient: [Color(0xFF251A3E), Color(0xFF100B1E)],
    ),
    _ChatThemeConfig(
      id: 'midnight',
      name: 'Midnight Dark',
      category: 'color',
      badgeColor: Color(0xFF1E293B),
      primaryAccent: Color(0xFF38BDF8),
      outgoingBubble: Color(0xFF2563EB),
      lightGradient: [Color(0xFF090D16), Color(0xFF111827)],
      darkGradient: [Color(0xFF090D16), Color(0xFF111827)],
      isAlwaysDark: true,
    ),
    _ChatThemeConfig(
      id: 'ruby',
      name: 'Crimson Ruby',
      category: 'color',
      badgeColor: Color(0xFFE11D48),
      primaryAccent: Color(0xFFBE123C),
      outgoingBubble: Color(0xFFBE123C),
      lightGradient: [Color(0xFFFFF1F2), Color(0xFFFFE4E6)],
      darkGradient: [Color(0xFF2E0D15), Color(0xFF19060B)],
    ),
    _ChatThemeConfig(
      id: 'sage',
      name: 'Forest Sage',
      category: 'color',
      badgeColor: Color(0xFF15803D),
      primaryAccent: Color(0xFF166534),
      outgoingBubble: Color(0xFF166534),
      lightGradient: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
      darkGradient: [Color(0xFF0F2617), Color(0xFF08170D)],
    ),
    _ChatThemeConfig(
      id: 'coral',
      name: 'Tangerine Coral',
      category: 'color',
      badgeColor: Color(0xFFEA580C),
      primaryAccent: Color(0xFFC2410C),
      outgoingBubble: Color(0xFFC2410C),
      lightGradient: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
      darkGradient: [Color(0xFF2B1408), Color(0xFF170903)],
    ),
    _ChatThemeConfig(
      id: 'indigo',
      name: 'Electric Indigo',
      category: 'color',
      badgeColor: Color(0xFF4F46E5),
      primaryAccent: Color(0xFF4338CA),
      outgoingBubble: Color(0xFF4338CA),
      lightGradient: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
      darkGradient: [Color(0xFF141438), Color(0xFF0A0A20)],
    ),
    _ChatThemeConfig(
      id: 'teal',
      name: 'Laguna Teal',
      category: 'color',
      badgeColor: Color(0xFF0D9488),
      primaryAccent: Color(0xFF0F766E),
      outgoingBubble: Color(0xFF0F766E),
      lightGradient: [Color(0xFFF0FDFA), Color(0xFFCCFBF1)],
      darkGradient: [Color(0xFF092624), Color(0xFF041514)],
    ),
    _ChatThemeConfig(
      id: 'mocha',
      name: 'Espresso Mocha',
      category: 'color',
      badgeColor: Color(0xFF78350F),
      primaryAccent: Color(0xFF854D0E),
      outgoingBubble: Color(0xFF854D0E),
      lightGradient: [Color(0xFFFAF6F0), Color(0xFFF5EBE1)],
      darkGradient: [Color(0xFF1F1815), Color(0xFF120E0C)],
    ),
    _ChatThemeConfig(
      id: 'cyber',
      name: 'Cyber Onyx',
      category: 'color',
      badgeColor: Color(0xFF06B6D4),
      primaryAccent: Color(0xFF22D3EE),
      outgoingBubble: Color(0xFF0891B2),
      lightGradient: [Color(0xFF030712), Color(0xFF0B0F19)],
      darkGradient: [Color(0xFF030712), Color(0xFF0B0F19)],
      isAlwaysDark: true,
    ),

    // ── Design Themes (Patterns & Layouts) ──────────────────────
    _ChatThemeConfig(
      id: 'design_doodle_dark',
      name: 'Dark Doodles',
      category: 'design',
      badgeColor: Color(0xFF00A884),
      primaryAccent: Color(0xFF00A884),
      outgoingBubble: Color(0xFF00A884),
      lightGradient: [Color(0xFF0B141B), Color(0xFF111B21)],
      darkGradient: [Color(0xFF0B141B), Color(0xFF111B21)],
      isAlwaysDark: true,
      patternType: 'doodle_dark',
    ),
    _ChatThemeConfig(
      id: 'design_doodle_mint',
      name: 'Mint Doodles',
      category: 'design',
      badgeColor: Color(0xFF128C7E),
      primaryAccent: Color(0xFF075E54),
      outgoingBubble: Color(0xFF056162),
      lightGradient: [Color(0xFFEFEAE2), Color(0xFFE4EDE5)],
      darkGradient: [Color(0xFF16242B), Color(0xFF0F1A20)],
      patternType: 'doodle_mint',
    ),
    _ChatThemeConfig(
      id: 'design_wavy_paper',
      name: 'Emerald Waves',
      category: 'design',
      badgeColor: Color(0xFF10B981),
      primaryAccent: Color(0xFF10B981),
      outgoingBubble: Color(0xFF059669),
      lightGradient: [Color(0xFF064E3B), Color(0xFF022C22)],
      darkGradient: [Color(0xFF064E3B), Color(0xFF022C22)],
      isAlwaysDark: true,
      patternType: 'wavy_paper',
    ),
    _ChatThemeConfig(
      id: 'design_neon_glow',
      name: 'Cyber Neon',
      category: 'design',
      badgeColor: Color(0xFFA855F7),
      primaryAccent: Color(0xFFA855F7),
      outgoingBubble: Color(0xFF9333EA),
      lightGradient: [Color(0xFF070514), Color(0xFF110726)],
      darkGradient: [Color(0xFF070514), Color(0xFF110726)],
      isAlwaysDark: true,
      patternType: 'neon_glow',
    ),
    _ChatThemeConfig(
      id: 'design_bokeh_bubbles',
      name: 'Cyan Bokeh',
      category: 'design',
      badgeColor: Color(0xFF06B6D4),
      primaryAccent: Color(0xFF06B6D4),
      outgoingBubble: Color(0xFF0284C7),
      lightGradient: [Color(0xFF083344), Color(0xFF0E7490)],
      darkGradient: [Color(0xFF083344), Color(0xFF0E7490)],
      isAlwaysDark: true,
      patternType: 'bokeh_bubbles',
    ),
    _ChatThemeConfig(
      id: 'design_pastel_clouds',
      name: 'Pastel Clouds',
      category: 'design',
      badgeColor: Color(0xFFEC4899),
      primaryAccent: Color(0xFFDB2777),
      outgoingBubble: Color(0xFFDB2777),
      lightGradient: [Color(0xFFFDF2F8), Color(0xFFE0F2FE)],
      darkGradient: [Color(0xFF2E122B), Color(0xFF121B2E)],
      patternType: 'pastel_clouds',
    ),
    _ChatThemeConfig(
      id: 'design_matrix_grid',
      name: 'Tech Matrix',
      category: 'design',
      badgeColor: Color(0xFF38BDF8),
      primaryAccent: Color(0xFF38BDF8),
      outgoingBubble: Color(0xFF0284C7),
      lightGradient: [Color(0xFF0B0F17), Color(0xFF111827)],
      darkGradient: [Color(0xFF0B0F17), Color(0xFF111827)],
      isAlwaysDark: true,
      patternType: 'matrix_grid',
    ),
    _ChatThemeConfig(
      id: 'design_starry_galaxy',
      name: 'Starry Galaxy',
      category: 'design',
      badgeColor: Color(0xFF818CF8),
      primaryAccent: Color(0xFF818CF8),
      outgoingBubble: Color(0xFF6366F1),
      lightGradient: [Color(0xFF060814), Color(0xFF0F172A)],
      darkGradient: [Color(0xFF060814), Color(0xFF0F172A)],
      isAlwaysDark: true,
      patternType: 'starry_galaxy',
    ),
  ];

  String _getCurrentUserId() {
    try {
      final state = context.read<AuthBloc>().state;
      if (state is Authenticated) {
        return state.user.id;
      }
    } catch (_) {}
    return '';
  }

  String _getCurrentUserRole() {
    try {
      final state = context.read<AuthBloc>().state;
      if (state is Authenticated) {
        return state.user.role;
      }
    } catch (_) {}
    return '';
  }

  _ChatThemeConfig _getActiveTheme(String targetUserId, Color defaultPrimary) {
    final myId = _getCurrentUserId();
    final myRole = _getCurrentUserRole().toLowerCase().trim();
    final userKey = myId.isNotEmpty ? myId : myRole;

    String? themeId;
    if (userKey.isNotEmpty) {
      themeId = _userWallpapers['${userKey}_$targetUserId'] ??
          _userWallpapers['${userKey}_default'];
    }
    themeId ??= _userWallpapers[targetUserId] ?? _userWallpapers['global'];

    if (themeId == null) {
      if (myRole.contains('telecaller')) {
        themeId = 'emerald';
      } else if (myRole.contains('sales')) {
        themeId = 'ocean';
      } else {
        themeId = 'default';
      }
    }

    final config = _chatThemes.firstWhere(
      (t) => t.id == themeId,
      orElse: () => _chatThemes.first,
    );
    if (config.id == 'default') {
      return _ChatThemeConfig(
        id: 'default',
        name: 'Classic Default',
        badgeColor: const Color(0xFF64748B),
        primaryAccent: defaultPrimary,
        outgoingBubble: defaultPrimary,
        lightGradient: const [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
        darkGradient: const [Color(0xFF0F172A), Color(0xFF1E293B)],
      );
    }
    return config;
  }
  final TeamMessagesService _service = TeamMessagesService();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  final FocusNode _keyboardFocusNode = FocusNode();

  List<TeamChatUserModel> _users = [];
  TeamChatUserModel? _selectedUser;
  List<TeamMessageModel> _messages = [];

  List<TeamChatUserModel> _filteredUsers = [];
  Map<String, List<TeamChatUserModel>> _groupedUsers = {};
  List<String> _sortedTeamKeys = [];

  bool _isLoadingUsers = true;
  bool _isLoadingMessages = false;
  bool _isSending = false;
  bool _isFetchingUsers = false;
  bool _isFetchingConversation = false;
  String _selectedRoleFilter = 'All';
  String _searchQuery = '';
  bool _viewingAdminChat = false;
  final Set<String> _collapsedTeams = {};
  final Map<String, String> _userWallpapers = {};
  String? _activeAuthUserId;
  final Map<String, int> _previousUnreadByUser = {};
  String? _targetUserIdFromRoute;

  Timer? _conversationPollTimer;
  Timer? _usersPollTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      final queryUserId = GoRouterState.of(context).uri.queryParameters['userId'];
      final targetId = queryUserId ?? widget.initialUserId;
      if (targetId != null && targetId != _targetUserIdFromRoute) {
        _targetUserIdFromRoute = targetId;
        _selectUserById(targetId);
      }
    } catch (_) {}
  }

  void _selectUserById(String targetId) {
    if (_users.isEmpty) return;
    final match = _users.where((u) => u.id == targetId).firstOrNull;
    if (match != null && _selectedUser?.id != match.id) {
      setState(() {
        _selectedUser = match;
        _viewingAdminChat = false;
        _isLoadingMessages = true;
      });
      _loadConversation(match.id);
    }
  }

  Future<void> _loadUserWallpaper(String targetUserId) async {
    final myId = _getCurrentUserId();
    final myRole = _getCurrentUserRole().toLowerCase().trim();
    final userKey = myId.isNotEmpty ? myId : myRole;

    try {
      final prefs = await SharedPreferences.getInstance();
      String? saved;
      if (userKey.isNotEmpty) {
        saved = prefs.getString('chat_theme_${userKey}_$targetUserId') ??
            prefs.getString('chat_theme_user_$userKey') ??
            prefs.getString('chat_theme_role_$myRole');
      }
      saved ??= prefs.getString('chat_wallpaper_$targetUserId') ??
          prefs.getString('chat_wallpaper_global');

      if (saved != null && mounted) {
        final loadedTheme = saved;
        setState(() {
          if (userKey.isNotEmpty) {
            _userWallpapers['${userKey}_$targetUserId'] = loadedTheme;
            _userWallpapers['${userKey}_default'] = loadedTheme;
          }
          _userWallpapers[targetUserId] = loadedTheme;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadUserDefaultWallpaper() async {
    final myId = _getCurrentUserId();
    final myRole = _getCurrentUserRole().toLowerCase().trim();
    final userKey = myId.isNotEmpty ? myId : myRole;

    try {
      final prefs = await SharedPreferences.getInstance();
      String? saved;
      if (userKey.isNotEmpty) {
        saved = prefs.getString('chat_theme_user_$userKey') ??
            prefs.getString('chat_theme_role_$myRole');
      }
      saved ??= prefs.getString('chat_wallpaper_global');

      if (saved != null && mounted) {
        final loadedTheme = saved;
        setState(() {
          if (userKey.isNotEmpty) {
            _userWallpapers['${userKey}_default'] = loadedTheme;
          }
          _userWallpapers['global'] = loadedTheme;
        });
      }
    } catch (_) {}
  }

  Future<void> _saveUserWallpaper(String targetUserId, String themeId) async {
    final myId = _getCurrentUserId();
    final myRole = _getCurrentUserRole().toLowerCase().trim();
    final userKey = myId.isNotEmpty ? myId : myRole;

    setState(() {
      if (userKey.isNotEmpty) {
        _userWallpapers['${userKey}_$targetUserId'] = themeId;
        _userWallpapers['${userKey}_default'] = themeId;
      }
      _userWallpapers[targetUserId] = themeId;
      _userWallpapers['global'] = themeId;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      if (userKey.isNotEmpty) {
        await prefs.setString('chat_theme_${userKey}_$targetUserId', themeId);
        await prefs.setString('chat_theme_user_$userKey', themeId);
        if (myRole.isNotEmpty) {
          await prefs.setString('chat_theme_role_$myRole', themeId);
        }
      }
      await prefs.setString('chat_wallpaper_$targetUserId', themeId);
      await prefs.setString('chat_wallpaper_global', themeId);
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {}
    _loadUserDefaultWallpaper();
    _loadUsers();
    _startTimers();
  }

  void _startTimers() {
    _conversationPollTimer?.cancel();
    _usersPollTimer?.cancel();

    // Poll active conversation every 4 seconds
    _conversationPollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_selectedUser != null && !_isFetchingConversation && !_isLoadingMessages && mounted) {
        _loadConversation(_selectedUser!.id, silent: true);
      }
    });

    // Poll team users roster every 4 seconds (for incoming messages & unread counts)
    _usersPollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_isFetchingUsers && !_isLoadingUsers && mounted) {
        _loadUsers(silent: true);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _conversationPollTimer?.cancel();
      _conversationPollTimer = null;
      _usersPollTimer?.cancel();
      _usersPollTimer = null;
    } else if (state == AppLifecycleState.resumed) {
      _startTimers();
      if (_selectedUser != null && !_isFetchingConversation && !_isLoadingMessages && mounted) {
        _loadConversation(_selectedUser!.id, silent: true);
      }
      if (!_isFetchingUsers && !_isLoadingUsers && mounted) {
        _loadUsers(silent: true);
      }
    }
  }

  @override
  void dispose() {
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
    _conversationPollTimer?.cancel();
    _usersPollTimer?.cancel();
    _keyboardFocusNode.dispose();
    _messageController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  void _recomputeFilteredAndGroupedUsers() {
    final authState = context.read<AuthBloc>().state;
    final currentUserRole = authState is Authenticated ? authState.user.role.toLowerCase() : '';
    final isSuperAdmin = currentUserRole == 'super admin';

    final filtered = _users.where((user) {
      // Telecaller, Salesperson, and Admin accounts must not see Admin users (only Super Admin sees Admins)
      if (!isSuperAdmin && user.role.toLowerCase().contains('admin')) {
        return false;
      }

      final matchesSearch = _searchQuery.isEmpty ||
          user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.role.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (user.teamName ?? '').toLowerCase().contains(_searchQuery.toLowerCase());

      if (!matchesSearch) return false;

      if (_selectedRoleFilter == 'All') return true;
      if (_selectedRoleFilter == 'Admins') {
        return user.role.toLowerCase().contains('admin');
      }
      if (_selectedRoleFilter == 'Telecallers') {
        return user.role.toLowerCase().contains('telecaller');
      }
      if (_selectedRoleFilter == 'Sales') {
        return user.role.toLowerCase().contains('sales');
      }
      return true;
    }).toList();

    final Map<String, List<TeamChatUserModel>> map = {};
    for (final u in filtered) {
      final key = u.teamName ?? 'General Team';
      if (!map.containsKey(key)) {
        map[key] = [];
      }
      map[key]!.add(u);
    }

    int roleRank(String r) {
      final s = r.toLowerCase();
      if (s.contains('admin')) return 1;
      if (s.contains('telecaller')) return 2;
      return 3;
    }

    for (final key in map.keys) {
      map[key]!.sort((a, b) {
        final rankDiff = roleRank(a.role) - roleRank(b.role);
        if (rankDiff != 0) return rankDiff;
        return a.name.compareTo(b.name);
      });
    }

    final keys = map.keys.toList();
    keys.sort((a, b) {
      final aIsProp = a.toLowerCase().contains('propkart');
      final bIsProp = b.toLowerCase().contains('propkart');
      if (aIsProp && !bIsProp) return -1;
      if (!aIsProp && bIsProp) return 1;
      return a.compareTo(b);
    });

    _filteredUsers = filtered;
    _groupedUsers = map;
    _sortedTeamKeys = keys;
  }

  Future<void> _loadUsers({bool silent = false}) async {
    if (_isFetchingUsers) return;
    _isFetchingUsers = true;

    if (!silent) {
      setState(() => _isLoadingUsers = true);
    }
    try {
      final fetchedUsers = await _service.getTeamUsers();
      if (mounted) {
        final screenWidth = MediaQuery.sizeOf(context).width;
        final isMobile = screenWidth < 768;
        TeamChatUserModel? userToLoad;

        var users = fetchedUsers;

        // Check for new incoming messages during background silent poll and display notification
        if (silent && _previousUnreadByUser.isNotEmpty) {
          for (final u in users) {
            final prevUnread = _previousUnreadByUser[u.id] ?? 0;
            if (u.unreadCount > prevUnread && u.lastMessage != null && u.lastMessage!.trim().isNotEmpty) {
              if (_selectedUser?.id != u.id) {
                PlatformNotifier.showNotification(
                  title: u.name,
                  body: u.lastMessage!.trim(),
                  data: {
                    'route': '/messages?userId=${u.id}',
                    'type': 'team_message',
                    'senderId': u.id,
                  },
                );
              }
            }
          }
        }
        for (final u in users) {
          _previousUnreadByUser[u.id] = u.unreadCount;
        }

        setState(() {
          _users = users;
          _isLoadingUsers = false;
          _recomputeFilteredAndGroupedUsers();

          final pendingTargetId = _targetUserIdFromRoute ?? widget.initialUserId;
          if (pendingTargetId != null) {
            final match = _users.where((u) => u.id == pendingTargetId).firstOrNull;
            if (match != null && (_selectedUser == null || _selectedUser!.id != match.id)) {
              _selectedUser = match;
              _viewingAdminChat = false;
              _isLoadingMessages = true;
              userToLoad = match;
            }
          }

          if (_selectedUser == null && _users.isNotEmpty && !isMobile) {
            final firstTeam = _sortedTeamKeys.firstOrNull;
            userToLoad = (firstTeam != null ? _groupedUsers[firstTeam]?.firstOrNull : null) ?? _users.first;
            _selectedUser = userToLoad;
            _viewingAdminChat = false;
            _isLoadingMessages = true;
          } else if (_selectedUser != null && userToLoad == null) {
            final match = _users.where((u) => u.id == _selectedUser!.id).firstOrNull;
            if (match != null) {
              _selectedUser = match;
            } else if (_users.isNotEmpty && !isMobile) {
              final firstTeam = _sortedTeamKeys.firstOrNull;
              userToLoad = (firstTeam != null ? _groupedUsers[firstTeam]?.firstOrNull : null) ?? _users.first;
              _selectedUser = userToLoad;
              _viewingAdminChat = false;
              _isLoadingMessages = true;
            } else {
              _selectedUser = null;
            }
          }
        });

        if (userToLoad != null && mounted) {
          _loadUserWallpaper(userToLoad!.id);
          _loadConversation(userToLoad!.id);
        }
      }
    } catch (e) {
      debugPrint('[TeamMessages] Error loading users: $e');
      if (mounted && !silent) {
        setState(() => _isLoadingUsers = false);
      }
    } finally {
      _isFetchingUsers = false;
    }
  }

  Future<void> _selectUser(TeamChatUserModel user) async {
    _loadUserWallpaper(user.id);
    setState(() {
      _selectedUser = user;
      _viewingAdminChat = false;
      _isLoadingMessages = true;
      _messages = [];
    });

    await _loadConversation(user.id);
  }

  Future<void> _loadConversation(String otherUserId, {bool silent = false}) async {
    if (_isFetchingConversation) return;
    _isFetchingConversation = true;

    try {
      final authState = context.read<AuthBloc>().state;
      final isSuperAdmin = authState is Authenticated &&
          authState.user.role.toLowerCase() == 'super admin';
      final withAdminId = (_viewingAdminChat && isSuperAdmin && _selectedUser?.role.toLowerCase() != 'admin')
          ? _selectedUser?.adminId
          : null;

      final fetchedMessages = await _service.getConversation(
        otherUserId,
        withAdminId: withAdminId,
      );
      if (mounted) {
        final hadMessagesBefore = _messages.isNotEmpty;
        final hasNewMessages = fetchedMessages.length != _messages.length;
        setState(() {
          _messages = fetchedMessages;
          _isLoadingMessages = false;
        });
        if (!hadMessagesBefore || hasNewMessages) {
          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint('[TeamMessages] Error loading conversation: $e');
      if (mounted && !silent) {
        setState(() => _isLoadingMessages = false);
      }
    } finally {
      _isFetchingConversation = false;
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _selectedUser == null || _isSending) return;

    if (_viewingAdminChat) {
      setState(() => _viewingAdminChat = false);
    }

    final targetUser = _selectedUser!;
    _messageController.clear();

    setState(() {
      _isSending = true;
    });

    try {
      final sentMessage = await _service.sendMessage(
        receiverId: targetUser.id,
        message: text,
      );
      if (mounted) {
        setState(() {
          _messages.add(sentMessage);
          _isSending = false;
        });
        _scrollToBottom();
        _loadUsers(silent: true);
        _messageFocusNode.requestFocus();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: ${e.toString()}'),
            backgroundColor: CRMColors.danger,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }



  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final primaryColor = ThemeManager().primaryColor;
    final isMobile = CRMBreakpoints.isPhone(context);

    final authState = context.watch<AuthBloc>().state;
    final currentUserId = authState is Authenticated ? authState.user.id : '';
    final currentUserRole = authState is Authenticated ? authState.user.role : '';

    if (_activeAuthUserId != currentUserId && currentUserId.isNotEmpty) {
      _activeAuthUserId = currentUserId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadUserDefaultWallpaper();
          if (_selectedUser != null) {
            _loadUserWallpaper(_selectedUser!.id);
          }
        }
      });
    }

    return PopScope(
      canPop: !isMobile || _selectedUser == null,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_selectedUser != null) {
          setState(() => _selectedUser = null);
        }
      },
      child: ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(
              isMobile
                  ? (_selectedUser != null ? 0 : CRMSpacing.s)
                  : CRMSpacing.l,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!isMobile || _selectedUser == null) ...[
                  // ── Master Screen Header with Back Button ─────────────
                  _buildTopHeader(context, isDark, primaryColor, currentUserRole),
                  const SizedBox(height: CRMSpacing.m),
                ],

                // ── Main Body Messenger Container ─────────────────────
                Expanded(
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: (isMobile && _selectedUser != null)
                          ? BorderRadius.zero
                          : BorderRadius.circular(12),
                      border: (isMobile && _selectedUser != null)
                          ? null
                          : Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                    ),
                    child: isMobile
                        ? (_selectedUser == null
                            ? _buildUserSidebar(isDark, primaryColor)
                            : _buildChatThread(isDark, primaryColor, currentUserId, currentUserRole, isMobile: true))
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Left User Roster Column
                              SizedBox(
                                width: 320,
                                child: _buildUserSidebar(isDark, primaryColor),
                              ),
                              // Vertical Divider
                              Container(
                                width: 1,
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              ),
                              // Right Active Chat Column
                              Expanded(
                                child: _buildChatThread(isDark, primaryColor, currentUserId, currentUserRole),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Top Page Header with Back Button ──────────────────────────
  Widget _buildTopHeader(
    BuildContext context,
    bool isDark,
    Color primaryColor,
    String currentUserRole,
  ) {
    return Row(
      children: [
        // Back Button
        IconButton.filledTonal(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          tooltip: 'Back to Dashboard',
          style: IconButton.styleFrom(
            minimumSize: const Size(48, 48),
            backgroundColor: primaryColor.withValues(alpha: 0.12),
            foregroundColor: primaryColor,
          ),
        ),
        const SizedBox(width: CRMSpacing.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      'Team Messages',
                      overflow: TextOverflow.ellipsis,
                      style: CRMTypography.sectionTitle.copyWith(
                        color: CRMColors.textOf(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(CRMBorderRadius.badge),
                      border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      currentUserRole.isNotEmpty ? currentUserRole.toUpperCase() : 'TEAM',
                      style: CRMTypography.captionBold.copyWith(
                        color: primaryColor,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Direct end-to-end messaging across Propkart Admin, Telecallers, and Sales team',
                style: CRMTypography.caption.copyWith(
                  color: CRMColors.textSecondaryOf(context),
                ),
              ),
            ],
          ),
        ),
        // Refresh Button
        IconButton(
          onPressed: () => _loadUsers(),
          icon: const Icon(Icons.refresh_rounded, size: 20),
          tooltip: 'Refresh conversations',
          color: CRMColors.textSecondaryOf(context),
        ),
      ],
    );
  }

  // ── Left User Sidebar ─────────────────────────────────────────
  Widget _buildUserSidebar(bool isDark, Color primaryColor) {
    final authState = context.read<AuthBloc>().state;
    final currentUserRole = authState is Authenticated ? authState.user.role.toLowerCase() : '';
    final isSuperAdmin = currentUserRole == 'super admin';
    final roles = isSuperAdmin
        ? ['All', 'Admins', 'Telecallers', 'Sales']
        : ['All', 'Telecallers', 'Sales'];

    return Column(
      children: [
        // Search & Role Filter Header
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
          ),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim();
                    _recomputeFilteredAndGroupedUsers();
                  });
                },
                style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textOf(context)),
                decoration: InputDecoration(
                  hintText: 'Search team member...',
                  hintStyle: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
                  prefixIcon: Icon(Icons.search_rounded, size: 18, color: CRMColors.textSecondaryOf(context)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _recomputeFilteredAndGroupedUsers();
                            });
                          },
                        )
                      : null,
                  isDense: true,
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: CRMColors.borderOf(context)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: CRMColors.borderOf(context)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: primaryColor),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Role Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: roles.map((role) {
                    final isSelected = _selectedRoleFilter == role;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(role),
                        selected: isSelected,
                        selectedColor: primaryColor.withValues(alpha: 0.15),
                        backgroundColor: Colors.transparent,
                        labelStyle: CRMTypography.captionBold.copyWith(
                          fontSize: 11,
                          color: isSelected ? primaryColor : CRMColors.textSecondaryOf(context),
                        ),
                        side: BorderSide(
                          color: isSelected ? primaryColor : CRMColors.borderOf(context),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(CRMBorderRadius.badge),
                        ),
                        visualDensity: VisualDensity.compact,
                        onSelected: (_) {
                          setState(() {
                            _selectedRoleFilter = role;
                            _recomputeFilteredAndGroupedUsers();
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // User list grouped by teams
        Expanded(
          child: _isLoadingUsers
              ? const Center(child: CircularProgressIndicator())
              : _filteredUsers.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.group_off_rounded, size: 36, color: CRMColors.textSecondaryOf(context)),
                            const SizedBox(height: 8),
                            Text(
                              'No team members found',
                              style: CRMTypography.captionBold.copyWith(color: CRMColors.textOf(context)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Team members will appear organized by team units here.',
                              textAlign: TextAlign.center,
                              style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _sortedTeamKeys.length,
                      itemBuilder: (context, teamIndex) {
                        final teamName = _sortedTeamKeys[teamIndex];
                        final teamUsers = _groupedUsers[teamName] ?? [];
                        final isCollapsed = _collapsedTeams.contains(teamName);
                        final isPropkart = teamName.toLowerCase().contains('propkart');

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Team Section Header
                            InkWell(
                              onTap: () {
                                setState(() {
                                  if (isCollapsed) {
                                    _collapsedTeams.remove(teamName);
                                  } else {
                                    _collapsedTeams.add(teamName);
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                margin: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isPropkart
                                      ? const Color(0xFF2563EB).withValues(alpha: isDark ? 0.18 : 0.08)
                                      : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isPropkart
                                        ? const Color(0xFF2563EB).withValues(alpha: 0.3)
                                        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isPropkart ? Icons.verified_user_rounded : Icons.corporate_fare_rounded,
                                      size: 16,
                                      color: isPropkart
                                          ? const Color(0xFF2563EB)
                                          : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        isPropkart ? 'Propkart Admin Team' : '$teamName Team',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${teamUsers.length}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      isCollapsed ? Icons.keyboard_arrow_right_rounded : Icons.keyboard_arrow_down_rounded,
                                      size: 18,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Team Members List
                            if (!isCollapsed)
                              ...teamUsers.map((user) => _buildUserTile(user, primaryColor, isDark)),
                          ],
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildUserTile(
    TeamChatUserModel user,
    Color primaryColor,
    bool isDark,
  ) {
    final isSelected = _selectedUser?.id == user.id;
    final roleColor = _getRoleColor(user.role);
    final isAdmin = user.role.toLowerCase() == 'admin';

    return InkWell(
      onTap: () => _selectUser(user),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: isDark ? 0.18 : 0.08)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? primaryColor : Colors.transparent,
              width: 3.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // Avatar with status
            Stack(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: roleColor.withValues(alpha: 0.15),
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: roleColor,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: CRMColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                user.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isAdmin) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.star_rounded, size: 14, color: Color(0xFF2563EB)),
                            ],
                          ],
                        ),
                      ),
                      if (user.lastMessageAt != null)
                        Text(
                          _formatTimeAgo(user.lastMessageAt!),
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      // Distinct Role Badge
                      _buildRoleBadge(user.role, roleColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          user.lastMessage ?? user.email,
                          style: TextStyle(
                            fontSize: 11,
                            color: user.unreadCount > 0
                                ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                            fontWeight: user.unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user.unreadCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${user.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Right Chat Area ───────────────────────────────────────────
  Widget _buildChatThread(
    bool isDark,
    Color primaryColor,
    String currentUserId,
    String currentUserRole, {
    bool isMobile = false,
  }) {
    if (_selectedUser == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.forum_outlined, size: 48, color: primaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              'Select a team member',
              style: CRMTypography.sectionTitle.copyWith(
                color: CRMColors.textOf(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Chat directly with Propkart Admin, Telecallers, and Sales agents',
              style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
            ),
          ],
        ),
      );
    }

    final targetUser = _selectedUser!;
    final roleColor = _getRoleColor(targetUser.role);
    final themeConfig = _getActiveTheme(targetUser.id, primaryColor);
    final bool isEffectiveDark = themeConfig.isAlwaysDark || isDark;

    return Column(
      children: [
        // Top Conversation Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
            border: Border(
              bottom: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
          ),
          child: Row(
            children: [
              if (isMobile) ...[
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, size: 20),
                  onPressed: () => setState(() => _selectedUser = null),
                  tooltip: 'Back to team members',
                ),
                const SizedBox(width: 4),
              ],
              CircleAvatar(
                radius: 18,
                backgroundColor: roleColor.withValues(alpha: 0.15),
                child: Text(
                  targetUser.name.isNotEmpty ? targetUser.name[0].toUpperCase() : 'U',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: roleColor,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            targetUser.name,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildRoleBadge(targetUser.role, roleColor),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${targetUser.email} • Team: ${targetUser.teamName ?? 'Propkart'}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.wallpaper_rounded, size: 18),
                onPressed: () => _showWallpaperPicker(context, targetUser.id, targetUser.name),
                tooltip: 'Chat Theme / Wallpaper',
                color: themeConfig.primaryAccent,
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 18),
                onPressed: () => _loadConversation(targetUser.id),
                tooltip: 'Refresh chat',
                color: CRMColors.textSecondaryOf(context),
              ),
            ],
          ),
        ),

        // Super Admin Mode Switcher: Direct Chat vs Admin Conversation Inspection
        if (currentUserRole.toLowerCase() == 'super admin' &&
            targetUser.role.toLowerCase() != 'admin' &&
            targetUser.adminName != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<bool>(
                    segments: [
                      const ButtonSegment<bool>(
                        value: false,
                        icon: Icon(Icons.chat_outlined, size: 14),
                        label: Text('Direct Chat', style: TextStyle(fontSize: 11.5)),
                      ),
                      ButtonSegment<bool>(
                        value: true,
                        icon: const Icon(Icons.history_edu_rounded, size: 14),
                        label: Text('Team Chat (${targetUser.adminName})', style: const TextStyle(fontSize: 11.5)),
                      ),
                    ],
                    selected: {_viewingAdminChat},
                    onSelectionChanged: (Set<bool> val) {
                      setState(() {
                        _viewingAdminChat = val.first;
                        _isLoadingMessages = true;
                      });
                      _loadConversation(targetUser.id);
                    },
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_viewingAdminChat)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              color: const Color(0xFF2563EB).withValues(alpha: 0.1),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Inspection Mode: Viewing messages between ${targetUser.name} and ${targetUser.adminName ?? 'Admin'}.',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],

        // Message bubbles list and seamless floating input (all over the wallpaper background)
        Expanded(
          child: _buildWallpaperBackground(
            themeConfig: themeConfig,
            isDark: isDark,
            child: Column(
              children: [
                Expanded(
                  child: _isLoadingMessages
                      ? Center(
                          child: CircularProgressIndicator(
                            color: themeConfig.primaryAccent,
                          ),
                        )
                      : _messages.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: themeConfig.primaryAccent.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      size: 36,
                                      color: themeConfig.primaryAccent,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'No messages yet',
                                    style: CRMTypography.captionBold.copyWith(
                                      color: isEffectiveDark ? Colors.white : const Color(0xFF0F172A),
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Send a greeting to start chatting with ${targetUser.name}',
                                    style: CRMTypography.caption.copyWith(
                                      color: isEffectiveDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                final msg = _messages[index];
                                final bool isMe;
                                final String? senderLabel;

                                if (_viewingAdminChat) {
                                  isMe = msg.senderId != targetUser.id;
                                  senderLabel = msg.senderId == targetUser.id
                                      ? targetUser.name
                                      : (targetUser.adminName ?? 'Admin');
                                } else {
                                  isMe = msg.senderId == currentUserId;
                                  senderLabel = null;
                                }

                                final bool showDateHeader;
                                if (index == 0) {
                                  showDateHeader = true;
                                } else {
                                  final prevMsg = _messages[index - 1];
                                  final prevDate = prevMsg.createdAt.toLocal();
                                  final currDate = msg.createdAt.toLocal();
                                  showDateHeader = prevDate.year != currDate.year ||
                                      prevDate.month != currDate.month ||
                                      prevDate.day != currDate.day;
                                }

                                final bubble = _buildMessageBubble(
                                  msg,
                                  isMe,
                                  themeConfig.outgoingBubble,
                                  isEffectiveDark,
                                  senderLabel: senderLabel,
                                  currentUserRole: currentUserRole,
                                );

                                if (showDateHeader) {
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      _buildDateHeaderChip(msg.createdAt, isEffectiveDark),
                                      bubble,
                                    ],
                                  );
                                }
                                return bubble;
                              },
                            ),
                ),

                // Seamless floating input bar (no background container)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: KeyboardListener(
                          focusNode: _keyboardFocusNode,
                          onKeyEvent: (event) {
                            if (event is KeyDownEvent &&
                                event.logicalKey == LogicalKeyboardKey.enter &&
                                !HardwareKeyboard.instance.isShiftPressed) {
                              _sendMessage();
                            }
                          },
                          child: TextField(
                            controller: _messageController,
                            focusNode: _messageFocusNode,
                            minLines: 1,
                            maxLines: 4,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: isEffectiveDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Type your message to ${targetUser.name}...',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: isEffectiveDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                              fillColor: isEffectiveDark
                                  ? const Color(0xFF0F172A).withValues(alpha: 0.85)
                                  : Colors.white.withValues(alpha: 0.95),
                              filled: true,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide(
                                  color: isEffectiveDark
                                      ? Colors.white.withValues(alpha: 0.12)
                                      : Colors.black.withValues(alpha: 0.08),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide(
                                  color: isEffectiveDark
                                      ? Colors.white.withValues(alpha: 0.12)
                                      : Colors.black.withValues(alpha: 0.08),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide(
                                  color: themeConfig.primaryAccent.withValues(alpha: 0.7),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _isSending ? null : _sendMessage,
                        icon: _isSending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.send_rounded, size: 18),
                        style: IconButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          backgroundColor: themeConfig.outgoingBubble,
                          foregroundColor: Colors.white,
                          elevation: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _deleteMessage(String messageId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: CRMColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final success = await _service.deleteMessage(messageId);
      if (success && mounted) {
        setState(() {
          _messages.removeWhere((m) => m.id == messageId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message deleted successfully'),
            duration: Duration(seconds: 2),
          ),
        );
        _loadUsers(silent: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete message: ${e.toString()}'),
            backgroundColor: CRMColors.danger,
          ),
        );
      }
    }
  }

  Widget _buildMessageBubble(
    TeamMessageModel msg,
    bool isMe,
    Color outgoingColor,
    bool isEffectiveDark, {
    String? senderLabel,
    String currentUserRole = '',
  }) {
    final bubbleColor = isMe
        ? outgoingColor
        : (isEffectiveDark ? const Color(0xFF1E293B) : Colors.white);
    final textColor = isMe
        ? Colors.white
        : (isEffectiveDark ? Colors.white : const Color(0xFF0F172A));
    final canDelete = isMe || currentUserRole.toLowerCase().contains('admin');

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: const BoxConstraints(
          maxWidth: 520,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isMe ? 14 : 2),
            bottomRight: Radius.circular(isMe ? 2 : 14),
          ),
          border: isMe
              ? null
              : Border.all(
                  color: isEffectiveDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  width: 0.5,
                ),
          boxShadow: isMe
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isEffectiveDark ? 0.2 : 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (senderLabel != null) ...[
              Text(
                senderLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isMe
                      ? (isEffectiveDark ? Colors.lightBlueAccent : Colors.white)
                      : (isEffectiveDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB)),
                ),
              ),
              const SizedBox(height: 3),
            ],
            Text(
              msg.message,
              style: TextStyle(
                fontSize: 13.5,
                color: textColor,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('h:mm a').format(msg.createdAt.toLocal()),
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.white70 : (isEffectiveDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    msg.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                    size: 13,
                    color: Colors.white,
                  ),
                ],
                if (canDelete) ...[
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => _deleteMessage(msg.id),
                    borderRadius: BorderRadius.circular(4),
                    child: Tooltip(
                      message: 'Delete message',
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 13,
                          color: isMe ? Colors.white70 : (isEffectiveDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Role Badge Pill ───────────────────────────────────────────
  Widget _buildRoleBadge(String role, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    final r = role.toLowerCase().trim();
    if (r.contains('super')) return const Color(0xFFF59E0B); // Amber
    if (r.contains('admin')) return const Color(0xFF2563EB); // Blue
    if (r.contains('telecaller')) return const Color(0xFF059669); // Emerald Green
    return const Color(0xFF7C3AED); // Purple for Sales
  }

  String _formatDynamicMessageDate(DateTime time) {
    final localTime = time.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDate = DateTime(localTime.year, localTime.month, localTime.day);

    if (msgDate == today) {
      return 'Today';
    } else if (msgDate == yesterday) {
      return 'Yesterday';
    } else {
      if (localTime.year == now.year) {
        return DateFormat('MMM d').format(localTime);
      } else {
        return DateFormat('MMM d, yyyy').format(localTime);
      }
    }
  }

  String _formatTimeAgo(DateTime time) {
    return _formatDynamicMessageDate(time);
  }

  Widget _buildDateHeaderChip(DateTime dateTime, bool isEffectiveDark) {
    final dateLabel = _formatDynamicMessageDate(dateTime);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isEffectiveDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isEffectiveDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              width: 0.5,
            ),
          ),
          child: Text(
            dateLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isEffectiveDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWallpaperBackground({
    required _ChatThemeConfig themeConfig,
    required bool isDark,
    required Widget child,
  }) {
    final gradientDecoration = BoxDecoration(
      gradient: LinearGradient(
        colors: isDark ? themeConfig.darkGradient : themeConfig.lightGradient,
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    );

    if (themeConfig.patternType != null) {
      return Container(
        decoration: gradientDecoration,
        child: CustomPaint(
          painter: _ChatDesignPainter(
            patternType: themeConfig.patternType!,
            isDark: isDark,
          ),
          child: child,
        ),
      );
    }

    return Container(
      decoration: gradientDecoration,
      child: child,
    );
  }

  void _showWallpaperPicker(BuildContext context, String targetUserId, String targetUserName) {
    final activeTheme = _getActiveTheme(targetUserId, CRMColors.primary);
    String currentTheme = activeTheme.id;
    String selectedFolder = activeTheme.category;
    final myRole = _getCurrentUserRole().trim();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final liveTheme = _getActiveTheme(targetUserId, CRMColors.primary);
          final isDark = ThemeManager().isDarkMode;
          final colorThemes = _chatThemes.where((t) => t.category == 'color').toList();
          final designThemes = _chatThemes.where((t) => t.category == 'design').toList();

          final isMobile = MediaQuery.of(ctx).size.width < 600;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            insetPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 40,
              vertical: 24,
            ),
            titlePadding: EdgeInsets.fromLTRB(
              isMobile ? 16 : 24,
              isMobile ? 16 : 24,
              isMobile ? 16 : 24,
              8,
            ),
            contentPadding: EdgeInsets.fromLTRB(
              isMobile ? 16 : 24,
              12,
              isMobile ? 16 : 24,
              16,
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: liveTheme.primaryAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.palette_rounded, color: liveTheme.primaryAccent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Chat Theme ($targetUserName)',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      if (myRole.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Personalized for ${myRole[0].toUpperCase()}${myRole.substring(1)} Account',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: liveTheme.primaryAccent,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 720,
                maxHeight: (MediaQuery.of(ctx).size.height * 0.8).clamp(350.0, 540.0),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose a visual theme for your chat with $targetUserName (applies to your account only):',
                      style: const TextStyle(fontSize: 12.5, color: Colors.grey),
                    ),
                    const SizedBox(height: 14),

                    // ── Folder Selection Tabs: Color Themes vs Design Themes ──
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setDialogState(() {
                                  selectedFolder = 'color';
                                });
                              },
                              borderRadius: BorderRadius.circular(9),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: EdgeInsets.symmetric(vertical: 9, horizontal: isMobile ? 4 : 8),
                                decoration: BoxDecoration(
                                  color: selectedFolder == 'color'
                                      ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(9),
                                  boxShadow: selectedFolder == 'color'
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.08),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.palette_rounded,
                                      size: 16,
                                      color: selectedFolder == 'color'
                                          ? liveTheme.primaryAccent
                                          : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        'Color Themes (${colorThemes.length})',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: selectedFolder == 'color' ? FontWeight.bold : FontWeight.w600,
                                          color: selectedFolder == 'color'
                                              ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setDialogState(() {
                                  selectedFolder = 'design';
                                });
                              },
                              borderRadius: BorderRadius.circular(9),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: EdgeInsets.symmetric(vertical: 9, horizontal: isMobile ? 4 : 8),
                                decoration: BoxDecoration(
                                  color: selectedFolder == 'design'
                                      ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(9),
                                  boxShadow: selectedFolder == 'design'
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.08),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.auto_awesome_mosaic_rounded,
                                      size: 16,
                                      color: selectedFolder == 'design'
                                          ? liveTheme.primaryAccent
                                          : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        'Design Themes (${designThemes.length})',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: selectedFolder == 'design' ? FontWeight.bold : FontWeight.w600,
                                          color: selectedFolder == 'design'
                                              ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Folder Content: Color Themes vs Design Themes ─────────
                    if (selectedFolder == 'color') ...[
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 450;
                          final cardWidth = isNarrow
                              ? (constraints.maxWidth >= 330
                                  ? ((constraints.maxWidth - 20) / 3).floorToDouble()
                                  : ((constraints.maxWidth - 10) / 2).floorToDouble())
                              : 108.0;
                          return Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: colorThemes.map((w) {
                              final isSelected = currentTheme == w.id;
                              final color = w.badgeColor;
                              return InkWell(
                                onTap: () async {
                                  setDialogState(() {
                                    currentTheme = w.id;
                                  });
                                  await _saveUserWallpaper(targetUserId, w.id);
                                  if (ctx.mounted) {
                                    Navigator.of(ctx).pop();
                                  }
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: cardWidth,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? color.withValues(alpha: 0.18)
                                        : color.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? color : color.withValues(alpha: 0.25),
                                      width: isSelected ? 2.5 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: color,
                                        child: isSelected
                                            ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                                            : null,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        w.name,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          color: color,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ] else ...[
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 450;
                          final cardWidth = isNarrow
                              ? (constraints.maxWidth >= 260
                                  ? ((constraints.maxWidth - 12) / 2).floorToDouble()
                                  : constraints.maxWidth)
                              : 138.0;
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: designThemes.map((w) {
                              final isSelected = currentTheme == w.id;
                              return InkWell(
                                onTap: () async {
                                  setDialogState(() {
                                    currentTheme = w.id;
                                  });
                                  await _saveUserWallpaper(targetUserId, w.id);
                                  if (ctx.mounted) {
                                    Navigator.of(ctx).pop();
                                  }
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: cardWidth,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? w.primaryAccent.withValues(alpha: 0.14)
                                        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? w.primaryAccent
                                          : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                      width: isSelected ? 2.5 : 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          height: 62,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: isDark ? w.darkGradient : w.lightGradient,
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                            ),
                                          ),
                                          child: Stack(
                                            children: [
                                              if (w.patternType != null)
                                                Positioned.fill(
                                                  child: CustomPaint(
                                                    painter: _ChatDesignPainter(
                                                      patternType: w.patternType!,
                                                      isDark: isDark,
                                                    ),
                                                  ),
                                                ),
                                              if (isSelected)
                                                Center(
                                                  child: Container(
                                                    padding: const EdgeInsets.all(4),
                                                    decoration: BoxDecoration(
                                                      color: w.primaryAccent,
                                                      shape: BoxShape.circle,
                                                      boxShadow: const [
                                                        BoxShadow(color: Colors.black38, blurRadius: 4),
                                                      ],
                                                    ),
                                                    child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        w.name,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                          color: isSelected
                                              ? w.primaryAccent
                                              : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }
}
