import 'package:flutter/material.dart';
import 'package:quizz_generator/theme/colors.dart';
import 'package:quizz_generator/widgets/localization_extensions.dart';

class PageHeading extends StatelessWidget {
  const PageHeading({required this.titleKey, required this.subtitleKey, super.key});
  final String titleKey;
  final String subtitleKey;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 22, height: 3, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(height: 10),
          Text(context.text(titleKey), style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 8),
          Text(context.text(subtitleKey), style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.muted)),
        ],
      );
}
