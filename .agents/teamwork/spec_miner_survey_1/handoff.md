# Handoff Report — Spec Miner Survey 1

**Agent**: `spec_miner_survey_1`  
**Parent**: `orchestrator` (`6756ae02-4558-4e4c-95a6-b9d1af3cbd26`)  
**Mission**: Pure Dart Domain Specification for Phase 1 of Afya Santé (`package:medmate`) across all 5 features (`auth`, `pharmacy_search`, `reservation`, `duty_pharmacy`, `pharmacist_portal`).  
**Generated Specification**: `/home/charles/Documents/Work/Me/MedMate/.agents/teamwork/spec_miner_survey_1/spec_domain.md`

---

## 1. Observation

1. **Requirements & Scope**:
   - `ORIGINAL_REQUEST.md` (lines 13-53) mandates implementing Phase 1 pure Dart domain layer and unit tests across 5 features:
     - Feature 1: `auth` (Entities: `PatientSession`, `PharmacistProfile`, `UserSession`; Repository: `AuthRepository`; UseCases: `GetCurrentSessionUseCase`, `SignInPharmacistUseCase`, `SignOutUseCase`).
     - Feature 2: `pharmacy_search` (Entities: `Medication`, `Pharmacy`; Invariant: Zero price field in `Medication`; Repository: `PharmacySearchRepository`; UseCases: `SearchMedicationsUseCase`, `SearchNearbyPharmaciesUseCase`).
     - Feature 3: `reservation` (Entities: `BasketItem`, `ItemAvailabilityStatus`, `OfferItemResponse`, `PharmacyOffer`, `FlashRequest`, `Reservation`; Invariant: 6-digit OTP, 2-hour TTL; Repository: `ReservationRepository`; UseCases: `SubmitFlashRequestUseCase`, `EscalateDispatchWaveUseCase` [waves of 2 partner pharmacies in Round-Robin], `SelectPharmacyOfferUseCase`, `ConfirmReservationOtpUseCase`).
     - Feature 4: `duty_pharmacy` (Entities: `DutySchedule`; Repository: `DutyPharmacyRepository`; UseCases: `GetDutyPharmaciesByQuartierUseCase`).
     - Feature 5: `pharmacist_portal` (Entities: `IncomingDemand`, `CounterQuoteSubmission` [prices entered only at counter], `PharmacyDailyAnalytics` [Loi n° 2024/017 Zero PII]; Repository: `PharmacistPortalRepository`; UseCases: `SubmitCounterQuoteUseCase`, `ValidatePickupOtpUseCase`, `GetPharmacyAnalyticsUseCase`).
   - Line 49: "Zéro dépendance UI ou externe dans `domain/` : uniquement du Dart pur, `equatable` et `fpdart` (`Either<Failure, T>`)."
   - Line 50: "Zéro `dynamic` : typage strict partout."
   - Line 51: "Ne pas modifier `lib/main.dart` (aucune modification d'interface graphique dans cette étape)."
2. **Architecture & Project Invariants**:
   - `AGENTS.md` (§2) & `.agents/rules/architecture.md` (§2, §3): Invariant 1 (Politique Zéro Prix Affiché dans `Medication`), Invariant 2 (Souveraineté Cartographique OSM, repères urbains de Yaoundé), Invariant 3 (Neutralité déontologique ONPC, Round-Robin sans sponsoring).
   - `.agents/rules/security.md` (§4): Invariant 4 (Protection des données de santé Loi n° 2024/017 ANTIC/APDP, TTL 2h, OTP 6 chiffres, anonymisation/minimisation).
3. **Existing Codebase & Tooling**:
   - `pubspec.yaml` confirms packages: `equatable: ^2.0.5`, `fpdart: ^1.1.0`, `mocktail: ^1.0.4`, `freezed_annotation: ^3.1.0`.
   - `lib/core/errors/failures.dart` defines sealed `Failure` hierarchy (`NetworkFailure`, `ServerFailure`, `StorageFailure`, `CacheFailure`, `LocationFailure`, `AuthFailure`, `NotFoundFailure`, `InsufficientStockFailure`, `ReservationFailure`).
   - `lib/core/config/app_config.dart` defines `reservationTtl = Duration(hours: 2)`, `networkTimeout = Duration(seconds: 10)`.
   - `lib/core/constants/yaounde_landmarks.dart` defines `YaoundeLandmark` and `YaoundeLandmarks.list` with 12 canonical Yaoundé landmarks across 6 arrondissements.
   - `lib/features/` currently has directories but 0 files (virgin clean architecture canvas).
   - `test/` currently contains only `widget_test.dart` (which passes).

---

## 2. Logic Chain

1. From **Observation 1 & 3**, the domain layer must contain zero UI dependencies (`flutter/material.dart`, etc.) and zero `dart:io`. Using `equatable` directly for domain entities avoids relying on `build_runner` or platform-specific code in domain models, providing instant value equality (`props`), string representation, and immutability.
2. From **Observation 1 & 2 (Invariant 1)**, `Medication` in `pharmacy_search` must NOT contain any price property. Pricing is only established dynamically at the counter by pharmacists when responding to patient requests. Thus, prices are strictly isolated to `OfferItemResponse.prixUnitaireCommunicParPharmacien`, `PharmacyOffer.montantTotalPropose`, and `CounterQuoteSubmission.montantTotal`.
3. From **Observation 1 & 2 (Invariant 2)**, Yaoundé's geographical reality dictates that proximity cannot be a naive Euclidean radius. Pharmacies are indexed by `quartier`, `carrefourRepere`, and coordinates (`latitude`, `longitude`). `SearchNearbyPharmaciesUseCase` must validate that at least one spatial parameter is supplied before querying the repository.
4. From **Observation 1 & 2 (Invariant 3)**, the ONPC code of ethics forbids sponsored ranking. Dispatch escalation in `EscalateDispatchWaveUseCase` must advance in fair waves of exactly 2 unnotified partner pharmacies (`candidatePharmacyIds.where((id) => !alreadyNotified.contains(id)).take(2)`).
5. From **Observation 1 & 2 (Invariant 4)**, patient privacy under Law n° 2024/017 requires `PatientSession` to remain anonymous until reservation confirmation (where a phone number is provided). The reservation code `codeRetraitOtp6Chiffres` must strictly match 6 numeric digits (`r'^\d{6}$'`), and TTL is fixed at 2 hours. `PharmacyDailyAnalytics` in the pharmacist portal must aggregate only counts and conversion rates with zero personal health data.
6. From **Observation 1 & 3**, all repository contracts and usecase returns must strictly use `Either<Failure, T>` from `fpdart`, with failures typed to the `Failure` sealed class from `lib/core/errors/failures.dart`.

---

## 3. Caveats

- **Freezed vs Equatable in Domain**: Although `freezed_annotation` is present in `pubspec.yaml`, `ORIGINAL_REQUEST.md` (R5) strictly mandates: "Zéro dépendance UI ou externe dans `domain/` : uniquement du Dart pur, `equatable` et `fpdart` (`Either<Failure, T>`)". Equatable entities fulfill value equality, immutability, and copyWith without requiring code generation steps in `domain/`.
- **Validation Failures**: `lib/core/errors/failures.dart` is a sealed class hierarchy. Domain-level validation failures are mapped to existing domain failure types (`AuthFailure`, `ReservationFailure`, `LocationFailure`) with clear descriptive messages.
- No code was implemented by this agent (spec mining is read-only).

---

## 4. Conclusion

The specification for Phase 1 (Domain Layer & Unit Tests) has been mined, extracted, and documented in full detail in `/home/charles/Documents/Work/Me/MedMate/.agents/teamwork/spec_miner_survey_1/spec_domain.md`.
The specification provides:
- Exact signatures and field definitions for all 15 domain entities across the 5 features.
- Concrete interface definitions for all 5 abstract repositories.
- Complete input parameters, business validation rules, and error handling for all 13 UseCases.
- A comprehensive unit test matrix detailing happy paths, validation errors, failure paths, and invariant checks.

The specification is 100% ready for the orchestrator to proceed with Milestone decomposition and implementation delegation.

---

## 5. Verification Method

To independently verify this specification report:
1. Inspect the full specification document:
   ```bash
   cat /home/charles/Documents/Work/Me/MedMate/.agents/teamwork/spec_miner_survey_1/spec_domain.md
   ```
2. Verify cross-reference compliance with requirements:
   - Check `ORIGINAL_REQUEST.md` R1 to R5 vs `spec_domain.md` §3 to §7.
   - Verify `Medication` entity definition has zero price attributes.
   - Verify `Reservation` entity definition enforces 6-digit OTP and 2h TTL.
   - Verify `EscalateDispatchWaveUseCase` enforces waves of 2 partner pharmacies.
   - Verify `PharmacyDailyAnalytics` contains zero PII.
3. Validate that existing codebase tests still pass without interference:
   ```bash
   /home/charles/development/flutter/bin/flutter test
   ```
