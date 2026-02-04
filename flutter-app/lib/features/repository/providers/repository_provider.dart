import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repository_models.dart';
import '../data/repository_api.dart';

class RepositoryState {
  final bool isLoading;
  final List<RepositoryItem> items;
  final RepositoryFilter filter;
  final String? error;
  final int page;
  final int totalPages;
  final bool hasMore;

  const RepositoryState({
    this.isLoading = false,
    this.items = const [],
    this.filter = const RepositoryFilter(),
    this.error,
    this.page = 0,
    this.totalPages = 1,
    this.hasMore = true,
  });

  RepositoryState copyWith({
    bool? isLoading,
    List<RepositoryItem>? items,
    RepositoryFilter? filter,
    String? error,
    int? page,
    int? totalPages,
    bool? hasMore,
  }) {
    return RepositoryState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      filter: filter ?? this.filter,
      error: error,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class RepositoryNotifier extends StateNotifier<RepositoryState> {
  final RepositoryApi _api;

  RepositoryNotifier(this._api) : super(const RepositoryState()) {
    loadItems();
  }

  Future<void> loadItems({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(page: 0, items: [], hasMore: true);
    }

    if (!state.hasMore && !refresh) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final items = await _api.getPublishedContent(
        type: state.filter.type,
        searchQuery: state.filter.searchQuery,
        page: state.page,
      );

      state = state.copyWith(
        isLoading: false,
        items: refresh ? items : [...state.items, ...items],
        page: state.page + 1,
        hasMore: items.length >= 20,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void updateFilter(RepositoryFilter filter) {
    state = state.copyWith(filter: filter);
    loadItems(refresh: true);
  }

  void search(String query) {
    state = state.copyWith(
      filter: state.filter.copyWith(searchQuery: query),
    );
    loadItems(refresh: true);
  }

  void clearFilters() {
    state = state.copyWith(filter: const RepositoryFilter());
    loadItems(refresh: true);
  }

  Future<void> refresh() async {
    await loadItems(refresh: true);
  }
}

final repositoryProvider =
    StateNotifierProvider<RepositoryNotifier, RepositoryState>((ref) {
  final api = ref.watch(repositoryApiProvider);
  return RepositoryNotifier(api);
});
