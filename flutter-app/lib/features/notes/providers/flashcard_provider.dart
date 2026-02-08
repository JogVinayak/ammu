import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/flashcard_models.dart';
import '../data/notes_repository.dart';

/// Parameters for fetching flashcards with optional difficulty filter
class FlashcardsParams {
  final String noteId;
  final String? difficulty;

  const FlashcardsParams({required this.noteId, this.difficulty});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlashcardsParams &&
          runtimeType == other.runtimeType &&
          noteId == other.noteId &&
          difficulty == other.difficulty;

  @override
  int get hashCode => noteId.hashCode ^ difficulty.hashCode;
}

/// Provider that fetches flashcards for a specific note (all difficulties)
final flashcardsProvider = FutureProvider.family<List<Flashcard>, String>(
  (ref, noteId) async {
    final repository = ref.watch(notesRepositoryProvider);
    return repository.getFlashcards(noteId);
  },
);

/// Provider that fetches flashcards with optional difficulty filter
final flashcardsByDifficultyProvider = FutureProvider.family<List<Flashcard>, FlashcardsParams>(
  (ref, params) async {
    final repository = ref.watch(notesRepositoryProvider);
    return repository.getFlashcards(params.noteId, difficulty: params.difficulty);
  },
);

/// State for flashcard editing
class FlashcardsState {
  final List<Flashcard> flashcards;
  final bool isLoading;
  final String? error;

  const FlashcardsState({
    this.flashcards = const [],
    this.isLoading = false,
    this.error,
  });

  FlashcardsState copyWith({
    List<Flashcard>? flashcards,
    bool? isLoading,
    String? error,
  }) {
    return FlashcardsState(
      flashcards: flashcards ?? this.flashcards,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing flashcards with mutations
class FlashcardsNotifier extends StateNotifier<FlashcardsState> {
  final NotesRepository _repository;
  final String noteId;

  FlashcardsNotifier(this._repository, this.noteId)
      : super(const FlashcardsState(isLoading: true)) {
    loadFlashcards();
  }

  Future<void> loadFlashcards({String? difficulty}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final flashcards = await _repository.getFlashcards(noteId, difficulty: difficulty);
      state = FlashcardsState(flashcards: flashcards);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addFlashcard(CreateFlashcardRequest request) async {
    try {
      final flashcard = await _repository.createFlashcard(noteId, request);
      state = state.copyWith(
        flashcards: [...state.flashcards, flashcard],
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> updateFlashcard(
    String flashcardId,
    UpdateFlashcardRequest request,
  ) async {
    try {
      final updated = await _repository.updateFlashcard(
        noteId,
        flashcardId,
        request,
      );
      state = state.copyWith(
        flashcards: state.flashcards
            .map((f) => f.id == flashcardId ? updated : f)
            .toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteFlashcard(String flashcardId) async {
    try {
      await _repository.deleteFlashcard(noteId, flashcardId);
      state = state.copyWith(
        flashcards: state.flashcards.where((f) => f.id != flashcardId).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> batchSave(List<FlashcardItem> items, {bool replaceAll = true}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final request = BatchFlashcardsRequest(
        flashcards: items,
        replaceAll: replaceAll,
      );
      final flashcards = await _repository.batchUpsertFlashcards(noteId, request);
      state = FlashcardsState(flashcards: flashcards);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for FlashcardsNotifier - used for editing flashcards
final flashcardsNotifierProvider = StateNotifierProvider.family<
    FlashcardsNotifier, FlashcardsState, String>(
  (ref, noteId) {
    final repository = ref.watch(notesRepositoryProvider);
    return FlashcardsNotifier(repository, noteId);
  },
);
