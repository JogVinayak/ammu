import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../data/mcq_models.dart';
import '../providers/mcq_provider.dart';

class McqViewerDialog extends ConsumerStatefulWidget {
  final String noteId;
  final String noteTitle;

  const McqViewerDialog({
    super.key,
    required this.noteId,
    required this.noteTitle,
  });

  @override
  ConsumerState<McqViewerDialog> createState() => _McqViewerDialogState();
}

class _McqViewerDialogState extends ConsumerState<McqViewerDialog> {
  int _currentIndex = 0;
  int? _selectedOption;
  bool _hasSubmitted = false;
  late PageController _pageController;
  String? _difficultyFilter;

  // Track stats
  int _correctCount = 0;
  int _attemptedCount = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _resetForNewQuestion() {
    setState(() {
      _selectedOption = null;
      _hasSubmitted = false;
    });
  }

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

  @override
  Widget build(BuildContext context) {
    final mcqsAsync = ref.watch(mcqsProvider(widget.noteId));

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Expanded(
              child: mcqsAsync.when(
                data: (mcqs) {
                  final filtered = _difficultyFilter != null
                      ? mcqs
                          .where((m) =>
                              m.difficulty.toUpperCase() ==
                              _difficultyFilter!.toUpperCase())
                          .toList()
                      : mcqs;
                  return filtered.isEmpty
                      ? _buildEmptyState()
                      : _buildMcqView(filtered);
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Error: $e'),
                  ),
                ),
              ),
            ),
            mcqsAsync.maybeWhen(
              data: (mcqs) {
                final filtered = _difficultyFilter != null
                    ? mcqs
                        .where((m) =>
                            m.difficulty.toUpperCase() ==
                            _difficultyFilter!.toUpperCase())
                        .toList()
                    : mcqs;
                return filtered.isNotEmpty
                    ? _buildControls(filtered.length)
                    : const SizedBox.shrink();
              },
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.quiz, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quiz',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      widget.noteTitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Difficulty filter chips
          Row(
            children: [
              _buildFilterChip(null, 'All'),
              const SizedBox(width: 8),
              _buildFilterChip('LOW', 'Easy'),
              const SizedBox(width: 8),
              _buildFilterChip('MEDIUM', 'Medium'),
              const SizedBox(width: 8),
              _buildFilterChip('HIGH', 'Hard'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String? difficulty, String label) {
    final isSelected = _difficultyFilter == difficulty;
    final color = difficulty != null
        ? _getDifficultyColor(difficulty)
        : AppColors.primary;

    return GestureDetector(
      onTap: () {
        setState(() {
          _difficultyFilter = difficulty;
          _currentIndex = 0;
          _resetForNewQuestion();
        });
        _pageController.jumpToPage(0);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? color : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _difficultyFilter != null
                ? 'No ${_getDifficultyLabel(_difficultyFilter!)} questions'
                : 'No quiz questions yet',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Quiz questions for this note will appear here',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary.withAlpha(180),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMcqView(List<Mcq> mcqs) {
    return PageView.builder(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      onPageChanged: (index) {
        setState(() {
          _currentIndex = index;
          _resetForNewQuestion();
        });
      },
      itemCount: mcqs.length,
      itemBuilder: (context, index) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _buildQuestionCard(mcqs[index]),
        );
      },
    );
  }

  Widget _buildQuestionCard(Mcq mcq) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Difficulty badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _getDifficultyColor(mcq.difficulty).withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _getDifficultyLabel(mcq.difficulty),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _getDifficultyColor(mcq.difficulty),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Question
        Text(
          mcq.questionText,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),

        // Options
        ...mcq.options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          return _buildOptionTile(index, option, mcq.correctIndex);
        }),

        const SizedBox(height: 20),

        // Submit/Next button
        if (!_hasSubmitted && _selectedOption != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _hasSubmitted = true;
                  _attemptedCount++;
                  if (_selectedOption == mcq.correctIndex) {
                    _correctCount++;
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Check Answer'),
            ),
          ),

        // Explanation (shown after submit)
        if (_hasSubmitted && mcq.explanation != null) ...[
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline,
                        size: 18, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Explanation',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  mcq.explanation!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade900,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOptionTile(int index, McqOption option, int? correctIndex) {
    final isSelected = _selectedOption == index;
    final isCorrect = index == correctIndex;
    final showResult = _hasSubmitted;

    Color? backgroundColor;
    Color? borderColor;
    IconData? trailingIcon;

    if (showResult) {
      if (isCorrect) {
        backgroundColor = AppColors.success.withOpacity(0.1);
        borderColor = AppColors.success;
        trailingIcon = Icons.check_circle;
      } else if (isSelected && !isCorrect) {
        backgroundColor = AppColors.error.withOpacity(0.1);
        borderColor = AppColors.error;
        trailingIcon = Icons.cancel;
      }
    } else if (isSelected) {
      backgroundColor = AppColors.primary.withOpacity(0.1);
      borderColor = AppColors.primary;
    }

    return GestureDetector(
      onTap: _hasSubmitted
          ? null
          : () {
              setState(() => _selectedOption = index);
            },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor ?? Colors.grey.shade300,
            width: isSelected || (showResult && isCorrect) ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? (showResult
                        ? (isCorrect
                            ? AppColors.success
                            : AppColors.error)
                        : AppColors.primary)
                    : Colors.grey.shade200,
              ),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + index), // A, B, C, D
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option.text,
                style: TextStyle(
                  fontSize: 15,
                  color: showResult && isCorrect
                      ? AppColors.success
                      : (showResult && isSelected && !isCorrect
                          ? AppColors.error
                          : null),
                ),
              ),
            ),
            if (showResult && trailingIcon != null)
              Icon(
                trailingIcon,
                color: isCorrect ? AppColors.success : AppColors.error,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(int total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        children: [
          // Stats row
          if (_attemptedCount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle,
                      size: 16, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text(
                    '$_correctCount / $_attemptedCount correct',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: _currentIndex > 0
                    ? () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    : null,
              ),
              Text(
                '${_currentIndex + 1} / $total',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios),
                onPressed: _currentIndex < total - 1
                    ? () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
