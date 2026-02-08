import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';

class SuperAdminShell extends StatelessWidget {
  final Widget child;

  const SuperAdminShell({super.key, required this.child});

  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/super-admin/dashboard')) return 0;
    if (location.startsWith('/super-admin/schools')) return 1;
    if (location.startsWith('/super-admin/approvals')) return 2;
    if (location.startsWith('/super-admin/profile')) return 3;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/super-admin/dashboard');
        break;
      case 1:
        context.go('/super-admin/schools');
        break;
      case 2:
        context.go('/super-admin/approvals');
        break;
      case 3:
        context.go('/super-admin/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: SuperAdminBottomNavBar(
        currentIndex: _getSelectedIndex(context),
        onTap: (index) => _onItemTapped(context, index),
      ),
    );
  }
}

class SuperAdminBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const SuperAdminBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SuperAdminNavItem(
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard,
                label: 'Dashboard',
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _SuperAdminNavItem(
                icon: Icons.school_outlined,
                activeIcon: Icons.school,
                label: 'Schools',
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _SuperAdminNavItem(
                icon: Icons.fact_check_outlined,
                activeIcon: Icons.fact_check,
                label: 'Approvals',
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _SuperAdminNavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profile',
                isActive: currentIndex == 3,
                onTap: () => onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuperAdminNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SuperAdminNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Using red/crimson accent for super admin UI
    const activeColor = Color(0xFFDC2626);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? activeColor : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? activeColor : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
