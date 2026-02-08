import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/student_repository.dart';
import '../../notes/data/note_models.dart';
import '../../notes/widgets/flashcard_viewer.dart';
import '../../notes/widgets/mcq_viewer.dart';
import '../widgets/guided_reading_view.dart';

class StudentNoteViewerScreen extends ConsumerStatefulWidget {
  final String noteId;

  const StudentNoteViewerScreen({super.key, required this.noteId});

  @override
  ConsumerState<StudentNoteViewerScreen> createState() =>
      _StudentNoteViewerScreenState();
}

class _StudentNoteViewerScreenState
    extends ConsumerState<StudentNoteViewerScreen> {
  Note? _note;
  bool _isLoading = true;
  String? _error;
  bool _isGuidedReadingMode = false;
  final ScrollController _scrollController = ScrollController();

  static const _accentColor = Color(0xFF14B8A6); // Teal for students

  @override
  void initState() {
    super.initState();
    _loadNote();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadNote() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = ref.read(studentRepositoryProvider);
      final note = await repository.getNoteById(widget.noteId);
      setState(() {
        _note = note;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showFlashcards() {
    if (_note == null) return;
    showDialog(
      context: context,
      builder: (context) => FlashcardViewerDialog(
        noteId: _note!.id,
        noteTitle: _note!.title,
      ),
    );
  }

  void _showMcqs() {
    if (_note == null) return;
    showDialog(
      context: context,
      builder: (context) => McqViewerDialog(
        noteId: _note!.id,
        noteTitle: _note!.title,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_note?.title ?? 'Note'),
        centerTitle: true,
        actions: [
          // Flashcard button
          if (_note != null)
            IconButton(
              icon: const Icon(Icons.style),
              tooltip: 'Revise Flashcards',
              onPressed: () => _showFlashcards(),
            ),
          // MCQ/Quiz button
          if (_note != null)
            IconButton(
              icon: const Icon(Icons.quiz),
              tooltip: 'Take Quiz',
              onPressed: () => _showMcqs(),
            ),
          // Guided reading button
          if (_note != null && _note!.contentMd != null && _note!.contentMd!.isNotEmpty)
            IconButton(
              onPressed: () {
                setState(() => _isGuidedReadingMode = !_isGuidedReadingMode);
              },
              icon: Icon(
                _isGuidedReadingMode
                    ? Icons.chrome_reader_mode
                    : Icons.chrome_reader_mode_outlined,
                color: _isGuidedReadingMode ? _accentColor : null,
              ),
              tooltip: _isGuidedReadingMode
                  ? 'Exit Guided Reading'
                  : 'Guided Reading Mode',
            ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const LoadingIndicator(message: 'Loading note...');
    }

    if (_error != null) {
      return AppErrorWidget(
        message: _error!,
        onRetry: _loadNote,
      );
    }

    if (_note == null) {
      return const Center(child: Text('Note not found'));
    }

    // Wrap content with guided reading overlay
    return GuidedReadingOverlay(
      isEnabled: _isGuidedReadingMode,
      scrollController: _scrollController,
      textContent: _note!.contentMd ?? '',  // Fallback: raw markdown
      guidedJson: _note!.contentGuidedJson,  // Preferred: pre-processed JSON from server
      title: _note!.title,
      highlightColor: _accentColor,
      onDisable: () => setState(() => _isGuidedReadingMode = false),
      onComplete: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('You completed reading this note!'),
            backgroundColor: _accentColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: _buildNoteContent(context),
    );
  }

  /// Simple markdown stripper for word counting
  String _stripMarkdown(String markdown) {
    var text = markdown;
    text = text.replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '');
    text = text.replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'\1');
    text = text.replaceAll(RegExp(r'\*(.+?)\*'), r'\1');
    text = text.replaceAll(RegExp(r'__(.+?)__'), r'\1');
    text = text.replaceAll(RegExp(r'_(.+?)_'), r'\1');
    text = text.replaceAll(RegExp(r'```[\s\S]*?```'), '');
    text = text.replaceAll(RegExp(r'`(.+?)`'), r'\1');
    text = text.replaceAll(RegExp(r'\[(.+?)\]\(.+?\)'), r'\1');
    text = text.replaceAll(RegExp(r'!\[.*?\]\(.+?\)'), '');
    text = text.replaceAll(RegExp(r'^[\*\-\+]\s+', multiLine: true), '');
    text = text.replaceAll(RegExp(r'^\d+\.\s+', multiLine: true), '');
    text = text.replaceAll(RegExp(r'^>\s*', multiLine: true), '');
    text = text.replaceAll(RegExp(r'^[-*_]{3,}$', multiLine: true), '');
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return text.trim();
  }

  Widget _buildNoteContent(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            _note!.title,
            style: Theme.of(context).textTheme.headlineLarge,
          ),

          // Summary
          if (_note!.summary != null && _note!.summary!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _note!.summary!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],

          // Metadata
          const SizedBox(height: AppSpacing.md),
          _buildMetadata(context),

          // Divider
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Divider(),
          ),

          // Content
          if (_note!.contentMd != null && _note!.contentMd!.isNotEmpty)
            MarkdownBody(
              data: _note!.contentMd!,
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                h1: Theme.of(context).textTheme.headlineLarge,
                h2: Theme.of(context).textTheme.headlineSmall,
                h3: Theme.of(context).textTheme.titleLarge,
                p: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                ),
                code: TextStyle(
                  backgroundColor: AppColors.background,
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
                codeblockDecoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                blockquoteDecoration: BoxDecoration(
                  color: AppColors.background,
                  border: Border(
                    left: BorderSide(
                      color: AppColors.primary,
                      width: 4,
                    ),
                  ),
                ),
              ),
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    Icon(
                      Icons.article_outlined,
                      size: 48,
                      color: AppColors.textSecondary.withOpacity(0.5),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'No content available',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom padding
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildMetadata(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: [
        if (_note!.updatedAt != null)
          _MetadataChip(
            icon: Icons.update,
            label: 'Updated ${_formatDate(_note!.updatedAt!)}',
          ),
        if (_note!.tags.isNotEmpty)
          ..._note!.tags.map((tag) => _TagChip(tag: tag)),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _MetadataChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetadataChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  final String tag;

  const _TagChip({required this.tag});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        tag,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
