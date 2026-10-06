import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:quizz_generator/theme/app_theme.dart';
import 'package:quizz_generator/state/quizflow_home.dart';

class QuizFlowApp extends StatelessWidget {
  const QuizFlowApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'QuizFlow',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        home: const QuizFlowHome(),
      );
}
