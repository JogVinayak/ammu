import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/super_admin_models.dart';
import '../providers/super_admin_provider.dart';

class PermissionsManagementScreen extends ConsumerStatefulWidget {
  const PermissionsManagementScreen({super.key});

  @override
  ConsumerState<PermissionsManagementScreen> createState() =>
      _PermissionsManagementScreenState();
}

class _PermissionsManagementScreenState
    extends ConsumerState<PermissionsManagementScreen> {
  static const _accentColor = Color(0xFFDC2626);

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(permissionsProvider.notifier).loadPermissions(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(permissionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Permissions'),
        centerTitle: true,
      ),
      body: state.isLoading && state.permissions.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.permissions.isEmpty
              ? _buildErrorState(context, state.error!)
              : state.permissions.isEmpty
                  ? _buildEmptyState(context)
                  : RefreshIndicator(
                      onRefresh: () => ref
                          .read(permissionsProvider.notifier)
                          .loadPermissions(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: state.permissions.length,
                        itemBuilder: (context, index) {
                          final permission = state.permissions[index];
                          return _PermissionCard(
                            permission: permission,
                            onEdit: () =>
                                _showEditPermissionDialog(context, permission),
                            onDelete: () => _showDeleteConfirmation(
                                context, permission),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePermissionDialog(context),
        backgroundColor: _accentColor,
        icon: const Icon(Icons.add),
        label: const Text('Create Permission'),
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
            Text('Failed to load permissions',
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
                  ref.read(permissionsProvider.notifier).loadPermissions(),
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
            Icon(Icons.lock_outline,
                size: 80,
                color: AppColors.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: AppSpacing.lg),
            Text('No permissions yet',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.sm),
            Text(
                'Create permissions to define what actions can be performed',
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

  void _showCreatePermissionDialog(BuildContext context) {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final resourceController = TextEditingController();
    final actionController = TextEditingController();
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
            child: SingleChildScrollView(
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
                  Text('Create Permission',
                      style: Theme.of(ctx)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      prefixIcon: Icon(Icons.label),
                      hintText: 'e.g., Read Content',
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: codeController,
                    decoration: const InputDecoration(
                      labelText: 'Code',
                      prefixIcon: Icon(Icons.code),
                      hintText: 'e.g., content:read',
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: resourceController,
                          decoration: const InputDecoration(
                            labelText: 'Resource',
                            hintText: 'e.g., content',
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: TextFormField(
                          controller: actionController,
                          decoration: const InputDecoration(
                            labelText: 'Action',
                            hintText: 'e.g., read',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final success = await ref
                            .read(permissionsProvider.notifier)
                            .createPermission(
                              name: nameController.text.trim(),
                              code: codeController.text.trim(),
                              resource:
                                  resourceController.text.trim().isNotEmpty
                                      ? resourceController.text.trim()
                                      : null,
                              action:
                                  actionController.text.trim().isNotEmpty
                                      ? actionController.text.trim()
                                      : null,
                              description:
                                  descController.text.trim().isNotEmpty
                                      ? descController.text.trim()
                                      : null,
                            );
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(success
                                ? 'Permission created'
                                : 'Failed to create permission'),
                            backgroundColor:
                                success ? AppColors.success : AppColors.error,
                          ));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentColor,
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md),
                      ),
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

  void _showEditPermissionDialog(
      BuildContext context, Permission permission) {
    final nameController = TextEditingController(text: permission.code);
    final descController =
        TextEditingController(text: permission.description ?? '');
    final resourceController =
        TextEditingController(text: permission.resource ?? '');
    final actionController =
        TextEditingController(text: permission.action ?? '');
    bool active = permission.active;
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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.textSecondary
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Edit Permission',
                        style: Theme.of(ctx)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name / Code',
                        prefixIcon: Icon(Icons.label),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: resourceController,
                            decoration: const InputDecoration(
                              labelText: 'Resource',
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: TextFormField(
                            controller: actionController,
                            decoration: const InputDecoration(
                              labelText: 'Action',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SwitchListTile(
                      title: const Text('Active'),
                      value: active,
                      onChanged: (v) =>
                          setSheetState(() => active = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final success = await ref
                              .read(permissionsProvider.notifier)
                              .updatePermission(
                                permission.id,
                                name: nameController.text.trim(),
                                resource: resourceController.text
                                        .trim()
                                        .isNotEmpty
                                    ? resourceController.text.trim()
                                    : null,
                                action: actionController.text
                                        .trim()
                                        .isNotEmpty
                                    ? actionController.text.trim()
                                    : null,
                                description: descController.text
                                        .trim()
                                        .isNotEmpty
                                    ? descController.text.trim()
                                    : null,
                                active: active,
                              );
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(
                              content: Text(success
                                  ? 'Permission updated'
                                  : 'Failed to update'),
                              backgroundColor: success
                                  ? AppColors.success
                                  : AppColors.error,
                            ));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentColor,
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md),
                        ),
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
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Permission permission) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Permission'),
        content: Text(
            'Are you sure you want to delete "${permission.code}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref
                  .read(permissionsProvider.notifier)
                  .deletePermission(permission.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(success
                      ? '${permission.code} deleted'
                      : 'Failed to delete'),
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

class _PermissionCard extends StatelessWidget {
  final Permission permission;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PermissionCard({
    required this.permission,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: const Icon(Icons.lock_outline,
                    color: Color(0xFF8B5CF6), size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(permission.code,
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                )),
                    if (permission.resource != null ||
                        permission.action != null)
                      Text(
                        [permission.resource, permission.action]
                            .where((e) => e != null)
                            .join(' : '),
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                      ),
                    if (permission.description != null &&
                        permission.description!.isNotEmpty)
                      Text(permission.description!,
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
                  color: (permission.active
                          ? AppColors.success
                          : AppColors.error)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: Text(
                  permission.active ? 'ACTIVE' : 'INACTIVE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: permission.active
                        ? AppColors.success
                        : AppColors.error,
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
