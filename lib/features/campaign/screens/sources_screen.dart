import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../../core/security/role_guard.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/tokens/app_breakpoints.dart';
import '../../../core/design_system/widgets/cards.dart';
import '../../../core/design_system/widgets/crm_permission_denied.dart';
import '../../../core/design_system/mobile/mobile.dart';
import '../bloc/campaign_connections_bloc.dart';
import '../models/campaign_connection_model.dart';
import '../services/campaign_connections_service.dart';
import '../services/portal_integrations_service.dart';

/// Lists every campaign source of the current Admin's organisation and opens
/// the existing Campaign Leads page for the selected source.
class SourcesScreen extends StatefulWidget {
  const SourcesScreen({super.key});

  @override
  State<SourcesScreen> createState() => _SourcesScreenState();
}

class _SourcesScreenState extends State<SourcesScreen> {
  final PortalIntegrationsService _portals = PortalIntegrationsService();
  final CampaignConnectionsService _connections = CampaignConnectionsService();
  List<Map<String, dynamic>> _portalIntegrations = [];
  bool _loadingPortals = true;

  @override
  void initState() {
    super.initState();
    _loadPortals();
  }

  Future<void> _loadPortals({bool force = false}) async {
    try {
      final rows = force ? await _portals.list() : await _portals.listCached();
      if (mounted) setState(() => _portalIntegrations = rows);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingPortals = false);
    }
  }

  Future<void> _refresh() async {
    CampaignConnectionsBloc().add(const FetchCampaignConnectionsEvent(silent: true));
    await _loadPortals(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    String userRole = '';
    if (authState is Authenticated) {
      userRole = authState.user.role;
    }

    if (!RoleGuard.canAccessCampaign(userRole)) {
      return Scaffold(
        backgroundColor: CRMColors.backgroundOf(context),
        body: SafeArea(
          child: CRMPermissionDenied(
            onGoBack: () => Navigator.of(context).maybePop(),
            title: 'Access Restricted',
            message:
                'You do not have the required permissions to view this module. Please contact your system administrator.',
          ),
        ),
      );
    }

    final isMobile = MediaQuery.sizeOf(context).width < CRMBreakpoints.tablet;

    final bodyContent = SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        isMobile ? CRMSpacing.m : CRMSpacing.l,
        isMobile ? CRMSpacing.s : CRMSpacing.l,
        isMobile ? CRMSpacing.m : CRMSpacing.l,
        isMobile ? CRMSpacing.m : CRMSpacing.l,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isMobile) ...[
            Text(
              'Sources',
              style: CRMTypography.headline.copyWith(fontSize: 26, letterSpacing: -0.5),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            'All campaigns added for your workspace. Select a campaign to open its leads.',
            style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
          ),
          const SizedBox(height: CRMSpacing.l),
          BlocBuilder<CampaignConnectionsBloc, CampaignConnectionsState>(
            bloc: CampaignConnectionsBloc()..add(const FetchCampaignConnectionsEvent(silent: true)),
            builder: (context, connState) {
              final tiles = _buildSourceTiles(context, userRole, connState);
              return LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= CRMBreakpoints.tablet;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isWide)
                        Wrap(
                          spacing: CRMSpacing.l,
                          runSpacing: CRMSpacing.l,
                          children: tiles.map((tile) => SizedBox(width: 420, child: tile)).toList(),
                        )
                      else
                        ...tiles.expand((tile) => [tile, const SizedBox(height: CRMSpacing.l)]),
                      if (_loadingPortals ||
                          connState.status == CampaignConnectionsStatus.initial ||
                          connState.status == CampaignConnectionsStatus.loading)
                        const Padding(
                          padding: EdgeInsets.only(top: CRMSpacing.l),
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: CRMSpacing.l),
        ],
      ),
    );

    if (isMobile) {
      return MobileScreenScaffold(
        title: 'Sources',
        scrollable: false,
        onRefresh: _refresh,
        body: bodyContent,
      );
    }

    return Scaffold(
      backgroundColor: CRMColors.backgroundOf(context),
      body: SafeArea(
        top: false,
        bottom: false,
        child: bodyContent,
      ),
    );
  }

  List<Widget> _buildSourceTiles(
    BuildContext context,
    String userRole,
    CampaignConnectionsState connState,
  ) {
    final loaded = connState.status == CampaignConnectionsStatus.success;
    final failed = connState.status == CampaignConnectionsStatus.failure;
    final meta = connState.findByProvider('META');
    final housing = connState.findByProvider('HOUSING');
    final showMeta = (loaded && meta != null) || failed;
    final showHousing = (loaded && housing != null) || failed;
    final canDelete = RoleGuard.isAdmin(userRole) || RoleGuard.isSuperAdmin(userRole);
    return [
      if (showMeta && RoleGuard.canViewPage(userRole, '/campaign/meta'))
        _buildSourceTile(
          context,
          title: 'Meta',
          subtitle: 'Meta Ads lead forms (Facebook & Instagram)',
          icon: Icons.campaign_rounded,
          color: CRMColors.terracotta,
          status: 'Listening',
          route: '/campaign/meta',
          onDelete: canDelete && meta != null
              ? () => _confirmDelete(context, name: 'Meta', delete: () => _connections.deleteConnection(meta.id))
              : null,
        ),
      if (showHousing && RoleGuard.canViewPage(userRole, '/campaign/housing'))
        _buildSourceTile(
          context,
          title: 'Housing',
          subtitle: 'Housing.com verified property inquiries',
          icon: Icons.apartment_rounded,
          color: const Color(0xFF6C5CE7),
          status: housing?.isConnected == true ? 'Connected' : 'Ready',
          route: '/campaign/housing',
          onDelete: canDelete && housing != null
              ? () => _confirmDelete(context, name: 'Housing', delete: () => _connections.deleteConnection(housing.id))
              : null,
        ),
      for (final row in _portalIntegrations)
        if ((row['id']?.toString() ?? '').isNotEmpty)
          _buildSourceTile(
            context,
            title: row['name']?.toString() ?? 'Portal',
            subtitle: _portalSubtitle(row),
            icon: Icons.hub_outlined,
            color: _portalStatusColor(row['status']?.toString()),
            status: _portalStatusLabel(row['status']?.toString()),
            route: '/campaign/portal-leads/${row['id']}',
            onDelete: canDelete
                ? () => _confirmDelete(
                      context,
                      name: row['name']?.toString() ?? 'Portal',
                      delete: () => _portals.remove(row['id'].toString()),
                    )
                : null,
          ),
      for (final conn in _otherActiveConnections(connState.connections))
        _buildSourceTile(
          context,
          title: conn.displayName,
          subtitle: 'Campaign connection',
          icon: Icons.extension_rounded,
          color: CRMColors.success,
          status: 'Active',
          route: '/campaign/leads?source=${Uri.encodeComponent(conn.displayName)}',
          onDelete: canDelete
              ? () => _confirmDelete(context, name: conn.displayName, delete: () => _connections.deleteConnection(conn.id))
              : null,
        ),
    ];
  }

  Future<void> _confirmDelete(
    BuildContext context, {
    required String name,
    required Future<void> Function() delete,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "$name"?'),
        content: const Text(
          'This campaign will be removed from Sources and Lead Allocation and will stop syncing new leads. '
          'Leads already received from it are kept and stay with their assigned users.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: CRMColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await delete();
      if (!mounted) return;
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(content: Text('"$name" deleted.'), backgroundColor: CRMColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: CRMColors.danger,
        ),
      );
    }
    await _refresh();
  }

  Iterable<CampaignConnectionModel> _otherActiveConnections(
    List<CampaignConnectionModel> connections,
  ) {
    return connections.where((conn) {
      final type = conn.providerType.toUpperCase();
      return type != 'HOUSING' && type != 'META' && conn.isActive;
    });
  }

  String _portalSubtitle(Map<String, dynamic> row) {
    final kind = row['integrationType'] == 'WEBHOOK' ? 'Webhook / Push' : 'API Pull';
    final provider = row['provider']?.toString() ?? '';
    return provider.isEmpty ? 'Property portal · $kind' : 'Property portal · $provider · $kind';
  }

  String _portalStatusLabel(String? status) {
    switch ((status ?? '').toUpperCase()) {
      case 'ACTIVE':
        return 'Active';
      case 'PAUSED':
        return 'Paused';
      case 'ERROR':
        return 'Error';
      case 'DRAFT':
        return 'Draft';
      default:
        return 'Not configured';
    }
  }

  Color _portalStatusColor(String? status) {
    switch ((status ?? '').toUpperCase()) {
      case 'ACTIVE':
        return CRMColors.success;
      case 'ERROR':
        return CRMColors.danger;
      case 'PAUSED':
        return const Color(0xFFB45309);
      default:
        return const Color(0xFF3D6B8C);
    }
  }

  Widget _buildSourceTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String status,
    required String route,
    VoidCallback? onDelete,
  }) {
    return InkWell(
      onTap: () => context.go(route),
      borderRadius: BorderRadius.circular(16),
      child: CRMCard(
        elevated: true,
        accentBorder: color.withValues(alpha: 0.35),
        title: title,
        subtitle: subtitle,
        headerAction: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              status.toUpperCase(),
              style: CRMTypography.captionBold.copyWith(color: color, fontSize: 11),
            ),
            if (onDelete != null) ...[
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Delete campaign',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_outline_rounded, size: 20, color: CRMColors.danger),
                onPressed: onDelete,
              ),
            ],
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Open campaign leads',
                style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: CRMColors.textSecondaryOf(context)),
          ],
        ),
      ),
    );
  }
}
