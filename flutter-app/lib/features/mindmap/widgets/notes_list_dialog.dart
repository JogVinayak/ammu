import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../notes/data/note_models.dart';
import '../../notes/providers/notes_provider.dart';
import '../data/concept_categories.dart';

class NotesListDialog extends ConsumerStatefulWidget {
  final ConceptCategory category;

  const NotesListDialog({
    super.key,
    required this.category,
  });

  @override
  ConsumerState<NotesListDialog> createState() => _NotesListDialogState();
}

class _NotesListDialogState extends ConsumerState<NotesListDialog> {
  List<Note> _filteredNotes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAndFilterNotes();
  }

  Future<void> _loadAndFilterNotes() async {
    try {
      // Get all notes from the provider
      final notesState = ref.read(notesProvider);

      if (notesState.isLoading) {
        // Wait for notes to load
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        final updatedState = ref.read(notesProvider);
        _filterNotes(updatedState.notes);
      } else if (notesState.error != null) {
        setState(() {
          _isLoading = false;
          _error = notesState.error;
        });
      } else {
        _filterNotes(notesState.notes);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _filterNotes(List<Note> allNotes) {
    final keywords = _getAllKeywords(widget.category);

    // Filter notes that match any keyword in title or content
    final filtered = allNotes.where((note) {
      final titleLower = note.title.toLowerCase();
      final contentLower = (note.contentMd ?? '').toLowerCase();

      return keywords.any((keyword) {
        final keywordLower = keyword.toLowerCase();
        return titleLower.contains(keywordLower) ||
               contentLower.contains(keywordLower);
      });
    }).toList();

    setState(() {
      _filteredNotes = filtered;
      _isLoading = false;
    });
  }

  List<String> _getAllKeywords(ConceptCategory category) {
    final keywords = <String>[...category.keywords, category.name];

    // Add child keywords too
    for (final child in category.children) {
      keywords.addAll(child.keywords);
      keywords.add(child.name);
    }

    return keywords;
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.category;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: category.color.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: category.color.withOpacity(0.2),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            _buildKeywordChips(),
            Expanded(child: _buildNotesList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final category = widget.category;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            category.color.withOpacity(0.3),
            category.color.withOpacity(0.1),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        border: Border(
          bottom: BorderSide(
            color: category.color.withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: category.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: category.color.withOpacity(0.3),
              ),
            ),
            child: Icon(
              category.icon,
              color: category.color,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: TextStyle(
                    color: category.color,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category.description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.white.withOpacity(0.7)),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildKeywordChips() {
    final category = widget.category;
    final keywords = _getAllKeywords(category);

    if (keywords.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Searching for:',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: keywords.take(8).map((keyword) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: category.color.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  keyword,
                  style: TextStyle(
                    color: category.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesList() {
    final category = widget.category;

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: category.color),
            const SizedBox(height: 16),
            Text(
              'Searching notes...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error loading notes',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredNotes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.note_add_outlined,
                size: 64,
                color: category.color.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No notes found',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create notes with keywords like "${category.keywords.isNotEmpty ? category.keywords.first : category.name}" to see them here',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to create note
                  context.push('/notes/new');
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Create Note'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: category.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredNotes.length,
      itemBuilder: (context, index) {
        final note = _filteredNotes[index];
        return _buildNoteCard(note);
      },
    );
  }

  Widget _buildNoteCard(Note note) {
    final category = widget.category;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.pop(context);
            context.push('/notes/${note.id}');
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: category.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.description_outlined,
                    color: category.color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildStatusBadge(note.status),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(note.updatedAt),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withOpacity(0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(NoteStatus status) {
    Color color;
    String label;

    switch (status) {
      case NoteStatus.draft:
        color = Colors.orange;
        label = 'Draft';
        break;
      case NoteStatus.ready:
        color = AppColors.primary;
        label = 'Ready';
        break;
      case NoteStatus.released:
        color = AppColors.success;
        label = 'Released';
        break;
      case NoteStatus.inReview:
        color = Colors.blue;
        label = 'In Review';
        break;
      case NoteStatus.archived:
        color = Colors.grey;
        label = 'Archived';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
