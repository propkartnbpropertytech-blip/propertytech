import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/theme_manager.dart';

class UserProfileCard extends StatelessWidget {
  final String name;
  final String email;
  final String? avatarUrl;
  final VoidCallback? onTap;
  final bool isCollapsed;

  const UserProfileCard({
    super.key,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.onTap,
    this.isCollapsed = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final initials = name.isNotEmpty
        ? name
              .trim()
              .split(' ')
              .map((e) => e.isNotEmpty ? e[0] : '')
              .take(2)
              .join()
              .toUpperCase()
        : 'PK';

    if (isCollapsed) {
      return Tooltip(
        message: name.isNotEmpty ? name : 'User',
        child: InkWell(
          onTap: onTap ?? () => context.go('/profile'),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: CircleAvatar(
                radius: 18,
                backgroundColor: ThemeManager().primaryColor.withValues(alpha: 0.15),
                child: Text(
                  initials,
                  style: TextStyle(
                    color: ThemeManager().primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return InkWell(
      onTap: onTap ?? () => context.go('/profile'),
      borderRadius: BorderRadius.circular(12),
      hoverColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F4F9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: ThemeManager().primaryColor.withValues(alpha: 0.15),
              child: Text(
                initials,
                style: TextStyle(
                  color: ThemeManager().primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name.isNotEmpty ? name : 'User',
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFFF8FAFC)
                          : const Color(0xFF14213D),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      email,
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF68738A),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: isDark
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF68738A),
            ),
          ],
        ),
      ),
    );
  }
}
