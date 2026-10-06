# QuizFlow — Remaining Tasks (مهام متبقية)

Next implementation tasks for the QuizFlow bilingual graduation project (Flutter + Firebase). أيقونة المشروع: `lib/` — Flutter, Firebase Auth, Cloud Firestore.

---

## Task 1 — Create Profile Screen (إنشاء شاشة الملف الشخصي)

**Goal / الهدف**

A user-accessible profile screen showing the signed-in user's account information, role, and session actions. شاشة تعرض معلومات الحساب والدور وأزرار إدارة الجلسة.

### Requirements / المتطلبات

- Add a new route value to the `AppPage` enum in `lib/state/app_page.dart` (e.g. `profile`).
- Show the current user's:
  - Name (من `state.name`)
  - Email (from `FirebaseAuth.instance.currentUser?.email`)
  - Role badge (admin / instructor / student) translated in AR + EN using the existing `UserRole` mapping
  - User ID (optional, small/copyable)
- Add a profile icon to the sidebar (`_Rail` in `lib/screens/workspace_page.dart`) and the mobile `_Drawer` so every role can reach the screen.
- Actions available on the screen:
  - **Sign out** -> `context.read<AppCubit>().signOut()`
  - **Back to dashboard** -> `context.read<AppCubit>().navigate(AppPage.dashboard)`
- Follow the existing design system:
  - `AppColors.*`, `AppCard`, `PageHeading`, bilingual hardcoded strings (AR/EN) or new keys in `assets/lang/en.json` + `assets/lang/ar.json`
  - Arabic handled with `Directionality`, English default
- Profile avatar initials already exist as `_initials(name)` in `workspace_page.dart`; reuse a shared version.

### Suggested files / الملفات المقترحة

| File / الملف | Change / التغيير |
|---|---|
| `lib/state/app_page.dart` | Add `profile` to `AppPage` |
| `lib/screens/workspace_page.dart` | Register route in `_page()`, add icon to `_Rail` + `_Drawer` |
| `lib/screens/profile_page.dart` (new) | New profile screen widget |
| `assets/lang/en.json` / `assets/lang/ar.json` | Any new labels (`profile`, `userRole`, etc.) |

### Acceptance / معايير القبول

- All three roles can open profile from sidebar + drawer.
- Name, email, role badge, and sign-out work with live auth/session state.
- Renders correctly in both Arabic and English.

---

## Task 2 — Results Screen: Students Who Solved Quizzes & Questions (شاشة النتائج: الطلاب الذين حلّوا الاختبارات)

**Goal / الهدف**

Extend the results area so an instructor/admin can see which students solved which quizzes (and the questions covered), with per-student performance. شاشة تعرض للطالب-الخريج حسب الاختبارات والأسئلة.

### Current state / الوضع الحالي

- `lib/screens/results_page.dart` already streams `attempts` + `quizzes` and shows:
  - Metrics: completion rate, students passed, average score
  - `_QuizPerformancePanel` (per-quiz avg / pass rate)
  - `_StudentPerformancePanel` (recent 5 attempts)
- Attempts are saved to the Firestore `attempts` collection with `{ userId, name, email, score, total, percentage, submittedAt }`.

### Requirements / المتطلبات

- Keep the existing panels, and add a **student breakdown** that lists, for each quiz, the students who solved it:
  - Group `attempts` by `quizId` (or by quiz title when `quizId` is empty)
  - For each student row show: avatar initials, name, email, score (`score/total`), percentage, submission time
- Add a **questions breakdown** view (optional secondary tab/panel) that shows, per approved question, attempts answered or the count of correct/incorrect responses from the `attempts`/`questions` data.
- Empty state when no attempts exist: "No attempts yet" in AR + EN.
- Plumb the quiz id into student attempts so grouping is accurate: when a student starts a quiz, pass the selected quiz id through `AppCubit.navigate` / the attempt flow and save it in the attempt doc (`quizId`). Update `attempts` writes in `lib/screens/assessment_pages.dart`.
- Keep the screen role-gated to instructor/admin (already handled by `workspace_page.dart` route protection).

### Suggested files / الملفات المقترحة

| File / الملف | Change / التغيير |
|---|---|
| `lib/screens/assessment_pages.dart` | Persist `quizId` in the attempt doc when starting from a specific quiz |
| `lib/screens/quizzes_page.dart` / `dashboard_page.dart` | Pass the selected quiz id when navigating to the attempt page |
| `lib/screens/results_page.dart` | Group attempts by quiz, add per-studden solved list + question coverage |
| `lib/state/app_cubit.dart` | (optional) carry `selectedQuizId` in `AppState` |
| `assets/lang/en.json` / `assets/lang/ar.json` | New labels (`studentsSolved`, `perQuiz`, `noAttemptsYet`, etc.) |

### Acceptance / معايير القبول

- Instructor/admin opens Results and sees each quiz with the list of students who solved it (name, email, score, %).
- Data comes from the live Firestore `attempts` collection; zero fabricated rows.
- Empty database => clear empty state in both languages.
- `flutter analyze` passes with no errors/warnings from these changes.