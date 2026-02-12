import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/class_models.dart';
import '../data/classes_repository.dart';

class ClassesState {
  final bool isLoading;
  final List<Map<String, dynamic>> classes;
  final List<Map<String, dynamic>> userProfiles;
  final List<Map<String, dynamic>> studentProfiles;
  final String? error;

  const ClassesState({
    this.isLoading = false,
    this.classes = const [],
    this.userProfiles = const [],
    this.studentProfiles = const [],
    this.error,
  });

  ClassesState copyWith({
    bool? isLoading,
    List<Map<String, dynamic>>? classes,
    List<Map<String, dynamic>>? userProfiles,
    List<Map<String, dynamic>>? studentProfiles,
    String? error,
  }) {
    return ClassesState(
      isLoading: isLoading ?? this.isLoading,
      classes: classes ?? this.classes,
      userProfiles: userProfiles ?? this.userProfiles,
      studentProfiles: studentProfiles ?? this.studentProfiles,
      error: error,
    );
  }

  /// Map userId -> student profile (classId, divisionId, grade)
  Map<String, Map<String, dynamic>> get studentProfileMap {
    final map = <String, Map<String, dynamic>>{};
    for (final sp in studentProfiles) {
      final userId = sp['userId']?.toString();
      if (userId != null) map[userId] = sp;
    }
    return map;
  }

  /// Students from userProfiles (those with userType == STUDENT)
  List<Map<String, dynamic>> get students {
    return userProfiles.where((u) => u['userType'] == 'STUDENT').toList();
  }

  /// Get students for a specific division
  List<Map<String, dynamic>> studentsForDivision(String divisionId) {
    final spMap = studentProfileMap;
    return students.where((student) {
      final userId = student['userId']?.toString();
      if (userId == null) return false;
      final sp = spMap[userId];
      return sp != null && sp['divisionId']?.toString() == divisionId;
    }).toList();
  }

  /// Count students in a division
  int studentCountForDivision(String divisionId) {
    return studentsForDivision(divisionId).length;
  }
}

class ClassesNotifier extends StateNotifier<ClassesState> {
  final ClassesRepository _repository;
  final String _tenantId;
  final String _userId;

  ClassesNotifier(this._repository, this._tenantId, this._userId)
      : super(const ClassesState()) {
    if (_tenantId.isNotEmpty && _userId.isNotEmpty) {
      loadClasses();
    }
  }

  Future<void> loadClasses() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait([
        _repository.getTeacherClasses(_tenantId, _userId),
        _repository.getUserProfiles(_tenantId),
        _repository.getStudentProfiles(_tenantId),
      ]);

      state = state.copyWith(
        isLoading: false,
        classes: results[0],
        userProfiles: results[1],
        studentProfiles: results[2],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    await loadClasses();
  }
}

final classesProvider =
    StateNotifierProvider<ClassesNotifier, ClassesState>((ref) {
  final repository = ref.watch(classesRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  final tenantId = user?.tenantId ?? '';
  final userId = user?.id ?? '';
  return ClassesNotifier(repository, tenantId, userId);
});

final classDetailProvider =
    FutureProvider.family<TeacherClass?, String>((ref, id) async {
  final repository = ref.watch(classesRepositoryProvider);
  return repository.getClassById(id);
});
