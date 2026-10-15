import 'package:flutter/material.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/widgets/cards.dart';
import '../../../core/theme/theme_manager.dart';
import '../services/page_control_service.dart';

/// Clean and simplified Page Control interface for Super Admin.
/// Displays three separate tabs (Admin, Telecaller, Sales Person) with all sidebar pages
/// in a simple list with page name on the left and Under Development toggle on the right.
class PageControlSettingsCard extends StatefulWidget {
  const PageControlSettingsCard({super.key});

  @override
  State<PageControlSettingsCard> createState() => _PageControlSettingsCardState();
}

class _PageControlSettingsCardState extends State<PageControlSettingsCard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _roles = const ['Admin', 'Telecaller', 'Sales Person'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _roles.length, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    PageControlService.instance.addListener(_onServiceChanged);
    PageControlService.instance.fetchControls(silent: true);
  }

  void _onServiceChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    PageControlService.instance.removeListener(_onServiceChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final primary = CRMColors.primary;
    final service = PageControlService.instance;
    final activeRole = _roles[_tabController.index];
    final rolePages = service.getControlsForRole(activeRole);

    return CRMCard(
      title: 'Page Control',
      subtitle: 'Manage Under Development maintenance mode for each role\'s sidebar pages.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: CRMSpacing.m),

          // ── Three Role Tabs: Admin, Telecaller, Sales Person ──────
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(4),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              labelColor: primary,
              unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: _roles.map((role) => Tab(text: role)).toList(),
            ),
          ),
          const SizedBox(height: CRMSpacing.l),

          // ── Simple List of Sidebar Pages for the Selected Role ───
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: rolePages.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                thickness: 1,
                color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
              ),
              itemBuilder: (context, index) {
                final page = rolePages[index];
                final isUnderDev = page.isUnderDevForRole(activeRole);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Left: Page icon
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isUnderDev
                              ? const Color(0xFFF59E0B).withValues(alpha: 0.12)
                              : primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          page.iconData,
                          size: 20,
                          color: isUnderDev ? const Color(0xFFD97706) : primary,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Left: Page name & optional Under Development badge
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                page.title,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isUnderDev) ...[
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                                    width: 0.8,
                                  ),
                                ),
                                child: const Text(
                                  'Under Development',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFD97706),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Right: Under Development Toggle
                      Switch.adaptive(
                        value: isUnderDev,
                        activeThumbColor: const Color(0xFFF59E0B),
                        activeTrackColor: const Color(0xFFF59E0B).withValues(alpha: 0.45),
                        onChanged: (newVal) async {
                          final success = await PageControlService.instance.toggleUnderDevelopment(
                            page.pageKey,
                            newVal,
                            role: activeRole,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            if (success) {
                              final status = newVal ? 'marked as Under Development for $activeRole' : 'restored to Live for $activeRole';
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('"${page.title}" $status.'),
                                  backgroundColor: newVal ? const Color(0xFFD97706) : const Color(0xFF059669),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Could not update "${page.title}". Please try again.'),
                                  backgroundColor: const Color(0xFFDC2626),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: CRMSpacing.m),
        ],
      ),
    );
  }
}
