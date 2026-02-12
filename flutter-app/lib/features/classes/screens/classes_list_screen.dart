import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/classes_provider.dart';

class ClassesListScreen extends ConsumerWidget {
  const ClassesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(classesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Classes'),
      ),
      body: state.isLoading
          ? const LoadingIndicator(message: 'Loading classes...')
          : state.error != null
              ? AppErrorWidget(
                  message: state.error!,
                  onRetry: () => ref.read(classesProvider.notifier).refresh(),
                )
              : state.classes.isEmpty
                  ? const EmptyState(
                      icon: Icons.school_outlined,
                      title: 'No classes assigned',
                      subtitle: 'Classes you teach will appear here',
                    )
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(classesProvider.notifier).refresh(),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: state.classes.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final cls = state.classes[index];
                          return _ClassCard(
                            classData: cls,
                            classesState: state,
                          );
                        },
                      ),
                    ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final Map<String, dynamic> classData;
  final ClassesState classesState;

  const _ClassCard({
    required this.classData,
    required this.classesState,
  });

  @override
  Widget build(BuildContext context) {
    final name = classData['name']?.toString() ?? 'Unnamed';
    final grade = classData['grade']?.toString() ?? '';
    final divisions = (classData['divisions'] as List?) ?? [];
    final teachers = (classData['teachers'] as List?) ?? [];

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        childrenPadding: const EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          bottom: AppSpacing.md,
        ),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          child: const Icon(
            Icons.school,
            color: AppColors.primary,
            size: 28,
          ),
        ),
        title: Text(
          name,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        subtitle: Row(
          children: [
            if (grade.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: Text(
                  'Grade $grade',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Text(
              '${divisions.length} division${divisions.length != 1 ? 's' : ''}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        children: [
          // Teacher chips
          if (teachers.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Teachers',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: teachers.map((t) {
                  final role = (t is Map ? t['role']?.toString() : null) ?? '';
                  final subject =
                      (t is Map ? t['subject']?.toString() : null) ?? '';
                  final label =
                      subject.isNotEmpty ? '$role ($subject)' : role;
                  return Chip(
                    label: Text(label, style: const TextStyle(fontSize: 11)),
                    avatar: const Icon(Icons.person, size: 16),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Divisions list
          if (divisions.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Divisions',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            ...divisions.map((div) {
              final divId = (div is Map ? div['id']?.toString() : null) ?? '';
              final divName = (div is Map
                      ? (div['displayName']?.toString() ??
                          div['name']?.toString())
                      : null) ??
                  'Division';
              final studentCount =
                  classesState.studentCountForDivision(divId);

              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.groups_outlined,
                    color: AppColors.secondary,
                    size: 20,
                  ),
                ),
                title: Text(divName),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                      ),
                      child: Text(
                        '$studentCount student${studentCount != 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right,
                        size: 20, color: AppColors.textSecondary),
                  ],
                ),
                onTap: () {
                  final classId = classData['id']?.toString() ?? '';
                  context.push(
                    '/classes/$classId/divisions/$divId?name=${Uri.encodeComponent(divName)}',
                  );
                },
              );
            }),
          ] else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                'No divisions yet',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
        ],
      ),
    );
  }
}
