import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
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
import '../widgets/appflowy_editor_wrapper.dart';
import '../widgets/flashcard_editor_tab.dart';
import '../widgets/mcq_editor_tab.dart';

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
  final _tagController = TextEditingController();
  final _editorKey = GlobalKey<AppFlowyEditorWrapperState>();
  final List<String> _tags = [];
  bool _isLoading = false;
  bool _isSaving = false;
  NoteStatus? _noteStatus;
  String? _noteScopeType;
  String _initialContentMd = '';

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
          _initialContentMd = note.contentMd;
          _tags.clear();
          _tags.addAll(note.tags);
          _noteStatus = note.status;
          _noteScopeType = note.scopeType;
        });
        // Load markdown into editor after setState
        _editorKey.currentState?.loadMarkdown(note.contentMd);
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
    _tagController.dispose();
    super.dispose();
  }

  // ========== TAG MANAGEMENT ==========

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

  // ========== FLASHCARD / MCQ CALLBACKS ==========

  void _onFlashcardsChanged(List<FlashcardItem> flashcards) {
    _pendingFlashcards = flashcards;
    _flashcardsModified = true;
  }

  void _onMcqsChanged(List<McqItem> mcqs) {
    _pendingMcqs = mcqs;
    _mcqsModified = true;
  }

  // ========== IMAGE PICKER ==========

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

        final contentMd = _editorKey.currentState?.exportToMarkdown() ?? '';
        final note = await repository.createNote(CreateNoteRequest(
          title: _titleController.text.isNotEmpty
              ? _titleController.text
              : 'Untitled Note',
          contentMd: contentMd,
          tags: _tags,
          createdBy: userId,
          tenantId: tenantId,
          changeSummary: 'Auto-saved for image upload',
        ));
        noteId = note.id;
      }

      final imageResponse = await repository.uploadImage(noteId, picked.path);

      // Insert image into the editor with full URL
      final prefs = ref.read(sharedPreferencesProvider);
      final serverAddress = prefs.getString(StorageKeys.serverIp);
      final baseUrl = ApiConstants.baseUrl(serverAddress);
      final imageUrl =
          '$baseUrl/v1/notes/$noteId/images/${imageResponse.id}';
      _editorKey.currentState?.insertImageUrl(imageUrl);

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
    }
  }

  // ========== SAVE ==========

  Future<void> _saveNote() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final contentMd = _editorKey.currentState?.exportToMarkdown() ?? '';

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
          'contentMd': contentMd,
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
          contentMd: contentMd,
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

  // ========== BUILD ==========

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
          onTap: (_) => setState(() {}),
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
                  _buildEditor(),
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
    return Column(
      children: [
        // Metadata fields
        Padding(
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
            ],
          ),
        ),
        const Divider(height: 1),
        // AppFlowy Editor fills remaining space
        Expanded(
          child: AppFlowyEditorWrapper(
            key: _editorKey,
            initialMarkdown: _initialContentMd,
            onImageRequested: _showImagePickerSheet,
          ),
        ),
      ],
    );
  }
}
