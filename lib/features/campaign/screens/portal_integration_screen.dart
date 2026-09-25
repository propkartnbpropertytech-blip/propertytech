import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/widgets/buttons.dart';
import '../../../core/design_system/widgets/cards.dart';
import '../services/portal_integrations_service.dart';

class PortalIntegrationScreen extends StatefulWidget {
  final String? integrationId;
  final String? initialProvider;
  const PortalIntegrationScreen({super.key, this.integrationId, this.initialProvider});

  @override
  State<PortalIntegrationScreen> createState() => _PortalIntegrationScreenState();
}

class _PortalIntegrationScreenState extends State<PortalIntegrationScreen> {
  final _service = PortalIntegrationsService();
  final _steps = const [
    'Basic',
    'Authentication',
    'Request',
    'Parameters',
    'Response',
    'Mapping',
    'Sync',
    'Test',
  ];

  int _step = 0;
  bool _loading = true;
  bool _saving = false;
  String? _id;
  String _name = '';
  String _provider = 'custom';
  String _type = 'API_PULL';
  String _status = 'DRAFT';
  Map<String, dynamic> _config = {};
  List<Map<String, dynamic>> _credentials = [];
  List<Map<String, dynamic>> _destinations = [];
  Map<String, dynamic>? _testResult;
  Map<String, dynamic>? _sample;
  List<Map<String, dynamic>> _logs = [];
  bool _forceActivate = false;

  final _nameCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _collectionCtrl = TextEditingController();
  final _advancedBodyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _provider = widget.initialProvider ?? 'custom';
    _name = _defaultName(_provider);
    _nameCtrl.text = _name;
    _config = _emptyConfig();
    _boot();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    _collectionCtrl.dispose();
    _advancedBodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    try {
      _destinations = await _service.destinations();
      if (widget.integrationId != null) {
        final row = await _service.getOne(widget.integrationId!);
        _apply(row);
      }
    } catch (e) {
      _toast(_message(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _apply(Map<String, dynamic> row) {
    _id = row['id']?.toString();
    _name = row['name']?.toString() ?? _name;
    _provider = row['provider']?.toString() ?? _provider;
    _type = row['integrationType']?.toString() ?? 'API_PULL';
    _status = row['status']?.toString() ?? 'DRAFT';
    _config = row['configuration'] is Map ? Map<String, dynamic>.from(row['configuration'] as Map) : _emptyConfig();
    _credentials = (row['credentials'] as List?)?.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
    _nameCtrl.text = _name;
    _urlCtrl.text = _config['url']?.toString() ?? '';
    _collectionCtrl.text = (_config['response'] as Map?)?['collectionPath']?.toString() ?? '';
    _advancedBodyCtrl.text = _config['advancedBody']?.toString() ?? '';
  }

  Future<void> _ensureCreated() async {
    _readBasic();
    if (_id != null) {
      final saved = await _service.save(_id!, {
        'name': _name,
        'provider': _provider,
        'integrationType': _type,
        'configuration': _config,
      });
      _apply(saved);
      return;
    }
    final created = await _service.create(name: _name, provider: _provider, integrationType: _type);
    _apply(created);
    await _service.save(_id!, {'name': _name, 'provider': _provider, 'integrationType': _type, 'configuration': _config});
  }

  void _readBasic() {
    _name = _nameCtrl.text.trim().isEmpty ? _defaultName(_provider) : _nameCtrl.text.trim();
    _config['url'] = _urlCtrl.text.trim();
    _config['advancedBody'] = _advancedBodyCtrl.text;
    _config['response'] = {
      ..._asMap(_config['response']),
      'collectionPath': _collectionCtrl.text.trim(),
      'format': _asMap(_config['response'])['format'] ?? 'json',
    };
  }

  Future<void> _save({bool stay = true}) async {
    setState(() => _saving = true);
    try {
      await _ensureCreated();
      _toast('Configuration saved');
    } catch (e) {
      _toast(_message(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _next() async {
    await _save();
    if (!mounted || _id == null) return;
    setState(() => _step = (_step + 1).clamp(0, _steps.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      backgroundColor: CRMColors.backgroundOf(context),
      appBar: AppBar(
        backgroundColor: CRMColors.cardBgOf(context),
        foregroundColor: CRMColors.textOf(context),
        title: Text(_nameCtrl.text.isEmpty ? 'Add integration' : _nameCtrl.text),
        leading: IconButton(onPressed: () => context.go('/campaign/connections'), icon: const Icon(Icons.arrow_back_rounded)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                SizedBox(
                  height: 64,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _steps.length,
                    separatorBuilder: (_, index) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final selected = index == _step;
                      return ChoiceChip(
                        label: Text('${index + 1}. ${_steps[index]}'),
                        selected: selected,
                        onSelected: (_) => setState(() => _step = index),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(wide ? 32 : 16, 8, wide ? 32 : 16, 24),
                    children: [
                      CRMCard(
                        elevated: true,
                        title: _steps[_step],
                        child: _stepBody(),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.end,
                        children: [
                          if (_step > 0)
                            CRMButton(
                              label: 'Back',
                              variant: CRMButtonVariant.outline,
                              onPressed: () => setState(() => _step -= 1),
                            ),
                          CRMButton(
                            label: _saving ? 'Saving...' : 'Save draft',
                            variant: CRMButtonVariant.outline,
                            onPressed: _saving ? null : _save,
                          ),
                          if (_step < _steps.length - 1)
                            CRMButton(label: 'Next', onPressed: _saving ? null : _next)
                          else
                            CRMButton(label: 'Save & activate', onPressed: _saving ? null : _activate),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _stepBody() {
    switch (_step) {
      case 0:
        return _basic();
      case 1:
        return _auth();
      case 2:
        return _request();
      case 3:
        return _parameters();
      case 4:
        return _response();
      case 5:
        return _mapping();
      case 6:
        return _sync();
      default:
        return _test();
    }
  }

  Widget _basic() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label('Integration Name', 'Internal name used to identify this connection.'),
        TextField(controller: _nameCtrl, decoration: const InputDecoration(hintText: 'e.g. 99acres - NB Infra')),
        const SizedBox(height: 12),
        _dropdown('Provider', _provider, const {
          '99acres': '99acres',
          'magicbricks': 'MagicBricks',
          'nobroker': 'NoBroker',
          'housing': 'Housing',
          'custom': 'Custom',
        }, (value) => setState(() => _provider = value)),
        _dropdown('Integration Type', _type, const {
          'API_PULL': 'API Pull',
          'WEBHOOK': 'Webhook / Push',
        }, (value) => setState(() => _type = value)),
        Text('Status: $_status. Activation waits for a successful test unless you override it.', style: CRMTypography.caption),
      ],
    );
  }

  Widget _auth() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _dropdown('Authentication Type', _config['authType']?.toString() ?? 'none', const {
          'none': 'None',
          'api_key': 'API Key',
          'bearer': 'Bearer Token',
          'basic': 'Basic Authentication',
          'password': 'Username + Password',
          'oauth': 'OAuth 2.0',
          'header': 'Custom Header',
          'query': 'Query Parameter',
          'custom': 'Custom',
        }, (value) => setState(() => _config['authType'] = value)),
        const Text('Add every credential the portal gave you. Secret values stay masked after saving.'),
        const SizedBox(height: 8),
        ..._credentials.map((row) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(row['name']?.toString() ?? row['key']?.toString() ?? ''),
              subtitle: Text('${row['key']} · ••••••••'),
            )),
        Align(
          alignment: Alignment.centerLeft,
          child: CRMButton(label: 'Add credential', prefixIcon: Icons.add, variant: CRMButtonVariant.outline, onPressed: _addCredential),
        ),
      ],
    );
  }

  Widget _request() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _dropdown('HTTP Method', _config['method']?.toString() ?? 'GET', const {
          'GET': 'GET',
          'POST': 'POST',
          'PUT': 'PUT',
          'PATCH': 'PATCH',
          'DELETE': 'DELETE',
        }, (value) {
          setState(() {
            _config['method'] = value;
            if (value == 'GET') _config['bodyType'] = 'none';
          });
        }),
        _label('API Endpoint URL', 'Enter the official endpoint provided by the portal.'),
        TextField(controller: _urlCtrl, decoration: const InputDecoration(hintText: 'https://api.example.com/v1/leads')),
        const SizedBox(height: 8),
        const Text('Path variables such as {{account_id}} are filled from the credentials you add.'),
      ],
    );
  }

  Widget _parameters() {
    final headers = _rows('headers');
    final query = _rows('query');
    final bodyFields = _rows('bodyFields');
    final method = _config['method']?.toString() ?? 'GET';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Headers', style: CRMTypography.title),
        ..._kvList(headers, 'headers', 'Authorization', 'Bearer {{access_token}}'),
        CRMButton(label: 'Add header', variant: CRMButtonVariant.outline, prefixIcon: Icons.add, onPressed: () => _addRow('headers')),
        const SizedBox(height: 16),
        Text('Query parameters', style: CRMTypography.title),
        ..._kvList(query, 'query', 'start_date', '{{from_date}}'),
        CRMButton(label: 'Add parameter', variant: CRMButtonVariant.outline, prefixIcon: Icons.add, onPressed: () => _addRow('query')),
        const SizedBox(height: 16),
        Text('Request body', style: CRMTypography.title),
        if (method == 'GET')
          const Text('Request body is none for GET.')
        else ...[
          _dropdown('Body type', _config['bodyType']?.toString() ?? 'json', const {
            'json': 'JSON',
            'form': 'Form URL encoded',
            'multipart': 'Multipart form data',
            'raw': 'Raw',
          }, (value) => setState(() => _config['bodyType'] = value)),
          ..._kvList(bodyFields, 'bodyFields', 'startDate', '{{from_date}}'),
          CRMButton(label: 'Add body field', variant: CRMButtonVariant.outline, prefixIcon: Icons.add, onPressed: () => _addRow('bodyFields')),
          const SizedBox(height: 8),
          const Text('Advanced JSON editor'),
          TextField(controller: _advancedBodyCtrl, maxLines: 6, decoration: const InputDecoration(hintText: '{ "from": "{{from_date}}" }')),
        ],
        const SizedBox(height: 12),
        const Text('System variables: {{from_date}} {{to_date}} {{last_sync}} {{current_date}} {{current_datetime}} {{timestamp}}. Credential keys you create, such as {{advertiser_id}}, are available too.'),
      ],
    );
  }

  Widget _response() {
    final pagination = _asMap(_config['pagination']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _dropdown('Response format', _asMap(_config['response'])['format']?.toString() ?? 'json', const {
          'json': 'JSON',
          'xml': 'XML',
          'csv': 'CSV',
        }, (value) => setState(() => _config['response'] = {..._asMap(_config['response']), 'format': value})),
        _label('Lead collection path', 'Example: data.leads'),
        TextField(controller: _collectionCtrl, decoration: const InputDecoration(hintText: 'e.g. data.leads')),
        const SizedBox(height: 12),
        _dropdown('Pagination', pagination['type']?.toString() ?? 'none', const {
          'none': 'None',
          'page': 'Page number',
          'offset': 'Offset / limit',
          'cursor': 'Cursor',
          'next_url': 'Next URL',
        }, (value) => setState(() => _config['pagination'] = {...pagination, 'type': value})),
        if (pagination['type'] == 'page') ...[
          _mini('Page parameter', pagination['pageParam']?.toString() ?? 'page', (v) => _config['pagination'] = {..._asMap(_config['pagination']), 'pageParam': v}),
          _mini('Page size parameter', pagination['pageSizeParam']?.toString() ?? 'limit', (v) => _config['pagination'] = {..._asMap(_config['pagination']), 'pageSizeParam': v}),
        ],
        if (pagination['type'] == 'offset') ...[
          _mini('Offset parameter', pagination['offsetParam']?.toString() ?? 'offset', (v) => _config['pagination'] = {..._asMap(_config['pagination']), 'offsetParam': v}),
          _mini('Limit parameter', pagination['limitParam']?.toString() ?? 'limit', (v) => _config['pagination'] = {..._asMap(_config['pagination']), 'limitParam': v}),
        ],
        if (pagination['type'] == 'cursor') ...[
          _mini('Cursor parameter', pagination['cursorParam']?.toString() ?? 'cursor', (v) => _config['pagination'] = {..._asMap(_config['pagination']), 'cursorParam': v}),
          _mini('Response cursor path', pagination['cursorPath']?.toString() ?? '', (v) => _config['pagination'] = {..._asMap(_config['pagination']), 'cursorPath': v}),
        ],
        if (pagination['type'] == 'next_url')
          _mini('Next URL JSON path', pagination['nextUrlPath']?.toString() ?? '', (v) => _config['pagination'] = {..._asMap(_config['pagination']), 'nextUrlPath': v}),
        _mini('Maximum pages', '${pagination['maxPages'] ?? 5}', (v) => _config['pagination'] = {..._asMap(_config['pagination']), 'maxPages': int.tryParse(v) ?? 5}),
        _mini('Maximum records', '${pagination['maxRecords'] ?? 100}', (v) => _config['pagination'] = {..._asMap(_config['pagination']), 'maxRecords': int.tryParse(v) ?? 100}),
      ],
    );
  }

  Widget _mapping() {
    final mappings = _rows('mappings');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Map each portal field to a PropKart field. You can add as many rows as the portal response needs.'),
        const SizedBox(height: 8),
        ...mappings.asMap().entries.map((entry) {
          final row = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(width: 220, child: TextFormField(
                  initialValue: row['sourcePath']?.toString() ?? '',
                  decoration: const InputDecoration(labelText: 'Source field / JSON path', hintText: 'buyerName'),
                  onChanged: (value) => row['sourcePath'] = value,
                )),
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String>(
                    initialValue: _destinations.any((d) => d['key'] == row['destination']) ? row['destination']?.toString() : 'lead_name',
                    decoration: const InputDecoration(labelText: 'PropKart field'),
                    items: _destinationItems(),
                    onChanged: (value) => setState(() => row['destination'] = value),
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String>(
                    initialValue: row['transform']?.toString() ?? 'none',
                    decoration: const InputDecoration(labelText: 'Transform'),
                    items: const ['none', 'trim', 'lowercase', 'uppercase', 'phone', 'date', 'number', 'boolean', 'split']
                        .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                        .toList(),
                    onChanged: (value) => setState(() => row['transform'] = value),
                  ),
                ),
              ],
            ),
          );
        }),
        CRMButton(label: 'Add mapping', prefixIcon: Icons.add, variant: CRMButtonVariant.outline, onPressed: () {
          setState(() => _rows('mappings').add({'sourcePath': '', 'destination': 'lead_name', 'transform': 'none'}));
        }),
        const SizedBox(height: 12),
        _dropdown('Duplicate strategy', _config['duplicateStrategy']?.toString() ?? 'external_id_source', const {
          'external_id_source': 'External lead ID + source',
          'external_id': 'External lead ID',
          'phone': 'Phone',
          'email': 'Email',
          'phone_property': 'Phone + property',
        }, (value) => setState(() => _config['duplicateStrategy'] = value)),
      ],
    );
  }

  Widget _sync() {
    final sync = _asMap(_config['sync']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _dropdown('Sync strategy', sync['strategy']?.toString() ?? 'last_sync', const {
          'date_range': 'Date range',
          'last_sync': 'Last sync',
          'cursor': 'Cursor',
          'page': 'Page based',
          'full': 'Full sync',
        }, (value) => setState(() => _config['sync'] = {..._asMap(_config['sync']), 'strategy': value})),
        _dropdown('Sync frequency', '${sync['frequencyMinutes'] ?? 5}', const {
          '1': 'Every 1 minute',
          '5': 'Every 5 minutes',
          '10': 'Every 10 minutes',
          '15': 'Every 15 minutes',
          '30': 'Every 30 minutes',
          '60': 'Every hour',
          '0': 'Manual',
        }, (value) => setState(() => _config['sync'] = {..._asMap(_config['sync']), 'frequencyMinutes': int.tryParse(value) ?? 5})),
        _dropdown('Initial sync', sync['initialWindow']?.toString() ?? '24h', const {
          '1h': 'Last 1 hour',
          '6h': 'Last 6 hours',
          '24h': 'Last 24 hours',
          '3d': 'Last 3 days',
          '7d': 'Last 7 days',
        }, (value) => setState(() => _config['sync'] = {..._asMap(_config['sync']), 'initialWindow': value})),
        _mini('Sync overlap minutes', '${sync['overlapMinutes'] ?? 2}', (v) => _config['sync'] = {..._asMap(_config['sync']), 'overlapMinutes': int.tryParse(v) ?? 2}),
        _mini('Maximum records per run', '${sync['maxRecords'] ?? 100}', (v) => _config['sync'] = {..._asMap(_config['sync']), 'maxRecords': int.tryParse(v) ?? 100}),
        _mini('Retry attempts', '${sync['retryAttempts'] ?? 3}', (v) => _config['sync'] = {..._asMap(_config['sync']), 'retryAttempts': int.tryParse(v) ?? 3}),
        _mini('Retry delay seconds', '${sync['retryDelaySeconds'] ?? 30}', (v) => _config['sync'] = {..._asMap(_config['sync']), 'retryDelaySeconds': int.tryParse(v) ?? 30}),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Enable integration after activation'),
          value: sync['enabled'] == true,
          onChanged: (value) => setState(() => _config['sync'] = {..._asMap(_config['sync']), 'enabled': value}),
        ),
      ],
    );
  }

  Widget _test() {
    final result = _testResult;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Provider: $_provider\nMethod: ${_config['method'] ?? 'GET'}\nEndpoint: ${_urlCtrl.text}\nAuthentication: ${_config['authType'] ?? 'none'}\nHeaders: ${_rows('headers').length}\nQuery parameters: ${_rows('query').length}\nMappings: ${_rows('mappings').length}\nSync: every ${_asMap(_config['sync'])['frequencyMinutes'] ?? 5} minutes'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            CRMButton(label: 'Test request', onPressed: _runTest),
            CRMButton(label: 'Fetch sample lead', variant: CRMButtonVariant.outline, onPressed: _runSample),
            CRMButton(label: 'View logs', variant: CRMButtonVariant.outline, onPressed: _loadLogs),
            if (_status == 'ACTIVE')
              CRMButton(label: 'Pause', variant: CRMButtonVariant.outline, onPressed: _pause),
          ],
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Activate even if the test has not succeeded'),
          value: _forceActivate,
          onChanged: (value) => setState(() => _forceActivate = value == true),
        ),
        if (result != null) ...[
          const SizedBox(height: 12),
          Text(result['ok'] == true ? 'SUCCESS' : 'FAILED', style: CRMTypography.title),
          Text('HTTP status: ${result['httpStatus'] ?? '-'}'),
          Text('Response time: ${result['durationMs'] ?? '-'} ms'),
          Text('Records: ${result['records'] ?? 0}'),
          if (result['detectedPaths'] is List) Text('Detected arrays: ${(result['detectedPaths'] as List).join(', ')}'),
          const SizedBox(height: 8),
          const Text('Raw response is shown with secrets removed.'),
          Text(result['raw']?.toString() ?? '', maxLines: 8, overflow: TextOverflow.ellipsis),
        ],
        if (_sample != null) ...[
          const SizedBox(height: 12),
          Text('Sample preview', style: CRMTypography.title),
          Text('External: ${_sample!['external']}'),
          const SizedBox(height: 4),
          Text('PropKart: ${_sample!['mapped']}'),
        ],
        if (_logs.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Recent logs', style: CRMTypography.title),
          ..._logs.take(8).map((log) => Text('${log['status']} · fetched ${log['records_fetched'] ?? 0} · created ${log['records_created'] ?? 0} · duplicates ${log['duplicates'] ?? 0}')),
        ],
      ],
    );
  }

  List<DropdownMenuItem<String>> _destinationItems() {
    final items = _destinations.isEmpty
        ? [
            {'key': 'lead_name', 'label': 'Lead Name'},
            {'key': 'phone', 'label': 'Phone'},
            {'key': 'email', 'label': 'Email'},
            {'key': 'external_lead_id', 'label': 'External Lead ID'},
          ]
        : _destinations;
    return items
        .map((row) => DropdownMenuItem(value: row['key']?.toString() ?? '', child: Text(row['label']?.toString() ?? '')))
        .toList();
  }

  Future<void> _runTest() async {
    setState(() => _saving = true);
    try {
      await _ensureCreated();
      final result = await _service.test(_id!);
      setState(() => _testResult = result);
      _toast('Test request succeeded');
    } catch (e) {
      _toast(_message(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _runSample() async {
    setState(() => _saving = true);
    try {
      await _ensureCreated();
      final result = await _service.sample(_id!);
      setState(() => _sample = result);
    } catch (e) {
      _toast(_message(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _loadLogs() async {
    if (_id == null) return;
    try {
      final rows = await _service.logs(_id!);
      setState(() => _logs = rows);
    } catch (e) {
      _toast(_message(e), error: true);
    }
  }

  Future<void> _pause() async {
    if (_id == null) return;
    setState(() => _saving = true);
    try {
      final saved = await _service.pause(_id!);
      _apply(saved);
      _toast('Integration paused');
    } catch (e) {
      _toast(_message(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _activate() async {
    setState(() => _saving = true);
    try {
      await _ensureCreated();
      await _service.activate(_id!, force: _forceActivate);
      _toast('Integration activated. PropKart will pull leads on the schedule you set.');
      if (mounted) context.go('/campaign/connections');
    } catch (e) {
      _toast(_message(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addCredential() async {
    if (_id == null) {
      try {
        await _ensureCreated();
      } catch (e) {
        _toast(_message(e), error: true);
        return;
      }
    }
    final name = TextEditingController();
    final key = TextEditingController();
    final value = TextEditingController();
    String type = 'secret';
    if (!mounted) return;
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add credential'),
        content: StatefulBuilder(
          builder: (context, setLocal) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Credential name', hintText: 'e.g. API Key')),
              TextField(controller: key, decoration: const InputDecoration(labelText: 'Credential key', hintText: 'e.g. api_key')),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'secret', child: Text('Secret')),
                  DropdownMenuItem(value: 'text', child: Text('Text')),
                  DropdownMenuItem(value: 'number', child: Text('Number')),
                ],
                onChanged: (value) => setLocal(() => type = value ?? 'secret'),
              ),
              TextField(
                controller: value,
                obscureText: type == 'secret',
                decoration: const InputDecoration(labelText: 'Value', hintText: 'Paste value provided by portal'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );
    if (saved == true && _id != null) {
      try {
        await _service.saveCredential(_id!, key: key.text.trim(), name: name.text.trim(), type: type, value: value.text);
        final fresh = await _service.getOne(_id!);
        setState(() => _apply(fresh));
        _toast('Credential saved');
      } catch (e) {
        _toast(_message(e), error: true);
      }
    }
    name.dispose();
    key.dispose();
    value.dispose();
  }

  void _addRow(String key) {
    setState(() {
      _rows(key).add({'name': '', 'value': '', 'valueType': 'static'});
    });
  }

  List<Widget> _kvList(List<Map<String, dynamic>> rows, String key, String nameHint, String valueHint) {
    return rows.asMap().entries.map((entry) {
      final row = entry.value;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SizedBox(
              width: 200,
              child: TextFormField(
                initialValue: row['name']?.toString() ?? '',
                decoration: InputDecoration(hintText: nameHint),
                onChanged: (value) => row['name'] = value,
              ),
            ),
            SizedBox(
              width: 240,
              child: TextFormField(
                initialValue: row['value']?.toString() ?? '',
                decoration: InputDecoration(hintText: valueHint),
                onChanged: (value) => row['value'] = value,
              ),
            ),
            SizedBox(
              width: 160,
              child: DropdownButtonFormField<String>(
                initialValue: row['valueType']?.toString() ?? 'static',
                items: const ['static', 'credential', 'system', 'custom']
                    .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                    .toList(),
                onChanged: (value) => setState(() => row['valueType'] = value),
              ),
            ),
            IconButton(onPressed: () => setState(() => rows.removeAt(entry.key)), icon: const Icon(Icons.close)),
          ],
        ),
      );
    }).toList();
  }

  Widget _dropdown(String label, String value, Map<String, String> options, ValueChanged<String> onChanged) {
    final selected = options.containsKey(value) ? value : options.keys.first;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: selected,
        decoration: InputDecoration(labelText: label),
        items: options.entries.map((entry) => DropdownMenuItem(value: entry.key, child: Text(entry.value))).toList(),
        onChanged: (next) {
          if (next != null) onChanged(next);
        },
      ),
    );
  }

  Widget _mini(String label, String value, ValueChanged<String> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        onChanged: onChanged,
      ),
    );
  }

  Widget _label(String title, String help) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: CRMTypography.captionBold),
          Text(help, style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context))),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _rows(String key) {
    final raw = _config[key];
    if (raw is List && raw.every((item) => item is Map<String, dynamic>)) {
      return raw.cast<Map<String, dynamic>>();
    }
    final normalized = <Map<String, dynamic>>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) normalized.add(Map<String, dynamic>.from(item));
      }
    }
    _config[key] = normalized;
    return normalized;
  }

  Map<String, dynamic> _asMap(dynamic value) => value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  void _toast(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: error ? CRMColors.danger : CRMColors.success));
  }

  String _message(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] != null) return data['message'].toString();
    }
    return error.toString();
  }

  String _defaultName(String provider) {
    switch (provider) {
      case '99acres':
        return '99acres';
      case 'magicbricks':
        return 'MagicBricks';
      case 'nobroker':
        return 'NoBroker';
      case 'housing':
        return 'Housing API';
      default:
        return 'Custom API';
    }
  }

  Map<String, dynamic> _emptyConfig() => {
        'authType': 'none',
        'method': 'GET',
        'url': '',
        'headers': <Map<String, dynamic>>[],
        'query': <Map<String, dynamic>>[],
        'bodyType': 'none',
        'bodyFields': <Map<String, dynamic>>[],
        'advancedBody': '',
        'pagination': {'type': 'none', 'maxPages': 5, 'maxRecords': 100, 'pageParam': 'page', 'pageSizeParam': 'limit', 'startPage': 1},
        'sync': {'strategy': 'last_sync', 'frequencyMinutes': 5, 'initialWindow': '24h', 'overlapMinutes': 2, 'maxRecords': 100, 'retryAttempts': 3, 'retryDelaySeconds': 30, 'enabled': false},
        'response': {'format': 'json', 'collectionPath': ''},
        'mappings': <Map<String, dynamic>>[],
        'duplicateStrategy': 'external_id_source',
      };
}
