import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../../classes/providers/classes_provider.dart';
import '../../notes/data/note_models.dart';
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
  // Map of contentId -> list of class names it's released to
  Map<String, List<String>>? _releaseMap;
  bool _loadingHistory = false;

  @override
  void initState() {
    super.initState();
    if (widget.contentId != null) {
      _selectedContent.add(widget.contentId!);
    }
    if (widget.classId != null) {
      _selectedClasses.add(widget.classId!);
    }
    _loadReleaseHistory();
  }

  Future<void> _loadReleaseHistory() async {
    setState(() => _loadingHistory = true);
    try {
      final repo = ref.read(workflowRepositoryProvider);
      final history = await repo.getReleaseHistory(size: 100);
      final map = <String, List<String>>{};
      for (final item in history) {
        map.putIfAbsent(item.contentId, () => []);
        if (item.className.isNotEmpty && !map[item.contentId]!.contains(item.className)) {
          map[item.contentId]!.add(item.className);
        }
      }
      if (mounted) {
        setState(() {
          _releaseMap = map;
          _loadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingHistory = false);
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
        final releasedTo = _releaseMap?[item.id];
        final typeLabel = item.type == 'note' ? 'Note' : 'Mindmap';
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
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(typeLabel),
              if (releasedTo != null && releasedTo.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'Released to: ${releasedTo.join(", ")}',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
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

    if (classesState.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (classesState.error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Column(
          children: [
            Text('Error loading classes: ${classesState.error}'),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              text: 'Retry',
              variant: AppButtonVariant.outline,
              onPressed: () => ref.read(classesProvider.notifier).refresh(),
            ),
          ],
        ),
      );
    }

    if (classesState.classes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Column(
          children: [
            const Text('No classes available'),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              text: 'Refresh',
              variant: AppButtonVariant.outline,
              onPressed: () => ref.read(classesProvider.notifier).refresh(),
            ),
          ],
        ),
      );
    }

    return Column(
      children: classesState.classes.map((cls) {
        final clsId = cls['id']?.toString() ?? '';
        final clsName = cls['name']?.toString() ?? 'Unnamed';
        final clsGrade = cls['grade']?.toString() ?? '';
        final divisions = (cls['divisions'] as List?)?.length ?? 0;
        final isSelected = _selectedClasses.contains(clsId);
        return CheckboxListTile(
          value: isSelected,
          onChanged: (value) {
            setState(() {
              if (value == true) {
                _selectedClasses.add(clsId);
              } else {
                _selectedClasses.remove(clsId);
              }
            });
          },
          title: Text(clsName),
          subtitle: Text('Grade $clsGrade - $divisions divisions'),
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
        .where((c) => _selectedClasses.contains(c['id']?.toString()))
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
                  Text(c['name']?.toString() ?? 'Unnamed'),
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
      // Refresh classes when moving to step 2
      ref.read(classesProvider.notifier).refresh();
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
      final workflowRepository = ref.read(workflowRepositoryProvider);
      final notesNotifier = ref.read(notesProvider.notifier);

      // Release notes
      final notesState = ref.read(notesProvider);
      final selectedNoteIds = _selectedContent
          .where((id) => notesState.notes.any((n) => n.id == id))
          .toList();

      if (selectedNoteIds.isNotEmpty) {
        // Auto mark-ready any notes that aren't already READY or RELEASED
        for (final noteId in selectedNoteIds) {
          final note = notesState.notes.firstWhere((n) => n.id == noteId);
          if (note.status == NoteStatus.draft || note.status == NoteStatus.inReview) {
            try {
              await notesNotifier.markReady(noteId);
              print('DEBUG: Auto marked note $noteId as READY');
            } catch (e) {
              print('DEBUG: Failed to mark note $noteId ready: $e');
            }
          }
        }

        // Create release record in workflow service
        await workflowRepository.releaseContent(ReleaseRequest(
          contentIds: selectedNoteIds,
          classIds: _selectedClasses.toList(),
          contentType: 'note',
        ));

        // Update note status in notes service
        for (final noteId in selectedNoteIds) {
          try {
            await notesNotifier.releaseNote(noteId, classIds: _selectedClasses.toList());
          } catch (e) {
            print('DEBUG: Failed to update note $noteId status: $e');
          }
        }
      }

      // Release mindmaps
      final mindmapsState = ref.read(mindmapsProvider);
      final selectedMindmapIds = _selectedContent
          .where((id) => mindmapsState.mindmaps.any((m) => m.id == id))
          .toList();

      if (selectedMindmapIds.isNotEmpty) {
        await workflowRepository.releaseContent(ReleaseRequest(
          contentIds: selectedMindmapIds,
          classIds: _selectedClasses.toList(),
          contentType: 'mindmap',
        ));
      }

      // Refresh notes and mindmaps to ensure UI is in sync
      await ref.read(notesProvider.notifier).refresh();
      ref.read(mindmapsProvider.notifier).refresh();

      // Refresh release history to show updated release info
      await _loadReleaseHistory();

      if (mounted) {
        final classesState = ref.read(classesProvider);
        final releasedClassNames = classesState.classes
            .where((c) => _selectedClasses.contains(c['id']?.toString()))
            .map((c) => c['name']?.toString() ?? 'Unnamed')
            .toList();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Released to: ${releasedClassNames.join(", ")}',
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
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
