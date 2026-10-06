# QuizFlow Flutter Design Implementation Instructions

## Objective

Apply the uploaded QuizFlow bilingual university quiz-system design consistently across the entire Flutter project. Use the original UI archive, the supplied reference screenshots, and this document as the visual source of truth.

Do not create a generic Material dashboard. The final application must preserve the QuizFlow identity: a calm academic workspace with a dark navigation rail, warm paper surfaces, compact status signals, restrained typography, asymmetric layouts, and complete Arabic RTL support.

## General implementation process

Before changing code, inspect the existing Flutter project structure, routing, theme, localization, state management, reusable widgets, and feature screens. Reuse the existing architecture where practical, but refactor shared visual behavior into a central design system instead of applying unrelated one-off styling to individual pages.

Implement the shared theme and application shell first. Then update authentication, dashboard, question bank, quiz management, student attempt, and results screens so that they all use the same spacing, typography, colors, surfaces, controls, status states, and directionality rules.

After each major screen is updated, run the application at desktop width and Arabic RTL. Compare the result against the supplied screenshots. Complete the work only after testing both Arabic and English layouts at desktop and mobile widths.

## Visual identity

The design direction is **Scholarly Signal**. The interface should feel precise, warm, trustworthy, and academic. It should not resemble a colorful consumer application or a standard admin template.

The primary canvas is warm off-white. Content cards are warm paper rather than bright white. Deep ink blue is reserved for the navigation rail, page titles, primary actions, and active states. Teal communicates confirmed progress, approval, live availability, and selected states. Saffron communicates attention, drafts, scheduled states, and active indicators. Red is reserved for errors and destructive actions.

Use the following centralized color tokens:

| Token | Value | Usage |
|---|---|---|
| Background | `#FBF8F2` | Application canvas |
| Paper | `#FFFDF9` | Cards, panels, forms |
| Ink blue | `#173F5F` | Rail, headings, primary buttons |
| Active blue | `#245473` | Selected navigation item |
| Teal | `#3C8D89` | Approved, live, selected, progress |
| Dark teal | `#246D6A` | Teal text and icons |
| Saffron | `#D99A2B` | Draft, scheduled, focus, active marker |
| Border | `#E8E1D7` | Card and field borders |
| Warm surface | `#F4F0E8` | Notes, criteria, filters |
| Error | `#B42318` | Error states |

Keep borders subtle, shadows restrained, and surfaces mostly flat. Use 6–8 px radii for inputs and standard buttons, 8–13 px for feature cards, and pill shapes only for status badges or compact controls.

## Typography

Use IBM Plex Sans Arabic or another high-quality Arabic-capable font across the application. Configure the font and text scale centrally. Do not rely on unmodified default Flutter Material typography.

The hierarchy should be quiet and deliberate. Main page titles are large and deep blue, subtitles are smaller and muted, section labels are compact, and row metadata is noticeably smaller than titles.

| Element | Starting size |
|---|---:|
| Desktop page title | 42–48 px for Arabic, approximately 31–36 px for compact English layouts |
| Mobile page title | 27–32 px |
| Section title | 24–32 px |
| Metric value | 30–48 px depending on card size |
| Main card title | 18–24 px |
| Navigation label | 14–16 px |
| Supporting metadata | 13–15 px |
| Status badge | 13–15 px |
| Small overline | 10–12 px |

Arabic text requires relaxed line height, approximately 1.5–1.65. Use `TextAlign.start`; do not hard-code left or right alignment.

## Shared application shell

Create one reusable authenticated shell for all role-based screens. On wide screens, use a fixed navigation rail and a main content frame. The main frame contains a sticky utility bar and a padded content canvas. On mobile, replace the rail with an off-canvas drawer and a menu button.

The desktop rail should be approximately 252 px wide. It uses `#173F5F`, contains the QuizFlow brand mark and wordmark, and remains visually prominent. The active navigation item uses `#245473` and a thin saffron indicator on its logical edge. Inactive items use pale blue-gray text and outline icons. Place the logout control at the bottom.

The desktop top bar should be approximately 76 px high. It contains the QuizFlow wordmark, language switch, notification icon with a small saffron dot, and compact circular profile avatar. It should have a warm translucent surface and a subtle bottom border. On mobile, reduce the height to approximately 66 px, show a menu button, hide the desktop breadcrumb, and simplify the profile controls.

The page canvas should use approximately 42 px horizontal padding on desktop and 17 px on mobile. Avoid excessive blank space between the top bar, page header, and first content panel. Keep the content dense but comfortable.

## RTL and localization

Arabic is a first-class layout mode, not merely translated copy. Configure generated Flutter localization resources for Arabic and English. Switching locale must update the application locale and layout direction without losing the current route unnecessarily.

Use `TextDirection.rtl` through locale-aware app directionality. Use `EdgeInsetsDirectional`, `AlignmentDirectional`, `BorderRadiusDirectional`, `PositionedDirectional`, logical start/end alignment, and mirrored directional icons. Never implement RTL by manually reversing strings or hard-coding left/right values.

Arabic requirements include the following behavior:

| Element | Arabic behavior |
|---|---|
| Navigation rail | Logical right side |
| Page title/subtitle | Right aligned |
| Primary action | Logical opposite side of title |
| Status badges | Logical leading side of list rows |
| Progress and dividers | Mirror consistently |
| Back/forward icons | Reflect logical direction |
| Search and form fields | Use start alignment and directional padding |
| Numbers and percentages | Remain readable within Arabic text |

All user-visible strings must come from localization resources. Localize dates, times, numbers, status labels, actions, errors, and empty states.

## Shared components

Build reusable components before duplicating page-specific versions. At minimum, create shared components for the application shell, page header, primary and secondary buttons, metric card, status badge, signal/progress line, paper panel, searchable list, empty state, toast/success strip, readiness card, and responsive section layout.

The page header should consistently contain a small colored overline rule, a title, a subtitle, and an optional action aligned to the opposite side. The same structure should appear on dashboard, question bank, quizzes, and results screens.

Status badges must combine color with text and a small dot or icon. Use teal for approved/live, blue for scheduled, saffron for draft or pending, and slate gray for closed or inactive. Do not communicate state using color alone.

Signal lines are a signature QuizFlow element. Use thin horizontal progress lines under metric values, quiz rows, readiness sections, and reports. Keep the line height around 2–4 px and use a small accent tick where appropriate.

## Screen implementation requirements

### Authentication

Use a centered warm paper card approximately 430 px wide on desktop. Include the QuizFlow brand lockup, a small graduation-project overline, a centered title, short description, login/register tabs, compact labeled fields, dark primary submit button, localized validation errors, and an Arabic/English switch. Do not use a marketing hero, gradient, or full-screen illustration.

### Instructor dashboard

Use a page header followed by three compact metric cards. Each metric card should have a colored top edge, small label, prominent value, icon square, supporting note, and signal line.

Below the metrics, use an asymmetric desktop layout. The main column contains a recent-quizzes list with compact rows, status badges, course metadata, dates, attempts, progress, and contextual actions. The narrower side column contains a dark readiness card, upcoming deadlines with small date blocks, and a muted activity card. Stack the side column below the main list on mobile.

### Student dashboard

Use a supportive learning-space header with greeting, subtitle, and progress card. Show a large available-quiz paper card with live status, title, course, duration, question count, attempt limit, availability deadline, and a dark `Start quiz` button. Add a dark next-quiz card and a small study-note illustration card in the side column.

### Question bank

Use a page header with an `Add question` action, a wide paper search field, and a large connected paper panel rather than an overly dense generic data table. Each question row should show the prompt, course and points metadata, a compact review-status badge, and edit/delete actions. Use clear horizontal separators and appropriate mobile card behavior.

Use teal for approved, saffron for in-review, and gray for draft. Provide a clear empty state and confirmation for destructive actions.

### Question editor

Use a large paper editor card with a question textarea and answer rows. Each answer row contains a radio button for the correct answer, a letter label, and an input. Place course and guidance controls in a narrower warm sidebar with a saffron top edge. Use a clear saved-success strip after saving. Stack the editor and sidebar on mobile.

### Quizzes

Use a page header with a publish action and one large paper overview panel. The panel should contain compact horizontal quiz rows. Each row includes title, course, number of questions, duration, attempt limit, status badge, and a full-width divider. Avoid many unrelated floating cards.

### Quiz builder and review

Use a three-step content/review/publish stepper with the active step marked by deep blue text and a saffron underline. The builder uses a two-column form card and readiness card. The review screen uses a connected content-summary/question-list panel beside a publish-settings card. Keep audience, mode, duration, attempts, result policy, and final publish action clearly grouped.

### Student attempt

Use a focused question stage with a question navigator, progress/remaining time, question prompt, stacked answer controls, and previous/next actions. The question navigator uses numbered buttons with separate unanswered, answered, and current states. On desktop it sits beside the question stage; on mobile it moves above it. Do not animate the timer.

### Results and reports

Use compact metric cards followed by paper report panels. Results should emphasize list-based performance rows, course and quiz summaries, averages, pass/completion rates, and student performance. Keep charts restrained and aligned with the signal-line visual language. Do not turn the page into a saturated analytics dashboard.

## Responsive behavior

At wide desktop widths, preserve the navigation rail, asymmetric content grid, three-column metric row, and main-plus-signal-column layout. At widths below approximately 1050 px, reduce page padding and stack signal content where necessary. Below approximately 760 px, hide the rail behind a drawer, simplify the top bar, stack page headers, collapse metric grids, make content panels full width, and convert dense rows into readable cards.

Mobile must not be a shrunken desktop layout. Preserve reading order, touch target size, status visibility, and logical RTL mirroring.

## Data and architecture boundaries

Use proper Flutter feature architecture and repository interfaces. Fixture data is acceptable while building the design, but production behavior must not copy browser `localStorage`, `sessionStorage`, or client-side password checks from the prototype.

Use server-backed authentication, role-based authorization, questions, quizzes, attempts, scoring, results, notifications, and audit history. The backend must enforce permissions, timing, attempt limits, correct answers, and result visibility.

## Verification requirements

Run the application at approximately 1920×1080 and verify Arabic RTL screens for dashboard, question bank, quizzes, and results. Also verify English LTR and mobile layouts.

The implementation is not complete if the page content is pushed too far below the top bar, the title is visually isolated, metric cards are tall empty boxes, the side signal column is missing, list screens become generic tables, the active rail indicator is missing, or Arabic is simulated rather than fully mirrored.

Run formatting, static analysis, unit/widget tests, and the available build command. Report changed files and unresolved issues after implementation.

## Reference materials

Use these files as supporting references when working in Codex:

- `bilingual-quiz-system-flutter-instructions.md` — detailed Flutter design and screen specification.
- `CODEX_VISUAL_CORRECTION_QUIZFLOW.md` — screenshot-derived correction details.
- The original `bilingual-quiz-system-ui.zip` archive — source UI and styles.
- Supplied QuizFlow reference screenshots — visual comparison targets.
