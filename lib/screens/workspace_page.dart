import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizz_generator/theme/colors.dart';
import 'package:quizz_generator/widgets/app_card.dart';
import 'package:quizz_generator/widgets/localization_extensions.dart';
import 'package:quizz_generator/screens/assessment_pages.dart';
import 'package:quizz_generator/screens/dashboard_page.dart';
import 'package:quizz_generator/screens/question_bank_page.dart';
import 'package:quizz_generator/screens/quizzes_page.dart';
import 'package:quizz_generator/screens/results_page.dart';
import 'package:quizz_generator/screens/profile_page.dart';
import 'package:quizz_generator/screens/subjects_page.dart';
import 'package:quizz_generator/screens/user_management_page.dart';
import 'package:quizz_generator/state/app_page.dart';
import 'package:quizz_generator/state/user_role.dart';
import 'package:quizz_generator/state/app_cubit.dart';
import 'package:quizz_generator/widgets/language_button.dart';

class WorkspacePage extends StatelessWidget {
  const WorkspacePage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppCubit>().state;
    final width = MediaQuery.sizeOf(context).width;
    final mobile = width < 760;
    final compact = width >= 760 && width < 1100;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      drawer: mobile ? _Drawer(state: state) : null,
      body: SafeArea(
        child: Row(
          children: [
            if (!mobile) _Rail(state: state, compact: compact),
            Expanded(
              child: Column(
                children: [
                  _TopBar(mobile: mobile),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsetsDirectional.symmetric(
                        horizontal: mobile ? 17 : 42,
                        vertical: 24,
                      ),
                      child: _page(context, state),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _page(BuildContext context, AppState state) {
    // Role-aware route protection
    final isInstructorPage = state.page == AppPage.questions;
    final isStudentPage = state.page == AppPage.attempt;
    final isAdminPage = state.page == AppPage.users ||
        state.page == AppPage.subjects;

    if (state.role == UserRole.student && (isInstructorPage || isAdminPage)) {
      return const _PermissionDeniedPage();
    }
    if (state.role == UserRole.instructor && (isStudentPage || isAdminPage)) {
      return const _PermissionDeniedPage();
    }
    if (state.role == UserRole.admin && isStudentPage) {
      return const _PermissionDeniedPage();
    }

    return switch (state.page) {
      AppPage.dashboard => DashboardPage(role: state.role, name: state.name),
      AppPage.questions => const QuestionBankScreen(),
      AppPage.quizzes => QuizzesScreen(role: state.role),
      AppPage.results => const ResultsScreen(),
      AppPage.attempt => const AttemptPage(),
      AppPage.users => const UserManagementScreen(),
      AppPage.subjects => const SubjectsScreen(),
      AppPage.profile => ProfilePage(role: state.role, name: state.name),
    };
  }
}

class _PermissionDeniedPage extends StatelessWidget {
  const _PermissionDeniedPage();

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: AppCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.gpp_bad_outlined,
                    size: 54,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  isRtl ? 'وصول غير مصرح' : 'Access Denied',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  isRtl
                      ? 'ليس لديك الصلاحية للوصول إلى هذه الصفحة.'
                      : 'You do not have permission to access this page.',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.inkBlue,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  isRtl
                      ? 'لا يمكن لحسابات الطلاب الدخول إلى صفحات المحاضر، كما لا يمكن لحسابات المحاضرين الدخول إلى صفحات تقديم الاختبارات.'
                      : 'Student accounts cannot access instructor pages, and instructor accounts cannot access student attempt pages.',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: FilledButton(
                    onPressed: () {
                      context.read<AppCubit>().navigate(AppPage.dashboard);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.inkBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      isRtl
                          ? 'العودة إلى لوحة المعلومات'
                          : 'Return to Dashboard',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.mobile});
  final bool mobile;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Container(
      height: mobile ? 66 : 76,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          if (mobile)
            Builder(
              builder: (c) => IconButton(
                onPressed: () => Scaffold.of(c).openDrawer(),
                icon: const Icon(Icons.menu, color: AppColors.inkBlue),
                tooltip: isRtl
                    ? 'فتح القائمة الجانبية'
                    : 'Open navigation drawer',
              ),
            ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.activeBlue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: AppColors.saffron,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'QuizFlow',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.inkBlue,
            ),
          ),
          const Spacer(),
          _buildUserChip(context, isRtl),
          const SizedBox(width: 12),
          const LanguageButton(),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.inkBlue,
                    content: Text(
                      isRtl
                          ? 'لا توجد إشعارات جديدة'
                          : 'No new notifications',
                    ),
                  ),
                );
            },
            tooltip: context.text('notifications'),
            icon: const Badge(
              smallSize: 7,
              backgroundColor: AppColors.saffron,
              child: Icon(Icons.notifications_none, color: AppColors.inkBlue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserChip(BuildContext context, bool isRtl) {
    final state = context.watch<AppCubit>().state;
    final name = state.name.trim();
    if (name.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.warmSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: AppColors.inkBlue,
            child: Text(
              name[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.inkBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({required this.state, required this.compact});
  final AppState state;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? 82 : 252,
      color: AppColors.inkBlue,
      child: Column(
        children: [
          _BrandLockup(compact: compact),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: _navItems(context, state, compact: compact),
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 10),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            child: Tooltip(
              message: context.text('signOut'),
              child: InkWell(
                onTap: context.read<AppCubit>().signOut,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: compact
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: Icon(Icons.logout, color: Colors.white70),
                      ),
                      if (!compact)
                        Text(
                          context.text('signOut'),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _navItems(
    BuildContext context,
    AppState state, {
    required bool compact,
  }) {
    final items = <(AppPage, IconData, String)>[
      (AppPage.dashboard, Icons.grid_view_outlined, 'dashboard'),
      if (state.role == UserRole.admin)
        (AppPage.users, Icons.people_outline, 'userManagement'),
      if (state.role == UserRole.admin)
        (AppPage.subjects, Icons.menu_book_outlined, 'subjects'),
      if (state.role == UserRole.instructor)
        (AppPage.questions, Icons.quiz_outlined, 'questionBank'),
      if (state.role != UserRole.admin)
        (AppPage.quizzes, Icons.assignment_outlined, 'quizzes'),
if (state.role != UserRole.admin)
          (AppPage.results, Icons.bar_chart_outlined, 'results'),
      (AppPage.profile, Icons.person_outline, 'profile'),
    ];

    return items.map((item) {
      final selected = state.page == item.$1;
      return _RailItem(item: item, selected: selected, compact: compact);
    }).toList();
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup({required this.compact});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 24,
        vertical: 24,
      ),
      child: Row(
        mainAxisAlignment: compact
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.activeBlue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.school_outlined,
              color: AppColors.saffron,
              size: 24,
            ),
          ),
          if (!compact) ...[
            const SizedBox(width: 12),
            const Text(
              'QuizFlow',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.item,
    required this.selected,
    required this.compact,
  });

  final (AppPage, IconData, String) item;
  final bool selected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textDirection = Directionality.of(context);
    final indicatorAlignment = textDirection == TextDirection.rtl
        ? Alignment.centerRight
        : Alignment.centerLeft;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Tooltip(
        message: context.text(item.$3),
        child: InkWell(
          onTap: () => context.read<AppCubit>().navigate(item.$1),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: selected ? AppColors.activeBlue : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                if (selected)
                  Align(
                    alignment: indicatorAlignment,
                    child: Container(
                      width: 4,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.saffron,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: compact ? 0 : 20,
                    end: 12,
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: compact
                          ? MainAxisAlignment.center
                          : MainAxisAlignment.start,
                      children: [
                        Icon(
                          item.$2,
                          color: selected
                              ? Colors.white
                              : Colors.white.withOpacity(0.65),
                          size: 22,
                        ),
                        if (!compact) ...[
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              context.text(item.$3),
                              style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.65),
                                fontSize: 15,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Drawer extends StatelessWidget {
  const _Drawer({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final items = <(AppPage, IconData, String)>[
      (AppPage.dashboard, Icons.grid_view_outlined, 'dashboard'),
      if (state.role == UserRole.admin)
        (AppPage.users, Icons.people_outline, 'userManagement'),
      if (state.role == UserRole.admin)
        (AppPage.subjects, Icons.menu_book_outlined, 'subjects'),
      if (state.role == UserRole.instructor)
        (AppPage.questions, Icons.quiz_outlined, 'questionBank'),
      if (state.role != UserRole.admin)
        (AppPage.quizzes, Icons.assignment_outlined, 'quizzes'),
if (state.role != UserRole.admin)
          (AppPage.results, Icons.bar_chart_outlined, 'results'),
      (AppPage.profile, Icons.person_outline, 'profile'),
    ];

    return Drawer(
      backgroundColor: AppColors.canvas,
      child: SafeArea(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.line)),
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/app_logo.png',
                      width: 32,
                      height: 32,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'QuizFlow',
                      style: TextStyle(
                        color: AppColors.inkBlue,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: items.map((item) {
                  final selected = state.page == item.$1;
                  return ListTile(
                    selected: selected,
                    selectedTileColor: AppColors.activeBlue.withOpacity(0.08),
                    leading: Icon(
                      item.$2,
                      color: selected ? AppColors.inkBlue : AppColors.muted,
                    ),
                    title: Text(
                      context.text(item.$3),
                      style: TextStyle(
                        color: selected ? AppColors.inkBlue : AppColors.ink,
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    onTap: () {
                      context.read<AppCubit>().navigate(item.$1);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
            ),
            const Divider(color: AppColors.line),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: Text(
                context.text('signOut'),
                style: const TextStyle(color: AppColors.error),
              ),
              onTap: () {
                context.read<AppCubit>().signOut();
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
