import 'package:quizz_generator/backend/backend.dart';
import 'package:flutter/material.dart';
import 'package:quizz_generator/theme/colors.dart';
import 'package:quizz_generator/widgets/app_card.dart';
import 'package:quizz_generator/widgets/localization_extensions.dart';
import 'package:quizz_generator/widgets/page_heading.dart';
import 'package:quizz_generator/widgets/stream_error_state.dart';

class SubjectsScreen extends StatelessWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeading(titleKey: 'subjects', subtitleKey: 'subjectsIntro'),
        const SizedBox(height: 26),

        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: FilledButton.icon(
            onPressed: () => _showSubjectDialog(context, isRtl: isRtl),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.inkBlue,
            ),
            icon: const Icon(Icons.add, size: 18),
            label: Text(
              context.text('addSubject'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 18),

        StreamBuilder<BackendSnapshot>(
          stream: Backend.instance.store
              .collection('subjects')
              .orderBy('name')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return AppCard(
                child: StreamErrorState(isRtl: isRtl),
              );
            }
            if (!snapshot.hasData) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: AppColors.inkBlue),
                ),
              );
            }

            final docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return _SubjectsEmptyState(isRtl: isRtl);
            }

            return AppCard(
              title: context.text('subjects'),
              child: Column(
                children: List.generate(docs.length * 2 - 1, (index) {
                  if (index.isOdd) {
                    return const Divider(height: 1);
                  }
                  final doc = docs[index ~/ 2];
                  final data = doc.data;
                  return _SubjectRow(
                    name: data['name'] ?? '',
                    onEdit: () => _showSubjectDialog(
                      context,
                      isRtl: isRtl,
                      existingId: doc.id,
                      existingName: data['name'] ?? '',
                    ),
                    onDelete: () => _confirmDelete(context, doc.id, isRtl),
                  );
                }),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _showSubjectDialog(
    BuildContext context, {
    required bool isRtl,
    String? existingId,
    String existingName = '',
  }) async {
    final controller = TextEditingController(text: existingName);
    final isEdit = existingId != null;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        final formKey = GlobalKey<FormState>();
        return AlertDialog(
          backgroundColor: AppColors.paper,
          title: Text(
            isEdit
                ? context.text('editSubject')
                : context.text('addSubject'),
          ),
          content: SizedBox(
            width: 380,
            child: Form(
              key: formKey,
              child: TextFormField(
                controller: controller,
                autofocus: true,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: context.text('subjectName'),
                  labelStyle: const TextStyle(color: AppColors.muted),
                  filled: true,
                  fillColor: AppColors.canvas,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty
                        ? context.text('subjectRequired')
                        : null,
                onFieldSubmitted: (_) {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(context, true);
                  }
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.text('cancel')),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, true);
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.inkBlue,
              ),
              child: Text(
                isEdit
                    ? context.text('saveQuestion')
                    : context.text('addSubject'),
              ),
            ),
          ],
        );
      },
    );

    if (saved != true) return;

    final name = controller.text.trim();
    final collection = Backend.instance.store.collection('subjects');
    try {
      if (isEdit) {
        await collection.doc(existingId).update({'name': name});
      } else {
        await collection.add({
          'name': name,
          'createdAt': BackendFieldValue.serverTimestamp,
        });
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              backgroundColor: AppColors.teal,
              content: Text(context.text('subjectSaved')),
            ),
          );
      }
    } catch (_) {}
  }

  Future<void> _confirmDelete(
    BuildContext context,
    String id,
    bool isRtl,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.paper,
        title: Text(
          isRtl ? 'حذف المادة' : 'Delete subject',
        ),
        content: Text(
          isRtl
              ? 'هل أنت متأكد من حذف هذه المادة؟'
              : 'Are you sure you want to delete this subject?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.text('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text(isRtl ? 'حذف' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await Backend.instance.store
          .collection('subjects')
          .doc(id)
          .delete();
    }
  }
}

class _SubjectRow extends StatelessWidget {
  const _SubjectRow({
    required this.name,
    required this.onEdit,
    required this.onDelete,
  });

  final String name;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.teal.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.menu_book_outlined,
              color: AppColors.teal,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.inkBlue,
                fontSize: 15,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: onEdit,
            tooltip: isRtl ? 'تعديل' : 'Edit',
            icon: const Icon(Icons.edit_outlined, color: AppColors.inkBlue),
          ),
          IconButton(
            onPressed: onDelete,
            tooltip: isRtl ? 'حذف' : 'Delete',
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
          ),
        ],
      ),
    );
  }
}

class _SubjectsEmptyState extends StatelessWidget {
  const _SubjectsEmptyState({required this.isRtl});
  final bool isRtl;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Icon(Icons.menu_book_outlined, size: 40, color: AppColors.muted),
            const SizedBox(height: 12),
            Text(
              isRtl
                  ? 'لا توجد مواد بعد.'
                  : 'No subjects yet.',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.inkBlue,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}