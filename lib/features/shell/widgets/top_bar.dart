import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme_manager.dart';
import '../../../core/theme/theme_presets.dart';
import '../../auth/bloc/auth_bloc.dart';

class ModernTopBar extends StatefulWidget {
  final VoidCallback onToggleSidebar;
  final VoidCallback? onQuickAdd;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onLogout;
  final int unreadNotifications;
  final int unreadMessages;
  final String userName;
  final String userRole;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final ValueChanged<String>? onSearchSubmitted;

  const ModernTopBar({
    super.key,
    required this.onToggleSidebar,
    this.onQuickAdd,
    this.onNotificationsTap,
    this.onLogout,
    this.unreadNotifications = 0,
    this.unreadMessages = 0,
    this.userName = 'Super Administrator',
    this.userRole = 'Super Admin',
    this.searchController,
    this.onSearchChanged,
    this.onSearchSubmitted,
  });

  @override
  State<ModernTopBar> createState() => _ModernTopBarState();
}

class _ModernTopBarState extends State<ModernTopBar> {
  bool _isSearchExpanded = false;

  void _showSetDefaultThemeDialog(BuildContext context) {
    final themeManager = ThemeManager();
    final isDark = themeManager.isDarkMode;
    final primaryColor = themeManager.primaryColor;
    String selectedThemeId = themeManager.systemDefaultThemeId;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE8ECF2),
                ),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.palette_outlined,
                      color: primaryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Set System Default Theme',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF14213D),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Select the default theme for all visitors & users',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF68738A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final theme in themeManager.availableThemes) ...[
                      InkWell(
                        onTap: () {
                          setDialogState(() {
                            selectedThemeId = theme.id;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: selectedThemeId == theme.id
                                ? primaryColor.withValues(alpha: isDark ? 0.15 : 0.08)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selectedThemeId == theme.id
                                  ? primaryColor
                                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE8ECF2)),
                              width: selectedThemeId == theme.id ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Radio<String>(
                                value: theme.id,
                                groupValue: selectedThemeId,
                                activeColor: primaryColor,
                                onChanged: (val) {
                                  if (val != null) {
                                    setDialogState(() => selectedThemeId = val);
                                  }
                                },
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          theme.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13.5,
                                            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF14213D),
                                          ),
                                        ),
                                        if (themeManager.isSystemDefault(theme.id)) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF159B73).withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'CURRENT DEFAULT',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF159B73),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      theme.description,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF68738A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Row(
                                children: [
                                  for (int i = 0; i < theme.previewColors.length.clamp(0, 4); i++)
                                    Container(
                                      width: 14,
                                      height: 14,
                                      margin: const EdgeInsets.only(left: 3),
                                      decoration: BoxDecoration(
                                        color: theme.previewColors[i],
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF68738A),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    await themeManager.setSystemDefaultTheme(selectedThemeId);
                    if (dialogCtx.mounted) {
                      Navigator.of(dialogCtx).pop();
                    }
                    if (context.mounted) {
                      final selectedPreset = AppThemePresets.getById(selectedThemeId);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Theme "${selectedPreset.name}" is now set as the system default!'),
                          backgroundColor: const Color(0xFF159B73),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.star_rounded, size: 16),
                  label: const Text(
                    'Make it as Default',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showUserDropdown(BuildContext buttonContext) {
    final themeManager = ThemeManager();
    final isDark = themeManager.isDarkMode;
    final primaryColor = themeManager.primaryColor;
    final renderBox = buttonContext.findRenderObject() as RenderBox?;
    final offset = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    final size = renderBox?.size ?? Size.zero;

    final router = GoRouter.of(buttonContext);
    final authBloc = buttonContext.read<AuthBloc>();
    final isSuperAdmin = widget.userRole.toLowerCase().contains('admin');

    showMenu<void>(
      context: buttonContext,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + size.height + 8,
        offset.dx + size.width,
        0,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE8ECF2),
          width: 1,
        ),
      ),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      elevation: 8,
      items: <PopupMenuEntry<void>>[
        // 1. User Header Details
        PopupMenuItem<void>(
          enabled: false,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: primaryColor.withValues(alpha: 0.15),
                child: Text(
                  widget.userName.isNotEmpty
                      ? widget.userName
                          .trim()
                          .split(' ')
                          .map((e) => e.isNotEmpty ? e[0] : '')
                          .take(2)
                          .join()
                          .toUpperCase()
                      : 'SA',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.userName.isNotEmpty ? widget.userName : 'Super Administrator',
                    style: TextStyle(
                      color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF14213D),
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.userRole.isNotEmpty ? widget.userRole : 'Super Admin',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),

        // 2. Default Theme Selector (Super Admin Provision)
        if (isSuperAdmin) ...[
          PopupMenuItem<void>(
            onTap: () {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showSetDefaultThemeDialog(buttonContext);
              });
            },
            child: Row(
              children: [
                Icon(Icons.palette_outlined, size: 18, color: primaryColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Set Default Theme',
                        style: TextStyle(
                          color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF14213D),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        themeManager.defaultTheme.name,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF68738A),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'DEFAULT',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const PopupMenuDivider(height: 1),
        ],

        // 3. Quick Dark Mode Switch
        PopupMenuItem<void>(
          onTap: () {
            ThemeManager().toggleTheme();
          },
          child: Row(
            children: [
              Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                size: 18,
                color: isDark ? const Color(0xFFF59E0B) : const Color(0xFF68738A),
              ),
              const SizedBox(width: 10),
              Text(
                isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                style: TextStyle(
                  color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF14213D),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),

        // 4. Settings option
        PopupMenuItem<void>(
          onTap: () {
            router.go('/settings');
          },
          child: Row(
            children: [
              Icon(
                Icons.settings_outlined,
                size: 18,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF68738A),
              ),
              const SizedBox(width: 10),
              Text(
                'Settings',
                style: TextStyle(
                  color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF14213D),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),

        const PopupMenuDivider(height: 1),

        // 5. Slide-down Logout Button
        PopupMenuItem<void>(
          onTap: () {
            if (widget.onLogout != null) {
              widget.onLogout!();
            } else {
              authBloc.add(LogoutRequested());
            }
          },
          child: const Row(
            children: [
              Icon(
                Icons.logout_rounded,
                size: 18,
                color: Color(0xFFE11D48),
              ),
              SizedBox(width: 10),
              Text(
                'Logout',
                style: TextStyle(
                  color: Color(0xFFE11D48),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = ThemeManager();
    final isDark = themeManager.isDarkMode;
    final primaryColor = themeManager.primaryColor;
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 768;
    final bool isSmallMobile = screenWidth < 600;
    final bool isTablet = screenWidth >= 768 && screenWidth < 1024;

    final initials = widget.userName.isNotEmpty
        ? widget.userName
            .trim()
            .split(' ')
            .map((e) => e.isNotEmpty ? e[0] : '')
            .take(2)
            .join()
            .toUpperCase()
        : 'SA';

    // Collapsed or expanded search view on small mobile screens
    if (isSmallMobile && _isSearchExpanded) {
      return Container(
        height: 62,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          border: Border(
            bottom: BorderSide(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE8ECF2),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.arrow_back_rounded,
                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF14213D),
                size: 22,
              ),
              onPressed: () {
                setState(() => _isSearchExpanded = false);
              },
            ),
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F4F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : Colors.transparent,
                  ),
                ),
                child: TextField(
                  autofocus: true,
                  controller: widget.searchController,
                  onChanged: widget.onSearchChanged,
                  onSubmitted: widget.onSearchSubmitted,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF14213D),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search properties, leads, or locations...',
                    hintStyle: TextStyle(
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      fontSize: 13,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF68738A),
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    isDense: true,
                  ),
                ),
              ),
            ),
            if (widget.searchController != null && widget.searchController!.text.isNotEmpty)
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF68738A),
                  size: 20,
                ),
                onPressed: () {
                  widget.searchController?.clear();
                  widget.onSearchChanged?.call('');
                },
              ),
          ],
        ),
      );
    }

    return Container(
      height: isMobile ? 62 : 74,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE8ECF2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // ── Sidebar Toggle ─────────────────────────────────
          IconButton(
            onPressed: widget.onToggleSidebar,
            icon: Icon(
              Icons.menu_rounded,
              color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF14213D),
              size: 24,
            ),
            tooltip: 'Toggle Menu',
            splashRadius: 22,
          ),
          const SizedBox(width: 6),

          // Brand name on mobile when search is collapsed
          if (isSmallMobile) ...[
            Text(
              'PropKart',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: primaryColor,
                letterSpacing: -0.3,
              ),
            ),
            const Spacer(),
            // Search icon button to expand search
            IconButton(
              icon: Icon(
                Icons.search_rounded,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF68738A),
                size: 22,
              ),
              onPressed: () {
                setState(() => _isSearchExpanded = true);
              },
              tooltip: 'Search',
            ),
          ] else ...[
            // ── Search Bar on Tablet/Desktop ─────────────────────
            Expanded(
              child: Container(
                height: 42,
                constraints: const BoxConstraints(maxWidth: 420),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F4F9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : Colors.transparent,
                  ),
                ),
                child: TextField(
                  controller: widget.searchController,
                  onChanged: widget.onSearchChanged,
                  onSubmitted: widget.onSearchSubmitted,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF14213D),
                  ),
                  decoration: InputDecoration(
                    hintText: isMobile ? 'Search...' : 'Search properties, leads, or locations...',
                    hintStyle: TextStyle(
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      fontSize: 13,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF68738A),
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
                    isDense: true,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],

          // ── Right Side Actions ─────────────────────────────
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Circular Quick Add "+" Action Button with dynamic primaryColor
              Container(
                width: isMobile ? 34 : 38,
                height: isMobile ? 34 : 38,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: widget.onQuickAdd ?? () => _showQuickAddModal(context),
                  tooltip: 'Quick Add',
                ),
              ),

              SizedBox(width: isMobile ? 6 : 12),

              // Notifications with Badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: widget.onNotificationsTap ??
                        () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Notifications panel'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                    icon: Icon(
                      Icons.notifications_none_rounded,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF68738A),
                      size: 22,
                    ),
                    tooltip: 'Notifications',
                    splashRadius: 20,
                  ),
                  if (widget.unreadNotifications > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE11D48),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 8,
                          minHeight: 8,
                        ),
                      ),
                    ),
                ],
              ),

              if (!isMobile) ...[
                // Messages with Badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      onPressed: () {
                        context.go('/requirements');
                      },
                      icon: Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF68738A),
                        size: 20,
                      ),
                      tooltip: 'Messages',
                      splashRadius: 20,
                    ),
                    if (widget.unreadMessages > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFF3B82F6),
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 8,
                            minHeight: 8,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 8),
              ],

              // Divider before Profile
              if (!isMobile)
                Container(
                  height: 28,
                  width: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE8ECF2),
                ),

              // Super Admin Profile Toggle (Slides down logout menu)
              Builder(
                builder: (buttonContext) => InkWell(
                  onTap: () => _showUserDropdown(buttonContext),
                  borderRadius: BorderRadius.circular(20),
                  hoverColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F4F9),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 17,
                          backgroundColor: primaryColor.withValues(alpha: 0.15),
                          child: Text(
                            initials,
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (!isMobile && !isTablet) ...[
                          const SizedBox(width: 8),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.userName.isNotEmpty ? widget.userName : 'Super Administrator',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF14213D),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                widget.userRole.isNotEmpty ? widget.userRole : 'Super Admin',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF68738A),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF68738A),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showQuickAddModal(BuildContext context) {
    final themeManager = ThemeManager();
    final isDark = themeManager.isDarkMode;
    final primaryColor = themeManager.primaryColor;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF14213D),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF68738A),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.add_home_work_rounded,
                    color: primaryColor,
                  ),
                ),
                title: Text(
                  'Add New Property',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF14213D),
                  ),
                ),
                subtitle: Text(
                  'Create a rental or re-sale listing',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF68738A),
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  context.go('/properties');
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person_add_rounded,
                    color: Color(0xFF3B82F6),
                  ),
                ),
                title: Text(
                  'Add New Lead / Requirement',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF14213D),
                  ),
                ),
                subtitle: Text(
                  'Capture customer demand details',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF68738A),
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  context.go('/requirements');
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: Color(0xFF8B5CF6),
                  ),
                ),
                title: Text(
                  'Schedule Site Visit',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF14213D),
                  ),
                ),
                subtitle: Text(
                  'Book client inspection appointment',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF68738A),
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  context.go('/dashboard');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

