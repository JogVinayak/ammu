import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    final recentContent = ref.watch(recentContentProvider);
    final isLoading = ref.watch(dashboardLoadingProvider);
    final error = ref.watch(dashboardErrorProvider);
    final userName = ref.watch(userNameProvider);
    final refresh = ref.watch(dashboardRefreshProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: refresh,
          child: isLoading
              ? const LoadingIndicator(message: 'Loading dashboard...')
              : error != null
                  ? AppErrorWidget(
                      message: error,
                      onRetry: refresh,
                    )
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildGreeting(context, userName),
                          const SizedBox(height: AppSpacing.lg),
                          _buildStatsGrid(context, stats),
                          const SizedBox(height: AppSpacing.lg),
                          _buildQuickActions(context),
                          const SizedBox(height: AppSpacing.lg),
                          _buildRecentContent(context, recentContent),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildGreeting(BuildContext context, String userName) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        Text(
          'Hello, $userName',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context, DashboardStats stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.4,
      children: [
        StatsCard(
          title: 'My Notes',
          value: stats.myNotes.toString(),
          icon: Icons.description,
          iconColor: AppColors.primary,
          onTap: () => context.go('/content?tab=notes'),
        ),
        StatsCard(
          title: 'My Mindmaps',
          value: stats.myMindmaps.toString(),
          icon: Icons.account_tree,
          iconColor: AppColors.secondary,
          onTap: () => context.go('/content?tab=mindmaps'),
        ),
        StatsCard(
          title: 'Classes',
          value: stats.classes.toString(),
          icon: Icons.school,
          iconColor: AppColors.warning,
          onTap: () => context.go('/classes'),
        ),
        StatsCard(
          title: 'Released',
          value: stats.released.toString(),
          icon: Icons.publish,
          iconColor: AppColors.success,
          onTap: () => context.push('/release-history'),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                icon: Icons.folder_open,
                label: 'Browse\nRepository',
                onTap: () => context.go('/repository'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.note_add,
                label: 'Create\nNote',
                onTap: () => context.push('/notes/create'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.add_chart,
                label: 'Create\nMindmap',
                onTap: () => context.push('/mindmaps/create'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentContent(
      BuildContext context, List<RecentContent> content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Content',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            TextButton(
              onPressed: () => context.go('/content'),
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (content.isEmpty)
          const EmptyState(
            icon: Icons.content_paste_off,
            title: 'No recent content',
            subtitle: 'Your recent notes and mindmaps will appear here',
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: content.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final item = content[index];
              return _RecentContentTile(
                content: item,
                onTap: () {
                  if (item.type == 'note') {
                    context.push('/notes/${item.id}');
                  } else {
                    context.push('/mindmaps/${item.id}');
                  }
                },
              );
            },
          ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

class _RecentContentTile extends StatelessWidget {
  final RecentContent content;
  final VoidCallback onTap;

  const _RecentContentTile({
    required this.content,
    required this.onTap,
  });

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PUBLISHED':
      case 'RELEASED':
        return AppColors.success;
      case 'DRAFT':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: (content.type == 'note'
                      ? AppColors.primary
                      : AppColors.secondary)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: Icon(
              content.type == 'note' ? Icons.description : Icons.account_tree,
              color: content.type == 'note'
                  ? AppColors.primary
                  : AppColors.secondary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content.title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(content.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                      ),
                      child: Text(
                        content.status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(content.status),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      _formatTime(content.updatedAt),
                      style: Theme.of(context).textTheme.bodySmall,
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
    );
  }
}
