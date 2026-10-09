import '../../features/users/models/user_model.dart';
import '../../features/requirements/models/requirement_model.dart';
import '../../features/integration/models/integration_lead_model.dart';

class TeamUserVisibility {
  static bool canUseFilter(String? role) {
    final r = (role ?? '').trim().toLowerCase();
    return r == 'admin' || r == 'super admin' || r == 'telecaller';
  }

  static bool isSalesRole(String roleName) {
    final r = roleName.toLowerCase();
    return r.contains('sales') || r.contains('executive') || r.contains('agent') || r.contains('advisor');
  }

  static bool isTelecallerRole(String roleName) {
    return roleName.toLowerCase().contains('telecaller');
  }

  static bool isAdminRole(String roleName) {
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
        return isAdminRole(r) || isTelecallerRole(r) || isSalesRole(r);
      }
      if (role == 'admin') {
        return isTelecallerRole(r) || isSalesRole(r);
      }
      if (role == 'telecaller') {
        if (u.id == currentUserId) return false;
        return isSalesRole(r);
      }
      return false;
    }).toList()
      ..sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
  }

  static List<UserModel> visibleSalesUsers({
    required List<UserModel> users,
    required String? currentRole,
    required String currentUserId,
  }) {
    final all = visibleUsers(users: users, currentRole: currentRole, currentUserId: currentUserId);
    return all.where((u) => isSalesRole(u.roleName)).toList();
  }

  static List<UserModel> visibleTelecallerUsers({
    required List<UserModel> users,
    required String? currentRole,
    required String currentUserId,
  }) {
    final role = (currentRole ?? '').trim().toLowerCase();
    if (role == 'telecaller') {
      return const [];
    }
    final active = users.where((u) => u.isActive).toList();
    return active.where((u) => isTelecallerRole(u.roleName)).toList()
      ..sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
  }

  static bool _matchesPerson(String? value, dynamic user) {
    if (value == null || value.trim().isEmpty || user == null) return false;
    final v = value.trim().toLowerCase();
    if (v == 'unassigned' || v == 'null') return false;
    final id = (user.id ?? '').toString().trim().toLowerCase();
    if (id.isNotEmpty && v == id) return true;
    final name = (user is UserModel
            ? user.fullName
            : (user.fullName ?? user.name ?? ''))
        .toString()
        .trim()
        .toLowerCase();
    if (name.isNotEmpty) {
      if (v == name) return true;
      final cleanV = v.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
      if (cleanV == name) return true;
      if (cleanV.isNotEmpty && (cleanV.contains(name) || name.contains(cleanV))) return true;
    }
    final email = (user is UserModel ? user.email : user.email?.toString() ?? '')
        .toString()
        .trim()
        .toLowerCase();
    if (email.isNotEmpty && v == email) return true;
    return false;
  }

  static bool telecallerLeadSentToSalesperson(
    RequirementModel req,
    UserModel salesperson,
    dynamic currentTelecaller,
  ) {
    final isAssignedToSales = _matchesPerson(req.assignedTo, salesperson) ||
        _matchesPerson(req.assigneeName, salesperson);

    final history = req.metaCustomFields?['assignment_history'];
    bool historyMatches = false;
    if (history is List) {
      for (final item in history) {
        if (item is Map) {
          final toId = item['user_id']?.toString();
          final toName = item['user_name']?.toString();
          final byId = item['assigned_by']?.toString();
          final byName = item['assigned_by_name']?.toString();
          if ((_matchesPerson(toId, salesperson) || _matchesPerson(toName, salesperson)) &&
              (_matchesPerson(byId, currentTelecaller) || _matchesPerson(byName, currentTelecaller))) {
            historyMatches = true;
            break;
          }
        }
      }
    }

    if (!isAssignedToSales && !historyMatches) return false;

    final createdByMe = _matchesPerson(req.createdBy, currentTelecaller) ||
        _matchesPerson(req.creatorName, currentTelecaller);
    final metaTcId = req.metaCustomFields?['telecaller_id']?.toString() ??
        req.metaCustomFields?['assigned_telecaller_id']?.toString() ??
        req.metaCustomFields?['telecaller_by']?.toString();
    final tcMatches = metaTcId != null && _matchesPerson(metaTcId, currentTelecaller);

    return createdByMe || tcMatches || historyMatches || isAssignedToSales;
  }

  static bool requirementBelongsToUser(RequirementModel req, UserModel user) {
    if (_matchesPerson(req.assignedTo, user) || _matchesPerson(req.assigneeName, user)) {
      return true;
    }
    if (_matchesPerson(req.createdBy, user) || _matchesPerson(req.creatorName, user)) {
      return true;
    }
    if (_matchesPerson(req.assignedTelecallerId, user)) {
      return true;
    }
    final meta = req.metaCustomFields;
    if (meta != null) {
      final keysToCheck = [
        'assigned_telecaller_id',
        'assigned_telecaller_name',
        '_assigned_telecaller_id',
        '_assigned_telecaller_name',
        'telecaller_id',
        'telecaller_name',
        'telecaller_by',
        'telecaller_by_id',
        'telecaller',
        'rejected_by',
        'rejected_by_id',
        'rejected_by_name',
        'rejected_by_telecaller',
        'handled_by',
        'handled_by_id',
        'handled_by_name',
        'sales_user_id',
        'sales_user_name',
        'handled_by_sales_id',
        'sales_handled_by',
      ];
      for (final key in keysToCheck) {
        final val = meta[key]?.toString();
        if (_matchesPerson(val, user)) {
          return true;
        }
      }
      final history = meta['assignment_history'];
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
    }
    final uName = user.fullName.trim().toLowerCase();
    if (uName.isNotEmpty && uName.length >= 3) {
      if (req.creatorName != null && req.creatorName!.trim().toLowerCase().contains(uName)) {
        return true;
      }
      if (req.assigneeName != null && req.assigneeName!.trim().toLowerCase().contains(uName)) {
        return true;
      }
      if (req.remarks != null && req.remarks!.toLowerCase().contains(uName)) {
        return true;
      }
      if (req.notes != null && req.notes!.toLowerCase().contains(uName)) {
        return true;
      }
    }
    return false;
  }

  static bool campaignLeadBelongsToUser(IntegrationLeadModel lead, dynamic user) {
    if (_matchesPerson(lead.assignedTo, user) || _matchesPerson(lead.assignedToName, user)) {
      return true;
    }
    if (_matchesPerson(lead.assignedTelecallerId, user) || _matchesPerson(lead.assignedTelecallerName, user)) {
      return true;
    }
    if (_matchesPerson(lead.interactedBy, user)) {
      return true;
    }
    if (_matchesPerson(lead.statusUpdatedById, user) || _matchesPerson(lead.statusUpdatedByName, user)) {
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
