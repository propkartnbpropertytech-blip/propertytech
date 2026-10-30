import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/mobile/mobile.dart';
import '../../../core/design_system/tokens/app_breakpoints.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../bloc/super_admin_dashboard_bloc.dart';
import '../models/super_admin_platform_overview.dart';
import '../repository/super_admin_dashboard_repository.dart';
import '../widgets/stat_card.dart';

class SuperAdminDashboardScreen extends StatelessWidget {
  final SuperAdminDashboardBloc? bloc;
  final SuperAdminDashboardRepository? repository;
  const SuperAdminDashboardScreen({super.key, this.bloc, this.repository});

  @override
  Widget build(BuildContext context) {
    final existing = bloc ?? _lookupBloc(context);
    if (existing != null) {
      return BlocProvider<SuperAdminDashboardBloc>.value(
        value: existing,
        child: const _SuperAdminDashboardView(),
      );
    }
    return BlocProvider(
      create: (_) => SuperAdminDashboardBloc(
        repository: repository ?? SuperAdminDashboardRepository(),
      )..add(const LoadSuperAdminDashboard()),
      child: const _SuperAdminDashboardView(),
    );
  }

  SuperAdminDashboardBloc? _lookupBloc(BuildContext context) {
    try {
      return BlocProvider.of<SuperAdminDashboardBloc>(context, listen: false);
    } catch (_) {
      return null;
    }
  }
}

class _SuperAdminDashboardView extends StatelessWidget {
  const _SuperAdminDashboardView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SuperAdminDashboardBloc, SuperAdminDashboardState>(
      builder: (context, state) {
        final isMobile = MobileLayout.isMobileShell(MediaQuery.sizeOf(context).width);
        if (state is SuperAdminDashboardLoading || state is SuperAdminDashboardInitial) {
          if (isMobile) {
            return const MobileScreenScaffold(
              key: Key('super-admin-dashboard-mobile'),
              scrollable: false,
              body: MobileLoadingState(),
            );
          }
          return const Center(
            key: Key('super-admin-dashboard-desktop'),
            child: CircularProgressIndicator(),
          );
        }
        if (state is SuperAdminDashboardError) {
          void retry() {
            context.read<SuperAdminDashboardBloc>().add(const LoadSuperAdminDashboard());
          }
          if (isMobile) {
            return MobileScreenScaffold(
              key: const Key('super-admin-dashboard-mobile'),
              scrollable: false,
              body: MobileErrorState(
                title: 'Failed to load platform overview',
                message: state.message,
                onRetry: retry,
              ),
            );
          }
          return Center(
            key: const Key('super-admin-dashboard-desktop'),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(state.message),
                const SizedBox(height: CRMSpacing.s),
                TextButton(onPressed: retry, child: const Text('Retry')),
              ],
            ),
          );
        }
        final loaded = state as SuperAdminDashboardLoaded;
        final body = _OverviewBody(state: loaded);
        if (isMobile) {
          return MobileScreenScaffold(
            key: const Key('super-admin-dashboard-mobile'),
            onRefresh: () async {
              context.read<SuperAdminDashboardBloc>().add(const RefreshSuperAdminDashboard());
            },
            body: body,
          );
        }
        return RefreshIndicator(
          key: const Key('super-admin-dashboard-desktop'),
          onRefresh: () async {
            context.read<SuperAdminDashboardBloc>().add(const RefreshSuperAdminDashboard());
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: CRMBreakpoints.pagePadding(context),
              vertical: CRMSpacing.l,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: CRMBreakpoints.maxContentWidth),
                child: body,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OverviewBody extends StatelessWidget {
  final SuperAdminDashboardLoaded state;

  const _OverviewBody({required this.state});

  @override
  Widget build(BuildContext context) {
    final overview = state.overview;
    final summary = overview.summary;
    final isMobile = MobileLayout.isMobileShell(MediaQuery.sizeOf(context).width);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Platform overview',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: CRMColors.text,
              ),
        ),
        const SizedBox(height: CRMSpacing.xs),
        Text(
          'Signed in as Super Admin. Workspace views are read-only and do not change your session.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: CRMColors.textSecondary),
        ),
        const SizedBox(height: CRMSpacing.m),
        LayoutBuilder(
          builder: (context, constraints) {
            return _SummaryGrid(
              maxWidth: constraints.maxWidth,
              cards: [
                _metric(
                  'Workspaces',
                  '${summary.organizationCount}',
                  'Admin ${summary.adminWorkspaceCount} · Broker ${summary.brokerWorkspaceCount} · Other ${summary.otherWorkspaceCount}',
                  Icons.domain_rounded,
                  const Color(0xFF0D9488),
                  const Key('super-admin-workspaces'),
                ),
                _metric(
                  'Active subscriptions',
                  '${summary.activeSubscriptionCount}',
                  'Status active and not past expiry',
                  Icons.verified_outlined,
                  const Color(0xFF10B981),
                  const Key('super-admin-active-subscriptions'),
                ),
                _metric(
                  'Nearing expiry',
                  '${summary.nearingExpiryCount}',
                  'Within ${summary.nearingExpiryDays} days',
                  Icons.schedule_rounded,
                  const Color(0xFFF59E0B),
                  const Key('super-admin-nearing-expiry'),
                ),
                _metric(
                  'Expired subscriptions',
                  '${summary.expiredSubscriptionCount}',
                  'Inactive status or past expiry',
                  Icons.event_busy_rounded,
                  const Color(0xFFEF4444),
                  const Key('super-admin-expired-subscriptions'),
                ),
                _metric(
                  'Pending onboarding',
                  '${summary.pendingOnboardingCount}',
                  'Requests still pending',
                  Icons.mark_email_unread_outlined,
                  const Color(0xFF6366F1),
                  const Key('super-admin-pending-onboarding'),
                ),
                _metric(
                  'Open support',
                  '${summary.openSupportCount}',
                  'In progress ${summary.inProgressSupportCount}',
                  Icons.support_agent_rounded,
                  const Color(0xFF0EA5E9),
                  const Key('super-admin-open-support'),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: CRMSpacing.l),
        const _QuickLinks(),
        const SizedBox(height: CRMSpacing.l),
        if (isMobile) ...[
          _OrganizationPanel(state: state),
          const SizedBox(height: CRMSpacing.m),
          _SnapshotPanel(workspace: overview.selectedWorkspace),
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _OrganizationPanel(state: state)),
              const SizedBox(width: CRMSpacing.m),
              Expanded(child: _SnapshotPanel(workspace: overview.selectedWorkspace)),
            ],
          ),
        const SizedBox(height: CRMSpacing.l),
        _QueueSection(
          title: 'Pending broker requests',
          empty: 'No pending onboarding requests.',
          children: overview.pendingOnboarding
              .map(
                (request) => _Line(
                  title: request.brokerageName,
                  detail: '${request.fullName} · ${request.email} · ${request.status}',
                ),
              )
              .toList(),
        ),
        const SizedBox(height: CRMSpacing.m),
        _QueueSection(
          title: 'Expired and nearing expiry',
          empty: 'No subscriptions need renewal attention.',
          children: overview.attentionSubscriptions
              .map(
                (org) => _Line(
                  title: org.organizationName,
                  detail: '${org.workspaceLabel} · ${org.planName ?? 'No plan'} · ${org.subscriptionLabel}',
                ),
              )
              .toList(),
        ),
        const SizedBox(height: CRMSpacing.m),
        _QueueSection(
          title: 'Open support issues',
          empty: 'No open support issues.',
          children: overview.openIssues
              .map(
                (issue) => _Line(
                  title: '${issue.ticketNumber} · ${issue.pageName}',
                  detail: '${issue.reporterName} · ${issue.priority} · ${issue.status}',
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _metric(String title, String value, String subtitle, IconData icon, Color color, Key key) {
    return KeyedSubtree(
      key: key,
      child: StatCard(
        title: title,
        value: value,
        subtitle: subtitle,
        icon: icon,
        accentColor: color,
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final double maxWidth;
  final List<Widget> cards;

  const _SummaryGrid({required this.maxWidth, required this.cards});

  @override
  Widget build(BuildContext context) {
    final columns = maxWidth < CRMBreakpoints.tablet
        ? 2
        : maxWidth < CRMBreakpoints.desktop
            ? 3
            : 4;
    const gap = 12.0;
    final cardWidth = (maxWidth - gap * (columns - 1)) / columns;
    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: [
        for (final card in cards) SizedBox(width: cardWidth, child: card),
      ],
    );
  }
}

class _QuickLinks extends StatelessWidget {
  const _QuickLinks();

  static const _links = <_NavLink>[
    _NavLink('Broker Workspaces', '/admin/brokers', Icons.domain_rounded),
    _NavLink('Tier Plans', '/admin/plans', Icons.workspace_premium_rounded),
    _NavLink('Permissions', '/admin/permissions', Icons.security_rounded),
    _NavLink('Issue Management', '/admin/support', Icons.admin_panel_settings_outlined),
    _NavLink('Audit Logs', '/settings/audit-logs', Icons.history_rounded),
    _NavLink('Super Admin Metrics', '/reports/leads/super-admin-metrics', Icons.insights_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: CRMSpacing.xs,
      runSpacing: CRMSpacing.xs,
      children: [
        for (final link in _links)
          OutlinedButton.icon(
            onPressed: () => context.go(link.route),
            icon: Icon(link.icon, size: 18),
            label: Text(link.label),
            style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
          ),
      ],
    );
  }
}

class _NavLink {
  final String label;
  final String route;
  final IconData icon;

  const _NavLink(this.label, this.route, this.icon);
}

class _OrganizationPanel extends StatelessWidget {
  final SuperAdminDashboardLoaded state;

  const _OrganizationPanel({required this.state});

  @override
  Widget build(BuildContext context) {
    final organizations = state.overview.organizations;
    return _Panel(
      title: 'Organizations',
      child: organizations.isEmpty
          ? const Text('No organizations yet.')
          : Column(
              children: [
                for (final org in organizations)
                  _OrgTile(
                    org: org,
                    selected: org.organizationId == state.selectedOrganizationId,
                    onTap: () => context.read<SuperAdminDashboardBloc>().add(
                          SelectSuperAdminOrganization(org.organizationId),
                        ),
                  ),
                if (state.overview.organizationListTruncated)
                  const Padding(
                    padding: EdgeInsets.only(top: CRMSpacing.xs),
                    child: Text('Showing the latest workspaces. Totals above include every organization.'),
                  ),
              ],
            ),
    );
  }
}

class _OrgTile extends StatelessWidget {
  final SuperAdminOrganizationRow org;
  final bool selected;
  final VoidCallback onTap;

  const _OrgTile({required this.org, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: CRMSpacing.xs),
      child: Material(
        color: selected ? CRMColors.primary.withValues(alpha: 0.08) : CRMColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.s, vertical: CRMSpacing.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(org.organizationName, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(
                    '${org.ownerName ?? 'No owner'} · ${org.ownerRole ?? 'No role'} · ${org.planName ?? 'No plan'} · ${org.subscriptionLabel}',
                    style: TextStyle(color: CRMColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SnapshotPanel extends StatelessWidget {
  final SuperAdminSelectedWorkspace? workspace;

  const _SnapshotPanel({required this.workspace});

  @override
  Widget build(BuildContext context) {
    final selected = workspace;
    return _Panel(
      key: const Key('super-admin-snapshot'),
      title: 'Workspace snapshot',
      child: selected == null
          ? const Text('Select an organization to view a read-only Admin or Broker snapshot.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(selected.organization.organizationName, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: CRMSpacing.xxs),
                Text(selected.organization.workspaceLabel),
                Text(
                  '${selected.organization.ownerName ?? 'No owner'} · ${selected.organization.ownerRole ?? 'No role'}',
                ),
                Text(
                  '${selected.organization.planName ?? 'No plan'} · ${selected.organization.subscriptionLabel}',
                ),
                const SizedBox(height: CRMSpacing.s),
                Wrap(
                  spacing: CRMSpacing.m,
                  runSpacing: CRMSpacing.xs,
                  children: [
                    _Count('Available inventory', selected.metrics.availableInventory),
                    _Count('Total leads', selected.metrics.totalLeads),
                    _Count('Active users', selected.metrics.activeUsers),
                    _Count('Closed deals', selected.metrics.closedDeals),
                    _Count('Site visits done', selected.metrics.siteVisitsDone),
                  ],
                ),
                const SizedBox(height: CRMSpacing.s),
                Wrap(
                  spacing: CRMSpacing.xs,
                  runSpacing: CRMSpacing.xs,
                  children: [
                    _link(context, 'Users', '/users'),
                    _link(context, 'Hierarchy', '/users/tree'),
                    _link(context, 'Broker management', '/admin/brokers'),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _link(BuildContext context, String label, String route) {
    return TextButton(
      onPressed: () => context.go(route),
      style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
      child: Text(label),
    );
  }
}

class _Count extends StatelessWidget {
  final String label;
  final int value;

  const _Count(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Text('$label: $value');
  }
}

class _QueueSection extends StatelessWidget {
  final String title;
  final String empty;
  final List<Widget> children;

  const _QueueSection({required this.title, required this.empty, required this.children});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: title,
      child: children.isEmpty ? Text(empty) : Column(children: children),
    );
  }
}

class _Line extends StatelessWidget {
  final String title;
  final String detail;

  const _Line({required this.title, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: CRMSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(detail, style: TextStyle(color: CRMColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final Widget child;

  const _Panel({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(CRMSpacing.m),
      decoration: BoxDecoration(
        color: CRMColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CRMColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: CRMSpacing.s),
          child,
        ],
      ),
    );
  }
}
