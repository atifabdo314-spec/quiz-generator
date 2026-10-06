import 'package:flutter/material.dart';
import 'package:quizz_generator/backend/backend.dart';
import 'package:quizz_generator/theme/colors.dart';
import 'package:quizz_generator/widgets/app_card.dart';
import 'package:quizz_generator/widgets/page_heading.dart';
import 'package:quizz_generator/widgets/stream_error_state.dart';
import 'package:quizz_generator/state/user_role.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  String _searchQuery = '';
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _selectedRole = UserRole.instructor;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showAddUserDialog() {
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _selectedRole = UserRole.instructor;

    showDialog(
      context: context,
      builder: (context) {
        final isRtl = Directionality.of(context) == TextDirection.rtl;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.paper,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Text(
                isRtl ? 'إضافة مستخدم جديد' : 'Add New User',
                style: const TextStyle(
                  color: AppColors.inkBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isRtl ? 'الاسم الكامل' : 'Full Name',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.inkBlue,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isRtl ? 'البريد الإلكتروني' : 'Email Address',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.inkBlue,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isRtl ? 'كلمة المرور' : 'Password',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.inkBlue,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(hintText: '••••••'),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isRtl ? 'الدور الوظيفي' : 'User Role',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.inkBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<UserRole>(
                      value: _selectedRole,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: UserRole.admin,
                          child: Text(isRtl ? 'مسؤول النظام (Admin)' : 'Admin'),
                        ),
                        DropdownMenuItem(
                          value: UserRole.instructor,
                          child: Text(
                            isRtl ? 'محاضر (Instructor)' : 'Instructor',
                          ),
                        ),
                        DropdownMenuItem(
                          value: UserRole.student,
                          child: Text(isRtl ? 'طالب (Student)' : 'Student'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedRole = val);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    isRtl ? 'إلغاء' : 'Cancel',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ),
                FilledButton(
                  onPressed: () async {
                    final email = _emailController.text.trim();
                    if (email.isEmpty || !email.contains('@')) {
                      return;
                    }
                    Navigator.pop(context);

                    // Register the user profile in the 'users' collection.
                    try {
                      await Backend.instance.store.collection('users').add({
                        'name': _nameController.text.trim(),
                        'email': email,
                        'role': _selectedRole.name,
                      });
                      _showSuccessSnackBar(
                        isRtl
                            ? 'تم إنشاء ملف المستخدم بنجاح'
                            : 'User profile created successfully',
                      );
                    } catch (e) {
                      _showErrorSnackBar('Error: $e');
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.inkBlue,
                  ),
                  child: Text(isRtl ? 'إضافة' : 'Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showChangeRoleDialog(String userId, String currentRole, String email) {
    _selectedRole = UserRole.values.firstWhere(
      (e) => e.name == currentRole,
      orElse: () => UserRole.student,
    );

    showDialog(
      context: context,
      builder: (context) {
        final isRtl = Directionality.of(context) == TextDirection.rtl;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.paper,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Text(
                isRtl ? 'تعديل دور المستخدم' : 'Edit User Role',
                style: const TextStyle(
                  color: AppColors.inkBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    email,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.muted,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isRtl ? 'الدور الوظيفي الجديد' : 'New Role',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.inkBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<UserRole>(
                    value: _selectedRole,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: UserRole.admin,
                        child: Text(isRtl ? 'مسؤول النظام (Admin)' : 'Admin'),
                      ),
                      DropdownMenuItem(
                        value: UserRole.instructor,
                        child: Text(
                          isRtl ? 'محاضر (Instructor)' : 'Instructor',
                        ),
                      ),
                      DropdownMenuItem(
                        value: UserRole.student,
                        child: Text(isRtl ? 'طالب (Student)' : 'Student'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedRole = val);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    isRtl ? 'إلغاء' : 'Cancel',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ),
                FilledButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    try {
                      await Backend.instance.store
                          .collection('users')
                          .doc(userId)
                          .update({'role': _selectedRole.name});
                      _showSuccessSnackBar(
                        isRtl
                            ? 'تم تحديث دور المستخدم بنجاح'
                            : 'User role updated successfully',
                      );
                    } catch (e) {
                      _showErrorSnackBar('Error: $e');
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.inkBlue,
                  ),
                  child: Text(isRtl ? 'تحديث' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmDialog(String userId, String email) {
    showDialog(
      context: context,
      builder: (context) {
        final isRtl = Directionality.of(context) == TextDirection.rtl;
        return AlertDialog(
          backgroundColor: AppColors.paper,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            isRtl ? 'حذف الحساب؟' : 'Delete Account?',
            style: const TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            isRtl
                ? 'هل أنت متأكد من رغبتك في حذف الحساب $email نهائياً؟'
                : 'Are you sure you want to permanently delete the account $email?',
            style: const TextStyle(color: AppColors.ink),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                isRtl ? 'إلغاء' : 'Cancel',
                style: const TextStyle(color: AppColors.muted),
              ),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await Backend.instance.store
                      .collection('users')
                      .doc(userId)
                      .delete();
                  _showSuccessSnackBar(
                    isRtl
                        ? 'تم حذف المستخدم بنجاح'
                        : 'User deleted successfully',
                  );
                } catch (e) {
                  _showErrorSnackBar('Error: $e');
                }
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              child: Text(isRtl ? 'حذف' : 'Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.teal,
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 10),
            Text(msg),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: AppColors.error, content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    Widget content = StreamBuilder<BackendSnapshot>(
      stream: Backend.instance.store.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          final isRtlPage = Directionality.of(context) == TextDirection.rtl;
          return Center(
            child: StreamErrorState(isRtl: isRtlPage),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(color: AppColors.inkBlue),
            ),
          );
        }
        final docs = snapshot.data?.docs ?? [];
        final usersList = docs.map((doc) {
          final data = doc.data;
          return {
            'id': doc.id,
            'name': data['name'] ?? '',
            'email': data['email'] ?? '',
            'role': data['role'] ?? 'student',
          };
        }).toList();

        return _buildUserList(isRtl, usersList);
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Page Header
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: PageHeading(
                titleKey: 'userManagement',
                subtitleKey: 'usersIntro',
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: _showAddUserDialog,
              icon: const Icon(Icons.add, size: 18),
              label: Text(isRtl ? 'إضافة مستخدم' : 'Add User'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.inkBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Wide Paper Search Field
        TextField(
          onChanged: (val) {
            setState(() {
              _searchQuery = val;
            });
          },
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search, color: AppColors.muted),
            hintText: isRtl
                ? 'البحث عن طريق الاسم أو البريد الإلكتروني...'
                : 'Search by name or email address...',
            fillColor: AppColors.paper,
            filled: true,
          ),
        ),
        const SizedBox(height: 20),

        content,
      ],
    );
  }

  Widget _buildUserList(bool isRtl, List<Map<String, dynamic>> users) {
    final query = _searchQuery.toLowerCase();
    final filteredUsers = users.where((u) {
      final email = (u['email'] as String? ?? '').toLowerCase();
      final name = (u['name'] as String? ?? '').toLowerCase();
      return email.contains(query) || name.contains(query);
    }).toList();

    return AppCard(
      title: isRtl ? 'حسابات المستخدمين المسجلة' : 'Registered User Accounts',
      child: filteredUsers.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    const Icon(
                      Icons.people_outline,
                      size: 48,
                      color: AppColors.muted,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isRtl
                          ? 'لم يتم العثور على أي مستخدمين'
                          : 'No users found',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.inkBlue,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: List.generate(filteredUsers.length * 2 - 1, (index) {
                if (index.isOdd) {
                  return const Divider(height: 1);
                }
                final uIndex = index ~/ 2;
                final user = filteredUsers[uIndex];
                final name = user['name'] as String? ?? '';
                final email = user['email'] as String? ?? '';
                final role = user['role'] as String? ?? 'student';
                final userId = user['id'] as String? ?? '';

                return _UserRow(
                  name: name,
                  email: email,
                  role: role,
                  isRtl: isRtl,
                  onEdit: () => _showChangeRoleDialog(userId, role, email),
                  onDelete: () => _showDeleteConfirmDialog(userId, email),
                );
              }),
            ),
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({
    required this.name,
    required this.email,
    required this.role,
    required this.isRtl,
    required this.onEdit,
    required this.onDelete,
  });

  final String name;
  final String email;
  final String role;
  final bool isRtl;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final roleColor = switch (role) {
      'admin' => AppColors.saffron,
      'instructor' => AppColors.teal,
      _ => AppColors.muted,
    };

    final roleLabel = switch (role) {
      'admin' => isRtl ? 'مسؤول' : 'Admin',
      'instructor' => isRtl ? 'محاضر' : 'Instructor',
      _ => isRtl ? 'طالب' : 'Student',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          // Icon Avatar
          CircleAvatar(
            backgroundColor: roleColor.withOpacity(0.08),
            radius: 20,
            child: Icon(
              role == 'admin'
                  ? Icons.admin_panel_settings_outlined
                  : (role == 'instructor'
                        ? Icons.menu_book_outlined
                        : Icons.school_outlined),
              color: roleColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),

          // Name & Email & Role Badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? email : name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.inkBlue,
                  ),
                ),
                if (name.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: roleColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      roleLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: roleColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          Row(
            children: [
              IconButton(
                onPressed: onEdit,
                icon: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.teal,
                  size: 20,
                ),
                tooltip: isRtl ? 'تعديل الدور' : 'Edit Role',
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                  size: 20,
                ),
                tooltip: isRtl ? 'حذف المستخدم' : 'Delete User',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
