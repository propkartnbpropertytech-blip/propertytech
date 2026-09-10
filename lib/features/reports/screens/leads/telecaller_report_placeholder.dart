import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/tokens/app_colors.dart';
import '../../../../core/theme/theme_manager.dart';

class TelecallerReportPlaceholderScreen extends StatelessWidget {
  const TelecallerReportPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final primaryColor = CRMColors.primary;

    return Scaffold(
      backgroundColor: CRMColors.backgroundOf(context),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF64748B).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.headset_mic_rounded,
                  size: 48,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Telecaller Performance Report',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Detailed telecaller activity, call recordings, connectivity benchmarks, and disposition metrics are scheduled for Stage 2.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => context.go('/reports/leads/overall-business-insight'),
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text('Back to Overall Business Insight'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
