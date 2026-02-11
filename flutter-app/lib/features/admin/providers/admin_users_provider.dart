import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../super_admin/data/super_admin_models.dart';
import '../../super_admin/data/super_admin_repository.dart';

class AdminUsersState {
  final List<UserProfile> allUsers;
  final List<Map<String, dynamic>> studentProfiles;
  final List<Map<String, dynamic>> schoolClasses;
  final bool isLoading;
  final String? error;

  const AdminUsersState({
    this.allUsers = const [],
    this.studentProfiles = const [],
    this.schoolClasses = const [],
    this.isLoading = false,
    this.error,
  });

  AdminUsersState copyWith({
    List<UserProfile>? allUsers,
    List<Map<String, dynamic>>? studentProfiles,
    List<Map<String, dynamic>>? schoolClasses,
    bool? isLoading,
    String? error,
  }) {
    return AdminUsersState(
      allUsers: allUsers ?? this.allUsers,
      studentProfiles: studentProfiles ?? this.studentProfiles,
      schoolClasses: schoolClasses ?? this.schoolClasses,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  List<UserProfile> get teachers =>
      allUsers.where((u) => u.isTeacher).toList();

  List<UserProfile> get students =>
      allUsers.where((u) => u.isStudent).toList();

  /// Build a map of userId -> student profile (classId, divisionId, grade)
  Map<String, Map<String, dynamic>> get studentProfileMap {
    final map = <String, Map<String, dynamic>>{};
    for (final sp in studentProfiles) {
      final userId = sp['userId']?.toString();
      if (userId != null) map[userId] = sp;
    }
    return map;
  }

  /// Build maps for class/division name lookup
  Map<String, String> get classNameMap {
    final map = <String, String>{};
    for (final cls in schoolClasses) {
      map[cls['id'].toString()] = cls['name']?.toString() ?? '';
    }
    return map;
  }

  Map<String, String> get divisionNameMap {
    final map = <String, String>{};
    for (final cls in schoolClasses) {
      final divs = cls['divisions'];
      if (divs is List) {
        for (final div in divs) {
          if (div is Map) {
            map[div['id'].toString()] =
                div['displayName']?.toString() ?? div['name']?.toString() ?? '';
          }
        }
      }
    }
    return map;
  }

  /// Group students by className + divisionName
  /// Returns a list of (groupLabel, students) pairs, sorted by class name.
  /// Unassigned students go under "Unassigned".
  List<(String, List<UserProfile>)> get groupedStudents {
    final spMap = studentProfileMap;
    final clsNames = classNameMap;
    final divNames = divisionNameMap;
    final groups = <String, List<UserProfile>>{};

    for (final student in students) {
      final sp = spMap[student.userId];
      final classId = sp?['classId']?.toString();
      final divisionId = sp?['divisionId']?.toString();

      String label;
      if (classId != null && clsNames.containsKey(classId)) {
        label = clsNames[classId]!;
        if (divisionId != null && divNames.containsKey(divisionId)) {
          label += ' - ${divNames[divisionId]}';
        }
      } else {
        label = 'Unassigned';
      }

      groups.putIfAbsent(label, () => []);
      groups[label]!.add(student);
    }

    final sorted = groups.entries.toList()
      ..sort((a, b) {
        if (a.key == 'Unassigned') return 1;
        if (b.key == 'Unassigned') return -1;
        return a.key.compareTo(b.key);
      });

    return sorted.map((e) => (e.key, e.value)).toList();
  }
}

class AdminUsersNotifier extends StateNotifier<AdminUsersState> {
  final SuperAdminRepository _repository;
  final String _tenantId;

  AdminUsersNotifier(this._repository, this._tenantId)
      : super(const AdminUsersState());

  Future<void> loadUsers() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Load all three in parallel
      final results = await Future.wait([
        _repository.getUserProfiles(_tenantId),
        _repository.getStudentProfiles(_tenantId),
        _repository.getSchoolClasses(_tenantId),
      ]);

      final users = results[0] as List<UserProfile>;
      final studentProfiles = results[1] as List<Map<String, dynamic>>;
      final classes = results[2] as List<Map<String, dynamic>>;

      final filteredUsers = users
          .where((u) => u.userType != 'ADMIN' && u.userType != 'SUPER_ADMIN')
          .toList();

      state = state.copyWith(
        allUsers: filteredUsers,
        studentProfiles: studentProfiles,
        schoolClasses: classes,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Full onboarding: auth signup handles identity + profile + role assignment.
  /// For students, also assigns classId and divisionId via student-profile upsert.
  Future<bool> createUser({
    required String email,
    required String password,
    required String displayName,
    required String userType,
    String? classId,
    String? divisionId,
    String? grade,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final identity = await _repository.createUserIdentity(
        email: email,
        password: password,
        tenantId: _tenantId,
        name: displayName,
        userType: userType,
      );

      // If student with class/division, upsert student profile
      if (userType == 'STUDENT' && classId != null) {
        await _repository.upsertStudentProfile(
          tenantId: _tenantId,
          userId: identity.id,
          classId: classId,
          divisionId: divisionId,
          grade: grade,
        );
      }

      await loadUsers();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Update user profile (and optionally student profile for class/division)
  Future<bool> updateUser({
    required String profileId,
    required String userId,
    String? displayName,
    String? email,
    bool isStudent = false,
    String? classId,
    String? divisionId,
    String? grade,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.updateUserProfile(
        tenantId: _tenantId,
        profileId: profileId,
        displayName: displayName,
        email: email,
      );

      // Update student class/division if applicable
      if (isStudent) {
        await _repository.upsertStudentProfile(
          tenantId: _tenantId,
          userId: userId,
          classId: classId,
          divisionId: divisionId,
          grade: grade,
        );
      }

      await loadUsers();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Delete user (profile + auth identity)
  Future<bool> deleteUser({
    required String profileId,
    required String userId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.deleteUserProfile(
        tenantId: _tenantId,
        profileId: profileId,
      );
      await _repository.deleteUserIdentity(userId);
      await loadUsers();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Fetch school classes for the tenant (used by the create-user form)
  Future<List<Map<String, dynamic>>> getSchoolClasses() async {
    return _repository.getSchoolClasses(_tenantId);
  }
}

final adminUsersProvider =
    StateNotifierProvider<AdminUsersNotifier, AdminUsersState>((ref) {
  final repository = ref.watch(superAdminRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  final tenantId = user?.tenantId ?? '';
  return AdminUsersNotifier(repository, tenantId);
});
