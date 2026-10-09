import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/security/role_guard.dart';
import '../../requirements/repository/requirements_repository.dart';

// --- EVENTS ---
abstract class SalesDashboardEvent extends Equatable {
  const SalesDashboardEvent();
  @override
  List<Object?> get props => [];
}

class SalesDashboardRequested extends SalesDashboardEvent {}

class AddNoteRequested extends SalesDashboardEvent {
  final String content;
  const AddNoteRequested(this.content);
  @override
  List<Object?> get props => [content];
}

class ToggleNoteRequested extends SalesDashboardEvent {
  final String id;
  final bool isCompleted;
  const ToggleNoteRequested(this.id, this.isCompleted);
  @override
  List<Object?> get props => [id, isCompleted];
}

class DeleteNoteRequested extends SalesDashboardEvent {
  final String id;
  const DeleteNoteRequested(this.id);
  @override
  List<Object?> get props => [id];
}

// --- STATE ---
class SalesDashboardState extends Equatable {
  final bool loading;
  final String? error;
  final Map<String, dynamic> data;
  const SalesDashboardState({this.loading = false, this.error, this.data = const {}});
  @override
  List<Object?> get props => [loading, error, data];
}

// --- BLOC ---
class SalesDashboardBloc extends Bloc<SalesDashboardEvent, SalesDashboardState> {
  SalesDashboardBloc() : super(const SalesDashboardState(loading: true)) {
    on<SalesDashboardRequested>((event, emit) async {
      emit(SalesDashboardState(loading: state.data.isEmpty, data: state.data));
      Map<String, dynamic> resData = {};
      try {
        final res = await DioClient.dio.get(ApiConstants.salesDashboardSummary);
        resData = Map<String, dynamic>.from(res.data['data'] ?? res.data ?? {});
      } catch (e) {
        // Safe fallback below
      }

      final rawFollowups = resData['followups'];
      final hasFollowups = rawFollowups is List && rawFollowups.isNotEmpty;
      if (!hasFollowups) {
        try {
          final reqs = await RequirementsRepository().getRequirements(refreshFromServer: false);
          final currentUser = RoleGuard.currentUser;
          final currentUserName = currentUser?.fullName.trim().toLowerCase() ?? '';

          final localFollowupList = <Map<String, dynamic>>[];
          for (final req in reqs) {
            final st = req.status.trim().toLowerCase();
            final isFollowup = st == 'follow-up' || st == 'followup' || st == 're-followup' || st == 'refollowup' || st == 'pending';
            if (!isFollowup) continue;

            if (currentUser != null && currentUser.role == 'Sales') {
              final isAssignedToUser = (req.assignedTo != null && (req.assignedTo == currentUser.id || (currentUserName.isNotEmpty && req.assignedTo!.trim().toLowerCase() == currentUserName))) ||
                  (req.assigneeName != null && currentUserName.isNotEmpty && req.assigneeName!.trim().toLowerCase() == currentUserName);
              final isUnassignedCreatedByUser = (req.assignedTo == null || req.assignedTo!.trim().isEmpty || req.assignedTo!.trim().toLowerCase() == 'unassigned') &&
                  (req.createdBy == currentUser.id || (req.creatorName != null && currentUserName.isNotEmpty && req.creatorName!.trim().toLowerCase() == currentUserName));
              if (!isAssignedToUser && !isUnassignedCreatedByUser) continue;
            }

            final dateStr = (req.nextFollowupDate != null && req.nextFollowupDate!.trim().isNotEmpty)
                ? req.nextFollowupDate!
                : req.createdAt.toIso8601String();

            localFollowupList.add({
              'id': 'fu_${req.id}',
              'followup_date': dateStr,
              'status': req.status,
              'remarks': req.remarks ?? 'Follow-up scheduled',
              'notes': req.remarks ?? 'Follow-up scheduled',
              'requirement_id': req.id,
              'requirement': {
                'id': req.id,
                'customer_name': req.clientName,
                'mobile': req.clientMobile,
                'status': req.status,
                'listing_type': {'name': req.listingTypeName ?? 'Rent'},
              },
            });
          }

          if (localFollowupList.isNotEmpty) {
            resData['followups'] = localFollowupList;
          }
        } catch (_) {}
      }

      if (resData['rentalSiteVisitsDone'] == null && resData['resaleSiteVisitsDone'] == null) {
        try {
          final reqs = await RequirementsRepository().getRequirements(refreshFromServer: false);
          final currentUser = RoleGuard.currentUser;
          final currentUserName = currentUser?.fullName.trim().toLowerCase() ?? '';

          int localRentalSiteVisitsDone = 0;
          int localResaleSiteVisitsDone = 0;
          for (final req in reqs) {
            final st = req.status.trim().toLowerCase().replaceAll(RegExp(r'[\s_-]+'), '');
            final isSiteVisitDone = st == 'sitevisitdone' || st == 'sitevisitcompleted' || st == 'visitdone';
            if (!isSiteVisitDone) continue;

            if (currentUser != null && currentUser.role == 'Sales') {
              final isAssignedToUser = (req.assignedTo != null && (req.assignedTo == currentUser.id || (currentUserName.isNotEmpty && req.assignedTo!.trim().toLowerCase() == currentUserName))) ||
                  (req.assigneeName != null && currentUserName.isNotEmpty && req.assigneeName!.trim().toLowerCase() == currentUserName);
              final isUnassignedCreatedByUser = (req.assignedTo == null || req.assignedTo!.trim().isEmpty || req.assignedTo!.trim().toLowerCase() == 'unassigned') &&
                  (req.createdBy == currentUser.id || (req.creatorName != null && currentUserName.isNotEmpty && req.creatorName!.trim().toLowerCase() == currentUserName));
              if (!isAssignedToUser && !isUnassignedCreatedByUser) continue;
            }

            final isRent = (req.listingTypeName ?? '').toLowerCase().contains('rent');
            if (isRent) {
              localRentalSiteVisitsDone++;
            } else {
              localResaleSiteVisitsDone++;
            }
          }

          resData['rentalSiteVisitsDone'] = localRentalSiteVisitsDone;
          resData['resaleSiteVisitsDone'] = localResaleSiteVisitsDone;
          resData['siteVisitsDone'] = localRentalSiteVisitsDone + localResaleSiteVisitsDone;
        } catch (_) {}
      }

      emit(SalesDashboardState(data: resData));
    });

    on<AddNoteRequested>((event, emit) async {
      final currentNotes = List<dynamic>.from(state.data['notes'] ?? []);
      final tempNote = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'content': event.content,
        'is_completed': false,
        'created_at': DateTime.now().toIso8601String(),
      };
      final updatedData = Map<String, dynamic>.from(state.data);
      updatedData['notes'] = [tempNote, ...currentNotes];
      emit(SalesDashboardState(loading: false, data: updatedData));
      try {
        await DioClient.dio.post('/dashboard/notes', data: {'content': event.content});
        add(SalesDashboardRequested());
      } catch (e) {
        emit(SalesDashboardState(error: e.toString(), data: state.data));
      }
    });

    on<ToggleNoteRequested>((event, emit) async {
      final currentNotes = List<dynamic>.from(state.data['notes'] ?? []);
      final updatedNotes = currentNotes.map((n) {
        if (n is Map && (n['id'] ?? '').toString() == event.id) {
          final copy = Map<String, dynamic>.from(n);
          copy['is_completed'] = event.isCompleted;
          return copy;
        }
        return n;
      }).toList();
      final updatedData = Map<String, dynamic>.from(state.data);
      updatedData['notes'] = updatedNotes;
      emit(SalesDashboardState(loading: false, data: updatedData));
      try {
        await DioClient.dio.patch('/dashboard/notes/${event.id}', data: {'is_completed': event.isCompleted});
        add(SalesDashboardRequested());
      } catch (e) {
        emit(SalesDashboardState(error: e.toString(), data: state.data));
      }
    });

    on<DeleteNoteRequested>((event, emit) async {
      final currentNotes = List<dynamic>.from(state.data['notes'] ?? []);
      final updatedNotes = currentNotes.where((n) {
        return n is Map && (n['id'] ?? '').toString() != event.id;
      }).toList();
      final updatedData = Map<String, dynamic>.from(state.data);
      updatedData['notes'] = updatedNotes;
      emit(SalesDashboardState(loading: false, data: updatedData));
      try {
        await DioClient.dio.delete('/dashboard/notes/${event.id}');
        add(SalesDashboardRequested());
      } catch (e) {
        emit(SalesDashboardState(error: e.toString(), data: state.data));
      }
    });
  }
}
