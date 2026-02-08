import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';

class SchoolDetailScreen extends ConsumerWidget {
  final String schoolId;

  const SchoolDetailScreen({super.key, required this.schoolId});

  static const _accentColor = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Fetch school details from API
    final school = <String, dynamic>{
      'name': 'Sample School',
      'code': 'SAMPLE001',
      'status': 'ACTIVE',
      'teacherCount': 0,
      'studentCount': 0,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(school['name'] ?? 'School Details'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              // TODO: Handle menu actions
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Edit School'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'suspend',
                child: Row(
                  children: [
                    Icon(Icons.pause_circle_outline, color: AppColors.warning),
                    SizedBox(width: 8),
                    Text('Suspend School'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Delete School'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSchoolHeader(context, school),
            const SizedBox(height: AppSpacing.lg),
            _buildStatsRow(context, school),
            const SizedBox(height: AppSpacing.lg),
            _buildSectionHeader(context, 'Teachers', () {
              // TODO: Navigate to teachers list
            }),
            const SizedBox(height: AppSpacing.md),
            _buildEmptySection(context, 'No teachers yet', Icons.person_outline),
            const SizedBox(height: AppSpacing.lg),
            _buildSectionHeader(context, 'Students', () {
              // TODO: Navigate to students list
            }),
            const SizedBox(height: AppSpacing.md),
            _buildEmptySection(context, 'No students yet', Icons.people_outline),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Show add user dialog
        },
        backgroundColor: _accentColor,
        icon: const Icon(Icons.person_add),
        label: const Text('Add User'),
      ),
    );
  }

  Widget _buildSchoolHeader(BuildContext context, Map<String, dynamic> school) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: const Icon(
                Icons.school,
                color: Color(0xFF3B82F6),
                size: 32,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    school['name'] ?? '',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    school['code'] ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                    ),
                    child: Text(
                      school['status'] ?? 'ACTIVE',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, Map<String, dynamic> school) {
    return Row(
      children: [
        Expanded(
          child: _StatBox(
            icon: Icons.person,
            label: 'Teachers',
            value: '${school['teacherCount'] ?? 0}',
            color: const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatBox(
            icon: Icons.people,
            label: 'Students',
            value: '${school['studentCount'] ?? 0}',
            color: const Color(0xFF8B5CF6),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, VoidCallback onSeeAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        TextButton(
          onPressed: onSeeAll,
          child: const Text('See All'),
        ),
      ],
    );
  }

  Widget _buildEmptySection(BuildContext context, String message, IconData icon) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Column(
            children: [
              Icon(
                icon,
                size: 40,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
