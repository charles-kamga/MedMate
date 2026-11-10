# Project: Afya Santé (MedMate) — Étape 2: Synchronized Data Layer, Responsive Navigation & Quality Gates

## Architecture
- Modular Clean Architecture with strict separation of layers:
  - `lib/features/<feature>/domain/` (pure Dart, zero UI, zero Supabase, zero `dart:io`, Equatable, fpdart `Either<Failure, T>`)
  - `lib/features/<feature>/data/`:
    - `models/` (DTOs with `fromJson`/`toJson` or entity conversion, strict zero-price on Medication models)
    - `datasources/` (local and in-memory sources, realistic seeded data for Yaoundé landmarks)
    - `repositories/` (implementations of domain repository interfaces returning `Either<Failure, T>`)
  - `lib/features/auth/presentation/`:
    - `controllers/` (`AuthCubit` & `AuthState` for patient & pharmacist sessions)
    - `views/` (`pharmacist_sign_in_view.dart` strictly < 300 lines)
  - `lib/core/navigation/`:
    - `afya_app_shell.dart` strictly < 350 lines, responsive breakpoint: Mobile (< 600px) NavigationBar, Desktop (>= 600px) NavigationRail
  - `lib/main.dart`: Root entrypoint initializing app configuration, repository providers, AuthCubit, and responsive shell.

## Synchronized In-Memory State Architecture (R2)
- To ensure zero mocks in the UI and absolute data consistency between the Patient and Pharmacist portals:
  - A shared in-memory coordinator (`InMemoryFlashOrderStore`) manages active flash requests, incoming demands, submitted counter quotes, and confirmed reservations.
  - When a patient submits a `FlashRequest`, it is immediately recorded in the store and dispatched to eligible partner pharmacies in Yaoundé (initial wave of 2 pharmacies).
  - The pharmacist portal data source observes/queries this shared store for demands addressed to the pharmacist's officine.
  - When the pharmacist submits a `CounterQuoteSubmission`, the quote is converted to a `PharmacyOffer` and appended to the patient's `FlashRequest.offresRecues`.
  - When the patient selects an offer, a `Reservation` is created with a generated 6-digit numeric OTP and a 2-hour TTL.
  - When the pharmacist validates the pickup OTP, the reservation status changes to confirmed, and `PharmacyDailyAnalytics` for that pharmacy is automatically incremented.
  - Full reactive synchronization via streams or shared state eliminates any state desynchronization.

## Invariants & Rules
1. **Strict Zero Price Invariant**:
   - Neither `Medication` nor `MedicationModel` contains any price or tariff field.
   - Prices exist exclusively in counter quotes (`OfferItemResponse`, `PharmacyOffer`, `CounterQuoteSubmission`).
2. **Yaoundé Spatial Landmarks & WGS84**:
   - Pharmacies mapped to real quarters (*Bastos, Mokolo, Biyem-Assi, Omnisports, Tsinga, Essos, Mendong, Nsam, etc.*) and intersections (*Carrefour Warda, Carrefour Obili, Carrefour Nlongkak, etc.*).
   - Proximity filtering by quarter/landmark and haversine/WGS84 distance.
3. **ONPC Ethical Neutrality & Round-Robin**:
   - Waves of 2 partner pharmacies with round-robin rotation. No ranking or sponsored listings.
4. **Widget Line Limits**:
   - No widget file may exceed 400 lines.
   - `pharmacist_sign_in_view.dart` < 300 lines (actual: 239).
   - `afya_app_shell.dart` < 350 lines (actual: 339).
5. **Platform Safety**:
   - Zero unprotected `dart:io` imports. Web-compatible compilation.
   - Zero uncast `dynamic` types.

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | Auth Models & DataSource | `UserModel`, `PatientSessionModel`, `PharmacistProfileModel`, `AuthLocalDataSource` with reference credentials | M1 | ORIGINAL_REQUEST §R1 |
| 2 | Auth Repository Impl | `AuthRepositoryImpl` linking datasource to domain contract | M1 | ORIGINAL_REQUEST §R1 |
| 3 | Pharmacy Search Models | `MedicationModel` (ZERO price), `PharmacyModel` (WGS84, Yaoundé landmarks) | M1 | ORIGINAL_REQUEST §R1 |
| 4 | Yaoundé Pharmacy DataSource | Approved catalog, fault-tolerant search, partner/non-partner filtering | M1 | ORIGINAL_REQUEST §R1 |
| 5 | Pharmacy Search Repository Impl | `PharmacySearchRepositoryImpl` | M1 | ORIGINAL_REQUEST §R1 |
| 6 | Duty Pharmacy Models & DataSource | `DutyScheduleModel`, `DutyPharmacyDataSource` (ONPC duty rosters) | M1 | ORIGINAL_REQUEST §R1 |
| 7 | Duty Pharmacy Repository Impl | `DutyPharmacyRepositoryImpl` | M1 | ORIGINAL_REQUEST §R1 |
| 8 | Reservation Models | `BasketItemModel`, `OfferItemResponseModel`, `PharmacyOfferModel`, `FlashRequestModel`, `ReservationModel` | M2 | ORIGINAL_REQUEST §R2 |
| 9 | Flash Order DataSource & Store | `InMemoryFlashOrderStore`, `FlashOrderDataSource` managing requests, waves, offers | M2 | ORIGINAL_REQUEST §R2 |
| 10 | Reservation Repository Impl | `ReservationRepositoryImpl` | M2 | ORIGINAL_REQUEST §R2 |
| 11 | Pharmacist Portal Models | `IncomingDemandModel`, `CounterQuoteSubmissionModel`, `PharmacyDailyAnalyticsModel` | M2 | ORIGINAL_REQUEST §R2 |
| 12 | Pharmacist Portal DataSource | `PharmacistPortalDataSource` using shared in-memory store, 3-status quotes, OTP validation | M2 | ORIGINAL_REQUEST §R2 |
| 13 | Pharmacist Portal Repository Impl | `PharmacistPortalRepositoryImpl` | M2 | ORIGINAL_REQUEST §R2 |
| 14 | Auth Presentation | `AuthCubit`, `AuthState`, `pharmacist_sign_in_view.dart` (< 300 lines) | M3 | ORIGINAL_REQUEST §R3 |
| 15 | Responsive AfyaAppShell | `afya_app_shell.dart` (< 350 lines) with Mobile NavigationBar & Desktop NavigationRail | M3 | ORIGINAL_REQUEST §R3 |
| 16 | Main Entrypoint Update | `lib/main.dart` with providers, theme, and responsive navigation shell | M3 | ORIGINAL_REQUEST §R3 |
| 17 | Multi-Viewport Tests | Responsive widget tests across compact (< 600px) and desktop (>= 600px) viewports | M3 | ORIGINAL_REQUEST §R3 |
| 18 | Post-Execution Audit & Quality Gates | Zero-price scan, lifecycle consistency test, zero `dart:io`, `dart analyze`, `flutter test`, `flutter build web --release` | M4 | ORIGINAL_REQUEST §R4 |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | M1: Data Layer Auth, Pharmacy Search & Duty Pharmacy | Models, DataSources (`AuthLocalDataSource`, `YaoundePharmacyDataSource`, `DutyPharmacyDataSource`), Repositories + Tests | Phase 1 Domain | DONE |
| 2 | M2: Data Layer Reservation & Pharmacist Portal | Synchronized In-Memory Store, Models, DataSources, Repositories + Lifecycle Tests | Phase 1 Domain | DONE |
| 3 | M3: Auth Presentation, Responsive AfyaAppShell & main.dart | `AuthCubit`, `PharmacistSignInView` (< 300 lines), `AfyaAppShell` (< 350 lines), `lib/main.dart` + Multi-Viewport Tests | M1, M2 | DONE |
| 4 | M4: Quality Gates, Adversarial Stress & Forensic Audit | Zero-price audit, full lifecycle integration test, `dart analyze`, `flutter test`, `flutter build web`, Forensic Auditor | M1, M2, M3 | DONE |
