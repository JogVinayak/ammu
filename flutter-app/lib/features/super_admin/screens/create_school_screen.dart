import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';

class CreateSchoolScreen extends ConsumerStatefulWidget {
  const CreateSchoolScreen({super.key});

  @override
  ConsumerState<CreateSchoolScreen> createState() => _CreateSchoolScreenState();
}

class _CreateSchoolScreenState extends ConsumerState<CreateSchoolScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _adminNameController = TextEditingController();
  bool _createAdminUser = true;
  bool _isLoading = false;

  static const _accentColor = Color(0xFFDC2626);

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _adminEmailController.dispose();
    _adminNameController.dispose();
    super.dispose();
  }

  Future<void> _createSchool() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // TODO: Call API to create school
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('School created successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create school: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create School'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'School Information',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'School Name',
                          hintText: 'Enter school name',
                          prefixIcon: Icon(Icons.school),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter school name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _codeController,
                        decoration: const InputDecoration(
                          labelText: 'School Code',
                          hintText: 'e.g., SCHOOL001',
                          prefixIcon: Icon(Icons.tag),
                        ),
                        textCapitalization: TextCapitalization.characters,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter school code';
                          }
                          if (value.length < 3) {
                            return 'Code must be at least 3 characters';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Text(
                    'Create Admin User',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Spacer(),
                  Switch(
                    value: _createAdminUser,
                    onChanged: (value) => setState(() => _createAdminUser = value),
                    activeColor: _accentColor,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (_createAdminUser)
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _adminNameController,
                          decoration: const InputDecoration(
                            labelText: 'Admin Name',
                            hintText: 'Enter admin name',
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: _createAdminUser
                              ? (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter admin name';
                                  }
                                  return null;
                                }
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _adminEmailController,
                          decoration: const InputDecoration(
                            labelText: 'Admin Email',
                            hintText: 'admin@school.com',
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: _createAdminUser
                              ? (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter admin email';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                }
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'A temporary password will be sent to this email',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createSchool,
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
                      : const Text('Create School'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
