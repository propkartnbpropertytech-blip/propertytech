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
  final RequirementModel? newlyAdded;
  final bool isSilentRefreshing;

  RequirementsLoaded({
    required this.requirements,
    this.newlyAdded,
    this.isSilentRefreshing = false,
  });

  RequirementsLoaded copyWith({
    List<RequirementModel>? requirements,
    RequirementModel? newlyAdded,
    bool? isSilentRefreshing,
  }) {
    return RequirementsLoaded(
      requirements: requirements ?? this.requirements,
      newlyAdded: newlyAdded ?? this.newlyAdded,
      isSilentRefreshing: isSilentRefreshing ?? this.isSilentRefreshing,
    );
  }
}

class RequirementsError extends RequirementsState {
  final String message;
  RequirementsError(this.message);
}

class RequirementsSuccess extends RequirementsLoaded {
  final String message;
  final RequirementModel? requirement;

  RequirementsSuccess(
    this.message, {
    this.requirement,
    List<RequirementModel>? requirements,
    super.newlyAdded,
    super.isSilentRefreshing,
  }) : super(
          requirements: requirements ?? (requirement != null ? [requirement] : const []),
        );
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
      } else {
        add(FetchRequirementsEvent());
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
    final hasExistingData = state is RequirementsLoaded && (state as RequirementsLoaded).requirements.isNotEmpty;
    if (!hasExistingData) {
      emit(RequirementsLoading());
    } else {
      emit((state as RequirementsLoaded).copyWith(isSilentRefreshing: true));
    }
    try {
      final list = await requirementsRepository.getRequirements(
        search: event.search,
        configurationId: event.configurationId,
        propertyTypeId: event.propertyTypeId,
        status: event.status,
        listingTypeId: event.listingTypeId,
      );
      emit(RequirementsLoaded(requirements: list, isSilentRefreshing: false));
    } catch (e) {
      if (!hasExistingData) {
        emit(RequirementsError(e.toString()));
      }
    }
  }

  Future<void> _onCreateRequirement(
    CreateRequirementEvent event,
    Emitter<RequirementsState> emit,
  ) async {
    try {
      final saved = await requirementsRepository.createRequirement(event.requirement);
      final List<RequirementModel> next;
      if (state is RequirementsLoaded) {
        final current = state as RequirementsLoaded;
        next = [saved, ...current.requirements.where((r) => r.id != saved.id)];
      } else {
        next = [saved];
      }
      emit(RequirementsSuccess(
        "Requirement created successfully.",
        requirement: saved,
        requirements: next,
        newlyAdded: saved,
      ));
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
      List<RequirementModel> next = [updated];
      if (state is RequirementsLoaded) {
        final current = state as RequirementsLoaded;
        final patched = current.requirements.map((r) {
          return r.id == updated.id ? updated : r;
        }).toList();
        final exists = current.requirements.any((r) => r.id == updated.id);
        next = exists ? patched : [...current.requirements, updated];
        emit(RequirementsLoaded(
          requirements: next,
        ));
      }

      emit(RequirementsSuccess(
        "Requirement updated successfully.",
        requirement: updated,
        requirements: next,
      ));
    } catch (e) {
      emit(RequirementsError(e.toString()));
    }
  }

  Future<void> _onDeleteRequirement(
    DeleteRequirementEvent event,
    Emitter<RequirementsState> emit,
  ) async {
    try {
      await requirementsRepository.deleteRequirement(event.id);
      List<RequirementModel> next = [];
      if (state is RequirementsLoaded) {
        final current = state as RequirementsLoaded;
        next = current.requirements.where((r) => r.id != event.id).toList();
        emit(RequirementsLoaded(
          requirements: next,
        ));
      }
      emit(RequirementsSuccess("Requirement deleted successfully.", requirements: next));
    } catch (e) {
      emit(RequirementsError(e.toString()));
    }
  }
}
