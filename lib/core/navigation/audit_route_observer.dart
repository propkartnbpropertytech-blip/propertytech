import 'package:flutter/material.dart';
import '../telemetry/audit_telemetry_service.dart';

/// Navigation observer that automatically records page transitions into the audit log
class AuditRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _logRoute(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _logRoute(newRoute);
    }
  }

  void _logRoute(Route<dynamic> route) {
    final routeName = route.settings.name;
    if (routeName != null && routeName.isNotEmpty) {
      // Ignore internal modal popups/dialogs if they do not represent screen paths
      if (!routeName.startsWith('/')) return;
      AuditTelemetryService.instance.trackPageView(
        routeName,
        title: _getFriendlyTitle(routeName),
      );
    }
  }

  String _getFriendlyTitle(String path) {
    final p = path.toLowerCase();
    if (p == '/' || p.startsWith('/dashboard')) return 'Dashboard';
    if (p.startsWith('/properties')) return 'Properties Screen';
    if (p.startsWith('/requirements') || p.startsWith('/leads')) return 'Leads Screen';
    if (p.startsWith('/campaign')) return 'Campaign / Connections';
    if (p.startsWith('/users')) return 'Employees / Users';
    if (p.startsWith('/reports')) return 'Reports';
    if (p.startsWith('/library')) return 'Library';
    if (p.startsWith('/settings/audit-logs')) return 'Super Admin Audit Logs';
    if (p.startsWith('/settings')) return 'Settings';
    if (p.startsWith('/profile')) return 'User Profile';
    if (p.startsWith('/bin')) return 'Recycle Bin';
    if (p.startsWith('/messages')) return 'Team Messages';
    return path;
  }
}
