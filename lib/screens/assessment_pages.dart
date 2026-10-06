import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizz_generator/backend/backend.dart';
import 'package:quizz_generator/theme/colors.dart';
import 'package:quizz_generator/widgets/app_card.dart';
import 'package:quizz_generator/widgets/localization_extensions.dart';
import 'package:quizz_generator/state/app_page.dart';
import 'package:quizz_generator/state/app_cubit.dart';
import 'package:quizz_generator/widgets/stream_error_state.dart';

class AttemptPage extends StatefulWidget {
  const AttemptPage({super.key});

  @override
  State<AttemptPage> createState() => _AttemptPageState();
}

class _AttemptPageState extends State<AttemptPage> {
  int _currentIndex = 0;
  List<Map<String, dynamic>> _questions = [];
  List<String?> _selectedAnswers = [];
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _loadingTimer = true;
  bool _submitting = false;
  List<Map<String, dynamic>> _resultDetails = [];

  @override
  void initState() {
    super.initState();
    _startQuizTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startQuizTimer() async {
    final quizId = context.read<AppCubit>().state.selectedQuizId;
    if (quizId.isEmpty) {
      if (mounted) setState(() => _loadingTimer = false);
      return;
    }
    try {
      final doc = await Backend.instance.store
          .collection('quizzes')
          .doc(quizId)
          .get();
      if (!mounted) return;
      final minutes = doc.data['duration'];
      if (!doc.exists || minutes is! num || minutes <= 0) {
        setState(() => _loadingTimer = false);
        return;
      }
      setState(() {
        _remainingSeconds = (minutes * 60).round();
        _loadingTimer = false;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (_remainingSeconds <= 1) {
          timer.cancel();
          setState(() => _remainingSeconds = 0);
          _submit(context);
        } else {
          setState(() => _remainingSeconds--);
        }
      });
    } catch (_) {
      if (mounted) setState(() => _loadingTimer = false);
    }
  }

  String _formatRemaining() {
    final m = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  List<Map<String, dynamic>> _mapQuestions(BackendSnapshot snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data;
      final optionsMap = data['options'] as Map<String, dynamic>? ?? {};
      final options = ['A', 'B', 'C', 'D']
          .map((k) => (optionsMap[k]?.toString() ?? '').trim())
          .where((o) => o.isNotEmpty)
          .toList();
      final correctAnswer = data['correctAnswer'] as String? ?? '';
      return {
        'prompt': data['title'] ?? '',
        'options': options,
        'correct': optionsMap[correctAnswer]?.toString() ?? '',
      };
    }).toList();
  }

  int _calculateScore() {
    int score = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_selectedAnswers[i] == _questions[i]['correct']) {
        score++;
      }
    }
    return score;
  }

  Future<void> _submit(BuildContext context) async {
    if (_submitting) return;
    _submitting = true;
    _timer?.cancel();

    final appCubit = context.read<AppCubit>();
    final state = appCubit.state;
    final total = _questions.length;
    final score = _calculateScore();
    final percentage = total == 0 ? 0 : (score * 100 / total).round();

    _resultDetails = List.generate(total, (index) {
      final q = _questions[index];
      final sel = _selectedAnswers[index];
      return {
        'prompt': q['prompt'],
        'selected': sel ?? '',
        'correct': q['correct'],
        'isCorrect': sel == q['correct'],
      };
    });

    String email = '';
    try {
      email = Backend.instance.auth.currentUser?.email ?? '';
    } catch (_) {}

    try {
      await Backend.instance.store.collection('attempts').add({
        'userId': state.userId,
        'name': state.name,
        'email': email,
        'score': score,
        'total': total,
        'percentage': percentage,
        'quizId': state.selectedQuizId,
        'answers': _resultDetails,
        'submittedAt': BackendFieldValue.serverTimestamp,
      });
    } catch (_) {}

    if (!mounted) return;
    appCubit.submit();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppCubit>().state;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    if (state.submitted) {
      final score = _calculateScore();
      return ResultPage(
        score: score,
        total: _questions.length,
        details: _resultDetails,
      );
    }

    return StreamBuilder<BackendSnapshot>(
      stream: Backend.instance.store
          .collection('questions')
          .where('status', isEqualTo: 'approved')
          .where('quizId', isEqualTo: state.selectedQuizId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: AppCard(
              child: StreamErrorState(isRtl: isRtl),
            ),
          );
        }
        final questions = snapshot.hasData
            ? _mapQuestions(snapshot.data!)
            : <Map<String, dynamic>>[];
        if (_questions.length != questions.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _questions = questions;
                _selectedAnswers = List.filled(questions.length, null);
                if (_currentIndex >= questions.length) {
                  _currentIndex = 0;
                }
              });
            }
          });
        }

        if (!snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: AppColors.inkBlue),
            ),
          );
        }

        if (questions.isEmpty) {
          return Center(
            child: AppCard(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.inbox_outlined,
                      size: 48,
                      color: AppColors.muted,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isRtl
                          ? 'لا توجد أسئلة معتمدة متاحة'
                          : 'No approved questions available',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.inkBlue,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isRtl
                          ? 'اطلب من المحاضر إضافة أسئلة معتمدة.'
                          : 'Ask your instructor to add approved questions.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (_questions.isEmpty || _questions.length != questions.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: AppColors.inkBlue),
            ),
          );
        }

        final width = MediaQuery.sizeOf(context).width;
        final isMobile = width < 850;

        final questionStage = _buildQuestionStage(context, isRtl);
        final questionNavigator = _buildQuestionNavigator(isRtl);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 3,
                        color: AppColors.saffron,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isRtl ? 'محاولة اختبار' : 'Quiz Attempt',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.inkBlue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isRtl
                            ? 'استعرض الأسئلة وأجب عليها ثم سلم المحاولة.'
                            : 'Review the questions, answer them, then submit your attempt.',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_loadingTimer && _remainingSeconds > 0) ...[
                  const SizedBox(width: 12),
                  _buildTimerChip(context),
                ],
              ],
            ),
            const SizedBox(height: 16),

            Container(
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: (_currentIndex + 1) / _questions.length,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.teal,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (isMobile)
              Column(
                children: [
                  questionNavigator,
                  const SizedBox(height: 20),
                  questionStage,
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: questionStage),
                  const SizedBox(width: 24),
                  SizedBox(width: 260, child: questionNavigator),
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _buildTimerChip(BuildContext context) {
    final low = _remainingSeconds <= 60;
    final color = low ? AppColors.error : AppColors.inkBlue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 20, color: color),
          const SizedBox(width: 8),
          Text(
            _formatRemaining(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionStage(BuildContext context, bool isRtl) {
    final q = _questions[_currentIndex];
    final questionText = q['prompt'] ?? '';
    final options = q['options'] as List<String>;

    return AppCard(
      title: '${context.text('question')} ${_currentIndex + 1} '
          '${context.text('of')} ${_questions.length}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            questionText,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.inkBlue,
            ),
          ),
          const SizedBox(height: 20),

          ...options.map((option) {
            final selected = _selectedAnswers[_currentIndex] == option;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedAnswers[_currentIndex] = option;
                  });
                  context.read<AppCubit>().selectAnswer();
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.teal.withOpacity(0.06)
                        : AppColors.paper,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected ? AppColors.teal : AppColors.border,
                      width: selected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? AppColors.teal : AppColors.muted,
                            width: 2,
                          ),
                          color: selected
                              ? AppColors.teal
                              : Colors.transparent,
                        ),
                        child: selected
                            ? const Icon(
                                Icons.circle,
                                size: 8,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          option,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: selected
                                ? AppColors.darkTeal
                                : AppColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton(
                onPressed: _currentIndex > 0
                    ? () {
                        setState(() {
                          _currentIndex--;
                        });
                      }
                    : null,
                child: Text(isRtl ? 'السابق' : 'Previous'),
              ),
              if (_currentIndex < _questions.length - 1)
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _currentIndex++;
                    });
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.inkBlue,
                  ),
                  child: Text(isRtl ? 'التالي' : 'Next'),
                )
              else
                FilledButton(
                  onPressed: _selectedAnswers.contains(null)
                      ? () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: AppColors.paper,
                              title: Text(isRtl ? 'تنبيه' : 'Warning'),
                              content: Text(
                                isRtl
                                    ? 'لم تقم بالإجابة على جميع الأسئلة. هل تريد التسليم على أية حال؟'
                                    : 'You have unanswered questions. Do you want to submit anyway?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(isRtl ? 'إلغاء' : 'Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _submit(context);
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.inkBlue,
                                  ),
                                  child: Text(isRtl ? 'تسليم' : 'Submit'),
                                ),
                              ],
                            ),
                          );
                        }
                      : () {
                          _submit(context);
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.inkBlue,
                  ),
                  child: Text(context.text('submitQuiz')),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionNavigator(bool isRtl) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isRtl ? 'مخطط الأسئلة' : 'QUESTION NAVIGATOR',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 16),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(_questions.length, (index) {
              final isCurrent = _currentIndex == index;
              final isAnswered = _selectedAnswers[index] != null;

              Color bgColor = AppColors.paper;
              Color textColor = AppColors.muted;
              Color borderColor = AppColors.border;

              if (isCurrent) {
                bgColor = AppColors.activeBlue;
                textColor = Colors.white;
                borderColor = AppColors.saffron;
              } else if (isAnswered) {
                bgColor = AppColors.teal;
                textColor = Colors.white;
                borderColor = AppColors.teal;
              }

              return InkWell(
                onTap: () {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: borderColor,
                      width: isCurrent ? 2.0 : 1.0,
                    ),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),

          _buildLegendRow(AppColors.activeBlue, isRtl ? 'الحالي' : 'Current'),
          const SizedBox(height: 8),
          _buildLegendRow(AppColors.teal, isRtl ? 'تمت الإجابة' : 'Answered'),
          const SizedBox(height: 8),
          _buildLegendRow(
            AppColors.paper,
            isRtl ? 'غير مجاب' : 'Unanswered',
            isOutlined: true,
          ),
        ],
      ),
    );
  }

  Widget _buildLegendRow(Color color, String text, {bool isOutlined = false}) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: isOutlined ? Colors.transparent : color,
            borderRadius: BorderRadius.circular(3),
            border: isOutlined ? Border.all(color: AppColors.border) : null,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.muted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class ResultPage extends StatelessWidget {
  const ResultPage({
    required this.score,
    required this.total,
    this.details = const [],
    super.key,
  });
  final int score;
  final int total;
  final List<Map<String, dynamic>> details;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final percentage = total == 0 ? 0 : (score / total * 100).toInt();
    final passed = percentage >= 50;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          child: AppCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: passed
                        ? AppColors.teal.withOpacity(0.08)
                        : AppColors.error.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    passed
                        ? Icons.check_circle_outline
                        : Icons.error_outline,
                    size: 54,
                    color: passed ? AppColors.teal : AppColors.error,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  passed
                      ? context.text('attemptSubmitted')
                      : (isRtl ? 'تم تسليم المحاولة' : 'Attempt submitted'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.inkBlue,
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  width: 110,
                  height: 110,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.saffron, width: 3),
                    color: AppColors.warmSurface,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$score / $total',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.inkBlue,
                        ),
                      ),
                      Text(
                        '$percentage%',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  isRtl
                      ? (passed
                            ? 'نتيجتك متاحة الآن. عمل رائع.'
                            : 'نتيجتك متاحة الآن. حاول مرة أخرى في المرة القادمة.')
                      : (passed
                            ? 'Your result is available now. Great work!'
                            : 'Your result is available now. Try again next time.'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.muted,
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
                      context.text('backToDashboard'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                if (details.isNotEmpty) ...[
                  const Divider(),
                  const SizedBox(height: 12),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      isRtl ? 'مراجعة إجاباتك' : 'Review your answers',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.inkBlue,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...details.asMap().entries.map((entry) => _AnswerReviewItem(
                    index: entry.key + 1,
                    data: entry.value,
                    isRtl: isRtl,
                  )),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnswerReviewItem extends StatelessWidget {
  const _AnswerReviewItem({
    required this.index,
    required this.data,
    required this.isRtl,
  });

  final int index;
  final Map<String, dynamic> data;
  final bool isRtl;

  @override
  Widget build(BuildContext context) {
    final isCorrect = data['isCorrect'] == true;
    final selected = (data['selected'] ?? '').toString().trim();
    final correct = (data['correct'] ?? '').toString().trim();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCorrect
            ? AppColors.teal.withOpacity(0.05)
            : AppColors.error.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCorrect
              ? AppColors.teal.withOpacity(0.45)
              : AppColors.error.withOpacity(0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: isCorrect ? AppColors.teal : AppColors.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isCorrect
                      ? (isRtl ? 'صحيح' : 'Correct')
                      : (isRtl ? 'خطأ' : 'Wrong'),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${isRtl ? 'السؤال' : 'Question'} $index',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.muted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            data['prompt'] ?? '',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.inkBlue,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              text: isRtl ? 'إجابتك: ' : 'Your answer: ',
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
              children: [
                TextSpan(
                  text: selected.isEmpty
                      ? (isRtl ? 'لم تتم الإجابة' : 'Not answered')
                      : selected,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: selected.isEmpty
                        ? AppColors.error
                        : (isCorrect ? AppColors.teal : AppColors.error),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              text: isRtl ? 'الإجابة الصحيحة: ' : 'Correct answer: ',
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
              children: [
                TextSpan(
                  text: correct,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.teal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}