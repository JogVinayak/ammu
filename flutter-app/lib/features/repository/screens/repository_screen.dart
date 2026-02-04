import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/repository_models.dart';
import '../providers/repository_provider.dart';

class RepositoryScreen extends ConsumerStatefulWidget {
  const RepositoryScreen({super.key});

  @override
  ConsumerState<RepositoryScreen> createState() => _RepositoryScreenState();
}

class _RepositoryScreenState extends ConsumerState<RepositoryScreen> {
  final _searchController = TextEditingController();
  String _selectedType = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(repositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Repository'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search notes and mindmaps...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(repositoryProvider.notifier).search('');
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    ref.read(repositoryProvider.notifier).search(value);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        isSelected: _selectedType == 'all',
                        onTap: () {
                          setState(() => _selectedType = 'all');
                          ref.read(repositoryProvider.notifier).updateFilter(
                                state.filter.copyWith(type: null),
                              );
                        },
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _FilterChip(
                        label: 'Notes',
                        isSelected: _selectedType == 'note',
                        onTap: () {
                          setState(() => _selectedType = 'note');
                          ref.read(repositoryProvider.notifier).updateFilter(
                                state.filter.copyWith(type: 'note'),
                              );
                        },
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _FilterChip(
                        label: 'Mindmaps',
                        isSelected: _selectedType == 'mindmap',
                        onTap: () {
                          setState(() => _selectedType = 'mindmap');
                          ref.read(repositoryProvider.notifier).updateFilter(
                                state.filter.copyWith(type: 'mindmap'),
                              );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: state.isLoading && state.items.isEmpty
                ? const LoadingIndicator(message: 'Loading content...')
                : state.error != null
                    ? AppErrorWidget(
                        message: state.error!,
                        onRetry: () =>
                            ref.read(repositoryProvider.notifier).refresh(),
                      )
                    : state.items.isEmpty
                        ? EmptyState(
                            icon: Icons.folder_open,
                            title: 'No content found',
                            subtitle: state.filter.hasFilters
                                ? 'Try adjusting your filters'
                                : 'Published content will appear here',
                            actionText: state.filter.hasFilters
                                ? 'Clear Filters'
                                : null,
                            onAction: state.filter.hasFilters
                                ? () => ref
                                    .read(repositoryProvider.notifier)
                                    .clearFilters()
                                : null,
                          )
                        : RefreshIndicator(
                            onRefresh: () =>
                                ref.read(repositoryProvider.notifier).refresh(),
                            child: ListView.separated(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              itemCount: state.items.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: AppSpacing.md),
                              itemBuilder: (context, index) {
                                final item = state.items[index];
                                return _RepositoryItemCard(
                                  item: item,
                                  onTap: () =>
                                      context.push('/repository/${item.id}'),
                                  onCopy: () => _copyToMyContent(context, item),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  void _copyToMyContent(BuildContext context, RepositoryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Copy to My Content'),
        content: Text(
            'Do you want to copy "${item.title}" to your personal collection?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${item.title} copied to your content'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _RepositoryItemCard extends StatelessWidget {
  final RepositoryItem item;
  final VoidCallback onTap;
  final VoidCallback onCopy;

  const _RepositoryItemCard({
    required this.item,
    required this.onTap,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: (item.type == 'note'
                          ? AppColors.primary
                          : AppColors.secondary)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: Icon(
                  item.type == 'note' ? Icons.description : Icons.account_tree,
                  color: item.type == 'note'
                      ? AppColors.primary
                      : AppColors.secondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.summary != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        item.summary!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: item.tags
                .take(3)
                .map((tag) => Chip(
                      label: Text(
                        tag,
                        style: const TextStyle(fontSize: 10),
                      ),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ))
                .toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'By ${item.authorName}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              OutlinedButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
