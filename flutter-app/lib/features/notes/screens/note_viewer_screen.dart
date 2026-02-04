import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/notes_provider.dart';

class NoteViewerScreen extends ConsumerWidget {
  final String noteId;

  const NoteViewerScreen({super.key, required this.noteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noteAsync = ref.watch(noteDetailProvider(noteId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Note'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/notes/$noteId/edit'),
          ),
        ],
      ),
      body: noteAsync.when(
        data: (note) {
          if (note == null) {
            return const AppErrorWidget(message: 'Note not found');
          }

          return SelectionArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '${note.updatedAt.day}/${note.updatedAt.month}/${note.updatedAt.year}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(note.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppRadius.chip),
                        ),
                        child: Text(
                          note.status.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(note.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (note.summary != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      note.summary!,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                  if (note.tags.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: note.tags
                          .map((tag) => Chip(
                                label: Text(tag),
                                backgroundColor:
                                    AppColors.primary.withOpacity(0.1),
                                labelStyle: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  const Divider(),
                  const SizedBox(height: AppSpacing.md),
                  MarkdownBody(
                    data: note.contentMd,
                    styleSheet: MarkdownStyleSheet.fromTheme(
                      Theme.of(context),
                    ).copyWith(
                      h1: Theme.of(context).textTheme.headlineMedium,
                      h2: Theme.of(context).textTheme.headlineSmall,
                      h3: Theme.of(context).textTheme.titleLarge,
                      p: Theme.of(context).textTheme.bodyLarge,
                      code: TextStyle(
                        backgroundColor: AppColors.background,
                        fontFamily: 'monospace',
                      ),
                      blockquote:
                          Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppColors.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          );
        },
        loading: () => const LoadingIndicator(message: 'Loading note...'),
        error: (error, _) => AppErrorWidget(message: error.toString()),
      ),
      floatingActionButton: noteAsync.maybeWhen(
        data: (note) => note != null
            ? FloatingActionButton.extended(
                onPressed: () => _releaseToClass(context, ref),
                icon: const Icon(Icons.publish),
                label: const Text('Release to Class'),
              )
            : null,
        orElse: () => null,
      ),
    );
  }

  Color _getStatusColor(dynamic status) {
    switch (status.toString()) {
      case 'NoteStatus.published':
        return AppColors.success;
      case 'NoteStatus.draft':
        return AppColors.warning;
      case 'NoteStatus.released':
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }

  void _releaseToClass(BuildContext context, WidgetRef ref) {
    context.push('/release?contentId=$noteId&contentType=note');
  }
}
