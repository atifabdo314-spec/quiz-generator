import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:quizz_generator/screens/login_page.dart';
import 'package:quizz_generator/state/app_cubit.dart';
import 'package:quizz_generator/screens/workspace_page.dart';

class QuizFlowHome extends StatelessWidget {
  const QuizFlowHome({super.key});

  @override
  Widget build(BuildContext context) => BlocBuilder<AppCubit, AppState>(
        builder: (context, state) => state.signedIn
            ? const WorkspacePage()
            : const LoginPage(),
      );
}
