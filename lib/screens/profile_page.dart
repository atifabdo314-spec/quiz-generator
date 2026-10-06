import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizz_generator/backend/backend.dart';
import 'package:quizz_generator/state/app_cubit.dart';
import 'package:quizz_generator/state/app_page.dart';
import 'package:quizz_generator/theme/colors.dart';
import 'package:quizz_generator/widgets/app_card.dart';
import 'package:quizz_generator/widgets/localization_extensions.dart';
import 'package:quizz_generator/widgets/page_heading.dart';
import 'package:quizz_generator/state/user_role.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({required this.role, required this.name, super.key});

  final UserRole role;
  final String name;

  String _initials(String n) {
    final cleaned = n.trim();
    if (cleaned.isEmpty) return '?';
    final parts = cleaned.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    var email = '';
    var userId = '';
    try {
      final user = Backend.instance.auth.currentUser;
      email = user?.email ?? '';
      userId = user?.uid ?? '';
    } catch (_) {}

    final roleColor = switch (role) {
      UserRole.admin => AppColors.saffron,
      UserRole.instructor => AppColors.teal,
      _ => AppColors.inkBlue,
    };

    final roleLabel = switch (role) {
      UserRole.admin => isRtl ? 'مسؤول' : 'Admin',
      UserRole.instructor => isRtl ? 'محاضر' : 'Instructor',
      _ => isRtl ? 'طالب' : 'Student',
    };

    final roleIcon = switch (role) {
      UserRole.admin => Icons.admin_panel_settings_outlined,
      UserRole.instructor => Icons.menu_book_outlined,
      _ => Icons.school_outlined,
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeading(
            titleKey: 'profile',
            subtitleKey: 'profile',
          ),
          const SizedBox(height: 26),

          AppCard(
            title: isRtl ? 'معلومات الحساب' : 'Account Information',
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: roleColor.withOpacity(0.12),
                      child: Text(
                        _initials(name),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: roleColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.isNotEmpty ? name : email,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.inkBlue,
                            ),
                          ),
                          if (name.isNotEmpty && email.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 16),
                _InfoRow(
                  icon: roleIcon,
                  label: isRtl ? 'الدور' : 'Role',
                  value: roleLabel,
                  valueColor: roleColor,
                  isRtl: isRtl,
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.badge_outlined,
                  label: 'User ID',
                  value: userId,
                  valueColor: AppColors.muted,
                  isRtl: isRtl,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            context.read<AppCubit>().navigate(AppPage.dashboard),
                        icon: Icon(
                          isRtl ? Icons.arrow_forward : Icons.arrow_back,
                          size: 18,
                        ),
                        label: Text(context.text('backToDashboard')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            context.read<AppCubit>().signOut(),
                        icon: const Icon(Icons.logout, size: 18),
                        label: Text(context.text('signOut')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
    required this.isRtl,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;
  final bool isRtl;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.muted),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
            textAlign: isRtl ? TextAlign.left : TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
