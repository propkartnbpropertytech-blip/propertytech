import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:propkart/core/storage/repository_coordinator.dart';
import '../models/builder_model.dart';
import '../repository/builders_repository.dart';

// --- Events ---
abstract class BuildersEvent {}

class FetchBuildersEvent extends BuildersEvent {
  final String? search;
  final String? tier;
  FetchBuildersEvent({this.search, this.tier});
}

class CreateBuilderEvent extends BuildersEvent {
  final BuilderModel builder;
  CreateBuilderEvent(this.builder);
}

class UpdateBuilderEvent extends BuildersEvent {
  final BuilderModel builder;
  UpdateBuilderEvent(this.builder);
}

class DeleteBuilderEvent extends BuildersEvent {
  final String id;
  DeleteBuilderEvent(this.id);
}

// --- States ---
abstract class BuildersState {}

class BuildersInitial extends BuildersState {}

class BuildersLoading extends BuildersState {}

class BuildersLoaded extends BuildersState {
  final List<BuilderModel> builders;
  BuildersLoaded({required this.builders});
}

class BuildersError extends BuildersState {
  final String message;
  BuildersError(this.message);
}

class BuildersSuccess extends BuildersState {
  final String message;
  BuildersSuccess(this.message);
}

// --- BLoC ---

class BuildersBloc extends Bloc<BuildersEvent, BuildersState> {
  final BuildersRepository buildersRepository;
  FetchBuildersEvent? _lastFetchEvent;
  StreamSubscription? _buildersSubscription;

  BuildersBloc({required this.buildersRepository}) : super(BuildersInitial()) {
    on<FetchBuildersEvent>(_onFetchBuilders);
    on<CreateBuilderEvent>(_onCreateBuilder);
    on<UpdateBuilderEvent>(_onUpdateBuilder);
    on<DeleteBuilderEvent>(_onDeleteBuilder);

    _buildersSubscription = RepositoryCoordinator().buildersStream.listen((_) {
      if (_lastFetchEvent != null) {
        add(_lastFetchEvent!);
      }
    });
  }

  @override
  Future<void> close() {
    _buildersSubscription?.cancel();
    return super.close();
  }

  Future<void> _onFetchBuilders(
    FetchBuildersEvent event,
    Emitter<BuildersState> emit,
  ) async {
    _lastFetchEvent = event;
    emit(BuildersLoading());
    try {
      final list = await buildersRepository.getBuilders(
        search: event.search,
        tier: event.tier,
      );
      emit(BuildersLoaded(builders: list));
    } catch (e) {
      emit(BuildersError(e.toString()));
    }
  }

  Future<void> _onCreateBuilder(
    CreateBuilderEvent event,
    Emitter<BuildersState> emit,
  ) async {
    emit(BuildersLoading());
    try {
      await buildersRepository.createBuilder(event.builder);
      emit(BuildersSuccess("Builder profile created successfully."));
    } catch (e) {
      emit(BuildersError(e.toString()));
    }
  }

  Future<void> _onUpdateBuilder(
    UpdateBuilderEvent event,
    Emitter<BuildersState> emit,
  ) async {
    emit(BuildersLoading());
    try {
      await buildersRepository.updateBuilder(event.builder);
      emit(BuildersSuccess("Builder profile updated successfully."));
    } catch (e) {
      emit(BuildersError(e.toString()));
    }
  }

  Future<void> _onDeleteBuilder(
    DeleteBuilderEvent event,
    Emitter<BuildersState> emit,
  ) async {
    emit(BuildersLoading());
    try {
      await buildersRepository.deleteBuilder(event.id);
      emit(BuildersSuccess("Builder profile deleted successfully."));
    } catch (e) {
      emit(BuildersError(e.toString()));
    }
  }
}
