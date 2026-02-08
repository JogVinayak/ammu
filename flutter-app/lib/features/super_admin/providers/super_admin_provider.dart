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

// Convenience providers
final teachersProvider = Provider<List<UserProfile>>((ref) {
  return ref.watch(usersProvider).teachers;
});

final studentsProvider = Provider<List<UserProfile>>((ref) {
  return ref.watch(usersProvider).students;
});
