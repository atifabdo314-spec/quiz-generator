import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizz_generator/backend/backend.dart';
import 'package:quizz_generator/state/app_cubit.dart';
import 'package:quizz_generator/theme/colors.dart';
import 'package:quizz_generator/widgets/app_card.dart';
import 'package:quizz_generator/widgets/attempt_details_dialog.dart';
import 'package:quizz_generator/widgets/localization_extensions.dart';
import 'package:quizz_generator/widgets/page_heading.dart';
import 'package:quizz_generator/widgets/status_badge.dart';
import 'package:quizz_generator/widgets/stream_error_state.dart';
import 'package:quizz_generator/state/user_role.dart';

class QuizzesScreen extends StatefulWidget {
  const QuizzesScreen({required this.role, super.key});
  final UserRole role;

  @override
  State<QuizzesScreen> createState() => _QuizzesScreenState();
}

class _QuizzesScreenState extends State<QuizzesScreen> {
  bool _isBuilding = false;
  int _currentStep = 0;

  final _titleController = TextEditingController();
  String? _selectedCourse;
  String _duration = '30';
  String _attempts = '2';
  String _resultPolicy = 'immediate';
  final Set<String> _selectedQuestionIds = {};

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    if (_isBuilding && widget.role == UserRole.instructor) {
      return _buildQuizBuilderAndReview(context, isRtl);
    }

    return _buildQuizOverview(context, isRtl);
  }

  Widget _buildQuizOverview(BuildContext context, bool isRtl) {
    final instructor = widget.role == UserRole.instructor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: PageHeading(
                titleKey: 'quizzes',
                subtitleKey: 'quizBuilderIntro',
              ),
            ),
            const SizedBox(width: 12),
            if (instructor)
              FilledButton.icon(
                onPressed: () {
                  setState(() {
                    _isBuilding = true;
                    _currentStep = 0;
                    _selectedQuestionIds.clear();
                  });
                },
                icon: const Icon(Icons.add, size: 18),
                label: Text(isRtl ? 'إنشاء اختبار' : 'Create Quiz'),
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

        StreamBuilder<BackendSnapshot>(
          stream: Backend.instance.store
              .collection('quizzes')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return AppCard(
                title: context.text('quizOverview'),
                child: StreamErrorState(isRtl: isRtl),
              );
            }
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.inkBlue),
                ),
              );
            }
            final allDocs = snapshot.data!.docs;
            // Students only ever see published quizzes.
            final docs = widget.role == UserRole.student
                ? allDocs.where((d) => d.data['published'] == true).toList()
                : allDocs;

            if (docs.isEmpty) {
              return AppCard(
                title: context.text('quizOverview'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.quiz_outlined,
                        size: 40,
                        color: AppColors.muted,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isRtl
                            ? 'لا توجد اختبارات بعد'
                            : 'No quizzes yet',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.inkBlue,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.role == UserRole.student
                            ? (isRtl
                                  ? 'لا توجد اختبارات متاحة الآن.'
                                  : 'No quizzes are available right now.')
                            : (isRtl
                                  ? 'أنشئ أول اختبار من الأعلى.'
                                  : 'Create your first quiz using the button above.'),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.muted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            final quizzes = docs.map((doc) {
              final data = doc.data;
              return {
                'id': doc.id,
                'title': data['title'] ?? '',
                'course': data['course'] ?? '',
                'duration': data['duration'],
                'published': data['published'] == true,
              };
            }).toList();

            return AppCard(
              title: context.text('quizOverview'),
              child: Column(
                children: List.generate(quizzes.length * 2 - 1, (index) {
                  if (index.isOdd) {
                    return const Divider(height: 1);
                  }
                  final q = quizzes[index ~/ 2];
                  final title = q['title'] as String;
                  final course = q['course'] as String;
                  final duration = q['duration'];
                  final published = q['published'] as bool;
                  final metadata = [
                    if (course.isNotEmpty) course,
                    if (duration != null && '$duration'.isNotEmpty)
                      '$duration ${isRtl ? 'دقيقة' : 'min'}',
                  ].join(' · ');

                  final canAttempt = published &&
                      (widget.role == UserRole.student ||
                          widget.role == UserRole.admin);

                  return _QuizOverviewRow(
                    title: title,
                    metadata: metadata,
                    status: published ? 'liveNow' : 'draft',
                    startLabel: isRtl ? 'ابدأ الاختبار' : 'Start quiz',
                    onTap: canAttempt
                        ? () => context.read<AppCubit>().startQuiz(q['id'] as String)
                        : null,
                    onResultsTap: widget.role == UserRole.instructor
                        ? () => _showQuizResults(context, q, isRtl)
                        : null,
                  );
                }),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showQuizResults(
    BuildContext context,
    Map<String, dynamic> q,
    bool isRtl,
  ) {
    showDialog(
      context: context,
      builder: (context) => _QuizResultsDialog(
        quizId: q['id'] as String,
        quizTitle: (q['title'] as String?) ?? '',
        isRtl: isRtl,
      ),
    );
  }

  Widget _buildQuizBuilderAndReview(BuildContext context, bool isRtl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  _isBuilding = false;
                });
              },
              icon: Icon(
                isRtl ? Icons.arrow_forward : Icons.arrow_back,
                color: AppColors.inkBlue,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isRtl ? 'منشئ الاختبارات' : 'Quiz Builder',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.inkBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        _buildCustomStepperHeader(isRtl),
        const SizedBox(height: 24),

        if (_currentStep == 0)
          _buildStepContentBuilder(context, isRtl)
        else if (_currentStep == 1)
          _buildStepContentReview(context, isRtl)
        else
          _buildStepContentPublish(context, isRtl),
      ],
    );
  }

  Widget _buildCustomStepperHeader(bool isRtl) {
    final steps = [
      isRtl ? '1. تفاصيل المحتوى' : '1. Content Details',
      isRtl ? '2. المراجعة والأسئلة' : '2. Review & Questions',
      isRtl ? '3. النشر والإعدادات' : '3. Publish & Settings',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length, (index) {
          final active = _currentStep == index;
          return Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _currentStep = index;
                });
              },
              child: Column(
                children: [
                  Text(
                    steps[index],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: active ? FontWeight.bold : FontWeight.normal,
                      color: active ? AppColors.inkBlue : AppColors.muted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 3,
                    color: active ? AppColors.saffron : Colors.transparent,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContentBuilder(BuildContext context, bool isRtl) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 900;

    final formCard = AppCard(
      title: isRtl ? 'تفاصيل الاختبار الأساسية' : 'Quiz Core Details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isRtl ? 'المقرر الدراسي' : 'Course',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.inkBlue,
            ),
          ),
          const SizedBox(height: 6),
          StreamBuilder<BackendSnapshot>(
            stream: Backend.instance.store
                .collection('subjects')
                .snapshots(),
            builder: (context, snapshot) {
              final subjects = <String>{};
              if (snapshot.hasData) {
                for (final doc in snapshot.data!.docs) {
                  final n = (doc.data['name'] as String? ?? '').trim();
                  if (n.isNotEmpty) subjects.add(n);
                }
              }
              final current = _selectedCourse?.trim() ?? '';
              if (current.isNotEmpty) subjects.add(current);
              final list = subjects.toList()..sort();
              return DropdownButtonFormField<String>(
                value: current.isEmpty || list.isEmpty ? null : current,
                isExpanded: true,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                ),
                hint: Text(isRtl ? 'اختر المقرر' : 'Select course'),
                items: list
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text(
                          s,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedCourse = val);
                  }
                },
              );
            },
          ),
          const SizedBox(height: 16),

          Text(
            isRtl ? 'عنوان الاختبار' : 'Quiz Title',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.inkBlue,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _titleController,
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isRtl ? 'المدة (بالدقائق)' : 'Duration (mins)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.inkBlue,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      initialValue: _duration,
                      keyboardType: TextInputType.number,
                      onChanged: (val) => _duration = val,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isRtl ? 'المحاولات المتاحة' : 'Attempts Allowed',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.inkBlue,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      initialValue: _attempts,
                      keyboardType: TextInputType.number,
                      onChanged: (val) => _attempts = val,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => setState(() => _isBuilding = false),
                child: Text(isRtl ? 'إلغاء' : 'Cancel'),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: () => setState(() => _currentStep = 1),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.inkBlue,
                ),
                child: Text(
                  isRtl ? 'المتابعة للمراجعة' : 'Continue to Review',
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final readinessCard = _ApprovedCountCard(isRtl: isRtl);

    if (isMobile) {
      return Column(
        children: [
          formCard,
          const SizedBox(height: 16),
          readinessCard,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: formCard),
        const SizedBox(width: 24),
        Expanded(flex: 1, child: readinessCard),
      ],
    );
  }

  Widget _buildStepContentReview(BuildContext context, bool isRtl) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 900;

    final questionListPanel = StreamBuilder<BackendSnapshot>(
      stream: Backend.instance.store
          .collection('questions')
          .where('status', isEqualTo: 'approved')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return AppCard(
            title: isRtl ? 'أسئلة الاختبار المحددة' : 'Selected Quiz Questions',
            child: StreamErrorState(isRtl: isRtl),
          );
        }
        if (!snapshot.hasData) {
          return AppCard(
            title: isRtl ? 'أسئلة الاختبار المحددة' : 'Selected Quiz Questions',
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.inkBlue),
              ),
            ),
          );
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return AppCard(
            title: isRtl ? 'أسئلة الاختبار المحددة' : 'Selected Quiz Questions',
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  const Icon(
                    Icons.help_outline,
                    size: 36,
                    color: AppColors.muted,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isRtl
                        ? 'لا توجد أسئلة معتمدة بعد'
                        : 'No approved questions yet',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.inkBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isRtl
                        ? 'أضف أسئلة معتمدة من صفحة بنك الأسئلة.'
                        : 'Add approved questions from the question bank page.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        final questions = docs.map((doc) {
          final data = doc.data;
          return {
            'id': doc.id,
            'title': data['title'] ?? '',
            'points': data['points'] ?? 2,
          };
        }).toList();
        final selectedCount = questions
            .where((q) => _selectedQuestionIds.contains(q['id']))
            .length;
        final totalPoints = questions
            .where((q) => _selectedQuestionIds.contains(q['id']))
            .fold<int>(0, (acc, q) => acc + (q['points'] as int? ?? 0));

        return AppCard(
          title: isRtl ? 'أسئلة الاختبار المحددة' : 'Selected Quiz Questions',
          child: Column(
            children: [
              Text(
                isRtl
                    ? 'اختر الأسئلة التي تريد إضافتها إلى هذا الاختبار.'
                    : 'Tick the questions you want to include in this quiz.',
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              const SizedBox(height: 4),
              ...List.generate(questions.length, (i) {
                final q = questions[i];
                final id = q['id'] as String;
                final title = q['title'] as String;
                final points = q['points'] as int;
                final ptsLabel = points == 1
                    ? (isRtl ? 'نقطة' : '1 pt')
                    : (isRtl ? '$points نقاط' : '$points pts');
                return _buildReviewQuestionRow(
                  i + 1,
                  title,
                  ptsLabel,
                  selected: _selectedQuestionIds.contains(id),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedQuestionIds.add(id);
                      } else {
                        _selectedQuestionIds.remove(id);
                      }
                    });
                  },
                );
              }),
              if (questions.length > 1)
                const Divider()
              else
                const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isRtl
                        ? 'الأسئلة المختارة: $selectedCount من ${questions.length}'
                        : 'Selected questions: $selectedCount of ${questions.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.inkBlue,
                    ),
                  ),
                  Text(
                    isRtl
                        ? 'إجمالي النقاط: $totalPoints'
                        : 'Total Points: $totalPoints',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.teal,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    final publishSettingsCard = AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isRtl ? 'سياسة النتائج' : 'Result Policy',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.inkBlue,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _resultPolicy,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
            ),
            items: [
              DropdownMenuItem(
                value: 'immediate',
                child: Text(
                  isRtl
                      ? 'فوري بعد التسليم'
                      : 'Immediate after submission',
                ),
              ),
              DropdownMenuItem(
                value: 'manual',
                child: Text(
                  isRtl
                      ? 'يدوي بواسطة المحاضر'
                      : 'Manual release by instructor',
                ),
              ),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _resultPolicy = val);
            },
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _currentStep = 0),
                  child: Text(isRtl ? 'السابق' : 'Previous'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => setState(() => _currentStep = 2),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.inkBlue,
                  ),
                  child: Text(isRtl ? 'التالي' : 'Next'),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (isMobile) {
      return Column(
        children: [
          questionListPanel,
          const SizedBox(height: 16),
          publishSettingsCard,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: questionListPanel),
        const SizedBox(width: 24),
        Expanded(flex: 1, child: publishSettingsCard),
      ],
    );
  }

  Widget _buildReviewQuestionRow(
    int num,
    String question,
    String pts, {
    required bool selected,
    required ValueChanged<bool?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: selected,
            onChanged: onChanged,
            activeColor: AppColors.teal,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 4),
          Text(
            '$num.',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.inkBlue,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              question,
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            pts,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContentPublish(BuildContext context, bool isRtl) {
    return AppCard(
      title: isRtl ? 'نشر وإتاحة التقييم' : 'Publish & Schedule Assessment',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warmSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPublishSummaryRow(
                  isRtl ? 'المقرر الدراسي' : 'Course',
                  (_selectedCourse?.trim() ?? '').isEmpty
                      ? (isRtl ? 'بدون مقرر' : 'No course')
                      : _selectedCourse!.trim(),
                ),
                const Divider(height: 20),
                _buildPublishSummaryRow(
                  isRtl ? 'العنوان' : 'Title',
                  _titleController.text.isEmpty
                      ? (isRtl ? 'اختبار بدون عنوان' : 'Untitled Quiz')
                      : _titleController.text,
                ),
                const Divider(height: 20),
                _buildPublishSummaryRow(
                  isRtl ? 'المدة الزمنية' : 'Duration',
                  '$_duration ${isRtl ? 'دقيقة' : 'minutes'}',
                ),
                const Divider(height: 20),
                _buildPublishSummaryRow(
                  isRtl ? 'عدد المحاولات' : 'Attempts',
                  '$_attempts ${isRtl ? 'محاولات' : 'attempts'}',
                ),
                const Divider(height: 20),
                _buildPublishSummaryRow(
                  isRtl ? 'سياسة النتائج' : 'Result Policy',
                  _resultPolicy == 'immediate'
                      ? (isRtl ? 'فوري بعد التسليم' : 'Immediate release')
                      : (isRtl ? 'إصدار يدوي' : 'Manual release'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => setState(() => _currentStep = 1),
                child: Text(isRtl ? 'السابق' : 'Previous'),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () => _publishQuiz(context, isRtl),
                icon: const Icon(Icons.publish_outlined, size: 18),
                label: Text(context.text('publishQuiz')),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.inkBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _publishQuiz(BuildContext context, bool isRtl) async {
    try {
      final title = _titleController.text.trim();
      if (title.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(
              isRtl ? 'رجاءً أدخل عنوان الاختبار' : 'Please enter a quiz title',
            ),
          ),
        );
        return;
      }
      if (_selectedQuestionIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(
              isRtl
                  ? 'اختر سؤالاً واحداً على الأقل من خطوة المراجعة.'
                  : 'Select at least one question from the Review step.',
            ),
          ),
        );
        setState(() => _currentStep = 1);
        return;
      }

      final quiz = await Backend.instance.store.collection('quizzes').add({
        'title': title,
        'course': _selectedCourse?.trim() ?? '',
        'duration': int.tryParse(_duration) ?? 30,
        'maxAttempts': int.tryParse(_attempts) ?? 2,
        'resultPolicy': _resultPolicy,
        'published': true,
        'createdAt': BackendFieldValue.serverTimestamp,
      });

      for (final questionId in _selectedQuestionIds) {
        await Backend.instance.store
            .collection('questions')
            .doc(questionId)
            .update({'quizId': quiz.id});
      }

      if (!context.mounted) return;
      setState(() {
        _isBuilding = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.teal,
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 10),
              Text(context.text('quizPublished')),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Failed to publish quiz: $e'),
        ),
      );
    }
  }

  Widget _buildPublishSummaryRow(String label, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.inkBlue,
            fontSize: 14,
          ),
        ),
        Text(
          val,
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _QuizOverviewRow extends StatelessWidget {
  const _QuizOverviewRow({
    required this.title,
    required this.metadata,
    required this.status,
    this.startLabel,
    this.onTap,
    this.onResultsTap,
  });

  final String title, metadata, status;
  final String? startLabel;
  final VoidCallback? onTap;
  final VoidCallback? onResultsTap;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.warmSurface,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.assignment_outlined,
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
                if (metadata.isNotEmpty)
                  Text(
                    metadata,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          StatusBadge(statusKey: status),
          if (onResultsTap != null) ...[
            const SizedBox(width: 4),
            IconButton(
              onPressed: onResultsTap,
              tooltip: isRtl ? 'عرض النتائج' : 'View results',
              visualDensity: VisualDensity.compact,
              iconSize: 20,
              icon: const Icon(
                Icons.bar_chart_outlined,
                color: AppColors.inkBlue,
              ),
            ),
          ],
          if (onTap != null) ...[
            const SizedBox(width: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  startLabel ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.inkBlue,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  isRtl ? Icons.chevron_left : Icons.chevron_right,
                  size: 20,
                  color: AppColors.inkBlue,
                ),
              ],
            ),
          ],
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        hoverColor: AppColors.activeBlue.withOpacity(0.06),
        child: row,
      ),
    );
  }
}

class _ApprovedCountCard extends StatelessWidget {
  const _ApprovedCountCard({required this.isRtl});
  final bool isRtl;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BackendSnapshot>(
      stream: Backend.instance.store
          .collection('questions')
          .where('status', isEqualTo: 'approved')
          .snapshots(),
      builder: (context, snapshot) {
        final count =
            snapshot.hasData ? snapshot.data!.docs.length : 0;
        return Container(
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(12),
            border: const Border(
              top: BorderSide(color: AppColors.teal, width: 4),
              left: BorderSide(color: AppColors.border),
              right: BorderSide(color: AppColors.border),
              bottom: BorderSide(color: AppColors.border),
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isRtl ? 'حالة جاهزية المحتوى' : 'CONTENT READINESS',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.teal,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isRtl
                          ? 'تم العثور على $count سؤالاً معتمداً'
                          : '$count Approved questions found',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.inkBlue,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                isRtl
                    ? 'تأكد من مراجعة معايير التقييم والصعوبة للحصول على توزيع درجات متوازن.'
                    : 'Ensure assessment criteria and question difficulties match for a balanced score distribution.',
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuizResultsDialog extends StatelessWidget {
  const _QuizResultsDialog({
    required this.quizId,
    required this.quizTitle,
    required this.isRtl,
  });

  final String quizId;
  final String quizTitle;
  final bool isRtl;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.paper,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      title: Row(
        children: [
          const Icon(
            Icons.bar_chart_outlined,
            color: AppColors.inkBlue,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isRtl ? 'نتائج الاختبار' : 'Quiz results',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 560,
        height: 440,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              quizTitle.isEmpty ? (isRtl ? 'اختبار' : 'Quiz') : quizTitle,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.inkBlue,
                fontSize: 15,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<BackendSnapshot>(
                stream: Backend.instance.store
                    .collection('attempts')
                    .where('quizId', isEqualTo: quizId)
                    .orderBy('submittedAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        isRtl
                            ? 'فشل تحميل النتائج.'
                            : 'Failed to load results.',
                        style: const TextStyle(
                          color: AppColors.inkBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.inkBlue,
                      ),
                    );
                  }
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.quiz_outlined,
                            size: 36,
                            color: AppColors.muted,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            isRtl
                                ? 'لا توجد نتائج لهذا الاختبار بعد.'
                                : 'No results for this quiz yet.',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.inkBlue,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: docs.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) =>
                        _QuizResultRow(doc: docs[index], isRtl: isRtl),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.text('cancel')),
        ),
      ],
    );
  }
}

class _QuizResultRow extends StatelessWidget {
  const _QuizResultRow({required this.doc, required this.isRtl});

  final BackendDoc doc;
  final bool isRtl;

  String _initials(String n) {
    final cleaned = n.trim();
    if (cleaned.isEmpty) return '?';
    final parts = cleaned.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String _date(BackendTimestamp? ts) {
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
    final data = doc.data;
    final name = data['name']?.toString().trim() ?? '';
    final email = data['email']?.toString() ?? '';
    final score = data['score'] ?? 0;
    final total = data['total'] ?? 0;
    final pct = (data['percentage'] ?? 0) as num;
    final ts = data['submittedAt'] as BackendTimestamp?;
    final color = pct >= 50 ? AppColors.teal : AppColors.error;
    final label =
        name.isNotEmpty ? name : (email.isNotEmpty ? email : (isRtl ? 'طالب' : 'Student'));
    final dateText = _date(ts);

    return InkWell(
      onTap: () => showAttemptDetails(context, doc, isRtl),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: color.withOpacity(0.1),
              child: Text(
                _initials(label),
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
                    label,
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
                  '$score/$total',
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
                if (dateText.isNotEmpty)
                  Text(
                    dateText,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
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
