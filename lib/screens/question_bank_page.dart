import 'package:flutter/material.dart';
import 'package:quizz_generator/backend/backend.dart';
import 'package:quizz_generator/theme/colors.dart';
import 'package:quizz_generator/widgets/app_card.dart';
import 'package:quizz_generator/widgets/localization_extensions.dart';
import 'package:quizz_generator/widgets/page_heading.dart';
import 'package:quizz_generator/widgets/status_badge.dart';
import 'package:quizz_generator/widgets/stream_error_state.dart';

class QuestionBankScreen extends StatefulWidget {
  const QuestionBankScreen({super.key});

  @override
  State<QuestionBankScreen> createState() => _QuestionBankScreenState();
}

class _QuestionBankScreenState extends State<QuestionBankScreen> {
  bool _isEditing = false;
  String _searchQuery = '';
  String? _editingQuestionId;

  // Controllers
  final _promptController = TextEditingController();
  final _optionAController = TextEditingController();
  final _optionBController = TextEditingController();
  final _optionCController = TextEditingController();
  final _optionDController = TextEditingController();
  final _pointsController = TextEditingController(text: '2');

  String? _selectedCourse;
  String _correctAnswer = 'A';
  String _selectedDifficulty = 'medium';
  String _selectedStatus = 'approved';

  @override
  void dispose() {
    _promptController.dispose();
    _optionAController.dispose();
    _optionBController.dispose();
    _optionCController.dispose();
    _optionDController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  void _startCreateQuestion() {
    setState(() {
      _isEditing = true;
      _editingQuestionId = null;
      _promptController.clear();
      _optionAController.clear();
      _optionBController.clear();
      _optionCController.clear();
      _optionDController.clear();
      _pointsController.text = '2';
      _correctAnswer = 'A';
      _selectedCourse = null;
      _selectedDifficulty = 'medium';
      _selectedStatus = 'approved';
    });
  }

  void _startEditQuestion(String id, Map<String, dynamic> data) {
    setState(() {
      _isEditing = true;
      _editingQuestionId = id;
      _promptController.text = data['title'] as String? ?? '';
      final options = data['options'] as Map<String, dynamic>? ?? {};
      _optionAController.text = options['A'] as String? ?? '';
      _optionBController.text = options['B'] as String? ?? '';
      _optionCController.text = options['C'] as String? ?? '';
      _optionDController.text = options['D'] as String? ?? '';
      _pointsController.text = (data['points'] ?? 2).toString();
      _correctAnswer = data['correctAnswer'] as String? ?? 'A';
      _selectedCourse = data['course'] as String?;
      _selectedDifficulty = data['difficulty'] as String? ?? 'medium';
      _selectedStatus = data['status'] as String? ?? 'approved';
    });
  }

  Future<void> _saveQuestion() async {
    final title = _promptController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            Directionality.of(context) == TextDirection.rtl
                ? 'الرجاء إدخال نص السؤال'
                : 'Please enter question prompt',
          ),
        ),
      );
      return;
    }

    final options = {
      'A': _optionAController.text.trim(),
      'B': _optionBController.text.trim(),
      'C': _optionCController.text.trim(),
      'D': _optionDController.text.trim(),
    };

    if (options.values.any((opt) => opt.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            Directionality.of(context) == TextDirection.rtl
                ? 'الرجاء ملء جميع خيارات الإجابة'
                : 'Please fill all answer options',
          ),
        ),
      );
      return;
    }

    final data = {
      'title': title,
      'course': _selectedCourse,
      'points': int.tryParse(_pointsController.text) ?? 2,
      'difficulty': _selectedDifficulty,
      'status': _selectedStatus,
      'options': options,
      'correctAnswer': _correctAnswer,
      'createdAt': BackendFieldValue.serverTimestamp,
    };

    setState(() {
      _isEditing = false;
    });

    try {
      if (_editingQuestionId != null) {
        await Backend.instance.store
            .collection('questions')
            .doc(_editingQuestionId!)
            .update(data);
      } else {
        await Backend.instance.store.collection('questions').add(data);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.teal,
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 10),
              Text(context.text('questionSaved')),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Failed to save question: $e'),
        ),
      );
    }
  }

  void _deleteQuestion(String id) {
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
            isRtl ? 'حذف السؤال؟' : 'Delete Question?',
            style: const TextStyle(
              color: AppColors.inkBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            isRtl
                ? 'هل أنت متأكد من رغبتك في حذف هذا السؤال نهائياً؟'
                : 'Are you sure you want to permanently delete this question?',
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
                      .collection('questions')
                      .doc(id)
                      .delete();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.inkBlue,
                      content: Text(
                        isRtl
                            ? 'تم حذف السؤال بنجاح'
                            : 'Question deleted successfully',
                      ),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.error,
                      content: Text(
                        isRtl
                            ? 'فشل حذف السؤال: $e'
                            : 'Failed to delete question: $e',
                      ),
                    ),
                  );
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

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    if (_isEditing) {
      return _buildQuestionEditor(context, isRtl);
    }

    return _buildQuestionList(context, isRtl);
  }

  Widget _buildQuestionList(BuildContext context, bool isRtl) {
    final questionsStream = Backend.instance.store
        .collection('questions')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return StreamBuilder<BackendSnapshot>(
      stream: questionsStream,
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
        final filteredDocs = docs.where((doc) {
          final data = doc.data;
          final title = data['title'] as String? ?? '';
          return title.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: PageHeading(
                    titleKey: 'questionBank',
                    subtitleKey: 'questionBankIntro',
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _startCreateQuestion,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(context.text('newQuestion')),
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
                hintText: context.text('searchQuestions'),
                fillColor: AppColors.paper,
                filled: true,
              ),
            ),
            const SizedBox(height: 20),

            // Connected Paper Panel
            AppCard(
              title: '${filteredDocs.length} ${context.text('questions')}',
              child: filteredDocs.isEmpty
                  ? _buildEmptyState(isRtl)
                  : Column(
                      children: List.generate(filteredDocs.length * 2 - 1, (
                        index,
                      ) {
                        if (index.isOdd) {
                          return const Divider(height: 1);
                        }
                        final qIndex = index ~/ 2;
                        final doc = filteredDocs[qIndex];
                        final data = doc.data;
                        final title = data['title'] as String? ?? '';
                        final course = data['course'] as String? ?? '';
                        final points = data['points'] ?? 2;
                        final status = data['status'] as String? ?? 'approved';

                        final ptsLabel = points == 1
                            ? (isRtl ? 'نقطة واحدة' : '1 pt')
                            : (isRtl ? '$points نقاط' : '$points pts');
                        final metadata = course.isEmpty
                            ? ptsLabel
                            : '$course · $ptsLabel';

                        return _QuestionBankRow(
                          title: title,
                          metadata: metadata,
                          status: status,
                          onDelete: () => _deleteQuestion(doc.id),
                          onEdit: () {
                            _startEditQuestion(doc.id, data);
                          },
                        );
                      }),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(bool isRtl) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warmSurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.help_outline_outlined,
              size: 48,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isRtl ? 'لا توجد أسئلة مضافة' : 'No Questions Found',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.inkBlue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isRtl
                ? 'ابدأ بإضافة أول سؤال لبنك الأسئلة الخاص بك.'
                : 'Start by adding your very first question to the bank.',
            style: const TextStyle(fontSize: 14, color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _startCreateQuestion,
            icon: const Icon(Icons.add, size: 18),
            label: Text(context.text('newQuestion')),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.inkBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionEditor(BuildContext context, bool isRtl) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 900;

    final editorCard = _buildEditorCard(context, isRtl);
    final sidebar = _buildEditorSidebar(context, isRtl);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Editor Header
        Row(
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  _isEditing = false;
                });
              },
              icon: Icon(
                isRtl ? Icons.arrow_forward : Icons.arrow_back,
                color: AppColors.inkBlue,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isRtl ? 'محرر الأسئلة' : 'Question Editor',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.inkBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Main & Sidebar Layout
        if (isMobile)
          Column(children: [editorCard, const SizedBox(height: 16), sidebar])
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: editorCard),
              const SizedBox(width: 24),
              Expanded(flex: 1, child: sidebar),
            ],
          ),
      ],
    );
  }

  Widget _buildEditorCard(BuildContext context, bool isRtl) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question Textarea
          Text(
            context.text('questionPrompt'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.inkBlue,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _promptController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: isRtl
                  ? 'أدخل نص السؤال هنا...'
                  : 'Enter question prompt here...',
              fillColor: AppColors.canvas,
              filled: true,
            ),
          ),
          const SizedBox(height: 24),

          // Answer Rows
          Text(
            isRtl ? 'خيارات الإجابة' : 'Answer Options',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.inkBlue,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          _buildAnswerOptionRow('A', isRtl, _optionAController),
          const SizedBox(height: 12),
          _buildAnswerOptionRow('B', isRtl, _optionBController),
          const SizedBox(height: 12),
          _buildAnswerOptionRow('C', isRtl, _optionCController),
          const SizedBox(height: 12),
          _buildAnswerOptionRow('D', isRtl, _optionDController),
          const SizedBox(height: 28),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                  });
                },
                child: Text(context.text('cancel')),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: _saveQuestion,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.inkBlue,
                ),
                child: Text(context.text('saveQuestion')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerOptionRow(
    String letter,
    bool isRtl,
    TextEditingController controller,
  ) {
    return Row(
      children: [
        Radio<String>(
          value: letter,
          groupValue: _correctAnswer,
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _correctAnswer = val;
              });
            }
          },
          activeColor: AppColors.teal,
        ),
        const SizedBox(width: 4),
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.warmSurface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            letter,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.inkBlue,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: isRtl ? 'أدخل الخيار $letter' : 'Enter option $letter',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditorSidebar(BuildContext context, bool isRtl) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          top: BorderSide(color: AppColors.saffron, width: 4),
          left: BorderSide(color: AppColors.border),
          right: BorderSide(color: AppColors.border),
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isRtl ? 'إعدادات السؤال' : 'QUESTION SETTINGS',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 16),

          // Course Selection
          Text(
            isRtl ? 'المقرر الدراسي' : 'Course',
            style: const TextStyle(
              fontSize: 13,
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
                hint: Text(
                  isRtl ? 'اختر المقرر' : 'Select course',
                  style: const TextStyle(fontSize: 13),
                ),
                items: list
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text(
                          s,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
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

          // Points
          Text(
            isRtl ? 'النقاط' : 'Points',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.inkBlue,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _pointsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
          ),
          const SizedBox(height: 16),

          // Difficulty
          Text(
            isRtl ? 'الصعوبة' : 'Difficulty',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.inkBlue,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _selectedDifficulty,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            items: [
              DropdownMenuItem(
                value: 'easy',
                child: Text(isRtl ? 'سهل' : 'Easy'),
              ),
              DropdownMenuItem(
                value: 'medium',
                child: Text(isRtl ? 'متوسط' : 'Medium'),
              ),
              DropdownMenuItem(
                value: 'hard',
                child: Text(isRtl ? 'صعب' : 'Hard'),
              ),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedDifficulty = val;
                });
              }
            },
          ),
          const SizedBox(height: 16),

          // Status
          Text(
            isRtl ? 'الحالة' : 'Status',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.inkBlue,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _selectedStatus,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            items: [
              DropdownMenuItem(
                value: 'approved',
                child: Text(isRtl ? 'مقبول' : 'Approved'),
              ),
              DropdownMenuItem(
                value: 'inReview',
                child: Text(isRtl ? 'قيد المراجعة' : 'In Review'),
              ),
              DropdownMenuItem(
                value: 'draft',
                child: Text(isRtl ? 'مسودة' : 'Draft'),
              ),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedStatus = val;
                });
              }
            },
          ),
        ],
      ),
    );
  }
}

class _QuestionBankRow extends StatelessWidget {
  const _QuestionBankRow({
    required this.title,
    required this.metadata,
    required this.status,
    required this.onDelete,
    required this.onEdit,
  });

  final String title, metadata, status;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.warmSurface,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.help_outline,
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
                Row(
                  children: [
                    Text(
                      metadata,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(width: 12),
                    StatusBadge(statusKey: status),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: onEdit,
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: AppColors.inkBlue,
                ),
                tooltip: Directionality.of(context) == TextDirection.rtl
                    ? 'تعديل'
                    : 'Edit',
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: AppColors.error,
                ),
                tooltip: Directionality.of(context) == TextDirection.rtl
                    ? 'حذف'
                    : 'Delete',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
