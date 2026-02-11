import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/super_admin_provider.dart';

class SuperAdminDashboardScreen extends ConsumerStatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  ConsumerState<SuperAdminDashboardScreen> createState() => _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends ConsumerState<SuperAdminDashboardScreen> {
  static const _accentColor = Color(0xFFDC2626); // Red for super admin

  @override
  void initState() {
    super.initState();
    // Load data on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(schoolsProvider.notifier).loadSchools();
      ref.read(usersProvider.notifier).loadUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final schoolsState = ref.watch(schoolsProvider);
    final usersState = ref.watch(usersProvider);

    final schoolsCount = schoolsState.schools.length;
    final teachersCount = usersState.allUsers.where((u) => u.isTeacher).length;
    final studentsCount = usersState.allUsers.where((u) => u.isStudent).length;
    final isLoading = schoolsState.isLoading || usersState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(schoolsProvider.notifier).loadSchools();
              ref.read(usersProvider.notifier).loadUsers();
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              ref.read(schoolsProvider.notifier).loadSchools(),
              ref.read(usersProvider.notifier).loadUsers(),
            ]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGreeting(context, user?.name ?? 'Admin'),
                const SizedBox(height: AppSpacing.xs),
                _buildRoleBadge(context),
                const SizedBox(height: AppSpacing.lg),
                _buildStatsGrid(
                  context,
                  schoolsCount: schoolsCount,
                  teachersCount: teachersCount,
                  studentsCount: studentsCount,
                  isLoading: isLoading,
                ),
                const SizedBox(height: AppSpacing.lg),
                _buildQuickActions(context),
                const SizedBox(height: AppSpacing.lg),
                _buildPendingApprovals(context),
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

  Widget _buildRoleBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.admin_panel_settings, size: 16, color: _accentColor),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Super Administrator',
            style: TextStyle(
              color: _accentColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(
    BuildContext context, {
    required int schoolsCount,
    required int teachersCount,
    required int studentsCount,
    required bool isLoading,
  }) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.5,
      children: [
        _StatCard(
          title: 'Schools',
          value: isLoading ? '-' : '$schoolsCount',
          subtitle: 'Total',
          icon: Icons.school,
          iconColor: const Color(0xFF3B82F6), // Blue
          onTap: () => context.go('/super-admin/schools'),
        ),
        _StatCard(
          title: 'Teachers',
          value: isLoading ? '-' : '$teachersCount',
          subtitle: 'Total',
          icon: Icons.person,
          iconColor: const Color(0xFF10B981), // Green
          onTap: () => context.push('/super-admin/users'),
        ),
        _StatCard(
          title: 'Students',
          value: isLoading ? '-' : '$studentsCount',
          subtitle: 'Total',
          icon: Icons.people,
          iconColor: const Color(0xFF8B5CF6), // Purple
          onTap: () => context.push('/super-admin/users'),
        ),
        _StatCard(
          title: 'Pending',
          value: '0', // TODO: Fetch pending approvals count
          subtitle: 'Approvals',
          icon: Icons.pending_actions,
          iconColor: const Color(0xFFF59E0B), // Amber
          onTap: () => context.go('/super-admin/approvals'),
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
                icon: Icons.add_business,
                label: 'Create\nSchool',
                onTap: () => context.push('/super-admin/schools/create'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.fact_check,
                label: 'Review\nContent',
                onTap: () => context.go('/super-admin/approvals'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.people,
                label: 'Manage\nUsers',
                onTap: () => context.push('/super-admin/users'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.admin_panel_settings,
                label: 'Permissions',
                onTap: () => context.push('/super-admin/permissions'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                icon: Icons.security,
                label: 'Manage\nRoles',
                onTap: () => context.push('/super-admin/roles'),
              ),
            ),
            const Spacer(flex: 3),
          ],
        ),
      ],
    );
  }

  Widget _buildPendingApprovals(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pending Approvals',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            TextButton(
              onPressed: () => context.go('/super-admin/approvals'),
              child: Text(
                'See All',
                style: TextStyle(color: _accentColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 48,
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'No pending approvals',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Content awaiting your review will appear here',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: iconColor,
                      ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
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
    const accentColor = Color(0xFFDC2626);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: Icon(
              icon,
              color: accentColor,
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
