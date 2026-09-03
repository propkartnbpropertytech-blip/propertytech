import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:propkart/core/storage/repository_coordinator.dart';
import '../models/requirement_model.dart';
import '../repository/requirements_repository.dart';

// --- Events ---
abstract class RequirementsEvent {}

class FetchRequirementsEvent extends RequirementsEvent {
  final String? search;
  final String? configurationId;
  final String? propertyTypeId;
  final String? status;
  final String? listingTypeId;
  FetchRequirementsEvent({this.search, this.configurationId, this.propertyTypeId, this.status, this.listingTypeId});
}

class CreateRequirementEvent extends RequirementsEvent {
  final RequirementModel requirement;
  CreateRequirementEvent(this.requirement);
}

class UpdateRequirementEvent extends RequirementsEvent {
  final RequirementModel requirement;
  UpdateRequirementEvent(this.requirement);
}

class DeleteRequirementEvent extends RequirementsEvent {
  final String id;
  DeleteRequirementEvent(this.id);
}

// --- States ---
abstract class RequirementsState {}

class RequirementsInitial extends RequirementsState {}

class RequirementsLoading extends RequirementsState {}

class RequirementsLoaded extends RequirementsState {
  final List<RequirementModel> requirements;
  RequirementsLoaded({required this.requirements});
}

class RequirementsError extends RequirementsState {
  final String message;
  RequirementsError(this.message);
}

class RequirementsSuccess extends RequirementsState {
  final String message;
  RequirementsSuccess(this.message);
}

// --- BLoC ---

class RequirementsBloc extends Bloc<RequirementsEvent, RequirementsState> {
  final RequirementsRepository requirementsRepository;
  FetchRequirementsEvent? _lastFetchEvent;
  StreamSubscription? _requirementsSubscription;

  RequirementsBloc({required this.requirementsRepository}) : super(RequirementsInitial()) {
    on<FetchRequirementsEvent>(_onFetchRequirements);
    on<CreateRequirementEvent>(_onCreateRequirement);
    on<UpdateRequirementEvent>(_onUpdateRequirement);
    on<DeleteRequirementEvent>(_onDeleteRequirement);

    _requirementsSubscription = RepositoryCoordinator().requirementsStream.listen((_) {
      if (_lastFetchEvent != null) {
        add(_lastFetchEvent!);
      }
    });
  }

  @override
  Future<void> close() {
    _requirementsSubscription?.cancel();
    return super.close();
  }

  Future<void> _onFetchRequirements(
    FetchRequirementsEvent event,
    Emitter<RequirementsState> emit,
  ) async {
    _lastFetchEvent = event;
    // Avoid blanking My Won / tables when refreshing after a status change.
    if (state is! RequirementsLoaded) {
      emit(RequirementsLoading());
    }
    try {
      final list = await requirementsRepository.getRequirements(
        search: event.search,
        configurationId: event.configurationId,
        propertyTypeId: event.propertyTypeId,
        status: event.status,
        listingTypeId: event.listingTypeId,
      );
      emit(RequirementsLoaded(requirements: list));
    } catch (e) {
      emit(RequirementsError(e.toString()));
    }
  }

  Future<void> _onCreateRequirement(
    CreateRequirementEvent event,
    Emitter<RequirementsState> emit,
  ) async {
    emit(RequirementsLoading());
    try {
      await requirementsRepository.createRequirement(event.requirement);
      emit(RequirementsSuccess("Requirement created successfully."));
    } catch (e) {
      emit(RequirementsError(e.toString()));
    }
  }

  Future<void> _onUpdateRequirement(
    UpdateRequirementEvent event,
    Emitter<RequirementsState> emit,
  ) async {
    try {
      final updated = await requirementsRepository.updateRequirement(event.requirement);

      // Optimistically patch the in-memory list so My Won status UI updates immediately.
      if (state is RequirementsLoaded) {
        final current = state as RequirementsLoaded;
        final next = current.requirements.map((r) {
          return r.id == updated.id ? updated : r;
        }).toList();
        final exists = current.requirements.any((r) => r.id == updated.id);
        emit(RequirementsLoaded(
          requirements: exists ? next : [...current.requirements, updated],
        ));
      }

      emit(RequirementsSuccess("Requirement updated successfully."));
    } catch (e) {
      emit(RequirementsError(e.toString()));
    }
  }

  Future<void> _onDeleteRequirement(
    DeleteRequirementEvent event,
    Emitter<RequirementsState> emit,
  ) async {
    emit(RequirementsLoading());
    try {
      await requirementsRepository.deleteRequirement(event.id);
      emit(RequirementsSuccess("Requirement deleted successfully."));
    } catch (e) {
      emit(RequirementsError(e.toString()));
    }
  }
}
