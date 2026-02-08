import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/providers/auth_provider.dart';

class SuperAdminProfileScreen extends ConsumerWidget {
  const SuperAdminProfileScreen({super.key});

  static const _accentColor = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            _buildProfileHeader(context, user),
            const SizedBox(height: AppSpacing.lg),
            _buildMenuSection(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, dynamic user) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: _accentColor.withOpacity(0.1),
              child: user?.avatar != null
                  ? ClipOval(
                      child: Image.network(
                        user!.avatar!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.admin_panel_settings,
                          size: 50,
                          color: _accentColor,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.admin_panel_settings,
                      size: 50,
                      color: _accentColor,
                    ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              user?.name ?? 'Super Admin',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              user?.email ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: _accentColor.withOpacity(0.1),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            children: [
              _MenuItem(
                icon: Icons.settings,
                title: 'App Settings',
                onTap: () => context.push('/settings'),
              ),
              const Divider(height: 1),
              _MenuItem(
                icon: Icons.lock_outline,
                title: 'Change Password',
                onTap: () {
                  // TODO: Navigate to change password
                },
              ),
              const Divider(height: 1),
              _MenuItem(
                icon: Icons.history,
                title: 'Activity Log',
                onTap: () {
                  // TODO: Navigate to activity log
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Support',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            children: [
              _MenuItem(
                icon: Icons.help_outline,
                title: 'Help & Support',
                onTap: () {
                  // TODO: Navigate to help
                },
              ),
              const Divider(height: 1),
              _MenuItem(
                icon: Icons.info_outline,
                title: 'About',
                onTap: () {
                  // TODO: Show about dialog
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ref.read(authProvider.notifier).logout();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                      ),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.logout, color: AppColors.error),
            label: const Text(
              'Logout',
              style: TextStyle(color: AppColors.error),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
