# Repository & Offline-First Data Standard

> **Document Version:** 1.0.0  
> **Date:** October 2026  
> **Target:** PropKart Flutter Frontend (`c:\NB\propkart\lib`)  
> **Primary Technologies:** `isar: ^3.1.0+1`, `dio: ^5.4.0`  

---

## 1. Offline-First Architecture Contract

PropKart applications must remain fully interactive and responsive even with zero network connectivity. The Repository layer implements this contract:

```text
               ┌───────────────────────────┐
               │    Domain / Use Case      │
               └─────────────┬─────────────┘
                             │
                             ▼
               ┌───────────────────────────┐
               │   Repository Coordinator  │
               └──────┬─────────────┬──────┘
                      │             │
        (1. Fast Cache Read)   (2. Network Revalidate)
                      ▼             ▼
        ┌───────────────────┐ ┌───────────────────┐
        │  LocalDataSource  │ │ RemoteDataSource  │
        │  (Isar Database)  │ │ (Dio HTTP Client) │
        └───────────────────┘ └───────────────────┘
```

---

## 2. Standard Read Pattern (Cache-Then-Revalidate)

When retrieving collections (e.g. `Requirements`, `Properties`):
1. **Emit Immediate Cache:** The repository immediately queries the local Isar database and returns existing cached models to eliminate latency and avoid loading skeletons.
2. **Background Network Refresh:** Concurrently or sequentially, the repository checks network availability and requests fresh delta updates from the REST API via Dio.
3. **Reconcile & Update Local Store:** When network data returns, the repository updates the local Isar records inside a single write transaction and notifies listeners.

---

## 3. Standard Write Pattern (Optimistic Mutation)

When creating or modifying records (e.g. `updateRequirementStatus`):
1. **Apply Optimistic Update:** Immediately update the local Isar record with `isPendingSync = true` so the UI reflects the change with zero delay.
2. **Submit Remote API Call:** Send the HTTP request via DioClient.
3. **On Success:** Mark `isPendingSync = false` and update server timestamps.
4. **On Failure:**
   - If offline: Retain the mutation in Isar and register an entry in `SyncManager` outbox.
   - If permanent server rejection (400 / 422): Rollback the local record to its previous state and surface a domain failure to the BLoC.

---

## 4. Exception Mapping Standard

Data sources must never expose raw driver exceptions (e.g. `DioException`, `IsarError`) directly to domain or presentation layers. The repository maps them into standard domain failures:

```dart
try {
  final response = await remoteDataSource.patchStatus(id, status);
  return Right(response.toEntity());
} on DioException catch (e) {
  if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.connectionError) {
    return Left(NetworkFailure('No internet connection. Action queued for sync.'));
  }
  return Left(ServerFailure(e.response?.data?['message'] ?? 'Server error'));
} catch (e) {
  return Left(DatabaseFailure('Local storage update failed: $e'));
}
```
