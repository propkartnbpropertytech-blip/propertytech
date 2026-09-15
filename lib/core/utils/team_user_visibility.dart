import '../../features/users/models/user_model.dart';
import '../../features/requirements/models/requirement_model.dart';
import '../../features/integration/models/integration_lead_model.dart';

class TeamUserVisibility {
  static bool canUseFilter(String? role) {
    final r = (role ?? '').trim().toLowerCase();
    return r == 'admin' || r == 'super admin' || r == 'telecaller';
  }

  static bool _isSalesRole(String roleName) {
    final r = roleName.toLowerCase();
    return r.contains('sales') || r.contains('executive') || r.contains('agent') || r.contains('advisor');
  }

  static bool _isTelecallerRole(String roleName) {
    return roleName.toLowerCase().contains('telecaller');
  }

  static bool _isAdminRole(String roleName) {
    return roleName.toLowerCase() == 'admin';
  }

  static List<UserModel> visibleUsers({
    required List<UserModel> users,
    required String? currentRole,
    required String currentUserId,
  }) {
    final role = (currentRole ?? '').trim().toLowerCase();
    final active = users.where((u) => u.isActive).toList();
    return active.where((u) {
      final r = u.roleName;
      if (role == 'super admin') {
        return _isAdminRole(r) || _isTelecallerRole(r) || _isSalesRole(r);
      }
      if (role == 'admin') {
        return _isTelecallerRole(r) || _isSalesRole(r);
      }
      if (role == 'telecaller') {
        if (u.id == currentUserId) return false;
        return _isTelecallerRole(r) || _isSalesRole(r);
      }
      return false;
    }).toList()
      ..sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
  }

  static bool _matchesPerson(String? value, UserModel user) {
    if (value == null || value.trim().isEmpty) return false;
    final v = value.trim().toLowerCase();
    if (v == 'unassigned') return false;
    return v == user.id.toLowerCase() || v == user.fullName.trim().toLowerCase();
  }

  static bool requirementBelongsToUser(RequirementModel req, UserModel user) {
    if (_matchesPerson(req.assignedTo, user) || _matchesPerson(req.assigneeName, user)) {
      return true;
    }
    if (_matchesPerson(req.createdBy, user) || _matchesPerson(req.creatorName, user)) {
      return true;
    }
    final history = req.metaCustomFields?['assignment_history'];
    if (history is List) {
      for (final item in history) {
        if (item is Map) {
          final id = item['user_id']?.toString();
          final name = item['user_name']?.toString();
          final byId = item['assigned_by']?.toString();
          final byName = item['assigned_by_name']?.toString();
          if (_matchesPerson(id, user) ||
              _matchesPerson(name, user) ||
              _matchesPerson(byId, user) ||
              _matchesPerson(byName, user)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  static bool campaignLeadBelongsToUser(IntegrationLeadModel lead, UserModel user) {
    if (_matchesPerson(lead.assignedTo, user) || _matchesPerson(lead.assignedToName, user)) {
      return true;
    }
    if (_matchesPerson(lead.interactedBy, user)) {
      return true;
    }
    final transfer = lead.rawJson['_transfer'];
    if (transfer is Map) {
      if (_matchesPerson(transfer['assigned_to']?.toString(), user) ||
          _matchesPerson(transfer['assigned_to_name']?.toString(), user) ||
          _matchesPerson(transfer['interacted_by']?.toString(), user)) {
        return true;
      }
    }
    final history = lead.rawJson['assignment_history'] ?? lead.rawJson['_assignment_history'];
    if (history is List) {
      for (final item in history) {
        if (item is Map) {
          if (_matchesPerson(item['user_id']?.toString(), user) ||
              _matchesPerson(item['user_name']?.toString(), user) ||
              _matchesPerson(item['assigned_by']?.toString(), user)) {
            return true;
          }
        }
      }
    }
    return false;
  }
}
