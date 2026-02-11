import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/super_admin_models.dart';
import '../providers/super_admin_provider.dart';

class RolesManagementScreen extends ConsumerStatefulWidget {
  const RolesManagementScreen({super.key});

  @override
  ConsumerState<RolesManagementScreen> createState() =>
      _RolesManagementScreenState();
}

class _RolesManagementScreenState
    extends ConsumerState<RolesManagementScreen> {
  static const _accentColor = Color(0xFFDC2626);

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(superAdminRolesProvider.notifier).loadAllRoles(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(superAdminRolesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Roles by School'),
        centerTitle: true,
      ),
      body: state.isLoading && state.schoolRoles.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.schoolRoles.isEmpty
              ? _buildErrorState(context, state.error!)
              : state.schoolRoles.isEmpty
                  ? _buildEmptyState(context)
                  : Row(
                      children: [
                        Expanded(
                          flex: state.selectedRole != null ? 2 : 1,
                          child: _buildSchoolRolesList(context, state),
                        ),
                        if (state.selectedRole != null)
                          Expanded(
                            flex: 3,
                            child: _PermissionsPanel(
                              role: state.selectedRole!,
                              tenantId: state.selectedTenantId!,
                              grants: state.grants,
                              allPermissions: state.allPermissions,
                              isLoading: state.isLoadingGrants,
                            ),
                          ),
                      ],
                    ),
      floatingActionButton: state.schoolRoles.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateRoleDialog(context, state),
              backgroundColor: _accentColor,
              icon: const Icon(Icons.add),
              label: const Text('Create Role'),
            )
          : null,
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
                  ref.read(superAdminRolesProvider.notifier).loadAllRoles(),
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
            Text('No schools found',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.sm),
            Text('Create schools first to manage their roles',
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

  Widget _buildSchoolRolesList(
      BuildContext context, SuperAdminRolesState state) {
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(superAdminRolesProvider.notifier).loadAllRoles(),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: state.schoolRoles.length,
        itemBuilder: (context, index) {
          final schoolRole = state.schoolRoles[index];
          return _SchoolRolesGroup(
            schoolRole: schoolRole,
            selectedRoleId: state.selectedRole?.id,
            onRoleTap: (role) => ref
                .read(superAdminRolesProvider.notifier)
                .selectRole(schoolRole.school.id, role),
            onEditRole: (role) =>
                _showEditRoleDialog(context, schoolRole.school, role),
            onDeleteRole: (role) =>
                _showDeleteRoleDialog(context, schoolRole.school, role),
          );
        },
      ),
    );
  }

  void _showCreateRoleDialog(
      BuildContext context, SuperAdminRolesState state) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? selectedSchoolId = state.schoolRoles.isNotEmpty
        ? state.schoolRoles.first.school.id
        : null;

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
                  Text('Create Role',
                      style: Theme.of(ctx)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: AppSpacing.lg),
                  DropdownButtonFormField<String>(
                    initialValue: selectedSchoolId,
                    decoration: const InputDecoration(
                      labelText: 'School',
                      prefixIcon: Icon(Icons.school),
                    ),
                    items: state.schoolRoles
                        .map((sr) => DropdownMenuItem(
                              value: sr.school.id,
                              child: Text(sr.school.name),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setSheetState(() => selectedSchoolId = v),
                    validator: (v) => v == null ? 'Select a school' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentColor,
                      ),
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final success = await ref
                            .read(superAdminRolesProvider.notifier)
                            .createRole(
                              selectedSchoolId!,
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
      ),
    );
  }

  void _showEditRoleDialog(
      BuildContext context, School school, Role role) {
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
                  const SizedBox(height: AppSpacing.xs),
                  Text(school.name,
                      style: Theme.of(ctx)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textSecondary)),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentColor,
                      ),
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final success = await ref
                            .read(superAdminRolesProvider.notifier)
                            .updateRole(
                              school.id,
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

  void _showDeleteRoleDialog(
      BuildContext context, School school, Role role) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Role'),
        content: Text(
            'Delete "${role.name}" from ${school.name}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref
                  .read(superAdminRolesProvider.notifier)
                  .deleteRole(school.id, role.id);
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

/// Expandable group showing one school's roles
class _SchoolRolesGroup extends StatelessWidget {
  final SchoolRoles schoolRole;
  final int? selectedRoleId;
  final ValueChanged<Role> onRoleTap;
  final ValueChanged<Role> onEditRole;
  final ValueChanged<Role> onDeleteRole;

  const _SchoolRolesGroup({
    required this.schoolRole,
    required this.selectedRoleId,
    required this.onRoleTap,
    required this.onEditRole,
    required this.onDeleteRole,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: true,
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              child: const Icon(Icons.school,
                  color: Color(0xFF3B82F6), size: 20),
            ),
            title: Text(schoolRole.school.name,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            subtitle: Text(
              '${schoolRole.roles.length} role${schoolRole.roles.length == 1 ? '' : 's'}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            children: [
              if (schoolRole.error != null)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text('Error: ${schoolRole.error}',
                      style: TextStyle(
                          color: AppColors.error, fontSize: 12)),
                )
              else if (schoolRole.roles.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text('No roles defined',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textSecondary)),
                )
              else
                ...schoolRole.roles.map((role) => _RoleListItem(
                      role: role,
                      isSelected: selectedRoleId == role.id,
                      onTap: () => onRoleTap(role),
                      onEdit: () => onEditRole(role),
                      onDelete: () => onDeleteRole(role),
                    )),
              const SizedBox(height: AppSpacing.xs),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleListItem extends StatelessWidget {
  final Role role;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RoleListItem({
    required this.role,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: isSelected
            ? BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                border: Border(
                  left: BorderSide(color: AppColors.primary, width: 3),
                ),
              )
            : null,
        child: Row(
          children: [
            Icon(Icons.shield_outlined,
                size: 18,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textSecondary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(role.name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
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
                  horizontal: AppSpacing.xs, vertical: 1),
              decoration: BoxDecoration(
                color: (role.active ? AppColors.success : AppColors.error)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.chip),
              ),
              child: Text(
                role.active ? 'ACTIVE' : 'INACTIVE',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: role.active ? AppColors.success : AppColors.error,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            SizedBox(
              width: 28,
              height: 28,
              child: IconButton(
                icon: const Icon(Icons.edit_outlined, size: 16),
                color: AppColors.primary,
                onPressed: onEdit,
                padding: EdgeInsets.zero,
              ),
            ),
            SizedBox(
              width: 28,
              height: 28,
              child: IconButton(
                icon: const Icon(Icons.delete_outline, size: 16),
                color: AppColors.error,
                onPressed: onDelete,
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Right panel showing permissions for the selected role
class _PermissionsPanel extends ConsumerWidget {
  final Role role;
  final String tenantId;
  final List<RolePermissionGrant> grants;
  final List<Permission> allPermissions;
  final bool isLoading;

  const _PermissionsPanel({
    required this.role,
    required this.tenantId,
    required this.grants,
    required this.allPermissions,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grantedCodes = grants.map((g) => g.permissionCode).toSet();

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
            child: Row(
              children: [
                Expanded(
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
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => ref
                      .read(superAdminRolesProvider.notifier)
                      .clearSelection(),
                ),
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
                            .read(superAdminRolesProvider.notifier)
                            .addGrant(
                                tenantId, role.id, permission.code);
                      } else if (grant != null) {
                        await ref
                            .read(superAdminRolesProvider.notifier)
                            .removeGrant(
                                tenantId, role.id, grant.id);
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
