import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/api/dio_client.dart';
import '../../../core/security/role_guard.dart';

class PropertyNote {
  final String id;
  final String note;
  final String createdByName;
  final String createdByRole;
  final String companyName;
  final DateTime? createdAt;
  final bool canDelete;

  const PropertyNote({
    required this.id,
    required this.note,
    required this.createdByName,
    required this.createdByRole,
    required this.companyName,
    required this.createdAt,
    required this.canDelete,
  });

  factory PropertyNote.fromJson(Map<String, dynamic> json) => PropertyNote(
        id: (json['id'] ?? '').toString(),
        note: (json['note'] ?? '').toString(),
        createdByName: (json['createdByName'] ?? '').toString(),
        createdByRole: (json['createdByRole'] ?? '').toString(),
        companyName: (json['companyName'] ?? '').toString(),
        createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
        canDelete: json['canDelete'] == true,
      );
}

/// Notes per property (separate `property_notes` table). Note counts for visible cards are
/// fetched in one batched request so each card can show "+ Add Notes" or "View Notes".
class PropertyNotesController extends ChangeNotifier {
  PropertyNotesController._();
  static final PropertyNotesController instance = PropertyNotesController._();

  static const int maxNoteLength = 2000;
  static const Duration _countTtl = Duration(seconds: 60);

  final Map<String, int> _counts = {};
  final Map<String, DateTime> _countFetchedAt = {};
  final Set<String> _pending = {};
  final Set<String> _inFlight = {};
  Timer? _batchTimer;
  Timer? _accessTimer;
  String? _userId;

  /// Super Admin "Add Notes" switch for the signed-in user's Admin team (from the backend).
  bool _enabled = true;
  bool _accessKnown = false;

  /// True once the backend confirmed notes are enabled for this user.
  bool get enabled => _accessKnown && _enabled;

  void _resetIfUserChanged() {
    final userId = RoleGuard.currentUser?.id;
    if (userId == _userId) return;
    _userId = userId;
    _enabled = true;
    _accessKnown = false;
    _counts.clear();
    _countFetchedAt.clear();
    _pending.clear();
  }

  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
    _accessTimer ??= Timer.periodic(const Duration(seconds: 30), (_) => refreshAccess());
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (!hasListeners) {
      _accessTimer?.cancel();
      _accessTimer = null;
    }
  }

  void _applyEnabled(bool value) {
    if (_accessKnown && value == _enabled) return;
    _accessKnown = true;
    _enabled = value;
    if (value) {
      _countFetchedAt.clear();
    }
    notifyListeners();
  }

  /// Re-reads the "Add Notes" switch (e.g. after the Super Admin changes it).
  Future<void> refreshAccess() async {
    _resetIfUserChanged();
    if (RoleGuard.currentUser == null) return;
    final requestUserId = _userId;
    try {
      final response = await DioClient.dio.get('/properties/notes/counts');
      if (requestUserId != _userId) return;
      final data = response.data is Map ? response.data['data'] : null;
      if (data is Map) _applyEnabled(data['enabled'] != false);
    } catch (_) {}
  }

  void _handleError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (error.response?.statusCode == 403 && data is Map && data['errorCode'] == 'ACTION_DISABLED') {
        _applyEnabled(false);
      }
    }
  }

  int? countFor(String propertyId) {
    _resetIfUserChanged();
    return _counts[propertyId];
  }

  /// Queues a count lookup; safe to call from build.
  void ensureCount(String propertyId) {
    _resetIfUserChanged();
    if (propertyId.isEmpty || propertyId.startsWith('temp_') || _inFlight.contains(propertyId)) return;
    final fetchedAt = _countFetchedAt[propertyId];
    if (fetchedAt != null && DateTime.now().difference(fetchedAt) < _countTtl) return;
    _pending.add(propertyId);
    _batchTimer ??= Timer(const Duration(milliseconds: 80), _flushCounts);
  }

  Future<void> _flushCounts() async {
    _batchTimer = null;
    final ids = _pending.toList();
    _pending.clear();
    if (ids.isEmpty) return;
    _inFlight.addAll(ids);
    final requestUserId = _userId;
    var changed = false;
    try {
      for (var i = 0; i < ids.length; i += 100) {
        final chunk = ids.sublist(i, i + 100 > ids.length ? ids.length : i + 100);
        final response = await DioClient.dio.get(
          '/properties/notes/counts',
          queryParameters: {'ids': chunk.join(',')},
        );
        if (requestUserId != _userId) return;
        final data = response.data is Map ? response.data['data'] : null;
        if (data is Map && (!_accessKnown || (data['enabled'] != false) != _enabled)) {
          _accessKnown = true;
          _enabled = data['enabled'] != false;
          changed = true;
        }
        final counts = data is Map ? data['counts'] : null;
        final now = DateTime.now();
        for (final id in chunk) {
          _countFetchedAt[id] = now;
        }
        if (counts is Map) {
          counts.forEach((key, value) {
            final count = value is num ? value.toInt() : int.tryParse('$value') ?? 0;
            if (_counts[key.toString()] != count) {
              _counts[key.toString()] = count;
              changed = true;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('[PropertyNotes] count fetch failed: $e');
    } finally {
      _inFlight.removeAll(ids);
      if (changed) notifyListeners();
    }
  }

  void _setCount(String propertyId, int count) {
    _counts[propertyId] = count < 0 ? 0 : count;
    _countFetchedAt[propertyId] = DateTime.now();
    notifyListeners();
  }

  Future<List<PropertyNote>> fetchNotes(String propertyId) async {
    _resetIfUserChanged();
    final Response response;
    try {
      response = await DioClient.dio.get('/properties/$propertyId/notes');
    } catch (e) {
      _handleError(e);
      rethrow;
    }
    final data = response.data is Map ? response.data['data'] : null;
    final raw = data is Map ? data['notes'] : null;
    final notes = raw is List
        ? raw.whereType<Map>().map((e) => PropertyNote.fromJson(Map<String, dynamic>.from(e))).toList()
        : <PropertyNote>[];
    _setCount(propertyId, notes.length);
    return notes;
  }

  Future<PropertyNote> addNote(String propertyId, String note) async {
    _resetIfUserChanged();
    final Response response;
    try {
      response = await DioClient.dio.post('/properties/$propertyId/notes', data: {'note': note});
    } catch (e) {
      _handleError(e);
      rethrow;
    }
    final data = response.data is Map ? response.data['data'] : null;
    final created = PropertyNote.fromJson(Map<String, dynamic>.from((data is Map ? data['note'] : null) ?? const {}));
    _setCount(propertyId, (_counts[propertyId] ?? 0) + 1);
    return created;
  }

  Future<void> deleteNote(String propertyId, String noteId) async {
    _resetIfUserChanged();
    try {
      await DioClient.dio.delete('/properties/$propertyId/notes/$noteId');
    } catch (e) {
      _handleError(e);
      rethrow;
    }
    _setCount(propertyId, (_counts[propertyId] ?? 1) - 1);
  }

  static String errorMessage(Object error, String fallback) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] is String && (data['message'] as String).trim().isNotEmpty) {
        return data['message'] as String;
      }
    }
    return fallback;
  }
}
