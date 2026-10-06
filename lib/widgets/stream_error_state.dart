import 'package:flutter/material.dart';
import 'package:quizz_generator/theme/colors.dart';

class StreamErrorState extends StatelessWidget {
  const StreamErrorState({super.key, required this.isRtl});

  final bool isRtl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 36, color: AppColors.muted),
          const SizedBox(height: 12),
          Text(
            isRtl ? 'تعذر الاتصال بالخدمة' : 'Connection error',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.inkBlue,
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            isRtl
                ? 'لا يمكن الوصول إلى الخادم. تحقق من اتصالك بالإنترنت وحاول مرة أخرى.'
                : 'Unable to reach the server. Check your internet connection and try again.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}