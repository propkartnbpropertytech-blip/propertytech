import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../models/team_message_model.dart';

class TeamMessagesService {
  final ApiClient _apiClient = ApiClient();

  Future<List<TeamChatUserModel>> getTeamUsers() async {
    try {
      final response = await _apiClient.get('/team-messages/users');
      if (response.data is Map<String, dynamic> && response.data['success'] == true) {
        final List usersList = response.data['data']?['users'] ?? [];
        return usersList.map((u) => TeamChatUserModel.fromJson(u as Map<String, dynamic>)).toList();
      }
      throw ApiException(message: "Failed to fetch team users.");
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<List<TeamMessageModel>> getConversation(String otherUserId, {String? withAdminId}) async {
    try {
      final queryParams = withAdminId != null && withAdminId.isNotEmpty
          ? {'with_admin_id': withAdminId}
          : null;
      final response = await _apiClient.get(
        '/team-messages/conversation/$otherUserId',
        queryParameters: queryParams,
      );
      if (response.data is Map<String, dynamic> && response.data['success'] == true) {
        final List msgList = response.data['data']?['messages'] ?? [];
        return msgList.map((m) => TeamMessageModel.fromJson(m as Map<String, dynamic>)).toList();
      }
      throw ApiException(message: "Failed to fetch conversation.");
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<TeamMessageModel> sendMessage({required String receiverId, required String message}) async {
    try {
      final response = await _apiClient.post(
        '/team-messages/send',
        {
          'receiver_id': receiverId,
          'message': message,
        },
      );
      if (response.data is Map<String, dynamic> && response.data['success'] == true) {
        final msgData = response.data['data']?['message'];
        if (msgData != null) {
          return TeamMessageModel.fromJson(msgData as Map<String, dynamic>);
        }
      }
      throw ApiException(message: "Failed to send message.");
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<void> markAsRead(String otherUserId) async {
    try {
      await _apiClient.patch('/team-messages/read/$otherUserId', {});
    } catch (_) {}
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _apiClient.get('/team-messages/unread-count');
      if (response.data is Map<String, dynamic> && response.data['success'] == true) {
        return (response.data['data']?['unread_count'] as int?) ?? 0;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }
}
