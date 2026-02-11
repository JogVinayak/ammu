import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../super_admin/data/super_admin_repository.dart';

class AdminClassesState {
  final List<Map<String, dynamic>> classes;
  final bool isLoading;
  final String? error;

  const AdminClassesState({
    this.classes = const [],
    this.isLoading = false,
    this.error,
  });

  AdminClassesState copyWith({
    List<Map<String, dynamic>>? classes,
    bool? isLoading,
    String? error,
  }) {
    return AdminClassesState(
      classes: classes ?? this.classes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AdminClassesNotifier extends StateNotifier<AdminClassesState> {
  final SuperAdminRepository _repository;
  final String _tenantId;

  AdminClassesNotifier(this._repository, this._tenantId)
      : super(const AdminClassesState());

  Future<void> loadClasses() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final classes = await _repository.getSchoolClasses(_tenantId);
      state = state.copyWith(classes: classes, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createClass({
    required String name,
    required int gradeLevel,
    String? description,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.createSchoolClass(
        tenantId: _tenantId,
        name: name,
        gradeLevel: gradeLevel,
        description: description,
      );
      await loadClasses();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteClass(String classId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.deleteSchoolClass(
        tenantId: _tenantId,
        classId: classId,
      );
      await loadClasses();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> createDivision({
    required String classId,
    required String name,
    String? displayName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.createDivision(
        tenantId: _tenantId,
        classId: classId,
        name: name,
        displayName: displayName,
      );
      await loadClasses();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteDivision({
    required String classId,
    required String divisionId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.deleteDivision(
        tenantId: _tenantId,
        classId: classId,
        divisionId: divisionId,
      );
      await loadClasses();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> assignTeacher({
    required String classId,
    required String teacherId,
    required String role,
    String? subject,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.assignTeacher(
        tenantId: _tenantId,
        classId: classId,
        teacherId: teacherId,
        role: role,
        subject: subject,
      );
      await loadClasses();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> removeTeacherAssignment({
    required String classId,
    required String assignmentId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.removeTeacherAssignment(
        tenantId: _tenantId,
        classId: classId,
        assignmentId: assignmentId,
      );
      await loadClasses();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final adminClassesProvider =
    StateNotifierProvider<AdminClassesNotifier, AdminClassesState>((ref) {
  final repository = ref.watch(superAdminRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  final tenantId = user?.tenantId ?? '';
  return AdminClassesNotifier(repository, tenantId);
});
