import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../../super_admin/data/super_admin_models.dart';
import '../providers/admin_users_provider.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminUsersProvider.notifier).loadUsers();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersState = ref.watch(adminUsersProvider);
    final teachers = usersState.teachers;
    final students = usersState.students;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person, size: 18),
                  const SizedBox(width: 8),
                  Text('Teachers (${teachers.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people, size: 18),
                  const SizedBox(width: 8),
                  Text('Students (${students.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: usersState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : usersState.error != null
              ? _buildErrorState(context, usersState.error!)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildUsersList(context, teachers, 'teacher'),
                    _buildGroupedStudentsList(context, usersState),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateUserDialog(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Add User'),
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
              'Error loading users',
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
                ref.read(adminUsersProvider.notifier).loadUsers();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersList(
    BuildContext context,
    List<UserProfile> users,
    String type,
  ) {
    if (users.isEmpty) {
      return _buildEmptyState(context, type);
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(adminUsersProvider.notifier).loadUsers();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return _UserCard(
            name: user.fullName,
            email: user.email ?? '',
            userType: user.userType,
            status: user.status,
            onEdit: () => _showEditUserDialog(context, user),
            onDelete: () => _showDeleteConfirmation(context, user),
          );
        },
      ),
    );
  }

  Widget _buildGroupedStudentsList(
    BuildContext context,
    AdminUsersState usersState,
  ) {
    final grouped = usersState.groupedStudents;
    if (grouped.isEmpty) {
      return _buildEmptyState(context, 'student');
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(adminUsersProvider.notifier).loadUsers();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: grouped.fold<int>(
          0,
          (sum, group) => sum + 1 + group.$2.length, // header + students
        ),
        itemBuilder: (context, index) {
          // Walk through groups to find which item this index maps to
          int cursor = 0;
          for (final (label, students) in grouped) {
            if (index == cursor) {
              // Section header
              return Padding(
                padding: EdgeInsets.only(
                  top: cursor == 0 ? 0 : AppSpacing.md,
                  bottom: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Icon(
                      label == 'Unassigned'
                          ? Icons.help_outline
                          : Icons.class_outlined,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      label,
                      style:
                          Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${students.length}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            cursor++; // past the header
            if (index < cursor + students.length) {
              final student = students[index - cursor];
              return _UserCard(
                name: student.fullName,
                email: student.email ?? '',
                userType: student.userType,
                status: student.status,
                onEdit: () => _showEditUserDialog(context, student),
                onDelete: () => _showDeleteConfirmation(context, student),
              );
            }
            cursor += students.length;
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String type) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'teacher' ? Icons.person_outline : Icons.people_outline,
              size: 80,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No ${type}s yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tap the + button to add a $type',
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

  void _showEditUserDialog(BuildContext context, UserProfile user) {
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
        child: _EditUserSheet(user: user),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, UserProfile user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to delete ${user.fullName}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success =
                  await ref.read(adminUsersProvider.notifier).deleteUser(
                        profileId: user.id,
                        userId: user.userId,
                      );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? '${user.fullName} deleted'
                          : 'Failed to delete user',
                    ),
                    backgroundColor:
                        success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showCreateUserDialog(BuildContext context) {
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
        child: const _CreateUserSheet(),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final String name;
  final String email;
  final String userType;
  final String status;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _UserCard({
    required this.name,
    required this.email,
    required this.userType,
    required this.status,
    this.onEdit,
    this.onDelete,
  });

  String get _userTypeLabel {
    switch (userType) {
      case 'TEACHER':
        return 'Teacher';
      case 'STUDENT':
        return 'Student';
      case 'CONTENT_CREATOR':
        return 'Content Creator';
      default:
        return userType;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
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
                      name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userTypeLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
              if (onEdit != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  color: AppColors.primary,
                  onPressed: onEdit,
                  tooltip: 'Edit',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: AppColors.error,
                  onPressed: onDelete,
                  tooltip: 'Delete',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateUserSheet extends ConsumerStatefulWidget {
  const _CreateUserSheet();

  @override
  ConsumerState<_CreateUserSheet> createState() => _CreateUserSheetState();
}

class _CreateUserSheetState extends ConsumerState<_CreateUserSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _userType = 'TEACHER';
  bool _isLoading = false;

  // Class/Division selection for students
  List<Map<String, dynamic>> _schoolClasses = [];
  bool _loadingClasses = false;
  Map<String, dynamic>? _selectedClass;
  Map<String, dynamic>? _selectedDivision;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onUserTypeChanged(String userType) {
    setState(() {
      _userType = userType;
      _selectedClass = null;
      _selectedDivision = null;
    });
    if (userType == 'STUDENT' && _schoolClasses.isEmpty) {
      _loadClasses();
    }
  }

  Future<void> _loadClasses() async {
    setState(() => _loadingClasses = true);
    try {
      final classes =
          await ref.read(adminUsersProvider.notifier).getSchoolClasses();
      if (mounted) {
        setState(() {
          _schoolClasses = classes;
          _loadingClasses = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingClasses = false);
    }
  }

  List<Map<String, dynamic>> get _divisions {
    if (_selectedClass == null) return [];
    final divs = _selectedClass!['divisions'];
    if (divs is List) return divs.cast<Map<String, dynamic>>();
    return [];
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final success = await ref.read(adminUsersProvider.notifier).createUser(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            displayName: _nameController.text.trim(),
            userType: _userType,
            classId: _selectedClass?['id']?.toString(),
            divisionId: _selectedDivision?['id']?.toString(),
            grade: _selectedClass?['gradeLevel']?.toString(),
          );

      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User created successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          final error = ref.read(adminUsersProvider).error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create user: $error'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: _formKey,
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
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Add New User',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'User Type',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _UserTypeChip(
                      label: 'Teacher',
                      isSelected: _userType == 'TEACHER',
                      onTap: () => _onUserTypeChanged('TEACHER'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _UserTypeChip(
                      label: 'Student',
                      isSelected: _userType == 'STUDENT',
                      onTap: () => _onUserTypeChanged('STUDENT'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _UserTypeChip(
                      label: 'Creator',
                      isSelected: _userType == 'CONTENT_CREATOR',
                      onTap: () => _onUserTypeChanged('CONTENT_CREATOR'),
                    ),
                  ),
                ],
              ),
              // Class & Division dropdowns (only for students)
              if (_userType == 'STUDENT') ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Class & Division',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (_loadingClasses)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.sm),
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else ...[
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Class',
                      prefixIcon: Icon(Icons.class_),
                    ),
                    value: _selectedClass?['id']?.toString(),
                    items: _schoolClasses.map((cls) {
                      final name =
                          cls['name'] ?? 'Class ${cls['gradeLevel']}';
                      return DropdownMenuItem<String>(
                        value: cls['id'].toString(),
                        child: Text(name.toString()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedClass = _schoolClasses.firstWhere(
                          (c) => c['id'].toString() == value,
                        );
                        _selectedDivision = null;
                      });
                    },
                    validator: (value) {
                      if (value == null && _userType == 'STUDENT') {
                        return 'Please select a class';
                      }
                      return null;
                    },
                  ),
                  if (_selectedClass != null && _divisions.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Division',
                        prefixIcon: Icon(Icons.groups),
                      ),
                      value: _selectedDivision?['id']?.toString(),
                      items: _divisions.map((div) {
                        final name =
                            div['displayName'] ?? div['name'] ?? '';
                        return DropdownMenuItem<String>(
                          value: div['id'].toString(),
                          child: Text(name.toString()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDivision = _divisions.firstWhere(
                            (d) => d['id'].toString() == value,
                          );
                        });
                      },
                    ),
                  ],
                ],
              ],
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createUser,
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
                      : const Text('Create User'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditUserSheet extends ConsumerStatefulWidget {
  final UserProfile user;

  const _EditUserSheet({required this.user});

  @override
  ConsumerState<_EditUserSheet> createState() => _EditUserSheetState();
}

class _EditUserSheetState extends ConsumerState<_EditUserSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  bool _isLoading = false;

  // Class/Division selection for students
  List<Map<String, dynamic>> _schoolClasses = [];
  bool _loadingClasses = false;
  Map<String, dynamic>? _selectedClass;
  Map<String, dynamic>? _selectedDivision;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.displayName);
    _emailController = TextEditingController(text: widget.user.email ?? '');
    if (widget.user.isStudent) {
      _loadClassesAndPreselect();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadClassesAndPreselect() async {
    setState(() => _loadingClasses = true);
    try {
      final classes =
          await ref.read(adminUsersProvider.notifier).getSchoolClasses();
      if (!mounted) return;

      // Find current student profile to pre-select class/division
      final usersState = ref.read(adminUsersProvider);
      final spMap = usersState.studentProfileMap;
      final sp = spMap[widget.user.userId];

      Map<String, dynamic>? selectedClass;
      Map<String, dynamic>? selectedDivision;

      if (sp != null) {
        final classId = sp['classId']?.toString();
        final divisionId = sp['divisionId']?.toString();

        if (classId != null) {
          for (final cls in classes) {
            if (cls['id'].toString() == classId) {
              selectedClass = cls;
              if (divisionId != null) {
                final divs = cls['divisions'];
                if (divs is List) {
                  for (final div in divs) {
                    if (div is Map && div['id'].toString() == divisionId) {
                      selectedDivision = Map<String, dynamic>.from(div);
                      break;
                    }
                  }
                }
              }
              break;
            }
          }
        }
      }

      setState(() {
        _schoolClasses = classes;
        _selectedClass = selectedClass;
        _selectedDivision = selectedDivision;
        _loadingClasses = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loadingClasses = false);
    }
  }

  List<Map<String, dynamic>> get _divisions {
    if (_selectedClass == null) return [];
    final divs = _selectedClass!['divisions'];
    if (divs is List) return divs.cast<Map<String, dynamic>>();
    return [];
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final success = await ref.read(adminUsersProvider.notifier).updateUser(
            profileId: widget.user.id,
            userId: widget.user.userId,
            displayName: _nameController.text.trim(),
            email: _emailController.text.trim(),
            isStudent: widget.user.isStudent,
            classId: _selectedClass?['id']?.toString(),
            divisionId: _selectedDivision?['id']?.toString(),
            grade: _selectedClass?['gradeLevel']?.toString(),
          );

      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User updated successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          final error = ref.read(adminUsersProvider).error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update user: $error'),
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
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Edit User',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              // Class & Division dropdowns (only for students)
              if (widget.user.isStudent) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Class & Division',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (_loadingClasses)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.sm),
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else ...[
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Class',
                      prefixIcon: Icon(Icons.class_),
                    ),
                    value: _selectedClass?['id']?.toString(),
                    items: _schoolClasses.map((cls) {
                      final name =
                          cls['name'] ?? 'Class ${cls['gradeLevel']}';
                      return DropdownMenuItem<String>(
                        value: cls['id'].toString(),
                        child: Text(name.toString()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedClass = _schoolClasses.firstWhere(
                          (c) => c['id'].toString() == value,
                        );
                        _selectedDivision = null;
                      });
                    },
                  ),
                  if (_selectedClass != null && _divisions.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Division',
                        prefixIcon: Icon(Icons.groups),
                      ),
                      value: _selectedDivision?['id']?.toString(),
                      items: _divisions.map((div) {
                        final name =
                            div['displayName'] ?? div['name'] ?? '';
                        return DropdownMenuItem<String>(
                          value: div['id'].toString(),
                          child: Text(name.toString()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDivision = _divisions.firstWhere(
                            (d) => d['id'].toString() == value,
                          );
                        });
                      },
                    ),
                  ],
                ],
              ],
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveUser,
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
                      : const Text('Save Changes'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserTypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _UserTypeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.textSecondary.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
