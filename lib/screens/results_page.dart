import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizz_generator/backend/backend.dart';
import 'package:quizz_generator/state/app_cubit.dart';
import 'package:quizz_generator/state/user_role.dart';
import 'package:quizz_generator/theme/colors.dart';
import 'package:quizz_generator/widgets/app_card.dart';
import 'package:quizz_generator/widgets/attempt_details_dialog.dart';
import 'package:quizz_generator/widgets/localization_extensions.dart';
import 'package:quizz_generator/widgets/page_heading.dart';
import 'package:quizz_generator/widgets/metric_card.dart';
import 'package:quizz_generator/widgets/stream_error_state.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return StreamBuilder<BackendSnapshot>(
      stream: Backend.instance.store
          .collection('quizzes')
          .snapshots(),
      builder: (context, quizSnapshot) {
        final quizTitles = <String, String>{};
        if (quizSnapshot.hasData) {
          for (final doc in quizSnapshot.data!.docs) {
            final data = doc.data;
            quizTitles[doc.id] = data['title'] ?? '';
          }
        }

        return StreamBuilder<BackendSnapshot>(
          stream: Backend.instance.store
              .collection('attempts')
              .orderBy('submittedAt', descending: true)
              .snapshots(),
          builder: (context, attemptSnapshot) {
            final attempts = attemptSnapshot.hasData
                ? attemptSnapshot.data!.docs
                : <BackendDoc>[];

if (attemptSnapshot.hasError) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PageHeading(
                    titleKey: 'results',
                    subtitleKey: 'performanceByQuiz',
                  ),
                  const SizedBox(height: 26),
                  const SizedBox(height: 24),
                  AppCard(
                    child: StreamErrorState(isRtl: isRtl),
                  ),
                ],
              );
            }

            final appState = context.watch<AppCubit>().state;
            if (appState.role == UserRole.student) {
              final mine = attempts
                  .where((d) => d.data['userId']?.toString() == appState.userId)
                  .toList();
              return _StudentResultsView(
                isRtl: isRtl,
                attempts: mine,
                quizTitles: quizTitles,
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PageHeading(
                  titleKey: 'results',
                  subtitleKey: 'performanceByQuiz',
                ),
                const SizedBox(height: 26),

                _buildMetricsRow(context, attempts),
                const SizedBox(height: 24),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final performancePanel = _QuizPerformancePanel(
                      isRtl: isRtl,
                      attempts: attempts,
                      quizTitles: quizTitles,
                    );
                    final studentListPanel = _StudentPerformancePanel(
                      isRtl: isRtl,
                      attempts: attempts,
                      quizTitles: quizTitles,
                    );

                    if (constraints.maxWidth < 1050) {
                      return Column(
                        children: [
                          performancePanel,
                          const SizedBox(height: 20),
                          studentListPanel,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: performancePanel),
                        const SizedBox(width: 24),
                        Expanded(flex: 2, child: studentListPanel),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                _QuizStudentsPanel(
                  isRtl: isRtl,
                  attempts: attempts,
                  quizTitles: quizTitles,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMetricsRow(
    BuildContext context,
    List<BackendDoc> attempts,
  ) {
    final metricsData = _computeMetrics(attempts);

    final metrics = [
      DashboardMetric(
        labelKey: 'completionRate',
        value: metricsData.$1,
        icon: Icons.done_all,
        color: AppColors.teal,
      ),
      DashboardMetric(
        labelKey: 'studentsPassed',
        value: metricsData.$2,
        icon: Icons.groups_outlined,
        color: AppColors.inkBlue,
      ),
      DashboardMetric(
        labelKey: 'averageScore',
        value: metricsData.$3,
        icon: Icons.workspace_premium_outlined,
        color: AppColors.saffron,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth < 700
            ? (constraints.maxWidth - 16) / 2
            : (constraints.maxWidth - 30) / 3;
        return Wrap(
          spacing: 15,
          runSpacing: 15,
          children: metrics.map((metric) {
            return SizedBox(
              width: cardWidth,
              height: 145,
              child: MetricCard(metric: metric),
            );
          }).toList(),
        );
      },
    );
  }

  (String, String, String) _computeMetrics(
    List<BackendDoc> attempts,
  ) {
    if (attempts.isEmpty) return ('—', '—', '—');
    final percentages = <num>[];
    for (final doc in attempts) {
      final data = doc.data;
      final pct = data['percentage'];
      if (pct is num) percentages.add(pct);
    }
    if (percentages.isEmpty) return ('—', '—', '—');
    final passed = percentages.where((p) => p >= 50).length;
    final avg = percentages.reduce((a, b) => a + b) / percentages.length;
return (
      '${(passed * 100 / percentages.length).round()}%',
      '$passed',
      '${avg.round()}%',
    );
  }
}

class _StudentResultsView extends StatelessWidget {
  const _StudentResultsView({
    required this.isRtl,
    required this.attempts,
    required this.quizTitles,
  });

  final bool isRtl;
  final List<BackendDoc> attempts;
  final Map<String, String> quizTitles;

  @override
  Widget build(BuildContext context) {
    final percentages = <num>[];
    for (final doc in attempts) {
      final pct = doc.data['percentage'];
      if (pct is num) percentages.add(pct);
    }
    final avg = percentages.isEmpty
        ? '—'
        : '${(percentages.reduce((a, b) => a + b) / percentages.length).round()}%';
    final best = percentages.isEmpty
        ? '—'
        : '${percentages.reduce((a, b) => a > b ? a : b).round()}%';
    final passed = percentages.where((p) => p >= 50).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeading(titleKey: 'myResults', subtitleKey: 'yourAttempts'),
        const SizedBox(height: 26),

        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth < 700
                ? (constraints.maxWidth - 16) / 2
                : (constraints.maxWidth - 30) / 3;
            final metrics = [
              DashboardMetric(
                labelKey: 'attempts',
                value: '${attempts.length}',
                icon: Icons.assignment_turned_in_outlined,
                color: AppColors.teal,
              ),
              DashboardMetric(
                labelKey: 'averageScore',
                value: avg,
                icon: Icons.workspace_premium_outlined,
                color: AppColors.inkBlue,
              ),
              DashboardMetric(
                labelKey: 'bestScore',
                value: best,
                icon: Icons.trending_up,
                color: AppColors.saffron,
              ),
            ];
            return Wrap(
              spacing: 15,
              runSpacing: 15,
              children: metrics
                  .map(
                    (m) => SizedBox(
                      width: cardWidth,
                      height: 145,
                      child: MetricCard(metric: m),
                    ),
                  )
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 24),

        AppCard(
          title: isRtl ? 'محاولاتك السابقة' : 'Your past attempts',
          child: attempts.isEmpty
              ? _ResultsEmptyState(
                  isRtl: isRtl,
                  message: isRtl
                      ? 'لم تخض أي اختبار بعد. ابدأ من صفحة الاختبارات.'
                      : 'You have not taken any quiz yet. Start from the quizzes page.',
                )
              : Column(
                  children: [
                    for (final doc in attempts)
                      _StudentAttemptRow(
                        doc: doc,
                        isRtl: isRtl,
                        title: quizTitles[doc.data['quizId']?.toString() ?? ''] ??
                            (doc.data['quiz_title']?.toString() ?? ''),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 24),

        AppCard(
          title: isRtl ? 'ملخص الأداء' : 'Performance summary',
          child: _ResultsEmptyState(
            isRtl: isRtl,
            message: isRtl
                ? '$passed من ${attempts.length} اختبار تجاوزت 50%.'
                : '$passed of ${attempts.length} quizzes scored 50% or more.',
          ),
        ),
      ],
    );
  }
}

class _StudentAttemptRow extends StatelessWidget {
  const _StudentAttemptRow({
    required this.doc,
    required this.isRtl,
    required this.title,
  });

  final BackendDoc doc;
  final bool isRtl;
  final String title;

  @override
  Widget build(BuildContext context) {
    final data = doc.data;
    final score = data['score'] ?? 0;
    final total = data['total'] ?? 0;
    final pct = (data['percentage'] ?? 0) as num;
    final passed = pct >= 50;
    final color = passed ? AppColors.teal : AppColors.error;
    final submitted = data['submittedAt'];
    final dateText = submitted is DateTime
        ? '${submitted.year}-${submitted.month.toString().padLeft(2, '0')}-${submitted.day.toString().padLeft(2, '0')}'
        : '';

    return InkWell(
      onTap: () => showAttemptDetails(context, doc, isRtl),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                passed ? Icons.check_circle_outline : Icons.cancel_outlined,
                size: 22,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.isEmpty ? (isRtl ? 'اختبار' : 'Quiz') : title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.inkBlue,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (dateText.isNotEmpty)
                    Text(
                      dateText,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$score / $total',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.inkBlue,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${pct.round()}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(
              isRtl ? Icons.chevron_left : Icons.chevron_right,
              size: 20,
              color: AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizPerformancePanel extends StatelessWidget {
  const _QuizPerformancePanel({
    required this.isRtl,
    required this.attempts,
    required this.quizTitles,
  });

  final bool isRtl;
  final List<BackendDoc> attempts;
  final Map<String, String> quizTitles;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<num>>{};
    for (final doc in attempts) {
      final data = doc.data;
      final quizId = data['quizId'] as String? ?? '';
      final pct = data['percentage'];
      if (pct is num) {
        grouped.putIfAbsent(quizId, () => []).add(pct);
      }
    }

    return AppCard(
      title: context.text('performanceByQuiz'),
      child: grouped.isEmpty
          ? _ResultsEmptyState(
              isRtl: isRtl,
              message: isRtl
                  ? 'لا توجد محاولات بعد لتوليد النتاجئ.'
                  : 'No attempts yet to generate results.',
            )
          : Column(
              children: List.generate(grouped.length * 2 - 1, (index) {
                if (index.isOdd) {
                  return const Divider(height: 1);
                }
                final entryIndex = index ~/ 2;
                final entry = grouped.entries.elementAt(entryIndex);
                final percentages = entry.value;
                final avg = percentages.reduce((a, b) => a + b) /
                    percentages.length;
                final pass = percentages.where((p) => p >= 50).length;
                final title = quizTitles[entry.key]?.isNotEmpty == true
                    ? quizTitles[entry.key]!
                    : (isRtl ? 'اختبار' : 'Quiz');

                return _PerformanceRow(
                  title: title,
                  submissions: '${percentages.length}',
                  averageText: isRtl
                      ? 'المعدل: ${avg.round()}%'
                      : 'Average: ${avg.round()}%',
                  passRateText: isRtl
                      ? 'نسبة النجاح: ${(pass * 100 / percentages.length).round()}%'
                      : 'Pass Rate: ${(pass * 100 / percentages.length).round()}%',
                  progress: (avg / 100).clamp(0, 1),
                  passProgress: (pass / percentages.length).clamp(0, 1),
                );
              }),
            ),
    );
  }
}

class _PerformanceRow extends StatelessWidget {
  const _PerformanceRow({
    required this.title,
    required this.submissions,
    required this.averageText,
    required this.passRateText,
    required this.progress,
    required this.passProgress,
  });

  final String title, submissions, averageText, passRateText;
  final double progress, passProgress;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.inkBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.assessment_outlined,
                  size: 20,
                  color: AppColors.inkBlue,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.inkBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isRtl
                          ? '$submissions تسليماً'
                          : '$submissions submissions',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      averageText,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: AppColors.saffron.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                      child: FractionallySizedBox(
                        alignment: AlignmentDirectional.centerStart,
                        widthFactor: progress,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.saffron,
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      passRateText,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: AppColors.teal.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                      child: FractionallySizedBox(
                        alignment: AlignmentDirectional.centerStart,
                        widthFactor: passProgress,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.teal,
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StudentPerformancePanel extends StatelessWidget {
  const _StudentPerformancePanel({
    required this.isRtl,
    required this.attempts,
    required this.quizTitles,
  });

  final bool isRtl;
  final List<BackendDoc> attempts;
  final Map<String, String> quizTitles;

  @override
  Widget build(BuildContext context) {
    final recent = attempts.take(5).toList();

    return AppCard(
      title: isRtl ? 'أحدث نتاجئ الطلاب' : 'Recent Student Results',
      child: recent.isEmpty
          ? _ResultsEmptyState(
              isRtl: isRtl,
              message: isRtl
                  ? 'لا توجد نتاجئ بعد.'
                  : 'No results yet.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(recent.length * 2 - 1, (index) {
                if (index.isOdd) {
                  return const Divider();
                }
                final doc = recent[index ~/ 2];
                final data = doc.data;
                final name = data['name'] as String? ?? '';
                final email = data['email'] as String? ?? '';
                final quizId = data['quizId'] as String? ?? '';
                final score = data['score'] ?? 0;
                final total = data['total'] ?? 0;
                final pct = data['percentage'] is num
                    ? (data['percentage'] as num).toDouble()
                    : 0.0;
                final label = name.isNotEmpty
                    ? name
                    : (email.isNotEmpty ? email : data['userId'] ?? '');
                final course = quizTitles[quizId]?.isNotEmpty == true
                    ? quizTitles[quizId]!
                    : (isRtl ? 'اختبار' : 'Quiz');
                final color = pct >= 50
                    ? AppColors.teal
                    : AppColors.error;
                final courseDot = pct >= 90
                    ? AppColors.teal
                    : (pct >= 50 ? AppColors.saffron : AppColors.error);

                return GestureDetector(
                  onTap: () => showAttemptDetails(context, doc, isRtl),
                  child: _buildStudentRow(
                    label,
                    course,
                    '$score/$total',
                    '${pct.round()}%',
                    color,
                    courseDot,
                  ),
                );
              }),
            ),
    );
  }

  Widget _buildStudentRow(
    String name,
    String course,
    String score,
    String pct,
    Color color,
    Color courseDot,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withOpacity(0.1),
            child: Text(
              name.isEmpty ? '?' : name.split(' ').map((e) => e[0]).take(2).join(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.inkBlue,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: courseDot,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        course,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                score,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.inkBlue,
                  fontSize: 14,
                ),
              ),
              Text(
                pct,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuizStudentsPanel extends StatelessWidget {
  const _QuizStudentsPanel({
    required this.isRtl,
    required this.attempts,
    required this.quizTitles,
  });

  final bool isRtl;
  final List<BackendDoc> attempts;
  final Map<String, String> quizTitles;

  String _initials(String n) {
    final cleaned = n.trim();
    if (cleaned.isEmpty) return '?';
    final parts = cleaned.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String _formatTime(BackendTimestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate().toLocal();
    final y = dt.year;
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$y/$m/$d  $h:$min';
  }

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<BackendDoc>>{};
    for (final doc in attempts) {
      final data = doc.data;
      final quizId = data['quizId'] as String? ?? '';
      grouped.putIfAbsent(quizId, () => []).add(doc);
    }

    return AppCard(
      title: isRtl ? 'الطلاب الذين حلّوا الاختبارات' : 'Students Who Solved Quizzes',
      child: grouped.isEmpty
          ? _ResultsEmptyState(
              isRtl: isRtl,
              message: isRtl
                  ? 'لا توجد محاولات بعد.'
                  : 'No attempts yet.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: grouped.entries.expand((entry) {
                final quizId = entry.key;
                final docs = entry.value;
                final title = quizTitles[quizId]?.isNotEmpty == true
                    ? quizTitles[quizId]!
                    : (isRtl ? 'اختبار' : 'Quiz');
                return [
                  _SectionHeader(
                    title: title,
                    count: docs.length,
                    isRtl: isRtl,
                  ),
                  ...docs.map((doc) {
                    final data = doc.data;
                    final name = data['name'] as String? ?? '';
                    final email = data['email'] as String? ?? '';
                    final score = data['score'] ?? 0;
                    final total = data['total'] ?? 0;
                    final pct = data['percentage'] is num
                        ? (data['percentage'] as num).toDouble()
                        : 0.0;
                    final ts = data['submittedAt'] as BackendTimestamp?;
                    final label = name.isNotEmpty
                        ? name
                        : (email.isNotEmpty ? email : data['userId'] ?? '');
                    final color =
                        pct >= 50 ? AppColors.teal : AppColors.error;
                    return GestureDetector(
                      onTap: () => showAttemptDetails(context, doc, isRtl),
                      child: _SolvedStudentRow(
                        initials: _initials(label),
                        name: label,
                        email: email,
                        scoreText: '$score/$total',
                        pctText: '${pct.round()}%',
                        color: color,
                        date: _formatTime(ts),
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                ];
              }).toList(),
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.count,
    required this.isRtl,
  });

  final String title;
  final int count;
  final bool isRtl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 18,
            color: AppColors.inkBlue,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.inkBlue,
                fontSize: 15,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.inkBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              isRtl ? '$count محاولات' : '$count attempts',
              style: const TextStyle(
                fontSize: 11,
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

class _SolvedStudentRow extends StatelessWidget {
  const _SolvedStudentRow({
    required this.initials,
    required this.name,
    required this.email,
    required this.scoreText,
    required this.pctText,
    required this.color,
    required this.date,
  });

  final String initials;
  final String name;
  final String email;
  final String scoreText;
  final String pctText;
  final Color color;
  final String date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withOpacity(0.1),
            child: Text(
              initials,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.inkBlue,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (email.isNotEmpty)
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                scoreText,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.inkBlue,
                  fontSize: 14,
                ),
              ),
              Text(
                pctText,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (date.isNotEmpty)
                Text(
                  date,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultsEmptyState extends StatelessWidget {
  const _ResultsEmptyState({required this.isRtl, required this.message});
  final bool isRtl;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.query_stats, size: 40, color: AppColors.muted),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.inkBlue,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
