import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/mindmap_models.dart';
import '../data/mindmaps_repository.dart';

class MindmapsState {
  final bool isLoading;
  final List<Mindmap> mindmaps;
  final String? error;

  const MindmapsState({
    this.isLoading = false,
    this.mindmaps = const [],
    this.error,
  });

  MindmapsState copyWith({
    bool? isLoading,
    List<Mindmap>? mindmaps,
    String? error,
  }) {
    return MindmapsState(
      isLoading: isLoading ?? this.isLoading,
      mindmaps: mindmaps ?? this.mindmaps,
      error: error,
    );
  }
}

class MindmapsNotifier extends StateNotifier<MindmapsState> {
  final MindmapsRepository _repository;

  MindmapsNotifier(this._repository) : super(const MindmapsState()) {
    loadMindmaps();
  }

  Future<void> loadMindmaps() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final mindmaps = await _repository.getMindmaps();
      state = state.copyWith(
        isLoading: false,
        mindmaps: mindmaps,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> deleteMindmap(String id) async {
    try {
      await _repository.deleteMindmap(id);
      state = state.copyWith(
        mindmaps: state.mindmaps.where((m) => m.id != id).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> refresh() async {
    await loadMindmaps();
  }
}

final mindmapsProvider =
    StateNotifierProvider<MindmapsNotifier, MindmapsState>((ref) {
  final repository = ref.watch(mindmapsRepositoryProvider);
  return MindmapsNotifier(repository);
});

final mindmapDetailProvider =
    FutureProvider.family<Mindmap?, String>((ref, id) async {
  final repository = ref.watch(mindmapsRepositoryProvider);
  try {
    return await repository.getMindmapById(id);
  } catch (e) {
    // Fallback to cached mindmaps
    final state = ref.watch(mindmapsProvider);
    final cached = state.mindmaps.where((m) => m.id == id).firstOrNull;
    if (cached != null) return cached;
    rethrow;
  }
});
