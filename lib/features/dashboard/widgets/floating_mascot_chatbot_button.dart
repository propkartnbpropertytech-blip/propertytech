import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../support/widgets/roakbot_dialog.dart';
import '../../../core/services/roakbot/roakbot_service.dart';

class FloatingMascotChatbotButton extends StatefulWidget {
  const FloatingMascotChatbotButton({super.key});

  @override
  State<FloatingMascotChatbotButton> createState() =>
      FloatingMascotChatbotButtonState();
}

class FloatingMascotChatbotButtonState
    extends State<FloatingMascotChatbotButton>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const String _mascotGifUrl =
      'https://res.cloudinary.com/haacwr5z/image/upload/v1792041589/roakbot/k4t0dfawrgayape2ztkr.gif';
  static const Color _primaryColor = Color(0xFF0F172A);

  AnimationController? _bobbingController;
  Animation<double>? _bobbingAnimation;

  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;

  Timer? _idleSettleTimer;
  bool _isHovered = false;
  bool _showSpeechBubble = true;
  bool _isIdled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // On Web, the native Roakbot script handles the mascot. Do not initialize or spin tickers.
    if (!kIsWeb) {
      _initAnimationControllers();
      _startAnimating();
      _scheduleIdleSettling(const Duration(seconds: 5));
    }
  }

  void _initAnimationControllers() {
    // 1. Smooth up/down floating bobbing motion
    _bobbingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _bobbingAnimation = Tween<double>(begin: 0, end: -7).animate(
      CurvedAnimation(
        parent: _bobbingController!,
        curve: Curves.easeInOutSine,
      ),
    );

    // 2. Subtle pulse halo glow ring
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _pulseController!,
        curve: Curves.easeOut,
      ),
    );
  }

  void _startAnimating() {
    if (_bobbingController == null || _pulseController == null) return;
    if (!_bobbingController!.isAnimating) {
      _bobbingController!.repeat(reverse: true);
    }
    if (!_pulseController!.isAnimating) {
      _pulseController!.repeat();
    }
    _isIdled = false;
  }

  void _scheduleIdleSettling(Duration delay) {
    _idleSettleTimer?.cancel();
    _idleSettleTimer = Timer(delay, () {
      if (!mounted) return;
      _settleToIdle();
    });
  }

  void _settleToIdle() {
    _idleSettleTimer?.cancel();
    _idleSettleTimer = null;
    if (_bobbingController != null && _bobbingController!.isAnimating) {
      _bobbingController!.animateTo(0.0, duration: const Duration(milliseconds: 400));
    }
    if (_pulseController != null && _pulseController!.isAnimating) {
      _pulseController!.animateTo(0.0, duration: const Duration(milliseconds: 300));
    }
    _isIdled = true;
  }

  void _wakeUpAndAnimate() {
    if (kIsWeb) return;
    _startAnimating();
    _scheduleIdleSettling(const Duration(seconds: 4));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _settleToIdle();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _idleSettleTimer?.cancel();
    _bobbingController?.dispose();
    _pulseController?.dispose();
    super.dispose();
  }

  void _onChatbotTap() {
    _wakeUpAndAnimate();
    if (kIsWeb) {
      RoakbotService.open();
    }
    RoakbotDialog.show(context);
  }

  @visibleForTesting
  bool get isBobbingAnimating => _bobbingController?.isAnimating ?? false;

  @visibleForTesting
  bool get isPulseAnimating => _pulseController?.isAnimating ?? false;

  @visibleForTesting
  bool get isIdled => _isIdled;

  @visibleForTesting
  void triggerWakeUpForTesting() => _wakeUpAndAnimate();

  @visibleForTesting
  void triggerSettleForTesting() => _settleToIdle();

  @override
  Widget build(BuildContext context) {
    // On Web, the native Roakbot dynamic widget script from index.html automatically
    // renders the floating mascot widget and invitation bubble with live auto-sync.
    if (kIsWeb || _bobbingController == null || _pulseController == null) {
      return const SizedBox.shrink();
    }

    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      if (!_isIdled) {
        _settleToIdle();
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final launcherW = isMobile ? 120.0 : 180.0;
    final launcherH = isMobile ? 120.0 : 108.0;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_bobbingAnimation!, _pulseAnimation!]),
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _bobbingAnimation!.value),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Playful Speech Bubble on Top
                if (_showSpeechBubble) ...[
                  GestureDetector(
                  onTap: _onChatbotTap,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
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
                onEnter: (_) {
                  setState(() => _isHovered = true);
                  _wakeUpAndAnimate();
                },
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
                        scale: _pulseAnimation!.value,
                        child: Container(
                          width: launcherW,
                          height: launcherH,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: _primaryColor.withValues(
                              alpha: math.max(
                                0.0,
                                0.25 * (1.0 - (_pulseController?.value ?? 0.0)),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Mascot Container
                      AnimatedScale(
                        scale: _isHovered ? 1.05 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        child: Container(
                          width: launcherW,
                          height: launcherH,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
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
                              // Mascot GIF Image with cover fit and fallback
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(
                                  _mascotGifUrl,
                                  width: launcherW,
                                  height: launcherH,
                                  fit: BoxFit.cover,
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
                                top: 4,
                                right: 4,
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
    ),
  );
}
}
