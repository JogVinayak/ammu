import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/student_provider.dart';

class StudentClassScreen extends ConsumerWidget {
  const StudentClassScreen({super.key});

  static const _accentColor = Color(0xFF14B8A6);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(studentProfileProvider);
    final user = ref.watch(currentUserProvider);
    final profile = profileState.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Class'),
        centerTitle: true,
      ),
      body: profileState.isLoading
          ? const LoadingIndicator(message: 'Loading class info...')
          : profileState.error != null
              ? AppErrorWidget(
                  message: profileState.error!,
                  onRetry: () {
                    ref.read(studentProfileProvider.notifier).loadProfile();
                  },
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    ref.read(studentProfileProvider.notifier).loadProfile();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildClassInfoCard(context, profile),
                        const SizedBox(height: AppSpacing.lg),
                        _buildStudentInfoCard(context, profile, user),
                        const SizedBox(height: AppSpacing.lg),
                        _buildClassmatesSection(context),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildClassInfoCard(BuildContext context, dynamic profile) {
    final className = profile?.className ??
        'Grade ${profile?.grade ?? '?'} - Section ${profile?.section ?? '?'}';

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                  child: Icon(
                    Icons.school,
                    color: _accentColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        className,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      Text(
                        'General Studies',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentInfoCard(
      BuildContext context, dynamic profile, dynamic user) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            _InfoRow(label: 'Name', value: user?.name ?? '-'),
            _InfoRow(label: 'Grade', value: profile?.grade ?? '-'),
            _InfoRow(label: 'Section', value: profile?.section ?? '-'),
            _InfoRow(label: 'Roll Number', value: profile?.rollNumber ?? '-'),
            if (profile?.board != null)
              _InfoRow(label: 'Board', value: profile!.board!),
          ],
        ),
      ),
    );
  }

  Widget _buildClassmatesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Classmates',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Icon(
                  Icons.group_outlined,
                  size: 48,
                  color: AppColors.textSecondary.withOpacity(0.5),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Coming soon',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                Text(
                  'Classmate list will be available here',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}
