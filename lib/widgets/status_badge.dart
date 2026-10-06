import 'package:flutter/material.dart';
import 'package:quizz_generator/theme/colors.dart';
import 'package:quizz_generator/widgets/localization_extensions.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({required this.statusKey, super.key});
  final String statusKey;

  @override
  Widget build(BuildContext context) {
    final color = switch (statusKey) {
      'liveNow' || 'approved' => AppColors.teal,
      'scheduled' || 'inReview' => AppColors.saffron,
      _ => AppColors.muted,
    };

    return Container(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Small dot indicator to not communicate state using color alone
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            context.text(statusKey),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
