## 2026-11-09T19:19:10Z
Sender: 6756ae02-4558-4e4c-95a6-b9d1af3cbd26
Priority: MESSAGE_PRIORITY_HIGH

DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

You are Worker M1 implementing Milestone 1: Pure Dart Domain Layer & Unit Tests for `auth` and `pharmacy_search` features in Afya Santé (`package:medmate`).
Working directory: /home/charles/Documents/Work/Me/MedMate/.agents/teamwork/worker_m1/

Authoritative references to read:
- /home/charles/Documents/Work/Me/MedMate/.agents/teamwork/ORIGINAL_REQUEST.md
- /home/charles/Documents/Work/Me/MedMate/.agents/teamwork/PROJECT.md
- /home/charles/Documents/Work/Me/MedMate/.agents/teamwork/spec_miner_survey_1/spec_domain.md
- /home/charles/Documents/Work/Me/MedMate/lib/core/errors/failures.dart

Your Scope & Files Owned:
1. `lib/core/errors/failures.dart`:
   Add `ValidationFailure` as a `final class ValidationFailure extends Failure` with code 'VALIDATION_ERROR'.
2. `lib/features/auth/domain/`:
   - `entities/patient_session.dart`: `PatientSession` (sessionId, phoneNumber, createdAt, lastActiveAt, isAnonymous getter, copyWith, Equatable)
   - `entities/pharmacist_profile.dart`: `PharmacistProfile` (userId, pharmacyId, licenceOnpc, role, fullName, email, telephone, isVerified, copyWith, Equatable)
   - `entities/user_session.dart`: `UserSession` (sessionId, patientSession, pharmacistProfile, isAuthenticated getter, copyWith, Equatable)
   - `repositories/auth_repository.dart`: abstract contract `AuthRepository` with `getCurrentSession()`, `signInPharmacist({required String email, required String password})`, `signOut()` returning `Future<Either<Failure, T>>`
   - `usecases/get_current_session_usecase.dart`: `GetCurrentSessionUseCase`
   - `usecases/sign_in_pharmacist_usecase.dart`: `SignInPharmacistUseCase` (with `SignInPharmacistParams`)
   - `usecases/sign_out_usecase.dart`: `SignOutUseCase`
3. `lib/features/pharmacy_search/domain/`:
   - `entities/medication.dart`: `Medication` (id, codeNational, nomCommercial, dci, forme, dosage, necessiteOrdonnance). MANDATORY INVARIANT: ABSOLUTELY NO PRICE FIELD.
   - `entities/pharmacy.dart`: `Pharmacy` (id, nom, licenceOnpc, quartier, carrefourRepere, latitude, longitude, telephoneGarde, estOuverte, estDeGarde, estPartenaire, distanceMetres, copyWith, Equatable)
   - `repositories/pharmacy_search_repository.dart`: abstract contract `PharmacySearchRepository` with `searchMedications(String query)` and `searchNearbyPharmacies(...)`
   - `usecases/search_medications_usecase.dart`: `SearchMedicationsUseCase` (with `SearchMedicationsParams`, handles query validation)
   - `usecases/search_nearby_pharmacies_usecase.dart`: `SearchNearbyPharmaciesUseCase` (with `SearchNearbyPharmaciesParams`, validates that at least quartier/carrefour or coordinates are provided)
4. Unit Tests under `test/features/`:
   - `test/features/auth/domain/entities/patient_session_test.dart`
   - `test/features/auth/domain/entities/pharmacist_profile_test.dart`
   - `test/features/auth/domain/entities/user_session_test.dart`
   - `test/features/auth/domain/usecases/get_current_session_usecase_test.dart`
   - `test/features/auth/domain/usecases/sign_in_pharmacist_usecase_test.dart`
   - `test/features/auth/domain/usecases/sign_out_usecase_test.dart`
   - `test/features/pharmacy_search/domain/entities/medication_test.dart` (MUST explicitly verify absence of price field and equality)
   - `test/features/pharmacy_search/domain/entities/pharmacy_test.dart`
   - `test/features/pharmacy_search/domain/usecases/search_medications_usecase_test.dart`
   - `test/features/pharmacy_search/domain/usecases/search_nearby_pharmacies_usecase_test.dart`

Quality Requirements:
- Pure Dart in domain: NO `package:flutter/...` imports, NO `dart:io`.
- Strict zero `dynamic`.
- DO NOT MODIFY `lib/main.dart`.
- Run `/home/charles/development/flutter/bin/dart analyze --fatal-infos --fatal-warnings` -> must be 0 errors, 0 warnings.
- Run `/home/charles/development/flutter/bin/flutter test` -> all tests must pass 100%. (Use BypassSandbox: true if executing flutter test).

When done, write `handoff.md` in your working directory and send a completion message to the orchestrator via `send_message`.
