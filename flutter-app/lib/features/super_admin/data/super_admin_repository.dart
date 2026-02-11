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
  /// Auth-service signup also creates profile and assigns default role.
  Future<UserIdentity> createUserIdentity({
    required String email,
    required String password,
    required String tenantId,
    String? name,
    String? userType,
  }) async {
    try {
      final response = await _dioClient.post(
        '/v1/auth/signup',
        data: {
          'email': email,
          'password': password,
          'tenantId': tenantId,
          if (name != null) 'name': name,
          if (userType != null) 'userType': userType,
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

  /// Upsert student profile (set classId, divisionId, grade, etc.)
  Future<void> upsertStudentProfile({
    required String tenantId,
    required String userId,
    String? classId,
    String? divisionId,
    String? grade,
  }) async {
    try {
      await _dioClient.put(
        '/v1/tenants/$tenantId/users/$userId/student-profile',
        data: {
          if (classId != null) 'classId': classId,
          if (divisionId != null) 'divisionId': divisionId,
          if (grade != null) 'grade': grade,
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Update a user profile
  Future<void> updateUserProfile({
    required String tenantId,
    required String profileId,
    String? displayName,
    String? email,
  }) async {
    try {
      await _dioClient.put(
        '/v1/tenants/$tenantId/profiles/$profileId',
        data: {
          if (displayName != null) 'displayName': displayName,
          if (email != null) 'email': email,
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Delete a user profile (also deletes associated student profile)
  Future<void> deleteUserProfile({
    required String tenantId,
    required String profileId,
  }) async {
    try {
      await _dioClient.delete('/v1/tenants/$tenantId/profiles/$profileId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Delete user identity from auth service
  Future<void> deleteUserIdentity(String userId) async {
    try {
      await _dioClient.delete('/v1/auth/users/$userId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============== School Classes & Divisions ==============

  /// Fetch student profiles (with classId/divisionId) for a tenant
  Future<List<Map<String, dynamic>>> getStudentProfiles(String tenantId) async {
    try {
      final response =
          await _dioClient.get('/v1/tenants/$tenantId/profiles/student-summaries');
      final List<dynamic> data = response.data;
      return data.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Fetch school classes (with embedded divisions) for a tenant
  Future<List<Map<String, dynamic>>> getSchoolClasses(String tenantId) async {
    try {
      final response = await _dioClient.get('/v1/tenants/$tenantId/classes');
      final List<dynamic> data = response.data;
      return data.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Create a school class
  Future<Map<String, dynamic>> createSchoolClass({
    required String tenantId,
    required String name,
    required int gradeLevel,
    String? description,
  }) async {
    try {
      final response = await _dioClient.post(
        '/v1/tenants/$tenantId/classes',
        data: {
          'name': name,
          'gradeLevel': gradeLevel,
          if (description != null) 'description': description,
        },
      );
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Delete a school class
  Future<void> deleteSchoolClass({
    required String tenantId,
    required String classId,
  }) async {
    try {
      await _dioClient.delete('/v1/tenants/$tenantId/classes/$classId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Create a division within a class
  Future<Map<String, dynamic>> createDivision({
    required String tenantId,
    required String classId,
    required String name,
    String? displayName,
  }) async {
    try {
      final response = await _dioClient.post(
        '/v1/tenants/$tenantId/classes/$classId/divisions',
        data: {
          'name': name,
          if (displayName != null) 'displayName': displayName,
        },
      );
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Delete a division
  Future<void> deleteDivision({
    required String tenantId,
    required String classId,
    required String divisionId,
  }) async {
    try {
      await _dioClient
          .delete('/v1/tenants/$tenantId/classes/$classId/divisions/$divisionId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============== Teacher-Class Assignments ==============

  /// List teachers assigned to a class
  Future<List<Map<String, dynamic>>> getClassTeachers({
    required String tenantId,
    required String classId,
  }) async {
    try {
      final response = await _dioClient
          .get('/v1/tenants/$tenantId/classes/$classId/teachers');
      final List<dynamic> data = response.data;
      return data.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Assign a teacher to a class
  Future<Map<String, dynamic>> assignTeacher({
    required String tenantId,
    required String classId,
    required String teacherId,
    required String role,
    String? subject,
  }) async {
    try {
      final response = await _dioClient.post(
        '/v1/tenants/$tenantId/classes/$classId/teachers',
        data: {
          'teacherId': teacherId,
          'role': role,
          if (subject != null) 'subject': subject,
        },
      );
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Remove a teacher assignment from a class
  Future<void> removeTeacherAssignment({
    required String tenantId,
    required String classId,
    required String assignmentId,
  }) async {
    try {
      await _dioClient.delete(
        '/v1/tenants/$tenantId/classes/$classId/teachers/$assignmentId',
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Create a complete user (identity + profile + role).
  /// Auth-service signup now handles profile creation and role assignment.
  Future<UserIdentity> createUser({
    required String tenantId,
    required String email,
    required String password,
    required String displayName,
    String? firstName,
    String? lastName,
    required String userType,
  }) async {
    return createUserIdentity(
      email: email,
      password: password,
      tenantId: tenantId,
      name: displayName,
      userType: userType,
    );
  }

  // ============== Roles (tenant-scoped) ==============

  Future<List<Role>> getRoles(String tenantId) async {
    try {
      final response = await _dioClient.get('/v1/tenants/$tenantId/roles');
      final List<dynamic> data = response.data;
      return data.map((json) => Role.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Role> createRole(
    String tenantId, {
    required String name,
    String? description,
  }) async {
    try {
      final response = await _dioClient.post(
        '/v1/tenants/$tenantId/roles',
        data: {
          'name': name,
          if (description != null) 'description': description,
          'active': true,
        },
      );
      return Role.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Role> updateRole(
    String tenantId,
    int roleId, {
    String? name,
    String? description,
    bool? active,
  }) async {
    try {
      final response = await _dioClient.put(
        '/v1/tenants/$tenantId/roles/$roleId',
        data: {
          'id': roleId,
          if (name != null) 'name': name,
          if (description != null) 'description': description,
          if (active != null) 'active': active,
        },
      );
      return Role.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteRole(String tenantId, int roleId) async {
    try {
      await _dioClient.delete('/v1/tenants/$tenantId/roles/$roleId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============== Role Permission Grants ==============

  Future<List<RolePermissionGrant>> getRoleGrants(
    String tenantId,
    int roleId,
  ) async {
    try {
      final response = await _dioClient.get(
        '/v1/tenants/$tenantId/roles/$roleId/grants',
      );
      final List<dynamic> data = response.data;
      return data.map((json) => RolePermissionGrant.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<RolePermissionGrant> createRoleGrant(
    String tenantId,
    int roleId, {
    required String permissionCode,
    String? scopeCode,
  }) async {
    try {
      final response = await _dioClient.post(
        '/v1/tenants/$tenantId/roles/$roleId/grants',
        data: {
          'permissionCode': permissionCode,
          if (scopeCode != null) 'scopeCode': scopeCode,
        },
      );
      return RolePermissionGrant.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteRoleGrant(
    String tenantId,
    int roleId,
    int grantId,
  ) async {
    try {
      await _dioClient.delete(
        '/v1/tenants/$tenantId/roles/$roleId/grants/$grantId',
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============== Permissions (global) ==============

  Future<List<Permission>> getPermissions() async {
    try {
      final response = await _dioClient.get('/v1/permissions');
      final List<dynamic> data = response.data;
      return data.map((json) => Permission.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Permission> createPermission({
    required String name,
    required String code,
    String? resource,
    String? action,
    String? description,
  }) async {
    try {
      final response = await _dioClient.post(
        '/v1/permissions',
        data: {
          'name': name,
          'code': code,
          if (resource != null) 'resource': resource,
          if (action != null) 'action': action,
          if (description != null) 'description': description,
          'active': true,
        },
      );
      return Permission.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Permission> updatePermission(
    int permissionId, {
    String? name,
    String? description,
    String? resource,
    String? action,
    bool? active,
  }) async {
    try {
      final response = await _dioClient.put(
        '/v1/permissions/$permissionId',
        data: {
          'id': permissionId,
          if (name != null) 'name': name,
          if (description != null) 'description': description,
          if (resource != null) 'resource': resource,
          if (action != null) 'action': action,
          if (active != null) 'active': active,
        },
      );
      return Permission.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deletePermission(int permissionId) async {
    try {
      await _dioClient.delete('/v1/permissions/$permissionId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
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
