import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../../super_admin/data/super_admin_models.dart';
import '../providers/admin_roles_provider.dart';

class AdminRolesScreen extends ConsumerStatefulWidget {
  const AdminRolesScreen({super.key});

  @override
  ConsumerState<AdminRolesScreen> createState() => _AdminRolesScreenState();
}

class _AdminRolesScreenState extends ConsumerState<AdminRolesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(adminRolesProvider.notifier).loadRoles(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminRolesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Roles'),
        centerTitle: true,
      ),
      body: state.isLoading && state.roles.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.roles.isEmpty
              ? _buildErrorState(context, state.error!)
              : state.roles.isEmpty
                  ? _buildEmptyState(context)
                  : _buildContent(context, state),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateRoleDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Create Role'),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 64, color: AppColors.error.withValues(alpha: 0.7)),
            const SizedBox(height: AppSpacing.lg),
            Text('Failed to load roles',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.sm),
            Text(error,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: () =>
                  ref.read(adminRolesProvider.notifier).loadRoles(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
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
            Icon(Icons.admin_panel_settings_outlined,
                size: 80,
                color: AppColors.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: AppSpacing.lg),
            Text('No roles yet',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.sm),
            Text('Create roles to manage user permissions',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AdminRolesState state) {
    return Row(
      children: [
        // Roles list (left panel or full width on narrow screens)
        Expanded(
          flex: 2,
          child: RefreshIndicator(
            onRefresh: () =>
                ref.read(adminRolesProvider.notifier).loadRoles(),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: state.roles.length,
              itemBuilder: (context, index) {
                final role = state.roles[index];
                final isSelected = state.selectedRole?.id == role.id;
                return _RoleCard(
                  role: role,
                  isSelected: isSelected,
                  onTap: () =>
                      ref.read(adminRolesProvider.notifier).selectRole(role),
                  onEdit: () => _showEditRoleDialog(context, role),
                  onDelete: () => _showDeleteRoleDialog(context, role),
                );
              },
            ),
          ),
        ),
        // Permissions panel (right side)
        if (state.selectedRole != null)
          Expanded(
            flex: 3,
            child: _PermissionsPanel(
              role: state.selectedRole!,
              grants: state.grants,
              allPermissions: state.allPermissions,
              isLoading: state.isLoadingGrants,
            ),
          ),
      ],
    );
  }

  void _showCreateRoleDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Create Role',
                    style: Theme.of(ctx)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Role Name',
                    prefixIcon: Icon(Icons.badge),
                    hintText: 'e.g., CONTENT_REVIEWER',
                  ),
                  textCapitalization: TextCapitalization.characters,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    prefixIcon: Icon(Icons.description),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final success = await ref
                          .read(adminRolesProvider.notifier)
                          .createRole(
                            nameController.text.trim(),
                            descController.text.trim().isNotEmpty
                                ? descController.text.trim()
                                : null,
                          );
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(success
                              ? 'Role created'
                              : 'Failed to create role'),
                          backgroundColor:
                              success ? AppColors.success : AppColors.error,
                        ));
                      }
                    },
                    child: const Text('Create'),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditRoleDialog(BuildContext context, Role role) {
    final nameController = TextEditingController(text: role.name);
    final descController =
        TextEditingController(text: role.description ?? '');
    bool active = role.active;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color:
                            AppColors.textSecondary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Edit Role',
                      style: Theme.of(ctx)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Role Name',
                      prefixIcon: Icon(Icons.badge),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      prefixIcon: Icon(Icons.description),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SwitchListTile(
                    title: const Text('Active'),
                    value: active,
                    onChanged: (v) => setSheetState(() => active = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final success = await ref
                            .read(adminRolesProvider.notifier)
                            .updateRole(
                              role.id,
                              name: nameController.text.trim(),
                              description: descController.text.trim(),
                              active: active,
                            );
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(success
                                ? 'Role updated'
                                : 'Failed to update role'),
                            backgroundColor:
                                success ? AppColors.success : AppColors.error,
                          ));
                        }
                      },
                      child: const Text('Save Changes'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteRoleDialog(BuildContext context, Role role) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Role'),
        content: Text(
            'Are you sure you want to delete "${role.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref
                  .read(adminRolesProvider.notifier)
                  .deleteRole(role.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      success ? '${role.name} deleted' : 'Failed to delete'),
                  backgroundColor:
                      success ? AppColors.success : AppColors.error,
                ));
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final Role role;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RoleCard({
    required this.role,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        onTap: onTap,
        child: Container(
          decoration: isSelected
              ? BoxDecoration(
                  border: Border.all(color: AppColors.primary, width: 2),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                )
              : null,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: Icon(Icons.shield_outlined,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(role.name,
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                )),
                    if (role.description != null &&
                        role.description!.isNotEmpty)
                      Text(role.description!,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 2),
                decoration: BoxDecoration(
                  color: (role.active ? AppColors.success : AppColors.error)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: Text(
                  role.active ? 'ACTIVE' : 'INACTIVE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: role.active ? AppColors.success : AppColors.error,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                color: AppColors.primary,
                onPressed: onEdit,
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: AppColors.error,
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionsPanel extends ConsumerWidget {
  final Role role;
  final List<RolePermissionGrant> grants;
  final List<Permission> allPermissions;
  final bool isLoading;

  const _PermissionsPanel({
    required this.role,
    required this.grants,
    required this.allPermissions,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grantedCodes =
        grants.map((g) => g.permissionCode).toSet();

    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Permissions for ${role.name}',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.xs),
                Text(
                    '${grantedCodes.length} of ${allPermissions.length} assigned',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          const Divider(height: 1),
          if (isLoading)
            const Expanded(
                child: Center(child: CircularProgressIndicator()))
          else if (allPermissions.isEmpty)
            Expanded(
              child: Center(
                child: Text('No permissions defined yet',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.textSecondary)),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: allPermissions.length,
                itemBuilder: (context, index) {
                  final permission = allPermissions[index];
                  final isGranted =
                      grantedCodes.contains(permission.code);
                  final grant = isGranted
                      ? grants.firstWhere(
                          (g) => g.permissionCode == permission.code)
                      : null;

                  return CheckboxListTile(
                    title: Text(permission.displayLabel,
                        style: const TextStyle(fontSize: 14)),
                    subtitle: permission.description != null
                        ? Text(permission.description!,
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary))
                        : null,
                    value: isGranted,
                    dense: true,
                    onChanged: (checked) async {
                      if (checked == true) {
                        await ref
                            .read(adminRolesProvider.notifier)
                            .addGrant(role.id, permission.code);
                      } else if (grant != null) {
                        await ref
                            .read(adminRolesProvider.notifier)
                            .removeGrant(role.id, grant.id);
                      }
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
