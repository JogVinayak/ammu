import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/note_models.dart';
import '../data/notes_repository.dart';

class NotesState {
  final bool isLoading;
  final List<Note> notes;
  final NoteStatus? filterStatus;
  final String? searchQuery;
  final String? error;

  const NotesState({
    this.isLoading = false,
    this.notes = const [],
    this.filterStatus,
    this.searchQuery,
    this.error,
  });

  NotesState copyWith({
    bool? isLoading,
    List<Note>? notes,
    NoteStatus? filterStatus,
    String? searchQuery,
    String? error,
    bool clearFilter = false,
  }) {
    return NotesState(
      isLoading: isLoading ?? this.isLoading,
      notes: notes ?? this.notes,
      filterStatus: clearFilter ? null : (filterStatus ?? this.filterStatus),
      searchQuery: searchQuery ?? this.searchQuery,
      error: error,
    );
  }

  List<Note> get filteredNotes {
    print('DEBUG filteredNotes: filterStatus=$filterStatus, total notes=${notes.length}');
    for (var note in notes) {
      print('DEBUG filteredNotes: Note "${note.title}" has status=${note.status}');
    }
    final result = notes.where((note) {
      if (filterStatus != null && note.status != filterStatus) {
        return false;
      }
      if (searchQuery != null && searchQuery!.isNotEmpty) {
        final query = searchQuery!.toLowerCase();
        return note.title.toLowerCase().contains(query) ||
            (note.summary?.toLowerCase().contains(query) ?? false) ||
            note.tags.any((tag) => tag.toLowerCase().contains(query));
      }
      return true;
    }).toList();
    print('DEBUG filteredNotes: Returning ${result.length} notes');
    return result;
  }
}

class NotesNotifier extends StateNotifier<NotesState> {
  final NotesRepository _repository;
  final String? _userId;

  NotesNotifier(this._repository, this._userId) : super(const NotesState()) {
    if (_userId != null && _userId!.isNotEmpty) {
      loadNotes();
    }
  }

  Future<void> loadNotes() async {
    // Don't load if no user ID - wait for auth
    if (_userId == null || _userId!.isEmpty) {
      print('DEBUG: loadNotes skipped - no userId');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      print('DEBUG: loadNotes with userId: $_userId');
      // Pass createdBy to get all notes by this user (teachers see their own notes)
      final notes = await _repository.getNotes(createdBy: _userId);
      print('DEBUG: loadNotes returned ${notes.length} notes');
      state = state.copyWith(
        isLoading: false,
        notes: notes,
      );
    } catch (e) {
      print('DEBUG: loadNotes error: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void filterByStatus(NoteStatus? status) {
    if (status == null) {
      state = state.copyWith(clearFilter: true);
    } else {
      state = state.copyWith(filterStatus: status);
    }
  }

  void search(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> deleteNote(String noteId) async {
    try {
      await _repository.deleteNote(noteId);
      state = state.copyWith(
        notes: state.notes.where((n) => n.id != noteId).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> markReady(String noteId) async {
    if (_userId == null) throw Exception('User not logged in');
    try {
      await _repository.markReady(noteId, _userId!);
      state = state.copyWith(
        notes: state.notes.map((n) {
          if (n.id == noteId) {
            return n.copyWith(status: NoteStatus.ready);
          }
          return n;
        }).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> releaseNote(String noteId, {List<String>? classIds}) async {
    if (_userId == null) throw Exception('User not logged in');
    try {
      await _repository.releaseNote(noteId, classIds: classIds, releasedBy: _userId);
      state = state.copyWith(
        notes: state.notes.map((n) {
          if (n.id == noteId) {
            return n.copyWith(status: NoteStatus.released);
          }
          return n;
        }).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> refresh() async {
    await loadNotes();
  }
}

final notesProvider = StateNotifierProvider<NotesNotifier, NotesState>((ref) {
  final repository = ref.watch(notesRepositoryProvider);
  final authState = ref.watch(authProvider);
  final userId = authState.user?.id;
  return NotesNotifier(repository, userId);
});

// Provider for single note - fetches from API
final noteDetailProvider =
    FutureProvider.family<Note?, String>((ref, noteId) async {
  final repository = ref.watch(notesRepositoryProvider);
  try {
    return await repository.getNoteById(noteId);
  } catch (e) {
    // Fallback to cached notes if API fails
    final notesState = ref.watch(notesProvider);
    final cachedNote = notesState.notes.where((n) => n.id == noteId).firstOrNull;
    if (cachedNote != null) return cachedNote;
    rethrow;
  }
});
