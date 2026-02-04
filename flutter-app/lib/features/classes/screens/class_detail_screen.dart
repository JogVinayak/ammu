import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/class_models.dart';
import '../providers/classes_provider.dart';

class ClassDetailScreen extends ConsumerStatefulWidget {
  final String classId;

  const ClassDetailScreen({super.key, required this.classId});

  @override
  ConsumerState<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends ConsumerState<ClassDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final classAsync = ref.watch(classDetailProvider(widget.classId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Class Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Students'),
            Tab(text: 'Released Content'),
          ],
        ),
      ),
      body: classAsync.when(
        data: (teacherClass) {
          if (teacherClass == null) {
            return const AppErrorWidget(message: 'Class not found');
          }

          return Column(
            children: [
              _buildClassHeader(context, teacherClass),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildStudentsList(context, teacherClass.students),
                    _buildReleasedContentList(
                        context, teacherClass.releasedContent),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const LoadingIndicator(message: 'Loading class...'),
        error: (error, _) => AppErrorWidget(message: error.toString()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/release?classId=${widget.classId}'),
        icon: const Icon(Icons.publish),
        label: const Text('Release Content'),
      ),
    );
  }

  Widget _buildClassHeader(BuildContext context, TeacherClass teacherClass) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: AppColors.surface,
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: const Icon(
              Icons.school,
              color: AppColors.primary,
              size: 36,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teacherClass.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  '${teacherClass.subject} - ${teacherClass.grade}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    _StatChip(
                      icon: Icons.people,
                      label: '${teacherClass.studentCount} students',
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _StatChip(
                      icon: Icons.description,
                      label: '${teacherClass.releasedContent.length} released',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsList(BuildContext context, List<Student> students) {
    if (students.isEmpty) {
      return const EmptyState(
        icon: Icons.people_outline,
        title: 'No students',
        subtitle: 'Students will appear here when enrolled',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: students.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final student = students[index];
        return AppCard(
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(
                  student.name[0].toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (student.email != null)
                      Text(
                        student.email!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReleasedContentList(
      BuildContext context, List<ReleasedContent> content) {
    if (content.isEmpty) {
      return EmptyState(
        icon: Icons.publish_outlined,
        title: 'No content released',
        subtitle: 'Release notes and mindmaps to this class',
        actionText: 'Release Content',
        onAction: () => context.push('/release?classId=${widget.classId}'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: content.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final item = content[index];
        return AppCard(
          onTap: () {
            if (item.type == 'note') {
              context.push('/notes/${item.id}');
            } else {
              context.push('/mindmaps/${item.id}');
            }
          },
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: (item.type == 'note'
                          ? AppColors.primary
                          : AppColors.secondary)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: Icon(
                  item.type == 'note' ? Icons.description : Icons.account_tree,
                  color: item.type == 'note'
                      ? AppColors.primary
                      : AppColors.secondary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'Released ${_formatDate(item.releasedAt)}',
                      style: Theme.of(context).textTheme.bodySmall,
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
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'today';
    } else if (diff.inDays == 1) {
      return 'yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
