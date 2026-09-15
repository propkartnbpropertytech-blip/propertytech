import '../../properties/models/property_model.dart';
import '../../requirements/models/requirement_model.dart';
import '../models/user_model.dart';

class EmployeeActivity {
  static bool _namesMatch(String? a, String b) {
    final left = (a ?? '').trim().toLowerCase();
    final right = b.trim().toLowerCase();
    return left.isNotEmpty && right.isNotEmpty && left == right;
  }

  static bool belongsToProperty(PropertyModel p, UserModel user) {
    final name = user.fullName;
    return (p.adminId ?? '') == user.id ||
        p.createdBy == user.id ||
        _namesMatch(p.createdByName, name) ||
        _namesMatch(p.createdBy, name);
  }

  static bool belongsToRequirement(RequirementModel r, UserModel user) {
    final name = user.fullName;
    return (r.adminId ?? '') == user.id ||
        (r.assignedTo ?? '') == user.id ||
        (r.createdBy ?? '') == user.id ||
        _namesMatch(r.creatorName, name) ||
        _namesMatch(r.assigneeName, name) ||
        _namesMatch(r.createdBy, name) ||
        _namesMatch(r.assignedTo, name);
  }

  static String propertyListingBucket(PropertyModel p) {
    final lt = p.listingTypeName.toLowerCase();
    if (lt.contains('rent')) return 'Rent';
    return 'Re-Sale';
  }

  static String requirementListingBucket(RequirementModel r) {
    final combined = '${r.listingTypeName ?? ''} ${r.listingTypeId ?? ''}'.toLowerCase();
    if (combined.contains('rent')) return 'Rent';
    if (combined.contains('sale') || combined.contains('resale')) return 'Re-Sale';
    return 'Rent';
  }

  static bool isWon(RequirementModel r) {
    final s = r.status.trim().toLowerCase();
    return s == 'won' || s == 'closed';
  }

  static DateTime? followupAt(RequirementModel r) {
    final raw = r.nextFollowupDate;
    if (raw == null || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  static bool isPendingFollowup(RequirementModel r) {
    final dt = followupAt(r);
    if (dt == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    return !day.isBefore(today);
  }

  static bool isOverdueFollowup(RequirementModel r) {
    final dt = followupAt(r);
    if (dt == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    return day.isBefore(today) && !isWon(r);
  }

  static bool hasSiteVisit(RequirementModel r) {
    return r.rawSiteVisits != null && r.rawSiteVisits!.isNotEmpty;
  }

  static bool isAssignedTo(RequirementModel r, UserModel user) {
    return (r.assignedTo ?? '') == user.id ||
        _namesMatch(r.assignedTo, user.fullName) ||
        _namesMatch(r.assigneeName, user.fullName);
  }

  static bool isCreatedBy(RequirementModel r, UserModel user) {
    return (r.createdBy ?? '') == user.id ||
        _namesMatch(r.createdBy, user.fullName) ||
        _namesMatch(r.creatorName, user.fullName);
  }

  static bool isTeamMemberOf(UserModel member, UserModel manager) {
    if (member.id == manager.id) return false;
    final role = member.roleName.toLowerCase();
    if (role != 'sales' && role != 'telecaller') return false;
    return (member.adminId ?? '') == manager.id ||
        _namesMatch(member.createdByName, manager.fullName);
  }
}
