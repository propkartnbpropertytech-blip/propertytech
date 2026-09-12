import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/features/settings/models/audit_log_model.dart';

void main() {
  group('Audit & Telemetry Models & Parsing Suite', () {
    test('1. AuditLogModel accurately parses non-UUID record IDs and nested details', () {
      final json = {
        'id': 'log-101',
        'user_id': 'usr-admin-1',
        'user_name': 'PropKart Admin',
        'user_email': 'admin@propkart.com',
        'user_role': 'Admin',
        'admin_id': null,
        'organization_id': 'org-1',
        'module': 'Properties',
        'action': 'PROPERTY_TOUCH',
        'record_type': 'Property',
        'record_id': 'prop-8819',
        'event_name': 'property_card_click',
        'path': '/properties/prop-8819',
        'dwell_ms': 2350,
        'details': {
          'title': '3 BHK Luxury Apartment in Bodakdev',
          'touch_type': 'drawer_open',
          'price': 15000000,
        },
        'ip_address': '103.24.12.8',
        'user_agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
        'session_id': 'sess-98213',
        'created_at': '2026-09-12T07:15:30.000Z',
      };

      final log = AuditLogModel.fromJson(json);

      expect(log.id, equals('log-101'));
      expect(log.userId, equals('usr-admin-1'));
      expect(log.userName, equals('PropKart Admin'));
      expect(log.userRole, equals('Admin'));
      expect(log.action, equals('PROPERTY_TOUCH'));
      expect(log.recordId, equals('prop-8819'));
      expect(log.dwellMs, equals(2350));
      expect(log.details?['touch_type'], equals('drawer_open'));
      expect(log.ipAddress, equals('103.24.12.8'));
      expect(log.sessionId, equals('sess-98213'));
    });

    test('2. AuditLogModel handles navigation routes and button strings in record_id', () {
      final routeLogJson = {
        'id': 'log-route-1',
        'action': 'PAGE_VIEW',
        'module': 'Settings',
        'record_type': 'Route',
        'record_id': '/settings/audit-logs',
        'path': '/settings/audit-logs',
        'description': 'Navigated to /settings/audit-logs',
        'created_at': '2026-09-12T07:20:00.000Z',
      };

      final buttonLogJson = {
        'id': 'log-btn-1',
        'action': 'BUTTON_CLICK',
        'module': 'Properties',
        'record_type': 'Button',
        'record_id': 'btn_export_excel',
        'description': 'Clicked Export Excel on /properties',
        'created_at': '2026-09-12T07:21:00.000Z',
      };

      final routeLog = AuditLogModel.fromJson(routeLogJson);
      final buttonLog = AuditLogModel.fromJson(buttonLogJson);

      expect(routeLog.recordId, equals('/settings/audit-logs'));
      expect(routeLog.action, equals('PAGE_VIEW'));
      expect(buttonLog.recordId, equals('btn_export_excel'));
      expect(buttonLog.action, equals('BUTTON_CLICK'));
    });

    test('3. AuditTelemetryStats parses metric counters correctly', () {
      final statsJson = {
        'total': 120,
        'pageViews': 45,
        'propertyTouches': 38,
        'propertyShares': 12,
        'searches': 15,
        'dwells': 10,
      };

      final stats = AuditTelemetryStats.fromJson(statsJson);

      expect(stats.total, equals(120));
      expect(stats.pageViews, equals(45));
      expect(stats.propertyTouches, equals(38));
      expect(stats.propertyShares, equals(12));
      expect(stats.searches, equals(15));
      expect(stats.dwells, equals(10));
    });

    test('4. UsersHierarchyResponse structures Admins, Telecallers, and Sales users with admin links', () {
      final json = {
        'admins': [
          {'id': 'adm-1', 'name': 'Admin Alpha', 'email': 'alpha@propkart.com', 'role': 'Admin', 'adminId': null, 'adminName': null},
          {'id': 'adm-2', 'name': 'Admin Beta', 'email': 'beta@propkart.com', 'role': 'Admin', 'adminId': null, 'adminName': null},
        ],
        'telecallers': [
          {'id': 'tel-1', 'name': 'Zeel Caller', 'email': 'zeel@propkart.com', 'role': 'Telecaller', 'adminId': 'adm-1', 'adminName': 'Admin Alpha'},
        ],
        'salesUsers': [
          {'id': 'sal-1', 'name': 'Jay Sales', 'email': 'jay@propkart.com', 'role': 'Sales', 'adminId': 'adm-2', 'adminName': 'Admin Beta'},
        ],
        'allUsers': [
          {'id': 'adm-1', 'name': 'Admin Alpha', 'email': 'alpha@propkart.com', 'role': 'Admin', 'adminId': null, 'adminName': null},
          {'id': 'adm-2', 'name': 'Admin Beta', 'email': 'beta@propkart.com', 'role': 'Admin', 'adminId': null, 'adminName': null},
          {'id': 'tel-1', 'name': 'Zeel Caller', 'email': 'zeel@propkart.com', 'role': 'Telecaller', 'adminId': 'adm-1', 'adminName': 'Admin Alpha'},
          {'id': 'sal-1', 'name': 'Jay Sales', 'email': 'jay@propkart.com', 'role': 'Sales', 'adminId': 'adm-2', 'adminName': 'Admin Beta'},
        ],
      };

      final hierarchy = UsersHierarchyResponse.fromJson(json);

      expect(hierarchy.admins.length, equals(2));
      expect(hierarchy.telecallers.length, equals(1));
      expect(hierarchy.salesUsers.length, equals(1));
      expect(hierarchy.allUsers.length, equals(4));

      expect(hierarchy.telecallers.first.adminName, equals('Admin Alpha'));
      expect(hierarchy.salesUsers.first.adminName, equals('Admin Beta'));
    });

    test('5. AuditLogsResponse unpacks paginated response and metadata', () {
      final json = {
        'total': 1,
        'page': 1,
        'limit': 50,
        'totalPages': 1,
        'logs': [
          {
            'id': 'log-share-1',
            'action': 'PROPERTY_SHARE',
            'module': 'Properties',
            'record_type': 'Property',
            'record_id': 'prop-99',
            'dwell_ms': 0,
            'details': {
              'channel': 'WhatsApp',
              'recipient': '919876543210',
            },
            'created_at': '2026-09-12T08:00:00.000Z',
          }
        ],
        'stats': {
          'total': 1,
          'pageViews': 0,
          'propertyTouches': 0,
          'propertyShares': 1,
          'searches': 0,
          'dwells': 0,
        }
      };

      final response = AuditLogsResponse.fromJson(json);

      expect(response.total, equals(1));
      expect(response.page, equals(1));
      expect(response.logs.length, equals(1));
      expect(response.logs.first.action, equals('PROPERTY_SHARE'));
      expect(response.stats.propertyShares, equals(1));
    });
  });
}
