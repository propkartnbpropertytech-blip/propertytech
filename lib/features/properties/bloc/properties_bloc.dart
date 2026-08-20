import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:propkart/core/storage/repository_coordinator.dart';
import '../models/property_model.dart';
import '../repository/properties_repository.dart';

// --- Events ---
abstract class PropertiesEvent {}

class LoadPropertiesEvent extends PropertiesEvent {
  final String? search;
  final String? categoryId;
  final String? areaId;
  final String? listingTypeId;
  final String? createdBy;
  final bool? isVerified;
  final bool? includeDeleted;
  final String activeTab; // 'All', 'My Active', 'My Deleted', 'Shortlisted'
  final bool refreshFromServer;

  LoadPropertiesEvent({
    this.search,
    this.categoryId,
    this.areaId,
    this.listingTypeId,
    this.createdBy,
    this.isVerified,
    this.includeDeleted,
    required this.activeTab,
    this.refreshFromServer = true,
  });
}

class LoadMetadataEvent extends PropertiesEvent {}

class CreatePropertyEvent extends PropertiesEvent {
  final Map<String, dynamic> propertyData;
  final String activeTab;
  CreatePropertyEvent(this.propertyData, {required this.activeTab});
}

class UpdatePropertyEvent extends PropertiesEvent {
  final String id;
  final Map<String, dynamic> propertyData;
  final String activeTab;
  UpdatePropertyEvent(this.id, this.propertyData, {required this.activeTab});
}

class ToggleVerificationEvent extends PropertiesEvent {
  final String id;
  final bool isVerified;
  final String activeTab;
  ToggleVerificationEvent(this.id, this.isVerified, {required this.activeTab});
}

class DeletePropertyEvent extends PropertiesEvent {
  final String id;
  final String activeTab;
  DeletePropertyEvent(this.id, {required this.activeTab});
}

class RestorePropertyEvent extends PropertiesEvent {
  final String id;
  final String activeTab;
  RestorePropertyEvent(this.id, {required this.activeTab});
}

class ToggleBookmarkEvent extends PropertiesEvent {
  final String propertyId;
  final String activeTab;
  ToggleBookmarkEvent(this.propertyId, {required this.activeTab});
}

// --- States ---
abstract class PropertiesState {}

class PropertiesInitial extends PropertiesState {}

class PropertiesLoading extends PropertiesState {}

class PropertiesLoaded extends PropertiesState {
  final List<PropertyModel> properties;
  final PropertyMetadataModel? metadata;
  final Set<String> bookmarkedIds;
  final String activeTab;

  PropertiesLoaded({
    required this.properties,
    this.metadata,
    required this.bookmarkedIds,
    required this.activeTab,
  });

  PropertiesLoaded copyWith({
    List<PropertyModel>? properties,
    PropertyMetadataModel? metadata,
    Set<String>? bookmarkedIds,
    String? activeTab,
  }) {
    return PropertiesLoaded(
      properties: properties ?? this.properties,
      metadata: metadata ?? this.metadata,
      bookmarkedIds: bookmarkedIds ?? this.bookmarkedIds,
      activeTab: activeTab ?? this.activeTab,
    );
  }
}

class PropertiesError extends PropertiesState {
  final String message;
  PropertiesError(this.message);
}

class PropertyCreatedState extends PropertiesState {
  final PropertyModel property;
  PropertyCreatedState(this.property);
}

class PropertyUpdatedState extends PropertiesState {
  final PropertyModel property;
  PropertyUpdatedState(this.property);
}

// --- BLoC ---

class PropertiesBloc extends Bloc<PropertiesEvent, PropertiesState> {
  final PropertiesRepository _repository = PropertiesRepository();
  PropertyMetadataModel? _cachedMetadata;
  LoadPropertiesEvent? _lastLoadEvent;
  StreamSubscription? _propertiesSubscription;
  StreamSubscription? _lookupsSubscription;

  PropertiesBloc() : super(PropertiesInitial()) {
    on<LoadPropertiesEvent>(_onLoadProperties);
    on<LoadMetadataEvent>(_onLoadMetadata);
    on<CreatePropertyEvent>(_onCreateProperty);
    on<UpdatePropertyEvent>(_onUpdateProperty);
    on<ToggleVerificationEvent>(_onToggleVerification);
    on<DeletePropertyEvent>(_onDeleteProperty);
    on<RestorePropertyEvent>(_onRestoreProperty);
    on<ToggleBookmarkEvent>(_onToggleBookmark);

    _propertiesSubscription = RepositoryCoordinator().propertiesStream.listen((_) {
      if (_lastLoadEvent != null) {
        add(LoadPropertiesEvent(
          search: _lastLoadEvent!.search,
          categoryId: _lastLoadEvent!.categoryId,
          areaId: _lastLoadEvent!.areaId,
          listingTypeId: _lastLoadEvent!.listingTypeId,
          createdBy: _lastLoadEvent!.createdBy,
          isVerified: _lastLoadEvent!.isVerified,
          includeDeleted: _lastLoadEvent!.includeDeleted,
          activeTab: _lastLoadEvent!.activeTab,
          refreshFromServer: false,
        ));
      }
    });

    _lookupsSubscription = RepositoryCoordinator().lookupsStream.listen((_) {
      if (_lastLoadEvent != null) {
        add(LoadPropertiesEvent(
          search: _lastLoadEvent!.search,
          categoryId: _lastLoadEvent!.categoryId,
          areaId: _lastLoadEvent!.areaId,
          listingTypeId: _lastLoadEvent!.listingTypeId,
          createdBy: _lastLoadEvent!.createdBy,
          isVerified: _lastLoadEvent!.isVerified,
          includeDeleted: _lastLoadEvent!.includeDeleted,
          activeTab: _lastLoadEvent!.activeTab,
          refreshFromServer: false,
        ));
      }
    });
  }

  @override
  Future<void> close() {
    _propertiesSubscription?.cancel();
    _lookupsSubscription?.cancel();
    return super.close();
  }

  Future<Set<String>> _getBookmarkedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> list = prefs.getStringList('shortlisted_properties') ?? [];
    return list.toSet();
  }

  Future<void> _saveBookmarkedIds(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('shortlisted_properties', ids.toList());
  }

  Future<void> _onLoadProperties(
    LoadPropertiesEvent event,
    Emitter<PropertiesState> emit,
  ) async {
    _lastLoadEvent = event;
    emit(PropertiesLoading());
    try {
      final bookmarked = await _getBookmarkedIds();
      
      if (_cachedMetadata == null) {
        _cachedMetadata = await _repository.getPropertyMetadata();
      }

      List<PropertyModel> properties = [];
      
      if (event.activeTab == 'Shortlisted') {
        final allProps = await _repository.getProperties(
          search: event.search,
          refreshFromServer: event.refreshFromServer,
        );
        properties = allProps.where((p) => bookmarked.contains(p.id)).toList();
      } else {
        bool? includeDeleted = event.includeDeleted;
        if (event.activeTab == 'My Deleted') {
          includeDeleted = true;
        } else if (event.activeTab == 'My Active') {
          includeDeleted = false;
        }

        properties = await _repository.getProperties(
          search: event.search,
          categoryId: event.categoryId,
          areaId: event.areaId,
          listingTypeId: event.listingTypeId,
          createdBy: event.createdBy,
          isVerified: event.isVerified,
          includeDeleted: includeDeleted,
          refreshFromServer: event.refreshFromServer,
        );
      }

      emit(PropertiesLoaded(
        properties: properties,
        metadata: _cachedMetadata,
        bookmarkedIds: bookmarked,
        activeTab: event.activeTab,
      ));
    } catch (e) {
      emit(PropertiesError(e.toString()));
    }
  }

  Future<void> _onLoadMetadata(
    LoadMetadataEvent event,
    Emitter<PropertiesState> emit,
  ) async {
    try {
      _cachedMetadata = await _repository.getPropertyMetadata();
      if (state is PropertiesLoaded) {
        emit((state as PropertiesLoaded).copyWith(metadata: _cachedMetadata));
      }
    } catch (e) {
      emit(PropertiesError(e.toString()));
    }
  }

  Future<void> _onCreateProperty(
    CreatePropertyEvent event,
    Emitter<PropertiesState> emit,
  ) async {
    emit(PropertiesLoading());
    try {
      final saved = await _repository.createProperty(event.propertyData);
      emit(PropertyCreatedState(saved));
      add(LoadPropertiesEvent(activeTab: event.activeTab));
    } catch (e) {
      emit(PropertiesError(e.toString()));
      add(LoadPropertiesEvent(activeTab: event.activeTab));
    }
  }

  Future<void> _onUpdateProperty(
    UpdatePropertyEvent event,
    Emitter<PropertiesState> emit,
  ) async {
    try {
      final saved = await _repository.updateProperty(event.id, event.propertyData);
      if (state is PropertiesLoaded) {
        final current = state as PropertiesLoaded;
        final updatedList = current.properties.map((p) => p.id == saved.id ? saved : p).toList();
        emit(PropertiesLoaded(
          properties: updatedList,
          metadata: current.metadata,
          bookmarkedIds: current.bookmarkedIds,
          activeTab: current.activeTab,
        ));
      } else {
        emit(PropertyUpdatedState(saved));
        add(LoadPropertiesEvent(activeTab: event.activeTab));
      }
    } catch (e) {
      emit(PropertiesError(e.toString()));
    }
  }

  Future<void> _onToggleVerification(
    ToggleVerificationEvent event,
    Emitter<PropertiesState> emit,
  ) async {
    try {
      final saved = await _repository.togglePropertyVerification(event.id, event.isVerified);
      if (state is PropertiesLoaded) {
        final current = state as PropertiesLoaded;
        final updatedList = current.properties.map((p) => p.id == saved.id ? saved : p).toList();
        emit(PropertiesLoaded(
          properties: updatedList,
          metadata: current.metadata,
          bookmarkedIds: current.bookmarkedIds,
          activeTab: current.activeTab,
        ));
      } else {
        add(LoadPropertiesEvent(activeTab: event.activeTab));
      }
    } catch (e) {
      emit(PropertiesError(e.toString()));
    }
  }

  Future<void> _onDeleteProperty(
    DeletePropertyEvent event,
    Emitter<PropertiesState> emit,
  ) async {
    emit(PropertiesLoading());
    try {
      await _repository.softDeleteProperty(event.id);
      add(LoadPropertiesEvent(activeTab: event.activeTab, refreshFromServer: true));
    } catch (e) {
      emit(PropertiesError(e.toString()));
      add(LoadPropertiesEvent(activeTab: event.activeTab, refreshFromServer: true));
    }
  }

  Future<void> _onRestoreProperty(
    RestorePropertyEvent event,
    Emitter<PropertiesState> emit,
  ) async {
    emit(PropertiesLoading());
    try {
      await _repository.restoreProperty(event.id);
      add(LoadPropertiesEvent(activeTab: event.activeTab));
    } catch (e) {
      emit(PropertiesError(e.toString()));
      add(LoadPropertiesEvent(activeTab: event.activeTab));
    }
  }

  Future<void> _onToggleBookmark(
    ToggleBookmarkEvent event,
    Emitter<PropertiesState> emit,
  ) async {
    try {
      final bookmarked = await _getBookmarkedIds();
      if (bookmarked.contains(event.propertyId)) {
        bookmarked.remove(event.propertyId);
      } else {
        bookmarked.add(event.propertyId);
      }
      await _saveBookmarkedIds(bookmarked);
      add(LoadPropertiesEvent(activeTab: event.activeTab));
    } catch (e) {
      emit(PropertiesError(e.toString()));
      add(LoadPropertiesEvent(activeTab: event.activeTab));
    }
  }
}
