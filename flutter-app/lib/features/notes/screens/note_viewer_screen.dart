import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/note_models.dart';
import '../providers/notes_provider.dart';
import '../widgets/flashcard_viewer.dart';
import '../widgets/mcq_viewer.dart';
import '../widgets/note_image_builder.dart';

class NoteViewerScreen extends ConsumerStatefulWidget {
  final String noteId;

  const NoteViewerScreen({super.key, required this.noteId});

  @override
  ConsumerState<NoteViewerScreen> createState() => _NoteViewerScreenState();
}

class _NoteViewerScreenState extends ConsumerState<NoteViewerScreen> {
  bool _isPublishing = false;

  @override
  Widget build(BuildContext context) {
    final noteAsync = ref.watch(noteDetailProvider(widget.noteId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Note'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          noteAsync.maybeWhen(
            data: (note) => note != null
                ? IconButton(
                    icon: const Icon(Icons.style),
                    tooltip: 'Revise Flashcards',
                    onPressed: () => _showFlashcards(note),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
          noteAsync.maybeWhen(
            data: (note) => note != null
                ? IconButton(
                    icon: const Icon(Icons.quiz),
                    tooltip: 'Take Quiz',
                    onPressed: () => _showMcqs(note),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/notes/${widget.noteId}/edit'),
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
                    imageBuilder: (uri, title, alt) =>
                        buildNoteImage(uri, title, alt, ref),
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
        data: (note) {
          if (note == null) return null;

          // Show different actions based on status
          if (note.status == NoteStatus.draft) {
            return FloatingActionButton.extended(
              onPressed: _isPublishing ? null : () => _markReady(note),
              icon: _isPublishing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle),
              label: Text(_isPublishing ? 'Marking Ready...' : 'Mark Ready'),
              backgroundColor: AppColors.success,
            );
          } else if (note.status == NoteStatus.ready) {
            return FloatingActionButton.extended(
              onPressed: () => _releaseToClass(),
              icon: const Icon(Icons.publish),
              label: const Text('Release to Class'),
            );
          }
          // Released/archived notes don't need action
          return null;
        },
        orElse: () => null,
      ),
    );
  }

  Color _getStatusColor(dynamic status) {
    switch (status.toString()) {
      case 'NoteStatus.ready':
        return AppColors.success;
      case 'NoteStatus.draft':
        return AppColors.warning;
      case 'NoteStatus.inReview':
        return Colors.orange;
      case 'NoteStatus.released':
        return AppColors.primary;
      case 'NoteStatus.archived':
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }

  Future<void> _markReady(Note note) async {
    setState(() => _isPublishing = true);

    try {
      await ref.read(notesProvider.notifier).markReady(note.id);

      // Invalidate and refresh to show updated status
      ref.invalidate(noteDetailProvider(widget.noteId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note marked as ready'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark ready: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPublishing = false);
      }
    }
  }

  void _releaseToClass() {
    context.push('/release?contentId=${widget.noteId}&contentType=note');
  }

  void _showFlashcards(Note note) {
    showDialog(
      context: context,
      builder: (context) => FlashcardViewerDialog(
        noteId: note.id,
        noteTitle: note.title,
      ),
    );
  }

  void _showMcqs(Note note) {
    showDialog(
      context: context,
      builder: (context) => McqViewerDialog(
        noteId: note.id,
        noteTitle: note.title,
      ),
    );
  }
}
