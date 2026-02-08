import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import 'super_admin_models.dart';

class SuperAdminRepository {
  final DioClient _dioClient;

  SuperAdminRepository(this._dioClient);

  // ============== Schools (Tenants) ==============

  /// Get all schools (tenants)
  Future<List<School>> getSchools() async {
    try {
      final response = await _dioClient.get('/v1/tenants');
      final List<dynamic> data = response.data;
      return data.map((json) => School.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get a single school by ID
  Future<School> getSchool(String schoolId) async {
    try {
      final response = await _dioClient.get('/v1/tenants/$schoolId');
      return School.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Create a new school (tenant)
  Future<School> createSchool(CreateSchoolRequest request) async {
    try {
      final response = await _dioClient.post(
        '/v1/tenants',
        data: request.toJson(),
      );
      return School.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Suspend a school
  Future<School> suspendSchool(String schoolId) async {
    try {
      final response = await _dioClient.post('/v1/tenants/$schoolId/suspend');
      return School.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Activate a school
  Future<School> activateSchool(String schoolId) async {
    try {
      final response = await _dioClient.post('/v1/tenants/$schoolId/activate');
      return School.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Delete a school
  Future<void> deleteSchool(String schoolId) async {
    try {
      await _dioClient.delete('/v1/tenants/$schoolId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============== User Profiles ==============

  /// Get all user profiles for a specific tenant
  Future<List<UserProfile>> getUserProfiles(String tenantId) async {
    try {
      final response = await _dioClient.get('/v1/tenants/$tenantId/profiles');
      final List<dynamic> data = response.data;
      return data.map((json) => UserProfile.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get all users across all tenants (for super admin)
  Future<List<UserProfile>> getAllUsers() async {
    try {
      // First get all schools
      final schools = await getSchools();
      final List<UserProfile> allUsers = [];
      print('DEBUG getAllUsers: Found ${schools.length} schools');

      // For each school, get users and attach school name
      for (final school in schools) {
        // Skip system tenant
        if (school.id == '00000000-0000-0000-0000-000000000001') {
          print('DEBUG getAllUsers: Skipping system tenant');
          continue;
        }

        try {
          print('DEBUG getAllUsers: Fetching users for ${school.name} (${school.id})');
          final response = await _dioClient.get('/v1/tenants/${school.id}/profiles');
          final List<dynamic> data = response.data;
          final users = data.map((json) {
            final profile = UserProfile.fromJson(json);
            // Create a new profile with school name
            return UserProfile(
              id: profile.id,
              tenantId: profile.tenantId,
              userId: profile.userId,
              displayName: profile.displayName,
              firstName: profile.firstName,
              lastName: profile.lastName,
              email: profile.email,
              phone: profile.phone,
              avatarUrl: profile.avatarUrl,
              userType: profile.userType,
              status: profile.status,
              createdAt: profile.createdAt,
              updatedAt: profile.updatedAt,
              schoolName: school.name,
            );
          }).toList();
          print('DEBUG getAllUsers: Found ${users.length} users in ${school.name}');
          allUsers.addAll(users);
        } catch (e) {
          // Log error but continue with other schools
          print('DEBUG getAllUsers: Error fetching users for ${school.name}: $e');
        }
      }

      print('DEBUG getAllUsers: Total users found: ${allUsers.length}');
      return allUsers;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Create a user identity in auth service
  Future<UserIdentity> createUserIdentity({
    required String email,
    required String password,
    required String tenantId,
  }) async {
    try {
      final response = await _dioClient.post(
        '/v1/auth/signup',
        data: {
          'email': email,
          'password': password,
          'tenantId': tenantId,
        },
      );
      return UserIdentity.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Create a user profile
  Future<UserProfile> createUserProfile({
    required String tenantId,
    required CreateUserProfileRequest request,
  }) async {
    try {
      final response = await _dioClient.post(
        '/v1/tenants/$tenantId/profiles',
        data: request.toJson(),
      );
      return UserProfile.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Create a complete user (identity + profile)
  Future<UserProfile> createUser({
    required String tenantId,
    required String email,
    required String password,
    required String displayName,
    String? firstName,
    String? lastName,
    required String userType,
  }) async {
    // First create identity
    final identity = await createUserIdentity(
      email: email,
      password: password,
      tenantId: tenantId,
    );

    // Then create profile
    final profileRequest = CreateUserProfileRequest(
      userId: identity.id,
      displayName: displayName,
      firstName: firstName,
      lastName: lastName,
      email: email,
      userType: userType,
    );

    return createUserProfile(tenantId: tenantId, request: profileRequest);
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
          return 'Unauthorized. Please login again.';
        case 403:
          return 'Access denied.';
        case 404:
          return 'Resource not found.';
        case 409:
          return 'Resource already exists.';
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
      return 'Cannot connect to server.';
    }
    return 'Network error. Please check your connection.';
  }
}

final superAdminRepositoryProvider = Provider<SuperAdminRepository>((ref) {
  final dioClient = ref.watch(authDioClientProvider);
  return SuperAdminRepository(dioClient);
});
