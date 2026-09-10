import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../../core/security/role_guard.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/widgets/cards.dart';
import '../../../core/design_system/widgets/buttons.dart';
import '../../../core/design_system/widgets/crm_permission_denied.dart';
import '../../integration/services/integration_service.dart';
import 'campaign_subshell_header.dart';

class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen> {
  final IntegrationService _service = IntegrationService();
  final TextEditingController _sheetUrlController = TextEditingController();
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceUpdate);
    _service.watchCampaignUi();
    _service.ensureLoaded().then((_) {
      if (!mounted) return;
      _sheetUrlController.text = _service.googleSheetUrl;
    });
  }

  @override
  void dispose() {
    _service.unwatchCampaignUi();
    _service.removeListener(_onServiceUpdate);
    _sheetUrlController.dispose();
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _syncSheetToLeads(BuildContext context) async {
    setState(() => _isSyncing = true);
    try {
      await _service.setGoogleSheetUrl(_sheetUrlController.text);
      final count = await _service.syncGoogleSheet();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count == 0
                ? 'No new sheet rows found. Check sharing is set to Anyone with the link.'
                : 'Synced $count row(s) into Campaign Leads only. Open Campaign Leads to filter, delete fakes, then Move to Leads page.',
          ),
          backgroundColor: count == 0 ? null : CRMColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_service.lastSyncError ?? e.toString()),
          backgroundColor: CRMColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
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
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: CRMColors.backgroundOf(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(CRMSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              CampaignSubshellHeader(
                activeTab: 'connections',
                trailing: CRMButton(
                  label: 'Setup Guides',
                  prefixIcon: Icons.menu_book_rounded,
                  variant: CRMButtonVariant.outline,
                  height: 40,
                  onPressed: () => _showSetupGuidesModal(context),
                ),
              ),

              const SizedBox(height: CRMSpacing.l),

              // Active & Ready Connectors Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 900;
                  return isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildMetaConnectionCard(context)),
                            const SizedBox(width: CRMSpacing.l),
                            Expanded(child: _buildGoogleSheetsCard(context)),
                          ],
                        )
                      : Column(
                          children: [
                            _buildMetaConnectionCard(context),
                            const SizedBox(height: CRMSpacing.l),
                            _buildGoogleSheetsCard(context),
                          ],
                        );
                },
              ),

              const SizedBox(height: CRMSpacing.l),

              // Future Connectors Section
              _buildFutureConnectorsCard(context),
            ],
          ),
        ),
      ),
    );
  }

  // --- META CONNECTION CARD ---
  Widget _buildMetaConnectionCard(BuildContext context) {
    return CRMCard(
      elevated: true,
      accentBorder: CRMColors.terracotta.withValues(alpha: 0.35),
      title: 'Meta Lead Ads (Facebook & Instagram)',
      subtitle: 'Real-time webhook listener and Conversions API feedback loop for Meta Ads Manager.',
      headerAction: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: CRMColors.success.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CRMColors.success.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: CRMColors.success,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'LIVE & LISTENING',
              style: CRMTypography.captionBold.copyWith(color: CRMColors.success, fontSize: 11),
            ),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: CRMSpacing.s),

          // Production Webhook URL
          Text(
            'PRODUCTION SSL WEBHOOK URL (POST)',
            style: CRMTypography.captionBold.copyWith(color: CRMColors.textSecondaryOf(context), fontSize: 11),
          ),
          const SizedBox(height: CRMSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: 10),
            decoration: BoxDecoration(
              color: CRMColors.cardBgOf(context),
              borderRadius: BorderRadius.circular(CRMBorderRadius.input),
              border: Border.all(color: CRMColors.borderOf(context)),
            ),
            child: Row(
              children: [
                const Icon(Icons.link_rounded, color: CRMColors.terracotta, size: 20),
                const SizedBox(width: CRMSpacing.s),
                Expanded(
                  child: SelectableText(
                    _service.webhookUrl,
                    style: CRMTypography.body.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                      color: CRMColors.primaryOf(context),
                      fontSize: 12,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  tooltip: 'Copy Production URL',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _service.webhookUrl));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Production Webhook URL copied!')),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: CRMSpacing.m),

          // Direct Hostinger VPS IP URL
          Text(
            'DIRECT HOSTINGER VPS IP ENDPOINT (PORT 5001)',
            style: CRMTypography.captionBold.copyWith(color: CRMColors.textSecondaryOf(context), fontSize: 11),
          ),
          const SizedBox(height: CRMSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: 10),
            decoration: BoxDecoration(
              color: CRMColors.cardBgOf(context),
              borderRadius: BorderRadius.circular(CRMBorderRadius.input),
              border: Border.all(color: CRMColors.borderOf(context)),
            ),
            child: Row(
              children: [
                Icon(Icons.dns_rounded, color: CRMColors.textSecondaryOf(context), size: 18),
                const SizedBox(width: CRMSpacing.s),
                Expanded(
                  child: SelectableText(
                    _service.vpsDirectWebhookUrl,
                    style: CRMTypography.caption.copyWith(
                      fontFamily: 'monospace',
                      color: CRMColors.textSecondaryOf(context),
                      fontSize: 12,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  tooltip: 'Copy Direct VPS URL',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _service.vpsDirectWebhookUrl));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Direct VPS IP Webhook URL copied!')),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: CRMSpacing.m),

          // Verify Token & Webhook Secret
          Builder(
            builder: (context) {
              final isNarrow = MediaQuery.of(context).size.width < 700;
              final tokenField = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'META VERIFY TOKEN',
                    style: CRMTypography.captionBold.copyWith(color: CRMColors.textSecondaryOf(context), fontSize: 11),
                  ),
                  const SizedBox(height: CRMSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: 8),
                    decoration: BoxDecoration(
                      color: CRMColors.cardBgOf(context),
                      borderRadius: BorderRadius.circular(CRMBorderRadius.input),
                      border: Border.all(color: CRMColors.borderOf(context)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            _service.metaVerifyToken,
                            style: CRMTypography.caption.copyWith(fontFamily: 'monospace', fontSize: 11),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 14),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _service.metaVerifyToken));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Verify Token copied!')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final secretField = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WEBHOOK SECRET (HMAC SHA-256)',
                    style: CRMTypography.captionBold.copyWith(color: CRMColors.textSecondaryOf(context), fontSize: 11),
                  ),
                  const SizedBox(height: CRMSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: 8),
                    decoration: BoxDecoration(
                      color: CRMColors.cardBgOf(context),
                      borderRadius: BorderRadius.circular(CRMBorderRadius.input),
                      border: Border.all(color: CRMColors.borderOf(context)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            _service.webhookSecret,
                            style: CRMTypography.caption.copyWith(fontFamily: 'monospace', fontSize: 11),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 14),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _service.webhookSecret));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Webhook Secret copied!')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  children: [
                    tokenField,
                    const SizedBox(height: CRMSpacing.m),
                    secretField,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: tokenField),
                  const SizedBox(width: CRMSpacing.m),
                  Expanded(child: secretField),
                ],
              );
            },
          ),

          const SizedBox(height: CRMSpacing.m),

          // Actions
          Wrap(
            spacing: CRMSpacing.s,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.facebook_rounded, color: CRMColors.terracotta, size: 16),
                label: const Text('Meta Lead Ads Setup Guide'),
                onPressed: () => _showMetaSetupGuide(context),
              ),
              OutlinedButton.icon(
                icon: Icon(Icons.send_rounded, color: CRMColors.primaryOf(context), size: 16),
                label: const Text('Meta Conversions API (Lead Quality)'),
                onPressed: () => _showMetaConversionsApiInfo(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- GOOGLE SHEETS CARD ---
  Widget _buildGoogleSheetsCard(BuildContext context) {
    return CRMCard(
      elevated: true,
      accentBorder: CRMColors.sage.withValues(alpha: 0.35),
      title: 'Google Sheets Apps Script Integration',
      subtitle: 'Automatically push incoming spreadsheet rows from Google Forms or offline lead lists into your CRM.',
      headerAction: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: CRMColors.success.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CRMColors.success.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: CRMColors.success,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'ACTIVE',
              style: CRMTypography.captionBold.copyWith(color: CRMColors.success, fontSize: 11),
            ),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: CRMSpacing.s),
          Text(
            'APPS SCRIPT DESTINATION ENDPOINT',
            style: CRMTypography.captionBold.copyWith(color: CRMColors.textSecondaryOf(context), fontSize: 11),
          ),
          const SizedBox(height: CRMSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: 10),
            decoration: BoxDecoration(
              color: CRMColors.cardBgOf(context),
              borderRadius: BorderRadius.circular(CRMBorderRadius.input),
              border: Border.all(color: CRMColors.borderOf(context)),
            ),
            child: Row(
              children: [
                const Icon(Icons.table_chart_rounded, color: CRMColors.sage, size: 20),
                const SizedBox(width: CRMSpacing.s),
                Expanded(
                  child: SelectableText(
                    _service.webhookUrl,
                    style: CRMTypography.body.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                      color: CRMColors.primaryOf(context),
                      fontSize: 12,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  tooltip: 'Copy Apps Script Webhook URL',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _service.webhookUrl));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Google Sheets Webhook URL copied!')),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: CRMSpacing.m),

          Text(
            'Keep row 1 as plain headers. A Name dropdown with only a few options (projects/properties) is treated as a tag, not as the person. Each sheet row becomes its own campaign lead using phone/email. Clean them here, then Move to Leads page.',
            style: CRMTypography.body.copyWith(color: CRMColors.textSecondaryOf(context), fontSize: 13),
          ),

          const SizedBox(height: CRMSpacing.l),

          Text(
            'GOOGLE SHEET LINK (REQUIRED TO LOAD ALL ROWS)',
            style: CRMTypography.captionBold.copyWith(color: CRMColors.textSecondaryOf(context), fontSize: 11),
          ),
          const SizedBox(height: CRMSpacing.xs),
          TextField(
            controller: _sheetUrlController,
            decoration: InputDecoration(
              hintText: 'https://docs.google.com/spreadsheets/d/...',
              prefixIcon: const Icon(Icons.link_rounded, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.input)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: CRMSpacing.s),
          Text(
            'In Google Sheets: Share → Anyone with the link (Viewer), then Sync. Use a Property Name dropdown for inventory; keep Client Name as a separate column when the Name dropdown is a property list.',
            style: CRMTypography.body.copyWith(color: CRMColors.textSecondaryOf(context), fontSize: 13),
          ),
          if (_service.lastSyncError != null) ...[
            const SizedBox(height: CRMSpacing.s),
            Text(
              _service.lastSyncError!,
              style: CRMTypography.caption.copyWith(color: CRMColors.danger),
            ),
          ],
          const SizedBox(height: CRMSpacing.m),
          Wrap(
            spacing: CRMSpacing.s,
            runSpacing: CRMSpacing.s,
            children: [
              CRMButton(
                label: _isSyncing ? 'Syncing...' : 'Sync to Campaign inbox',
                prefixIcon: Icons.sync_rounded,
                height: 40,
                isLoading: _isSyncing,
                onPressed: _isSyncing ? null : () => _syncSheetToLeads(context),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.table_chart_rounded, color: CRMColors.sage, size: 16),
                label: const Text('Google Sheets Apps Script Guide'),
                onPressed: () => _showGoogleSheetsSetupGuide(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- FUTURE CONNECTORS SECTION ---
  Widget _buildFutureConnectorsCard(BuildContext context) {
    return CRMCard(
      elevated: true,
      title: 'Additional Marketing Connectors',
      subtitle: 'Connect other advertising channels, messaging APIs, and lead capture funnels.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;
          final tiles = [
            _buildConnectorTile(
              context,
              title: 'WhatsApp Cloud API',
              subtitle: 'Automate lead replies & conversational capture',
              icon: Icons.chat_rounded,
              iconColor: const Color(0xFF25D366),
              statusLabel: 'Ready to Connect',
              statusColor: CRMColors.primaryOf(context),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('WhatsApp Cloud API connector module initialized.')),
                );
              },
            ),
            _buildConnectorTile(
              context,
              title: 'Google Ads (Search & Display)',
              subtitle: 'Lead Form Assets & Offline Conversion Uploads',
              icon: Icons.ads_click_rounded,
              iconColor: const Color(0xFF4285F4),
              statusLabel: 'Ready to Connect',
              statusColor: CRMColors.primaryOf(context),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Google Ads webhook connector available via POST endpoint.')),
                );
              },
            ),
            _buildConnectorTile(
              context,
              title: 'Custom REST Webhook API',
              subtitle: 'Ingest JSON payloads from any external landing page',
              icon: Icons.api_rounded,
              iconColor: const Color(0xFF9C27B0),
              statusLabel: 'Active (Port 5001)',
              statusColor: CRMColors.success,
              onTap: () {
                Clipboard.setData(ClipboardData(text: _service.webhookUrl));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Custom REST Webhook URL copied!')),
                );
              },
            ),
          ];

          if (!isWide) {
            return Column(
              children: [
                tiles[0],
                const SizedBox(height: CRMSpacing.m),
                tiles[1],
                const SizedBox(height: CRMSpacing.m),
                tiles[2],
              ],
            );
          }

          return GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: CRMSpacing.m,
            crossAxisSpacing: CRMSpacing.m,
            childAspectRatio: 2.2,
            children: tiles,
          );
        },
      ),
    );
  }

  Widget _buildConnectorTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required String statusLabel,
    required Color statusColor,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(CRMSpacing.m),
      decoration: BoxDecoration(
        color: CRMColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(CRMBorderRadius.card),
        border: Border.all(color: CRMColors.borderOf(context)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: CRMSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: CRMTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context), fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  statusLabel,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            onPressed: onTap,
          ),
        ],
      ),
    );
  }

  // --- SETUP GUIDES MODAL ---
  void _showSetupGuidesModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.integration_instructions_rounded, color: CRMColors.primaryOf(context)),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Integration Setup Guides', overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListTile(
                    leading: const Icon(Icons.facebook_rounded, color: CRMColors.terracotta, size: 28),
                    title: const Text('Meta Lead Ads Setup Guide', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Connect Facebook & Instagram lead forms to auto-ingest into CRM'),
                    trailing: const Icon(Icons.chevron_right),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: CRMColors.borderOf(context)),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showMetaSetupGuide(context);
                    },
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    leading: const Icon(Icons.table_chart_rounded, color: CRMColors.sage, size: 28),
                    title: const Text('Google Sheets Apps Script Guide', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Sync new spreadsheet rows directly to your CRM webhook'),
                    trailing: const Icon(Icons.chevron_right),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: CRMColors.borderOf(context)),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showGoogleSheetsSetupGuide(context);
                    },
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    leading: Icon(Icons.send_rounded, color: CRMColors.primaryOf(context), size: 28),
                    title: const Text('Meta Conversions API (Lead Quality)', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Send qualified/converted offline lead feedback back to Meta algorithms'),
                    trailing: const Icon(Icons.chevron_right),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: CRMColors.borderOf(context)),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showMetaConversionsApiInfo(context);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showMetaSetupGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.facebook_rounded, color: CRMColors.terracotta),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Meta Lead Ads Webhook Setup', overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Follow these steps in your Meta for Developers App / Business Suite:',
                    style: CRMTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: CRMSpacing.m),
                  _buildGuideStep('1', 'Go to developers.facebook.com > Your App > Webhooks.'),
                  _buildGuideStep('2', 'Select "Page" or "Leadgen" object and click Subscribe.'),
                  _buildGuideStep('3', 'Callback URL:', _service.webhookUrl),
                  _buildGuideStep('4', 'Verify Token:', _service.metaVerifyToken),
                  _buildGuideStep('5', 'Subscribe to the "leadgen" field.'),
                  _buildGuideStep('6', 'Test using the Meta Lead Ads Testing Tool to ingest a sample lead.'),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Got It')),
        ],
      ),
    );
  }

  void _showGoogleSheetsSetupGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.table_chart_rounded, color: CRMColors.sage),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Google Sheets Apps Script Integration', overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('To send every spreadsheet row into PropKart Leads:'),
                  const SizedBox(height: CRMSpacing.m),
                  _buildGuideStep('1', 'Share the sheet: Anyone with the link (Viewer), paste the URL here, and click Sync to Campaign inbox. Rows stay on Campaign Leads until you move them.'),
                  _buildGuideStep('2', 'Also open Extensions > Apps Script, replace the code with this (sends new rows as they are added):'),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: SelectableText(
                      IntegrationService.appsScriptSnippet(_service.webhookUrl),
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                    ),
                  ),
                  const SizedBox(height: CRMSpacing.m),
                  _buildGuideStep('3', 'Click Run on syncAllRows once (authorize Google when asked). Keep your On change / On form submit trigger for new rows.'),
                  _buildGuideStep('4', 'Keep headers as plain text. Put dropdowns in data rows. Recommended columns: Client Name, Phone, Property Name (dropdown of inventory), City, Budget, Configuration, Campaign Name. If Name is a property dropdown, add a separate Client Name column.'),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done')),
        ],
      ),
    );
  }

  void _showMetaConversionsApiInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.send_rounded, color: CRMColors.primaryOf(context)),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Meta Conversions API (Lead Quality)', overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'When you update lead quality (Qualified, Disqualified, Converted) in the Ingestion Grid, an event is dispatched to Meta Conversions API.',
                  ),
                  const SizedBox(height: CRMSpacing.m),
                  _buildGuideStep(' Qualified', 'Signals to Meta algorithm to find more high-intent buyers with similar demographics.'),
                  _buildGuideStep(' Converted', 'Dispatches final conversion value to Meta for ROAS optimization.'),
                  _buildGuideStep(' Disqualified', 'Prevents ad budget wastage on junk clicks.'),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildGuideStep(String step, String text, [String? code]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: CRMSpacing.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$step. ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text),
                if (code != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SelectableText(code, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
