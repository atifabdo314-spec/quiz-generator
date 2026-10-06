import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:quizz_generator/backend/backend.dart';
import 'package:quizz_generator/state/app_page.dart';
import 'package:quizz_generator/state/user_role.dart';

class AppState extends Equatable {
  const AppState({
    this.signedIn = false,
    this.role = UserRole.instructor,
    this.page = AppPage.dashboard,
    this.questionCount = 24,
    this.answerSelected = false,
    this.submitted = false,
    this.loading = false,
    this.errorMessage,
    this.name = '',
    this.userId = '',
    this.selectedQuizId = '',
  });

  final bool signedIn, answerSelected, submitted;
  final UserRole role;
  final AppPage page;
  final int questionCount;
  final bool loading;
  final String? errorMessage;
  final String name;
  final String userId;
  final String selectedQuizId;

  AppState copyWith({
    bool? signedIn,
    UserRole? role,
    AppPage? page,
    int? questionCount,
    bool? answerSelected,
    bool? submitted,
    bool? loading,
    String? errorMessage,
    bool clearError = false,
    String? name,
    String? userId,
    String? selectedQuizId,
  }) => AppState(
    signedIn: signedIn ?? this.signedIn,
    role: role ?? this.role,
    page: page ?? this.page,
    questionCount: questionCount ?? this.questionCount,
    answerSelected: answerSelected ?? this.answerSelected,
    submitted: submitted ?? this.submitted,
    loading: loading ?? this.loading,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    name: name ?? this.name,
    userId: userId ?? this.userId,
    selectedQuizId: selectedQuizId ?? this.selectedQuizId,
  );

  @override
  List<Object?> get props => [
    signedIn,
    role,
    page,
    questionCount,
    answerSelected,
    submitted,
    loading,
    errorMessage,
    name,
    userId,
    selectedQuizId,
  ];
}

class AppCubit extends Cubit<AppState> {
  AppCubit({this.firebaseInitialized = true}) : super(const AppState()) {
    if (firebaseInitialized) {
      checkSession();
    }
  }

  final bool firebaseInitialized;

  BackendAuth get _auth => Backend.instance.auth;
  BackendStore get _store => Backend.instance.store;

  Future<void> checkSession() async {
    if (!firebaseInitialized) return;
    await _auth.restoreSession();
    final user = _auth.currentUser;
    if (user != null) {
      emit(state.copyWith(loading: true));
      try {
        final doc = await _store.collection('users').doc(user.uid).get();
        final roleStr = doc.data['role'] as String?;
        final name = (doc.data['name'] as String?) ?? '';
        final userRole = roleStr == 'admin'
            ? UserRole.admin
            : (roleStr == 'student' ? UserRole.student : UserRole.instructor);
        emit(
          state.copyWith(
            signedIn: true,
            role: userRole,
            name: name,
            userId: user.uid,
            page: AppPage.dashboard,
            loading: false,
          ),
        );
      } catch (e) {
        emit(
          state.copyWith(
            signedIn: true,
            role: UserRole.instructor, // fallback
            page: AppPage.dashboard,
            loading: false,
          ),
        );
      }
    }
  }

  Future<void> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    emit(state.copyWith(loading: true, errorMessage: null, clearError: true));

    if (!firebaseInitialized) {
      emit(
        state.copyWith(
          loading: false,
          errorMessage: 'Firebase is not initialized. Cannot sign in.',
        ),
      );
      return;
    }

    try {
      final user = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final doc = await _store.collection('users').doc(user.uid).get();
      var userRole = UserRole.instructor;
      String name = '';
      if (doc.exists) {
        final roleStr = doc.data['role'] as String?;
        name = (doc.data['name'] as String?) ?? '';
        userRole = roleStr == 'admin'
            ? UserRole.admin
            : (roleStr == 'student' ? UserRole.student : UserRole.instructor);
      }
      emit(
        state.copyWith(
          signedIn: true,
          role: userRole,
          name: name,
          userId: user.uid,
          page: AppPage.dashboard,
          loading: false,
        ),
      );
    } on BackendAuthException catch (e) {
      emit(
        state.copyWith(
          loading: false,
          errorMessage: e.message,
        ),
      );
    } catch (e) {
      emit(state.copyWith(loading: false, errorMessage: e.toString()));
    }
  }

  Future<void> registerWithEmailAndPassword(
    String email,
    String password,
    UserRole role, {
    String name = '',
  }) async {
    emit(state.copyWith(loading: true, errorMessage: null, clearError: true));

    if (!firebaseInitialized) {
      emit(
        state.copyWith(
          loading: false,
          errorMessage: 'Firebase is not initialized. Cannot register.',
        ),
      );
      return;
    }

    try {
      final user = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
        role: role.name,
      );
      await _store.collection('users').doc(user.uid).set({
        'name': name,
        'email': email,
        'role': role.name,
      });
      emit(
        state.copyWith(
          signedIn: true,
          role: role,
          name: name,
          userId: user.uid,
          page: AppPage.dashboard,
          loading: false,
        ),
      );
    } on BackendAuthException catch (e) {
      emit(
        state.copyWith(
          loading: false,
          errorMessage: e.message,
        ),
      );
    } catch (e) {
      emit(state.copyWith(loading: false, errorMessage: e.toString()));
    }
  }

  Future<void> signOut() async {
    emit(state.copyWith(loading: true));
    try {
      await _auth.signOut();
    } catch (_) {}
    emit(const AppState());
  }

  void clearError() {
    emit(state.copyWith(clearError: true));
  }

  void navigate(AppPage page) => emit(state.copyWith(page: page));
  void startQuiz(String quizId) => emit(
        state.copyWith(selectedQuizId: quizId, page: AppPage.attempt),
      );
  void addQuestion() =>
      emit(state.copyWith(questionCount: state.questionCount + 1));
  void selectAnswer() => emit(state.copyWith(answerSelected: true));
  void submit() => emit(state.copyWith(submitted: true));
}
