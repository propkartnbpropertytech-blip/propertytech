import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/core/search/directory_search.dart';
import 'package:propkart/core/search/search_request_gate.dart';
import 'package:propkart/core/telemetry/audit_telemetry_service.dart';
import 'package:propkart/features/properties/models/property_list_fallback.dart';
import 'package:propkart/features/properties/models/property_model.dart';
import 'package:propkart/features/requirements/services/followup_sync_engine.dart';

void main() {
  test('a failed property search keeps the cached rows', () {
    final cached = [
      PropertyModel.fromJson({'id': 'p-1', 'title': 'Cached home', 'price': 100}),
    ];
    final fallback = PropertyListFallback.serverFailed(cached);
    expect(fallback.stale, isTrue);
    expect(fallback.properties, same(cached));
    expect(fallback.properties, isNotEmpty);
  });

  test('client, owner, and builder search fields match online and offline', () {
    expect(clientSearchFields, ['name', 'email', 'mobile', 'remarks']);
    expect(ownerSearchFields, ['name', 'mobile', 'email', 'address', 'remarks']);
    expect(builderSearchFields, containsAll(['company_name', 'contact_person', 'mobile', 'email', 'active_projects']));

    expect(
      clientSearchMatches(name: 'A', email: 'a@x.com', mobile: '1', remarks: 'sea view note', query: 'sea view'),
      isTrue,
    );
    expect(
      ownerSearchMatches(name: 'A', mobile: '1', email: 'a@x.com', address: 'SG Highway', remarks: '', query: 'highway'),
      isTrue,
    );
    expect(
      builderSearchMatches(
        companyName: 'Harbour',
        contactPerson: 'Mina',
        mobile: '9876501234',
        email: 'mina@harbour.test',
        activeProjects: ['Harbour One'],
        remarks: 'township',
        query: 'harbour one',
      ),
      isTrue,
    );
    expect(clientSearchMatches(name: 'A', email: 'a@x.com', mobile: '1', remarks: '', query: 'missing'), isFalse);
  });

  test('rapid typing keeps only the latest search request', () {
    fakeAsync((async) {
      final gate = SearchRequestGate(delay: const Duration(milliseconds: 250));
      final fired = <int>[];
      gate.schedule(fired.add);
      async.elapse(const Duration(milliseconds: 100));
      gate.schedule(fired.add);
      async.elapse(const Duration(milliseconds: 100));
      gate.schedule(fired.add);
      async.elapse(const Duration(milliseconds: 249));
      expect(fired, isEmpty);
      async.elapse(const Duration(milliseconds: 1));
      expect(fired, [3]);
      expect(gate.isCurrent(1), isFalse);
      expect(gate.isCurrent(3), isTrue);
      gate.dispose();
    });
  });

  test('follow-up windows follow the local calendar and pending rules', () {
    final now = DateTime(2026, 10, 30, 12);
    expect(followupQuickWindow(dateRaw: '2026-10-30T09:00:00', status: 'Pending', now: now), 'today');
    expect(followupQuickWindow(dateRaw: '2026-10-29T09:00:00', status: 'Pending', now: now), 'overdue');
    expect(followupQuickWindow(dateRaw: '2026-10-29T09:00:00', status: 'Completed', now: now), isNull);
    expect(followupQuickWindow(dateRaw: null, status: 'Pending', now: now), 'overdue');
    expect(followupQuickWindow(dateRaw: '2026-11-03T09:00:00', status: 'Pending', now: now), 'next7');
    expect(followupQuickWindow(dateRaw: '2026-11-20T09:00:00', status: 'Done', now: now), isNull);
  });

  test('search telemetry drops the raw query', () {
    const raw = 'Anita Shah 9876543210 anita@example.com';
    final payload = buildSearchTelemetry(query: raw, module: 'Clients', resultCount: 2);
    final serialized = payload.toString();
    expect(serialized.contains('Anita'), isFalse);
    expect(serialized.contains('9876543210'), isFalse);
    expect(serialized.contains('anita@example.com'), isFalse);
    expect(payload['record_id'], isNull);
    expect(payload['details']['query_length'], raw.length);
    expect(payload['details']['result_count'], 2);
  });
}
