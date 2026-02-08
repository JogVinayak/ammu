import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../data/mcq_models.dart';
import '../providers/mcq_provider.dart';

class McqEditorTab extends ConsumerStatefulWidget {
  final String? noteId;
  final ValueChanged<List<McqItem>> onMcqsChanged;

  const McqEditorTab({
    super.key,
    this.noteId,
    required this.onMcqsChanged,
  });

  @override
  ConsumerState<McqEditorTab> createState() => _McqEditorTabState();
}

class _McqEditorTabState extends ConsumerState<McqEditorTab> {
  final List<_EditableMcq> _mcqs = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.noteId != null) {
      _loadMcqs();
    }
  }

  Future<void> _loadMcqs() async {
    if (widget.noteId == null) return;

    setState(() => _isLoading = true);

    try {
      final mcqsState = ref.read(mcqsNotifierProvider(widget.noteId!));

      if (mcqsState.isLoading) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
      }

      final notifier = ref.read(mcqsNotifierProvider(widget.noteId!).notifier);
      await notifier.loadMcqs();

      if (!mounted) return;

      final state = ref.read(mcqsNotifierProvider(widget.noteId!));
      setState(() {
        _isLoading = false;
        _mcqs.clear();
        for (final mcq in state.mcqs) {
          _mcqs.add(_EditableMcq.fromMcq(mcq));
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _addMcq() {
    setState(() {
      _mcqs.add(_EditableMcq.empty());
    });
    _notifyChange();
  }

  void _removeMcq(int index) {
    setState(() {
      final removed = _mcqs.removeAt(index);
      removed.dispose();
    });
    _notifyChange();
  }

  void _reorderMcq(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _mcqs.removeAt(oldIndex);
      _mcqs.insert(newIndex, item);
    });
    _notifyChange();
  }

  void _notifyChange() {
    final items = _mcqs.asMap().entries.map((entry) {
      final index = entry.key;
      final mcq = entry.value;
      return McqItem(
        id: mcq.id,
        questionText: mcq.questionController.text,
        options: mcq.options
            .map((o) => McqOption(
                  text: o.textController.text,
                  isCorrect: o.isCorrect,
                ))
            .toList(),
        difficulty: mcq.difficulty,
        explanation: mcq.explanationController.text.isEmpty
            ? null
            : mcq.explanationController.text,
        position: index + 1,
      );
    }).toList();
    widget.onMcqsChanged(items);
  }

  @override
  void dispose() {
    for (final mcq in _mcqs) {
      mcq.dispose();
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

    if (_mcqs.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: _mcqs.length,
            onReorder: _reorderMcq,
            proxyDecorator: (child, index, animation) {
              return Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: child,
              );
            },
            itemBuilder: (context, index) {
              return _McqEditItem(
                key: ValueKey(_mcqs[index].key),
                index: index,
                mcq: _mcqs[index],
                onRemove: () => _removeMcq(index),
                onChanged: _notifyChange,
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
              Icons.quiz_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              'No quiz questions yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add MCQs to test students\'\nunderstanding of this note',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary.withAlpha(180),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _addMcq,
              icon: const Icon(Icons.add),
              label: const Text('Add First Question'),
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
          onPressed: _addMcq,
          icon: const Icon(Icons.add),
          label: Text('Add Question (${_mcqs.length})'),
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

class _EditableOption {
  final TextEditingController textController;
  bool isCorrect;

  _EditableOption({
    required String text,
    required this.isCorrect,
  }) : textController = TextEditingController(text: text);

  void dispose() {
    textController.dispose();
  }
}

class _EditableMcq {
  final String key;
  final String? id;
  final TextEditingController questionController;
  final List<_EditableOption> options;
  String difficulty;
  final TextEditingController explanationController;

  _EditableMcq({
    this.id,
    required String question,
    required List<McqOption> optionsList,
    required this.difficulty,
    String? explanation,
  })  : key = id ?? UniqueKey().toString(),
        questionController = TextEditingController(text: question),
        options = optionsList
            .map((o) => _EditableOption(text: o.text, isCorrect: o.isCorrect))
            .toList(),
        explanationController = TextEditingController(text: explanation ?? '');

  factory _EditableMcq.empty() {
    return _EditableMcq(
      question: '',
      optionsList: [
        const McqOption(text: '', isCorrect: true),
        const McqOption(text: '', isCorrect: false),
        const McqOption(text: '', isCorrect: false),
        const McqOption(text: '', isCorrect: false),
      ],
      difficulty: 'MEDIUM',
    );
  }

  factory _EditableMcq.fromMcq(Mcq mcq) {
    return _EditableMcq(
      id: mcq.id,
      question: mcq.questionText,
      optionsList: mcq.options,
      difficulty: mcq.difficulty,
      explanation: mcq.explanation,
    );
  }

  void dispose() {
    questionController.dispose();
    explanationController.dispose();
    for (final o in options) {
      o.dispose();
    }
  }

  void setCorrectOption(int index) {
    for (int i = 0; i < options.length; i++) {
      options[i].isCorrect = i == index;
    }
  }
}

class _McqEditItem extends StatefulWidget {
  final int index;
  final _EditableMcq mcq;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _McqEditItem({
    super.key,
    required this.index,
    required this.mcq,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<_McqEditItem> createState() => _McqEditItemState();
}

class _McqEditItemState extends State<_McqEditItem> {
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
          // Header
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
                  index: widget.index,
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
                  'Q${widget.index + 1}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                // Difficulty selector
                _buildDifficultySelector(),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  iconSize: 20,
                  color: AppColors.error,
                  onPressed: widget.onRemove,
                  tooltip: 'Remove question',
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question text field
                TextField(
                  controller: widget.mcq.questionController,
                  onChanged: (_) => widget.onChanged(),
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Question',
                    hintText: 'Enter the question...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Options
                Text(
                  'Options (tap radio to mark correct answer)',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                ...widget.mcq.options.asMap().entries.map((entry) {
                  final optIndex = entry.key;
                  final option = entry.value;
                  return _buildOptionField(optIndex, option);
                }),

                const SizedBox(height: 16),

                // Explanation
                TextField(
                  controller: widget.mcq.explanationController,
                  onChanged: (_) => widget.onChanged(),
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Explanation (optional)',
                    hintText: 'Why is this the correct answer?',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultySelector() {
    return PopupMenuButton<String>(
      initialValue: widget.mcq.difficulty,
      onSelected: (value) {
        setState(() {
          widget.mcq.difficulty = value;
        });
        widget.onChanged();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _getDifficultyColor(widget.mcq.difficulty).withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getDifficultyLabel(widget.mcq.difficulty),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _getDifficultyColor(widget.mcq.difficulty),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: _getDifficultyColor(widget.mcq.difficulty),
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        _buildDifficultyMenuItem('LOW', 'Easy'),
        _buildDifficultyMenuItem('MEDIUM', 'Medium'),
        _buildDifficultyMenuItem('HIGH', 'Hard'),
      ],
    );
  }

  PopupMenuItem<String> _buildDifficultyMenuItem(String value, String label) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _getDifficultyColor(value),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  String _getDifficultyLabel(String difficulty) {
    switch (difficulty.toUpperCase()) {
      case 'LOW':
        return 'Easy';
      case 'MEDIUM':
        return 'Medium';
      case 'HIGH':
        return 'Hard';
      default:
        return difficulty;
    }
  }

  Widget _buildOptionField(int index, _EditableOption option) {
    final letter = String.fromCharCode(65 + index); // A, B, C, D

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Radio<int>(
            value: index,
            groupValue: widget.mcq.options.indexWhere((o) => o.isCorrect),
            onChanged: (value) {
              setState(() {
                widget.mcq.setCorrectOption(value!);
              });
              widget.onChanged();
            },
            activeColor: AppColors.success,
          ),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: option.isCorrect
                  ? AppColors.success.withOpacity(0.15)
                  : Colors.grey.shade100,
              border: Border.all(
                color: option.isCorrect ? AppColors.success : Colors.grey.shade300,
              ),
            ),
            child: Center(
              child: Text(
                letter,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: option.isCorrect
                      ? AppColors.success
                      : AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: option.textController,
              onChanged: (_) => widget.onChanged(),
              decoration: InputDecoration(
                hintText: 'Option $letter',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: option.isCorrect
                        ? AppColors.success
                        : Colors.grey.shade300,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: option.isCorrect
                        ? AppColors.success
                        : AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
