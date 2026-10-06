import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizz_generator/localization/localization_manager.dart';
import 'package:quizz_generator/screens/login_page.dart';
import 'package:quizz_generator/state/app_cubit.dart';

Widget _wrap(Widget child) => EasyLocalization(
  supportedLocales: LocalizationManager.supportedLocales,
  path: LocalizationManager.translationsPath,
  fallbackLocale: LocalizationManager.fallbackLocale,
  startLocale: const Locale('en'),
  child: BlocProvider(
    create: (_) => AppCubit(firebaseInitialized: false),
    child: MaterialApp(home: Scaffold(body: child)),
  ),
);

/// The rule text is either the translated sentence or the raw key when the
/// translation bundle is not available inside the test.
Finder _passwordRuleError() => find.byWidgetPredicate(
  (w) => w is Text &&
      (w.data == 'validPassword' ||
          (w.data ?? '').contains('at least 6 characters')),
);

Future<void> _pumpLogin(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1280, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_wrap(const LoginPage()));
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

void main() {
  testWidgets('Sign-in accepts the 4-character seeded passwords', (
    tester,
  ) async {
    await _pumpLogin(tester);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'admin@quiz.local',
    );
    await tester.enterText(find.byType(TextFormField).at(1), '1234');

    await tester.tap(find.text('Sign In').last);
    await tester.pump();

    // The old rule rejected any password shorter than 6 characters.
    expect(_passwordRuleError(), findsNothing);
  });

  testWidgets('Register still enforces the 6-character rule', (tester) async {
    await _pumpLogin(tester);

    await tester.tap(find.text('Register').first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'New Person');
    await tester.enterText(find.byType(TextFormField).at(1), 'a@b.com');
    await tester.enterText(find.byType(TextFormField).at(2), '1234');

    await tester.tap(find.text('Register').last);
    await tester.pump();

    expect(_passwordRuleError(), findsOneWidget);
  });
}