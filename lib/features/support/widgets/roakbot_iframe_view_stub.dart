import 'package:flutter/material.dart';
import '../../../core/services/roakbot/roakbot_service.dart';

class RoakbotIframePlatformImpl extends StatelessWidget {
  final double width;
  final double height;

  const RoakbotIframePlatformImpl({
    super.key,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 24),
          Text(
            'Roakbot Chatbot',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Your chatbot is ready to help you navigate property listings, client requirements, and software workflows.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => RoakbotService.open(),
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
            label: const Text('Start Chatting'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }
}
