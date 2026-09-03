import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/client_model.dart';
import '../repository/clients_repository.dart';

// --- Events ---
abstract class ClientsEvent {}

class FetchClientsEvent extends ClientsEvent {
  final String? search;
  final String? stage;
  final String? source;
  FetchClientsEvent({this.search, this.stage, this.source});
}

class CreateClientEvent extends ClientsEvent {
  final ClientModel client;
  CreateClientEvent(this.client);
}

class UpdateClientEvent extends ClientsEvent {
  final ClientModel client;
  UpdateClientEvent(this.client);
}

class DeleteClientEvent extends ClientsEvent {
  final String id;
  DeleteClientEvent(this.id);
}

// --- States ---
abstract class ClientsState {}

class ClientsInitial extends ClientsState {}

class ClientsLoading extends ClientsState {}

class ClientsLoaded extends ClientsState {
  final List<ClientModel> clients;
  ClientsLoaded({required this.clients});
}

class ClientsError extends ClientsState {
  final String message;
  ClientsError(this.message);
}

class ClientsSuccess extends ClientsState {
  final String message;
  ClientsSuccess(this.message);
}

// --- BLoC ---
class ClientsBloc extends Bloc<ClientsEvent, ClientsState> {
  final ClientsRepository clientsRepository;

  ClientsBloc({required this.clientsRepository}) : super(ClientsInitial()) {
    on<FetchClientsEvent>(_onFetchClients);
    on<CreateClientEvent>(_onCreateClient);
    on<UpdateClientEvent>(_onUpdateClient);
    on<DeleteClientEvent>(_onDeleteClient);
  }

  Future<void> _onFetchClients(
    FetchClientsEvent event,
    Emitter<ClientsState> emit,
  ) async {
    emit(ClientsLoading());
    try {
      final list = await clientsRepository.getClients(
        search: event.search,
        stage: event.stage,
        source: event.source,
      );
      emit(ClientsLoaded(clients: list));
    } catch (e) {
      emit(ClientsError(e.toString()));
    }
  }

  Future<void> _onCreateClient(
    CreateClientEvent event,
    Emitter<ClientsState> emit,
  ) async {
    emit(ClientsLoading());
    try {
      await clientsRepository.createClient(event.client);
      emit(ClientsSuccess("Client created successfully."));
    } catch (e) {
      emit(ClientsError(e.toString()));
    }
  }

  Future<void> _onUpdateClient(
    UpdateClientEvent event,
    Emitter<ClientsState> emit,
  ) async {
    emit(ClientsLoading());
    try {
      await clientsRepository.updateClient(event.client);
      emit(ClientsSuccess("Client updated successfully."));
    } catch (e) {
      emit(ClientsError(e.toString()));
    }
  }

  Future<void> _onDeleteClient(
    DeleteClientEvent event,
    Emitter<ClientsState> emit,
  ) async {
    emit(ClientsLoading());
    try {
      await clientsRepository.deleteClient(event.id);
      emit(ClientsSuccess("Client deleted successfully."));
    } catch (e) {
      emit(ClientsError(e.toString()));
    }
  }
}
