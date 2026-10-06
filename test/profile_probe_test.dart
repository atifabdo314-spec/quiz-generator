import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizz_generator/screens/profile_page.dart';
import 'package:quizz_generator/state/app_cubit.dart';
import 'package:quizz_generator/state/user_role.dart';

void main() {
  testWidgets('ProfilePage renders with a name', (tester) async {
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => AppCubit(firebaseInitialized: false),
        child: const MaterialApp(
          home: Scaffold(
            body: ProfilePage(role: UserRole.instructor, name: 'Test User'),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Account Information'), findsOneWidget);
    expect(find.text('Role'), findsOneWidget);
    expect(find.text('Instructor'), findsOneWidget);
  });

  testWidgets('ProfilePage does not crash with an empty name', (tester) async {
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => AppCubit(firebaseInitialized: false),
        child: const MaterialApp(
          home: Scaffold(
            body: ProfilePage(role: UserRole.instructor, name: ''),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Account Information'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}