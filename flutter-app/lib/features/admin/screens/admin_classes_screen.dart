import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/admin_classes_provider.dart';
import '../providers/admin_users_provider.dart';

class AdminClassesScreen extends ConsumerStatefulWidget {
  const AdminClassesScreen({super.key});

  @override
  ConsumerState<AdminClassesScreen> createState() => _AdminClassesScreenState();
}

class _AdminClassesScreenState extends ConsumerState<AdminClassesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminClassesProvider.notifier).loadClasses();
      ref.read(adminUsersProvider.notifier).loadUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminClassesProvider);
    final usersState = ref.watch(adminUsersProvider);

    // Build teacher name map for resolving IDs
    final teacherNameMap = <String, String>{};
    for (final teacher in usersState.teachers) {
      teacherNameMap[teacher.userId] = teacher.displayName;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Classes'),
        centerTitle: true,
      ),
      body: state.isLoading && state.classes.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.classes.isEmpty
              ? _buildErrorState(context, state.error!)
              : state.classes.isEmpty
                  ? _buildEmptyState(context)
                  : _buildClassesList(context, state.classes, teacherNameMap),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateClassSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Class'),
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
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error.withValues(alpha: 0.7),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Error loading classes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(adminClassesProvider.notifier).loadClasses();
              },
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
            Icon(
              Icons.class_outlined,
              size: 80,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No classes yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tap the + button to create a class',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassesList(
      BuildContext context,
      List<Map<String, dynamic>> classes,
      Map<String, String> teacherNameMap) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(adminClassesProvider.notifier).loadClasses();
        await ref.read(adminUsersProvider.notifier).loadUsers();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: classes.length,
        itemBuilder: (context, index) {
          final cls = classes[index];
          return _ClassCard(
            cls: cls,
            teacherNameMap: teacherNameMap,
            onAddDivision: () => _showCreateDivisionSheet(
              context,
              cls['id'].toString(),
            ),
            onAssignTeacher: () => _showAssignTeacherSheet(
              context,
              cls['id'].toString(),
            ),
            onDeleteClass: () => _confirmDeleteClass(
              context,
              cls['id'].toString(),
              cls['name']?.toString() ?? '',
            ),
            onDeleteDivision: (divisionId) => _confirmDeleteDivision(
              context,
              cls['id'].toString(),
              divisionId,
            ),
            onRemoveTeacher: (assignmentId) => _confirmRemoveTeacher(
              context,
              cls['id'].toString(),
              assignmentId,
            ),
          );
        },
      ),
    );
  }

  void _showCreateClassSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: const _CreateClassSheet(),
      ),
    );
  }

  void _showCreateDivisionSheet(BuildContext context, String classId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _CreateDivisionSheet(classId: classId),
      ),
    );
  }

  void _showAssignTeacherSheet(BuildContext context, String classId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _AssignTeacherSheet(classId: classId),
      ),
    );
  }

  void _confirmDeleteClass(
      BuildContext context, String classId, String className) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Class'),
        content: Text(
            'Are you sure you want to delete "$className" and all its divisions?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              final success = await ref
                  .read(adminClassesProvider.notifier)
                  .deleteClass(classId);
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                        success ? 'Class deleted' : 'Failed to delete class'),
                    backgroundColor:
                        success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteDivision(
      BuildContext context, String classId, String divisionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Division'),
        content:
            const Text('Are you sure you want to delete this division?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              final success = await ref
                  .read(adminClassesProvider.notifier)
                  .deleteDivision(classId: classId, divisionId: divisionId);
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Division deleted'
                        : 'Failed to delete division'),
                    backgroundColor:
                        success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveTeacher(
      BuildContext context, String classId, String assignmentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Teacher'),
        content: const Text(
            'Are you sure you want to remove this teacher from the class?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              final success = await ref
                  .read(adminClassesProvider.notifier)
                  .removeTeacherAssignment(
                      classId: classId, assignmentId: assignmentId);
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Teacher removed'
                        : 'Failed to remove teacher'),
                    backgroundColor:
                        success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final Map<String, dynamic> cls;
  final Map<String, String> teacherNameMap;
  final VoidCallback onAddDivision;
  final VoidCallback onAssignTeacher;
  final VoidCallback onDeleteClass;
  final void Function(String divisionId) onDeleteDivision;
  final void Function(String assignmentId) onRemoveTeacher;

  const _ClassCard({
    required this.cls,
    required this.teacherNameMap,
    required this.onAddDivision,
    required this.onAssignTeacher,
    required this.onDeleteClass,
    required this.onDeleteDivision,
    required this.onRemoveTeacher,
  });

  @override
  Widget build(BuildContext context) {
    final name = cls['name']?.toString() ?? '';
    final gradeLevel = cls['gradeLevel'];
    final divisions = cls['divisions'] is List
        ? (cls['divisions'] as List).cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];
    final teachers = cls['teachers'] is List
        ? (cls['teachers'] as List).cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      gradeLevel?.toString() ?? '?',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${divisions.length} division${divisions.length == 1 ? '' : 's'} · ${teachers.length} teacher${teachers.length == 1 ? '' : 's'}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.person_add_outlined,
                        color: AppColors.primary),
                    tooltip: 'Assign Teacher',
                    onPressed: onAssignTeacher,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline,
                        color: AppColors.primary),
                    tooltip: 'Add Division',
                    onPressed: onAddDivision,
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        color: AppColors.error.withValues(alpha: 0.7)),
                    tooltip: 'Delete Class',
                    onPressed: onDeleteClass,
                  ),
                ],
              ),
              // Teachers section
              if (teachers.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: teachers.map((teacher) {
                    final teacherId = teacher['teacherId']?.toString() ?? '';
                    final role = teacher['role']?.toString() ?? '';
                    final subject = teacher['subject']?.toString();
                    final assignmentId = teacher['id']?.toString() ?? '';
                    final teacherName =
                        teacherNameMap[teacherId] ?? 'Unknown';

                    final isClassTeacher = role == 'CLASS_TEACHER';
                    final label = isClassTeacher
                        ? 'Class Teacher: $teacherName'
                        : '${subject ?? 'Subject'}: $teacherName';

                    return Chip(
                      avatar: Icon(
                        isClassTeacher ? Icons.person : Icons.book,
                        size: 16,
                        color: isClassTeacher
                            ? AppColors.primary
                            : AppColors.secondary,
                      ),
                      label: Text(label),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => onRemoveTeacher(assignmentId),
                      backgroundColor: isClassTeacher
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.secondary.withValues(alpha: 0.1),
                      side: BorderSide.none,
                      labelStyle: TextStyle(
                        color: isClassTeacher
                            ? AppColors.primary
                            : AppColors.secondary,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    );
                  }).toList(),
                ),
              ],
              // Divisions section
              if (divisions.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                if (teachers.isEmpty) const Divider(height: 1),
                if (teachers.isEmpty) const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: divisions.map((div) {
                    final divName =
                        div['displayName'] ?? div['name'] ?? '';
                    final divId = div['id'].toString();
                    return Chip(
                      label: Text(divName.toString()),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => onDeleteDivision(divId),
                      backgroundColor:
                          AppColors.secondary.withValues(alpha: 0.1),
                      side: BorderSide.none,
                      labelStyle: const TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateClassSheet extends ConsumerStatefulWidget {
  const _CreateClassSheet();

  @override
  ConsumerState<_CreateClassSheet> createState() => _CreateClassSheetState();
}

class _CreateClassSheetState extends ConsumerState<_CreateClassSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _gradeLevelController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _gradeLevelController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final success =
          await ref.read(adminClassesProvider.notifier).createClass(
                name: _nameController.text.trim(),
                gradeLevel: int.parse(_gradeLevelController.text.trim()),
                description: _descriptionController.text.trim().isEmpty
                    ? null
                    : _descriptionController.text.trim(),
              );
      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Class created successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          final error = ref.read(adminClassesProvider).error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed: $error'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: _formKey,
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
            Text(
              'Create Class',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Class Name',
                prefixIcon: Icon(Icons.class_),
                hintText: 'e.g. Class 5',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a class name';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _gradeLevelController,
              decoration: const InputDecoration(
                labelText: 'Grade Level',
                prefixIcon: Icon(Icons.format_list_numbered),
                hintText: 'e.g. 5',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the grade level';
                }
                if (int.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                prefixIcon: Icon(Icons.description),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Create Class'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _CreateDivisionSheet extends ConsumerStatefulWidget {
  final String classId;

  const _CreateDivisionSheet({required this.classId});

  @override
  ConsumerState<_CreateDivisionSheet> createState() =>
      _CreateDivisionSheetState();
}

class _CreateDivisionSheetState
    extends ConsumerState<_CreateDivisionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final success =
          await ref.read(adminClassesProvider.notifier).createDivision(
                classId: widget.classId,
                name: _nameController.text.trim(),
                displayName: _displayNameController.text.trim().isEmpty
                    ? null
                    : _displayNameController.text.trim(),
              );
      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Division created successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          final error = ref.read(adminClassesProvider).error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed: $error'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: _formKey,
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
            Text(
              'Add Division',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Division Name',
                prefixIcon: Icon(Icons.groups),
                hintText: 'e.g. A',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a division name';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _displayNameController,
              decoration: const InputDecoration(
                labelText: 'Display Name (optional)',
                prefixIcon: Icon(Icons.label),
                hintText: 'e.g. Division A',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Add Division'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _AssignTeacherSheet extends ConsumerStatefulWidget {
  final String classId;

  const _AssignTeacherSheet({required this.classId});

  @override
  ConsumerState<_AssignTeacherSheet> createState() =>
      _AssignTeacherSheetState();
}

class _AssignTeacherSheetState extends ConsumerState<_AssignTeacherSheet> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  String _selectedRole = 'CLASS_TEACHER';
  String? _selectedTeacherId;
  bool _isLoading = false;

  @override
  void dispose() {
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTeacherId == null) return;

    setState(() => _isLoading = true);
    try {
      final success =
          await ref.read(adminClassesProvider.notifier).assignTeacher(
                classId: widget.classId,
                teacherId: _selectedTeacherId!,
                role: _selectedRole,
                subject: _selectedRole == 'SUBJECT_TEACHER' &&
                        _subjectController.text.trim().isNotEmpty
                    ? _subjectController.text.trim()
                    : null,
              );
      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Teacher assigned successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          final error = ref.read(adminClassesProvider).error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed: $error'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersState = ref.watch(adminUsersProvider);
    final teachers = usersState.teachers;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: _formKey,
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
            Text(
              'Assign Teacher',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            DropdownButtonFormField<String>(
              initialValue: _selectedRole,
              decoration: const InputDecoration(
                labelText: 'Role',
                prefixIcon: Icon(Icons.badge),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'CLASS_TEACHER',
                  child: Text('Class Teacher'),
                ),
                DropdownMenuItem(
                  value: 'SUBJECT_TEACHER',
                  child: Text('Subject Teacher'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedRole = value);
                }
              },
            ),
            if (_selectedRole == 'SUBJECT_TEACHER') ...[
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  prefixIcon: Icon(Icons.book),
                  hintText: 'e.g. Science, Mathematics',
                ),
                validator: (value) {
                  if (_selectedRole == 'SUBJECT_TEACHER' &&
                      (value == null || value.isEmpty)) {
                    return 'Please enter the subject';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _selectedTeacherId,
              decoration: const InputDecoration(
                labelText: 'Teacher',
                prefixIcon: Icon(Icons.person),
              ),
              items: teachers.map((teacher) {
                return DropdownMenuItem(
                  value: teacher.userId,
                  child: Text(teacher.displayName),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedTeacherId = value);
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a teacher';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Assign Teacher'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
