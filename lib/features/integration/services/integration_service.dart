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
import '../../../core/api/api_constants.dart';
import '../../../core/config/app_env.dart';
import '../../../core/security/role_guard.dart';
import '../../../core/storage/isar_collections.dart';
import '../../../core/storage/repository_coordinator.dart';
import '../../../core/services/notification_center.dart';

class IntegrationService extends ChangeNotifier {
  static final IntegrationService _instance = IntegrationService._internal();
  factory IntegrationService() => _instance;
  IntegrationService._internal();

  static bool matchesCampaignSource(String leadSource, String? filter) {
    if (filter == null || filter.isEmpty || filter == 'All') return true;
    final src = leadSource.toUpperCase().trim();
    final sel = filter.toUpperCase().trim();
    if (sel == 'HOUSING' || sel == 'HOUSING.COM') {
      return src == 'HOUSING' || src == 'HOUSING.COM';
    }
    if (sel == 'META' || sel == 'META ADS' || sel == 'FACEBOOK') {
      return src == 'META' || src == 'META ADS' || src == 'FACEBOOK' || src == 'INSTAGRAM';
    }
    if (sel == 'GOOGLE' || sel == 'GOOGLE SHEETS' || sel == 'GOOGLE SHEET') {
      return src == 'GOOGLE' || src == 'GOOGLE SHEETS' || src == 'GOOGLE SHEET';
    }
    return src == sel;
  }

  String get _orgScope => RoleGuard.currentUser?.organizationId ?? 'global';
  String get _userScope => RoleGuard.currentUser?.id ?? 'global';

  String get _leadsPrefsKey => 'campaign_ingestion_leads_json_${_orgScope}_$_userScope';
  String get _sheetUrlPrefsKey => 'campaign_google_sheet_url_$_orgScope';
  String get _propCustomHeadersPrefsKey => 'campaign_prop_custom_headers_v1_$_orgScope';
  String get _reqCustomHeadersPrefsKey => 'campaign_req_custom_headers_v1_$_orgScope';
  String get _propHiddenHeadersPrefsKey => 'campaign_prop_hidden_headers_v1_$_orgScope';
  String get _reqHiddenHeadersPrefsKey => 'campaign_req_hidden_headers_v1_$_orgScope';
  String get _headerOrderPrefsKey => 'campaign_header_order_v1_$_orgScope';
  String get _propHeaderOrderPrefsKey => 'campaign_prop_header_order_v1_$_orgScope';
  String get _reqHeaderOrderPrefsKey => 'campaign_req_header_order_v1_$_orgScope';
  String get _userLayoutPrefsKey => 'campaign_column_layout_user_v1_${_orgScope}_$_userScope';

  static final StreamController<Map<String, dynamic>> leadEvents =
      StreamController<Map<String, dynamic>>.broadcast();

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
  String? _loadedOrgScope;
  bool? _loadedCampaignOff;
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
  String get webhookUrl => '${AppEnv.apiBaseUrl}/integrations/webhooks/meta-leads';
  String get vpsDirectWebhookUrl => webhookUrl;
  String webhookSecret = "pk_sec_99a8b7c6d5e4f3a2b1";
  String metaVerifyToken = "propkart_meta_lead_verify_token_2026";
  bool isWebhookListening = true;

  // Ingested Leads (clean start)
  final Map<String, (String, DateTime)> _recentlyReclassifiedLeads = {};
  List<IntegrationLeadModel> _leads = [];
  List<IntegrationLeadModel> get leads {
    if (RoleGuard.isTelecaller(RoleGuard.currentUser?.role)) {
      final myId = RoleGuard.currentUser?.id.trim().toLowerCase();
      if (myId != null && myId.isNotEmpty) {
        return List.unmodifiable(_leads.where((l) {
          final assigned = l.assignedTelecallerId?.trim().toLowerCase();
          return assigned != null && assigned.isNotEmpty && assigned == myId;
        }));
      }
    }
    return List.unmodifiable(_leads);
  }
  List<IntegrationLeadModel> get requirementLeads =>
      leads.where((l) => l.leadType == 'Requirement').toList();
  List<IntegrationLeadModel> get propertyListingLeads =>
      leads.where((l) => l.leadType == 'Property Listing').toList();

  // Dynamic user-defined headers created in advance or dynamically
  final Set<String> _customHeaders = {};
  Set<String> get customHeaders => Set.unmodifiable(_customHeaders);

  // Section-specific custom headers
  final Set<String> _propertyListingCustomHeaders = {};
  final Set<String> _requirementCustomHeaders = {};

  // Set of headers hidden by user preference
  final Set<String> _hiddenHeaders = {};
  Set<String> get hiddenHeaders => Set.unmodifiable(_hiddenHeaders);
  Set<String> get visibleHeaders => Set.from(getActiveVisibleHeaders());

  // Section-specific hidden headers
  final Set<String> _propertyListingHiddenHeaders = {};
  final Set<String> _requirementHiddenHeaders = {};

  // Column header ordering (preserves exact Google Sheet order or custom drag-and-drop order)
  List<String> _headerOrder = [];
  List<String> get headerOrder => List.unmodifiable(_headerOrder);

  // Section-specific header orders
  List<String> _propertyListingHeaderOrder = [];
  List<String> _requirementHeaderOrder = [];

  Set<String> customHeadersFor(String? section) {
    if (section == 'Property Listing') return Set.unmodifiable(_propertyListingCustomHeaders);
    if (section == 'Requirement') return Set.unmodifiable(_requirementCustomHeaders);
    return customHeaders;
  }

  Set<String> hiddenHeadersFor(String? section) {
    if (section == 'Property Listing') return Set.unmodifiable(_propertyListingHiddenHeaders);
    if (section == 'Requirement') return Set.unmodifiable(_requirementHiddenHeaders);
    return hiddenHeaders;
  }

  List<String> headerOrderFor(String? section) {
    if (section == 'Property Listing') return List.unmodifiable(_propertyListingHeaderOrder);
    if (section == 'Requirement') return List.unmodifiable(_requirementHeaderOrder);
    return headerOrder;
  }

  // Live Auto-Sync Status
  DateTime? _lastSyncAt;
  int _lastSyncCount = 0;
  DateTime? get lastSyncAt => _lastSyncAt;
  int get lastSyncCount => _lastSyncCount;

  // Live Diagnostic & Health Status
  List<Map<String, dynamic>> _activeHealthAlerts = [];
  List<Map<String, dynamic>> get activeHealthAlerts => List.unmodifiable(_activeHealthAlerts);
  String? _metaStatus;
  String? get metaStatus => _metaStatus;
  Map<String, dynamic>? _leadsPipelineInfo;
  Map<String, dynamic>? get leadsPipelineInfo => _leadsPipelineInfo;

  // Column header to CRM field mappings
  final Map<String, String> _columnToCrmFieldMap = {
    'Client / Owner Name': 'name',
    'Owner Name': 'name',
    'Full Name': 'name',
    'full_name': 'name',
    'Name': 'name',
    'Client Name': 'name',
    'Customer Name': 'name',
    'Buyer Name': 'name',
    'Phone Number': 'mobile',
    'phone_number': 'mobile',
    'Phone': 'mobile',
    'Mobile': 'mobile',
    'Contact': 'mobile',
    'Number': 'mobile',
    'Received On': 'received_at',
    'Arrival Time': 'received_at',
    'Received Date': 'received_at',
    'Date': 'received_at',
    'Property Type': 'configuration',
    'Configuration': 'configuration',
    'configuration': 'configuration',
    'BHK': 'configuration',
    'Expected Rent': 'budget',
    'Monthly Budget': 'budget',
    'budget': 'budget',
    'Budget': 'budget',
    'Target Budget': 'budget',
    'Property Location': 'city',
    'Preferred Area': 'city',
    'city': 'city',
    'City': 'city',
    'Location': 'city',
    'Email ID': 'email',
    'email': 'email',
    'Email': 'email',
    'Campaign Name': 'campaign',
    'campaign_name': 'campaign',
    'Form Name': 'campaign',
    'form_name': 'campaign',
    'Ad Name': 'campaign',
    'ad_name': 'campaign',
    'Who Will Be Staying': 'remarks',
    'remarks': 'remarks',
    'Notes': 'remarks',
    'Property': 'property',
    'Property Name': 'property',
    'Project': 'property',
    'Project Name': 'property',
    'Inventory': 'property',
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
    'received_at': 'Arrival / Received Date',
    'source': 'Lead Source Tag',
  };

  /// Add a custom header dynamically
  /// Add a custom header dynamically with optional persistence scope ('user' | 'global')
  Future<bool> addCustomHeader(String headerName, {String? crmField, String? section, String? scope}) async {
    final trimmed = headerName.trim();
    if (trimmed.isEmpty) return false;

    if (section == 'Property Listing') {
      _propertyListingCustomHeaders.add(trimmed);
      _propertyListingHiddenHeaders.remove(trimmed);
      if (!_propertyListingHeaderOrder.contains(trimmed)) {
        _propertyListingHeaderOrder.add(trimmed);
      }
    } else if (section == 'Requirement') {
      _requirementCustomHeaders.add(trimmed);
      _requirementHiddenHeaders.remove(trimmed);
      if (!_requirementHeaderOrder.contains(trimmed)) {
        _requirementHeaderOrder.add(trimmed);
      }
    } else {
      _customHeaders.add(trimmed);
      _hiddenHeaders.remove(trimmed);
      if (!_headerOrder.contains(trimmed)) {
        _headerOrder.add(trimmed);
        unawaited(_persistHeaderOrder());
      }
    }
    _invalidateHeaderCache();

    if (crmField != null && crmField.isNotEmpty) {
      _columnToCrmFieldMap[trimmed] = crmField;
    } else {
      _autoSuggestMappingForHeader(trimmed);
    }

    notifyListeners();
    return _saveSectionLayout(section, scope);
  }

  /// Remove a custom header
  Future<bool> removeCustomHeader(String headerName, {String? section, String? scope}) async {
    if (section == 'Property Listing') {
      _propertyListingCustomHeaders.remove(headerName);
      _propertyListingHiddenHeaders.remove(headerName);
      _propertyListingHeaderOrder.remove(headerName);
    } else if (section == 'Requirement') {
      _requirementCustomHeaders.remove(headerName);
      _requirementHiddenHeaders.remove(headerName);
      _requirementHeaderOrder.remove(headerName);
    } else {
      _customHeaders.remove(headerName);
      _hiddenHeaders.remove(headerName);
      _headerOrder.remove(headerName);
      unawaited(_persistHeaderOrder());
    }

    _columnToCrmFieldMap.remove(headerName);

    final updated = <IntegrationLeadModel>[];
    for (final lead in _leads) {
      if (section == null || lead.leadType == section) {
        final raw = Map<String, dynamic>.from(lead.rawJson);
        raw.remove(headerName);
        updated.add(lead.copyWith(rawJson: raw));
      } else {
        updated.add(lead);
      }
    }
    _leads = updated;
    _invalidateHeaderCache();
    notifyListeners();
    return _saveSectionLayout(section, scope);
  }

  /// Toggle header visibility with optional persistence scope ('user' | 'global')
  Future<bool> setHeaderVisibility(String header, bool isVisible, {String? section, String? scope}) async {
    if (section == 'Property Listing') {
      if (isVisible) {
        _propertyListingHiddenHeaders.remove(header);
      } else {
        _propertyListingHiddenHeaders.add(header);
      }
    } else if (section == 'Requirement') {
      if (isVisible) {
        _requirementHiddenHeaders.remove(header);
      } else {
        _requirementHiddenHeaders.add(header);
      }
    } else {
      if (isVisible) {
        _hiddenHeaders.remove(header);
      } else {
        _hiddenHeaders.add(header);
      }
    }
    _invalidateHeaderCache();
    notifyListeners();
    return _saveSectionLayout(section, scope);
  }

  /// Select or Deselect all headers with optional persistence scope ('user' | 'global')
  Future<bool> setAllHeadersVisibility(bool isVisible, {String? section, String? scope}) async {
    final all = getDetectedHeaders(section: section);
    if (section == 'Property Listing') {
      if (isVisible) {
        _propertyListingHiddenHeaders.clear();
      } else {
        _propertyListingHiddenHeaders.addAll(all);
      }
    } else if (section == 'Requirement') {
      if (isVisible) {
        _requirementHiddenHeaders.clear();
      } else {
        _requirementHiddenHeaders.addAll(all);
      }
    } else {
      if (isVisible) {
        _hiddenHeaders.clear();
      } else {
        _hiddenHeaders.addAll(all);
      }
    }
    _invalidateHeaderCache();
    notifyListeners();
    return _saveSectionLayout(section, scope);
  }

  /// Check if a header is visible
  bool isHeaderVisible(String header, {String? section}) {
    if (section == 'Property Listing') {
      return !_propertyListingHiddenHeaders.contains(header);
    }
    if (section == 'Requirement') {
      return !_requirementHiddenHeaders.contains(header);
    }
    return !_hiddenHeaders.contains(header);
  }

  List<String>? _cachedDetectedHeaders;
  List<String>? _cachedVisibleHeaders;

  void _invalidateHeaderCache() {
    _cachedDetectedHeaders = null;
    _cachedVisibleHeaders = null;
  }

  /// Get all detected headers in business-prioritized order:
  /// When section is provided (e.g. 'Property Listing' or 'Requirement'), standard columns
  /// for that section are strictly isolated and returned, followed by any section-specific custom fields.
  /// When section is null, preserves exact Google Sheet insertion order or custom user dragged order.
  List<String> getDetectedHeaders({List<IntegrationLeadModel>? leadsSubset, String? section}) {
    if (leadsSubset == null && section == null && _cachedDetectedHeaders != null) return _cachedDetectedHeaders!;

    final targetLeads = leadsSubset ?? _leads;

    // If section is provided (e.g. in Campaign Leads screen), strictly isolate to that section's headers
    if (section != null) {
      final isProp = section == 'Property Listing';

      final List<String> standardOrder = isProp
          ? [
              'Client / Owner Name',
              'Phone Number',
              'Received On',
              'Property Type',
              'Expected Rent',
              'Property Location',
              'City',
              'Email ID',
              'Campaign Name',
              'Form Name',
            ]
          : [
              'Client Name',
              'Phone Number',
              'Received On',
              'Configuration',
              'Monthly Budget',
              'Preferred Area',
              'City',
              'Who Will Be Staying',
              'Email ID',
              'Campaign Name',
              'Form Name',
            ];

      final sectionCustom = isProp ? _propertyListingCustomHeaders : _requirementCustomHeaders;
      final sectionSavedOrder = isProp ? _propertyListingHeaderOrder : _requirementHeaderOrder;
      final availableHeaders = {...standardOrder, ...sectionCustom};

      final result = <String>[];
      if (sectionSavedOrder.isNotEmpty) {
        for (final h in sectionSavedOrder) {
          if (availableHeaders.contains(h) && !result.contains(h)) {
            result.add(h);
          }
        }
      }

      for (final h in standardOrder) {
        if (!result.contains(h)) {
          result.add(h);
        }
      }

      for (final h in sectionCustom) {
        if (!result.contains(h)) {
          result.add(h);
        }
      }

      return result;
    }

    // When section is null (raw sheet connector or generic view):
    // 1. Gather all actual existing headers in leads + custom headers
    final existingHeaders = <String>{..._customHeaders};
    for (final lead in targetLeads) {
      for (final k in lead.rawJson.keys) {
        final clean = k.trim();
        if (clean.isNotEmpty && !clean.startsWith('_') && clean.toLowerCase() != 'source') {
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
        if (clean.isNotEmpty && clean.toLowerCase() != 'source' && !clean.startsWith('_')) {
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

  /// Reorder headers via drag and place.
  /// [persist] writes the layout. Drag previews pass false and save once a scope is chosen.
  Future<void> reorderHeaders(int oldIndex, int newIndex, {List<IntegrationLeadModel>? leadsSubset, String? section, String? scope, bool persist = true}) async {
    final current = List<String>.from(getDetectedHeaders(leadsSubset: leadsSubset, section: section));
    if (oldIndex < 0 || oldIndex >= current.length) return;
    if (newIndex < 0 || newIndex > current.length) return;

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = current.removeAt(oldIndex);
    current.insert(newIndex, item);

    if (section == 'Property Listing') {
      _propertyListingHeaderOrder = current;
      if (persist) {
        unawaited(saveColumnLayoutToServer(section: 'Property Listing', scope: scope ?? 'user'));
      }
    } else if (section == 'Requirement') {
      _requirementHeaderOrder = current;
      if (persist) {
        unawaited(saveColumnLayoutToServer(section: 'Requirement', scope: scope ?? 'user'));
      }
    } else if (leadsSubset != null) {
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
      unawaited(_persistHeaderOrder());
    } else {
      _headerOrder = current;
      unawaited(_persistHeaderOrder());
    }

    _invalidateHeaderCache();
    notifyListeners();
  }

  /// Move a single header left (-1) or right (+1)
  Future<bool> moveHeader(String header, int direction, {List<IntegrationLeadModel>? leadsSubset, String? section, String? scope}) async {
    final current = List<String>.from(getDetectedHeaders(leadsSubset: leadsSubset, section: section));
    final idx = current.indexOf(header);
    if (idx == -1) return false;
    final newIdx = idx + direction;
    if (newIdx < 0 || newIdx >= current.length) return false;

    final item = current.removeAt(idx);
    current.insert(newIdx, item);

    if (section == 'Property Listing') {
      _propertyListingHeaderOrder = current;
    } else if (section == 'Requirement') {
      _requirementHeaderOrder = current;
    } else if (leadsSubset != null) {
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
      unawaited(_persistHeaderOrder());
    } else {
      _headerOrder = current;
      unawaited(_persistHeaderOrder());
    }

    _invalidateHeaderCache();
    notifyListeners();
    return _saveSectionLayout(section, scope);
  }

  void replaceSectionHeaderOrder(String? section, List<String> order) {
    final next = List<String>.from(order);
    if (section == 'Property Listing') {
      _propertyListingHeaderOrder = next;
    } else if (section == 'Requirement') {
      _requirementHeaderOrder = next;
    } else {
      _headerOrder = next;
    }
    _invalidateHeaderCache();
    notifyListeners();
  }

  /// Reset header order back to original sheet insertion order
  Future<void> resetHeaderOrderToSheet({List<IntegrationLeadModel>? leadsSubset, String? section, bool persist = true}) async {
    if (section == 'Property Listing') {
      _propertyListingHeaderOrder.clear();
      if (persist) unawaited(_persistSectionHeaderOrder('Property Listing'));
    } else if (section == 'Requirement') {
      _requirementHeaderOrder.clear();
      if (persist) unawaited(_persistSectionHeaderOrder('Requirement'));
    } else if (leadsSubset != null) {
      final sectionHeaders = getDetectedHeaders(leadsSubset: leadsSubset);
      final extracted = <String>[];
      for (final lead in leadsSubset) {
        for (final k in lead.rawJson.keys) {
          final clean = k.trim();
          if (clean.isNotEmpty &&
              !clean.startsWith('_') &&
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
      unawaited(_persistHeaderOrder());
    } else {
      _headerOrder.clear();
      final extracted = <String>[];
      for (final lead in _leads) {
        for (final k in lead.rawJson.keys) {
          final clean = k.trim();
          if (clean.isNotEmpty &&
              !clean.startsWith('_') &&
              clean.toLowerCase() != 'source' &&
              clean != 'Client Name' &&
              clean != 'Phone' &&
              clean != 'Property Name') {
            if (!extracted.contains(clean)) extracted.add(clean);
          }
        }
      }
      _headerOrder = extracted;
      unawaited(_persistHeaderOrder());
    }
    _invalidateHeaderCache();
    notifyListeners();
  }

  Future<void> _persistHeaderOrder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_headerOrderPrefsKey, jsonEncode(_headerOrder));
    } catch (_) {}
  }

  Future<void> _persistSectionHeaderOrder(String section) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (section == 'Property Listing') {
        await prefs.setString(_propHeaderOrderPrefsKey, jsonEncode(_propertyListingHeaderOrder));
      } else if (section == 'Requirement') {
        await prefs.setString(_reqHeaderOrderPrefsKey, jsonEncode(_requirementHeaderOrder));
      }
    } catch (_) {}
  }

  Future<void> _persistSectionCustomHeaders(String section) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (section == 'Property Listing') {
        await prefs.setString(_propCustomHeadersPrefsKey, jsonEncode(_propertyListingCustomHeaders.toList()));
      } else if (section == 'Requirement') {
        await prefs.setString(_reqCustomHeadersPrefsKey, jsonEncode(_requirementCustomHeaders.toList()));
      }
    } catch (_) {}
  }

  Future<void> _persistSectionHiddenHeaders(String section) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (section == 'Property Listing') {
        await prefs.setString(_propHiddenHeadersPrefsKey, jsonEncode(_propertyListingHiddenHeaders.toList()));
      } else if (section == 'Requirement') {
        await prefs.setString(_reqHiddenHeadersPrefsKey, jsonEncode(_requirementHiddenHeaders.toList()));
      }
    } catch (_) {}
  }

  Future<bool> _saveSectionLayout(String? section, String? scope) {
    if (section == 'Property Listing' || section == 'Requirement') {
      return saveColumnLayoutToServer(section: section!, scope: scope ?? 'user');
    }
    return Future.value(true);
  }

  Future<bool> saveColumnLayoutToServer({
    required String section,
    required String scope, // 'user' or 'global'
  }) async {
    final normalizedScope = scope == 'global' ? 'global' : 'user';
    if (normalizedScope == 'global') {
      if (section == 'Property Listing') {
        await _persistSectionCustomHeaders('Property Listing');
        await _persistSectionHiddenHeaders('Property Listing');
        await _persistSectionHeaderOrder('Property Listing');
      } else if (section == 'Requirement') {
        await _persistSectionCustomHeaders('Requirement');
        await _persistSectionHiddenHeaders('Requirement');
        await _persistSectionHeaderOrder('Requirement');
      }
    } else {
      await _persistUserColumnLayout();
    }

    final payload = {
      'scope': normalizedScope,
      'section': section,
      'custom_headers': customHeadersFor(section).toList(),
      'hidden_headers': hiddenHeadersFor(section).toList(),
      'header_order': headerOrderFor(section).toList(),
    };

    try {
      final response = await _apiClient.post('/integrations/campaign-column-settings', payload);
      final ok = response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300;
      if (!ok) {
        debugPrint('[IntegrationService] column layout save failed: HTTP ${response.statusCode}');
      }
      return ok;
    } catch (e) {
      debugPrint('[IntegrationService] column layout save failed: $e');
      return false;
    }
  }

  Future<void> _persistUserColumnLayout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userLayoutPrefsKey, jsonEncode({
        'property_listing': {
          'custom_headers': _propertyListingCustomHeaders.toList(),
          'hidden_headers': _propertyListingHiddenHeaders.toList(),
          'header_order': _propertyListingHeaderOrder,
        },
        'requirement': {
          'custom_headers': _requirementCustomHeaders.toList(),
          'hidden_headers': _requirementHiddenHeaders.toList(),
          'header_order': _requirementHeaderOrder,
        },
      }));
    } catch (_) {}
  }

  Future<void> _loadUserColumnLayout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_userLayoutPrefsKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        _applyColumnSettingsFromMap(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {}
  }

  /// Fetch Column Layout settings from backend server DB.
  /// Personal layouts override the organization default for each section.
  Future<bool> fetchColumnLayoutFromServer() async {
    try {
      final response = await _apiClient.get('/integrations/campaign-column-settings');
      final body = response.data;
      if (body is! Map) return false;
      final nested = body['data'];
      final data = nested is Map
          ? Map<String, dynamic>.from(nested)
          : Map<String, dynamic>.from(body);
      if (!data.containsKey('property_listing') && !data.containsKey('requirement')) {
        return true;
      }
      _applyColumnSettingsFromMap(data);
      _invalidateHeaderCache();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[IntegrationService] column layout load failed: $e');
      return false;
    }
  }

  void _applyColumnSettingsFromMap(Map<String, dynamic> data) {
    if (data['property_listing'] is Map<String, dynamic>) {
      final propMap = data['property_listing'] as Map<String, dynamic>;
      if (propMap['custom_headers'] is List) {
        _propertyListingCustomHeaders.clear();
        _propertyListingCustomHeaders.addAll((propMap['custom_headers'] as List).map((e) => e.toString()));
      }
      if (propMap['hidden_headers'] is List) {
        _propertyListingHiddenHeaders.clear();
        _propertyListingHiddenHeaders.addAll((propMap['hidden_headers'] as List).map((e) => e.toString()));
      }
      if (propMap['header_order'] is List) {
        _propertyListingHeaderOrder = (propMap['header_order'] as List).map((e) => e.toString()).toList();
      }
    }

    if (data['requirement'] is Map<String, dynamic>) {
      final reqMap = data['requirement'] as Map<String, dynamic>;
      if (reqMap['custom_headers'] is List) {
        _requirementCustomHeaders.clear();
        _requirementCustomHeaders.addAll((reqMap['custom_headers'] as List).map((e) => e.toString()));
      }
      if (reqMap['hidden_headers'] is List) {
        _requirementHiddenHeaders.clear();
        _requirementHiddenHeaders.addAll((reqMap['hidden_headers'] as List).map((e) => e.toString()));
      }
      if (reqMap['header_order'] is List) {
        _requirementHeaderOrder = (reqMap['header_order'] as List).map((e) => e.toString()).toList();
      }
    }
  }

  /// Get currently visible headers for the table
  List<String> getActiveVisibleHeaders({List<IntegrationLeadModel>? leadsSubset, String? section}) {
    if (leadsSubset == null && section == null && _cachedVisibleHeaders != null) return _cachedVisibleHeaders!;
    final all = getDetectedHeaders(leadsSubset: leadsSubset, section: section);
    final hidden = hiddenHeadersFor(section);
    final visible = all.where((h) => !hidden.contains(h)).toList();
    if (leadsSubset == null && section == null) _cachedVisibleHeaders = visible;
    return visible;
  }

  Future<void> ensureLoaded() async {
    final campaignOff = RoleGuard.currentUser?.campaignEnabled == false &&
        RoleGuard.currentUser?.role.toLowerCase() != 'super admin';
    if (_loaded &&
        _loadedOrgScope == _orgScope &&
        _loadedCampaignOff == campaignOff) {
      return;
    }
    _loaded = true;
    _loadedOrgScope = _orgScope;
    _loadedCampaignOff = campaignOff;
    _leads = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      _googleSheetUrl = prefs.getString(_sheetUrlPrefsKey) ?? '';

      // Load saved header ordering preference
      final savedHeaderOrder = prefs.getString(_headerOrderPrefsKey);
      if (savedHeaderOrder != null && savedHeaderOrder.isNotEmpty) {
        try {
          final decoded = jsonDecode(savedHeaderOrder) as List<dynamic>;
          _headerOrder = decoded.map((e) => e.toString()).toList();
          _invalidateHeaderCache();
        } catch (_) {}
      }

      // 4. Load section-specific preferences
      final propOrder = prefs.getString(_propHeaderOrderPrefsKey);
      if (propOrder != null && propOrder.isNotEmpty) {
        try {
          final dec = jsonDecode(propOrder) as List<dynamic>;
          _propertyListingHeaderOrder = dec.map((e) => e.toString()).toList();
        } catch (_) {}
      }
      final reqOrder = prefs.getString(_reqHeaderOrderPrefsKey);
      if (reqOrder != null && reqOrder.isNotEmpty) {
        try {
          final dec = jsonDecode(reqOrder) as List<dynamic>;
          _requirementHeaderOrder = dec.map((e) => e.toString()).toList();
        } catch (_) {}
      }

      final propCustom = prefs.getString(_propCustomHeadersPrefsKey);
      if (propCustom != null && propCustom.isNotEmpty) {
        try {
          final dec = jsonDecode(propCustom) as List<dynamic>;
          _propertyListingCustomHeaders.addAll(dec.map((e) => e.toString()));
        } catch (_) {}
      }
      final reqCustom = prefs.getString(_reqCustomHeadersPrefsKey);
      if (reqCustom != null && reqCustom.isNotEmpty) {
        try {
          final dec = jsonDecode(reqCustom) as List<dynamic>;
          _requirementCustomHeaders.addAll(dec.map((e) => e.toString()));
        } catch (_) {}
      }

      final propHidden = prefs.getString(_propHiddenHeadersPrefsKey);
      if (propHidden != null && propHidden.isNotEmpty) {
        try {
          final dec = jsonDecode(propHidden) as List<dynamic>;
          _propertyListingHiddenHeaders.addAll(dec.map((e) => e.toString()));
        } catch (_) {}
      }
      final reqHidden = prefs.getString(_reqHiddenHeadersPrefsKey);
      if (reqHidden != null && reqHidden.isNotEmpty) {
        try {
          final dec = jsonDecode(reqHidden) as List<dynamic>;
          _requirementHiddenHeaders.addAll(dec.map((e) => e.toString()));
        } catch (_) {}
      }

      if (_googleSheetUrl.isNotEmpty) {
        _startSheetPolling();
      }
      // Fetch live leads directly from the database connection
      await fetchServerLeads(resetWithServer: true);
      final loadedLayout = await fetchColumnLayoutFromServer();
      if (!loadedLayout) {
        await _loadUserColumnLayout();
      }
    } catch (e) {
      debugPrint('Failed to load campaign leads: $e');
    }
    notifyListeners();
  }

  bool _isFetchingServerLeads = false;
  bool get isFetchingServerLeads => _isFetchingServerLeads;

  Future<int> fetchServerLeads({
    bool silent = false,
    bool resetWithServer = false,
    String? source,
  }) async {
    if (_isFetchingServerLeads) return 0;
    _isFetchingServerLeads = true;
    try {
      final queryParameters = <String, dynamic>{'limit': 1000};
      if (source != null && source.isNotEmpty && source != 'All') {
        queryParameters['source'] = source;
      }
      final response = await _apiClient.get(
        '/integrations/leads',
        queryParameters: queryParameters,
      );

      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        final List<dynamic> leadsList = data['leads'] ?? [];

        var incoming = <IntegrationLeadModel>[];
        final now = DateTime.now();
        // Clean up reclassification protection entries older than 60 seconds
        _recentlyReclassifiedLeads.removeWhere((_, entry) => now.difference(entry.$2).inSeconds > 60);

        for (final item in leadsList) {
          if (item is Map<String, dynamic>) {
            var model = IntegrationLeadModel.fromJson(item);
            final recent = _recentlyReclassifiedLeads[model.id] ??
                (model.externalLeadId != null ? _recentlyReclassifiedLeads[model.externalLeadId!] : null);
            if (recent != null && model.leadType != recent.$1) {
              String newStatus = model.campaignStatus;
              if (recent.$1 == 'Requirement' && (model.campaignStatus == 'Property Listed' || model.campaignStatus == 'Listed')) {
                newStatus = 'Archived';
              } else if (recent.$1 == 'Property Listing' && model.campaignStatus == 'Archived') {
                newStatus = 'Property Listed';
              }
              model = model.copyWith(
                leadType: recent.$1,
                campaignStatus: newStatus,
              );
            }
            incoming.add(model);
          }
        }

        if (incoming.isNotEmpty || resetWithServer) {
          if (resetWithServer) {
            final existingLocalMap = <String, IntegrationLeadModel>{for (final l in _leads) l.id: l};
            incoming = incoming.map((inc) {
              final local = existingLocalMap[inc.id] ?? (inc.externalLeadId != null ? existingLocalMap[inc.externalLeadId!] : null);
              if (local?.notInterestedReason != null &&
                  local!.notInterestedReason!.trim().isNotEmpty &&
                  (inc.notInterestedReason == null || inc.notInterestedReason!.trim().isEmpty)) {
                return inc.copyWith(notInterestedReason: local.notInterestedReason);
              }
              return inc;
            }).toList();

            if (source != null && source.isNotEmpty && source != 'All') {
              _leads = [
                ..._leads.where((l) => !matchesCampaignSource(l.source, source)),
                ...incoming,
              ];
            } else {
              _leads = incoming;
            }
          } else {
            // Build lookup of existing local leads for status and assignment preservation
            final existingLocalMap = <String, IntegrationLeadModel>{};
            for (final l in _leads) {
              existingLocalMap[l.id] = l;
              if (l.externalLeadId != null && l.externalLeadId!.isNotEmpty) {
                existingLocalMap[l.externalLeadId!] = l;
              }
            }

            final mergedIncoming = <IntegrationLeadModel>[];
            for (final inc in incoming) {
              final local = existingLocalMap[inc.id] ?? (inc.externalLeadId != null ? existingLocalMap[inc.externalLeadId!] : null);
              if (local != null) {
                final bool isIncDefault = inc.campaignStatus.isEmpty || inc.campaignStatus == 'New' || inc.campaignStatus == 'Pending';
                final String mergedStatus;
                if (!isIncDefault) {
                  mergedStatus = inc.campaignStatus;
                } else if (local.campaignStatus.isNotEmpty && local.campaignStatus != 'New') {
                  mergedStatus = local.campaignStatus;
                } else {
                  mergedStatus = inc.campaignStatus.isNotEmpty ? inc.campaignStatus : 'New';
                }
                final incomingIsFollowup = mergedStatus == 'Follow up' || mergedStatus == 'Follow-up';
                final incomingIsCallback = mergedStatus == 'Callback' || mergedStatus == 'Call Back';
                final merged = inc.copyWith(
                  leadType: (local.leadType != inc.leadType && local.leadType.isNotEmpty) ? local.leadType : inc.leadType,
                  campaignStatus: mergedStatus,
                  notInterestedReason: (inc.notInterestedReason != null && inc.notInterestedReason!.trim().isNotEmpty)
                      ? inc.notInterestedReason
                      : local.notInterestedReason,
                  allocationStatus: inc.allocationStatus ?? local.allocationStatus,
                  assignedTo: (inc.assignedTo != null && inc.assignedTo!.isNotEmpty) ? inc.assignedTo : local.assignedTo,
                  assignedToName: (inc.assignedToName != null && inc.assignedToName!.isNotEmpty) ? inc.assignedToName : local.assignedToName,
                  assignedTelecallerId: inc.assignedTelecallerId ?? local.assignedTelecallerId,
                  assignedTelecallerName: inc.assignedTelecallerName ?? local.assignedTelecallerName,
                  transferRemarks: (inc.transferRemarks != null && inc.transferRemarks!.isNotEmpty) ? inc.transferRemarks : local.transferRemarks,
                  interactedAt: inc.interactedAt ?? local.interactedAt,
                  interactedBy: (inc.interactedBy != null && inc.interactedBy!.isNotEmpty) ? inc.interactedBy : local.interactedBy,
                  followupScheduledAt: incomingIsFollowup ? (inc.followupScheduledAt ?? local.followupScheduledAt) : inc.followupScheduledAt,
                  followupRemarks: incomingIsFollowup
                      ? ((inc.followupRemarks != null && inc.followupRemarks!.isNotEmpty) ? inc.followupRemarks : local.followupRemarks)
                      : inc.followupRemarks,
                  followupStatus: incomingIsFollowup
                      ? ((inc.followupStatus != null && inc.followupStatus!.isNotEmpty) ? inc.followupStatus : local.followupStatus)
                      : (inc.followupStatus ?? 'Completed'),
                  callbackScheduledAt: incomingIsCallback ? (inc.callbackScheduledAt ?? local.callbackScheduledAt) : (inc.callbackScheduledAt ?? local.callbackScheduledAt),
                  callbackRemarks: incomingIsCallback
                      ? ((inc.callbackRemarks != null && inc.callbackRemarks!.isNotEmpty) ? inc.callbackRemarks : local.callbackRemarks)
                      : (inc.callbackRemarks ?? local.callbackRemarks),
                  callbackStatus: incomingIsCallback
                      ? ((inc.callbackStatus != null && inc.callbackStatus!.isNotEmpty) ? inc.callbackStatus : local.callbackStatus)
                      : (inc.callbackStatus ?? local.callbackStatus),
                  importStatus: local.importStatus == 'Imported' || inc.importStatus == 'Imported' ? 'Imported' : inc.importStatus,
                  importedClientId: (inc.importedClientId != null && inc.importedClientId!.isNotEmpty) ? inc.importedClientId : local.importedClientId,
                  clearFollowup: false,
                );
                mergedIncoming.add(merged);
              } else {
                mergedIncoming.add(inc);
              }
            }

            // Meta Ads leads are authoritative from the server; retain other sources (e.g. CSV/Google Sheets)
            final incomingIds = incoming.map((l) => l.id).toSet();
            final incomingExtIds = incoming.map((l) => l.externalLeadId).whereType<String>().toSet();
            final sourceScoped = source != null && source.isNotEmpty && source != 'All';
            final retained = _leads.where((l) {
              if (sourceScoped) {
                return !matchesCampaignSource(l.source, source);
              }
              final src = l.source.toUpperCase();
              final isServer = src.contains('META') || src.contains('HOUSING') || src.contains('ADS');
              return !isServer &&
                !incomingIds.contains(l.id) &&
                (l.externalLeadId == null || !incomingExtIds.contains(l.externalLeadId));
            }).toList();
            _leads = [...mergedIncoming, ...retained];
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
      await fetchServerLeads(resetWithServer: true, source: 'Meta Ads');
      await fetchHealthAlerts();
      final data = response.data is Map<String, dynamic> ? response.data as Map<String, dynamic> : {'success': true};
      if (data['metaAlert'] != null && data['metaAlert'] is Map) {
        final alert = Map<String, dynamic>.from(data['metaAlert'] as Map);
        _activeHealthAlerts = [alert, ..._activeHealthAlerts.where((a) => a['code'] != alert['code'])];
        _metaStatus = 'BLOCKED';
        notifyListeners();
      }
      return data;
    } catch (e) {
      debugPrint('Error syncing Meta leads: $e');
      await fetchHealthAlerts();
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> syncHousingLeads() async {
    try {
      final response = await _apiClient.post('/integrations/leads/sync-housing', {});
      await fetchServerLeads(resetWithServer: true, source: 'Housing.com');
      await fetchHealthAlerts();
      return response.data is Map<String, dynamic> ? response.data as Map<String, dynamic> : {'success': true};
    } catch (e) {
      debugPrint('Error syncing Housing leads: $e');
      await fetchHealthAlerts();
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Fetch diagnostic alerts and Meta status from backend health engine
  Future<void> fetchHealthAlerts() async {
    try {
      final response = await _apiClient.get('/health', queryParameters: {'deep': 'true', 'format': 'json'});
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        final alerts = data['activeAlerts'];
        if (alerts is List) {
          _activeHealthAlerts = alerts
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }
        _metaStatus = data['metaStatus']?.toString();
        if (data['leadsPipeline'] is Map) {
          _leadsPipelineInfo = Map<String, dynamic>.from(data['leadsPipeline']);
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[IntegrationService] fetchHealthAlerts error: $e');
    }
  }

  /// Real-time event handler for incoming leads from Supabase Realtime
  void handleRealtimeEvent(String eventType, Map<String, dynamic>? record, Map<String, dynamic>? oldRecord) {
    if (eventType == 'DELETE' && oldRecord != null) {
      final id = oldRecord['id']?.toString();
      if (id != null) {
        final before = _leads.length;
        _leads.removeWhere((l) => l.id == id);
        if (_leads.length != before) {
          _invalidateHeaderCache();
          notifyListeners();
          unawaited(_persistLeads());
        }
      }
    } else if (record != null) {
      try {
        final incomingLead = IntegrationLeadModel.fromJson(record);
        final index = _leads.indexWhere((l) => l.id == incomingLead.id);
        if (index != -1) {
          _leads[index] = incomingLead;
        } else {
          // Prepend new live lead at the top of the list
          _leads.insert(0, incomingLead);
          _updateDetectedHeadersFromRows([incomingLead.rawJson]);
          for (final k in incomingLead.rawJson.keys) {
            _autoSuggestMappingForHeader(k);
          }
        }
        _invalidateHeaderCache();
        notifyListeners();
        unawaited(_persistLeads());
      } catch (e) {
        debugPrint('[IntegrationService] handleRealtimeEvent error: $e');
      }
    }
  }

  /// Real-time event handler for campaign lead followups from Supabase Realtime
  void handleFollowupRealtimeEvent(String eventType, Map<String, dynamic>? record, Map<String, dynamic>? oldRecord) {
    if (record != null) {
      try {
        final leadId = record['lead_id']?.toString();
        if (leadId != null) {
          final index = _leads.indexWhere((l) => l.id == leadId);
          if (index != -1) {
            final lead = _leads[index];
            final scheduledAt = record['scheduled_at'] != null ? DateTime.tryParse(record['scheduled_at'].toString()) : lead.followupScheduledAt;
            final remarks = record['remarks']?.toString() ?? lead.followupRemarks;
            final status = record['status']?.toString() ?? lead.followupStatus;
            final isPending = status == 'Pending';
            const protectedStatuses = {
              'CNR',
              'Assigned',
              'Picked Up',
              'Interested',
              'Not interested',
              'Property Listed',
              'Listed',
              'Archived',
              'Closed',
              'Won',
            };
            final keepCurrentStatus = protectedStatuses.contains(lead.campaignStatus);
            _leads[index] = lead.copyWith(
              campaignStatus: isPending
                  ? (keepCurrentStatus ? lead.campaignStatus : 'Follow up')
                  : (lead.campaignStatus == 'Follow up' || lead.campaignStatus == 'Follow-up' ? 'New' : lead.campaignStatus),
              followupScheduledAt: isPending && !keepCurrentStatus ? scheduledAt : null,
              followupRemarks: remarks,
              followupStatus: status,
              clearFollowup: !isPending || keepCurrentStatus,
            );
            notifyListeners();
            unawaited(_persistLeads());
          }
        }
      } catch (e) {
        debugPrint('[IntegrationService] handleFollowupRealtimeEvent error: $e');
      }
    }
  }

  /// Update a lead's campaign status ('Follow up', 'Interested', 'Not interested', 'CNR', 'Property Listed', 'Archived', etc.)
  Future<bool> updateLeadCampaignStatus(String leadId, String status, {String? reason}) async {
    try {
      // 1. Optimistically update in memory & persist to local DB immediately
      final target = leadId.trim().toLowerCase();
      final idx = _leads.indexWhere((l) {
        if (l.id.toLowerCase() == target) return true;
        if (l.externalLeadId != null && l.externalLeadId!.toLowerCase() == target) return true;
        final rawId = l.rawJson['id']?.toString().toLowerCase();
        if (rawId != null && rawId == target) return true;
        final legacyId = (l.rawJson['legacy_integration_lead_id'] ?? l.rawJson['legacyIntegrationLeadId'])?.toString().toLowerCase();
        if (legacyId != null && legacyId == target) return true;
        return false;
      });
      if (idx != -1) {
        final isFollowup = status == 'Follow up' || status == 'Follow-up';
        final currentUserName = RoleGuard.currentUser?.fullName ?? RoleGuard.currentUser?.email ?? '';
        final currentUserId = RoleGuard.currentUser?.id;
        final currentRaw = Map<String, dynamic>.from(_leads[idx].rawJson);
        final cleanReason = reason?.trim();
        if (status == 'Not interested' && cleanReason != null && cleanReason.isNotEmpty) {
          currentRaw['not_interested_reason'] = cleanReason;
          currentRaw['not_interested_notes'] = cleanReason;
        }
        _leads[idx] = _leads[idx].copyWith(
          campaignStatus: status,
          allocationStatus: status == 'Not interested' ? 'RELEASED' : _leads[idx].allocationStatus,
          rawJson: currentRaw,
          statusUpdatedByName: currentUserName.isNotEmpty ? currentUserName : _leads[idx].statusUpdatedByName,
          statusUpdatedById: currentUserId ?? _leads[idx].statusUpdatedById,
          statusUpdatedAt: DateTime.now(),
          notInterestedByName: status == 'Not interested' ? currentUserName : _leads[idx].notInterestedByName,
          notInterestedById: status == 'Not interested' ? currentUserId : _leads[idx].notInterestedById,
          notInterestedAt: status == 'Not interested' ? DateTime.now() : _leads[idx].notInterestedAt,
          notInterestedReason: (status == 'Not interested' && cleanReason != null && cleanReason.isNotEmpty)
              ? cleanReason
              : _leads[idx].notInterestedReason,
          archivedByName: (status == 'Archived' || status == 'Property Listed' || status == 'Listed') ? currentUserName : _leads[idx].archivedByName,
          archivedById: (status == 'Archived' || status == 'Property Listed' || status == 'Listed') ? currentUserId : _leads[idx].archivedById,
          archivedAt: (status == 'Archived' || status == 'Property Listed' || status == 'Listed') ? DateTime.now() : _leads[idx].archivedAt,
          followupScheduledAt: isFollowup ? _leads[idx].followupScheduledAt : null,
          followupStatus: isFollowup ? _leads[idx].followupStatus : 'Completed',
          clearFollowup: !isFollowup,
        );
        notifyListeners();
        await _persistLeads();
      }

      // 2. Persist to backend
      final payload = <String, dynamic>{'status': status};
      if (reason != null && reason.trim().isNotEmpty) {
        payload['reason'] = reason.trim();
        payload['notes'] = reason.trim();
      }
      final res = await _apiClient.patch('/integrations/leads/$leadId/campaign-status', payload);

      if (res.statusCode != null && res.statusCode! >= 200 && res.statusCode! < 300) {
        if (res.data is Map && res.data['lead'] is Map) {
          try {
            final updatedLead = IntegrationLeadModel.fromJson(Map<String, dynamic>.from(res.data['lead']));
            final leadIdx = _leads.indexWhere((l) {
              if (l.id.toLowerCase() == target) return true;
              if (l.externalLeadId != null && l.externalLeadId!.toLowerCase() == target) return true;
              final rawId = l.rawJson['id']?.toString().toLowerCase();
              if (rawId != null && rawId == target) return true;
              final legacyId = (l.rawJson['legacy_integration_lead_id'] ?? l.rawJson['legacyIntegrationLeadId'])?.toString().toLowerCase();
              if (legacyId != null && legacyId == target) return true;
              return false;
            });
            if (leadIdx != -1) {
              final isFollowup = status == 'Follow up' || status == 'Follow-up';
              final cleanReason = reason?.trim();
              _leads[leadIdx] = updatedLead.copyWith(
                campaignStatus: status,
                allocationStatus: status == 'Not interested' ? 'RELEASED' : (updatedLead.allocationStatus ?? _leads[leadIdx].allocationStatus),
                notInterestedReason: (status == 'Not interested' && cleanReason != null && cleanReason.isNotEmpty)
                    ? cleanReason
                    : (updatedLead.notInterestedReason ?? _leads[leadIdx].notInterestedReason),
                assignedTelecallerId: updatedLead.assignedTelecallerId ?? _leads[leadIdx].assignedTelecallerId,
                assignedTelecallerName: updatedLead.assignedTelecallerName ?? _leads[leadIdx].assignedTelecallerName,
                assignedTo: updatedLead.assignedTo ?? _leads[leadIdx].assignedTo,
                assignedToName: updatedLead.assignedToName ?? _leads[leadIdx].assignedToName,
                followupScheduledAt: isFollowup ? updatedLead.followupScheduledAt : null,
                followupStatus: isFollowup ? updatedLead.followupStatus : 'Completed',
                clearFollowup: !isFollowup,
              );
              notifyListeners();
              await _persistLeads();
            }
          } catch (_) {}
        }
        leadEvents.add({'leadId': leadId, 'status': status, 'type': 'STATUS_UPDATED'});
        unawaited(fetchServerLeads(resetWithServer: true));
        return true;
      }

      return res.statusCode != null && res.statusCode! >= 200 && res.statusCode! < 300;
    } catch (e) {
      debugPrint('[IntegrationService] Error updating campaign status for $leadId: $e');
      return false;
    }
  }

  /// Bulk updates campaign status for multiple leads (e.g., 'Property Listed', 'Archived', 'Not interested')
  Future<bool> bulkUpdateCampaignStatus(List<String> leadIds, String status, {String? reason}) async {
    try {
      final isFollowup = status == 'Follow up' || status == 'Follow-up';
      final cleanReason = reason?.trim();
      for (final leadId in leadIds) {
        final idx = _leads.indexWhere((l) => l.id == leadId || l.externalLeadId == leadId);
        if (idx != -1) {
          final currentRaw = Map<String, dynamic>.from(_leads[idx].rawJson);
          if (status == 'Not interested' && cleanReason != null && cleanReason.isNotEmpty) {
            currentRaw['not_interested_reason'] = cleanReason;
            currentRaw['not_interested_notes'] = cleanReason;
          }
          _leads[idx] = _leads[idx].copyWith(
            campaignStatus: status,
            rawJson: currentRaw,
            notInterestedReason: (status == 'Not interested' && cleanReason != null && cleanReason.isNotEmpty)
                ? cleanReason
                : _leads[idx].notInterestedReason,
            followupScheduledAt: isFollowup ? _leads[idx].followupScheduledAt : null,
            followupStatus: isFollowup ? _leads[idx].followupStatus : 'Completed',
            clearFollowup: !isFollowup,
          );
        }
      }
      notifyListeners();
      await _persistLeads();

      final results = await Future.wait(leadIds.map((id) => updateLeadCampaignStatus(id, status, reason: reason)));
      return results.every((ok) => ok);
    } catch (e) {
      debugPrint('[IntegrationService] Error bulk updating campaign status: $e');
      return false;
    }
  }

  /// Schedule a follow-up or callback for a campaign lead
  Future<bool> scheduleFollowup(
    String leadId,
    DateTime scheduledAt,
    String remarks, {
    String status = 'Follow up',
  }) async {
    try {
      final isCb = status.trim().toLowerCase() == 'callback' || status.trim().toLowerCase() == 'call back';
      final finalStatus = isCb ? 'Callback' : 'Follow up';
      final finalAllocStatus = isCb ? 'CALLBACK' : 'FOLLOWUP';
      final outcomeName = isCb ? 'CALLBACK' : 'FOLLOWUP';

      // 1. Optimistically update in memory
      final idx = _leads.indexWhere((l) => l.id == leadId);
      if (idx != -1) {
        if (isCb) {
          _leads[idx] = _leads[idx].copyWith(
            campaignStatus: finalStatus,
            allocationStatus: finalAllocStatus,
            callbackScheduledAt: scheduledAt,
            callbackRemarks: remarks,
            callbackStatus: 'Pending',
            interactedAt: DateTime.now(),
          );
        } else {
          _leads[idx] = _leads[idx].copyWith(
            campaignStatus: finalStatus,
            allocationStatus: finalAllocStatus,
            followupScheduledAt: scheduledAt,
            followupRemarks: remarks,
            followupStatus: 'Pending',
            assignedTelecallerId: RoleGuard.isTelecaller(RoleGuard.currentUser?.role)
                ? (RoleGuard.currentUser?.id ?? _leads[idx].assignedTelecallerId)
                : _leads[idx].assignedTelecallerId,
            assignedTelecallerName: RoleGuard.isTelecaller(RoleGuard.currentUser?.role)
                ? (RoleGuard.currentUser?.fullName ?? _leads[idx].assignedTelecallerName)
                : _leads[idx].assignedTelecallerName,
            interactedAt: DateTime.now(),
          );
        }
        notifyListeners();
        unawaited(_persistLeads());
      }

      // 2. Persist to backend dedicated table
      final res = await _apiClient.post('/integrations/leads/$leadId/followups', {
        'scheduledAt': scheduledAt.toIso8601String(),
        'remarks': remarks,
        'status': finalStatus,
        'outcome': outcomeName,
      });

      final scheduledOk = res.statusCode != null && res.statusCode! >= 200 && res.statusCode! < 300;
      if (scheduledOk) {
        notifyOutcomeRecorded(
          leadId,
          outcome: outcomeName,
          remarks: remarks,
          callbackAt: scheduledAt.toUtc().toIso8601String(),
        );
        final lead = idx != -1 ? _leads[idx] : null;
        final name = lead != null
            ? (lead.getStringValue('Client Name').isNotEmpty
                ? lead.getStringValue('Client Name')
                : (lead.getStringValue('full_name').isNotEmpty
                    ? lead.getStringValue('full_name')
                    : lead.getStringValue('Client / Owner Name')))
            : '';
        final display = name.isNotEmpty ? name : 'client';
        unawaited(NotificationCenter.addNotification(
          title: isCb ? 'Callback scheduled' : 'Follow-up scheduled',
          message: '${isCb ? "Callback" : "Follow-up"} for client "$display" has been scheduled.',
          type: isCb ? 'callback' : 'followup',
          route: '/campaign/leads',
        ));
      }
      return scheduledOk;
    } catch (e) {
      debugPrint('[IntegrationService] Error scheduling follow-up for $leadId: $e');
      return false;
    }
  }

  /// Transfer and assign a campaign lead
  /// Handles CNR (marking as interacted) and Picked Up (assigning to team member with remarks)
  Future<Map<String, dynamic>> transferLead(
    String leadId, {
    required String status,
    String? assignedTo,
    String? assignedToName,
    String? remarks,
  }) async {
      final isCnr = status.trim().toUpperCase() == 'CNR';
      final isCallback = status.trim().toUpperCase() == 'CALLBACK' || status.trim().toLowerCase() == 'callback' || status.trim().toLowerCase() == 'call back';
      final isFollowup = status.trim().toLowerCase() == 'follow up' || status.trim().toLowerCase() == 'follow-up' || status.trim().toLowerCase() == 'follow-ups';
      final finalStatus = isCnr ? 'CNR' : (isCallback ? 'Callback' : (isFollowup ? 'Follow up' : 'Assigned'));
      final finalAllocationStatus = isCnr ? 'CNR' : (isCallback ? 'CALLBACK' : (isFollowup ? 'FOLLOWUP' : 'HANDED_TO_SALES'));
      final now = DateTime.now();
      final user = RoleGuard.currentUser;

    IntegrationLeadModel? previousLead;
    final idx = _leads.indexWhere((l) => l.id == leadId);

    Future<void> rollbackOptimistic() async {
      if (previousLead != null && idx != -1) {
        _leads[idx] = previousLead!;
        notifyListeners();
        unawaited(_persistLeads());
      }
    }

    String _transferErrorMessage(Object e) {
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null && data['message'].toString().trim().isNotEmpty) {
          return data['message'].toString();
        }
        if (e.response?.statusCode != null) {
          return 'Failed to transfer lead (HTTP ${e.response!.statusCode}).';
        }
      }
      final raw = e.toString().replaceAll('Exception: ', '');
      if (raw.contains('DioException')) {
        return 'Failed to transfer lead. Please try again.';
      }
      return raw;
    }

    try {
      // 1. Optimistically update in memory & notify UI immediately (0ms delay)
      if (idx != -1) {
        previousLead = _leads[idx];
        final currentRaw = Map<String, dynamic>.from(_leads[idx].rawJson);
        if (isCnr) {
          currentRaw['_transfer'] = {
            'status': 'CNR',
            'remarks': remarks ?? 'Marked as CNR',
            'interacted_at': now.toIso8601String(),
            'interacted_by': user?.id,
          };
        }
        _leads[idx] = _leads[idx].copyWith(
          campaignStatus: finalStatus,
          allocationStatus: finalAllocationStatus,
          assignedTelecallerId: (RoleGuard.isTelecaller(user?.role) ? (user?.id ?? _leads[idx].assignedTelecallerId) : (_leads[idx].assignedTelecallerId ?? user?.id)),
          assignedTo: (isCnr || isCallback || isFollowup) ? _leads[idx].assignedTo : assignedTo,
          assignedToName: (isCnr || isCallback || isFollowup) ? _leads[idx].assignedToName : assignedToName,
          transferRemarks: (isCnr || isCallback || isFollowup) ? _leads[idx].transferRemarks : remarks,
          interactedAt: now,
          interactedBy: user?.fullName,
          importStatus: (isCnr || isCallback || isFollowup) ? _leads[idx].importStatus : 'Imported',
          clearFollowup: isCnr,
          clearCallback: isCnr,
          rawJson: currentRaw,
        );
        notifyListeners();
        unawaited(_persistLeads());
      }

      // 2. Persist to backend API (~50ms network call)
      final res = await _apiClient.post('/integrations/leads/$leadId/transfer', {
        'status': status,
        'assignedTo': assignedTo,
        'remarks': remarks,
      });

      final ok = res.statusCode != null && res.statusCode! >= 200 && res.statusCode! < 300;
      if (!ok) {
        await rollbackOptimistic();
        await fetchServerLeads(resetWithServer: true);
        final data = res.data is Map ? Map<String, dynamic>.from(res.data) : <String, dynamic>{};
        final errMessage = (data['message'] ?? 'Failed to transfer lead (HTTP ${res.statusCode}).').toString();
        return {'success': false, 'message': errMessage};
      }

      // 3. Notify and refresh CRM once. Backend transfer already writes assigned_to.
      if (!isCnr && !isCallback && assignedTo != null && assignedTo.isNotEmpty) {
        final targetLead = idx != -1 ? _leads[idx] : null;
        final leadName = targetLead != null ? _mapLeadFields(targetLead)['name'] : null;
        final displayName = (leadName != null && leadName.isNotEmpty) ? leadName : 'Lead';
        final transferData = res.data is Map ? Map<String, dynamic>.from(res.data) : <String, dynamic>{};
        final nestedData = transferData['data'] is Map
            ? Map<String, dynamic>.from(transferData['data'] as Map)
            : transferData;
        final requirementId = (nestedData['requirementId'] ??
                nestedData['requirement_id'] ??
                transferData['requirementId'] ??
                transferData['requirement_id'] ??
                '')
            .toString();
        unawaited(NotificationCenter.addNotification(
          title: 'Lead assigned',
          message: 'You assigned client "$displayName" to ${assignedToName ?? "Sales"}.',
          type: 'lead_assigned',
          route: '/requirements?group=assigned',
          payload: {
            'clientName': displayName,
            'assigneeName': assignedToName,
            'assignerName': user?.fullName,
            'assignedTo': assignedTo,
            'audience': 'assigner',
            'campaignLeadId': leadId,
            if (requirementId.isNotEmpty && requirementId != 'null') 'requirementId': requirementId,
          },
        ));

        if (targetLead?.leadType == 'Property Listing') {
          unawaited(importLeadsToProperties([leadId], skipFetchServerLeads: true));
        } else if (requirementId.isNotEmpty && requirementId != 'null') {
          unawaited(_requirementsRepository.refreshFromServerNow());
        } else {
          unawaited(importLeadsToCrm([leadId], forceReimport: true, skipFetchServerLeads: true));
        }
        unawaited(_requirementsRepository.getRequirements(refreshFromServer: true));
      }

      final data = res.data is Map ? Map<String, dynamic>.from(res.data) : <String, dynamic>{};
      if (data['lead'] != null && data['lead'] is Map) {
        try {
          final updatedLead = IntegrationLeadModel.fromJson(Map<String, dynamic>.from(data['lead']));
          final leadIdx = _leads.indexWhere((l) => l.id == leadId);
          if (leadIdx != -1) {
            _leads[leadIdx] = updatedLead.copyWith(
              campaignStatus: finalStatus,
              allocationStatus: finalAllocationStatus,
              assignedTo: (isCnr || isCallback) ? _leads[leadIdx].assignedTo : (assignedTo ?? updatedLead.assignedTo),
              assignedToName: (isCnr || isCallback) ? _leads[leadIdx].assignedToName : (assignedToName ?? updatedLead.assignedToName),
              assignedTelecallerId: updatedLead.assignedTelecallerId ?? _leads[leadIdx].assignedTelecallerId,
              assignedTelecallerName: updatedLead.assignedTelecallerName ?? _leads[leadIdx].assignedTelecallerName,
              transferRemarks: remarks ?? updatedLead.transferRemarks,
              importStatus: (isCnr || isCallback) ? _leads[leadIdx].importStatus : 'Imported',
              clearFollowup: !isCallback,
            );
            notifyListeners();
            unawaited(_persistLeads());
          }
        } catch (_) {}
      }
      leadEvents.add({
        'leadId': leadId,
        'status': finalStatus,
        'allocationStatus': finalAllocationStatus,
        'type': 'TRANSFER_COMPLETED'
      });
      unawaited(fetchServerLeads(resetWithServer: true));
      return {'success': true, 'message': data['message'] ?? 'Lead transferred successfully'};
    } catch (e) {
      debugPrint('[IntegrationService] Error transferring lead $leadId: $e');
      await rollbackOptimistic();
      try {
        await fetchServerLeads(resetWithServer: true);
      } catch (_) {}
      return {'success': false, 'message': _transferErrorMessage(e)};
    }
  }

  static const _peerTransferLogKey = 'peer_telecaller_transfer_log_v1';

  String _peerTransferScopeKey() => '${_orgScope}_$_peerTransferLogKey';

  /// History of leads moved from one telecaller to another. Admin allocation
  /// merges this with the server assignment feed.
  Future<List<Map<String, dynamic>>> peerTransferHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_peerTransferScopeKey());
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      debugPrint('[IntegrationService] peerTransferHistory error: $e');
      return [];
    }
  }

  Future<void> _appendPeerTransferLog(Map<String, dynamic> entry) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await peerTransferHistory();
    existing.insert(0, entry);
    final trimmed = existing.length > 300 ? existing.sublist(0, 300) : existing;
    await prefs.setString(_peerTransferScopeKey(), jsonEncode(trimmed));
  }

  String _leadDisplayName(IntegrationLeadModel? lead) {
    if (lead == null) return 'Lead';
    for (final key in ['full_name', 'name', 'Client Name', 'Client / Owner Name']) {
      final value = lead.getStringValue(key).trim();
      if (value.isNotEmpty) return value;
    }
    return 'Lead';
  }

  String _leadPhone(IntegrationLeadModel? lead) {
    if (lead == null) return '';
    for (final key in ['phone_number', 'phone', 'Phone Number', 'mobile']) {
      final value = lead.getStringValue(key).trim();
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  /// Hand an allocated lead from the signed-in telecaller to a partner telecaller.
  /// Follow-ups, callbacks, and CNR stay on the lead and follow the new owner.
  Future<Map<String, dynamic>> transferLeadToPartnerTelecaller(
    String leadId, {
    required String toTelecallerId,
    required String toTelecallerName,
    String? reason,
  }) async {
    final user = RoleGuard.currentUser;
    final fromId = user?.id.trim() ?? '';
    final fromName = (user != null && user.fullName.trim().isNotEmpty)
        ? user.fullName.trim()
        : (user?.email ?? 'Telecaller');
    final destId = toTelecallerId.trim();
    final destName = toTelecallerName.trim().isEmpty ? 'Telecaller' : toTelecallerName.trim();
    if (destId.isEmpty || destId == fromId) {
      return {'success': false, 'message': 'Choose a different telecaller.'};
    }

    final idx = _leads.indexWhere(
      (l) => l.id == leadId || (l.externalLeadId != null && l.externalLeadId == leadId),
    );
    IntegrationLeadModel? previous;
    final now = DateTime.now();
    final note = (reason ?? '').trim();

    Future<void> rollback() async {
      if (previous != null && idx != -1 && idx < _leads.length) {
        _leads[idx] = previous!;
        notifyListeners();
        await _persistLeads();
      }
    }

    if (idx != -1) {
      previous = _leads[idx];
      final raw = Map<String, dynamic>.from(_leads[idx].rawJson);
      final history = raw['_peer_transfers'] is List
          ? List<dynamic>.from(raw['_peer_transfers'] as List)
          : <dynamic>[];
      history.insert(0, {
        'from_telecaller_id': fromId,
        'from_telecaller_name': fromName,
        'to_telecaller_id': destId,
        'to_telecaller_name': destName,
        'reason': note,
        'transferred_at': now.toIso8601String(),
      });
      raw['_peer_transfers'] = history;
      raw['assigned_telecaller_id'] = destId;
      raw['assigned_telecaller_name'] = destName;
      _leads[idx] = _leads[idx].copyWith(
        assignedTelecallerId: destId,
        assignedTelecallerName: destName,
        telecallerAssignedAt: now,
        allocationStatus: 'ASSIGNED',
        rawJson: raw,
        transferRemarks: note.isNotEmpty ? note : _leads[idx].transferRemarks,
      );
      notifyListeners();
      unawaited(_persistLeads());
    }

    final reasonText = note.isEmpty ? 'Transferred by $fromName to $destName' : note;
    final payload = <String, dynamic>{
      'leadId': leadId,
      'toTelecallerId': destId,
      'toTelecallerName': destName,
      'fromTelecallerId': fromId,
      'fromTelecallerName': fromName,
      'reason': reasonText,
      'assignmentType': 'PEER_TRANSFER',
      'overrideEligibility': true,
    };

    try {
      Response res = await _apiClient.post(ApiConstants.telecallerTransferLead, payload);

      final ok = res.statusCode != null && res.statusCode! >= 200 && res.statusCode! < 300;
      if (!ok) {
        await rollback();
        await fetchServerLeads(resetWithServer: true);
        return {'success': false, 'message': 'Failed to transfer this lead.'};
      }

      final moved = idx != -1 ? _leads[idx] : previous;
      await _appendPeerTransferLog({
        'lead_id': leadId,
        'lead_name': _leadDisplayName(moved),
        'lead_phone': _leadPhone(moved),
        'lead_campaign': moved?.source ?? '',
        'assignment_type': 'PEER_TRANSFER',
        'from_telecaller_id': fromId,
        'from_telecaller_name': fromName,
        'to_telecaller_id': destId,
        'to_telecaller_name': destName,
        'reason': reasonText,
        'assigned_at': now.toIso8601String(),
      });

      leadEvents.add({
        'leadId': leadId,
        'type': 'PEER_TRANSFER',
        'fromTelecallerId': fromId,
        'toTelecallerId': destId,
      });
      unawaited(fetchServerLeads(resetWithServer: true));
      return {'success': true, 'message': 'Lead transferred to $destName'};
    } catch (e) {
      debugPrint('[IntegrationService] partner transfer failed for $leadId: $e');
      await rollback();
      try {
        await fetchServerLeads(resetWithServer: true);
      } catch (_) {}
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null && data['message'].toString().trim().isNotEmpty) {
          return {'success': false, 'message': data['message'].toString()};
        }
        if (e.response?.statusCode != null) {
          return {
            'success': false,
            'message': 'Failed to transfer lead (HTTP ${e.response!.statusCode}).',
          };
        }
      }
      return {'success': false, 'message': 'Failed to transfer lead. Please try again.'};
    }
  }

  /// Synchronize in-memory leads and trigger server parity when a telecaller records an outcome anywhere
  void notifyOutcomeRecorded(
    String leadId, {
    required String outcome,
    String? remarks,
    String? salesUserId,
    String? assignedToName,
    String? callbackAt,
  }) {
    final normOutcome = outcome.trim().toUpperCase();
    final isCnr = normOutcome == 'CNR';
    final isCallback = normOutcome == 'CALLBACK' || normOutcome == 'CALL BACK';
    final isFollowup = normOutcome == 'FOLLOWUP' || normOutcome == 'FOLLOW UP' || normOutcome == 'FOLLOW-UP';
    final isPickedUp = normOutcome == 'PICKED_UP' || normOutcome == 'PICKED UP' || normOutcome == 'ASSIGNED';
    final isNotInterested = normOutcome == 'NOT_INTERESTED' || normOutcome == 'NOT INTERESTED';

    final finalStatus = isCnr
        ? 'CNR'
        : (isCallback
            ? 'Callback'
            : (isFollowup
                ? 'Follow up'
                : (isPickedUp ? 'Assigned' : (isNotInterested ? 'Not interested' : normOutcome))));
    final finalAllocStatus = isCnr
        ? 'CNR'
        : (isCallback
            ? 'CALLBACK'
            : (isFollowup
                ? 'FOLLOWUP'
                : (isPickedUp ? 'HANDED_TO_SALES' : (isNotInterested ? 'RELEASED' : normOutcome))));
    final now = DateTime.now();
    final user = RoleGuard.currentUser;

    final target = leadId.trim().toLowerCase();
    final idx = _leads.indexWhere((l) {
      if (l.id.toLowerCase() == target) return true;
      if (l.externalLeadId != null && l.externalLeadId!.toLowerCase() == target) return true;
      final rawId = l.rawJson['id']?.toString().toLowerCase();
      if (rawId != null && rawId == target) return true;
      final legacyId = (l.rawJson['legacy_integration_lead_id'] ?? l.rawJson['legacyIntegrationLeadId'])?.toString().toLowerCase();
      if (legacyId != null && legacyId == target) return true;
      return false;
    });
    if (idx != -1) {
      final lead = _leads[idx];
      DateTime? parsedCallback;
      if (callbackAt != null) {
        parsedCallback = DateTime.tryParse(callbackAt);
      }
      final currentRaw = Map<String, dynamic>.from(lead.rawJson);
      if (isNotInterested) {
        if (remarks != null && remarks.isNotEmpty) {
          currentRaw['not_interested_reason'] = remarks;
          currentRaw['not_interested_notes'] = remarks;
        }
        if (user != null) {
          currentRaw['not_interested_by_id'] = user.id;
          currentRaw['not_interested_by_name'] = user.fullName.isNotEmpty ? user.fullName : user.email;
          currentRaw['not_interested_at'] = now.toIso8601String();
        }
      }
      if (isCnr) {
        currentRaw['_transfer'] = {
          'status': 'CNR',
          'remarks': remarks ?? 'Marked as CNR',
          'interacted_at': now.toIso8601String(),
          'interacted_by': user?.id,
        };
      }
      if (isCallback) {
        currentRaw['_callback'] = {
          'scheduled_at': callbackAt,
          'remarks': remarks,
          'status': 'Pending',
          'interacted_at': now.toIso8601String(),
        };
      } else if (isFollowup) {
        currentRaw['_followup'] = {
          'scheduled_at': callbackAt,
          'remarks': remarks,
          'status': 'Pending',
          'interacted_at': now.toIso8601String(),
        };
      }
      _leads[idx] = lead.copyWith(
        campaignStatus: finalStatus,
        allocationStatus: finalAllocStatus,
        assignedTelecallerId: (RoleGuard.isTelecaller(user?.role) ? (user?.id ?? lead.assignedTelecallerId) : (lead.assignedTelecallerId ?? user?.id)),
        rawJson: currentRaw,
        notInterestedReason: isNotInterested ? (remarks ?? lead.notInterestedReason) : lead.notInterestedReason,
        notInterestedByName: isNotInterested ? (user != null && user.fullName.isNotEmpty ? user.fullName : lead.notInterestedByName) : lead.notInterestedByName,
        notInterestedById: isNotInterested ? (user?.id ?? lead.notInterestedById) : lead.notInterestedById,
        notInterestedAt: isNotInterested ? now : lead.notInterestedAt,
        assignedTo: isPickedUp ? (salesUserId ?? lead.assignedTo) : lead.assignedTo,
        assignedToName: isPickedUp ? (assignedToName ?? lead.assignedToName) : lead.assignedToName,
        transferRemarks: (isPickedUp || isCnr) ? (remarks ?? lead.transferRemarks) : lead.transferRemarks,
        interactedAt: now,
        interactedBy: user?.fullName ?? lead.interactedBy,
        followupScheduledAt: isFollowup ? (parsedCallback ?? lead.followupScheduledAt) : (isPickedUp || isNotInterested || isCnr ? null : lead.followupScheduledAt),
        followupRemarks: isFollowup ? (remarks ?? lead.followupRemarks) : (isPickedUp || isNotInterested || isCnr ? null : lead.followupRemarks),
        followupStatus: isFollowup ? 'Pending' : (isPickedUp || isNotInterested ? 'Completed' : (isCnr ? null : lead.followupStatus)),
        callbackScheduledAt: isCallback ? (parsedCallback ?? lead.callbackScheduledAt) : (isPickedUp || isNotInterested || isCnr ? null : lead.callbackScheduledAt),
        callbackRemarks: isCallback ? (remarks ?? lead.callbackRemarks) : (isPickedUp || isNotInterested || isCnr ? null : lead.callbackRemarks),
        callbackStatus: isCallback ? 'Pending' : (isPickedUp || isNotInterested ? 'Completed' : (isCnr ? null : lead.callbackStatus)),
        clearFollowup: isPickedUp || isNotInterested || isCnr,
        clearCallback: isPickedUp || isNotInterested || isCnr,
      );
      notifyListeners();
      unawaited(_persistLeads());
    }

    // Broadcast event across all blocs and screens
    leadEvents.add({
      'leadId': leadId,
      'outcome': normOutcome,
      'type': 'OUTCOME_RECORDED'
    });

    // Background sync with server to ensure 100% database parity
    unawaited(fetchServerLeads(resetWithServer: true));
  }

  /// Retrieve lead model from memory cache if available
  IntegrationLeadModel? getLeadById(String leadId) {
    try {
      return _leads.firstWhere((l) => l.id == leadId || (l.externalLeadId != null && l.externalLeadId == leadId));
    } catch (_) {
      return null;
    }
  }

  /// Retrieve or fetch complete lead model
  Future<IntegrationLeadModel?> fetchLeadById(String leadId) async {
    final local = getLeadById(leadId);
    if (local != null) return local;
    try {
      final res = await _apiClient.get('/integrations/leads/$leadId');
      if (res.data is Map<String, dynamic>) {
        final data = res.data as Map<String, dynamic>;
        final leadData = data['lead'] ?? data;
        if (leadData is Map<String, dynamic>) {
          return IntegrationLeadModel.fromJson(leadData);
        }
      }
    } catch (_) {}
    return null;
  }

  /// Synchronously and optimistically reclassifies lead in local memory on the first click
  void reclassifyLeadOptimistic(String leadId, String targetLeadType) {
    _recentlyReclassifiedLeads[leadId] = (targetLeadType, DateTime.now());
    int idx = _leads.indexWhere((l) => l.id == leadId);
    if (idx == -1) {
      idx = _leads.indexWhere((l) => l.externalLeadId == leadId);
    }
    if (idx != -1) {
      final current = _leads[idx];
      if (current.externalLeadId != null && current.externalLeadId!.isNotEmpty) {
        _recentlyReclassifiedLeads[current.externalLeadId!] = (targetLeadType, DateTime.now());
      }
      String newCampaignStatus = current.campaignStatus;
      if (targetLeadType == 'Requirement' && (current.campaignStatus == 'Property Listed' || current.campaignStatus == 'Listed')) {
        newCampaignStatus = 'Archived';
      } else if (targetLeadType == 'Property Listing' && current.campaignStatus == 'Archived') {
        newCampaignStatus = 'Property Listed';
      }
      _leads[idx] = current.copyWith(
        leadType: targetLeadType,
        campaignStatus: newCampaignStatus,
      );
      notifyListeners();
      unawaited(_persistLeads());
    }
  }

  /// Optimistically reclassifies multiple leads in local memory
  void bulkReclassifyLeadsOptimistic(List<String> leadIds, String targetLeadType) {
    for (final id in leadIds) {
      reclassifyLeadOptimistic(id, targetLeadType);
    }
  }

  /// Bulk reclassify leads between 'Requirement' and 'Property Listing'
  Future<bool> bulkReclassifyLeads(List<String> leadIds, String targetLeadType) async {
    bulkReclassifyLeadsOptimistic(leadIds, targetLeadType);
    final results = await Future.wait(leadIds.map((id) => reclassifyLead(id, targetLeadType)));
    return results.every((ok) => ok);
  }

  /// Reclassify a lead between 'Requirement' and 'Property Listing' ("Wrong Lead" action)
  Future<bool> reclassifyLead(String leadId, String targetLeadType) async {
    // 1. Immediately apply optimistic reclassification so first-click is instant
    reclassifyLeadOptimistic(leadId, targetLeadType);

    try {
      // 2. Call backend PATCH endpoint (with fallback to POST /reclassify if needed)
      Response? res;
      try {
        res = await _apiClient.patch('/integrations/leads/$leadId/lead-type', {
          'leadType': targetLeadType,
          'targetLeadType': targetLeadType,
        });
      } catch (patchErr) {
        debugPrint('[IntegrationService] PATCH /lead-type failed, trying fallback: $patchErr');
        res = await _apiClient.post('/integrations/leads/$leadId/reclassify', {
          'leadType': targetLeadType,
          'targetLeadType': targetLeadType,
        });
      }

      final isSuccess = res.statusCode != null && res.statusCode! >= 200 && res.statusCode! < 300;
      if (isSuccess) {
        if (res.data is Map && res.data['lead'] is Map) {
          try {
            final updatedLead = IntegrationLeadModel.fromJson(Map<String, dynamic>.from(res.data['lead']));
            int idx = _leads.indexWhere((l) => l.id == leadId);
            if (idx == -1) {
              idx = _leads.indexWhere((l) => l.externalLeadId == leadId);
            }
            if (idx != -1) {
              _leads[idx] = updatedLead;
              notifyListeners();
              unawaited(_persistLeads());
            }
          } catch (_) {}
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[IntegrationService] Error reclassifying lead $leadId: $e');
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

  /// Rename a single header across all leads and in this section's saved layout.
  void renameHeader(String oldHeader, String newHeader, {String? section}) {
    if (oldHeader == newHeader || newHeader.trim().isEmpty) return;
    mergeHeaders(sourceHeaders: [oldHeader], targetHeader: newHeader);
    List<String> renamed(List<String> headers) =>
        headers.map((header) => header == oldHeader ? newHeader : header).toList();
    if (section == 'Property Listing') {
      _propertyListingHeaderOrder = renamed(_propertyListingHeaderOrder);
      if (_propertyListingCustomHeaders.remove(oldHeader)) {
        _propertyListingCustomHeaders.add(newHeader);
      }
      if (_propertyListingHiddenHeaders.remove(oldHeader)) {
        _propertyListingHiddenHeaders.add(newHeader);
      }
    } else if (section == 'Requirement') {
      _requirementHeaderOrder = renamed(_requirementHeaderOrder);
      if (_requirementCustomHeaders.remove(oldHeader)) {
        _requirementCustomHeaders.add(newHeader);
      }
      if (_requirementHiddenHeaders.remove(oldHeader)) {
        _requirementHiddenHeaders.add(newHeader);
      }
    }
    _invalidateHeaderCache();
    notifyListeners();
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
    if (header.startsWith('_engine_') || header.trim().isEmpty) return;
    if (_columnToCrmFieldMap.containsKey(header)) return;
    final lower = header.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

    // 1. Marketing / Campaign / Ad / Form fields (check BEFORE 'name' so 'ad name' or 'form name' doesn't map to client name)
    if (lower.contains('campaign') ||
        lower.contains('adname') ||
        lower.contains('formname') ||
        lower == 'ad' ||
        lower == 'form' ||
        lower.contains('utm')) {
      _columnToCrmFieldMap[header] = 'campaign';
    }
    // 2. Client / Owner / Person Name
    else if (lower.contains('client') ||
        lower.contains('customer') ||
        lower.contains('buyer') ||
        lower.contains('owner') ||
        lower == 'fullname' ||
        lower == 'name' ||
        lower == 'leadname' ||
        lower.contains('leadname') ||
        lower == 'nameofclient') {
      _columnToCrmFieldMap[header] = 'name';
    }
    // 3. Phone / Mobile Number
    else if (lower.contains('phone') ||
        lower.contains('mobile') ||
        lower.contains('contact') ||
        lower.contains('number')) {
      _columnToCrmFieldMap[header] = 'mobile';
    }
    // 4. Email
    else if (lower.contains('email') || lower.contains('mail')) {
      _columnToCrmFieldMap[header] = 'email';
    }
    // 5. Rent / Budget / Price
    else if (lower.contains('rent') || lower.contains('budget') || lower.contains('price')) {
      _columnToCrmFieldMap[header] = 'budget';
    }
    // 6. Configuration / BHK / Property Type
    else if (lower.contains('bhk') ||
        lower.contains('config') ||
        lower.contains('apartmentname') ||
        lower.contains('propertytype') ||
        lower.contains('hometype')) {
      _columnToCrmFieldMap[header] = 'configuration';
    }
    // 7. Property / Project
    else if (lower.contains('project') || lower.contains('inventory') || lower == 'property' || lower.contains('propertyfield')) {
      _columnToCrmFieldMap[header] = 'property';
    }
    // 8. Location / Area / City
    else if (lower.contains('city') ||
        lower.contains('location') ||
        lower.contains('area') ||
        lower.contains('locality') ||
        lower.contains('located')) {
      _columnToCrmFieldMap[header] = 'city';
    }
    // 9. Remarks
    else if (lower.contains('remark') || lower.contains('note') || lower.contains('staying')) {
      _columnToCrmFieldMap[header] = 'remarks';
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
    final response = await _apiClient.post('/integrations/meta-feedback', {
      'leadId': leadId,
      'qualityStatus': qualityStatus,
    });
    final data = response.data is Map<String, dynamic> ? response.data as Map<String, dynamic> : {'success': true};
    if (index != -1) {
      _leads[index] = _leads[index].copyWith(
        qualityStatus: qualityStatus,
        metaFeedbackEventId: data['eventId']?.toString(),
        metaFeedbackSentAt: DateTime.now(),
      );
      notifyListeners();
      unawaited(_persistLeads());
    }
    return data;
  }

  Future<Map<String, dynamic>> sendHousingQualityFeedback({
    required String leadId,
    required String qualityStatus,
  }) async {
    final index = _leads.indexWhere((l) => l.id == leadId);
    final response = await _apiClient.post('/integrations/housing-feedback', {
      'leadId': leadId,
      'qualityStatus': qualityStatus,
    });
    final data = response.data is Map<String, dynamic> ? response.data as Map<String, dynamic> : {'success': true};
    if (index != -1) {
      _leads[index] = _leads[index].copyWith(qualityStatus: qualityStatus);
      notifyListeners();
      unawaited(_persistLeads());
    }
    return data;
  }

  /// Import selected campaign rows into the Leads page (requirements).
  Future<int> importLeadsToCrm(List<String> leadIds, {bool forceReimport = false, bool skipFetchServerLeads = false}) async {
    if (leadIds.isEmpty) return 0;

    final leadsPayload = <Map<String, dynamic>>[];
    for (final id in leadIds) {
      final idx = _leads.indexWhere((l) => l.id == id);
      if (idx != -1) {
        final lead = _leads[idx];
        leadsPayload.add({
          'id': lead.id,
          'assignedTo': lead.assignedTo,
          'assignedToName': lead.assignedToName,
          'remarks': lead.transferRemarks,
        });
      }
    }

    // 1. Try smart backend conversion engine first
    try {
      final response = await _apiClient.post(
        '/integrations/leads/convert-to-crm',
        {
          'leadIds': leadIds,
          'leads': leadsPayload,
        },
      );
      if (response.data is Map<String, dynamic> && response.data['success'] == true) {
        final count = response.data['count'] ?? 0;
        if (!skipFetchServerLeads) {
          await fetchServerLeads(resetWithServer: true);
        }
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
    final fallbackCategory = metadata.categories.isNotEmpty ? metadata.categories.first : null;
    if (fallbackCategory == null) {
      throw Exception(
        'Property lookups are not loaded yet. Open the Leads page once so cities and categories load, then sync again.',
      );
    }

    final List<MapEntry<int, RequirementModel>> batch = [];

    for (final id in leadIds) {
      final index = indexById[id];
      if (index == null) continue;

      final lead = _leads[index];
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
        RequirementModel? existingReq;
        for (final r in existing) {
          if (_normalizePhone(r.clientMobile) == normalizedMobile) {
            existingReq = r;
            break;
          }
        }
        if (existingReq != null && lead.assignedTo != null && lead.assignedTo!.isNotEmpty) {
          final updatedReq = existingReq.copyWith(
            assignedTo: lead.assignedTo,
            assigneeName: lead.assignedToName,
          );
          await _requirementsRepository.updateRequirement(updatedReq);
        }
        _leads[index] = lead.copyWith(
          importStatus: 'Imported',
          importedClientId: existingReq?.id ?? 'existing_$normalizedMobile',
        );
        importedCount++;
        continue;
      }

      if (!forceReimport && lead.importStatus == 'Imported') {
        importedCount++;
        continue;
      }

      if (normalizedMobile.isNotEmpty) {
        existingPhones.add(normalizedMobile);
      }

      final defaultListing = metadata.listingTypes.isNotEmpty ? metadata.listingTypes.first : null;
      final typeNeedle = _leadPropertyTypeNeedle(lead, mapped);
      final categoryNeedle = _leadCategoryNeedle(lead, mapped);

      LookupItem resolvedCategory = _matchCategoryFromRequirement(
            metadata.categories,
            categoryNeedle,
            typeNeedle,
          ) ??
          (primaryProperty != null && primaryProperty.categoryId.isNotEmpty
              ? LookupItem(id: primaryProperty.categoryId, name: primaryProperty.categoryName)
              : fallbackCategory);

      final typesForCategory = metadata.types
          .where((t) => t.categoryId == resolvedCategory.id)
          .where((t) => t.name.toLowerCase() != 'apartment')
          .toList();
      LookupItem? defaultType = typesForCategory.isNotEmpty ? typesForCategory.first : null;
      if (defaultType == null) {
        for (final t in metadata.types) {
          if (t.name.toLowerCase() != 'apartment') {
            defaultType = t;
            break;
          }
        }
      }

      final matchedType = _matchPropertyTypeFromRequirement(
        metadata.types,
        typeNeedle,
        categoryId: resolvedCategory.id,
      );
      LookupItem? resolvedType = matchedType ??
          (primaryProperty != null &&
                  primaryProperty.propertyTypeId.isNotEmpty &&
                  (primaryProperty.categoryId.isEmpty || primaryProperty.categoryId == resolvedCategory.id)
              ? LookupItem(
                  id: primaryProperty.propertyTypeId,
                  name: primaryProperty.propertyTypeName,
                  categoryId: primaryProperty.categoryId,
                )
              : defaultType);

      if (resolvedType != null && resolvedType.name.toLowerCase() == 'apartment') {
        resolvedType = _matchPropertyTypeFromRequirement(
              metadata.types,
              'flat',
              categoryId: resolvedCategory.id,
            ) ??
            resolvedType;
      }

      if (resolvedType == null) {
        throw Exception(
          'Property lookups are not loaded yet. Open the Leads page once so cities and categories load, then sync again.',
        );
      }

      final resolvedListing = primaryProperty != null && primaryProperty.listingTypeId.isNotEmpty
          ? LookupItem(id: primaryProperty.listingTypeId, name: primaryProperty.listingTypeName)
          : defaultListing;

      final budgetRange = parseBudgetRange(mapped['budget']!);
      final double budget = budgetRange.targetBudget > 0 ? budgetRange.targetBudget : (primaryProperty?.price ?? 0);
      final double minBudget = budgetRange.minBudget > 0 ? budgetRange.minBudget : (budget > 0 ? budget * 0.8 : 0);
      final double maxBudget = budgetRange.maxBudget > 0 ? budgetRange.maxBudget : (budget > 0 ? budget * 1.2 : 0);
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
      final rawAreaVal = lead.getStringValue('Preferred Area').isNotEmpty
          ? lead.getStringValue('Preferred Area')
          : (lead.getStringValue('Property Location').isNotEmpty
              ? lead.getStringValue('Property Location')
              : (lead.getStringValue('Area').isNotEmpty
                  ? lead.getStringValue('Area')
                  : (mapped['city']!.isNotEmpty
                      ? mapped['city']!
                      : '${primaryProperty?.areaName ?? ''} ${primaryProperty?.cityName ?? ''}')));
      final area = _matchArea(
            metadata.areas,
            metadata.cities,
            rawAreaVal,
          ) ??
          (primaryProperty != null && primaryProperty.areaId.isNotEmpty
              ? AreaLookup(id: primaryProperty.areaId, name: primaryProperty.areaName, cityId: primaryProperty.cityId, pincode: primaryProperty.pincode)
              : null);

      String fallbackAreaName = '';
      if (rawAreaVal.isNotEmpty) {
        final lower = rawAreaVal.toLowerCase();
        if (!lower.contains('any_suitable') && !lower.contains('any suitable') && lower != 'any' && lower != 'all' && lower != 'anywhere') {
          fallbackAreaName = rawAreaVal
              .replaceAll('_', ' ')
              .split(' ')
              .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
              .join(' ')
              .trim();
        }
      }
      final List<String> targetAreaNames = area != null
          ? [area.name]
          : (fallbackAreaName.isNotEmpty ? [fallbackAreaName] : const []);
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
      final transferNote = (lead.transferRemarks != null && lead.transferRemarks!.isNotEmpty)
          ? ' Key Points: ${lead.transferRemarks}.'
          : '';
      final summaryRemarks =
          '[Enquired: ${lead.formattedReceivedAt} via ${lead.source}] Campaign: $campaign.$propertyNotes$emailNote$transferNote${extraRemarks.isNotEmpty ? ' $extraRemarks' : ''}';

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
      metaCustomFields['received_at'] = lead.receivedAt.toIso8601String();
      metaCustomFields['received_on'] = lead.formattedReceivedAt;
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
        minBudget: minBudget,
        maxBudget: maxBudget,
        areaIds: area != null ? [area.id] : const [],
        areaNames: targetAreaNames,
        remarks: (lead.transferRemarks != null && lead.transferRemarks!.isNotEmpty)
            ? lead.transferRemarks
            : summaryRemarks,
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
        assignedTo: (lead.assignedTo != null && lead.assignedTo!.isNotEmpty)
            ? lead.assignedTo
            : (!isAdminOrTelecaller ? user?.id : null),
        assigneeName: (lead.assignedToName != null && lead.assignedToName!.isNotEmpty)
            ? lead.assignedToName
            : (!isAdminOrTelecaller ? user?.fullName : null),
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
  Future<int> importLeadsToProperties(List<String> leadIds, {bool skipFetchServerLeads = false}) async {
    if (leadIds.isEmpty) return 0;

    // 1. Try smart backend conversion engine first
    try {
      final leadsPayload = <Map<String, dynamic>>[];
      for (final id in leadIds) {
        final idx = _leads.indexWhere((l) => l.id == id);
        if (idx != -1) {
          final lead = _leads[idx];
          leadsPayload.add({
            'id': lead.id,
            'assignedTo': lead.assignedTo,
            'assignedToName': lead.assignedToName,
            'remarks': lead.transferRemarks,
          });
        }
      }
      final response = await _apiClient.post(
        '/integrations/leads/convert-to-crm',
        {
          'leadIds': leadIds,
          'leads': leadsPayload,
        },
      );
      if (response.data is Map<String, dynamic> && response.data['success'] == true) {
        final count = response.data['count'] ?? 0;
        if (!skipFetchServerLeads) {
          await fetchServerLeads(resetWithServer: true);
        }
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
          final importedId = lead.importedClientId;
          if (importedId != null &&
              importedId.isNotEmpty &&
              lead.assignedTo != null &&
              lead.assignedTo!.isNotEmpty) {
            try {
              await _propertiesRepository.updateProperty(importedId, {
                'assigned_to': lead.assignedTo,
              });
            } catch (e) {
              debugPrint('Error assigning imported property $importedId: $e');
            }
          }
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
          'remarks': '[Enquired: ${lead.formattedReceivedAt} via ${lead.source}] Campaign: ${lead.getStringValue('Campaign Name')}. Email: $email',
          'created_by': user?.id,
          if (lead.assignedTo != null && lead.assignedTo!.isNotEmpty) 'assigned_to': lead.assignedTo,
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
            final rawToStore = Map<String, dynamic>.from(l.rawJson);
            rawToStore['_lead_type'] = l.leadType;
            rawToStore['_campaign_status'] = l.campaignStatus;
            rawToStore['_enquiry_count'] = l.enquiryCount;
            if (l.followupScheduledAt != null) {
              rawToStore['_followup_scheduled_at'] = l.followupScheduledAt!.toIso8601String();
            }
            if (l.followupRemarks != null) {
              rawToStore['_followup_remarks'] = l.followupRemarks;
            }
            if (l.followupStatus != null) {
              rawToStore['_followup_status'] = l.followupStatus;
            }
            if (l.crmMatch != null) {
              rawToStore['_crm_match'] = l.crmMatch!.toJson();
            }
            local.rawJsonString = jsonEncode(rawToStore);
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

          final prefsForIsar = await SharedPreferences.getInstance();
          final isarOrg = prefsForIsar.getString('campaign_isar_org_v1');
          final canWriteIsar = isarOrg == null || isarOrg == _orgScope;
          if (canWriteIsar) {
            await dbRepo.clearAll();
            await dbRepo.saveLeads(locals);
            await prefsForIsar.setString('campaign_isar_org_v1', _orgScope);
          }

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

  static ({double minBudget, double maxBudget, double targetBudget}) parseBudgetRange(String raw) {
    if (raw.trim().isEmpty) {
      return (minBudget: 0.0, maxBudget: 0.0, targetBudget: 0.0);
    }

    double? parseToken(String tok) {
      final clean = tok.toLowerCase().replaceAll(',', '').trim();
      if (clean.endsWith('cr') || clean.endsWith('crore')) {
        final num = double.tryParse(clean.replaceAll(RegExp(r'crore|cr'), ''));
        return num != null ? num * 10000000 : null;
      }
      if (clean.endsWith('l') || clean.endsWith('lakh') || clean.endsWith('lac')) {
        final num = double.tryParse(clean.replaceAll(RegExp(r'lakh|lac|l'), ''));
        return num != null ? num * 100000 : null;
      }
      if (clean.endsWith('k') || clean.endsWith('thousand')) {
        final num = double.tryParse(clean.replaceAll(RegExp(r'thousand|k'), ''));
        return num != null ? num * 1000 : null;
      }
      final digits = clean.replaceAll(RegExp(r'[^\d.]'), '');
      return digits.isNotEmpty ? double.tryParse(digits) : null;
    }

    final lower = raw.toLowerCase();
    final matches = RegExp(r'\d+(?:,\d+)*(?:\.\d+)?\s*(?:cr|crore|lakh|lac|l|k|thousand)?', caseSensitive: false)
        .allMatches(lower);

    final nums = <double>[];
    for (final m in matches) {
      final val = parseToken(m.group(0)!);
      if (val != null && val > 0) nums.add(val);
    }

    if (nums.length >= 2) {
      final from = nums[0] < nums[1] ? nums[0] : nums[1];
      final to = nums[0] > nums[1] ? nums[0] : nums[1];
      final avg = (from + to) / 2;
      return (minBudget: from, maxBudget: to, targetBudget: avg);
    }

    if (nums.length == 1) {
      final val = nums[0];
      if (lower.contains('+') || lower.contains('above') || lower.contains('more')) {
        return (minBudget: val, maxBudget: val * 1.5, targetBudget: val);
      }
      if (lower.contains('below') || lower.contains('under') || lower.contains('less')) {
        final minVal = val * 0.5 > 5000 ? val * 0.5 : 5000.0;
        return (minBudget: minVal, maxBudget: val, targetBudget: val);
      }
      return (minBudget: val * 0.8, maxBudget: val * 1.2, targetBudget: val);
    }

    return (minBudget: 0.0, maxBudget: 0.0, targetBudget: 0.0);
  }

  double _parseBudget(String raw) {
    return parseBudgetRange(raw).targetBudget;
  }

  bool _isApartmentOrFlatLabel(String raw) {
    final n = raw.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
    if (n.isEmpty) return false;
    if (n.contains('apartment') || n.contains('flat')) return true;
    final tokens = n.split(' ');
    return tokens.contains('apt') || tokens.contains('apts') || tokens.contains('flats');
  }

  String _leadPropertyTypeNeedle(IntegrationLeadModel lead, Map<String, String> mapped) {
    const keys = [
      'Property Type',
      'Type of Property',
      'Type',
      'what_type_of_property_are_you_looking_to_rent_out?',
      'what_type_of_property_are_you_looking_to_rent_out',
      'what_type_of_home_are_you_looking_for?',
      'property_type',
      'typeofproperty',
    ];
    for (final key in keys) {
      final value = lead.getStringValue(key);
      if (value.trim().isNotEmpty) return value.trim();
    }
    for (final entry in lead.rawJson.entries) {
      final key = entry.key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
      if (key.contains('propertytype') || key.contains('typeofproperty') || key.contains('typeofhome')) {
        final value = entry.value?.toString().trim() ?? '';
        if (value.isNotEmpty) return value;
      }
    }
    return mapped['configuration'] ?? '';
  }

  String _leadCategoryNeedle(IntegrationLeadModel lead, Map<String, String> mapped) {
    const keys = [
      'Category',
      'Property Category',
      'Requirement Category',
      'category',
    ];
    for (final key in keys) {
      final value = lead.getStringValue(key);
      if (value.trim().isNotEmpty) return value.trim();
    }
    for (final entry in lead.rawJson.entries) {
      final key = entry.key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
      if (key == 'category' || key.contains('propertycategory')) {
        final value = entry.value?.toString().trim() ?? '';
        if (value.isNotEmpty) return value;
      }
    }
    return '';
  }

  LookupItem? _matchCategoryFromRequirement(
    List<LookupItem> categories,
    String categoryNeedle,
    String typeNeedle,
  ) {
    final direct = _matchLookup(categories, categoryNeedle);
    if (direct != null) return direct;

    final haystack = '${categoryNeedle.toLowerCase()} ${typeNeedle.toLowerCase()}';
    if (haystack.contains('commercial') ||
        haystack.contains('office') ||
        haystack.contains('shop') ||
        haystack.contains('showroom') ||
        haystack.contains('industrial')) {
      return _matchLookup(categories, 'commercial') ??
          categories.cast<LookupItem?>().firstWhere(
            (c) => (c!.name.toLowerCase().contains('commercial') || c.name.toLowerCase().contains('industrial')),
            orElse: () => null,
          );
    }
    if (haystack.contains('plot') || haystack.contains('land')) {
      return _matchLookup(categories, 'land') ??
          categories.cast<LookupItem?>().firstWhere(
            (c) => (c!.name.toLowerCase().contains('land') || c.name.toLowerCase().contains('plot')),
            orElse: () => null,
          );
    }
    if (haystack.contains('residential') ||
        haystack.contains('flat') ||
        haystack.contains('apartment') ||
        haystack.contains('villa') ||
        haystack.contains('bhk')) {
      return _matchLookup(categories, 'residential') ??
          categories.cast<LookupItem?>().firstWhere(
            (c) => c!.name.toLowerCase().contains('residential'),
            orElse: () => null,
          );
    }
    return null;
  }

  LookupItem? _matchPropertyTypeFromRequirement(
    List<LookupItem> types,
    String needle, {
    String? categoryId,
  }) {
    if (needle.trim().isEmpty) return null;
    final scoped = types.where((t) {
      if (t.name.toLowerCase() == 'apartment') return false;
      if (categoryId != null && t.categoryId != null && t.categoryId != categoryId) return false;
      return true;
    }).toList();

    if (_isApartmentOrFlatLabel(needle)) {
      for (final t in scoped) {
        if (t.name.toLowerCase().trim() == 'flat' || _isApartmentOrFlatLabel(t.name)) {
          return t;
        }
      }
    }

    return _matchLookup(scoped, needle) ?? _matchLookup(scoped, needle, categoryId: categoryId);
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

String _encodeCampaignLeadsJson(List<Map<String, dynamic>> leads) {
  return jsonEncode(leads);
}
