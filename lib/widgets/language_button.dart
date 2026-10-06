import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key});
  @override Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    return TextButton.icon(onPressed: () => context.setLocale(isArabic ? const Locale('en') : const Locale('ar')), icon: const Icon(Icons.language, size: 18), label: Text(isArabic ? 'EN' : 'ع'));
  }
}
