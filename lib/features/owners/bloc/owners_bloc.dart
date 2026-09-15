import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:propkart/core/storage/repository_coordinator.dart';
import '../models/owner_model.dart';
import '../repository/owners_repository.dart';

// --- Events ---
abstract class OwnersEvent {}

class FetchOwnersEvent extends OwnersEvent {
  final String? search;
  FetchOwnersEvent({this.search});
}

class CreateOwnerEvent extends OwnersEvent {
  final OwnerModel owner;
  CreateOwnerEvent(this.owner);
}

class UpdateOwnerEvent extends OwnersEvent {
  final OwnerModel owner;
  UpdateOwnerEvent(this.owner);
}

class DeleteOwnerEvent extends OwnersEvent {
  final String id;
  DeleteOwnerEvent(this.id);
}

// --- States ---
abstract class OwnersState {}

class OwnersInitial extends OwnersState {}

class OwnersLoading extends OwnersState {}

class OwnersLoaded extends OwnersState {
  final List<OwnerModel> owners;
  OwnersLoaded({required this.owners});
}

class OwnersError extends OwnersState {
  final String message;
  OwnersError(this.message);
}

class OwnersSuccess extends OwnersState {
  final String message;
  OwnersSuccess(this.message);
}

// --- BLoC ---

class OwnersBloc extends Bloc<OwnersEvent, OwnersState> {
  final OwnersRepository ownersRepository;
  FetchOwnersEvent? _lastFetchEvent;
  StreamSubscription? _ownersSubscription;
  List<OwnerModel> _cachedOwners = [];

  OwnersBloc({required this.ownersRepository}) : super(OwnersInitial()) {
    on<FetchOwnersEvent>(_onFetchOwners);
    on<CreateOwnerEvent>(_onCreateOwner);
    on<UpdateOwnerEvent>(_onUpdateOwner);
    on<DeleteOwnerEvent>(_onDeleteOwner);

    _ownersSubscription = RepositoryCoordinator().ownersStream.listen((_) {
      if (_lastFetchEvent != null) {
        add(_lastFetchEvent!);
      }
    });
  }

  @override
  Future<void> close() {
    _ownersSubscription?.cancel();
    return super.close();
  }

  Future<void> _onFetchOwners(
    FetchOwnersEvent event,
    Emitter<OwnersState> emit,
  ) async {
    _lastFetchEvent = event;
    if (state is! OwnersLoaded) {
      emit(OwnersLoading());
    }
    try {
      final list = await ownersRepository.getOwners(search: event.search);
      _cachedOwners = list;
      emit(OwnersLoaded(owners: list));
    } catch (e) {
      emit(OwnersError(e.toString()));
      _restoreLoaded(emit);
    }
  }

  void _restoreLoaded(Emitter<OwnersState> emit) {
    if (_cachedOwners.isNotEmpty) {
      emit(OwnersLoaded(owners: _cachedOwners));
    }
  }

  Future<void> _onCreateOwner(
    CreateOwnerEvent event,
    Emitter<OwnersState> emit,
  ) async {
    try {
      await ownersRepository.createOwner(event.owner);
      emit(OwnersSuccess("Owner profile created successfully."));
      _restoreLoaded(emit);
    } catch (e) {
      emit(OwnersError(e.toString()));
      _restoreLoaded(emit);
    }
  }

  Future<void> _onUpdateOwner(
    UpdateOwnerEvent event,
    Emitter<OwnersState> emit,
  ) async {
    try {
      await ownersRepository.updateOwner(event.owner);
      emit(OwnersSuccess("Owner profile updated successfully."));
      _restoreLoaded(emit);
    } catch (e) {
      emit(OwnersError(e.toString()));
      _restoreLoaded(emit);
    }
  }

  Future<void> _onDeleteOwner(
    DeleteOwnerEvent event,
    Emitter<OwnersState> emit,
  ) async {
    try {
      await ownersRepository.deleteOwner(event.id);
      emit(OwnersSuccess("Owner profile deleted successfully."));
      _restoreLoaded(emit);
    } catch (e) {
      emit(OwnersError(e.toString()));
      _restoreLoaded(emit);
    }
  }
}
