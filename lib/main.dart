import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:quizz_generator/backend/backend.dart';
import 'package:quizz_generator/firebase_options.dart';
import 'package:quizz_generator/app/quizflow_app.dart';
import 'package:quizz_generator/localization/localization_manager.dart';
import 'package:quizz_generator/state/app_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final local = Backend.isLocalHost;
  bool firebaseInitialized = false;
  if (!local) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      firebaseInitialized = true;
    } catch (e) {
      debugPrint("Firebase initialization failed: $e");
    }
  }

  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: LocalizationManager.supportedLocales,
      path: LocalizationManager.translationsPath,
      fallbackLocale: LocalizationManager.fallbackLocale,
      startLocale: const Locale('ar'),
      child: BlocProvider(
        create: (_) => AppCubit(firebaseInitialized: local || firebaseInitialized),
        child: const QuizFlowApp(),
      ),
    ),
  );
}
