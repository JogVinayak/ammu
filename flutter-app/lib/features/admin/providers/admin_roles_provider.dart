import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../super_admin/data/super_admin_models.dart';
import '../../super_admin/data/super_admin_repository.dart';

class AdminRolesState {
  final List<Role> roles;
  final Role? selectedRole;
  final List<RolePermissionGrant> grants;
  final List<Permission> allPermissions;
  final bool isLoading;
  final bool isLoadingGrants;
  final String? error;

  const AdminRolesState({
    this.roles = const [],
    this.selectedRole,
    this.grants = const [],
    this.allPermissions = const [],
    this.isLoading = false,
    this.isLoadingGrants = false,
    this.error,
  });

  AdminRolesState copyWith({
    List<Role>? roles,
    Role? selectedRole,
    bool clearSelectedRole = false,
    List<RolePermissionGrant>? grants,
    List<Permission>? allPermissions,
    bool? isLoading,
    bool? isLoadingGrants,
    String? error,
  }) {
    return AdminRolesState(
      roles: roles ?? this.roles,
      selectedRole: clearSelectedRole ? null : (selectedRole ?? this.selectedRole),
      grants: grants ?? this.grants,
      allPermissions: allPermissions ?? this.allPermissions,
      isLoading: isLoading ?? this.isLoading,
      isLoadingGrants: isLoadingGrants ?? this.isLoadingGrants,
      error: error,
    );
  }

  /// Returns the set of permission codes that are granted to the selected role
  Set<String> get grantedPermissionCodes =>
      grants.map((g) => g.permissionCode).toSet();
}

class AdminRolesNotifier extends StateNotifier<AdminRolesState> {
  final SuperAdminRepository _repository;
  final String _tenantId;

  AdminRolesNotifier(this._repository, this._tenantId)
      : super(const AdminRolesState());

  Future<void> loadRoles() async {
    if (_tenantId.isEmpty) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final roles = await _repository.getRoles(_tenantId);
      state = state.copyWith(roles: roles, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createRole(String name, String? description) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.createRole(_tenantId, name: name, description: description);
      await loadRoles();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateRole(int roleId, {String? name, String? description, bool? active}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.updateRole(_tenantId, roleId,
          name: name, description: description, active: active);
      await loadRoles();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteRole(int roleId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.deleteRole(_tenantId, roleId);
      // Clear selection if the deleted role was selected
      if (state.selectedRole?.id == roleId) {
        state = state.copyWith(clearSelectedRole: true, grants: []);
      }
      await loadRoles();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Loads grants for a role and all global permissions (for checkbox UI)
  Future<void> selectRole(Role role) async {
    state = state.copyWith(
      selectedRole: role,
      isLoadingGrants: true,
      error: null,
    );
    try {
      final results = await Future.wait([
        _repository.getRoleGrants(_tenantId, role.id),
        _repository.getPermissions(),
      ]);
      final grants = results[0] as List<RolePermissionGrant>;
      final permissions = results[1] as List<Permission>;
      state = state.copyWith(
        grants: grants,
        allPermissions: permissions,
        isLoadingGrants: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingGrants: false, error: e.toString());
    }
  }

  Future<bool> addGrant(int roleId, String permissionCode) async {
    try {
      await _repository.createRoleGrant(
        _tenantId,
        roleId,
        permissionCode: permissionCode,
      );
      // Reload grants
      final grants = await _repository.getRoleGrants(_tenantId, roleId);
      state = state.copyWith(grants: grants);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> removeGrant(int roleId, int grantId) async {
    try {
      await _repository.deleteRoleGrant(_tenantId, roleId, grantId);
      final grants = await _repository.getRoleGrants(_tenantId, roleId);
      state = state.copyWith(grants: grants);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  void clearSelection() {
    state = state.copyWith(clearSelectedRole: true, grants: []);
  }
}

final adminRolesProvider =
    StateNotifierProvider<AdminRolesNotifier, AdminRolesState>((ref) {
  final repository = ref.watch(superAdminRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  final tenantId = user?.tenantId ?? '';
  return AdminRolesNotifier(repository, tenantId);
});
