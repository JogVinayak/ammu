import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/mindmap_models.dart';
import '../providers/mindmaps_provider.dart';

class MindmapsListScreen extends ConsumerWidget {
  const MindmapsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mindmapsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Mindmaps'),
      ),
      body: state.isLoading
          ? const LoadingIndicator(message: 'Loading mindmaps...')
          : state.error != null
              ? AppErrorWidget(
                  message: state.error!,
                  onRetry: () => ref.read(mindmapsProvider.notifier).refresh(),
                )
              : state.mindmaps.isEmpty
                  ? EmptyState(
                      icon: Icons.account_tree_outlined,
                      title: 'No mindmaps yet',
                      subtitle: 'Create your first mindmap to visualize concepts',
                      actionText: 'Create Mindmap',
                      onAction: () => context.push('/mindmaps/create'),
                    )
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(mindmapsProvider.notifier).refresh(),
                      child: GridView.builder(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: AppSpacing.md,
                          mainAxisSpacing: AppSpacing.md,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: state.mindmaps.length,
                        itemBuilder: (context, index) {
                          final mindmap = state.mindmaps[index];
                          return _MindmapCard(
                            mindmap: mindmap,
                            onTap: () =>
                                context.push('/mindmaps/${mindmap.id}'),
                            onDelete: () =>
                                _deleteMindmap(context, ref, mindmap),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/mindmaps/create'),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _deleteMindmap(BuildContext context, WidgetRef ref, Mindmap mindmap) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Mindmap'),
        content: Text('Are you sure you want to delete "${mindmap.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(mindmapsProvider.notifier).deleteMindmap(mindmap.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Mindmap deleted'),
                  backgroundColor: AppColors.error,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _MindmapCard extends StatelessWidget {
  final Mindmap mindmap;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _MindmapCard({
    required this.mindmap,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.card),
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.account_tree,
                      size: 48,
                      color: AppColors.primary.withOpacity(0.5),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: PopupMenuButton(
                      icon: const Icon(
                        Icons.more_vert,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18, color: AppColors.error),
                              SizedBox(width: 8),
                              Text('Delete',
                                  style: TextStyle(color: AppColors.error)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'delete') {
                          onDelete();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mindmap.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    const Icon(
                      Icons.circle,
                      size: 8,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${mindmap.nodeCount} nodes',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
