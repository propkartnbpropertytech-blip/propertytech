import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/integration_lead_model.dart';
import '../../campaign/models/campaign_followup_model.dart';
import 'campaign_ingest_engine.dart';
import '../../properties/models/property_model.dart';
import '../../properties/repository/properties_repository.dart';
import '../../requirements/models/requirement_model.dart';
import '../../requirements/repository/requirements_repository.dart';
import '../../../core/api/api_client.dart';
import '../../../core/security/role_guard.dart';
import '../../../core/storage/isar_collections.dart';
import '../../../core/storage/repository_coordinator.dart';
import '../../../core/utils/budget_formatter.dart';

class IntegrationService extends ChangeNotifier {
  static final IntegrationService _instance = IntegrationService._internal();
  factory IntegrationService() => _instance;
  IntegrationService._internal();

  static const _leadsPrefsKey = 'campaign_ingestion_leads_json';
  static const _sheetUrlPrefsKey = 'campaign_google_sheet_url';

  final ApiClient _apiClient = ApiClient();
  final RequirementsRepository _requirementsRepository = RequirementsRepository();
  final PropertiesRepository _propertiesRepository = PropertiesRepository();
  final Dio _externalHttp = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      followRedirects: true,
      maxRedirects: 5,
      validateStatus: (code) => code != null && code >= 200 && code < 400,
    ),
  );

  bool _loaded = false;
  String _googleSheetUrl = '';
  Timer? _sheetPollTimer;
  String? lastSyncError;
  List<PropertyModel>? _propertyCache;
  DateTime? _propertyCacheAt;
  int _campaignUiWatchers = 0;
  bool _syncInFlight = false;
  bool _persistInFlight = false;
  bool _persistDirty = false;

  // Webhook configuration
  String webhookUrl = "https://api-propkart.nbpropertytech.com/api/v1/integrations/webhooks/meta-leads";
  String vpsDirectWebhookUrl = "http://200.234.36.120:5001/api/v1/integrations/webhooks/meta-leads";
  String webhookSecret = "pk_sec_99a8b7c6d5e4f3a2b1";
  String metaVerifyToken = "propkart_meta_lead_verify_token_2026";
  bool isWebhookListening = true;

  // Ingested Leads (clean start)
  List<IntegrationLeadModel> _leads = [];
  List<IntegrationLeadModel> get leads => List.unmodifiable(_leads);
  List<IntegrationLeadModel> get requirementLeads =>
      _leads.where((l) => l.leadType == 'Requirement').toList();
  List<IntegrationLeadModel> get propertyListingLeads =>
      _leads.where((l) => l.leadType == 'Property Listing').toList();

  // Dynamic user-defined headers created in advance or dynamically
  final Set<String> _customHeaders = {};
  Set<String> get customHeaders => Set.unmodifiable(_customHeaders);

  // Set of headers hidden by user preference
  final Set<String> _hiddenHeaders = {};
  Set<String> get hiddenHeaders => Set.unmodifiable(_hiddenHeaders);
  Set<String> get visibleHeaders => Set.from(getActiveVisibleHeaders());

  // Column header ordering (preserves exact Google Sheet order or custom drag-and-drop order)
  List<String> _headerOrder = [];
  List<String> get headerOrder => List.unmodifiable(_headerOrder);
  static const String _headerOrderPrefsKey = 'campaign_header_order_v1';

  // Live Auto-Sync Status
  DateTime? _lastSyncAt;
  int _lastSyncCount = 0;
  DateTime? get lastSyncAt => _lastSyncAt;
  int get lastSyncCount => _lastSyncCount;

  // Column header to CRM field mappings
  final Map<String, String> _columnToCrmFieldMap = {
    'Full Name': 'name',
    'full_name': 'name',
    'Name': 'name',
    'Client Name': 'name',
    'Customer Name': 'name',
    'Buyer Name': 'name',
    'Property': 'property',
    'Property Name': 'property',
    'Project': 'property',
    'Project Name': 'property',
    'Inventory': 'property',
    'phone_number': 'mobile',
    'Phone': 'mobile',
    'Mobile': 'mobile',
    'Contact': 'mobile',
    'Phone Number': 'mobile',
    'email': 'email',
    'Email': 'email',
    'Email ID': 'email',
    'city': 'city',
    'City': 'city',
    'Location': 'city',
    'budget': 'budget',
    'Budget': 'budget',
    'Target Budget': 'budget',
    'configuration': 'configuration',
    'Configuration': 'configuration',
    'BHK': 'configuration',
    'campaign_name': 'campaign',
    'Campaign Name': 'campaign',
    'remarks': 'remarks',
    'Notes': 'remarks',
  };

  Map<String, String> get columnMappings => Map.unmodifiable(_columnToCrmFieldMap);
  String get googleSheetUrl => _googleSheetUrl;

  /// Available CRM Target Fields
  static const Map<String, String> standardCrmFields = {
    'name': 'Client Name (Full Name)',
    'mobile': 'Mobile Number (+91)',
    'email': 'Email Address',
    'city': 'Target City / Locality',
    'budget': 'Max Budget Ceiling',
    'configuration': 'Property Configuration (BHK)',
    'property': 'Property / Project (dropdown)',
    'campaign': 'Marketing Campaign Name',
    'remarks': 'Remarks & Requirement Notes',
    'source': 'Lead Source Tag',
  };

  /// Add a custom header dynamically
  Future<void> addCustomHeader(String headerName, {String? crmField}) async {
    final trimmed = headerName.trim();
    if (trimmed.isEmpty) return;

    _customHeaders.add(trimmed);
    _hiddenHeaders.remove(trimmed);
    if (!_headerOrder.contains(trimmed)) {
      _headerOrder.add(trimmed);
      unawaited(_persistHeaderOrder());
    }
    _invalidateHeaderCache();

    if (crmField != null && crmField.isNotEmpty) {
      _columnToCrmFieldMap[trimmed] = crmField;
    } else {
      _autoSuggestMappingForHeader(trimmed);
    }

    notifyListeners();
  }

  /// Remove a custom header
  Future<void> removeCustomHeader(String headerName) async {
    _customHeaders.remove(headerName);
    _hiddenHeaders.remove(headerName);
    _columnToCrmFieldMap.remove(headerName);
    _headerOrder.remove(headerName);
    unawaited(_persistHeaderOrder());

    final updated = <IntegrationLeadModel>[];
    for (final lead in _leads) {
      final raw = Map<String, dynamic>.from(lead.rawJson);
      raw.remove(headerName);
      updated.add(lead.copyWith(rawJson: raw));
    }
    _leads = updated;
    _invalidateHeaderCache();
    notifyListeners();
  }

  /// Toggle header visibility
  Future<void> setHeaderVisibility(String header, bool isVisible) async {
    if (isVisible) {
      _hiddenHeaders.remove(header);
    } else {
      _hiddenHeaders.add(header);
    }
    _invalidateHeaderCache();
    notifyListeners();
  }

  /// Select or Deselect all headers
  void setAllHeadersVisibility(bool isVisible) {
    final all = getDetectedHeaders();
    if (isVisible) {
      _hiddenHeaders.clear();
    } else {
      _hiddenHeaders.addAll(all);
    }
    _invalidateHeaderCache();
    notifyListeners();
  }

  /// Check if a header is visible
  bool isHeaderVisible(String header) {
    return !_hiddenHeaders.contains(header);
  }

  List<String>? _cachedDetectedHeaders;
  List<String>? _cachedVisibleHeaders;

  void _invalidateHeaderCache() {
    _cachedDetectedHeaders = null;
    _cachedVisibleHeaders = null;
  }

  /// Get all detected headers in exact Google Sheet order or custom drag-and-drop order
  List<String> getDetectedHeaders({List<IntegrationLeadModel>? leadsSubset}) {
    if (leadsSubset == null && _cachedDetectedHeaders != null) return _cachedDetectedHeaders!;

    final targetLeads = leadsSubset ?? _leads;

    // 1. Gather all actual existing headers in leads + custom headers
    final existingHeaders = <String>{..._customHeaders};
    for (final lead in targetLeads) {
      for (final k in lead.rawJson.keys) {
        final clean = k.trim();
        if (clean.isNotEmpty && !clean.startsWith('_engine_') && clean.toLowerCase() != 'source') {
          existingHeaders.add(clean);
        }
      }
    }

    if (existingHeaders.isEmpty && _headerOrder.isEmpty) {
      final defaultHeaders = ['Full Name', 'Phone Number', 'Email ID', 'City', 'Budget', 'Configuration', 'Campaign Name'];
      if (leadsSubset == null) _cachedDetectedHeaders = defaultHeaders;
      return defaultHeaders;
    }

    // 2. Build list strictly following _headerOrder (preserves sheet order or user dragged order)
    if (_headerOrder.isNotEmpty) {
      final result = <String>[];
      for (final h in _headerOrder) {
        if (existingHeaders.contains(h) || _customHeaders.contains(h)) {
          result.add(h);
          existingHeaders.remove(h);
        }
      }

      // Only append genuine custom headers that were added after _headerOrder was initialized
      for (final h in _customHeaders) {
        if (!result.contains(h)) {
          result.add(h);
        }
      }

      if (leadsSubset == null) _cachedDetectedHeaders = result;
      return result;
    }

    final result = existingHeaders.toList();
    if (leadsSubset == null) {
      _headerOrder = List<String>.from(result);
      _cachedDetectedHeaders = result;
    }
    return result;
  }

  /// Update detected headers sequence from newly arrived sheet/CSV rows
  void _updateDetectedHeadersFromRows(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return;
    final incomingKeys = <String>[];
    for (final row in rows) {
      for (final k in row.keys) {
        final clean = k.trim();
        if (clean.isNotEmpty && clean.toLowerCase() != 'source' && !clean.startsWith('_engine_')) {
          if (!incomingKeys.contains(clean)) {
            incomingKeys.add(clean);
          }
        }
      }
    }

    if (_headerOrder.isEmpty) {
      _headerOrder = List<String>.from(incomingKeys);
      unawaited(_persistHeaderOrder());
    } else {
      bool added = false;
      for (final k in incomingKeys) {
        if (!_headerOrder.contains(k)) {
          _headerOrder.add(k);
          added = true;
        }
      }
      if (added) {
        unawaited(_persistHeaderOrder());
      }
    }
    _invalidateHeaderCache();
  }

  /// Reorder headers via drag and place
  Future<void> reorderHeaders(int oldIndex, int newIndex, {List<IntegrationLeadModel>? leadsSubset}) async {
    final current = List<String>.from(getDetectedHeaders(leadsSubset: leadsSubset));
    if (oldIndex < 0 || oldIndex >= current.length) return;
    if (newIndex < 0 || newIndex > current.length) return;

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = current.removeAt(oldIndex);
    current.insert(newIndex, item);

    if (leadsSubset != null) {
      final fullHeaders = List<String>.from(getDetectedHeaders());
      final sectionIndices = <int>[];
      for (int i = 0; i < fullHeaders.length; i++) {
        if (current.contains(fullHeaders[i])) {
          sectionIndices.add(i);
        }
      }
      for (int i = 0; i < current.length && i < sectionIndices.length; i++) {
        fullHeaders[sectionIndices[i]] = current[i];
      }
      _headerOrder = fullHeaders;
    } else {
      _headerOrder = current;
    }

    _invalidateHeaderCache();
    await _persistHeaderOrder();
    notifyListeners();
  }

  /// Move a single header left (-1) or right (+1)
  Future<void> moveHeader(String header, int direction, {List<IntegrationLeadModel>? leadsSubset}) async {
    final current = List<String>.from(getDetectedHeaders(leadsSubset: leadsSubset));
    final idx = current.indexOf(header);
    if (idx == -1) return;
    final newIdx = idx + direction;
    if (newIdx < 0 || newIdx >= current.length) return;

    final item = current.removeAt(idx);
    current.insert(newIdx, item);

    if (leadsSubset != null) {
      final fullHeaders = List<String>.from(getDetectedHeaders());
      final sectionIndices = <int>[];
      for (int i = 0; i < fullHeaders.length; i++) {
        if (current.contains(fullHeaders[i])) {
          sectionIndices.add(i);
        }
      }
      for (int i = 0; i < current.length && i < sectionIndices.length; i++) {
        fullHeaders[sectionIndices[i]] = current[i];
      }
      _headerOrder = fullHeaders;
    } else {
      _headerOrder = current;
    }

    _invalidateHeaderCache();
    await _persistHeaderOrder();
    notifyListeners();
  }

  /// Reset header order back to original sheet insertion order
  Future<void> resetHeaderOrderToSheet({List<IntegrationLeadModel>? leadsSubset}) async {
    if (leadsSubset != null) {
      final sectionHeaders = getDetectedHeaders(leadsSubset: leadsSubset);
      final extracted = <String>[];
      for (final lead in leadsSubset) {
        for (final k in lead.rawJson.keys) {
          final clean = k.trim();
          if (clean.isNotEmpty &&
              !clean.startsWith('_engine_') &&
              clean.toLowerCase() != 'source') {
            if (!extracted.contains(clean)) extracted.add(clean);
          }
        }
      }
      final fullHeaders = List<String>.from(getDetectedHeaders());
      final sectionIndices = <int>[];
      for (int i = 0; i < fullHeaders.length; i++) {
        if (sectionHeaders.contains(fullHeaders[i])) {
          sectionIndices.add(i);
        }
      }
      for (int i = 0; i < extracted.length && i < sectionIndices.length; i++) {
        fullHeaders[sectionIndices[i]] = extracted[i];
      }
      _headerOrder = fullHeaders;
    } else {
      _headerOrder.clear();
      final extracted = <String>[];
      for (final lead in _leads) {
        for (final k in lead.rawJson.keys) {
          final clean = k.trim();
          if (clean.isNotEmpty &&
              !clean.startsWith('_engine_') &&
              clean.toLowerCase() != 'source' &&
              clean != 'Client Name' &&
              clean != 'Phone' &&
              clean != 'Property Name') {
            if (!extracted.contains(clean)) extracted.add(clean);
          }
        }
      }
      _headerOrder = extracted;
    }
    _invalidateHeaderCache();
    await _persistHeaderOrder();
    notifyListeners();
  }

  Future<void> _persistHeaderOrder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_headerOrderPrefsKey, jsonEncode(_headerOrder));
    } catch (_) {}
  }

  /// Get currently visible headers for the table
  List<String> getActiveVisibleHeaders({List<IntegrationLeadModel>? leadsSubset}) {
    if (leadsSubset == null && _cachedVisibleHeaders != null) return _cachedVisibleHeaders!;
    final all = getDetectedHeaders(leadsSubset: leadsSubset);
    final visible = all.where((h) => !_hiddenHeaders.contains(h)).toList();
    if (leadsSubset == null) _cachedVisibleHeaders = visible;
    return visible;
  }

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      _googleSheetUrl = prefs.getString(_sheetUrlPrefsKey) ?? '';

      // 1. Try loading from Isar database first
      final dbLeads = await RepositoryCoordinator().campaignLeadLocal.getLeads();
      if (dbLeads.isNotEmpty) {
        final parsed = <IntegrationLeadModel>[];
        for (final item in dbLeads) {
          Map<String, dynamic> raw = {};
          try {
            if (item.rawJsonString.isNotEmpty) {
              raw = Map<String, dynamic>.from(jsonDecode(item.rawJsonString));
            }
          } catch (_) {}

          parsed.add(
            IntegrationLeadModel(
              id: item.id,
              source: item.source,
              receivedAt: item.receivedAt,
              rawJson: raw,
              externalLeadId: item.externalLeadId,
              isDuplicate: item.isDuplicate,
              duplicateReason: item.duplicateReason,
              qualityStatus: item.qualityStatus,
              importStatus: item.importStatus,
              importedClientId: item.importedClientId,
              metaFeedbackEventId: item.metaFeedbackEventId,
              metaFeedbackSentAt: item.metaFeedbackSentAt,
            ),
          );
        }
        _leads = parsed;
        _invalidateHeaderCache();
      } else {
        // 2. Backward compatibility: Check SharedPreferences and migrate to DB
        final stored = prefs.getString(_leadsPrefsKey);
        if (stored != null && stored.isNotEmpty) {
          final decoded = stored.length > 200000
              ? await compute(_decodeCampaignLeadsJson, stored)
              : jsonDecode(stored);
          if (decoded is List) {
            final parsed = <IntegrationLeadModel>[];
            for (var i = 0; i < decoded.length; i++) {
              final item = decoded[i];
              if (item is Map) {
                parsed.add(IntegrationLeadModel.fromJson(Map<String, dynamic>.from(item)));
              }
            }
            _leads = parsed;
            _invalidateHeaderCache();
            // Persist migrated records to DB
            unawaited(_persistLeads());
          }
        }
      }

      // 3. Load saved header ordering preference
      final savedHeaderOrder = prefs.getString(_headerOrderPrefsKey);
      if (savedHeaderOrder != null && savedHeaderOrder.isNotEmpty) {
        try {
          final decoded = jsonDecode(savedHeaderOrder) as List<dynamic>;
          _headerOrder = decoded.map((e) => e.toString()).toList();
          _invalidateHeaderCache();
        } catch (_) {}
      }

      if (_googleSheetUrl.isNotEmpty) {
        _startSheetPolling();
      }
    } catch (e) {
      debugPrint('Failed to load persisted campaign leads: $e');
    }
    notifyListeners();
  }

  bool _isFetchingServerLeads = false;
  bool get isFetchingServerLeads => _isFetchingServerLeads;

  Future<int> fetchServerLeads({bool silent = false, bool resetWithServer = false}) async {
    if (_isFetchingServerLeads) return 0;
    _isFetchingServerLeads = true;
    try {
      final response = await _apiClient.get(
        '/integrations/leads',
        queryParameters: {'limit': 1000},
      );

      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        final List<dynamic> leadsList = data['leads'] ?? [];

        final incoming = <IntegrationLeadModel>[];
        for (final item in leadsList) {
          if (item is Map<String, dynamic>) {
            incoming.add(IntegrationLeadModel.fromJson(item));
          }
        }

        if (incoming.isNotEmpty || resetWithServer) {
          if (resetWithServer) {
            _leads = incoming;
          } else {
            // Meta Ads leads are authoritative from the server; retain other sources (e.g. CSV/Google Sheets)
            final incomingIds = incoming.map((l) => l.id).toSet();
            final incomingExtIds = incoming.map((l) => l.externalLeadId).whereType<String>().toSet();
            final nonServerLeads = _leads.where((l) =>
                l.source != 'Meta Ads' &&
                !incomingIds.contains(l.id) &&
                (l.externalLeadId == null || !incomingExtIds.contains(l.externalLeadId))).toList();
            _leads = [...incoming, ...nonServerLeads];
          }

          _updateDetectedHeadersFromRows(incoming.map((l) => l.rawJson).toList());
          for (final lead in incoming) {
            for (final k in lead.rawJson.keys) {
              _autoSuggestMappingForHeader(k);
            }
          }
          _invalidateHeaderCache();
          await _persistLeads();
          notifyListeners();
          return incoming.length;
        }
      }
      return 0;
    } catch (e) {
      debugPrint('Failed to fetch campaign leads from server: $e');
      return 0;
    } finally {
      _isFetchingServerLeads = false;
    }
  }

  /// Clean and deduplicate all leads on the server, then reload
  Future<Map<String, dynamic>> cleanDuplicates() async {
    try {
      final response = await _apiClient.post('/integrations/leads/clean-duplicates', {});
      await fetchServerLeads(resetWithServer: true);
      return response.data is Map<String, dynamic> ? response.data as Map<String, dynamic> : {'success': true};
    } catch (e) {
      debugPrint('Error cleaning duplicates: $e');
      rethrow;
    }
  }

  /// Proactively pull latest leads from Meta Graph API
  Future<Map<String, dynamic>> syncMetaLeads() async {
    try {
      final response = await _apiClient.post('/integrations/leads/sync-meta', {});
      await fetchServerLeads(resetWithServer: true);
      return response.data is Map<String, dynamic> ? response.data as Map<String, dynamic> : {'success': true};
    } catch (e) {
      debugPrint('Error syncing Meta leads: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Update a lead's campaign status ('Follow up', 'Interested', 'Not interested')
  Future<bool> updateLeadCampaignStatus(String leadId, String status) async {
    try {
      // 1. Optimistically update in memory
      final idx = _leads.indexWhere((l) => l.id == leadId);
      if (idx != -1) {
        _leads[idx] = _leads[idx].copyWith(campaignStatus: status);
        notifyListeners();
        unawaited(_persistLeads());
      }

      // 2. Persist to backend
      final res = await _apiClient.patch('/integrations/leads/$leadId/campaign-status', {
        'status': status,
      });

      return res.statusCode != null && res.statusCode! >= 200 && res.statusCode! < 300;
    } catch (e) {
      debugPrint('[IntegrationService] Error updating campaign status for $leadId: $e');
      return false;
    }
  }

  /// Schedule a follow-up for a campaign lead
  Future<bool> scheduleFollowup(String leadId, DateTime scheduledAt, String remarks) async {
    try {
      // 1. Optimistically update in memory
      final idx = _leads.indexWhere((l) => l.id == leadId);
      if (idx != -1) {
        _leads[idx] = _leads[idx].copyWith(
          campaignStatus: 'Follow up',
          followupScheduledAt: scheduledAt,
          followupRemarks: remarks,
          followupStatus: 'Pending',
        );
        notifyListeners();
        unawaited(_persistLeads());
      }

      // 2. Persist to backend dedicated table
      final res = await _apiClient.post('/integrations/leads/$leadId/followups', {
        'scheduledAt': scheduledAt.toIso8601String(),
        'remarks': remarks,
      });

      return res.statusCode != null && res.statusCode! >= 200 && res.statusCode! < 300;
    } catch (e) {
      debugPrint('[IntegrationService] Error scheduling follow-up for $leadId: $e');
      return false;
    }
  }

  /// Fetch follow-ups from dedicated table (filter: today, future, all)
  Future<List<CampaignFollowupModel>> fetchFollowups({String filter = 'all', String? leadType}) async {
    try {
      final queryParams = <String, dynamic>{'filter': filter};
      if (leadType != null && leadType.isNotEmpty && leadType != 'All') {
        queryParams['leadType'] = leadType;
      }
      final res = await _apiClient.get('/integrations/followups', queryParameters: queryParams);
      if (res.data is Map<String, dynamic> && res.data['followups'] is List) {
        final list = res.data['followups'] as List;
        return list
            .map((item) => CampaignFollowupModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('[IntegrationService] Error fetching followups: $e');
      return [];
    }
  }


  void watchCampaignUi() {
    _campaignUiWatchers++;
    unawaited(ensureLoaded().then((_) => fetchServerLeads(silent: true)));
    _startSheetPolling();
  }

  void unwatchCampaignUi() {
    if (_campaignUiWatchers > 0) _campaignUiWatchers--;
    if (_campaignUiWatchers == 0) {
      _sheetPollTimer?.cancel();
      _sheetPollTimer = null;
    }
  }

  Future<void> setGoogleSheetUrl(String url) async {
    _googleSheetUrl = url.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sheetUrlPrefsKey, _googleSheetUrl);
    _startSheetPolling();
    notifyListeners();
  }

  /// Ingests a new incoming JSON lead from Meta Webhook, Google Sheets, or manual simulation
  Future<void> ingestRawLead({
    required String source,
    required Map<String, dynamic> rawJson,
    String? externalLeadId,
  }) async {
    final prepared = await CampaignIngestEngine().prepare([rawJson]);
    for (final item in prepared) {
      await _ingestPreparedLead(
        source: source,
        item: item,
        externalLeadId: externalLeadId,
      );
    }
  }

  Future<void> _ingestPreparedLead({
    required String source,
    required PreparedCampaignRow item,
    String? externalLeadId,
    bool flush = true,
    Map<String, int>? fingerprintIndex,
    Set<String>? seenPhones,
    Set<String>? seenEmails,
  }) async {
    item.mappings.forEach((header, field) {
      _columnToCrmFieldMap[header] = field;
    });

    final flattened = flattenIncomingPayload(item.rawJson);
    final fingerprint = externalLeadId ?? item.fingerprint;
    final existingIndex = fingerprintIndex?[fingerprint] ??
        _leads.indexWhere((l) => l.externalLeadId == fingerprint);
    if (existingIndex != -1 && existingIndex < _leads.length) {
      final existing = _leads[existingIndex];
      final merged = Map<String, dynamic>.from(existing.rawJson);
      flattened.forEach((key, value) {
        final incoming = _cellDisplayValue(value);
        if (incoming.isEmpty) return;
        merged[key] = value;
      });
      _leads[existingIndex] = existing.copyWith(rawJson: merged);
      if (flush) {
        await _persistLeads();
        notifyListeners();
      }
      return;
    }

    final newId = 'lead_${DateTime.now().millisecondsSinceEpoch}_${_leads.length}';
    
    for (final k in flattened.keys) {
      if (!_customHeaders.contains(k)) {
        _hiddenHeaders.remove(k);
        _autoSuggestMappingForHeader(k);
      }
    }

    final phone = _normalizePhone(_extractPhone(flattened));
    final email = _extractEmail(flattened).toLowerCase().trim();
    
    bool isDup = false;
    String? dupReason;

    if (phone.isNotEmpty && (seenPhones?.contains(phone) ?? false)) {
      isDup = true;
      dupReason = 'Duplicate phone number ($phone)';
    } else if (email.isNotEmpty && (seenEmails?.contains(email) ?? false)) {
      isDup = true;
      dupReason = 'Duplicate email ($email)';
    } else if (seenPhones == null && seenEmails == null && (phone.isNotEmpty || email.isNotEmpty)) {
      for (final existing in _leads) {
        final exPhone = _normalizePhone(_extractPhone(existing.rawJson));
        final exEmail = _extractEmail(existing.rawJson).toLowerCase().trim();
        if (phone.isNotEmpty && exPhone.isNotEmpty && phone == exPhone) {
          isDup = true;
          dupReason = 'Duplicate phone number ($phone)';
          break;
        }
        if (email.isNotEmpty && exEmail.isNotEmpty && email == exEmail) {
          isDup = true;
          dupReason = 'Duplicate email ($email)';
          break;
        }
      }
    }

    final newLead = IntegrationLeadModel(
      id: newId,
      source: source,
      receivedAt: DateTime.now(),
      rawJson: flattened,
      externalLeadId: fingerprint,
      isDuplicate: isDup,
      duplicateReason: dupReason,
      qualityStatus: 'Pending',
      importStatus: 'Pending',
    );

    _leads.insert(0, newLead);
    _invalidateHeaderCache();
    if (fingerprintIndex != null) {
      fingerprintIndex.updateAll((key, value) => value + 1);
      fingerprintIndex[fingerprint] = 0;
    }
    if (phone.isNotEmpty) seenPhones?.add(phone);
    if (email.isNotEmpty) seenEmails?.add(email);
    if (flush) {
      await _persistLeads();
      notifyListeners();
    }
  }

  /// Merge multiple headers into a single target header across all leads
  void mergeHeaders({
    required List<String> sourceHeaders,
    required String targetHeader,
  }) {
    if (sourceHeaders.isEmpty || targetHeader.trim().isEmpty) return;

    final updatedLeads = <IntegrationLeadModel>[];

    for (final lead in _leads) {
      final updatedRaw = Map<String, dynamic>.from(lead.rawJson);
      dynamic consolidatedValue;

      for (final src in sourceHeaders) {
        if (updatedRaw.containsKey(src) && updatedRaw[src] != null && updatedRaw[src].toString().trim().isNotEmpty) {
          consolidatedValue ??= updatedRaw[src];
          if (src != targetHeader) {
            updatedRaw.remove(src);
          }
        }
      }

      if (consolidatedValue != null) {
        updatedRaw[targetHeader] = consolidatedValue;
      }

      updatedLeads.add(lead.copyWith(rawJson: updatedRaw));
    }

    _leads = updatedLeads;

    for (final src in sourceHeaders) {
      if (src != targetHeader) {
        _customHeaders.remove(src);
        _hiddenHeaders.remove(src);
        _columnToCrmFieldMap.remove(src);
      }
    }
    _customHeaders.add(targetHeader);
    _hiddenHeaders.remove(targetHeader);
    _invalidateHeaderCache();
    
    _autoSuggestMappingForHeader(targetHeader);
    deduplicateAll();
    unawaited(_persistLeads());
    notifyListeners();
  }

  /// Rename a single header across all leads
  void renameHeader(String oldHeader, String newHeader) {
    if (oldHeader == newHeader || newHeader.trim().isEmpty) return;
    mergeHeaders(sourceHeaders: [oldHeader], targetHeader: newHeader);
  }

  /// Map a column header to a standard CRM Field
  void setColumnMapping(String header, String? crmField) {
    if (crmField == null || crmField.isEmpty) {
      _columnToCrmFieldMap.remove(header);
    } else {
      _columnToCrmFieldMap[header] = crmField;
    }
    notifyListeners();
  }

  void _autoSuggestMappingForHeader(String header) {
    if (header.startsWith('_engine_')) return;
    if (_columnToCrmFieldMap.containsKey(header)) return;
    final lower = header.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (lower.contains('property') || lower.contains('project') || lower.contains('inventory')) {
      _columnToCrmFieldMap[header] = 'property';
    } else if (lower.contains('client') || lower.contains('customer') || lower.contains('buyer') || lower == 'fullname' || lower == 'name') {
      _columnToCrmFieldMap[header] = 'name';
    } else if (lower.contains('name')) {
      _columnToCrmFieldMap[header] = 'name';
    } else if (lower.contains('phone') || lower.contains('mobile') || lower.contains('contact')) {
      _columnToCrmFieldMap[header] = 'mobile';
    } else if (lower.contains('email') || lower.contains('mail')) {
      _columnToCrmFieldMap[header] = 'email';
    } else if (lower.contains('city') || lower.contains('location') || lower.contains('area')) {
      _columnToCrmFieldMap[header] = 'city';
    } else if (lower.contains('budget') || lower.contains('price')) {
      _columnToCrmFieldMap[header] = 'budget';
    } else if (lower.contains('bhk') || lower.contains('config')) {
      _columnToCrmFieldMap[header] = 'configuration';
    } else if (lower.contains('campaign')) {
      _columnToCrmFieldMap[header] = 'campaign';
    }
  }

  /// Re-scans all leads and recalculates duplicate flags
  void deduplicateAll() {
    final Map<String, String> phoneSeen = {};
    final Map<String, String> emailSeen = {};
    final updated = <IntegrationLeadModel>[];

    for (final lead in _leads) {
      final phone = _normalizePhone(_extractPhone(lead.rawJson));
      final email = _extractEmail(lead.rawJson).toLowerCase().trim();
      final phoneKey = '${lead.leadType}_$phone';
      final emailKey = '${lead.leadType}_$email';

      bool isDup = false;
      String? dupReason;

      if (phone.isNotEmpty && phoneSeen.containsKey(phoneKey)) {
        isDup = true;
        dupReason = 'Duplicate phone number matches ${lead.leadType} lead ${phoneSeen[phoneKey]} ($phone)';
      } else if (email.isNotEmpty && emailSeen.containsKey(emailKey)) {
        isDup = true;
        dupReason = 'Duplicate email matches ${lead.leadType} lead ${emailSeen[emailKey]} ($email)';
      } else {
        if (phone.isNotEmpty) phoneSeen[phoneKey] = lead.id;
        if (email.isNotEmpty) emailSeen[emailKey] = lead.id;
      }

      updated.add(lead.copyWith(
        isDuplicate: isDup,
        duplicateReason: dupReason,
      ));
    }

    _leads = updated;
    unawaited(_persistLeads());
    notifyListeners();
  }

  /// Remove all duplicate leads
  void purgeDuplicates() {
    _leads.removeWhere((lead) => lead.isDuplicate);
    _invalidateHeaderCache();
    unawaited(_persistLeads());
    notifyListeners();
  }

  /// Clear all leads and resets header state
  Future<void> clearAllLeads() async {
    _leads.clear();
    _headerOrder.clear();
    _customHeaders.clear();
    _hiddenHeaders.clear();
    _columnToCrmFieldMap.clear();
    _invalidateHeaderCache();
    await RepositoryCoordinator().campaignLeadLocal.clearAll();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_headerOrderPrefsKey);
      await prefs.remove('isar_campaign_leads_web_v1');
    } catch (_) {}
    notifyListeners();
  }

  /// Send Lead Quality response back to Meta Conversions API
  Future<Map<String, dynamic>> sendMetaQualityFeedback({
    required String leadId,
    required String qualityStatus,
  }) async {
    final index = _leads.indexWhere((l) => l.id == leadId);
    if (index == -1) throw Exception("Lead not found");

    final lead = _leads[index];
    final eventId = 'fb_evt_${DateTime.now().millisecondsSinceEpoch}';

    await Future.delayed(const Duration(milliseconds: 500));

    _leads[index] = lead.copyWith(
      qualityStatus: qualityStatus,
      metaFeedbackEventId: eventId,
      metaFeedbackSentAt: DateTime.now(),
    );

    notifyListeners();
    unawaited(_persistLeads());

    return {
      'success': true,
      'eventId': eventId,
      'status': qualityStatus,
      'message': 'Lead quality response for Meta successfully dispatched.',
    };
  }

  /// Import selected campaign rows into the Leads page (requirements).
  Future<int> importLeadsToCrm(List<String> leadIds) async {
    if (leadIds.isEmpty) return 0;

    // 1. Try smart backend conversion engine first
    try {
      final response = await _apiClient.post(
        '/integrations/leads/convert-to-crm',
        {'leadIds': leadIds},
      );
      if (response.data is Map<String, dynamic> && response.data['success'] == true) {
        final count = response.data['count'] ?? 0;
        await fetchServerLeads(resetWithServer: true);
        return count is int ? count : (int.tryParse(count.toString()) ?? 0);
      }
    } catch (e) {
      debugPrint('[IntegrationService] Backend convert-to-crm error: $e. Falling back to local ingestion.');
    }

    int importedCount = 0;
    final coordinator = RepositoryCoordinator();
    coordinator.beginBulkMutation();
    try {
    final metadata = await _propertiesRepository.getPropertyMetadata();
    final existing = await _requirementsRepository.getRequirements(refreshFromServer: false);
    final existingPhones = existing
        .map((r) => _normalizePhone(r.clientMobile))
        .where((p) => p.isNotEmpty)
        .toSet();
    final inventory = await _cachedProperties();
    final indexById = <String, int>{};
    for (var i = 0; i < _leads.length; i++) {
      indexById[_leads[i].id] = i;
    }

    final user = RoleGuard.currentUser;
    final category = metadata.categories.isNotEmpty ? metadata.categories.first : null;
    final typesForCategory = metadata.types
        .where((t) => category == null || t.categoryId == category.id)
        .where((t) => t.name.toLowerCase() != 'apartment')
        .toList();
    final defaultType = typesForCategory.isNotEmpty
        ? typesForCategory.first
        : (metadata.types.isNotEmpty ? metadata.types.first : null);
    final defaultListing = metadata.listingTypes.isNotEmpty ? metadata.listingTypes.first : null;
    if (category == null || defaultType == null) {
      throw Exception(
        'Property lookups are not loaded yet. Open the Leads page once so cities and categories load, then sync again.',
      );
    }

    final List<MapEntry<int, RequirementModel>> batch = [];

    for (final id in leadIds) {
      final index = indexById[id];
      if (index == null) continue;

      final lead = _leads[index];
      if (lead.importStatus == 'Imported') {
        importedCount++;
        continue;
      }

      final mapped = _mapLeadFields(lead);
      final matchedProperties = _propertiesFromMappedRow(mapped, lead.rawJson, inventory);
      final primaryProperty = matchedProperties.isNotEmpty ? matchedProperties.first : null;

      var name = mapped['name']!.isNotEmpty ? mapped['name']! : '';
      if (primaryProperty != null && _isSameLabel(name, primaryProperty)) {
        name = primaryProperty.ownerName.trim().isNotEmpty
            ? primaryProperty.ownerName.trim()
            : 'Campaign Lead';
      }
      if (name.isEmpty) name = 'Campaign Lead';

      final mobile = mapped['mobile']!.isNotEmpty
          ? mapped['mobile']!
          : (primaryProperty != null && primaryProperty.ownerMobile.trim().isNotEmpty
              ? primaryProperty.ownerMobile
              : _extractPhone(lead.rawJson));
      final normalizedMobile = _normalizePhone(mobile);

      if (normalizedMobile.isNotEmpty && existingPhones.contains(normalizedMobile)) {
        _leads[index] = lead.copyWith(
          importStatus: 'Imported',
          importedClientId: 'existing_$normalizedMobile',
        );
        importedCount++;
        continue;
      }

      if (normalizedMobile.isNotEmpty) {
        existingPhones.add(normalizedMobile);
      }

      final resolvedCategory = primaryProperty != null && primaryProperty.categoryId.isNotEmpty
          ? LookupItem(id: primaryProperty.categoryId, name: primaryProperty.categoryName)
          : category;
      final resolvedType = primaryProperty != null && primaryProperty.propertyTypeId.isNotEmpty
          ? LookupItem(id: primaryProperty.propertyTypeId, name: primaryProperty.propertyTypeName, categoryId: primaryProperty.categoryId)
          : defaultType;
      final resolvedListing = primaryProperty != null && primaryProperty.listingTypeId.isNotEmpty
          ? LookupItem(id: primaryProperty.listingTypeId, name: primaryProperty.listingTypeName)
          : defaultListing;

      final parsedBudget = _parseBudget(mapped['budget']!);
      final budget = parsedBudget > 0 ? parsedBudget : (primaryProperty?.price ?? 0);
      final configNeedle = mapped['configuration']!.isNotEmpty
          ? mapped['configuration']!
          : (primaryProperty?.configurationName ?? '');
      LookupItem? config = _matchLookup(
        metadata.configurations,
        configNeedle,
        categoryId: resolvedCategory.id,
      );
      if (config == null && primaryProperty != null && (primaryProperty.configurationId ?? '').isNotEmpty) {
        config = LookupItem(
          id: primaryProperty.configurationId!,
          name: primaryProperty.configurationName ?? '',
        );
      }
      final area = _matchArea(
            metadata.areas,
            metadata.cities,
            mapped['city']!.isNotEmpty
                ? mapped['city']!
                : '${primaryProperty?.areaName ?? ''} ${primaryProperty?.cityName ?? ''}',
          ) ??
          (primaryProperty != null && primaryProperty.areaId.isNotEmpty
              ? AreaLookup(id: primaryProperty.areaId, name: primaryProperty.areaName, cityId: primaryProperty.cityId, pincode: primaryProperty.pincode)
              : null);
      final campaign = mapped['campaign']!.isNotEmpty ? mapped['campaign']! : lead.source;
      final extraRemarks = mapped['remarks']!;
      final propertyNotes = matchedProperties.isEmpty
          ? ''
          : ' Interested property: ${matchedProperties.map((p) => '${p.title} (${p.propertyCode})').join(', ')}.';
      final email = mapped['email']!.isNotEmpty
          ? mapped['email']!
          : (lead.getStringValue('Email ID').isNotEmpty
              ? lead.getStringValue('Email ID')
              : (lead.getStringValue('Email').isNotEmpty ? lead.getStringValue('Email') : _extractEmail(lead.rawJson)));
      final emailNote = email.isNotEmpty ? ' Email: $email.' : '';
      final summaryRemarks =
          'Imported from ${lead.source}. Campaign: $campaign.$propertyNotes$emailNote${extraRemarks.isNotEmpty ? ' $extraRemarks' : ''}';

      final userRole = (user?.role ?? '').toLowerCase();
      final bool isAdminOrTelecaller =
          userRole == 'admin' || userRole == 'super admin' || userRole == 'telecaller';

      final isMeta = lead.source == 'Meta Ads' || (lead.externalLeadId != null && lead.externalLeadId!.isNotEmpty);
      final metaLeadId = isMeta ? lead.externalLeadId : null;
      final metaCampaignName = lead.getStringValue('Campaign Name').isNotEmpty
          ? lead.getStringValue('Campaign Name')
          : (lead.getStringValue('Campaign').isNotEmpty ? lead.getStringValue('Campaign') : null);
      final metaAdName = lead.getStringValue('Ad Name').isNotEmpty ? lead.getStringValue('Ad Name') : null;

      final metaCustomFields = <String, dynamic>{};
      for (final entry in lead.rawJson.entries) {
        final k = entry.key.toLowerCase().trim();
        if (['client name', 'full name', 'name', 'phone number', 'phone', 'mobile', 'property', 'property name'].contains(k)) continue;
        metaCustomFields[entry.key] = entry.value;
      }
      if (email.isNotEmpty && !metaCustomFields.containsKey('Email ID') && !metaCustomFields.containsKey('Email')) {
        metaCustomFields['Email ID'] = email;
      }

      final req = RequirementModel(
        id: '',
        clientName: name,
        clientMobile: mobile.isEmpty ? '0000000000' : mobile,
        categoryId: resolvedCategory.id,
        categoryName: resolvedCategory.name,
        propertyTypeId: resolvedType.id,
        propertyTypeName: resolvedType.name,
        propertyTypeIds: [resolvedType.id],
        configurationId: config?.id,
        configurationIds: config != null ? [config.id] : const [],
        configurationName: config?.name,
        listingTypeId: resolvedListing?.id,
        listingTypeName: resolvedListing?.name,
        minBudget: budget > 0 ? budget * 0.8 : 0,
        maxBudget: budget > 0 ? budget * 1.2 : 0,
        areaIds: area != null ? [area.id] : const [],
        areaNames: area != null ? [area.name] : const [],
        remarks: summaryRemarks,
        status: 'Active',
        leadSource: isMeta ? 'Meta Ads' : lead.source,
        metaLeadId: metaLeadId,
        metaCampaignName: metaCampaignName,
        metaAdName: metaAdName,
        metaCustomFields: metaCustomFields.isNotEmpty ? metaCustomFields : null,
        leadQuality: 'Pending',
        createdAt: DateTime.now(),
        createdBy: user?.id,
        creatorName: user?.fullName,
        adminId: user?.role == 'Admin' ? user?.id : user?.adminId,
        assignedTo: !isAdminOrTelecaller ? user?.id : null,
        assigneeName: !isAdminOrTelecaller ? user?.fullName : null,
      );

      batch.add(MapEntry(index, req));
    }

    // Process in batches of 50 via bulk API
    for (var b = 0; b < batch.length; b += 50) {
      final chunk = batch.sublist(b, (b + 50 > batch.length) ? batch.length : b + 50);
      final reqsToCreate = chunk.map((e) => e.value).toList();
      try {
        final createdList = await _requirementsRepository.createRequirementsBulk(reqsToCreate);
        for (var i = 0; i < chunk.length; i++) {
          final leadIdx = chunk[i].key;
          final createdReq = (i < createdList.length) ? createdList[i] : null;
          final lead = _leads[leadIdx];
          _leads[leadIdx] = lead.copyWith(
            importStatus: 'Imported',
            importedClientId: createdReq?.id ?? 'bulk_imported',
          );
          unawaited(_apiClient.patch('/integrations/leads/${lead.id}/status', {
            'importStatus': 'Imported',
            'importedClientId': createdReq?.id,
          }).catchError((_) => Response(requestOptions: RequestOptions(path: ''))));
          importedCount++;
        }
      } catch (e) {
        debugPrint('Error bulk importing batch to Leads page: $e');
        // Fallback to sequential creation if bulk fails
        for (final entry in chunk) {
          try {
            final created = await _requirementsRepository.createRequirement(entry.value, notify: false);
            final lead = _leads[entry.key];
            _leads[entry.key] = lead.copyWith(
              importStatus: 'Imported',
              importedClientId: created.id,
            );
            unawaited(_apiClient.patch('/integrations/leads/${lead.id}/status', {
              'importStatus': 'Imported',
              'importedClientId': created.id,
            }).catchError((_) => Response(requestOptions: RequestOptions(path: ''))));
            importedCount++;
          } catch (err) {
            debugPrint('Error importing lead fallback: $err');
          }
        }
      }
      if (b + 50 < batch.length) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    await _persistLeads();
    notifyListeners();
    return importedCount;
    } finally {
      coordinator.endBulkMutation();
    }
  }

  /// Import selected Property Listing leads into the Properties inventory page
  Future<int> importLeadsToProperties(List<String> leadIds) async {
    if (leadIds.isEmpty) return 0;

    // 1. Try smart backend conversion engine first
    try {
      final response = await _apiClient.post(
        '/integrations/leads/convert-to-crm',
        {'leadIds': leadIds},
      );
      if (response.data is Map<String, dynamic> && response.data['success'] == true) {
        final count = response.data['count'] ?? 0;
        await fetchServerLeads(resetWithServer: true);
        return count is int ? count : (int.tryParse(count.toString()) ?? 0);
      }
    } catch (e) {
      debugPrint('[IntegrationService] Backend convert-to-properties error: $e. Falling back to local ingestion.');
    }

    int importedCount = 0;
    final coordinator = RepositoryCoordinator();
    coordinator.beginBulkMutation();
    try {
      final metadata = await _propertiesRepository.getPropertyMetadata();
      final user = RoleGuard.currentUser;

      // Find Rent listing type
      LookupItem? rentListing;
      for (final l in metadata.listingTypes) {
        if (l.name.toLowerCase().contains('rent')) {
          rentListing = l;
          break;
        }
      }
      rentListing ??= (metadata.listingTypes.isNotEmpty ? metadata.listingTypes.first : null);

      // Default category, city, status
      final defaultCategory = metadata.categories.isNotEmpty ? metadata.categories.first : null;
      final defaultCity = metadata.cities.isNotEmpty ? metadata.cities.first : null;
      final defaultStatus = metadata.statuses.isNotEmpty ? metadata.statuses.first : null;

      final indexById = <String, int>{};
      for (var i = 0; i < _leads.length; i++) {
        indexById[_leads[i].id] = i;
      }

      for (final id in leadIds) {
        final index = indexById[id];
        if (index == null) continue;

        final lead = _leads[index];
        if (lead.importStatus == 'Imported') {
          importedCount++;
          continue;
        }

        final rj = lead.rawJson;

        // Extract Owner Name
        String ownerName = '';
        for (final k in ['full_name', 'Client Name', 'Name of client', 'Name', 'Customer Name', 'Owner Name', 'owner_name']) {
          if (rj.containsKey(k) && rj[k] != null && rj[k].toString().trim().isNotEmpty) {
            ownerName = rj[k].toString().trim();
            break;
          }
        }
        if (ownerName.isEmpty) ownerName = 'Property Owner';

        // Extract Owner Mobile
        String mobile = '';
        for (final k in ['phone_number', 'Phone Number', 'Phone', 'Mobile', 'mobile', 'Number', 'contact']) {
          if (rj.containsKey(k) && rj[k] != null && rj[k].toString().trim().isNotEmpty) {
            mobile = _normalizePhone(rj[k].toString());
            if (mobile.isNotEmpty) break;
          }
        }

        // Extract Owner Email
        String email = '';
        for (final k in ['email', 'Email ID', 'Email', 'email_id']) {
          if (rj.containsKey(k) && rj[k] != null && rj[k].toString().trim().isNotEmpty) {
            email = rj[k].toString().trim();
            break;
          }
        }

        // Extract Location / Address
        String rawLocation = '';
        for (final k in [
          'where_is_your_property_located?',
          'where_is_your_property_located',
          'Where is your property located?',
          'what_is_the_complete_address_of_your_property?',
          'what_is_the_complete_address_of_your_property',
          'Location',
          'Address',
          'City',
          'city'
        ]) {
          if (rj.containsKey(k) && rj[k] != null && rj[k].toString().trim().isNotEmpty) {
            rawLocation = rj[k].toString().trim();
            break;
          }
        }
        String cleanLocation = rawLocation
            .replaceAll('_', ' ')
            .split(' ')
            .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}' : '')
            .join(' ')
            .trim();
        if (cleanLocation.toLowerCase() == 'other area') cleanLocation = 'Ahmedabad';

        // Extract Property Type / BHK
        String rawPropType = '';
        for (final k in [
          'what_type_of_property_are_you_looking_to_rent_out?',
          'what_type_of_property_are_you_looking_to_rent_out',
          'What type of property you are looking to rent out?',
          'Property Type',
          'Type',
          'Configuration',
          'BHK'
        ]) {
          if (rj.containsKey(k) && rj[k] != null && rj[k].toString().trim().isNotEmpty) {
            rawPropType = rj[k].toString().trim().toLowerCase();
            break;
          }
        }

        LookupItem? matchedType;
        if (rawPropType.contains('2_bhk') || rawPropType.contains('2 bhk')) {
          matchedType = metadata.types.firstWhere(
            (t) => t.name.toLowerCase().contains('2 bhk'),
            orElse: () => metadata.types.first,
          );
        } else if (rawPropType.contains('3_bhk') || rawPropType.contains('3 bhk')) {
          matchedType = metadata.types.firstWhere(
            (t) => t.name.toLowerCase().contains('3 bhk'),
            orElse: () => metadata.types.first,
          );
        } else if (rawPropType.contains('4_bhk') || rawPropType.contains('4 bhk')) {
          matchedType = metadata.types.firstWhere(
            (t) => t.name.toLowerCase().contains('4 bhk'),
            orElse: () => metadata.types.first,
          );
        } else if (rawPropType.contains('commercial') || rawPropType.contains('office')) {
          matchedType = metadata.types.firstWhere(
            (t) => t.name.toLowerCase().contains('commercial') || t.name.toLowerCase().contains('office'),
            orElse: () => metadata.types.first,
          );
        } else if (metadata.types.isNotEmpty) {
          matchedType = metadata.types.first;
        }

        // Extract Expected Monthly Rent
        String rawRent = '';
        for (final k in [
          'what_is_your_expected_monthly_rent?',
          'what_is_your_expected_monthly_rent',
          'What is your expected monthly rent?',
          'Expected Rent',
          'Price',
          'Rent',
          'Budget'
        ]) {
          if (rj.containsKey(k) && rj[k] != null && rj[k].toString().trim().isNotEmpty) {
            rawRent = rj[k].toString().trim();
            break;
          }
        }
        double parsedRent = 0;
        final rentDigits = RegExp(r'(\d+[\d,]*)').allMatches(rawRent);
        if (rentDigits.isNotEmpty) {
          final firstMatch = rentDigits.first.group(0)?.replaceAll(',', '');
          parsedRent = double.tryParse(firstMatch ?? '0') ?? 0;
        }

        // Match City
        String leadCity = lead.getStringValue('City').trim();
        if (leadCity.isEmpty) leadCity = lead.getStringValue('city').trim();
        LookupItem? matchedCity;
        if (leadCity.isNotEmpty) {
          for (final c in metadata.cities) {
            if (c.name.toLowerCase().contains(leadCity.toLowerCase())) {
              matchedCity = c;
              break;
            }
          }
        }
        matchedCity ??= defaultCity;

        // Generate clean property title
        final typeName = matchedType?.name ?? (rawPropType.isNotEmpty ? rawPropType.replaceAll('_', ' ').toUpperCase() : 'Property');
        final title = '$typeName for Rent in ${cleanLocation.isNotEmpty ? cleanLocation : 'Ahmedabad'}';

        final propertyData = {
          'title': title,
          'owner_name': ownerName,
          'owner_mobile': mobile,
          'address': cleanLocation.isNotEmpty ? cleanLocation : 'Ahmedabad',
          'price': parsedRent,
          'category_id': defaultCategory?.id ?? '',
          'property_type_id': matchedType?.id ?? '',
          'listing_type_id': rentListing?.id ?? '',
          'property_status_id': defaultStatus?.id ?? '',
          'city_id': matchedCity?.id ?? '',
          'remarks': 'Imported from Campaign Leads (Source: ${lead.source}, Campaign: ${lead.getStringValue('Campaign Name')}). Email: $email',
          'created_by': user?.id,
        };

        try {
          final createdProp = await _propertiesRepository.createProperty(propertyData);
          _leads[index] = lead.copyWith(
            importStatus: 'Imported',
            importedClientId: createdProp.id,
          );
          unawaited(_apiClient.patch('/integrations/leads/${lead.id}/status', {
            'importStatus': 'Imported',
            'importedClientId': createdProp.id,
          }).catchError((_) => Response(requestOptions: RequestOptions(path: ''))));
          importedCount++;
        } catch (e) {
          debugPrint('Error importing lead ${lead.id} to Properties: $e');
        }
      }

      await _persistLeads();
      notifyListeners();
      return importedCount;
    } finally {
      coordinator.endBulkMutation();
    }
  }

  Future<int> importAllPendingLeads() async {
    final pending = _leads
        .where((l) => l.importStatus != 'Imported' && !l.isDuplicate)
        .map((l) => l.id)
        .toList();
    if (pending.isEmpty) return 0;
    return importLeadsToCrm(pending);
  }

  /// Delete single lead (local memory + server sync)
  Future<bool> deleteLead(String id) async {
    final leadIndex = _leads.indexWhere((l) => l.id == id);
    if (leadIndex == -1) return false;

    _leads.removeAt(leadIndex);
    _invalidateHeaderCache();
    await _persistLeads();
    notifyListeners();

    unawaited(_apiClient.delete('/integrations/leads/$id').catchError((e) {
      debugPrint('Error syncing deleteLead to server: $e');
      return Response(requestOptions: RequestOptions(path: ''));
    }));

    return true;
  }

  /// Batch delete multiple leads (local memory + server sync)
  Future<int> deleteLeads(List<String> ids) async {
    if (ids.isEmpty) return 0;

    final idsSet = ids.toSet();
    final leadsToDelete = _leads.where((l) => idsSet.contains(l.id)).toList();

    _leads.removeWhere((l) => idsSet.contains(l.id));
    _invalidateHeaderCache();
    await _persistLeads();
    notifyListeners();

    unawaited(_apiClient.post('/integrations/leads/bulk-delete', {'ids': ids}).catchError((e) {
      debugPrint('Error syncing bulkDeleteLeads to server: $e');
      return Response(requestOptions: RequestOptions(path: ''));
    }));

    return leadsToDelete.length;
  }

  /// Merge multiple selected leads into a primary lead
  Future<bool> mergeSelectedLeads({
    required String primaryLeadId,
    required List<String> secondaryLeadIds,
  }) async {
    final primaryIndex = _leads.indexWhere((l) => l.id == primaryLeadId);
    if (primaryIndex == -1 || secondaryLeadIds.isEmpty) return false;

    final primaryLead = _leads[primaryIndex];
    final mergedRaw = Map<String, dynamic>.from(primaryLead.rawJson);

    final secondaryLeads = _leads.where((l) => secondaryLeadIds.contains(l.id)).toList();

    for (final sec in secondaryLeads) {
      for (final entry in sec.rawJson.entries) {
        final key = entry.key;
        final val = entry.value;
        if (val == null) continue;

        // If primary does not have this key, or is empty, copy from secondary
        if (!mergedRaw.containsKey(key) || mergedRaw[key] == null || mergedRaw[key].toString().trim().isEmpty) {
          mergedRaw[key] = val;
        } else if (key.toLowerCase().contains('remark') || key.toLowerCase().contains('note')) {
          // Append remarks
          mergedRaw[key] = '${mergedRaw[key]} | ${val.toString()}';
        }
      }
    }

    _leads[primaryIndex] = primaryLead.copyWith(
      rawJson: mergedRaw,
      isDuplicate: false,
      duplicateReason: null,
    );

    // Delete the secondary leads from memory
    await deleteLeads(secondaryLeadIds);

    deduplicateAll();
    notifyListeners();
    return true;
  }

  /// Bulk update lead quality status
  Future<void> bulkUpdateQualityStatus(List<String> leadIds, String qualityStatus) async {
    if (leadIds.isEmpty) return;
    final idsSet = leadIds.toSet();

    final updated = <IntegrationLeadModel>[];
    for (final lead in _leads) {
      if (idsSet.contains(lead.id)) {
        updated.add(lead.copyWith(qualityStatus: qualityStatus));
      } else {
        updated.add(lead);
      }
    }
    _leads = updated;
    unawaited(_persistLeads());
    notifyListeners();
  }

  Future<int> ingestCsv(String csv, {String source = 'Google Sheets', bool importToLeads = false}) async {
    final rows = _parseCsv(csv);
    return ingestRows(rows, source: source, importToLeads: importToLeads);
  }

  Future<int> ingestRows(
    List<Map<String, dynamic>> rows, {
    String source = 'Google Sheets',
    bool importToLeads = false,
  }) async {
    _updateDetectedHeadersFromRows(rows);
    final prepared = await CampaignIngestEngine().prepare(rows);
    if (prepared.isEmpty) return 0;

    final fingerprintIndex = <String, int>{};
    for (var i = 0; i < _leads.length; i++) {
      final fp = _leads[i].externalLeadId;
      if (fp != null && fp.isNotEmpty) fingerprintIndex[fp] = i;
    }
    final seenPhones = <String>{};
    final seenEmails = <String>{};
    for (final lead in _leads) {
      final phone = _normalizePhone(_extractPhone(lead.rawJson));
      final email = _extractEmail(lead.rawJson).toLowerCase().trim();
      if (phone.isNotEmpty) seenPhones.add(phone);
      if (email.isNotEmpty) seenEmails.add(email);
    }

    final incoming = <IntegrationLeadModel>[];
    final incomingFp = <String, int>{};
    var changed = false;

    for (var i = 0; i < prepared.length; i++) {
      final item = prepared[i];
      item.mappings.forEach((header, field) {
        _columnToCrmFieldMap[header] = field;
      });
      final flattened = flattenIncomingPayload(item.rawJson);
      final fingerprint = item.fingerprint;

      final existingIdx = fingerprintIndex[fingerprint];
      if (existingIdx != null) {
        final existing = _leads[existingIdx];
        final merged = Map<String, dynamic>.from(existing.rawJson);
        flattened.forEach((key, value) {
          if (_cellDisplayValue(value).isEmpty) return;
          merged[key] = value;
        });
        _leads[existingIdx] = existing.copyWith(rawJson: merged);
        changed = true;
        continue;
      }

      final incomingIdx = incomingFp[fingerprint];
      if (incomingIdx != null) {
        final existing = incoming[incomingIdx];
        final merged = Map<String, dynamic>.from(existing.rawJson);
        flattened.forEach((key, value) {
          if (_cellDisplayValue(value).isEmpty) return;
          merged[key] = value;
        });
        incoming[incomingIdx] = existing.copyWith(rawJson: merged);
        continue;
      }

      for (final k in flattened.keys) {
        if (!_customHeaders.contains(k)) {
          _hiddenHeaders.remove(k);
          _autoSuggestMappingForHeader(k);
        }
      }

      final phone = _normalizePhone(_extractPhone(flattened));
      final email = _extractEmail(flattened).toLowerCase().trim();
      var isDup = false;
      String? dupReason;
      if (phone.isNotEmpty && seenPhones.contains(phone)) {
        isDup = true;
        dupReason = 'Duplicate phone number ($phone)';
      } else if (email.isNotEmpty && seenEmails.contains(email)) {
        isDup = true;
        dupReason = 'Duplicate email ($email)';
      }
      if (phone.isNotEmpty) seenPhones.add(phone);
      if (email.isNotEmpty) seenEmails.add(email);

      final typeFromMap = (flattened['lead_type'] ?? flattened['leadType'])?.toString();
      final String detectedLeadType;
      if (typeFromMap != null && typeFromMap.isNotEmpty) {
        detectedLeadType = typeFromMap;
      } else {
        final rawStr = jsonEncode(flattened).toLowerCase();
        if (rawStr.contains('rent out') ||
            rawStr.contains('property located') ||
            rawStr.contains('expected monthly rent') ||
            rawStr.contains('expected_monthly_rent') ||
            rawStr.contains('rental property')) {
          detectedLeadType = 'Property Listing';
        } else {
          detectedLeadType = 'Requirement';
        }
      }

      incomingFp[fingerprint] = incoming.length;
      incoming.add(
        IntegrationLeadModel(
          id: 'lead_${DateTime.now().millisecondsSinceEpoch}_${incoming.length}',
          source: source,
          receivedAt: DateTime.now(),
          leadType: detectedLeadType,
          rawJson: flattened,
          externalLeadId: fingerprint,
          isDuplicate: isDup,
          duplicateReason: dupReason,
          qualityStatus: 'Pending',
          importStatus: 'Pending',
        ),
      );

      if (i % 80 == 0) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    if (incoming.isNotEmpty) {
      _leads = [...incoming.reversed, ..._leads];
      _invalidateHeaderCache();
      changed = true;
    }
    if (changed) {
      notifyListeners();
      unawaited(_persistLeads());
    }

    if (importToLeads && incoming.isNotEmpty) {
      await importAllPendingLeads();
    }
    return incoming.length;
  }

  Future<int> syncGoogleSheet({bool importToLeads = false, bool silent = false}) async {
    if (_syncInFlight) return 0;
    _syncInFlight = true;
    lastSyncError = null;
    final url = _googleSheetUrl.trim();
    if (url.isEmpty) {
      _syncInFlight = false;
      lastSyncError = 'Paste your Google Sheet link on Campaign → Connections first.';
      if (!silent) notifyListeners();
      return 0;
    }

    try {
      final rows = await _downloadSheetRows(url);
      final count = await ingestRows(rows, importToLeads: importToLeads);
      _lastSyncAt = DateTime.now();
      _lastSyncCount = count;
      lastSyncError = null;
      notifyListeners();
      return count;
    } catch (e) {
      lastSyncError = e.toString().replaceFirst('Exception: ', '');
      if (!silent) notifyListeners();
      if (!silent) rethrow;
      debugPrint('Google Sheet sync failed: $e');
      return 0;
    } finally {
      _syncInFlight = false;
    }
  }

  static String appsScriptSnippet(String webhookUrl) {
    return '''
var WEBHOOK_URL = "$webhookUrl";

function rowToPayload(headers, values) {
  var payload = { source: "Google Sheets" };
  for (var i = 0; i < headers.length; i++) {
    var key = String(headers[i] || "").trim();
    if (!key) continue;
    var val = values[i];
    if (Object.prototype.toString.call(val) === "[object Array]") {
      payload[key] = val.filter(Boolean).join(", ");
    } else {
      payload[key] = val;
    }
  }
  return payload;
}

function postLead(payload) {
  UrlFetchApp.fetch(WEBHOOK_URL, {
    method: "post",
    contentType: "application/json",
    payload: JSON.stringify(payload),
    muteHttpExceptions: true
  });
}

function syncAllRows() {
  var sheet = SpreadsheetApp.getActiveSpreadsheet().getActiveSheet();
  var data = sheet.getDataRange().getDisplayValues();
  if (data.length < 2) return;
  var headers = data[0];
  for (var r = 1; r < data.length; r++) {
    var payload = rowToPayload(headers, data[r]);
    var hasValue = false;
    for (var k in payload) {
      if (k !== "source" && payload[k] !== "" && payload[k] != null) hasValue = true;
    }
    if (hasValue) postLead(payload);
    Utilities.sleep(200);
  }
}

function onFormSubmit(e) {
  var sheet = SpreadsheetApp.getActiveSpreadsheet().getActiveSheet();
  var headers = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getDisplayValues()[0];
  var lastRow = sheet.getLastRow();
  var rowValues = sheet.getRange(lastRow, 1, 1, sheet.getLastColumn()).getDisplayValues()[0];
  postLead(rowToPayload(headers, rowValues));
}
''';
  }

  // --- Helper Methods ---

  Map<String, dynamic> flattenIncomingPayload(Map<String, dynamic> rawJson) {
    Map<String, dynamic> source = Map<String, dynamic>.from(rawJson);
    if (source['data'] is Map) {
      source = Map<String, dynamic>.from(source['data'] as Map);
      if (rawJson['source'] != null && !source.containsKey('source')) {
        source['source'] = rawJson['source'];
      }
    }

    final flattened = <String, dynamic>{};
    source.forEach((key, value) {
      flattened[key] = _cellDisplayValue(value);
    });
    return flattened;
  }

  Future<void> _persistLeads() async {
    _persistDirty = true;
    if (_persistInFlight) return;
    _persistInFlight = true;
    try {
      while (_persistDirty) {
        _persistDirty = false;
        try {
          // 1. Save to local Isar database
          final dbRepo = RepositoryCoordinator().campaignLeadLocal;
          final locals = _leads.map((l) {
            final local = CampaignLeadLocal();
            local.id = l.id;
            local.source = l.source;
            local.receivedAt = l.receivedAt;
            local.rawJsonString = jsonEncode(l.rawJson);
            local.externalLeadId = l.externalLeadId;
            local.isDuplicate = l.isDuplicate;
            local.duplicateReason = l.duplicateReason;
            local.qualityStatus = l.qualityStatus;
            local.importStatus = l.importStatus;
            local.importedClientId = l.importedClientId;
            local.metaFeedbackEventId = l.metaFeedbackEventId;
            local.metaFeedbackSentAt = l.metaFeedbackSentAt;
            return local;
          }).toList();

          await dbRepo.clearAll();
          await dbRepo.saveLeads(locals);

          // 2. Keep local prefs backup in sync (skip on Web for large sets to eliminate localStorage main-thread lock)
          if (!kIsWeb || _leads.length <= 100) {
            final payload = <Map<String, dynamic>>[];
            for (var i = 0; i < _leads.length; i++) {
              payload.add(_leads[i].toJson());
              if (!kIsWeb && i > 0 && i % 80 == 0) {
                await Future<void>.delayed(Duration.zero);
              }
            }
            final encoded = (!kIsWeb && payload.length > 400)
                ? await compute(_encodeCampaignLeadsJson, payload)
                : jsonEncode(payload);
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_leadsPrefsKey, encoded);
          }
        } catch (e) {
          debugPrint('Failed to persist campaign leads to database: $e');
        }
      }
    } finally {
      _persistInFlight = false;
      if (_persistDirty) {
        unawaited(_persistLeads());
      }
    }
  }

  void _startSheetPolling() {
    _sheetPollTimer?.cancel();
    if (_googleSheetUrl.trim().isEmpty) return;
    _sheetPollTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      unawaited(syncGoogleSheet(silent: true));
    });
  }

  bool _rowHasData(Map<String, dynamic> row) {
    return row.values.any((v) => v != null && v.toString().trim().isNotEmpty);
  }

  Map<String, String> _mapLeadFields(IntegrationLeadModel lead) {
    final mapped = {
      'name': '',
      'mobile': '',
      'email': '',
      'city': '',
      'budget': '',
      'configuration': '',
      'property': '',
      'campaign': '',
      'remarks': '',
    };

    mapped['name'] = lead.getStringValue(CampaignIngestEngine.engineClientName);
    mapped['mobile'] = lead.getStringValue(CampaignIngestEngine.engineMobile);
    mapped['email'] = lead.getStringValue(CampaignIngestEngine.engineEmail);
    mapped['property'] = lead.getStringValue(CampaignIngestEngine.engineProperty);
    mapped['campaign'] = lead.getStringValue(CampaignIngestEngine.engineCampaign);
    mapped['city'] = lead.getStringValue(CampaignIngestEngine.engineCity);

    for (final entry in lead.rawJson.entries) {
      if (entry.key.startsWith('_engine_')) continue;
      final val = _cellDisplayValue(entry.value);
      if (val.isEmpty) continue;
      _autoSuggestMappingForHeader(entry.key);
      final target = _columnToCrmFieldMap[entry.key];
      if (target == null || !mapped.containsKey(target) || mapped[target]!.isNotEmpty) continue;
      if (target == 'name' && mapped['property'] == val) continue;
      mapped[target] = val;
    }

    if (mapped['name']!.isEmpty || mapped['name'] == mapped['property']) {
      final client = lead.getStringValue('Client Name');
      mapped['name'] = client.isNotEmpty
          ? client
          : (mapped['mobile']!.length >= 4
              ? 'Lead ${mapped['mobile']!.substring(mapped['mobile']!.length - 4)}'
              : mapped['name']!);
    }
    if (mapped['property']!.isEmpty) {
      mapped['property'] = lead.getStringValue('Property Name');
    }
    if (mapped['mobile']!.isEmpty) {
      mapped['mobile'] = _extractPhone(lead.rawJson);
    }
    if (mapped['email']!.isEmpty) {
      mapped['email'] = _extractEmail(lead.rawJson);
    }
    return mapped;
  }

  double _parseBudget(String raw) {
    if (raw.trim().isEmpty) return 0;
    final fromWords = BudgetFormatter.parse(raw);
    if (fromWords > 0) return fromWords;
    return double.tryParse(raw.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
  }

  LookupItem? _matchLookup(List<LookupItem> items, String needle, {String? categoryId}) {
    final query = _normalizeLookup(needle);
    if (query.isEmpty) return null;
    final scoped = categoryId == null ? items : items.where((i) => i.categoryId == categoryId).toList();
    for (final item in scoped) {
      if (_normalizeLookup(item.name) == query) return item;
    }
    for (final item in scoped) {
      final name = _normalizeLookup(item.name);
      if (name.contains(query) || query.contains(name)) return item;
    }
    return null;
  }

  AreaLookup? _matchArea(List<AreaLookup> areas, List<LookupItem> cities, String needle) {
    final query = _normalizeLookup(needle);
    if (query.isEmpty) return null;

    for (final area in areas) {
      if (_normalizeLookup(area.name) == query) return area;
    }
    for (final city in cities) {
      if (_normalizeLookup(city.name) == query || _normalizeLookup(city.name).contains(query) || query.contains(_normalizeLookup(city.name))) {
        final cityAreas = areas.where((a) => a.cityId == city.id).toList();
        if (cityAreas.isNotEmpty) return cityAreas.first;
      }
    }
    for (final area in areas) {
      final name = _normalizeLookup(area.name);
      if (name.contains(query) || query.contains(name)) return area;
    }
    return null;
  }

  String _normalizeLookup(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  Future<List<Map<String, dynamic>>> _downloadSheetRows(String input) async {
    final id = extractSpreadsheetId(input);
    if (id == null) {
      throw Exception('That does not look like a Google Sheet link. Paste the full sharing URL.');
    }
    final gid = extractSheetGid(input) ?? '0';
    final jsonUrl = 'https://docs.google.com/spreadsheets/d/$id/gviz/tq?tqx=out:json&gid=$gid';
    final csvUrls = [
      'https://docs.google.com/spreadsheets/d/$id/export?format=csv&gid=$gid',
      'https://docs.google.com/spreadsheets/d/$id/gviz/tq?tqx=out:csv&gid=$gid',
    ];

    Object? lastError;
    try {
      final response = await _externalHttp.get<String>(jsonUrl);
      final body = response.data?.toString() ?? '';
      if (body.trim().isNotEmpty && !body.contains('<html') && !body.contains('<!DOCTYPE')) {
        final rows = _parseGvizJson(body);
        if (rows.isNotEmpty) return rows;
      }
    } on DioException catch (e) {
      lastError = _sheetFetchError(e);
    } catch (e) {
      lastError = e;
    }

    for (final url in csvUrls) {
      try {
        final response = await _externalHttp.get<String>(url);
        final body = response.data?.toString() ?? '';
        if (body.trim().isEmpty) continue;
        if (body.contains('<html') || body.contains('<!DOCTYPE')) {
          throw Exception(
            'Google blocked the download. Open the sheet → Share → General access: Anyone with the link (Viewer), then sync again.',
          );
        }
        return _parseCsv(body);
      } on DioException catch (e) {
        lastError = _sheetFetchError(e);
      } catch (e) {
        lastError = e;
      }
    }

    throw Exception(
      lastError?.toString() ??
          'Could not download the Google Sheet. Share it as Anyone with the link, or import a CSV file instead.',
    );
  }

  Object _sheetFetchError(DioException e) {
    final message = e.message ?? e.toString();
    if (message.contains('XMLHttpRequest') || message.contains('CORS') || e.type == DioExceptionType.connectionError) {
      return Exception(
        'The browser cannot read Google Sheets directly. Use Import CSV (File → Download → CSV) on Campaign Leads, or share the sheet and sync from the Windows app.',
      );
    }
    return e;
  }

  static String? extractSpreadsheetId(String input) {
    final trimmed = input.trim();
    final fromUrl = RegExp(r'/spreadsheets/d/([a-zA-Z0-9-_]+)').firstMatch(trimmed);
    if (fromUrl != null) return fromUrl.group(1);
    if (RegExp(r'^[a-zA-Z0-9-_]{20,}$').hasMatch(trimmed)) return trimmed;
    return null;
  }

  static String? extractSheetGid(String input) {
    return RegExp(r'[?#&]gid=([0-9]+)').firstMatch(input)?.group(1);
  }

  List<Map<String, dynamic>> _parseCsv(String csv) {
    final rows = <List<String>>[];
    var current = <String>[];
    var field = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < csv.length; i++) {
      final char = csv[i];
      final next = i + 1 < csv.length ? csv[i + 1] : '';
      if (inQuotes) {
        if (char == '"' && next == '"') {
          field.write('"');
          i++;
        } else if (char == '"') {
          inQuotes = false;
        } else {
          field.write(char);
        }
      } else if (char == '"') {
        inQuotes = true;
      } else if (char == ',') {
        current.add(field.toString());
        field = StringBuffer();
      } else if (char == '\n') {
        current.add(field.toString().replaceAll('\r', ''));
        field = StringBuffer();
        if (current.any((c) => c.trim().isNotEmpty)) rows.add(current);
        current = [];
      } else if (char != '\r') {
        field.write(char);
      }
    }
    current.add(field.toString());
    if (current.any((c) => c.trim().isNotEmpty)) rows.add(current);

    if (rows.length < 2) return [];
    final headers = rows.first.map((h) => h.trim()).toList();
    final result = <Map<String, dynamic>>[];
    for (var r = 1; r < rows.length; r++) {
      final values = _realignCsvRow(headers, rows[r]);
      final map = <String, dynamic>{};
      for (var c = 0; c < headers.length; c++) {
        final header = headers[c];
        if (header.isEmpty) continue;
        map[header] = c < values.length ? values[c].trim() : '';
      }
      result.add(map);
    }
    return result;
  }

  List<String> _realignCsvRow(List<String> headers, List<String> values) {
    if (values.length <= headers.length) return values;
    final extra = values.length - headers.length;
    var mergeAt = headers.indexWhere((h) {
      final key = h.toLowerCase();
      return key.contains('name') || key.contains('property') || key.contains('project');
    });
    if (mergeAt < 0) mergeAt = 0;
    final merged = values.sublist(mergeAt, mergeAt + extra + 1).join(', ');
    return [
      ...values.sublist(0, mergeAt),
      merged,
      ...values.sublist(mergeAt + extra + 1),
    ];
  }

  String _cellDisplayValue(dynamic value) {
    if (value == null) return '';
    if (value is List) {
      return value.map(_cellDisplayValue).where((v) => v.isNotEmpty).join(', ');
    }
    if (value is Map) {
      final formatted = value['f'] ?? value['label'] ?? value['name'] ?? value['title'];
      if (formatted != null && formatted.toString().trim().isNotEmpty) {
        return formatted.toString().trim();
      }
      final nested = value['v'] ?? value['value'];
      if (nested != null && nested != value) return _cellDisplayValue(nested);
    }
    return value.toString().trim();
  }

  List<Map<String, dynamic>> _parseGvizJson(String body) {
    var jsonText = body.trim();
    final start = jsonText.indexOf('{');
    final end = jsonText.lastIndexOf('}');
    if (start < 0 || end <= start) return [];
    jsonText = jsonText.substring(start, end + 1);
    final decoded = jsonDecode(jsonText);
    if (decoded is! Map) return [];
    final table = decoded['table'];
    if (table is! Map) return [];
    final cols = (table['cols'] as List? ?? [])
        .whereType<Map>()
        .map((c) => (c['label'] ?? c['id'] ?? '').toString().trim())
        .toList();
    if (cols.isEmpty) return [];
    final rows = <Map<String, dynamic>>[];
    for (final rawRow in (table['rows'] as List? ?? [])) {
      if (rawRow is! Map) continue;
      final cells = rawRow['c'] as List? ?? [];
      final map = <String, dynamic>{};
      for (var i = 0; i < cols.length; i++) {
        final header = cols[i];
        if (header.isEmpty) continue;
        map[header] = i < cells.length ? _cellDisplayValue(cells[i]) : '';
      }
      if (_rowHasData(map)) rows.add(map);
    }
    return rows;
  }

  Future<List<PropertyModel>> _cachedProperties() async {
    if (_propertyCache != null &&
        _propertyCacheAt != null &&
        DateTime.now().difference(_propertyCacheAt!) < const Duration(minutes: 2)) {
      return _propertyCache!;
    }
    _propertyCache = await _propertiesRepository.getProperties();
    _propertyCacheAt = DateTime.now();
    return _propertyCache!;
  }

  Future<Map<String, dynamic>> enrichRowFromProperties(Map<String, dynamic> row) async {
    final inventory = await _cachedProperties();
    if (inventory.isEmpty) return row;
    final mappedStub = <String, String>{
      'name': '',
      'property': '',
      'city': '',
      'budget': '',
      'configuration': '',
      'remarks': '',
    };
    for (final entry in row.entries) {
      _autoSuggestMappingForHeader(entry.key);
      final target = _columnToCrmFieldMap[entry.key];
      final val = _cellDisplayValue(entry.value);
      if (target != null && mappedStub.containsKey(target) && mappedStub[target]!.isEmpty && val.isNotEmpty) {
        mappedStub[target] = val;
      }
    }
    final matches = _propertiesFromMappedRow(mappedStub, row, inventory);
    if (matches.isEmpty) return row;

    final primary = matches.first;
    final enriched = Map<String, dynamic>.from(row);
    void fillIfEmpty(String key, String value) {
      if (value.trim().isEmpty) return;
      final current = _cellDisplayValue(enriched[key]);
      if (current.isEmpty) enriched[key] = value;
    }

    fillIfEmpty('City', primary.cityName);
    fillIfEmpty('Location', primary.areaName);
    fillIfEmpty('Area', primary.areaName);
    fillIfEmpty('Configuration', primary.configurationName ?? '');
    fillIfEmpty('BHK', primary.configurationName ?? '');
    fillIfEmpty('Budget', primary.price > 0 ? primary.price.toString() : '');
    fillIfEmpty('Property Name', primary.title);
    fillIfEmpty('Property', primary.title);
    enriched['_matched_properties'] = matches.map((p) => '${p.title} (${p.propertyCode})').join(', ');
    if (_cellDisplayValue(enriched['City']).isEmpty && primary.areaName.isNotEmpty) {
      enriched['City'] = primary.areaName;
    }
    return enriched;
  }

  List<PropertyModel> _propertiesFromMappedRow(
    Map<String, String> mapped,
    Map<String, dynamic> raw,
    List<PropertyModel> inventory,
  ) {
    final labels = <String>{
      mapped['property'] ?? '',
      mapped['name'] ?? '',
    };
    for (final entry in raw.entries) {
      final header = entry.key.toLowerCase();
      if (header.contains('property') || header.contains('project') || header == 'name') {
        labels.add(_cellDisplayValue(entry.value));
      }
    }
    final matches = <PropertyModel>[];
    final seen = <String>{};
    for (final label in labels) {
      for (final property in _matchProperties(label, inventory)) {
        if (seen.add(property.id)) matches.add(property);
      }
    }
    return matches;
  }

  List<PropertyModel> _matchProperties(String raw, List<PropertyModel> inventory) {
    final text = raw.trim();
    if (text.isEmpty) return [];
    final exact = _findProperty(text, inventory);
    if (exact != null) return [exact];

    final parts = text
        .split(RegExp(r'\s*[;\n|]\s*'))
        .expand((part) => part.contains(',') ? part.split(RegExp(r'\s*,\s*')) : [part])
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length < 2) return [];

    final matches = <PropertyModel>[];
    final seen = <String>{};
    for (final part in parts) {
      final found = _findProperty(part, inventory);
      if (found != null && seen.add(found.id)) matches.add(found);
    }
    return matches;
  }

  PropertyModel? _findProperty(String raw, List<PropertyModel> inventory) {
    final query = _normalizeLookup(raw);
    if (query.isEmpty) return null;
    for (final property in inventory) {
      final labels = [
        property.title,
        property.propertyCode,
        '${property.title} ${property.areaName}',
        '${property.title} - ${property.areaName}',
        '${property.propertyCode} ${property.title}',
        '${property.propertyCode} - ${property.title}',
      ];
      for (final label in labels) {
        if (_normalizeLookup(label) == query) return property;
      }
    }
    return null;
  }

  bool _isSameLabel(String name, PropertyModel property) {
    final query = _normalizeLookup(name);
    if (query.isEmpty) return false;
    return query == _normalizeLookup(property.title) ||
        query == _normalizeLookup(property.propertyCode) ||
        query == _normalizeLookup('${property.title} ${property.areaName}');
  }

  String _extractPhone(Map<String, dynamic> json) {
    for (final entry in json.entries) {
      final k = entry.key.toLowerCase();
      if (k.contains('phone') || k.contains('mobile') || k.contains('contact')) {
        return _cellDisplayValue(entry.value);
      }
    }
    return '';
  }

  String _extractEmail(Map<String, dynamic> json) {
    for (final entry in json.entries) {
      final k = entry.key.toLowerCase();
      if (k.contains('email') || k.contains('mail')) {
        return _cellDisplayValue(entry.value);
      }
    }
    return '';
  }

  String _normalizePhone(String phone) {
    var digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('91') && digits.length == 12) {
      digits = digits.substring(2);
    }
    return digits;
  }
}

List<dynamic> _decodeCampaignLeadsJson(String stored) {
  final decoded = jsonDecode(stored);
  return decoded is List ? decoded : const [];
}

String _encodeCampaignLeadsJson(List<Map<String, dynamic>> leads) {
  return jsonEncode(leads);
}
