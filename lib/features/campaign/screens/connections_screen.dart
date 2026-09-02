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
import '../../../core/design_system/widgets/crm_page_header.dart';
import '../../../core/design_system/widgets/crm_permission_denied.dart';
import '../../integration/services/integration_service.dart';

class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen> {
  final IntegrationService _service = IntegrationService();

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              CRMPageHeader(
                title: 'Connections',
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
          Row(
            children: [
              Expanded(
                child: Column(
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
                ),
              ),
              const SizedBox(width: CRMSpacing.m),
              Expanded(
                child: Column(
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
                ),
              ),
            ],
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
            'Spreadsheet columns (e.g. Name, Phone, City, Budget, Campaign) are dynamically parsed and automatically mapped into the Ingestion Grid.',
            style: CRMTypography.body.copyWith(color: CRMColors.textSecondaryOf(context), fontSize: 13),
          ),

          const SizedBox(height: CRMSpacing.l),

          OutlinedButton.icon(
            icon: const Icon(Icons.table_chart_rounded, color: CRMColors.sage, size: 16),
            label: const Text('Google Sheets Apps Script Guide'),
            onPressed: () => _showGoogleSheetsSetupGuide(context),
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
          return GridView.count(
            crossAxisCount: isWide ? 3 : 1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: CRMSpacing.m,
            crossAxisSpacing: CRMSpacing.m,
            childAspectRatio: isWide ? 2.2 : 3.5,
            children: [
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
            ],
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
            const Text('Integration Setup Guides'),
          ],
        ),
        content: SizedBox(
          width: 480,
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
            const Text('Meta Lead Ads Webhook Setup'),
          ],
        ),
        content: SizedBox(
          width: 540,
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
            const Text('Google Sheets Apps Script Integration'),
          ],
        ),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('To send new rows directly from Google Sheets to this CRM:'),
                const SizedBox(height: CRMSpacing.m),
                _buildGuideStep('1', 'Open your Google Sheet > Extensions > Apps Script.'),
                _buildGuideStep('2', 'Paste the webhook trigger function:'),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: SelectableText(
                    '''function onFormSubmit(e) {
  var url = "${_service.webhookUrl}";
  var payload = JSON.stringify({
    source: "Google Sheets",
    data: e.namedValues
  });
  UrlFetchApp.fetch(url, {
    method: "post",
    contentType: "application/json",
    payload: payload
  });
}''',
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
                const SizedBox(height: CRMSpacing.m),
                _buildGuideStep('3', 'Set up an "On form submit" or "On change" trigger in Apps Script.'),
              ],
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
            const Text('Meta Conversions API (Lead Quality)'),
          ],
        ),
        content: SizedBox(
          width: 520,
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
