import '../../core/network/sync_manager.dart';

/// A dropped realtime connection must reload the salesperson lead list once
/// the socket is live again. Events missed while offline are not replayed.
bool shouldRefreshSalesLeadsAfterReconnect(SyncState? previous, SyncState next) {
  final dropped = previous == SyncState.reconnecting ||
      previous == SyncState.offline ||
      previous == SyncState.disconnected ||
      previous == SyncState.error;
  final live = next == SyncState.live || next == SyncState.connected;
  return dropped && live;
}
