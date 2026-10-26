import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
    with SingleTickerProviderStateMixin {
  static const String _mascotImageUrl =
      'https://res.cloudinary.com/haacwr5z/image/upload/v1792669555/roakbot/mxxjezvxruhfpemry05k.png';

  late final AnimationController _bobbingController;
  late final Animation<double> _bobbingAnimation;

  bool _showSpeechBubble = true;

  @override
  void initState() {
    super.initState();
    _bobbingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _bobbingAnimation = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(
        parent: _bobbingController,
        curve: Curves.easeInOutSine,
      ),
    );
  }

  @override
  void dispose() {
    _bobbingController.dispose();
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
    // On Web desktop/browsers, index.html's native Roakbot script handles the mascot.
    if (kIsWeb) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _bobbingAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bobbingAnimation.value),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Speech bubble invitation
              if (_showSpeechBubble)
                GestureDetector(
                  onTap: _onChatbotTap,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 4, right: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '👋 Need assistance? Tap to chat!',
                          style: TextStyle(
                            fontSize: 11.5,
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
                            size: 13,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Waving Mascot Penguin Image
              GestureDetector(
                onTap: _onChatbotTap,
                child: SizedBox(
                  width: 76,
                  height: 92,
                  child: Image.network(
                    _mascotImageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0F172A),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.smart_toy_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
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
