import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../data/flashcard_models.dart';
import '../providers/flashcard_provider.dart';

class FlashcardEditorTab extends ConsumerStatefulWidget {
  final String? noteId;
  final ValueChanged<List<FlashcardItem>> onFlashcardsChanged;

  const FlashcardEditorTab({
    super.key,
    this.noteId,
    required this.onFlashcardsChanged,
  });

  @override
  ConsumerState<FlashcardEditorTab> createState() => _FlashcardEditorTabState();
}

class _FlashcardEditorTabState extends ConsumerState<FlashcardEditorTab> {
  final List<_EditableFlashcard> _flashcards = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.noteId != null) {
      _loadFlashcards();
    }
  }

  Future<void> _loadFlashcards() async {
    if (widget.noteId == null) return;

    setState(() => _isLoading = true);

    try {
      final flashcardsState = ref.read(flashcardsNotifierProvider(widget.noteId!));

      // Wait for loading to complete
      if (flashcardsState.isLoading) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
      }

      final notifier = ref.read(flashcardsNotifierProvider(widget.noteId!).notifier);
      await notifier.loadFlashcards();

      if (!mounted) return;

      final state = ref.read(flashcardsNotifierProvider(widget.noteId!));
      setState(() {
        _isLoading = false;
        _flashcards.clear();
        for (final fc in state.flashcards) {
          _flashcards.add(_EditableFlashcard(
            id: fc.id,
            frontController: TextEditingController(text: fc.frontText),
            backController: TextEditingController(text: fc.backText),
            difficulty: fc.difficulty,
          ));
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _addFlashcard() {
    setState(() {
      _flashcards.add(_EditableFlashcard(
        frontController: TextEditingController(),
        backController: TextEditingController(),
        difficulty: 'MEDIUM',
      ));
    });
    _notifyChange();
  }

  void _removeFlashcard(int index) {
    setState(() {
      final removed = _flashcards.removeAt(index);
      removed.frontController.dispose();
      removed.backController.dispose();
    });
    _notifyChange();
  }

  void _reorderFlashcard(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _flashcards.removeAt(oldIndex);
      _flashcards.insert(newIndex, item);
    });
    _notifyChange();
  }

  void _updateDifficulty(int index, String difficulty) {
    setState(() {
      _flashcards[index].difficulty = difficulty;
    });
    _notifyChange();
  }

  void _notifyChange() {
    final items = _flashcards.asMap().entries.map((entry) {
      final index = entry.key;
      final fc = entry.value;
      return FlashcardItem(
        id: fc.id,
        frontText: fc.frontController.text,
        backText: fc.backController.text,
        difficulty: fc.difficulty,
        position: index + 1,
      );
    }).toList();
    widget.onFlashcardsChanged(items);
  }

  @override
  void dispose() {
    for (final fc in _flashcards) {
      fc.frontController.dispose();
      fc.backController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_flashcards.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: _flashcards.length,
            onReorder: _reorderFlashcard,
            proxyDecorator: (child, index, animation) {
              return Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: child,
              );
            },
            itemBuilder: (context, index) {
              return _FlashcardEditItem(
                key: ValueKey(_flashcards[index].key),
                index: index,
                flashcard: _flashcards[index],
                onRemove: () => _removeFlashcard(index),
                onChanged: _notifyChange,
                onDifficultyChanged: (difficulty) => _updateDifficulty(index, difficulty),
              );
            },
          ),
        ),
        _buildAddButton(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.style_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              'No flashcards yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add flashcards to help students revise\nkey concepts from this note',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary.withAlpha(180),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _addFlashcard,
              icon: const Icon(Icons.add),
              label: const Text('Add First Flashcard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _addFlashcard,
          icon: const Icon(Icons.add),
          label: Text('Add Flashcard (${_flashcards.length})'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }
}

class _EditableFlashcard {
  final String key;
  final String? id;
  final TextEditingController frontController;
  final TextEditingController backController;
  String difficulty;

  _EditableFlashcard({
    this.id,
    required this.frontController,
    required this.backController,
    this.difficulty = 'MEDIUM',
  }) : key = id ?? UniqueKey().toString();
}

class _FlashcardEditItem extends StatelessWidget {
  final int index;
  final _EditableFlashcard flashcard;
  final VoidCallback onRemove;
  final VoidCallback onChanged;
  final ValueChanged<String> onDifficultyChanged;

  const _FlashcardEditItem({
    super.key,
    required this.index,
    required this.flashcard,
    required this.onRemove,
    required this.onChanged,
    required this.onDifficultyChanged,
  });

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toUpperCase()) {
      case 'LOW':
        return AppColors.success;
      case 'MEDIUM':
        return Colors.orange;
      case 'HIGH':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with drag handle, difficulty selector, and delete
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(15),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.drag_handle,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ),
                Text(
                  'Card ${index + 1}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                // Difficulty selector chips
                _buildDifficultyChip('LOW', 'Easy'),
                const SizedBox(width: 4),
                _buildDifficultyChip('MEDIUM', 'Medium'),
                const SizedBox(width: 4),
                _buildDifficultyChip('HIGH', 'Hard'),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  iconSize: 20,
                  color: AppColors.error,
                  onPressed: onRemove,
                  tooltip: 'Remove flashcard',
                ),
              ],
            ),
          ),

          // Front text field
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Question',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: flashcard.frontController,
                  onChanged: (_) => onChanged(),
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Enter the question...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),

          // Back text field
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withAlpha(25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Answer',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: flashcard.backController,
                  onChanged: (_) => onChanged(),
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter the answer...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.success),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyChip(String difficulty, String label) {
    final isSelected = flashcard.difficulty.toUpperCase() == difficulty.toUpperCase();
    final color = _getDifficultyColor(difficulty);

    return GestureDetector(
      onTap: () => onDifficultyChanged(difficulty),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? color : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
