import 'package:flutter/material.dart';

/// Represents a single manageable page or submenu in the Page Control system.
class PageControlModel {
  final String pageKey;
  final String title;
  final String route;
  final String? icon;
  final String category; // 'Main', 'Campaign', 'Settings', etc.
  final String? parentKey;
  final bool isShared;
  final List<String> roles; // ['Admin', 'Telecaller', 'Sales']
  final bool isUnderDevelopment;
  final List<String> underDevelopmentRoles; // ['Admin', 'Telecaller', 'Sales']
  final String? message;
  final int sortOrder;
  final DateTime? updatedAt;

  const PageControlModel({
    required this.pageKey,
    required this.title,
    required this.route,
    this.icon,
    this.category = 'Main',
    this.parentKey,
    this.isShared = true,
    required this.roles,
    this.isUnderDevelopment = false,
    this.underDevelopmentRoles = const [],
    this.message,
    this.sortOrder = 0,
    this.updatedAt,
  });

  factory PageControlModel.fromJson(Map<String, dynamic> json) {
    List<String> parseRoles(dynamic raw) {
      if (raw is List) {
        return raw.map((e) => e.toString().trim()).toList();
      }
      if (raw is String) {
        final clean = raw.replaceAll('{', '').replaceAll('}', '').replaceAll('"', '');
        return clean.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
      return ['Admin', 'Telecaller', 'Sales'];
    }

    return PageControlModel(
      pageKey: json['page_key']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      route: json['route']?.toString() ?? '',
      icon: json['icon']?.toString(),
      category: json['category']?.toString() ?? 'Main',
      parentKey: json['parent_key']?.toString(),
      isShared: json['is_shared'] == true ||
          json['is_shared']?.toString().toLowerCase() == 'true' ||
          json['is_shared'] == 1,
      roles: parseRoles(json['roles']),
      isUnderDevelopment: json['is_under_development'] == true ||
          json['is_under_development']?.toString().toLowerCase() == 'true' ||
          json['is_under_development'] == 1,
      underDevelopmentRoles: json['under_development_roles'] != null 
          ? parseRoles(json['under_development_roles']) 
          : const [],
      message: json['message']?.toString(),
      sortOrder: (json['sort_order'] is num) ? (json['sort_order'] as num).toInt() : 0,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'page_key': pageKey,
    'title': title,
    'route': route,
    'icon': icon,
    'category': category,
    'parent_key': parentKey,
    'is_shared': isShared,
    'roles': roles,
    'is_under_development': isUnderDevelopment,
    'under_development_roles': underDevelopmentRoles,
    'message': message,
    'sort_order': sortOrder,
    'updated_at': updatedAt?.toIso8601String(),
  };

  PageControlModel copyWith({
    String? pageKey,
    String? title,
    String? route,
    String? icon,
    String? category,
    String? parentKey,
    bool? isShared,
    List<String>? roles,
    bool? isUnderDevelopment,
    List<String>? underDevelopmentRoles,
    String? message,
    int? sortOrder,
    DateTime? updatedAt,
  }) {
    return PageControlModel(
      pageKey: pageKey ?? this.pageKey,
      title: title ?? this.title,
      route: route ?? this.route,
      icon: icon ?? this.icon,
      category: category ?? this.category,
      parentKey: parentKey ?? this.parentKey,
      isShared: isShared ?? this.isShared,
      roles: roles ?? this.roles,
      isUnderDevelopment: isUnderDevelopment ?? this.isUnderDevelopment,
      underDevelopmentRoles: underDevelopmentRoles ?? this.underDevelopmentRoles,
      message: message ?? this.message,
      sortOrder: sortOrder ?? this.sortOrder,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Evaluates whether this page is marked Under Development for the specific [role].
  bool isUnderDevForRole(String? role) {
    if (role == null || role.isEmpty) return false;
    final r = role.trim().toLowerCase();

    if (underDevelopmentRoles.isNotEmpty) {
      return underDevelopmentRoles.any((allowed) {
        final a = allowed.trim().toLowerCase();
        if (a == 'admin' && (r == 'admin' || r == 'super admin')) return true;
        if (a == 'telecaller' && r == 'telecaller') return true;
        if (a == 'sales' && (r == 'sales' || r == 'sales person' || r == 'salesperson')) return true;
        return a == r;
      });
    }

    // Fallback: if isUnderDevelopment is active and roles match
    if (isUnderDevelopment) {
      return matchesRole(role);
    }
    return false;
  }

  /// Evaluates whether this page applies to the specified role.
  bool matchesRole(String? role) {
    if (role == null || role.isEmpty) return false;
    final r = role.trim().toLowerCase();
    return roles.any((allowed) {
      final a = allowed.trim().toLowerCase();
      if (a == 'admin' && (r == 'admin' || r == 'super admin')) return true;
      if (a == 'telecaller' && r == 'telecaller') return true;
      if (a == 'sales' && (r == 'sales' || r == 'sales person' || r == 'salesperson')) return true;
      return a == r;
    });
  }

  /// Maps string icon name to Material IconData
  IconData get iconData {
    switch (icon) {
      case 'grid_view_rounded':
        return Icons.grid_view_rounded;
      case 'home_work_outlined':
        return Icons.home_work_outlined;
      case 'assignment_outlined':
        return Icons.assignment_outlined;
      case 'phone_in_talk_outlined':
        return Icons.phone_in_talk_outlined;
      case 'event_repeat':
        return Icons.event_repeat;
      case 'phone_missed_outlined':
        return Icons.phone_missed_outlined;
      case 'people_outline_rounded':
        return Icons.people_outline_rounded;
      case 'bar_chart_rounded':
        return Icons.bar_chart_rounded;
      case 'campaign_outlined':
        return Icons.campaign_outlined;
      case 'apartment_outlined':
        return Icons.apartment_outlined;
      case 'hub_outlined':
        return Icons.hub_outlined;
      case 'folder_outlined':
        return Icons.folder_outlined;
      case 'settings_outlined':
        return Icons.settings_outlined;
      case 'history_rounded':
        return Icons.history_rounded;
      case 'delete_outline_rounded':
        return Icons.delete_outline_rounded;
      case 'support_agent_rounded':
        return Icons.support_agent_rounded;
      case 'person_outline_rounded':
        return Icons.person_outline_rounded;
      case 'palette_outlined':
        return Icons.palette_outlined;
      case 'tune_rounded':
        return Icons.tune_rounded;
      case 'location_city_outlined':
        return Icons.location_city_outlined;
      case 'bolt_rounded':
        return Icons.bolt_rounded;
      case 'photo_library_outlined':
        return Icons.photo_library_outlined;
      case 'dashboard_customize_outlined':
        return Icons.dashboard_customize_outlined;
      case 'info_outline_rounded':
        return Icons.info_outline_rounded;
      default:
        return Icons.web_rounded;
    }
  }
}
