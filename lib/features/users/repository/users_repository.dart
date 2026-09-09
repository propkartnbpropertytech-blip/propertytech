import '../models/user_model.dart';
import '../services/users_service.dart';

class UsersRepository {
  final UsersService _usersService = UsersService();

  Future<List<UserModel>> getUsers({
    String? search,
    String? roleId,
    String? status,
  }) async {
    final response = await _usersService.getUsers(
      search: search,
      roleId: roleId,
      status: status,
    );
    final data = response['data'] as Map<String, dynamic>? ?? {};
    final list = data['users'] as List? ?? [];
    return list.map((item) => UserModel.fromJson(item)).toList();
  }

  Future<List<RoleModel>> getRoles() async {
    final response = await _usersService.getRoles();
    final data = response['data'] as Map<String, dynamic>? ?? {};
    final list = data['roles'] as List? ?? [];
    return list.map((item) => RoleModel.fromJson(item)).toList();
  }

  Future<UserModel> createUser(Map<String, dynamic> userData) async {
    final response = await _usersService.createUser(userData);
    final data = response['data'] as Map<String, dynamic>? ?? {};
    return UserModel.fromJson(data['user'] ?? {});
  }

  Future<UserModel> updateUser(String id, Map<String, dynamic> userData) async {
    final response = await _usersService.updateUser(id, userData);
    final data = response['data'] as Map<String, dynamic>? ?? {};
    return UserModel.fromJson(data['user'] ?? {});
  }

  Future<UserModel> toggleUserStatus(String id, bool isActive) async {
    final response = await _usersService.toggleUserStatus(id, isActive);
    final data = response['data'] as Map<String, dynamic>? ?? {};
    return UserModel.fromJson(data['user'] ?? {});
  }

  Future<UserModel> deleteUser(String id) async {
    final response = await _usersService.deleteUser(id);
    final data = response['data'] as Map<String, dynamic>? ?? {};
    return UserModel.fromJson(data['user'] ?? {});
  }
}
