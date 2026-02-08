import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';

class SchoolsManagementScreen extends ConsumerWidget {
  const SchoolsManagementScreen({super.key});

  static const _accentColor = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Fetch schools from API
    final schools = <Map<String, dynamic>>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schools'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: schools.isEmpty
          ? _buildEmptyState(context)
          : RefreshIndicator(
              onRefresh: () async {
                // TODO: Refresh schools
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: schools.length,
                itemBuilder: (context, index) {
                  final school = schools[index];
                  return _SchoolCard(
                    name: school['name'] ?? '',
                    code: school['code'] ?? '',
                    status: school['status'] ?? 'ACTIVE',
                    teacherCount: school['teacherCount'] ?? 0,
                    studentCount: school['studentCount'] ?? 0,
                    onTap: () => context.push('/super-admin/schools/${school['id']}'),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/super-admin/schools/create'),
        backgroundColor: _accentColor,
        icon: const Icon(Icons.add),
        label: const Text('Create School'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 80,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No schools yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Create your first school to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: () => context.push('/super-admin/schools/create'),
              icon: const Icon(Icons.add),
              label: const Text('Create School'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SchoolCard extends StatelessWidget {
  final String name;
  final String code;
  final String status;
  final int teacherCount;
  final int studentCount;
  final VoidCallback onTap;

  const _SchoolCard({
    required this.name,
    required this.code,
    required this.status,
    required this.teacherCount,
    required this.studentCount,
    required this.onTap,
  });

  Color _getStatusColor() {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return AppColors.success;
      case 'SUSPENDED':
        return AppColors.warning;
      case 'DELETED':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: const Icon(
                  Icons.school,
                  color: Color(0xFF3B82F6),
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      code,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppRadius.chip),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Icon(
                          Icons.person,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$teacherCount teachers',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Icon(
                          Icons.people,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$studentCount students',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
