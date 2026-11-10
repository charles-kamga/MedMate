# Dispatch: worker_m1_1 (Data Layer for auth, pharmacy_search & duty_pharmacy)

## Role & Mission
You are `worker_m1_1`, a specialized Teamwork Worker.
Your working directory is `/home/charles/Documents/Work/Me/MedMate/.agents/teamwork/worker_m1_1/`.
Your mission is to implement the complete data layer and tests for `auth`, `pharmacy_search`, and `duty_pharmacy` of Afya Santé (`package:medmate`), following Clean Architecture contracts established in Phase 1.

## Authoritative Documentation & Rules
- `/home/charles/Documents/Work/Me/MedMate/.agents/teamwork/ORIGINAL_REQUEST.md` (MUST READ FIRST)
- `/home/charles/Documents/Work/Me/MedMate/.agents/teamwork/PROJECT.md`
- `/home/charles/Documents/Work/Me/MedMate/AGENTS.md`
- `/home/charles/Documents/Work/Me/MedMate/.agents/rules/architecture.md`
- `/home/charles/Documents/Work/Me/MedMate/.agents/rules/coding-standards.md`
- `/home/charles/Documents/Work/Me/MedMate/.agents/rules/web-platform.md`

## Files Owned Exclusively by You
- `lib/features/auth/data/**`
- `lib/features/pharmacy_search/data/**`
- `lib/features/duty_pharmacy/data/**`
- `test/features/auth/data/**`
- `test/features/pharmacy_search/data/**`
- `test/features/duty_pharmacy/data/**`

Do NOT modify files owned by other modules.

## Requirements

### 1. `lib/features/auth/data/`
- **Models**:
  - `PatientSessionModel` (extends or converts to/from `PatientSession`)
  - `PharmacistProfileModel` (extends or converts to/from `PharmacistProfile`)
  - `UserSessionModel` (extends or converts to/from `UserSession`)
  - Ensure serialization (`toJson`, `fromJson`) and mapping to domain entities (`toDomain()`, `fromDomain()`).
- **Data Source**:
  - `AuthLocalDataSource` (abstract and concrete implementation `AuthLocalDataSourceImpl`):
    - Session storage in memory.
    - Seeded reference pharmacist credentials (e.g. `pharmacist@afya.cm` / `Afya2026!` with ONPC license `ONPC-2024-CMR-042`, pharmacyId `pharma-bastos-01`, full name `Dr. Charles Kamga`).
    - Methods: `Future<UserSessionModel> getCurrentSession()`, `Future<UserSessionModel> signInPharmacist(String email, String password)`, `Future<void> signOut()`.
- **Repository Implementation**:
  - `AuthRepositoryImpl` implementing `AuthRepository`:
    - Handles exceptions, maps to `Failure` (`AuthFailure`, `ValidationFailure`, etc.) using `Either<Failure, T>`.

### 2. `lib/features/pharmacy_search/data/`
- **Models**:
  - `MedicationModel`: MUST STRICTLY ENFORCE ZERO PRICE INVARIANT. No price or tariff field! Fields: `id`, `codeNational`, `nomCommercial`, `dci`, `forme`, `dosage`, `necessiteOrdonnance`.
  - `PharmacyModel`: fields matching `Pharmacy` (id, nom, licenceOnpc, quartier, carrefourRepere, latitude, longitude, telephoneGarde, estOuverte, estDeGarde, estPartenaire, distanceMetres).
- **Data Source**:
  - `YaoundePharmacyDataSource` (abstract and concrete implementation `YaoundePharmacyDataSourceImpl`):
    - Seeded catalog of approved Cameroonian/African medications (e.g. Paracetamol, Amoxicilline, Ibuprofene, Artemether-Lumefantrine / Coartem, Metformine, Omeprazole, Ciprofloxacine, etc.).
    - Seeded pharmacies in Yaoundé across diverse quarters (*Bastos, Mokolo, Biyem-Assi, Omnisports, Tsinga, Essos, Mendong, Nsam, Ngoa-Ekelle*) with realistic carrefours (*Carrefour Warda, Carrefour Obili, Carrefour Nlongkak, Carrefour Régie, Poste Centrale, Carrefour Emia, Carrefour MEEC*) and WGS84 coordinates. Include both partner (`estPartenaire: true`) and non-partner pharmacies.
    - `searchMedications(String query)`: tolerant search (case-insensitive, trims, prefix/substring matching across `nomCommercial` and `dci`).
    - `searchNearbyPharmacies({String? quartier, String? carrefourRepere, double? latitude, double? longitude, double? radiusMeters})`: spatial filtering by quarter/carrefour or distance calculation (Haversine formula in WGS84).
- **Repository Implementation**:
  - `PharmacySearchRepositoryImpl` implementing `PharmacySearchRepository`:
    - Returns `Either<Failure, List<Medication>>` and `Either<Failure, List<Pharmacy>>`.

### 3. `lib/features/duty_pharmacy/data/`
- **Models**:
  - `DutyScheduleModel` mapping to `DutySchedule` (`pharmacy`, `dateGarde`, `heureDebut`, `heureFin`, `verifieParOnpc`).
- **Data Source**:
  - `DutyPharmacyDataSource` (abstract and concrete implementation `DutyPharmacyDataSourceImpl`):
    - Realistic ONPC-verified duty roster for Yaoundé quarters with night and weekend coverage.
    - `getDutyPharmaciesByQuartier(String quartier)`: filters schedules for that quarter.
- **Repository Implementation**:
  - `DutyPharmacyRepositoryImpl` implementing `DutyPharmacyRepository`.

### 4. Tests
- Complete unit tests covering all models, datasources, and repositories:
  - `test/features/auth/data/models/...`
  - `test/features/auth/data/datasources/...`
  - `test/features/auth/data/repositories/...`
  - `test/features/pharmacy_search/data/models/...` (explicit test verifying absence of price in `MedicationModel`)
  - `test/features/pharmacy_search/data/datasources/...`
  - `test/features/pharmacy_search/data/repositories/...`
  - `test/features/duty_pharmacy/data/models/...`
  - `test/features/duty_pharmacy/data/datasources/...`
  - `test/features/duty_pharmacy/data/repositories/...`

## Mandatory Integrity Warning
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

## Quality Gates for Verification
Run:
`/home/charles/development/flutter/bin/dart analyze --fatal-infos --fatal-warnings`
`/home/charles/development/flutter/bin/flutter test test/features/auth/data test/features/pharmacy_search/data test/features/duty_pharmacy/data`

Write your report in `/home/charles/Documents/Work/Me/MedMate/.agents/teamwork/worker_m1_1/handoff.md`.


## 2026-11-09T22:25:36Z
You are worker_m1_1. Your working directory is /home/charles/Documents/Work/Me/MedMate/.agents/teamwork/worker_m1_1/.
You are working on Milestone 1 (R1) of Afya Santé (package:medmate): Data Layer & Tests for auth, pharmacy_search, and duty_pharmacy.

MANDATORY FIRST STEPS:
1. Read /home/charles/Documents/Work/Me/MedMate/.agents/teamwork/ORIGINAL_REQUEST.md
2. Read /home/charles/Documents/Work/Me/MedMate/.agents/teamwork/worker_m1_1/DISPATCH.md
3. Read /home/charles/Documents/Work/Me/MedMate/.agents/teamwork/PROJECT.md
4. Read /home/charles/Documents/Work/Me/MedMate/AGENTS.md and rules in .agents/rules/ (architecture.md, coding-standards.md, web-platform.md, testing.md)

SCOPE OF IMPLEMENTATION:
- lib/features/auth/data/
  - models/ (patient_session_model.dart, pharmacist_profile_model.dart, user_session_model.dart)
  - datasources/ (auth_local_data_source.dart: session storage in memory, seeded reference pharmacist credentials: e.g. pharmacist@afya.cm / Afya2026!, ONPC-2024-CMR-042)
  - repositories/ (auth_repository_impl.dart implementing AuthRepository with Either<Failure, T>)
- lib/features/pharmacy_search/data/
  - models/ (medication_model.dart STRICT ZERO PRICE INVARIANT: NO price or tariff field! pharmacy_model.dart matching domain Pharmacy with WGS84 and Yaoundé landmarks)
  - datasources/ (yaounde_pharmacy_data_source.dart: catalog of approved Cameroonian medications, seeded Yaoundé pharmacies across quarters Bastos, Mokolo, Biyem-Assi, Omnisports, Tsinga, Essos, Mendong, Nsam, etc. and carrefours, tolerant search, Haversine spatial filtering)
  - repositories/ (pharmacy_search_repository_impl.dart implementing PharmacySearchRepository)
- lib/features/duty_pharmacy/data/
  - models/ (duty_schedule_model.dart)
  - datasources/ (duty_pharmacy_data_source.dart: ONPC-verified duty rosters by quarter)
  - repositories/ (duty_pharmacy_repository_impl.dart implementing DutyPharmacyRepository)
- Comprehensive Unit Tests:
  - test/features/auth/data/** (models, datasource, repository)
  - test/features/pharmacy_search/data/** (models including explicit zero-price invariant test, datasource, repository)
  - test/features/duty_pharmacy/data/** (models, datasource, repository)
