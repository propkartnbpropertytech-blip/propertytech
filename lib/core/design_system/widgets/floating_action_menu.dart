import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  FAB Action item model
// ─────────────────────────────────────────────────────────────────────────────
class FabActionItem {
  final String id;
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const FabActionItem({
    required this.id,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  FloatingActionMenu
// ─────────────────────────────────────────────────────────────────────────────
class FloatingActionMenu extends StatefulWidget {
  final String role;
  final bool isMobile;

  static const String prefKey = 'quick_action_bar_visible';
  static bool isBarVisible = true;
  static final ValueNotifier<bool> barVisibilityNotifier = ValueNotifier<bool>(true);

  static Future<void> initVisibility() async {
    isBarVisible = true;
    barVisibilityNotifier.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(prefKey);
    } catch (_) {}
  }

  static Future<void> setBarVisibility(bool visible) async {
    isBarVisible = visible;
    barVisibilityNotifier.value = visible;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefKey, visible);
    } catch (_) {}
  }

  static Future<void> toggleBarVisibility() async {
    await setBarVisibility(!isBarVisible);
  }

  const FloatingActionMenu({
    super.key,
    required this.role,
    required this.isMobile,
  });

  @override
  State<FloatingActionMenu> createState() => _FloatingActionMenuState();
}

class _FloatingActionMenuState extends State<FloatingActionMenu>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;

  // Vertical position fraction (0.0 = top safe margin, 1.0 = bottom safe margin)
  double _verticalFraction = 0.5;

  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    FloatingActionMenu.initVisibility();
    FloatingActionMenu.barVisibilityNotifier.addListener(_onVisibilityChanged);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 260),
    );

    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      reverseCurve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    FloatingActionMenu.barVisibilityNotifier.removeListener(_onVisibilityChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onVisibilityChanged() {
    if (mounted) {
      if (!FloatingActionMenu.barVisibilityNotifier.value && _isOpen) {
        _isOpen = false;
        _controller.reverse();
      }
      setState(() {});
    }
  }

  void _toggleMenu() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _closeMenu() {
    if (_isOpen) {
      setState(() {
        _isOpen = false;
        _controller.reverse();
      });
    }
  }

  void _handleAction(String actionId) {
    _closeMenu();
    final now = DateTime.now().millisecondsSinceEpoch;
    switch (actionId) {
      case 'add_property':
        context.go('/properties?action=add&t=$now');
        break;
      case 'add_lead':
        context.go('/requirements?action=add&t=$now');
        break;
      case 'add_employee':
        context.go('/users?action=add&t=$now');
        break;
      case 'campaign_connection':
        context.go('/campaign/connections');
        break;
      case 'message':
        context.go('/messages');
        break;
      case 'profile':
        context.go('/profile');
        break;
      case 'recycle_bin':
        context.go('/bin');
        break;
      case 'add_location':
        context.go('/settings/location-config?action=add&t=$now');
        break;
      default:
        break;
    }
  }

  List<FabActionItem> _getActionsForRole() {
    final r = widget.role.trim().toLowerCase();
    final isAdmin = r == 'admin' || r == 'super admin';
    final isTelecaller = r == 'telecaller';
    final isSales = r == 'sales';

    if (isAdmin) {
      return [
        FabActionItem(
          id: 'add_property',
          icon: Icons.add_home_work_rounded,
          label: 'Add Property',
          color: const Color(0xFF10B981), // Emerald
          onTap: () => _handleAction('add_property'),
        ),
        FabActionItem(
          id: 'add_lead',
          icon: Icons.person_add_alt_1_rounded,
          label: 'Add Lead',
          color: const Color(0xFF2563EB), // Blue
          onTap: () => _handleAction('add_lead'),
        ),
        FabActionItem(
          id: 'add_employee',
          icon: Icons.badge_rounded,
          label: 'Add Employee',
          color: const Color(0xFF8B5CF6), // Purple
          onTap: () => _handleAction('add_employee'),
        ),
        FabActionItem(
          id: 'campaign_connection',
          icon: Icons.hub_rounded,
          label: 'Campaign: Connection',
          color: const Color(0xFFF59E0B), // Amber
          onTap: () => _handleAction('campaign_connection'),
        ),
        FabActionItem(
          id: 'message',
          icon: Icons.chat_bubble_outline_rounded,
          label: 'Message',
          color: const Color(0xFF06B6D4), // Cyan
          onTap: () => _handleAction('message'),
        ),
      ];
    } else if (isTelecaller) {
      return [
        FabActionItem(
          id: 'add_property',
          icon: Icons.add_home_work_rounded,
          label: 'Add Property',
          color: const Color(0xFF10B981), // Emerald
          onTap: () => _handleAction('add_property'),
        ),
        FabActionItem(
          id: 'add_lead',
          icon: Icons.person_add_alt_1_rounded,
          label: 'Add Lead',
          color: const Color(0xFF2563EB), // Blue
          onTap: () => _handleAction('add_lead'),
        ),
        FabActionItem(
          id: 'profile',
          icon: Icons.person_outline_rounded,
          label: 'Profile',
          color: const Color(0xFF6366F1), // Indigo
          onTap: () => _handleAction('profile'),
        ),
        FabActionItem(
          id: 'message',
          icon: Icons.chat_bubble_outline_rounded,
          label: 'Message',
          color: const Color(0xFF06B6D4), // Cyan
          onTap: () => _handleAction('message'),
        ),
        FabActionItem(
          id: 'recycle_bin',
          icon: Icons.delete_outline_rounded,
          label: 'Recycle Bin',
          color: const Color(0xFFEF4444), // Red
          onTap: () => _handleAction('recycle_bin'),
        ),
      ];
    } else if (isSales) {
      return [
        FabActionItem(
          id: 'profile',
          icon: Icons.person_outline_rounded,
          label: 'Profile',
          color: const Color(0xFF6366F1), // Indigo
          onTap: () => _handleAction('profile'),
        ),
        FabActionItem(
          id: 'message',
          icon: Icons.chat_bubble_outline_rounded,
          label: 'Message',
          color: const Color(0xFF06B6D4), // Cyan
          onTap: () => _handleAction('message'),
        ),
        FabActionItem(
          id: 'recycle_bin',
          icon: Icons.delete_outline_rounded,
          label: 'Recycle Bin',
          color: const Color(0xFFEF4444), // Red
          onTap: () => _handleAction('recycle_bin'),
        ),
        FabActionItem(
          id: 'add_location',
          icon: Icons.add_location_alt_rounded,
          label: 'Settings: Add Location',
          color: const Color(0xFFF97316), // Orange
          onTap: () => _handleAction('add_location'),
        ),
      ];
    }

    // Default fallback
    return [
      FabActionItem(
        id: 'add_property',
        icon: Icons.add_home_work_rounded,
        label: 'Add Property',
        color: const Color(0xFF10B981),
        onTap: () => _handleAction('add_property'),
      ),
      FabActionItem(
        id: 'add_lead',
        icon: Icons.person_add_alt_1_rounded,
        label: 'Add Lead',
        color: const Color(0xFF2563EB),
        onTap: () => _handleAction('add_lead'),
      ),
      FabActionItem(
        id: 'message',
        icon: Icons.chat_bubble_outline_rounded,
        label: 'Message',
        color: const Color(0xFF06B6D4),
        onTap: () => _handleAction('message'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: FloatingActionMenu.barVisibilityNotifier,
      builder: (context, isVisible, _) {
        final size = MediaQuery.of(context).size;
        final isMobile = widget.isMobile;
        final actions = _getActionsForRole();

        // Dimensions
        final double toggleWidth = _isOpen ? 44.0 : 26.0;
        final double toggleHeight = _isOpen ? 44.0 : 54.0;
        final double actionSize = isMobile ? 46.0 : 48.0;
        final double fanRadius = isMobile ? 95.0 : 110.0;

        // Vertical positioning
        final double minY = isMobile ? 70.0 : 100.0;
        final double maxY = size.height - (isMobile ? 120.0 : 80.0) - toggleHeight;
        final double rangeY = (maxY - minY).clamp(1.0, double.infinity);
        final double toggleY = (minY + (_verticalFraction * rangeY)).clamp(minY, maxY);

        // Both mobile and laptop: right edge of screen
        final double anchorX = size.width - (_isOpen ? 36.0 : 13.0);
        final double anchorY = toggleY + toggleHeight / 2;

        // Base angle pi: fan radiates leftward into the screen on both mobile and laptop
        const double baseAngle = math.pi;
        final double totalArc = (actions.length <= 1)
            ? 0.0
            : (actions.length <= 4 ? (math.pi * 0.65) : (math.pi * 0.78));

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // ── 1. Dimmed Background Overlay ─────────────────────────
            if (_isOpen || _controller.value > 0)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    final opacity = (_fadeAnimation.value * 0.5).clamp(0.0, 0.5);
                    return IgnorePointer(
                      ignoring: !_isOpen && _controller.value == 0,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _closeMenu,
                        child: Container(
                          color: Colors.black.withValues(alpha: opacity),
                        ),
                      ),
                    );
                  },
                ),
              ),

            // ── 2. Fan Action Buttons ────────────────────────────────
            if (_isOpen || _controller.value > 0)
              ...List.generate(actions.length, (index) {
                final action = actions[index];
                final double angleOffset = actions.length <= 1
                    ? 0.0
                    : -totalArc / 2 + (totalArc / (actions.length - 1)) * index;
                final double angle = baseAngle + angleOffset;

                final double targetDx = math.cos(angle) * fanRadius;
                final double targetDy = math.sin(angle) * fanRadius;

                return AnimatedBuilder(
                  animation: _expandAnimation,
                  builder: (context, child) {
                    final t = _expandAnimation.value;
                    if (t <= 0.001) return const SizedBox.shrink();

                    final currentX = anchorX + (targetDx * t);
                    final currentY = anchorY + (targetDy * t);

                    final scale = t.clamp(0.0, 1.0);
                    final opacity = (_fadeAnimation.value).clamp(0.0, 1.0);

                    return Positioned(
                      left: currentX - actionSize / 2,
                      top: currentY - actionSize / 2,
                      child: Opacity(
                        opacity: opacity,
                        child: Transform.scale(
                          scale: scale,
                          child: Tooltip(
                            message: action.label,
                            preferBelow: false,
                            verticalOffset: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            textStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: action.onTap,
                                borderRadius: BorderRadius.circular(actionSize / 2),
                                child: Container(
                                  width: actionSize,
                                  height: actionSize,
                                  decoration: BoxDecoration(
                                    color: action.color,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: action.color.withValues(alpha: 0.42),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.18),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Icon(
                                      action.icon,
                                      color: Colors.white,
                                      size: isMobile ? 21 : 23,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),

            // ── 3. Arrow Toggle / Close Button on Edge ───────────────
            Positioned(
              right: _isOpen ? 14.0 : 0.0,
              top: toggleY,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  Widget toggleContent = Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _toggleMenu,
                      borderRadius: _isOpen
                          ? BorderRadius.circular(22)
                          : const BorderRadius.horizontal(left: Radius.circular(16)),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: toggleWidth,
                        height: toggleHeight,
                        decoration: BoxDecoration(
                          color: _isOpen
                              ? const Color(0xFFEF4444) // Crisp red close button when open
                              : const Color(0xFF0F172A), // Sleek obsidian slate tab
                          borderRadius: _isOpen
                              ? BorderRadius.circular(22)
                              : const BorderRadius.horizontal(left: Radius.circular(16)),
                          border: Border.all(
                            color: _isOpen
                                ? Colors.white.withValues(alpha: 0.3)
                                : const Color(0xFF334155),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _isOpen
                                  ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                                  : Colors.black.withValues(alpha: 0.28),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: RotationTransition(
                            turns: _rotationAnimation,
                            child: _isOpen
                                ? const Icon(
                                    Icons.close_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  )
                                : const Icon(
                                    Icons.arrow_back_ios_rounded,
                                    color: Color(0xFFE2E8F0),
                                    size: 13,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  );

                  // If mobile, wrap in vertical drag gesture detector so user can move it anywhere along borders
                  if (isMobile && !_isOpen) {
                    toggleContent = GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onVerticalDragUpdate: (details) {
                        setState(() {
                          final delta = details.delta.dy / rangeY;
                          _verticalFraction = (_verticalFraction + delta).clamp(0.0, 1.0);
                        });
                      },
                      child: toggleContent,
                    );
                  }

                  return toggleContent;
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
