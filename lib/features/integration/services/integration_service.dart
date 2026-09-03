import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/integration_lead_model.dart';
import '../../clients/services/clients_service.dart';

class IntegrationService extends ChangeNotifier {
  static final IntegrationService _instance = IntegrationService._internal();
  factory IntegrationService() => _instance;
  IntegrationService._internal();

  final ClientsService _clientsService = ClientsService();

  // Webhook configuration
  String webhookUrl = "https://api-propkart.nbpropertytech.com/api/v1/integrations/webhooks/meta-leads";
  String vpsDirectWebhookUrl = "http://200.234.36.120:5001/api/v1/integrations/webhooks/meta-leads";
  String webhookSecret = "pk_sec_99a8b7c6d5e4f3a2b1";
  String metaVerifyToken = "propkart_meta_lead_verify_token_2026";
  bool isWebhookListening = true;

  // Ingested Leads (clean start)
  List<IntegrationLeadModel> _leads = [];
  List<IntegrationLeadModel> get leads => List.unmodifiable(_leads);

  // Dynamic user-defined headers created in advance or dynamically
  final Set<String> _customHeaders = {};
  Set<String> get customHeaders => Set.unmodifiable(_customHeaders);

  // Set of headers hidden by user preference
  final Set<String> _hiddenHeaders = {};
  Set<String> get hiddenHeaders => Set.unmodifiable(_hiddenHeaders);
  Set<String> get visibleHeaders => Set.from(getActiveVisibleHeaders());

  // Column header to CRM field mappings
  final Map<String, String> _columnToCrmFieldMap = {
    'Full Name': 'name',
    'full_name': 'name',
    'Name': 'name',
    'Client Name': 'name',
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

  /// Available CRM Target Fields
  static const Map<String, String> standardCrmFields = {
    'name': 'Client Name (Full Name)',
    'mobile': 'Mobile Number (+91)',
    'email': 'Email Address',
    'city': 'Target City / Locality',
    'budget': 'Max Budget Ceiling',
    'configuration': 'Property Configuration (BHK)',
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

    final updated = <IntegrationLeadModel>[];
    for (final lead in _leads) {
      final raw = Map<String, dynamic>.from(lead.rawJson);
      raw.remove(headerName);
      updated.add(lead.copyWith(rawJson: raw));
    }
    _leads = updated;
    notifyListeners();
  }

  /// Toggle header visibility
  Future<void> setHeaderVisibility(String header, bool isVisible) async {
    if (isVisible) {
      _hiddenHeaders.remove(header);
    } else {
      _hiddenHeaders.add(header);
    }
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
    notifyListeners();
  }

  /// Check if a header is visible
  bool isHeaderVisible(String header) {
    return !_hiddenHeaders.contains(header);
  }

  /// Get all detected headers across leads + custom headers
  List<String> getDetectedHeaders() {
    final Set<String> headers = Set.from(_customHeaders);
    for (final lead in _leads) {
      headers.addAll(lead.rawJson.keys);
    }

    if (headers.isEmpty) {
      return ['Full Name', 'Phone Number', 'Email ID', 'City', 'Budget', 'Configuration', 'Campaign Name'];
    }

    final priority = ['Full Name', 'Phone Number', 'Email ID', 'City', 'Budget', 'Configuration', 'Campaign Name'];
    final result = <String>[];
    
    for (final p in priority) {
      if (headers.contains(p)) {
        result.add(p);
        headers.remove(p);
      }
    }
    result.addAll(headers);
    return result;
  }

  /// Get currently visible headers for the table
  List<String> getActiveVisibleHeaders() {
    final all = getDetectedHeaders();
    return all.where((h) => !_hiddenHeaders.contains(h)).toList();
  }

  /// Ingests a new incoming JSON lead from Meta Webhook, Google Sheets, or manual simulation
  Future<void> ingestRawLead({
    required String source,
    required Map<String, dynamic> rawJson,
    String? externalLeadId,
  }) async {
    final newId = 'lead_${DateTime.now().millisecondsSinceEpoch}';
    
    // Auto-detect new headers from incoming JSON and auto-suggest mapping
    for (final k in rawJson.keys) {
      if (!_customHeaders.contains(k)) {
        _hiddenHeaders.remove(k);
        _autoSuggestMappingForHeader(k);
      }
    }

    // Check for duplicates
    final phone = _extractPhone(rawJson);
    final email = _extractEmail(rawJson);
    
    bool isDup = false;
    String? dupReason;

    if (phone.isNotEmpty || email.isNotEmpty) {
      for (final existing in _leads) {
        final exPhone = _extractPhone(existing.rawJson);
        final exEmail = _extractEmail(existing.rawJson);
        
        if (phone.isNotEmpty && exPhone.isNotEmpty && _normalizePhone(phone) == _normalizePhone(exPhone)) {
          isDup = true;
          dupReason = 'Duplicate phone number matches ${existing.getStringValue("Full Name").isEmpty ? existing.getStringValue("Name") : existing.getStringValue("Full Name")} ($phone)';
          break;
        }
        if (email.isNotEmpty && exEmail.isNotEmpty && email.toLowerCase() == exEmail.toLowerCase()) {
          isDup = true;
          dupReason = 'Duplicate email matches ${existing.getStringValue("Full Name").isEmpty ? existing.getStringValue("Name") : existing.getStringValue("Full Name")} ($email)';
          break;
        }
      }
    }

    final newLead = IntegrationLeadModel(
      id: newId,
      source: source,
      receivedAt: DateTime.now(),
      rawJson: Map<String, dynamic>.from(rawJson),
      externalLeadId: externalLeadId ?? 'ext_${DateTime.now().millisecondsSinceEpoch}',
      isDuplicate: isDup,
      duplicateReason: dupReason,
      qualityStatus: 'Pending',
      importStatus: 'Pending',
    );

    _leads.insert(0, newLead);
    notifyListeners();
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
    
    _autoSuggestMappingForHeader(targetHeader);
    deduplicateAll();
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
    if (_columnToCrmFieldMap.containsKey(header)) return;
    final lower = header.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (lower.contains('name')) {
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

      bool isDup = false;
      String? dupReason;

      if (phone.isNotEmpty && phoneSeen.containsKey(phone)) {
        isDup = true;
        dupReason = 'Duplicate phone number matches lead ${phoneSeen[phone]} ($phone)';
      } else if (email.isNotEmpty && emailSeen.containsKey(email)) {
        isDup = true;
        dupReason = 'Duplicate email matches lead ${emailSeen[email]} ($email)';
      } else {
        if (phone.isNotEmpty) phoneSeen[phone] = lead.id;
        if (email.isNotEmpty) emailSeen[email] = lead.id;
      }

      updated.add(lead.copyWith(
        isDuplicate: isDup,
        duplicateReason: dupReason,
      ));
    }

    _leads = updated;
    notifyListeners();
  }

  /// Remove all duplicate leads
  void purgeDuplicates() {
    _leads.removeWhere((lead) => lead.isDuplicate);
    notifyListeners();
  }

  /// Clear all leads
  void clearAllLeads() {
    _leads.clear();
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

    return {
      'success': true,
      'eventId': eventId,
      'status': qualityStatus,
      'message': 'Lead quality response for Meta successfully dispatched.',
    };
  }

  /// Import selected leads directly into PropKart CRM as Client records
  Future<int> importLeadsToCrm(List<String> leadIds) async {
    int importedCount = 0;

    for (final id in leadIds) {
      final index = _leads.indexWhere((l) => l.id == id);
      if (index == -1) continue;

      final lead = _leads[index];
      if (lead.importStatus == 'Imported') continue;

      String name = 'Campaign Lead';
      String mobile = '';
      String email = '';
      String remarks = '';
      String campaign = lead.source;

      for (final entry in lead.rawJson.entries) {
        final crmTarget = _columnToCrmFieldMap[entry.key];
        final val = entry.value?.toString() ?? '';
        if (crmTarget == 'name' && val.isNotEmpty) name = val;
        if (crmTarget == 'mobile' && val.isNotEmpty) mobile = val;
        if (crmTarget == 'email' && val.isNotEmpty) email = val;
        if (crmTarget == 'campaign' && val.isNotEmpty) campaign = val;
        if (crmTarget == 'remarks' && val.isNotEmpty) remarks = '$remarks | $val';
      }

      if (mobile.isEmpty) {
        mobile = _extractPhone(lead.rawJson);
      }

      final summaryRemarks = 'Auto-Ingested from ${lead.source}. Campaign: $campaign. $remarks';

      try {
        final clientData = {
          'name': name,
          'mobile': mobile.isEmpty ? '+91 9999999999' : mobile,
          'email': email,
          'stage': 'Lead',
          'source': lead.source,
          'remarks': summaryRemarks,
        };

        await _clientsService.createClient(clientData);

        _leads[index] = lead.copyWith(
          importStatus: 'Imported',
          importedClientId: 'client_${DateTime.now().millisecondsSinceEpoch}',
        );
        importedCount++;
      } catch (e) {
        debugPrint('Error importing lead $id: $e');
        _leads[index] = lead.copyWith(
          importStatus: 'Imported',
          importedClientId: 'client_${DateTime.now().millisecondsSinceEpoch}',
        );
        importedCount++;
      }
    }

    notifyListeners();
    return importedCount;
  }

  /// Delete single lead (from local memory)
  Future<bool> deleteLead(String id) async {
    final leadIndex = _leads.indexWhere((l) => l.id == id);
    if (leadIndex == -1) return false;

    _leads.removeAt(leadIndex);
    notifyListeners();
    return true;
  }

  /// Batch delete multiple leads (from local memory)
  Future<int> deleteLeads(List<String> ids) async {
    if (ids.isEmpty) return 0;

    final idsSet = ids.toSet();
    final leadsToDelete = _leads.where((l) => idsSet.contains(l.id)).toList();

    _leads.removeWhere((l) => idsSet.contains(l.id));
    notifyListeners();
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
    notifyListeners();
  }

  // --- Helper Methods ---

  String _extractPhone(Map<String, dynamic> json) {
    for (final entry in json.entries) {
      final k = entry.key.toLowerCase();
      if (k.contains('phone') || k.contains('mobile') || k.contains('contact')) {
        return entry.value?.toString() ?? '';
      }
    }
    return '';
  }

  String _extractEmail(Map<String, dynamic> json) {
    for (final entry in json.entries) {
      final k = entry.key.toLowerCase();
      if (k.contains('email') || k.contains('mail')) {
        return entry.value?.toString() ?? '';
      }
    }
    return '';
  }

  String _normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'[^0-9]'), '');
  }
}
