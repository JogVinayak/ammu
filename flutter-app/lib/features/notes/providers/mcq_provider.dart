import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/mcq_models.dart';
import '../data/notes_repository.dart';

/// Provider that fetches MCQs for a specific note
final mcqsProvider = FutureProvider.family<List<Mcq>, String>(
  (ref, noteId) async {
    final repository = ref.watch(notesRepositoryProvider);
    return repository.getMcqs(noteId);
  },
);

/// State for MCQ editing
class McqsState {
  final List<Mcq> mcqs;
  final bool isLoading;
  final String? error;

  const McqsState({
    this.mcqs = const [],
    this.isLoading = false,
    this.error,
  });

  McqsState copyWith({
    List<Mcq>? mcqs,
    bool? isLoading,
    String? error,
  }) {
    return McqsState(
      mcqs: mcqs ?? this.mcqs,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing MCQs with mutations
class McqsNotifier extends StateNotifier<McqsState> {
  final NotesRepository _repository;
  final String noteId;

  McqsNotifier(this._repository, this.noteId)
      : super(const McqsState(isLoading: true)) {
    loadMcqs();
  }

  Future<void> loadMcqs({String? difficulty}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final mcqs = await _repository.getMcqs(noteId, difficulty: difficulty);
      state = McqsState(mcqs: mcqs);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addMcq(CreateMcqRequest request) async {
    try {
      final mcq = await _repository.createMcq(noteId, request);
      state = state.copyWith(
        mcqs: [...state.mcqs, mcq],
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> updateMcq(
    String mcqId,
    UpdateMcqRequest request,
  ) async {
    try {
      final updated = await _repository.updateMcq(
        noteId,
        mcqId,
        request,
      );
      state = state.copyWith(
        mcqs: state.mcqs.map((m) => m.id == mcqId ? updated : m).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteMcq(String mcqId) async {
    try {
      await _repository.deleteMcq(noteId, mcqId);
      state = state.copyWith(
        mcqs: state.mcqs.where((m) => m.id != mcqId).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> batchSave(List<McqItem> items, {bool replaceAll = true}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final request = BatchMcqsRequest(
        mcqs: items,
        replaceAll: replaceAll,
      );
      final mcqs = await _repository.batchUpsertMcqs(noteId, request);
      state = McqsState(mcqs: mcqs);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for McqsNotifier - used for editing MCQs
final mcqsNotifierProvider =
    StateNotifierProvider.family<McqsNotifier, McqsState, String>(
  (ref, noteId) {
    final repository = ref.watch(notesRepositoryProvider);
    return McqsNotifier(repository, noteId);
  },
);
