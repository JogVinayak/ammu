import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../data/flashcard_models.dart';
import '../providers/flashcard_provider.dart';

class FlashcardViewerDialog extends ConsumerStatefulWidget {
  final String noteId;
  final String noteTitle;

  const FlashcardViewerDialog({
    super.key,
    required this.noteId,
    required this.noteTitle,
  });

  @override
  ConsumerState<FlashcardViewerDialog> createState() =>
      _FlashcardViewerDialogState();
}

class _FlashcardViewerDialogState extends ConsumerState<FlashcardViewerDialog> {
  int _currentIndex = 0;
  bool _showingFront = true;
  late PageController _pageController;
  String? _difficultyFilter;

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
    final flashcardsAsync = ref.watch(flashcardsProvider(widget.noteId));

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
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
              child: flashcardsAsync.when(
                data: (flashcards) {
                  final filtered = _difficultyFilter != null
                      ? flashcards
                          .where((f) =>
                              f.difficulty.toUpperCase() ==
                              _difficultyFilter!.toUpperCase())
                          .toList()
                      : flashcards;
                  return filtered.isEmpty
                      ? _buildEmptyState()
                      : _buildFlashcardStack(filtered);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Error: $e'),
                  ),
                ),
              ),
            ),
            flashcardsAsync.maybeWhen(
              data: (flashcards) {
                final filtered = _difficultyFilter != null
                    ? flashcards
                        .where((f) =>
                            f.difficulty.toUpperCase() ==
                            _difficultyFilter!.toUpperCase())
                        .toList()
                    : flashcards;
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
              const Icon(Icons.style, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Flashcards',
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
          // Difficulty filter chips (deck selection)
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
          _showingFront = true;
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
          Icon(Icons.style_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _difficultyFilter != null
                ? 'No ${_getDifficultyLabel(_difficultyFilter!)} flashcards'
                : 'No flashcards yet',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Flashcards for this note will appear here',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary.withAlpha(180),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashcardStack(List<Flashcard> flashcards) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentIndex = index;
          _showingFront = true;
        });
      },
      itemCount: flashcards.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: FlipCard(
            flashcard: flashcards[index],
            showFront: index == _currentIndex ? _showingFront : true,
            onFlip: () {
              if (index == _currentIndex) {
                setState(() => _showingFront = !_showingFront);
              }
            },
          ),
        );
      },
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
      child: Row(
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
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${_currentIndex + 1} / $total',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap card to flip',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
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
    );
  }
}

class FlipCard extends StatefulWidget {
  final Flashcard flashcard;
  final bool showFront;
  final VoidCallback onFlip;

  const FlipCard({
    super.key,
    required this.flashcard,
    required this.showFront,
    required this.onFlip,
  });

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _showFrontSide = true;

  @override
  void initState() {
    super.initState();
    _showFrontSide = widget.showFront;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(FlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showFront != _showFrontSide) {
      _flip();
    }
  }

  void _flip() {
    if (_showFrontSide) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    _showFrontSide = !_showFrontSide;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
    return GestureDetector(
      onTap: widget.onFlip,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * pi;
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle);

          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: angle < pi / 2
                ? _buildSide(
                    text: widget.flashcard.frontText,
                    label: 'Question',
                    color: AppColors.primary,
                    showDifficulty: true,
                  )
                : Transform(
                    transform: Matrix4.identity()..rotateY(pi),
                    alignment: Alignment.center,
                    child: _buildSide(
                      text: widget.flashcard.backText,
                      label: 'Answer',
                      color: AppColors.success,
                      showDifficulty: false,
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildSide({
    required String text,
    required String label,
    required Color color,
    bool showDifficulty = false,
  }) {
    final difficulty = widget.flashcard.difficulty;
    final difficultyColor = _getDifficultyColor(difficulty);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(80), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                if (showDifficulty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: difficultyColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getDifficultyLabel(difficulty),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: difficultyColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    height: 1.5,
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

/// AnimatedBuilder helper for building widgets based on animation value
class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) => builder(context, child);
}
