import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/super_admin_models.dart';
import '../data/super_admin_repository.dart';

// ============== Schools State ==============

class SchoolsState {
  final List<School> schools;
  final bool isLoading;
  final String? error;

  const SchoolsState({
    this.schools = const [],
    this.isLoading = false,
    this.error,
  });

  SchoolsState copyWith({
    List<School>? schools,
    bool? isLoading,
    String? error,
  }) {
    return SchoolsState(
      schools: schools ?? this.schools,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SchoolsNotifier extends StateNotifier<SchoolsState> {
  final SuperAdminRepository _repository;

  SchoolsNotifier(this._repository) : super(const SchoolsState());

  Future<void> loadSchools() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      print('DEBUG loadSchools: Starting to load schools');
      final schools = await _repository.getSchools();
      print('DEBUG loadSchools: Received ${schools.length} schools from repository');
      // Filter out system tenant
      final filteredSchools = schools
          .where((s) => s.id != '00000000-0000-0000-0000-000000000001')
          .toList();
      print('DEBUG loadSchools: After filtering system tenant: ${filteredSchools.length} schools');
      state = state.copyWith(schools: filteredSchools, isLoading: false);
    } catch (e) {
      print('DEBUG loadSchools: Error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createSchool(String name, String tenantKey) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final request = CreateSchoolRequest(name: name, tenantKey: tenantKey);
      await _repository.createSchool(request);
      await loadSchools();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> suspendSchool(String schoolId) async {
    try {
      await _repository.suspendSchool(schoolId);
      await loadSchools();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> activateSchool(String schoolId) async {
    try {
      await _repository.activateSchool(schoolId);
      await loadSchools();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteSchool(String schoolId) async {
    try {
      await _repository.deleteSchool(schoolId);
      await loadSchools();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final schoolsProvider = StateNotifierProvider<SchoolsNotifier, SchoolsState>((ref) {
  final repository = ref.watch(superAdminRepositoryProvider);
  return SchoolsNotifier(repository);
});

// ============== Users State ==============

class UsersState {
  final List<UserProfile> allUsers;
  final bool isLoading;
  final String? error;
  final String? selectedSchoolId;

  const UsersState({
    this.allUsers = const [],
    this.isLoading = false,
    this.error,
    this.selectedSchoolId,
  });

  UsersState copyWith({
    List<UserProfile>? allUsers,
    bool? isLoading,
    String? error,
    String? selectedSchoolId,
    bool clearSelectedSchool = false,
  }) {
    return UsersState(
      allUsers: allUsers ?? this.allUsers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedSchoolId: clearSelectedSchool ? null : (selectedSchoolId ?? this.selectedSchoolId),
    );
  }

  List<UserProfile> get teachers =>
      filteredUsers.where((u) => u.isTeacher).toList();

  List<UserProfile> get students =>
      filteredUsers.where((u) => u.isStudent).toList();

  List<UserProfile> get filteredUsers {
    if (selectedSchoolId == null) return allUsers;
    return allUsers.where((u) => u.tenantId == selectedSchoolId).toList();
  }
}

class UsersNotifier extends StateNotifier<UsersState> {
  final SuperAdminRepository _repository;

  UsersNotifier(this._repository) : super(const UsersState());

  Future<void> loadUsers() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      print('DEBUG loadUsers: Starting to load users');
      final users = await _repository.getAllUsers();
      print('DEBUG loadUsers: Received ${users.length} users from repository');
      // Filter out super admins
      final filteredUsers = users
          .where((u) => u.userType != 'SUPER_ADMIN')
          .toList();
      print('DEBUG loadUsers: After filtering super admins: ${filteredUsers.length} users');
      print('DEBUG loadUsers: Teachers: ${filteredUsers.where((u) => u.isTeacher).length}');
      print('DEBUG loadUsers: Students: ${filteredUsers.where((u) => u.isStudent).length}');
      state = state.copyWith(allUsers: filteredUsers, isLoading: false);
    } catch (e) {
      print('DEBUG loadUsers: Error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setSelectedSchool(String? schoolId) {
    if (schoolId == null) {
      state = state.copyWith(clearSelectedSchool: true);
    } else {
      state = state.copyWith(selectedSchoolId: schoolId);
    }
  }

  Future<bool> createUser({
    required String tenantId,
    required String email,
    required String password,
    required String displayName,
    String? firstName,
    String? lastName,
    required String userType,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.createUser(
        tenantId: tenantId,
        email: email,
        password: password,
        displayName: displayName,
        firstName: firstName,
        lastName: lastName,
        userType: userType,
      );
      await loadUsers();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final usersProvider = StateNotifierProvider<UsersNotifier, UsersState>((ref) {
  final repository = ref.watch(superAdminRepositoryProvider);
  return UsersNotifier(repository);
});

// ============== Permissions State (global, super admin only) ==============

class PermissionsState {
  final List<Permission> permissions;
  final bool isLoading;
  final String? error;

  const PermissionsState({
    this.permissions = const [],
    this.isLoading = false,
    this.error,
  });

  PermissionsState copyWith({
    List<Permission>? permissions,
    bool? isLoading,
    String? error,
  }) {
    return PermissionsState(
      permissions: permissions ?? this.permissions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class PermissionsNotifier extends StateNotifier<PermissionsState> {
  final SuperAdminRepository _repository;

  PermissionsNotifier(this._repository) : super(const PermissionsState());

  Future<void> loadPermissions() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final permissions = await _repository.getPermissions();
      state = state.copyWith(permissions: permissions, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createPermission({
    required String name,
    required String code,
    String? resource,
    String? action,
    String? description,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.createPermission(
        name: name,
        code: code,
        resource: resource,
        action: action,
        description: description,
      );
      await loadPermissions();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updatePermission(
    int permissionId, {
    String? name,
    String? description,
    String? resource,
    String? action,
    bool? active,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.updatePermission(
        permissionId,
        name: name,
        description: description,
        resource: resource,
        action: action,
        active: active,
      );
      await loadPermissions();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deletePermission(int permissionId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.deletePermission(permissionId);
      await loadPermissions();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final permissionsProvider =
    StateNotifierProvider<PermissionsNotifier, PermissionsState>((ref) {
  final repository = ref.watch(superAdminRepositoryProvider);
  return PermissionsNotifier(repository);
});

// ============== Roles State (super admin, all tenants) ==============

/// Roles for a single school
class SchoolRoles {
  final School school;
  final List<Role> roles;
  final bool isLoading;
  final String? error;

  const SchoolRoles({
    required this.school,
    this.roles = const [],
    this.isLoading = false,
    this.error,
  });
}

class SuperAdminRolesState {
  final List<SchoolRoles> schoolRoles;
  final bool isLoading;
  final String? error;
  // For the permission grants panel
  final Role? selectedRole;
  final String? selectedTenantId;
  final List<RolePermissionGrant> grants;
  final List<Permission> allPermissions;
  final bool isLoadingGrants;

  const SuperAdminRolesState({
    this.schoolRoles = const [],
    this.isLoading = false,
    this.error,
    this.selectedRole,
    this.selectedTenantId,
    this.grants = const [],
    this.allPermissions = const [],
    this.isLoadingGrants = false,
  });

  SuperAdminRolesState copyWith({
    List<SchoolRoles>? schoolRoles,
    bool? isLoading,
    String? error,
    Role? selectedRole,
    String? selectedTenantId,
    bool clearSelection = false,
    List<RolePermissionGrant>? grants,
    List<Permission>? allPermissions,
    bool? isLoadingGrants,
  }) {
    return SuperAdminRolesState(
      schoolRoles: schoolRoles ?? this.schoolRoles,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedRole:
          clearSelection ? null : (selectedRole ?? this.selectedRole),
      selectedTenantId:
          clearSelection ? null : (selectedTenantId ?? this.selectedTenantId),
      grants: clearSelection ? const [] : (grants ?? this.grants),
      allPermissions: allPermissions ?? this.allPermissions,
      isLoadingGrants: isLoadingGrants ?? this.isLoadingGrants,
    );
  }
}

class SuperAdminRolesNotifier extends StateNotifier<SuperAdminRolesState> {
  final SuperAdminRepository _repository;

  SuperAdminRolesNotifier(this._repository)
      : super(const SuperAdminRolesState());

  Future<void> loadAllRoles() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final schools = await _repository.getSchools();
      final filtered = schools
          .where((s) => s.id != '00000000-0000-0000-0000-000000000001')
          .toList();

      final List<SchoolRoles> results = [];
      for (final school in filtered) {
        try {
          final roles = await _repository.getRoles(school.id);
          results.add(SchoolRoles(school: school, roles: roles));
        } catch (e) {
          results.add(
              SchoolRoles(school: school, error: e.toString()));
        }
      }
      state = state.copyWith(schoolRoles: results, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createRole(
      String tenantId, String name, String? description) async {
    try {
      await _repository.createRole(tenantId,
          name: name, description: description);
      await loadAllRoles();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updateRole(String tenantId, int roleId,
      {String? name, String? description, bool? active}) async {
    try {
      await _repository.updateRole(tenantId, roleId,
          name: name, description: description, active: active);
      await loadAllRoles();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteRole(String tenantId, int roleId) async {
    try {
      await _repository.deleteRole(tenantId, roleId);
      if (state.selectedRole?.id == roleId) {
        state = state.copyWith(clearSelection: true);
      }
      await loadAllRoles();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<void> selectRole(String tenantId, Role role) async {
    state = state.copyWith(
      selectedRole: role,
      selectedTenantId: tenantId,
      isLoadingGrants: true,
      error: null,
    );
    try {
      final results = await Future.wait([
        _repository.getRoleGrants(tenantId, role.id),
        _repository.getPermissions(),
      ]);
      state = state.copyWith(
        grants: results[0] as List<RolePermissionGrant>,
        allPermissions: results[1] as List<Permission>,
        isLoadingGrants: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingGrants: false, error: e.toString());
    }
  }

  Future<bool> addGrant(
      String tenantId, int roleId, String permissionCode) async {
    try {
      await _repository.createRoleGrant(tenantId, roleId,
          permissionCode: permissionCode);
      final grants = await _repository.getRoleGrants(tenantId, roleId);
      state = state.copyWith(grants: grants);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> removeGrant(
      String tenantId, int roleId, int grantId) async {
    try {
      await _repository.deleteRoleGrant(tenantId, roleId, grantId);
      final grants = await _repository.getRoleGrants(tenantId, roleId);
      state = state.copyWith(grants: grants);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  void clearSelection() {
    state = state.copyWith(clearSelection: true);
  }
}

final superAdminRolesProvider =
    StateNotifierProvider<SuperAdminRolesNotifier, SuperAdminRolesState>((ref) {
  final repository = ref.watch(superAdminRepositoryProvider);
  return SuperAdminRolesNotifier(repository);
});

// Convenience providers
final teachersProvider = Provider<List<UserProfile>>((ref) {
  return ref.watch(usersProvider).teachers;
});

final studentsProvider = Provider<List<UserProfile>>((ref) {
  return ref.watch(usersProvider).students;
});
