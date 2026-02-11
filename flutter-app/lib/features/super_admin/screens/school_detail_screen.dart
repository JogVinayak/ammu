import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/super_admin_models.dart';
import '../providers/super_admin_provider.dart';

class SchoolDetailScreen extends ConsumerStatefulWidget {
  final String schoolId;

  const SchoolDetailScreen({super.key, required this.schoolId});

  @override
  ConsumerState<SchoolDetailScreen> createState() =>
      _SchoolDetailScreenState();
}

class _SchoolDetailScreenState extends ConsumerState<SchoolDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure schools are loaded (they might already be from the list screen)
    final state = ref.read(schoolsProvider);
    if (state.schools.isEmpty) {
      Future.microtask(
        () => ref.read(schoolsProvider.notifier).loadSchools(),
      );
    }
  }

  School? _findSchool(SchoolsState state) {
    try {
      return state.schools.firstWhere((s) => s.id == widget.schoolId);
    } catch (_) {
      return null;
    }
  }

  void _handleMenuAction(String action, School school) {
    switch (action) {
      case 'suspend':
        _showSuspendConfirmation(school);
        break;
      case 'activate':
        _showActivateConfirmation(school);
        break;
      case 'delete':
        _showDeleteConfirmation(school);
        break;
    }
  }

  void _showSuspendConfirmation(School school) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Suspend School'),
        content: Text(
          'Are you sure you want to suspend "${school.name}"? Users will not be able to access this school.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref
                  .read(schoolsProvider.notifier)
                  .suspendSchool(school.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? '${school.name} suspended'
                          : 'Failed to suspend school',
                    ),
                    backgroundColor:
                        success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.warning),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );
  }

  void _showActivateConfirmation(School school) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Activate School'),
        content: Text(
          'Are you sure you want to activate "${school.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref
                  .read(schoolsProvider.notifier)
                  .activateSchool(school.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? '${school.name} activated'
                          : 'Failed to activate school',
                    ),
                    backgroundColor:
                        success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.success),
            child: const Text('Activate'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(School school) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete School'),
        content: Text(
          'Are you sure you want to delete "${school.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref
                  .read(schoolsProvider.notifier)
                  .deleteSchool(school.id);
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${school.name} deleted'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  context.pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to delete school'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(schoolsProvider);
    final school = _findSchool(state);

    if (state.isLoading && school == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('School Details'), centerTitle: true),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (school == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('School Details'), centerTitle: true),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 64, color: AppColors.error.withValues(alpha: 0.7)),
              const SizedBox(height: AppSpacing.lg),
              const Text('School not found'),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final isSuspended = school.status.toUpperCase() == 'SUSPENDED';

    return Scaffold(
      appBar: AppBar(
        title: Text(school.name),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value, school),
            itemBuilder: (context) => [
              if (isSuspended)
                const PopupMenuItem(
                  value: 'activate',
                  child: Row(
                    children: [
                      Icon(Icons.play_circle_outline,
                          color: AppColors.success),
                      SizedBox(width: 8),
                      Text('Activate School'),
                    ],
                  ),
                )
              else
                const PopupMenuItem(
                  value: 'suspend',
                  child: Row(
                    children: [
                      Icon(Icons.pause_circle_outline,
                          color: AppColors.warning),
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
            _buildInfoSection(context, school),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolHeader(BuildContext context, School school) {
    final statusColor = _getStatusColor(school.status);

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
                    school.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    school.tenantKey,
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
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                    ),
                    child: Text(
                      school.status,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
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

  Widget _buildInfoSection(BuildContext context, School school) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            _InfoRow(label: 'School ID', value: school.id),
            const Divider(height: AppSpacing.lg),
            _InfoRow(label: 'Tenant Key', value: school.tenantKey),
            const Divider(height: AppSpacing.lg),
            _InfoRow(label: 'Status', value: school.status),
            if (school.createdAt != null) ...[
              const Divider(height: AppSpacing.lg),
              _InfoRow(
                label: 'Created',
                value: _formatDate(school.createdAt!),
              ),
            ],
            if (school.updatedAt != null) ...[
              const Divider(height: AppSpacing.lg),
              _InfoRow(
                label: 'Last Updated',
                value: _formatDate(school.updatedAt!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
    );
  }
}
