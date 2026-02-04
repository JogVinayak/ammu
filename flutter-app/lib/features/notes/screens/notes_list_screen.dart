import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/note_models.dart';
import '../providers/notes_provider.dart';

class NotesListScreen extends ConsumerStatefulWidget {
  const NotesListScreen({super.key});

  @override
  ConsumerState<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends ConsumerState<NotesListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      NoteStatus? status;
      switch (_tabController.index) {
        case 1:
          status = NoteStatus.draft;
          break;
        case 2:
          status = NoteStatus.published;
          break;
        case 3:
          status = NoteStatus.released;
          break;
        default:
          status = null;
      }
      ref.read(notesProvider.notifier).filterByStatus(status);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notesProvider);
    final filteredNotes = state.filteredNotes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Notes'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Draft'),
            Tab(text: 'Published'),
            Tab(text: 'Released'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search notes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: _searchController.text.isNotEmpty
                      ? IconButton(
                          key: const ValueKey('clear-search'),
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _searchFocusNode.unfocus();
                            ref.read(notesProvider.notifier).search('');
                            setState(() {});
                          },
                        )
                      : const SizedBox(
                          key: ValueKey('no-clear-search'),
                          width: 0,
                          height: 0,
                        ),
                ),
              ),
              onChanged: (value) {
                ref.read(notesProvider.notifier).search(value);
                setState(() {});
              },
              onSubmitted: (_) => _searchFocusNode.unfocus(),
            ),
          ),
          Expanded(
            child: state.isLoading
                ? const LoadingIndicator(message: 'Loading notes...')
                : state.error != null
                    ? AppErrorWidget(
                        message: state.error!,
                        onRetry: () =>
                            ref.read(notesProvider.notifier).refresh(),
                      )
                    : filteredNotes.isEmpty
                        ? EmptyState(
                            icon: Icons.note_alt_outlined,
                            title: 'No notes found',
                            subtitle: state.filterStatus != null ||
                                    (state.searchQuery?.isNotEmpty ?? false)
                                ? 'Try adjusting your filters'
                                : 'Create your first note to get started',
                            actionText: state.filterStatus == null &&
                                    (state.searchQuery?.isEmpty ?? true)
                                ? 'Create Note'
                                : null,
                            onAction: state.filterStatus == null &&
                                    (state.searchQuery?.isEmpty ?? true)
                                ? () => context.push('/notes/create')
                                : null,
                          )
                          : RefreshIndicator(
                            onRefresh: () =>
                                ref.read(notesProvider.notifier).refresh(),
                            child: ListView.separated(
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              padding: const EdgeInsets.all(AppSpacing.md),
                              itemCount: filteredNotes.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: AppSpacing.md),
                              itemBuilder: (context, index) {
                                final note = filteredNotes[index];
                                return _NoteCard(
                                  note: note,
                                  onTap: () =>
                                      context.push('/notes/${note.id}'),
                                  onEdit: () =>
                                      context.push('/notes/${note.id}/edit'),
                                  onRelease: () => _releaseNote(note),
                                  onDelete: () => _deleteNote(note),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/notes/create'),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _releaseNote(Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Release Note'),
        content: Text('Do you want to release "${note.title}" to your classes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(notesProvider.notifier).releaseNote(note.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Note released successfully'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Release'),
          ),
        ],
      ),
    );
  }

  void _deleteNote(Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text('Are you sure you want to delete "${note.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(notesProvider.notifier).deleteNote(note.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Note deleted'),
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

class _NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onRelease;
  final VoidCallback onDelete;

  const _NoteCard({
    required this.note,
    required this.onTap,
    required this.onEdit,
    required this.onRelease,
    required this.onDelete,
  });

  Color _getStatusColor(NoteStatus status) {
    switch (status) {
      case NoteStatus.published:
        return AppColors.success;
      case NoteStatus.draft:
        return AppColors.warning;
      case NoteStatus.released:
        return AppColors.primary;
    }
  }

  String _getStatusText(NoteStatus status) {
    switch (status) {
      case NoteStatus.published:
        return 'PUBLISHED';
      case NoteStatus.draft:
        return 'DRAFT';
      case NoteStatus.released:
        return 'RELEASED';
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final extraTags = note.tags.length - 3;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (note.summary != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        note.summary!,
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
              PopupMenuButton(
                icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  if (note.status != NoteStatus.released)
                    const PopupMenuItem(
                      value: 'release',
                      child: Row(
                        children: [
                          Icon(Icons.publish, size: 20),
                          SizedBox(width: 8),
                          Text('Release'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit();
                      break;
                    case 'release':
                      onRelease();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
              ),
            ],
          ),
          if (note.tags.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: note.tags
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
            if (extraTags > 0) ...[
              const SizedBox(height: AppSpacing.xs),
              Chip(
                label: Text(
                  '+$extraTags',
                  style: const TextStyle(fontSize: 10),
                ),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(note.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: Text(
                  _getStatusText(note.status),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(note.status),
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.schedule,
                    size: 12,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    _formatDate(note.updatedAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
