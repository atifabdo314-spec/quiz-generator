import 'package:flutter/material.dart';
import 'package:quizz_generator/backend/backend.dart';
import 'package:quizz_generator/theme/colors.dart';
import 'package:quizz_generator/widgets/localization_extensions.dart';

void showAttemptDetails(
  BuildContext context,
  BackendDoc doc,
  bool isRtl,
) {
  final data = doc.data;
  final name = data['name']?.toString().trim() ?? '';
  final email = data['email']?.toString() ?? '';
  final score = data['score'] ?? 0;
  final total = data['total'] ?? 0;
  final pct = data['percentage'] ?? 0;
  final answers = (data['answers'] as List?) ?? const [];

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.paper,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      title: Text(
        isRtl ? 'تفاصيل المحاولة' : 'Attempt details',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 580,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isRtl
                    ? '$name — الدرجة: $score من $total ($pct%)'
                    : '$name — Score: $score / $total ($pct%)',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.inkBlue,
                  fontSize: 15,
                ),
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.muted,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              if (answers.isEmpty)
                Text(
                  isRtl
                      ? 'لا توجد تفاصيل إجابة لهذه المحاولة.'
                      : 'No answer details are stored for this attempt.',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                  ),
                )
              else
                ...answers.asMap().entries.map(
                  (entry) => AttemptAnswerTile(
                    index: entry.key + 1,
                    data: entry.value,
                    isRtl: isRtl,
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.text('cancel')),
        ),
      ],
    ),
  );
}

class AttemptAnswerTile extends StatelessWidget {
  const AttemptAnswerTile({
    required this.index,
    required this.data,
    required this.isRtl,
  });

  final int index;
  final dynamic data;
  final bool isRtl;

  @override
  Widget build(BuildContext context) {
    final map = data is Map<String, dynamic>
        ? data as Map<String, dynamic>
        : <String, dynamic>{};
    final isCorrect = map['isCorrect'] == true;
    final selected = (map['selected'] ?? '').toString().trim();
    final correct = (map['correct'] ?? '').toString().trim();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
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
          Text(
            '${isRtl ? 'السؤال' : 'Question'} $index',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isCorrect ? AppColors.teal : AppColors.error,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            map['prompt']?.toString() ?? '',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.inkBlue,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              text: isRtl ? 'الجواب: ' : 'Answer: ',
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
              text: isRtl ? 'الصحيح: ' : 'Correct: ',
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