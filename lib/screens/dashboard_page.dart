import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizz_generator/backend/backend.dart';
import 'package:quizz_generator/theme/colors.dart';
import 'package:quizz_generator/widgets/app_card.dart';
import 'package:quizz_generator/widgets/localization_extensions.dart';
import 'package:quizz_generator/widgets/page_heading.dart';
import 'package:quizz_generator/widgets/status_badge.dart';
import 'package:quizz_generator/state/app_page.dart';
import 'package:quizz_generator/state/user_role.dart';
import 'package:quizz_generator/state/app_cubit.dart';
import 'package:quizz_generator/widgets/metric_card.dart';
import 'package:quizz_generator/widgets/stream_error_state.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({required this.role, this.name = '', super.key});
  final UserRole role;
  final String name;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return switch (role) {
      UserRole.admin => _buildAdminDashboard(context, isRtl),
      UserRole.instructor => _buildInstructorDashboard(context, isRtl),
      UserRole.student => _buildStudentDashboard(context, isRtl),
    };
  }

  Widget _buildAdminDashboard(BuildContext context, bool isRtl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeading(
          titleKey: 'adminDashboard',
          subtitleKey: 'dashboardIntroAdmin',
        ),
        const SizedBox(height: 26),

        _buildMetricRow(
          context,
          [
            _CountMetricCard(
              stream: Backend.instance.store
                  .collection('users')
                  .snapshots(),
              labelKey: 'totalUsers',
              icon: Icons.people_outline,
              color: AppColors.inkBlue,
            ),
            _CountMetricCard(
              stream: Backend.instance.store
                  .collection('questions')
                  .snapshots(),
              labelKey: 'questions',
              icon: Icons.quiz_outlined,
              color: AppColors.teal,
            ),
            _CountMetricCard(
              stream: Backend.instance.store
                  .collection('quizzes')
                  .snapshots(),
              labelKey: 'quizzes',
              icon: Icons.assignment_outlined,
              color: AppColors.saffron,
            ),
          ],
        ),
        const SizedBox(height: 24),

        LayoutBuilder(
          builder: (context, constraints) {
            final mainPanel = _RecentAccountsPanel(isRtl: isRtl);
            final sideColumn = _QuickActionCard(
              isRtl: isRtl,
              icon: Icons.manage_accounts_outlined,
              title: isRtl
                  ? 'إدارة حسابات الجامعة'
                  : 'Manage University Accounts',
              buttonLabel: isRtl
                  ? 'الانتقال لإدارة المستخدمين'
                  : 'Go to User Management',
              onPressed: () {
                context.read<AppCubit>().navigate(AppPage.users);
              },
            );

            if (constraints.maxWidth < 1050) {
              return Column(
                children: [
                  mainPanel,
                  const SizedBox(height: 20),
                  sideColumn,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: mainPanel),
                const SizedBox(width: 24),
                SizedBox(width: 300, child: sideColumn),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildInstructorDashboard(BuildContext context, bool isRtl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeading(
          titleKey: 'instructorDashboard',
          subtitleKey: 'dashboardIntroInstructor',
        ),
        const SizedBox(height: 26),

        _buildMetricRow(
          context,
          [
            _CountMetricCard(
              stream: Backend.instance.store
                  .collection('quizzes')
                  .where('published', isEqualTo: true)
                  .snapshots(),
              labelKey: 'activeQuizzes',
              icon: Icons.play_circle_outline,
              color: AppColors.teal,
            ),
            _CountMetricCard(
              stream: Backend.instance.store
                  .collection('attempts')
                  .snapshots(),
              labelKey: 'attempts',
              icon: Icons.groups_outlined,
              color: AppColors.inkBlue,
            ),
            _PassRateMetricCard(
              stream: Backend.instance.store
                  .collection('attempts')
                  .snapshots(),
              labelKey: 'passRate',
              icon: Icons.trending_up,
              color: AppColors.saffron,
            ),
          ],
        ),
        const SizedBox(height: 24),

        LayoutBuilder(
          builder: (context, constraints) {
            final panel = _RecentQuizzesPanel(isRtl: isRtl);
            final sideColumn = _InstructorSideColumn(isRtl: isRtl);

            if (constraints.maxWidth < 1050) {
              return Column(
                children: [panel, const SizedBox(height: 20), sideColumn],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: panel),
                const SizedBox(width: 24),
                SizedBox(width: 300, child: sideColumn),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStudentDashboard(BuildContext context, bool isRtl) {
    final userId = context.read<AppCubit>().state.signedIn
        ? (context.read<AppCubit>().state.userId)
        : '';

final attemptsStream = userId.isEmpty
    ? const Stream<BackendSnapshot>.empty()
    : Backend.instance.store
        .collection('attempts')
        .where('userId', isEqualTo: userId)
        .snapshots();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 22, height: 3, color: AppColors.saffron),
                  const SizedBox(height: 10),
                  Text(
                    name.isEmpty
                        ? context.text('welcome')
                        : context.text('welcomeBack'),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.inkBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.text('dashboardIntroStudent'),
                    style: TextStyle(fontSize: 15, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
        const SizedBox(height: 26),

        _buildMetricRow(
          context,
          [
            _CountMetricCard(
              stream: Backend.instance.store
                  .collection('quizzes')
                  .where('published', isEqualTo: true)
                  .snapshots(),
              labelKey: 'availableNow',
              icon: Icons.assignment_turned_in_outlined,
              color: AppColors.teal,
            ),
            _CountMetricCard(
              stream: attemptsStream,
              labelKey: 'completed',
              icon: Icons.task_alt_outlined,
              color: AppColors.inkBlue,
            ),
            _AverageScoreMetricCard(
              stream: attemptsStream,
              labelKey: 'averageScore',
              icon: Icons.workspace_premium_outlined,
              color: AppColors.saffron,
            ),
          ],
        ),
        const SizedBox(height: 24),

        LayoutBuilder(
          builder: (context, constraints) {
            final mainPanel = _StudentAvailableQuizPanel(isRtl: isRtl);
            final sideColumn = _StudentSideColumn(
              isRtl: isRtl,
              attemptsStream: attemptsStream,
            );

            if (constraints.maxWidth < 1050) {
              return Column(
                children: [mainPanel, const SizedBox(height: 20), sideColumn],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: mainPanel),
                const SizedBox(width: 24),
                SizedBox(width: 300, child: sideColumn),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildMetricRow(
    BuildContext context,
    List<Widget> cards,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth < 700
            ? (constraints.maxWidth - 16) / 2
            : (constraints.maxWidth - 30) / 3;
        return Wrap(
          spacing: 15,
          runSpacing: 15,
          children: cards
              .map(
                (card) => SizedBox(width: cardWidth, height: 145, child: card),
              )
              .toList(),
        );
      },
    );
  }
}

class _RecentAccountsPanel extends StatelessWidget {
  const _RecentAccountsPanel({required this.isRtl});
  final bool isRtl;

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':
        return isRtl ? 'مدير النظام' : 'Admin';
      case 'teacher':
        return isRtl ? 'محاضر' : 'Instructor';
      default:
        return isRtl ? 'طالب' : 'Student';
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':
        return AppColors.saffron;
      case 'teacher':
        return AppColors.inkBlue;
      default:
        return AppColors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BackendSnapshot>(
      stream: Backend.instance.store
          .collection('users')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return AppCard(
            title: isRtl ? 'أحدث الحسابات' : 'Recent Accounts',
            child: StreamErrorState(isRtl: isRtl),
          );
        }
        if (!snapshot.hasData) {
          return const AppCard(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.inkBlue),
              ),
            ),
          );
        }

        final users = snapshot.data!.docs.take(6).toList();
        return AppCard(
          title: isRtl ? 'أحدث الحسابات المسجلة' : 'Recent Accounts',
          child: users.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  child: Center(
                    child: Text(
                      isRtl ? 'لا توجد حسابات بعد.' : 'No accounts yet.',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.inkBlue,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(users.length * 2 - 1, (index) {
                    if (index.isOdd) {
                      return const Divider(height: 1);
                    }
                    final doc = users[index ~/ 2];
                    final data = doc.data;
                    final name = data['name']?.toString().trim() ?? '';
                    final email = data['email']?.toString() ?? '';
                    final role = data['role']?.toString() ?? 'student';
                    return _RecentAccountRow(
                      isRtl: isRtl,
                      name: name,
                      email: email,
                      roleLabel: _roleLabel(role),
                      roleColor: _roleColor(role),
                    );
                  }),
                ),
        );
      },
    );
  }
}

class _RecentAccountRow extends StatelessWidget {
  const _RecentAccountRow({
    required this.isRtl,
    required this.name,
    required this.email,
    required this.roleLabel,
    required this.roleColor,
  });

  final bool isRtl;
  final String name;
  final String email;
  final String roleLabel;
  final Color roleColor;

  String _initials(String n) {
    final cleaned = n.trim();
    if (cleaned.isEmpty) return '?';
    final parts = cleaned.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final label = name.isEmpty ? email : name;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.inkBlue.withOpacity(0.08),
            child: Text(
              _initials(label),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.inkBlue,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.inkBlue,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (email.isNotEmpty && name.isNotEmpty)
                  Text(
                    email,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              roleLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: roleColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.isRtl,
    required this.icon,
    required this.title,
    required this.buttonLabel,
    required this.onPressed,
  });

  final bool isRtl;
  final IconData icon;
  final String title;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.inkBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isRtl ? 'إجراء سريع' : 'QUICK ACTION',
            style: const TextStyle(
              color: Colors.white70,
              letterSpacing: 1.5,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.saffron,
                foregroundColor: AppColors.inkBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 16),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      buttonLabel,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentQuizzesPanel extends StatelessWidget {
  const _RecentQuizzesPanel({required this.isRtl});
  final bool isRtl;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: context.text('recentQuizzes'),
      child: StreamBuilder<BackendSnapshot>(
        stream: Backend.instance.store
            .collection('quizzes')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return StreamErrorState(isRtl: isRtl);
          }
          if (!snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.inkBlue),
              ),
            );
          }
          final docs = snapshot.data!.docs.where((doc) {
            final data = doc.data;
            return data['published'] == true;
          }).toList();

          if (docs.isEmpty) {
            return _DashboardEmptyState(
              icon: Icons.assignment_outlined,
              text: isRtl ? 'لا توجد اختبارات بعد' : 'No quizzes yet',
              hint: isRtl
                  ? 'انشر أول اختبار من صفحة الاختبارات.'
                  : 'Publish your first quiz from the quizzes page.',
            );
          }

          final quizzes = docs.take(5).map((doc) {
            final data = doc.data;
            return {
              'id': doc.id,
              'title': data['title'] ?? '',
              'course': data['course'] ?? '',
              'duration': data['duration'] ?? '',
            };
          }).toList();

          return Column(
            children: List.generate(quizzes.length * 2 - 1, (index) {
              if (index.isOdd) {
                return const Divider(height: 1);
              }
              final q = quizzes[index ~/ 2];
              final title = q['title'] as String;
              final course = q['course'] as String;
              final duration = q['duration'];
              final metadata = [
                if (course.isNotEmpty) course,
                if (duration != null && '$duration'.isNotEmpty)
                  '$duration ${isRtl ? 'دقيقة' : 'min'}',
              ].join(' · ');

              return _QuizListRow(
                title: title,
                course: metadata,
                status: 'liveNow',
                color: AppColors.teal,
              );
            }),
          );
        },
      ),
    );
  }
}

class _QuizListRow extends StatelessWidget {
  const _QuizListRow({
    required this.title,
    required this.course,
    required this.status,
    required this.color,
  });

  final String title, course, status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.assignment_outlined, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.inkBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(statusKey: status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  course,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.more_vert,
              color: AppColors.muted,
              size: 20,
            ),
            tooltip: isRtl ? 'الخيارات' : 'Options',
          ),
        ],
      ),
    );
  }
}

class _InstructorSideColumn extends StatelessWidget {
  const _InstructorSideColumn({required this.isRtl});
  final bool isRtl;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _QuickActionCard(
          isRtl: isRtl,
          icon: Icons.add_circle_outline,
          title: isRtl ? 'إنشاء اختبار جديد' : 'Create a New Quiz',
          buttonLabel: isRtl
              ? 'الانتقال إلى منشئ الاختبارات'
              : 'Go to Quiz Builder',
          onPressed: () {
            context.read<AppCubit>().navigate(AppPage.quizzes);
          },
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.teal.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bolt_outlined,
                  color: AppColors.teal,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isRtl
                      ? 'أضف أسئلة إلى بنك الأسئلة من صفحة بنك الأسئلة.'
                      : 'Add questions to the question bank from the question bank page.',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.inkBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StudentAvailableQuizPanel extends StatelessWidget {
  const _StudentAvailableQuizPanel({required this.isRtl});
  final bool isRtl;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: context.text('availableQuizzes'),
      child: StreamBuilder<BackendSnapshot>(
        stream: Backend.instance.store
            .collection('quizzes')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return StreamErrorState(isRtl: isRtl);
          }
          if (!snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.inkBlue),
              ),
            );
          }
          final docs = snapshot.data!.docs.where((doc) {
            final data = doc.data;
            return data['published'] == true;
          }).toList();

          if (docs.isEmpty) {
            return _DashboardEmptyState(
              icon: Icons.assignment_outlined,
              text: isRtl
                  ? 'لا توجد اختبارات متاحة حالياً'
                  : 'No quizzes available right now',
              hint: isRtl
                  ? 'عند نشر المحاضرين للاختبارات، ستظهر هنا.'
                  : 'When instructors publish quizzes, they will appear here.',
            );
          }

          final quiz = docs.first.data;
          final title = quiz['title'] ?? '';
          final course = quiz['course'] ?? '';
          final duration = quiz['duration'];

          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StatusBadge(statusKey: 'liveNow'),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.inkBlue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  [
                    if (course.toString().isNotEmpty) course,
                    if (duration != null && '$duration'.isNotEmpty)
                      '$duration ${isRtl ? 'دقيقة' : 'min'}',
                  ].join(' · '),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: FilledButton(
                    onPressed: () {
                      context
                          .read<AppCubit>()
                          .startQuiz(docs.first.id);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.inkBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      context.text('startQuiz'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StudentSideColumn extends StatelessWidget {
  const _StudentSideColumn({
    required this.isRtl,
    required this.attemptsStream,
  });
  final bool isRtl;
  final Stream<BackendSnapshot> attemptsStream;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        StreamBuilder<BackendSnapshot>(
          stream: attemptsStream,
          builder: (context, snapshot) {
            final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.inkBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isRtl ? 'المحاولات المكتملة' : 'COMPLETED ATTEMPTS',
                    style: const TextStyle(
                      color: Colors.white70,
                      letterSpacing: 1.5,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.saffron.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lightbulb_outline,
                      color: AppColors.saffron,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isRtl ? 'تلميح للدراسة' : 'STUDY NOTE',
                    style: const TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                isRtl
                    ? 'راجع مادة المقرر بانتظام وجهّز نفسك جيداً قبل بدء أي اختبار متاح.'
                    : 'Review your course material regularly and prepare well before starting any available quiz.',
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardEmptyState extends StatelessWidget {
  const _DashboardEmptyState({
    required this.icon,
    required this.text,
    required this.hint,
  });

  final IconData icon;
  final String text;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warmSurface,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.inkBlue,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            hint,
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CountMetricCard extends StatelessWidget {
  const _CountMetricCard({
    required this.stream,
    required this.labelKey,
    required this.icon,
    required this.color,
  });

  final Stream<BackendSnapshot> stream;
  final String labelKey;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BackendSnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        final value = snapshot.hasData
            ? '${snapshot.data!.docs.length}'
            : (snapshot.hasError ? '—' : '…');
        return MetricCard(
          metric: DashboardMetric(
            labelKey: labelKey,
            value: value,
            icon: icon,
            color: color,
          ),
        );
      },
    );
  }
}

class _PassRateMetricCard extends StatelessWidget {
  const _PassRateMetricCard({
    required this.stream,
    required this.labelKey,
    required this.icon,
    required this.color,
  });

  final Stream<BackendSnapshot> stream;
  final String labelKey;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BackendSnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        String value = '—';
        if (snapshot.hasData) {
          final docs = snapshot.data!.docs;
          final percentages = docs
              .map(
                (d) => (d.data)['percentage'],
              )
              .whereType<num>();
          if (percentages.isNotEmpty) {
            final pass = percentages.where((p) => p >= 50).length;
            value = '${(pass * 100 / percentages.length).round()}%';
          }
        } else if (snapshot.hasError) {
          value = '—';
        }
        return MetricCard(
          metric: DashboardMetric(
            labelKey: labelKey,
            value: value,
            icon: icon,
            color: color,
          ),
        );
      },
    );
  }
}

class _AverageScoreMetricCard extends StatelessWidget {
  const _AverageScoreMetricCard({
    required this.stream,
    required this.labelKey,
    required this.icon,
    required this.color,
  });

  final Stream<BackendSnapshot> stream;
  final String labelKey;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BackendSnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        String value = '—';
        if (snapshot.hasData) {
          final percentages = snapshot.data!.docs
              .map(
                (d) => (d.data)['percentage'],
              )
              .whereType<num>();
          if (percentages.isNotEmpty) {
            final avg = percentages.reduce((a, b) => a + b) / percentages.length;
            value = '${avg.round()}%';
          }
        } else if (snapshot.hasError) {
          value = '—';
        }
        return MetricCard(
          metric: DashboardMetric(
            labelKey: labelKey,
            value: value,
            icon: icon,
            color: color,
          ),
        );
      },
    );
  }
}