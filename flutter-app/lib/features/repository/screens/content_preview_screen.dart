import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';

class ContentPreviewScreen extends ConsumerStatefulWidget {
  final String contentId;

  const ContentPreviewScreen({super.key, required this.contentId});

  @override
  ConsumerState<ContentPreviewScreen> createState() =>
      _ContentPreviewScreenState();
}

class _ContentPreviewScreenState extends ConsumerState<ContentPreviewScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _content;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isLoading = false;
      _content = {
        'id': widget.contentId,
        'title': 'Introduction to Mathematics',
        'author': 'John Smith',
        'createdAt': DateTime.now().subtract(const Duration(days: 5)),
        'tags': ['Math', 'Grade 6', 'Basics'],
        'content': '''
# Introduction to Mathematics

Mathematics is the study of numbers, shapes, and patterns. It helps us understand the world around us.

## Basic Concepts

### Numbers
- Natural numbers: 1, 2, 3, 4, ...
- Whole numbers: 0, 1, 2, 3, ...
- Integers: ..., -2, -1, 0, 1, 2, ...

### Operations
1. **Addition** (+): Combining two or more numbers
2. **Subtraction** (-): Finding the difference between numbers
3. **Multiplication** (×): Repeated addition
4. **Division** (÷): Splitting into equal parts

## Formulas

The area of a rectangle: `A = length × width`

The perimeter of a rectangle: `P = 2(length + width)`

## Practice Problems

1. Calculate: 15 + 27 = ?
2. Find: 100 - 45 = ?
3. Solve: 8 × 7 = ?
4. Divide: 72 ÷ 9 = ?

> "Mathematics is the queen of sciences." - Carl Friedrich Gauss
''',
      };
    });
  }

  void _copyToMyNotes() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Copy to My Notes'),
        content: Text(
            'Do you want to copy "${_content?['title']}" to your notes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Copied to your notes'),
                  backgroundColor: AppColors.success,
                ),
              );
              context.pop();
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading content...')
          : _content == null
              ? const AppErrorWidget(message: 'Content not found')
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _content!['title'],
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            _content!['author'],
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '${(_content!['createdAt'] as DateTime).day}/${(_content!['createdAt'] as DateTime).month}/${(_content!['createdAt'] as DateTime).year}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: (_content!['tags'] as List)
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
                      const SizedBox(height: AppSpacing.lg),
                      const Divider(),
                      const SizedBox(height: AppSpacing.md),
                      MarkdownBody(
                        data: _content!['content'],
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
                          blockquote: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ),
                      const SizedBox(height: 80), // Space for FAB
                    ],
                  ),
                ),
      floatingActionButton: _content != null
          ? FloatingActionButton.extended(
              onPressed: _copyToMyNotes,
              icon: const Icon(Icons.copy),
              label: const Text('Copy to My Notes'),
            )
          : null,
    );
  }
}
