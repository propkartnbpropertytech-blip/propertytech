import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/theme_manager.dart';

class WelcomeHeader extends StatelessWidget {
  final String userName;
  final String? dateText;

  const WelcomeHeader({super.key, required this.userName, this.dateText});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning, 👋';
    if (hour < 17) return 'Good Afternoon, 👋';
    return 'Good Evening, 👋';
  }

  String _getFormattedDate() {
    if (dateText != null && dateText!.isNotEmpty) return dateText!;
    return DateFormat('d MMMM y, EEEE').format(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final isMobile = MediaQuery.of(context).size.width < 768;
    final greeting = _getGreeting();
    final dateString = _getFormattedDate();
    final displayName = userName.isNotEmpty ? userName : 'User';

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF68738A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            displayName,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF14213D),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Here's what's happening with your business today.",
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF68738A),
            ),
          ),
          const SizedBox(height: 12),
          _buildDateCard(dateString, isDark),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              greeting,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF68738A),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              displayName,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF14213D),
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Here's what's happening with your business today.",
              style: TextStyle(
                fontSize: 13.5,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF68738A),
              ),
            ),
          ],
        ),
        _buildDateCard(dateString, isDark),
      ],
    );
  }

  Widget _buildDateCard(String dateString, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE8ECF2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 16,
            color: ThemeManager().primaryColor,
          ),
          const SizedBox(width: 8),
          Text(
            dateString,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF14213D),
            ),
          ),
        ],
      ),
    );
  }
}
