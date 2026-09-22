import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/api/api_exception.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> getCaptcha() async {
    try {
      final response = await _apiClient.get(ApiConstants.captcha);
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      throw ApiException(message: "Invalid CAPTCHA response format.");
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>> login(
    String email,
    String password, {
    bool rememberMe = false,
    String? captchaId,
    String? captchaAnswer,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.login,
        {
          'email': email,
          'password': password,
          'rememberMe': rememberMe,
          if (captchaId != null && captchaId.isNotEmpty) 'captchaId': captchaId,
          if (captchaAnswer != null && captchaAnswer.isNotEmpty) 'captchaAnswer': captchaAnswer,
        },
      );
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      throw ApiException(message: "Invalid response format from server.");
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// [refreshToken] is required on mobile; on web omit so the HttpOnly cookie is used.
  Future<Map<String, dynamic>> refresh(String? refreshToken) async {
    try {
      final body = <String, dynamic>{};
      if (refreshToken != null && refreshToken.isNotEmpty) {
        body['refreshToken'] = refreshToken;
      }
      final response = await _apiClient.post(
        ApiConstants.refresh,
        body,
      );
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      throw ApiException(message: "Invalid refresh response.");
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<void> logout({String? refreshToken}) async {
    try {
      await _apiClient.post(
        ApiConstants.logout,
        {
          if (refreshToken != null && refreshToken.isNotEmpty) 'refreshToken': refreshToken,
        },
      );
    } catch (_) {
      // Local teardown still proceeds even if server revoke fails.
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _apiClient.get(ApiConstants.me);
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      throw ApiException(message: "Invalid response format from server.");
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>> verifyMfa(String mfaChallengeId, String code) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.mfaVerify,
        {
          'mfaChallengeId': mfaChallengeId,
          'code': code.trim(),
        },
      );
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      throw ApiException(message: "Invalid MFA verification response.");
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>> setupMfa() async {
    try {
      final response = await _apiClient.post(ApiConstants.mfaSetup, {});
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      throw ApiException(message: "Invalid MFA setup response.");
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>> confirmMfa(String code) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.mfaConfirm,
        {'code': code.trim()},
      );
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      throw ApiException(message: "Invalid MFA confirmation response.");
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>> disableMfa(String password) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.mfaDisable,
        {'password': password},
      );
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      throw ApiException(message: "Invalid MFA disable response.");
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
}

