import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/classes_provider.dart';

class DivisionStudentsScreen extends ConsumerWidget {
  final String classId;
  final String divisionId;
  final String divisionName;

  const DivisionStudentsScreen({
    super.key,
    required this.classId,
    required this.divisionId,
    required this.divisionName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(classesProvider);
    final students = state.studentsForDivision(divisionId);

    return Scaffold(
      appBar: AppBar(
        title: Text(divisionName),
      ),
      body: state.isLoading
          ? const LoadingIndicator(message: 'Loading students...')
          : students.isEmpty
              ? const EmptyState(
                  icon: Icons.people_outline,
                  title: 'No students',
                  subtitle: 'No students assigned to this division yet',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: students.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return _StudentCard(student: student);
                  },
                ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final Map<String, dynamic> student;

  const _StudentCard({required this.student});

  @override
  Widget build(BuildContext context) {
    final displayName =
        student['displayName']?.toString() ?? student['name']?.toString() ?? 'Student';
    final email = student['email']?.toString() ?? '';
    final initials = _getInitials(displayName);

    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(
              initials,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    email,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
