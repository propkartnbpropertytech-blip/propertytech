import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/user_model.dart';
import '../repository/users_repository.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../../core/security/role_guard.dart';

// Events
abstract class UsersEvent extends Equatable {
  const UsersEvent();

  @override
  List<Object?> get props => [];
}

class FetchUsers extends UsersEvent {
  final String? search;
  final String? roleId;
  final String? status;

  const FetchUsers({this.search, this.roleId, this.status});

  @override
  List<Object?> get props => [search, roleId, status];
}

class FetchRoles extends UsersEvent {}

class CreateUserRequested extends UsersEvent {
  final Map<String, dynamic> userData;

  const CreateUserRequested({required this.userData});

  @override
  List<Object?> get props => [userData];
}

class UpdateUserRequested extends UsersEvent {
  final String id;
  final Map<String, dynamic> userData;

  const UpdateUserRequested({required this.id, required this.userData});

  @override
  List<Object?> get props => [id, userData];
}

class ToggleUserStatusRequested extends UsersEvent {
  final String id;
  final bool isActive;

  const ToggleUserStatusRequested({required this.id, required this.isActive});

  @override
  List<Object?> get props => [id, isActive];
}

class DeleteUserRequested extends UsersEvent {
  final String id;

  const DeleteUserRequested({required this.id});

  @override
  List<Object?> get props => [id];
}

// States
abstract class UsersState extends Equatable {
  const UsersState();

  @override
  List<Object?> get props => [];
}

class UsersInitial extends UsersState {}

class UsersLoading extends UsersState {}

class UsersLoaded extends UsersState {
  final List<UserModel> users;
  final List<RoleModel> roles;

  const UsersLoaded({required this.users, required this.roles});

  @override
  List<Object?> get props => [users, roles];
}

class UsersOperationSuccess extends UsersState {
  final String message;

  const UsersOperationSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class UsersError extends UsersState {
  final String message;

  const UsersError({required this.message});

  @override
  List<Object?> get props => [message];
}

// BLoC
class UsersBloc extends Bloc<UsersEvent, UsersState> {
  final UsersRepository _usersRepository;
  final AuthBloc? _authBloc;
  List<RoleModel> _cachedRoles = [];
  List<UserModel> _cachedUsers = [];

  UsersBloc({
    required UsersRepository usersRepository,
    AuthBloc? authBloc,
  })  : _usersRepository = usersRepository,
        _authBloc = authBloc,
        super(UsersInitial()) {
    on<FetchUsers>(_onFetchUsers);
    on<FetchRoles>(_onFetchRoles);
    on<CreateUserRequested>(_onCreateUser);
    on<UpdateUserRequested>(_onUpdateUser);
    on<ToggleUserStatusRequested>(_onToggleUserStatus);
    on<DeleteUserRequested>(_onDeleteUser);
  }

  String? get _callerRole {
    final state = _authBloc?.state;
    if (state is Authenticated) return state.user.role;
    return null;
  }

  String? _resolveTargetRoleName(Map<String, dynamic> userData) {
    final roleId = userData['role_id']?.toString() ?? userData['roleId']?.toString();
    if (roleId != null && _cachedRoles.isNotEmpty) {
      for (final r in _cachedRoles) {
        if (r.id == roleId) {
          final resolvedName = r.name;
          if (resolvedName.toLowerCase() == 'admin' && _callerRole?.toLowerCase() == 'admin') {
            return 'Telecaller';
          }
          return resolvedName;
        }
      }
    }
    return userData['role']?.toString() ?? userData['roleName']?.toString();
  }

  Future<void> _onFetchUsers(
    FetchUsers event,
    Emitter<UsersState> emit,
  ) async {
    if (_cachedUsers.isNotEmpty) {
      emit(UsersLoaded(users: _cachedUsers, roles: _cachedRoles));
    } else {
      emit(UsersLoading());
    }
    try {
      if (_cachedRoles.isEmpty) {
        _cachedRoles = await _usersRepository.getRoles();
      }
      final users = await _usersRepository.getUsers(
        search: event.search,
        roleId: event.roleId,
        status: event.status,
      );
      _cachedUsers = users;
      emit(UsersLoaded(users: users, roles: _cachedRoles));
    } catch (e) {
      emit(UsersError(message: e.toString()));
      emit(UsersLoaded(users: _cachedUsers, roles: _cachedRoles));
    }
  }

  Future<void> _onFetchRoles(
    FetchRoles event,
    Emitter<UsersState> emit,
  ) async {
    try {
      _cachedRoles = await _usersRepository.getRoles();
    } catch (_) {}
  }

  Future<void> _onCreateUser(
    CreateUserRequested event,
    Emitter<UsersState> emit,
  ) async {
    try {
      if (_cachedRoles.isEmpty) {
        _cachedRoles = await _usersRepository.getRoles();
      }
      final denial = RoleGuard.validateUserMutation(
        callerRole: _callerRole,
        targetRoleName: _resolveTargetRoleName(event.userData),
        isDelete: false,
      );
      if (denial != null) {
        emit(UsersError(message: denial));
        emit(UsersLoaded(users: _cachedUsers, roles: _cachedRoles));
        return;
      }
      await _usersRepository.createUser(event.userData);
      emit(const UsersOperationSuccess(message: "User created successfully."));
    } catch (e) {
      emit(UsersError(message: e.toString()));
      emit(UsersLoaded(users: _cachedUsers, roles: _cachedRoles));
    }
  }

  Future<void> _onUpdateUser(
    UpdateUserRequested event,
    Emitter<UsersState> emit,
  ) async {
    try {
      if (_cachedRoles.isEmpty) {
        _cachedRoles = await _usersRepository.getRoles();
      }
      final denial = RoleGuard.validateUserMutation(
        callerRole: _callerRole,
        targetRoleName: _resolveTargetRoleName(event.userData),
        isDelete: false,
      );
      if (denial != null) {
        emit(UsersError(message: denial));
        emit(UsersLoaded(users: _cachedUsers, roles: _cachedRoles));
        return;
      }
      await _usersRepository.updateUser(event.id, event.userData);
      emit(const UsersOperationSuccess(message: "User updated successfully."));
    } catch (e) {
      emit(UsersError(message: e.toString()));
      emit(UsersLoaded(users: _cachedUsers, roles: _cachedRoles));
    }
  }

  Future<void> _onToggleUserStatus(
    ToggleUserStatusRequested event,
    Emitter<UsersState> emit,
  ) async {
    try {
      if (!RoleGuard.canManageEmployees(_callerRole)) {
        emit(const UsersError(message: 'You do not have permission to manage employees.'));
        emit(UsersLoaded(users: _cachedUsers, roles: _cachedRoles));
        return;
      }
      await _usersRepository.toggleUserStatus(event.id, event.isActive);
      emit(const UsersOperationSuccess(message: "User status updated."));
    } catch (e) {
      emit(UsersError(message: e.toString()));
      emit(UsersLoaded(users: _cachedUsers, roles: _cachedRoles));
    }
  }

  Future<void> _onDeleteUser(
    DeleteUserRequested event,
    Emitter<UsersState> emit,
  ) async {
    try {
      if (!RoleGuard.canManageEmployees(_callerRole)) {
        emit(const UsersError(message: 'You do not have permission to manage employees.'));
        emit(UsersLoaded(users: _cachedUsers, roles: _cachedRoles));
        return;
      }
      await _usersRepository.deleteUser(event.id);
      _cachedUsers.removeWhere((u) => u.id == event.id);
      emit(const UsersOperationSuccess(message: "User deleted successfully."));
      emit(UsersLoaded(users: List.from(_cachedUsers), roles: _cachedRoles));
    } catch (e) {
      emit(UsersError(message: e.toString()));
      emit(UsersLoaded(users: _cachedUsers, roles: _cachedRoles));
    }
  }
}
