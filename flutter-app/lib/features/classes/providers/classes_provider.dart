import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/class_models.dart';
import '../data/classes_repository.dart';

class ClassesState {
  final bool isLoading;
  final List<TeacherClass> classes;
  final String? error;

  const ClassesState({
    this.isLoading = false,
    this.classes = const [],
    this.error,
  });

  ClassesState copyWith({
    bool? isLoading,
    List<TeacherClass>? classes,
    String? error,
  }) {
    return ClassesState(
      isLoading: isLoading ?? this.isLoading,
      classes: classes ?? this.classes,
      error: error,
    );
  }
}

class ClassesNotifier extends StateNotifier<ClassesState> {
  final ClassesRepository _repository;

  ClassesNotifier(this._repository) : super(const ClassesState()) {
    loadClasses();
  }

  Future<void> loadClasses() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final classes = await _repository.getClasses();
      state = state.copyWith(
        isLoading: false,
        classes: classes,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    await loadClasses();
  }
}

final classesProvider =
    StateNotifierProvider<ClassesNotifier, ClassesState>((ref) {
  final repository = ref.watch(classesRepositoryProvider);
  return ClassesNotifier(repository);
});

final classDetailProvider =
    FutureProvider.family<TeacherClass?, String>((ref, id) async {
  final repository = ref.watch(classesRepositoryProvider);
  try {
    return await repository.getClassById(id);
  } catch (e) {
    // Fallback to cached classes
    final state = ref.watch(classesProvider);
    final cached = state.classes.where((c) => c.id == id).firstOrNull;
    if (cached != null) return cached;
    rethrow;
  }
});
