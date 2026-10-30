import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/core/network/sync_manager.dart';
import 'package:propkart/features/integration/services/integration_service.dart';
import 'package:propkart/features/requirements/sales_lead_sync.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('reconnect reloads sales leads only after the socket was down', () {
    expect(shouldRefreshSalesLeadsAfterReconnect(SyncState.reconnecting, SyncState.live), isTrue);
    expect(shouldRefreshSalesLeadsAfterReconnect(SyncState.offline, SyncState.connected), isTrue);
    expect(shouldRefreshSalesLeadsAfterReconnect(SyncState.disconnected, SyncState.live), isTrue);
    expect(shouldRefreshSalesLeadsAfterReconnect(SyncState.error, SyncState.connected), isTrue);
    expect(shouldRefreshSalesLeadsAfterReconnect(SyncState.live, SyncState.live), isFalse);
    expect(shouldRefreshSalesLeadsAfterReconnect(SyncState.connecting, SyncState.live), isFalse);
    expect(shouldRefreshSalesLeadsAfterReconnect(null, SyncState.live), isFalse);
  });

  test('a lead table change is published before the campaign inbox parses it', () async {
    final events = <Map<String, dynamic>>[];
    final subscription = IntegrationService.leadEvents.stream.listen(events.add);
    IntegrationService().handleRealtimeEvent('UPDATE', {'id': 'sales-lead-1'}, null);
    await Future<void>.delayed(Duration.zero);
    expect(
      events.any((event) => event['type'] == 'LEAD_CHANGED' && event['leadId'] == 'sales-lead-1'),
      isTrue,
    );
    await subscription.cancel();
  });
}