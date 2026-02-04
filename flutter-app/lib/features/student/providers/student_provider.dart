import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notes/data/note_models.dart';
import '../data/student_models.dart';
import '../data/student_repository.dart';

// Student Profile State
class StudentProfileState {
  final StudentProfile? profile;
  final bool isLoading;
  final String? error;

  const StudentProfileState({
    this.profile,
    this.isLoading = false,
    this.error,
  });

  StudentProfileState copyWith({
    StudentProfile? profile,
    bool? isLoading,
    String? error,
  }) {
    return StudentProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class StudentProfileNotifier extends StateNotifier<StudentProfileState> {
  final StudentRepository _repository;
  final String? _tenantId;
  final String? _userId;

  StudentProfileNotifier(this._repository, this._tenantId, this._userId)
      : super(const StudentProfileState()) {
    if (_tenantId != null && _userId != null) {
      loadProfile();
    }
  }

  Future<void> loadProfile() async {
    if (_tenantId == null || _userId == null) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final profile = await _repository.getStudentProfile(_tenantId!, _userId!);
      state = state.copyWith(profile: profile, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final studentProfileProvider =
    StateNotifierProvider<StudentProfileNotifier, StudentProfileState>((ref) {
  final repository = ref.watch(studentRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  return StudentProfileNotifier(repository, user?.tenantId, user?.id);
});

// Student Notes State
class StudentNotesState {
  final List<Note> notes;
  final bool isLoading;
  final String? error;
  final String searchQuery;

  const StudentNotesState({
    this.notes = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
  });

  StudentNotesState copyWith({
    List<Note>? notes,
    bool? isLoading,
    String? error,
    String? searchQuery,
  }) {
    return StudentNotesState(
      notes: notes ?? this.notes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  List<Note> get filteredNotes {
    if (searchQuery.isEmpty) return notes;
    final query = searchQuery.toLowerCase();
    return notes.where((note) {
      return note.title.toLowerCase().contains(query) ||
          (note.summary?.toLowerCase().contains(query) ?? false);
    }).toList();
  }
}

class StudentNotesNotifier extends StateNotifier<StudentNotesState> {
  final StudentRepository _repository;
  final String? _classId;

  StudentNotesNotifier(this._repository, this._classId)
      : super(const StudentNotesState()) {
    if (_classId != null) {
      loadNotes();
    }
  }

  Future<void> loadNotes() async {
    if (_classId == null) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final notes = await _repository.getReleasedNotes(_classId!);
      state = state.copyWith(notes: notes, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void search(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void clearSearch() {
    state = state.copyWith(searchQuery: '');
  }
}

// We need classId from student profile, so this depends on studentProfileProvider
final studentNotesProvider =
    StateNotifierProvider<StudentNotesNotifier, StudentNotesState>((ref) {
  final repository = ref.watch(studentRepositoryProvider);
  final profileState = ref.watch(studentProfileProvider);
  final classId = profileState.profile?.classId;
  return StudentNotesNotifier(repository, classId);
});

// Dashboard Stats Provider
final studentDashboardStatsProvider = FutureProvider<StudentDashboardStats>((ref) async {
  final profileState = ref.watch(studentProfileProvider);
  final notesState = ref.watch(studentNotesProvider);

  final profile = profileState.profile;

  return StudentDashboardStats(
    notesCount: notesState.notes.length,
    mindmapsCount: 0, // TODO: Add mindmaps count
    className: profile?.className,
    grade: profile?.grade,
    section: profile?.section,
  );
});

// Recent Content Provider (for dashboard)
final studentRecentContentProvider = Provider<List<Note>>((ref) {
  final notesState = ref.watch(studentNotesProvider);
  final notes = List<Note>.from(notesState.notes);

  // Sort by updatedAt descending and take top 5
  notes.sort((a, b) => (b.updatedAt ?? DateTime.now())
      .compareTo(a.updatedAt ?? DateTime.now()));

  return notes.take(5).toList();
});
