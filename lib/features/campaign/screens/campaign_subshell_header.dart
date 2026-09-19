import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme_manager.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/security/role_guard.dart';
import '../bloc/campaign_connections_bloc.dart';
import '../models/campaign_connection_model.dart';

class CampaignSubshellHeader extends StatelessWidget {
  final String activeTab; // 'connections', 'leads', 'housing', 'meta'
  final Widget? trailing;

  const CampaignSubshellHeader({
    super.key,
    required this.activeTab,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final themeManager = ThemeManager();
    final isDark = themeManager.isDarkMode;
    final primaryColor = themeManager.primaryColor;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 1100;
    final isTelecaller = RoleGuard.isTelecaller(RoleGuard.currentUser?.role);
    final title = isTelecaller ? 'My Calling Leads' : 'Campaign & Lead Automation';
    final subtitle = isTelecaller
        ? 'Inbound leads allocated to you · Filter by Property Listing & Requirement'
        : 'Multi-channel marketing automation, webhook integrations & lead pipelines';

    return Container(
      margin: EdgeInsets.only(bottom: isCompact ? CRMSpacing.s : CRMSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Title + Trailing actions
          if (isCompact) ...[
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF14213D),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(height: 12),
              trailing!,
            ],
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                          color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF14213D),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 12),
                  Flexible(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: trailing!,
                    ),
                  ),
                ],
              ],
            ),
          ],

          if (!isTelecaller) ...[
            const SizedBox(height: 16),

            // Dynamic Subshell Tab Switcher
            BlocBuilder<CampaignConnectionsBloc, CampaignConnectionsState>(
              bloc: CampaignConnectionsBloc()..add(const FetchCampaignConnectionsEvent(silent: true)),
              builder: (context, connState) {
                final tabs = _buildDynamicTabs(context, connState.connections);

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: tabs.map((tab) {
                        final isLast = tab == tabs.last;
                        return Padding(
                          padding: EdgeInsets.only(right: isLast ? 0 : 4),
                          child: _buildTabButton(
                            context,
                            title: tab.title,
                            icon: tab.icon,
                            isActive: tab.isActive,
                            isDark: isDark,
                            primaryColor: primaryColor,
                            onTap: tab.onTap,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  List<_TabConfig> _buildDynamicTabs(
    BuildContext context,
    List<CampaignConnectionModel> connections,
  ) {
    final normActive = activeTab.toLowerCase().trim();

    final List<_TabConfig> tabs = [
      _TabConfig(
        id: 'connections',
        title: 'Connections',
        icon: Icons.hub_rounded,
        isActive: normActive == 'connections',
        onTap: () {
          if (normActive != 'connections') {
            context.go('/campaign/connections');
          }
        },
      ),
      _TabConfig(
        id: 'meta',
        title: 'Meta',
        icon: Icons.campaign_rounded,
        isActive: normActive == 'meta' || normActive == 'meta ads',
        onTap: () {
          if (normActive != 'meta' && normActive != 'meta ads') {
            context.go('/campaign/meta');
          }
        },
      ),
      _TabConfig(
        id: 'housing',
        title: 'Housing',
        icon: Icons.apartment_rounded,
        isActive: normActive == 'housing' || normActive == 'housing.com',
        onTap: () {
          if (normActive != 'housing' && normActive != 'housing.com') {
            context.go('/campaign/housing');
          }
        },
      ),
    ];

    // Check for any other dynamic connections configured that aren't Meta or Housing
    for (final conn in connections) {
      final pType = conn.providerType.toUpperCase();
      if (pType != 'HOUSING' && pType != 'META' && conn.isActive) {
        final id = conn.id;
        final title = conn.displayName;
        tabs.add(
          _TabConfig(
            id: id,
            title: title,
            icon: Icons.extension_rounded,
            isActive: normActive == id || normActive == title.toLowerCase(),
            onTap: () {
              context.go('/campaign/leads?source=${Uri.encodeComponent(conn.displayName)}');
            },
          ),
        );
      }
    }

    return tabs;
  }

  Widget _buildTabButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isActive,
    required bool isDark,
    required Color primaryColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
            border: isActive
                ? Border.all(
                    color: primaryColor.withValues(alpha: 0.35),
                    width: 1,
                  )
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive
                    ? primaryColor
                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
              const SizedBox(width: 7),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive
                      ? primaryColor
                      : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabConfig {
  final String id;
  final String title;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  _TabConfig({
    required this.id,
    required this.title,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });
}
