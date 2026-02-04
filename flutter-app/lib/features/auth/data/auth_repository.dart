import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import 'models/auth_models.dart';

class AuthRepository {
  final DioClient _dioClient;
  final SharedPreferences _prefs;

  AuthRepository(this._dioClient, this._prefs);

  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.login,
        data: request.toJson(),
      );

      final loginResponse = LoginResponse.fromJson(response.data);

      // Save tokens and user info
      await _prefs.setString(StorageKeys.accessToken, loginResponse.accessToken);
      await _prefs.setString(StorageKeys.refreshToken, loginResponse.refreshToken);
      await _prefs.setString(StorageKeys.userId, loginResponse.userId);
      await _prefs.setString(StorageKeys.tenantId, loginResponse.tenantId);
      if (loginResponse.displayName != null) {
        await _prefs.setString(StorageKeys.userName, loginResponse.displayName!);
      }
      if (loginResponse.userType != null) {
        await _prefs.setString(StorageKeys.userType, loginResponse.userType!);
      }

      return loginResponse;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> saveServerIp(String serverIp) async {
    await _prefs.setString(StorageKeys.serverIp, serverIp);
  }

  String? getServerIp() {
    return _prefs.getString(StorageKeys.serverIp);
  }

  Future<void> logout() async {
    await _prefs.remove(StorageKeys.accessToken);
    await _prefs.remove(StorageKeys.refreshToken);
    await _prefs.remove(StorageKeys.userId);
    await _prefs.remove(StorageKeys.tenantId);
    await _prefs.remove(StorageKeys.userName);
    await _prefs.remove(StorageKeys.userEmail);
    await _prefs.remove(StorageKeys.userType);
  }

  bool isLoggedIn() {
    final token = _prefs.getString(StorageKeys.accessToken);
    return token != null && token.isNotEmpty;
  }

  User? getCurrentUser() {
    final userId = _prefs.getString(StorageKeys.userId);
    final userName = _prefs.getString(StorageKeys.userName);
    final userEmail = _prefs.getString(StorageKeys.userEmail);
    final tenantId = _prefs.getString(StorageKeys.tenantId);
    final userType = _prefs.getString(StorageKeys.userType);

    if (userId == null || tenantId == null) return null;

    return User(
      id: userId,
      name: userName ?? 'User',
      email: userEmail ?? '',
      tenantId: tenantId,
      userType: userType,
    );
  }

  String _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map && data['message'] != null) {
        return data['message'];
      }
      switch (e.response!.statusCode) {
        case 400:
          return 'Invalid request. Please check your input.';
        case 401:
          return 'Invalid credentials. Please try again.';
        case 403:
          return 'Access denied.';
        case 404:
          return 'User not found.';
        case 500:
          return 'Server error. Please try again later.';
        default:
          return 'Something went wrong. Please try again.';
      }
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timeout. Please check your network.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Cannot connect to server. Please check the server IP.';
    }
    return 'Network error. Please check your connection.';
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dioClient = ref.watch(authDioClientProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthRepository(dioClient, prefs);
});
