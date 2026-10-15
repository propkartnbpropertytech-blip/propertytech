import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../support/widgets/roakbot_dialog.dart';
import '../../../core/services/roakbot/roakbot_service.dart';

class FloatingMascotChatbotButton extends StatefulWidget {
  const FloatingMascotChatbotButton({super.key});

  @override
  State<FloatingMascotChatbotButton> createState() =>
      _FloatingMascotChatbotButtonState();
}

class _FloatingMascotChatbotButtonState
    extends State<FloatingMascotChatbotButton>
    with TickerProviderStateMixin {
  static const String _mascotGifUrl =
      'https://res.cloudinary.com/haacwr5z/image/upload/v1792041589/roakbot/k4t0dfawrgayape2ztkr.gif';
  static const Color _primaryColor = Color(0xFF0F172A);

  late final AnimationController _bobbingController;
  late final Animation<double> _bobbingAnimation;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  bool _isHovered = false;
  bool _showSpeechBubble = true;

  @override
  void initState() {
    super.initState();

    // 1. Smooth up/down floating bobbing motion
    _bobbingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _bobbingAnimation = Tween<double>(begin: 0, end: -7).animate(
      CurvedAnimation(
        parent: _bobbingController,
        curve: Curves.easeInOutSine,
      ),
    );

    // 2. Subtle pulse halo glow ring
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _bobbingController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onChatbotTap() {
    if (kIsWeb) {
      RoakbotService.open();
    }
    RoakbotDialog.show(context);
  }

  @override
  Widget build(BuildContext context) {
    // On Web, the native Roakbot dynamic widget script from index.html automatically
    // renders the floating mascot GIF button and invitation bubble with auto-sync.
    if (kIsWeb) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: Listenable.merge([_bobbingAnimation, _pulseAnimation]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bobbingAnimation.value),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Playful Speech Bubble
              if (_showSpeechBubble) ...[
                GestureDetector(
                  onTap: _onChatbotTap,
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '👋 Need assistance? Tap to chat!',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            setState(() => _showSpeechBubble = false);
                          },
                          child: Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Mascot Floating Button
              MouseRegion(
                onEnter: (_) => setState(() => _isHovered = true),
                onExit: (_) => setState(() => _isHovered = false),
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: _onChatbotTap,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // Pulsing halo aura
                      Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _primaryColor.withValues(
                              alpha: math.max(
                                0.0,
                                0.35 * (1.0 - _pulseController.value),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Mascot Container
                      AnimatedScale(
                        scale: _isHovered ? 1.08 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _primaryColor,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _primaryColor.withValues(alpha: 0.45),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Mascot GIF Image with fallback
                              ClipOval(
                                child: Image.network(
                                  _mascotGifUrl,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                    Icons.smart_toy_rounded,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ),

                              // Online Active Indicator Badge
                              Positioned(
                                top: 2,
                                right: 2,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0xFF10B981),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
