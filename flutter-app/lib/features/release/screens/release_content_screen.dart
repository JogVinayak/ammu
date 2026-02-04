import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../../classes/providers/classes_provider.dart';
import '../../notes/providers/notes_provider.dart';
import '../../mindmaps/providers/mindmaps_provider.dart';
import '../data/workflow_repository.dart';

class ReleaseContentScreen extends ConsumerStatefulWidget {
  final String? contentId;
  final String? contentType;
  final String? classId;

  const ReleaseContentScreen({
    super.key,
    this.contentId,
    this.contentType,
    this.classId,
  });

  @override
  ConsumerState<ReleaseContentScreen> createState() =>
      _ReleaseContentScreenState();
}

class _ReleaseContentScreenState extends ConsumerState<ReleaseContentScreen> {
  int _currentStep = 0;
  final Set<String> _selectedContent = {};
  final Set<String> _selectedClasses = {};
  bool _isReleasing = false;

  @override
  void initState() {
    super.initState();
    if (widget.contentId != null) {
      _selectedContent.add(widget.contentId!);
    }
    if (widget.classId != null) {
      _selectedClasses.add(widget.classId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Release Content'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: _onStepContinue,
        onStepCancel: _onStepCancel,
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Row(
              children: [
                if (_currentStep < 2)
                  AppButton(
                    text: 'Continue',
                    onPressed: details.onStepContinue,
                  )
                else
                  AppButton(
                    text: 'Release',
                    isLoading: _isReleasing,
                    onPressed: details.onStepContinue,
                  ),
                const SizedBox(width: AppSpacing.md),
                if (_currentStep > 0)
                  AppButton(
                    text: 'Back',
                    variant: AppButtonVariant.outline,
                    onPressed: details.onStepCancel,
                  ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Select Content'),
            subtitle: Text('${_selectedContent.length} selected'),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            content: _buildContentSelection(),
          ),
          Step(
            title: const Text('Select Classes'),
            subtitle: Text('${_selectedClasses.length} selected'),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            content: _buildClassSelection(),
          ),
          Step(
            title: const Text('Confirm'),
            subtitle: const Text('Review and release'),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.indexed,
            content: _buildConfirmation(),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSelection() {
    final notesState = ref.watch(notesProvider);
    final mindmapsState = ref.watch(mindmapsProvider);

    final allContent = [
      ...notesState.notes.map((n) => _ContentItem(
            id: n.id,
            title: n.title,
            type: 'note',
          )),
      ...mindmapsState.mindmaps.map((m) => _ContentItem(
            id: m.id,
            title: m.title,
            type: 'mindmap',
          )),
    ];

    if (allContent.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Text('No content available to release'),
      );
    }

    return Column(
      children: allContent.map((item) {
        final isSelected = _selectedContent.contains(item.id);
        return CheckboxListTile(
          value: isSelected,
          onChanged: (value) {
            setState(() {
              if (value == true) {
                _selectedContent.add(item.id);
              } else {
                _selectedContent.remove(item.id);
              }
            });
          },
          title: Text(item.title),
          subtitle: Text(item.type == 'note' ? 'Note' : 'Mindmap'),
          secondary: Icon(
            item.type == 'note' ? Icons.description : Icons.account_tree,
            color:
                item.type == 'note' ? AppColors.primary : AppColors.secondary,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildClassSelection() {
    final classesState = ref.watch(classesProvider);

    if (classesState.classes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Text('No classes available'),
      );
    }

    return Column(
      children: classesState.classes.map((cls) {
        final isSelected = _selectedClasses.contains(cls.id);
        return CheckboxListTile(
          value: isSelected,
          onChanged: (value) {
            setState(() {
              if (value == true) {
                _selectedClasses.add(cls.id);
              } else {
                _selectedClasses.remove(cls.id);
              }
            });
          },
          title: Text(cls.name),
          subtitle: Text('${cls.subject} - ${cls.studentCount} students'),
          secondary: const Icon(
            Icons.school,
            color: AppColors.primary,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildConfirmation() {
    final notesState = ref.watch(notesProvider);
    final mindmapsState = ref.watch(mindmapsProvider);
    final classesState = ref.watch(classesProvider);

    final selectedNotes = notesState.notes
        .where((n) => _selectedContent.contains(n.id))
        .toList();
    final selectedMindmaps = mindmapsState.mindmaps
        .where((m) => _selectedContent.contains(m.id))
        .toList();
    final selectedClasses = classesState.classes
        .where((c) => _selectedClasses.contains(c.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Content to release:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        ...selectedNotes.map((n) => Padding(
              padding: const EdgeInsets.only(left: AppSpacing.md),
              child: Row(
                children: [
                  const Icon(Icons.description, size: 16, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Text(n.title),
                ],
              ),
            )),
        ...selectedMindmaps.map((m) => Padding(
              padding: const EdgeInsets.only(left: AppSpacing.md),
              child: Row(
                children: [
                  const Icon(Icons.account_tree,
                      size: 16, color: AppColors.secondary),
                  const SizedBox(width: AppSpacing.sm),
                  Text(m.title),
                ],
              ),
            )),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Classes:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        ...selectedClasses.map((c) => Padding(
              padding: const EdgeInsets.only(left: AppSpacing.md),
              child: Row(
                children: [
                  const Icon(Icons.school, size: 16, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Text('${c.name} (${c.studentCount} students)'),
                ],
              ),
            )),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'This will make the selected content available to all students in the selected classes.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _onStepContinue() {
    if (_currentStep == 0) {
      if (_selectedContent.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one content item'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      setState(() => _currentStep++);
    } else if (_currentStep == 1) {
      if (_selectedClasses.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one class'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      setState(() => _currentStep++);
    } else if (_currentStep == 2) {
      _releaseContent();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _releaseContent() async {
    setState(() => _isReleasing = true);

    try {
      final repository = ref.read(workflowRepositoryProvider);

      // Release notes
      final notesState = ref.read(notesProvider);
      final selectedNoteIds = _selectedContent
          .where((id) => notesState.notes.any((n) => n.id == id))
          .toList();

      if (selectedNoteIds.isNotEmpty) {
        await repository.releaseContent(ReleaseRequest(
          contentIds: selectedNoteIds,
          classIds: _selectedClasses.toList(),
          contentType: 'note',
        ));
      }

      // Release mindmaps
      final mindmapsState = ref.read(mindmapsProvider);
      final selectedMindmapIds = _selectedContent
          .where((id) => mindmapsState.mindmaps.any((m) => m.id == id))
          .toList();

      if (selectedMindmapIds.isNotEmpty) {
        await repository.releaseContent(ReleaseRequest(
          contentIds: selectedMindmapIds,
          classIds: _selectedClasses.toList(),
          contentType: 'mindmap',
        ));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Content released successfully!'),
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
        setState(() => _isReleasing = false);
      }
    }
  }
}

class _ContentItem {
  final String id;
  final String title;
  final String type;

  _ContentItem({
    required this.id,
    required this.title,
    required this.type,
  });
}
