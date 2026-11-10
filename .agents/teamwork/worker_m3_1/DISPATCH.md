# Dispatch: worker_m3_1 (Auth Presentation, Responsive AfyaAppShell & lib/main.dart)

## Role & Mission
You are `worker_m3_1`, a specialized Teamwork Worker.
Your working directory is `/home/charles/Documents/Work/Me/MedMate/.agents/teamwork/worker_m3_1/`.
Your mission is to implement the presentation layer for `auth`, the responsive navigation shell `AfyaAppShell`, update `lib/main.dart`, and write multi-viewport widget tests for Afya Santé (`package:medmate`).

## Authoritative Documentation & Rules
- `/home/charles/Documents/Work/Me/MedMate/.agents/teamwork/ORIGINAL_REQUEST.md` (MUST READ FIRST)
- `/home/charles/Documents/Work/Me/MedMate/.agents/teamwork/PROJECT.md`
- `/home/charles/Documents/Work/Me/MedMate/AGENTS.md`
- `/home/charles/Documents/Work/Me/MedMate/.agents/rules/architecture.md`
- `/home/charles/Documents/Work/Me/MedMate/.agents/rules/coding-standards.md`
- `/home/charles/Documents/Work/Me/MedMate/.agents/rules/web-platform.md`
- `/home/charles/Documents/Work/Me/MedMate/.agents/rules/testing.md`

## Files Owned Exclusively by You
- `lib/features/auth/presentation/**`
- `lib/core/navigation/afya_app_shell.dart`
- `lib/main.dart`
- `test/features/auth/presentation/**`
- `test/core/navigation/**`

## Strict Hard Constraints
1. **Widget Line Limits**:
   - `pharmacist_sign_in_view.dart` MUST be strictly `< 300 lines`.
   - `afya_app_shell.dart` MUST be strictly `< 350 lines`.
   - NO widget file may exceed 400 lines.
2. **Platform & Web Compatibility**:
   - ZERO unprotected `dart:io` imports. Use `kIsWeb` or `defaultTargetPlatform`.
   - Responsive breakpoints: Mobile (`width < 600px`) uses `NavigationBar`, Desktop (`width >= 600px`) uses `NavigationRail`.
   - Responsive sizing: Use `MediaQuery.sizeOf(context)` or `LayoutBuilder`. No rigid widths causing overflow.
3. **Typing & Clean Architecture**:
   - ZERO uncast `dynamic`.
   - Passive UI: widgets emit events/call cubit methods, no direct Supabase/network calls in widgets.
   - Use `flutter_bloc` / `BlocBuilder` / `BlocConsumer`.
4. **Color & Design Tokens**:
   - Medical Teal/Emerald (`AppColors.primary` #0D9488, #10B981) and Amber for alerts/guards.
   - NO bright red branding.

## Requirements

### 1. `lib/features/auth/presentation/`
- `controllers/auth_state.dart`:
  - Sealed class or Equatable `AuthState`: `AuthInitial`, `AuthLoading`, `AuthenticatedPatient`, `AuthenticatedPharmacist`, `AuthUnauthenticated`, `AuthError`.
- `controllers/auth_cubit.dart`:
  - `AuthCubit(AuthRepository authRepository)`:
    - `checkCurrentSession()`
    - `signInPharmacist(String email, String password)`
    - `signOut()`
- `views/pharmacist_sign_in_view.dart` (< 300 lines):
  - Form with email/ONPC ID input, password input with obscure toggle, sign in button with loading state, error display (SnackBar or Banner).
  - Clean layout, medical branding, accessible tap targets (>= 48x48 px), semantic labels.

### 2. `lib/core/navigation/afya_app_shell.dart` (< 350 lines)
- Responsive shell hosting the 4 core navigation destinations:
  1. *Recherche* (Pharmacies & Médicaments)
  2. *Gardes* (Pharmacies de garde à Yaoundé)
  3. *Réservation* (Commande flash & suivi)
  4. *Espace Pro* (Portail Pharmacien / Connexion)
- Layout:
  - On Mobile (`width < 600px`): `Scaffold` with `bottomNavigationBar: NavigationBar(...)`.
  - On Desktop/Tablet (`width >= 600px`): `Scaffold` with row containing `NavigationRail(...)` and `Expanded(child: body)`.
- Respects safe areas and accessibility.

### 3. `lib/main.dart`
- Initialize `WidgetsFlutterBinding.ensureInitialized()`.
- Setup providers (e.g., `MultiRepositoryProvider` and `MultiBlocProvider` providing `AuthRepository`, `AuthCubit`, `PharmacySearchRepository`, `ReservationRepository`, `DutyPharmacyRepository`, `PharmacistPortalRepository`).
- `MaterialApp` configured with `AppTheme.lightTheme`, title `AppConfig.appName` ("Afya Santé"), and home `AfyaAppShell`.

### 4. Tests
- `test/features/auth/presentation/controllers/auth_cubit_test.dart`:
  - Bloc test / unit test of states for initial, login success, login failure, sign out.
- `test/features/auth/presentation/views/pharmacist_sign_in_view_test.dart`:
  - Widget test rendering form, entering email/password, triggering login.
- `test/core/navigation/afya_app_shell_test.dart`:
  - Multi-viewport responsive tests:
    - Viewport 360x700: asserts `NavigationBar` is present, `NavigationRail` is absent.
    - Viewport 1280x800: asserts `NavigationRail` is present, `NavigationBar` is absent.
    - Tab switching: switching destinations updates the view.

## Mandatory Integrity Warning
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

## Quality Gates for Verification
Run:
`/home/charles/development/flutter/bin/dart analyze --fatal-infos --fatal-warnings`
`/home/charles/development/flutter/bin/flutter test test/features/auth/presentation test/core/navigation`
`/home/charles/development/flutter/bin/flutter build web --release`

Write your complete report in `/home/charles/Documents/Work/Me/MedMate/.agents/teamwork/worker_m3_1/handoff.md`.


## 2026-11-09T23:01:52Z
[Message] timestamp=2026-11-09T23:01:52Z sender=03e25d6a-a96c-4d57-bc95-e80457f35655 priority=MESSAGE_PRIORITY_HIGH content=You are worker_m3_1. Your working directory is /home/charles/Documents/Work/Me/MedMate/.agents/teamwork/worker_m3_1/.
You are working on Milestone 3 (R3) of Afya Santé (package:medmate): Auth Presentation, Responsive AfyaAppShell navigation, and lib/main.dart update.

MANDATORY FIRST STEPS:
1. Read /home/charles/Documents/Work/Me/MedMate/.agents/teamwork/ORIGINAL_REQUEST.md
2. Read /home/charles/Documents/Work/Me/MedMate/.agents/teamwork/worker_m3_1/DISPATCH.md
3. Read /home/charles/Documents/Work/Me/MedMate/.agents/teamwork/PROJECT.md
4. Read /home/charles/Documents/Work/Me/MedMate/AGENTS.md and rules in .agents/rules/ (architecture.md, coding-standards.md, web-platform.md, testing.md)

SCOPE OF IMPLEMENTATION:
- lib/features/auth/presentation/
  - controllers/auth_state.dart
  - controllers/auth_cubit.dart (managing session, signInPharmacist, signOut with AuthRepository)
  - views/pharmacist_sign_in_view.dart (MUST BE STRICTLY < 300 lines)
- lib/core/navigation/afya_app_shell.dart (MUST BE STRICTLY < 350 lines)
  - Responsive navigation shell:
    - Mobile (< 600px width): uses Scaffold with NavigationBar (4 tabs: Recherche, Gardes, Réservation, Espace Pro)
    - Desktop/Tablet (>= 600px width): uses Scaffold with NavigationRail on the left and expanded view on the right
- lib/main.dart
  - Configures app with repository and bloc providers (AuthRepository, AuthCubit, and repositories from M1 and M2), AppTheme.lightTheme, AppConfig.appName, and AfyaAppShell as home.
- Tests:
  - test/features/auth/presentation/controllers/auth_cubit_test.dart
  - test/features/auth/presentation/views/pharmacist_sign_in_view_test.dart
  - test/core/navigation/afya_app_shell_test.dart (Multi-viewport responsive tests: verifies NavigationBar at 360x700, verifies NavigationRail at 1280x800, verifies tab switching)

STRICT CONSTRAINTS:
- No widget file may exceed 400 lines (pharmacist_sign_in_view.dart < 300, afya_app_shell.dart < 350).
- ZERO uncast dynamic. Zero unprotected dart:io imports.
- Medical Teal/Emerald palette (#0D9488, #10B981) and Amber for guards/alerts. No bright red branding.
- Zero mock in UI: use real repositories and AuthCubit.

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

VERIFICATION:
Run:
/home/charles/development/flutter/bin/dart analyze --fatal-infos --fatal-warnings
/home/charles/development/flutter/bin/flutter test test/features/auth/presentation test/core/navigation
/home/charles/development/flutter/bin/flutter build web --release

Write your complete handoff report in /home/charles/Documents/Work/Me/MedMate/.agents/teamwork/worker_m3_1/handoff.md and notify the orchestrator via send_message.


## 2026-11-10T03:47:34Z
[Message] timestamp=2026-11-10T03:47:34Z sender=03e25d6a-a96c-4d57-bc95-e80457f35655 priority=MESSAGE_PRIORITY_HIGH content=**Context**: Resuming Milestone 3 (R3) after transient pause.
**Content**: Your progress has been inspected: `auth_cubit.dart`, `auth_state.dart`, `pharmacist_sign_in_view.dart` (240 lines), and `afya_app_shell.dart` (340 lines) are in place. The remaining steps are:
1. Update `lib/main.dart` with providers (`MultiRepositoryProvider` and `MultiBlocProvider`), `AppTheme.lightTheme`, and home `AfyaAppShell`.
2. Implement unit and widget tests:
   - `test/features/auth/presentation/controllers/auth_cubit_test.dart`
   - `test/features/auth/presentation/views/pharmacist_sign_in_view_test.dart`
   - `test/core/navigation/afya_app_shell_test.dart` (multi-viewport tests: 360x700 for mobile NavigationBar, 1280x800 for desktop NavigationRail, tab switching).
3. Run quality gates:
   - `/home/charles/development/flutter/bin/dart analyze --fatal-infos --fatal-warnings`
   - `/home/charles/development/flutter/bin/flutter test`
   - `/home/charles/development/flutter/bin/flutter build web --release`
4. Write your complete handoff report in `/home/charles/Documents/Work/Me/MedMate/.agents/teamwork/worker_m3_1/handoff.md` and send completion message.
**Action**: Resume execution immediately and complete the remaining steps.
