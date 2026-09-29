import 'package:flutter/material.dart';

import '../../../core/design_system/tokens/app_colors.dart';
import '../services/portal_integrations_service.dart';
import 'campaign_leads_screen.dart';

class PortalLeadsScreen extends StatefulWidget {
  final String integrationId;
  const PortalLeadsScreen({super.key, required this.integrationId});

  @override
  State<PortalLeadsScreen> createState() => _PortalLeadsScreenState();
}

class _PortalLeadsScreenState extends State<PortalLeadsScreen> {
  final _service = PortalIntegrationsService();
  String? _name;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(PortalLeadsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.integrationId != widget.integrationId) _load();
  }

  Future<void> _load() async {
    setState(() {
      _name = null;
      _error = null;
    });
    try {
      final row = await _service.getOne(widget.integrationId);
      if (!mounted) return;
      setState(() => _name = row['name']?.toString() ?? 'Portal');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'This portal integration could not be opened.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: CRMColors.backgroundOf(context),
        body: Center(child: Text(_error!)),
      );
    }
    final name = _name;
    if (name == null) {
      return Scaffold(
        backgroundColor: CRMColors.backgroundOf(context),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return CampaignLeadsScreen(
      key: ValueKey(widget.integrationId),
      lockSource: name,
      portalTabId: widget.integrationId,
    );
  }
}
