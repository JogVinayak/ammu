import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/super_admin_models.dart';
import '../providers/super_admin_provider.dart';

class UsersManagementScreen extends ConsumerStatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  ConsumerState<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends ConsumerState<UsersManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _accentColor = Color(0xFFDC2626);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Load data on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(schoolsProvider.notifier).loadSchools();
      ref.read(usersProvider.notifier).loadUsers();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final schoolsState = ref.watch(schoolsProvider);
    final usersState = ref.watch(usersProvider);
    final teachers = usersState.teachers;
    final students = usersState.students;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: DropdownButtonFormField<String>(
                  value: usersState.selectedSchoolId ?? '',
                  decoration: InputDecoration(
                    labelText: schoolsState.isLoading ? 'Loading schools...' : 'Filter by School',
                    prefixIcon: const Icon(Icons.school),
                    suffixIcon: schoolsState.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: '',
                      child: Text('All Schools'),
                    ),
                    ...schoolsState.schools.map((school) => DropdownMenuItem<String>(
                          value: school.id,
                          child: Text(school.name),
                        )),
                  ],
                  onChanged: schoolsState.isLoading
                      ? null
                      : (value) {
                          ref.read(usersProvider.notifier).setSelectedSchool(
                            value == '' ? null : value,
                          );
                        },
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TabBar(
                controller: _tabController,
                indicatorColor: _accentColor,
                labelColor: _accentColor,
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
            ],
          ),
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
                    _buildUsersList(context, students, 'student'),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateUserDialog(context),
        backgroundColor: _accentColor,
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
                ref.read(usersProvider.notifier).loadUsers();
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
        await ref.read(usersProvider.notifier).loadUsers();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return _UserCard(
            name: user.fullName,
            email: user.email ?? '',
            schoolName: user.schoolName ?? '',
            status: user.status,
            onTap: () {
              // TODO: Navigate to user details
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String type) {
    final usersState = ref.watch(usersProvider);

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
              'No ${type}s found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              usersState.selectedSchoolId != null
                  ? 'No ${type}s in the selected school'
                  : 'Create a school first, then add ${type}s',
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
  final String schoolName;
  final String status;
  final VoidCallback onTap;

  const _UserCard({
    required this.name,
    required this.email,
    required this.schoolName,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        onTap: onTap,
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
                    if (schoolName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        schoolName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: status == 'ACTIVE'
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: status == 'ACTIVE' ? AppColors.success : AppColors.warning,
                  ),
                ),
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
  String? _selectedSchoolId;
  bool _isLoading = false;

  static const _accentColor = Color(0xFFDC2626);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSchoolId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a school'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await ref.read(usersProvider.notifier).createUser(
            tenantId: _selectedSchoolId!,
            email: _emailController.text.trim(),
            password: _passwordController.text,
            displayName: _nameController.text.trim(),
            userType: _userType,
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
          final error = ref.read(usersProvider).error;
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
    final schoolsState = ref.watch(schoolsProvider);

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
              'Create New User',
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
            DropdownButtonFormField<String>(
              value: _selectedSchoolId,
              decoration: InputDecoration(
                labelText: schoolsState.isLoading ? 'Loading schools...' : 'School',
                prefixIcon: const Icon(Icons.school),
              ),
              items: schoolsState.schools.map((school) => DropdownMenuItem<String>(
                    value: school.id,
                    child: Text(school.name),
                  )).toList(),
              onChanged: schoolsState.isLoading
                  ? null
                  : (value) => setState(() => _selectedSchoolId = value),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a school';
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
                    onTap: () => setState(() => _userType = 'TEACHER'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _UserTypeChip(
                    label: 'Student',
                    isSelected: _userType == 'STUDENT',
                    onTap: () => setState(() => _userType = 'STUDENT'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
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
    const accentColor = Color(0xFFDC2626);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? accentColor : AppColors.textSecondary.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? accentColor : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
