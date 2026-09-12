import 'dart:async';
import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../security/role_guard.dart';

/// High-throughput, non-blocking telemetry and audit event ingestion service.
/// Batches telemetry events in-memory and flushes periodically or on size thresholds.
class AuditTelemetryService {
  AuditTelemetryService._internal() {
    _startPeriodicFlush();
  }

  static final AuditTelemetryService instance = AuditTelemetryService._internal();

  final ApiClient _apiClient = ApiClient();
  final List<Map<String, dynamic>> _queue = [];
  Timer? _flushTimer;
  Timer? _searchDebounceTimer;
  bool _isFlushing = false;
  static const int _batchThreshold = 15;
  static const int _maxQueueCap = 150;
  static const Duration _flushInterval = Duration(seconds: 5);

  void _startPeriodicFlush() {
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(_flushInterval, (_) {
      flush();
    });
  }

  /// Track Page / Route Navigation
  void trackPageView(String path, {String? title, Map<String, dynamic>? extra}) {
    final user = RoleGuard.currentUser;
    _enqueue({
      'action': 'PAGE_VIEW',
      'module': _resolveModuleFromPath(path),
      'path': path,
      'event_name': 'page_view',
      'record_type': 'Route',
      'record_id': path,
      'description': title != null && title.isNotEmpty
          ? 'Visited $title ($path)'
          : 'Navigated to $path',
      'details': {
        if (title != null) 'title': title,
        if (extra != null) ...extra,
      },
      'user_id': user?.id,
      'user_name': user?.fullName,
      'user_email': user?.email,
      'user_role': user?.role,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// Track Property Touch (Click, Drawer view, Image inspection, Status click)
  void trackPropertyTouch({
    required String propertyId,
    required String propertyTitle,
    required String touchType,
    Map<String, dynamic>? extra,
  }) {
    final user = RoleGuard.currentUser;
    _enqueue({
      'action': 'PROPERTY_TOUCH',
      'module': 'Properties',
      'path': '/properties/$propertyId',
      'event_name': 'property_$touchType',
      'record_type': 'Property',
      'record_id': propertyId,
      'description': 'Interacted with property #$propertyId ($propertyTitle) - $touchType',
      'details': {
        'property_id': propertyId,
        'property_title': propertyTitle,
        'touch_type': touchType,
        if (extra != null) ...extra,
      },
      'user_id': user?.id,
      'user_name': user?.fullName,
      'user_email': user?.email,
      'user_role': user?.role,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// Track Property Share (WhatsApp, copied link, exported brochure)
  void trackPropertyShare({
    required String propertyId,
    required String channel,
    String? recipientInfo,
    Map<String, dynamic>? extra,
  }) {
    final user = RoleGuard.currentUser;
    _enqueue({
      'action': 'PROPERTY_SHARE',
      'module': 'Properties',
      'path': '/properties/$propertyId',
      'event_name': 'property_share_${channel.toLowerCase().replaceAll(' ', '_')}',
      'record_type': 'Property',
      'record_id': propertyId,
      'description': 'Shared property #$propertyId via $channel${recipientInfo != null ? ' to $recipientInfo' : ''}',
      'details': {
        'property_id': propertyId,
        'channel': channel,
        if (recipientInfo != null) 'recipient': recipientInfo,
        if (extra != null) ...extra,
      },
      'user_id': user?.id,
      'user_name': user?.fullName,
      'user_email': user?.email,
      'user_role': user?.role,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// Track Button Clicks & Important UI Actions
  void trackButtonClick({
    required String buttonId,
    required String buttonLabel,
    required String page,
    Map<String, dynamic>? extra,
  }) {
    final user = RoleGuard.currentUser;
    _enqueue({
      'action': 'BUTTON_CLICK',
      'module': _resolveModuleFromPath(page),
      'path': page,
      'event_name': 'btn_click_${buttonId.toLowerCase().replaceAll(' ', '_')}',
      'record_type': 'Button',
      'record_id': buttonId,
      'description': 'Clicked "$buttonLabel" on $page',
      'details': {
        'button_id': buttonId,
        'button_label': buttonLabel,
        'page': page,
        if (extra != null) ...extra,
      },
      'user_id': user?.id,
      'user_name': user?.fullName,
      'user_email': user?.email,
      'user_role': user?.role,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// Track Search Queries with debouncing (800ms)
  void trackSearch({
    required String query,
    required String module,
    int? resultCount,
    Map<String, dynamic>? filters,
  }) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 800), () {
      final user = RoleGuard.currentUser;
      _enqueue({
        'action': 'SEARCH',
        'module': module,
        'path': '/search',
        'event_name': 'search_query',
        'record_type': 'Search',
        'record_id': trimmed,
        'description': 'Searched "$trimmed" in $module (${resultCount ?? 0} results)',
        'details': {
          'query': trimmed,
          'module': module,
          'result_count': resultCount,
          if (filters != null) 'filters': filters,
        },
        'user_id': user?.id,
        'user_name': user?.fullName,
        'user_email': user?.email,
        'user_role': user?.role,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    });
  }

  /// Track Hover Dwells (stops and hovers >= 1000ms)
  void trackHoverDwell({
    required String targetType,
    required String targetId,
    required int dwellMs,
    required String page,
    Map<String, dynamic>? metadata,
  }) {
    if (dwellMs < 1000) return; // Discard transient mouse-overs
    final user = RoleGuard.currentUser;
    final seconds = (dwellMs / 1000.0).toStringAsFixed(1);
    _enqueue({
      'action': 'HOVER_DWELL',
      'module': _resolveModuleFromPath(page),
      'path': page,
      'event_name': 'hover_dwell',
      'record_type': targetType,
      'record_id': targetId,
      'dwell_ms': dwellMs,
      'description': 'Hovered on $targetType #$targetId for ${seconds}s on $page',
      'details': {
        'target_type': targetType,
        'target_id': targetId,
        'dwell_ms': dwellMs,
        'dwell_seconds': seconds,
        'page': page,
        if (metadata != null) ...metadata,
      },
      'user_id': user?.id,
      'user_name': user?.fullName,
      'user_email': user?.email,
      'user_role': user?.role,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// Enqueue event and check threshold
  void _enqueue(Map<String, dynamic> event) {
    if (_queue.length >= _maxQueueCap) {
      _queue.removeAt(0); // Evict oldest to keep memory bounded
    }
    _queue.add(event);

    if (_queue.length >= _batchThreshold) {
      flush();
    }
  }

  /// Flush in-memory queue to backend API
  Future<void> flush() async {
    if (_isFlushing || _queue.isEmpty) return;
    _isFlushing = true;

    final batch = List<Map<String, dynamic>>.from(_queue);
    _queue.clear();

    try {
      await _apiClient.post('/audit/events', {'events': batch});
      if (kDebugMode) {
        debugPrint('[AuditTelemetry] Flushed ${batch.length} events successfully.');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AuditTelemetry] Failed to flush events: $e');
      }
      // Re-queue failed batch if within reasonable cap
      if (_queue.length + batch.length <= _maxQueueCap) {
        _queue.insertAll(0, batch);
      }
    } finally {
      _isFlushing = false;
    }
  }

  String _resolveModuleFromPath(String path) {
    final p = path.toLowerCase();
    if (p.contains('/properties')) return 'Properties';
    if (p.contains('/requirements') || p.contains('/leads')) return 'Leads';
    if (p.contains('/campaign') || p.contains('/connections')) return 'Campaign';
    if (p.contains('/users') || p.contains('/employees')) return 'Users';
    if (p.contains('/reports')) return 'Reports';
    if (p.contains('/library')) return 'Library';
    if (p.contains('/settings')) return 'Settings';
    if (p.contains('/dashboard')) return 'Dashboard';
    if (p.contains('/bin')) return 'Recycle Bin';
    return 'General';
  }

  void dispose() {
    _flushTimer?.cancel();
    _searchDebounceTimer?.cancel();
    flush();
  }
}
