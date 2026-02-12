import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/flashcard_models.dart';
import '../data/mcq_models.dart';
import '../data/note_models.dart';
import '../data/notes_repository.dart';
import '../providers/flashcard_provider.dart';
import '../providers/mcq_provider.dart';
import '../providers/notes_provider.dart';
import '../widgets/flashcard_editor_tab.dart';
import '../widgets/mcq_editor_tab.dart';
import '../widgets/note_image_builder.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final String? noteId;

  const NoteEditorScreen({super.key, this.noteId});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();
  final List<String> _tags = [];
  bool _isPreview = false;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isUploadingImage = false;
  NoteStatus? _noteStatus;
  String? _noteScopeType;

  late TabController _tabController;
  List<FlashcardItem> _pendingFlashcards = [];
  bool _flashcardsModified = false;
  List<McqItem> _pendingMcqs = [];
  bool _mcqsModified = false;

  bool get isEditing => widget.noteId != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (isEditing) {
      _loadNote();
    }
  }

  Future<void> _loadNote() async {
    setState(() => _isLoading = true);

    try {
      final repository = ref.read(notesRepositoryProvider);
      final note = await repository.getNoteById(widget.noteId!);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _titleController.text = note.title;
          _summaryController.text = note.summary ?? '';
          _contentController.text = note.contentMd;
          _tags.clear();
          _tags.addAll(note.tags);
          _noteStatus = note.status;
          _noteScopeType = note.scopeType;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading note: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _summaryController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _insertMarkdown(String prefix, [String suffix = '']) {
    final text = _contentController.text;
    final selection = _contentController.selection;
    final selectedText = selection.textInside(text);

    final newText = text.replaceRange(
      selection.start,
      selection.end,
      '$prefix$selectedText$suffix',
    );

    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + prefix.length + selectedText.length + suffix.length,
      ),
    );
  }

  void _onFlashcardsChanged(List<FlashcardItem> flashcards) {
    _pendingFlashcards = flashcards;
    _flashcardsModified = true;
  }

  void _onMcqsChanged(List<McqItem> mcqs) {
    _pendingMcqs = mcqs;
    _mcqsModified = true;
  }

  void _showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        imageQuality: 80,
      );
      if (picked == null) return;

      setState(() => _isUploadingImage = true);

      final repository = ref.read(notesRepositoryProvider);
      String noteId;

      if (isEditing) {
        noteId = widget.noteId!;
      } else {
        // Auto-save the note first to get an ID
        final user = ref.read(authProvider).user;
        final userId = user?.id ?? '';
        final tenantId = user?.tenantId ?? '';

        if (userId.isEmpty || tenantId.isEmpty) {
          throw Exception('User not logged in');
        }

        final note = await repository.createNote(CreateNoteRequest(
          title: _titleController.text.isNotEmpty
              ? _titleController.text
              : 'Untitled Note',
          contentMd: _contentController.text,
          tags: _tags,
          createdBy: userId,
          tenantId: tenantId,
          changeSummary: 'Auto-saved for image upload',
        ));
        noteId = note.id;
        // Update the widget to reflect it's now editing an existing note
        // We can't change widget.noteId, so we just use noteId going forward
      }

      final imageResponse = await repository.uploadImage(noteId, picked.path);

      // Insert markdown image reference at cursor
      final imageMarkdown =
          '\n![${imageResponse.fileName}](/v1/notes/$noteId/images/${imageResponse.id})\n';
      _insertMarkdown(imageMarkdown);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo attached'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to attach photo: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  Future<void> _saveNote() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    try {
      final repository = ref.read(notesRepositoryProvider);

      final user = ref.read(authProvider).user;
      final userId = user?.id ?? '';
      final tenantId = user?.tenantId ?? '';

      if (userId.isEmpty) {
        throw Exception('User not logged in. Please login again.');
      }
      if (tenantId.isEmpty) {
        throw Exception('Tenant not resolved. Please login again.');
      }

      String savedNoteId;

      if (isEditing) {
        // Update existing note
        final updatePayload = <String, dynamic>{
          'title': _titleController.text,
          if (_summaryController.text.isNotEmpty) 'summary': _summaryController.text,
          'contentMd': _contentController.text,
          'tags': _tags,
          'updatedBy': userId,
          if (_noteScopeType != null && _noteScopeType!.isNotEmpty)
            'scopeType': _noteScopeType,
          if (_noteStatus != null) 'status': _noteStatus!.name.toUpperCase(),
        };

        await repository.updateNote(widget.noteId!, updatePayload);
        savedNoteId = widget.noteId!;
      } else {
        // Create new note
        final note = await repository.createNote(CreateNoteRequest(
          title: _titleController.text,
          summary: _summaryController.text.isNotEmpty ? _summaryController.text : null,
          contentMd: _contentController.text,
          tags: _tags,
          createdBy: userId,
          tenantId: tenantId,
          changeSummary: 'Initial draft',
        ));
        savedNoteId = note.id;
      }

      // Save flashcards if modified
      if (_flashcardsModified && _pendingFlashcards.isNotEmpty) {
        final flashcardsNotifier = ref.read(
          flashcardsNotifierProvider(savedNoteId).notifier,
        );
        await flashcardsNotifier.batchSave(_pendingFlashcards, replaceAll: true);
      }

      // Save MCQs if modified
      if (_mcqsModified && _pendingMcqs.isNotEmpty) {
        final mcqsNotifier = ref.read(
          mcqsNotifierProvider(savedNoteId).notifier,
        );
        await mcqsNotifier.batchSave(_pendingMcqs, replaceAll: true);
      }

      if (mounted) {
        // Refresh the notes list
        ref.read(notesProvider.notifier).refresh();

        // Invalidate the detail provider so viewer fetches fresh data
        if (isEditing) {
          ref.invalidate(noteDetailProvider(widget.noteId!));
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Note updated' : 'Note created'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Note' : 'Create Note'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          // Preview toggle only shown for Content tab
          if (_tabController.index == 0)
            IconButton(
              icon: Icon(_isPreview ? Icons.edit : Icons.preview),
              onPressed: () => setState(() => _isPreview = !_isPreview),
              tooltip: _isPreview ? 'Edit' : 'Preview',
            ),
          TextButton(
            onPressed: _isSaving ? null : _saveNote,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => setState(() {}), // Rebuild to update preview button visibility
          tabs: const [
            Tab(
              icon: Icon(Icons.description_outlined),
              text: 'Content',
            ),
            Tab(
              icon: Icon(Icons.style_outlined),
              text: 'Flashcards',
            ),
            Tab(
              icon: Icon(Icons.quiz_outlined),
              text: 'Quiz',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading note...')
          : Form(
              key: _formKey,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Content Tab
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: _isPreview
                        ? KeyedSubtree(
                            key: const ValueKey('preview'),
                            child: _buildPreview(),
                          )
                        : KeyedSubtree(
                            key: const ValueKey('editor'),
                            child: _buildEditor(),
                          ),
                  ),
                  // Flashcards Tab
                  FlashcardEditorTab(
                    noteId: widget.noteId,
                    onFlashcardsChanged: _onFlashcardsChanged,
                  ),
                  // MCQ Tab
                  McqEditorTab(
                    noteId: widget.noteId,
                    onMcqsChanged: _onMcqsChanged,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEditor() {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            label: 'Title',
            hint: 'Enter note title',
            controller: _titleController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a title';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Summary',
            hint: 'Brief summary of the note',
            controller: _summaryController,
            maxLines: 2,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Tags',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tagController,
                  decoration: const InputDecoration(
                    hintText: 'Add a tag',
                  ),
                  onSubmitted: (_) => _addTag(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                onPressed: _addTag,
                icon: const Icon(Icons.add_circle),
                color: AppColors.primary,
              ),
            ],
          ),
          if (_tags.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: _tags
                  .map((tag) => Chip(
                        label: Text(tag),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => _removeTag(tag),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(
            'Content',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildMarkdownToolbar(),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _contentController,
            maxLines: 15,
            decoration: const InputDecoration(
              hintText: 'Write your content in Markdown...',
              alignLabelWithHint: true,
            ),
            style: const TextStyle(fontFamily: 'monospace'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter content';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMarkdownToolbar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _ToolbarButton(
            icon: Icons.format_bold,
            tooltip: 'Bold',
            onPressed: () => _insertMarkdown('**', '**'),
          ),
          _ToolbarButton(
            icon: Icons.format_italic,
            tooltip: 'Italic',
            onPressed: () => _insertMarkdown('*', '*'),
          ),
          _ToolbarButton(
            icon: Icons.title,
            tooltip: 'Heading',
            onPressed: () => _insertMarkdown('## '),
          ),
          _ToolbarButton(
            icon: Icons.format_list_bulleted,
            tooltip: 'Bullet List',
            onPressed: () => _insertMarkdown('- '),
          ),
          _ToolbarButton(
            icon: Icons.format_list_numbered,
            tooltip: 'Numbered List',
            onPressed: () => _insertMarkdown('1. '),
          ),
          _ToolbarButton(
            icon: Icons.code,
            tooltip: 'Code',
            onPressed: () => _insertMarkdown('`', '`'),
          ),
          _ToolbarButton(
            icon: Icons.format_quote,
            tooltip: 'Quote',
            onPressed: () => _insertMarkdown('> '),
          ),
          _ToolbarButton(
            icon: Icons.link,
            tooltip: 'Link',
            onPressed: () => _insertMarkdown('[', '](url)'),
          ),
          _isUploadingImage
              ? const Padding(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : _ToolbarButton(
                  icon: Icons.camera_alt,
                  tooltip: 'Add Photo',
                  onPressed: _showImagePickerSheet,
                ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _titleController.text.isEmpty ? 'Untitled' : _titleController.text,
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          if (_summaryController.text.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _summaryController.text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
          if (_tags.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: _tags
                  .map((tag) => Chip(
                        label: Text(tag),
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        labelStyle: TextStyle(color: AppColors.primary),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          const SizedBox(height: AppSpacing.md),
          MarkdownBody(
            data: _contentController.text.isEmpty
                ? '*No content yet*'
                : _contentController.text,
            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
            imageBuilder: (uri, title, alt) =>
                buildNoteImage(uri, title, alt, ref),
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Icon(icon, size: 20),
        ),
      ),
    );
  }
}
