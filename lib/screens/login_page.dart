import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizz_generator/theme/colors.dart';
import 'package:quizz_generator/widgets/app_card.dart';
import 'package:quizz_generator/widgets/localization_extensions.dart';
import 'package:quizz_generator/state/user_role.dart';
import 'package:quizz_generator/state/app_cubit.dart';
import 'package:quizz_generator/widgets/language_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        // Start each tab with a clean form (keep the email for convenience).
        _nameController.clear();
        _passwordController.clear();
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return BlocConsumer<AppCubit, AppState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.error,
              content: Text(state.errorMessage!),
            ),
          );
          context.read<AppCubit>().clearError();
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.canvas,
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: AppCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Language switcher at the top right
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: const LanguageButton(),
                        ),
                        const SizedBox(height: 10),

                        // Brand Lockup
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.inkBlue,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.school_outlined,
                                color: AppColors.saffron,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                'Quiz Generator',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.inkBlue,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Centered Title and Subtitle
                        Text(
                          _tabController.index == 0
                              ? context.text('welcomeBack')
                              : (isRtl ? 'إنشاء حساب جديد' : 'Create Account'),
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.inkBlue,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _tabController.index == 0
                              ? context.text('signInSubtitle')
                              : (isRtl
                                    ? 'سجل للبدء في استخدام نظام الاختبارات'
                                    : 'Sign up to start using the quiz system'),
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        // Login/Register Tabs
                        Container(
                          height: 46,
                          decoration: BoxDecoration(
                            color: AppColors.warmSurface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            indicatorSize: TabBarIndicatorSize.tab,
                            dividerColor: Colors.transparent,
                            indicator: BoxDecoration(
                              color: AppColors.paper,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            labelColor: AppColors.inkBlue,
                            unselectedLabelColor: AppColors.muted,
                            labelStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            tabs: [
                              Tab(text: isRtl ? 'تسجيل الدخول' : 'Sign In'),
                              Tab(text: isRtl ? 'إنشاء حساب' : 'Register'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Compact Labeled Name Field (registration only)
                        if (_tabController.index == 1) ...[
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: context.text('fullName'),
                              prefixIcon: const Icon(
                                Icons.person_outline,
                                color: AppColors.muted,
                                size: 20,
                              ),
                            ),
                            textInputAction: TextInputAction.next,
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? context.text('validName')
                                : null,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Compact Labeled Email Field
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: context.text('email'),
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              color: AppColors.muted,
                              size: 20,
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) =>
                              value == null || !value.contains('@')
                              ? context.text('validEmail')
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Compact Labeled Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: context.text('password'),
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: AppColors.muted,
                              size: 20,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return context.text('validPassword');
                            }
                            // Existing seeded accounts use short 4-character
                            // passwords, so only enforce the strong rule while
                            // creating a new account.
                            final minLength = _tabController.index == 1 ? 6 : 4;
                            return value.length < minLength
                                ? context.text('validPassword')
                                : null;
                          },
                        ),
                        const SizedBox(height: 18),

                        // Only student accounts can be created via public
                        // registration; teacher and admin accounts are
                        // created by a manager.
                       
                        const SizedBox(height: 28),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton(
                            onPressed: state.loading
                                ? null
                                : () {
                                    if (_formKey.currentState!.validate()) {
                                      if (_tabController.index == 0) {
                                        context
                                            .read<AppCubit>()
                                            .signInWithEmailAndPassword(
                                              _emailController.text.trim(),
                                              _passwordController.text.trim(),
                                            );
                                      } else {
                                        context
                                            .read<AppCubit>()
                                            .registerWithEmailAndPassword(
                                              _emailController.text.trim(),
                                              _passwordController.text.trim(),
                                              UserRole.student,
                                              name: _nameController.text.trim(),
                                            );
                                      }
                                    }
                                  },
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.inkBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: state.loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _tabController.index == 0
                                        ? context.text('signIn')
                                        : (isRtl ? 'إنشاء حساب' : 'Register'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
