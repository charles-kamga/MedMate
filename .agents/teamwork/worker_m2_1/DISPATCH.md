# Dispatch: worker_m2_1 (Data Layer for reservation & pharmacist_portal — Shared In-Memory State)

## Role & Mission
You are `worker_m2_1`, a specialized Teamwork Worker.
Your working directory is `/home/charles/Documents/Work/Me/MedMate/.agents/teamwork/worker_m2_1/`.
Your mission is to implement the synchronized in-memory data layer and tests for `reservation` and `pharmacist_portal` of Afya Santé (`package:medmate`), ensuring a single, shared, coherent state between Patient and Pharmacist without any dummy mock in the UI.

## Authoritative Documentation & Rules
- `/home/charles/Documents/Work/Me/MedMate/.agents/teamwork/ORIGINAL_REQUEST.md` (MUST READ FIRST)
- `/home/charles/Documents/Work/Me/MedMate/.agents/teamwork/PROJECT.md`
- `/home/charles/Documents/Work/Me/MedMate/AGENTS.md`
- `/home/charles/Documents/Work/Me/MedMate/.agents/rules/architecture.md`
- `/home/charles/Documents/Work/Me/MedMate/.agents/rules/coding-standards.md`
- `/home/charles/Documents/Work/Me/MedMate/.agents/rules/web-platform.md`

## Files Owned Exclusively by You
- `lib/features/reservation/data/**`
- `lib/features/pharmacist_portal/data/**`
- `test/features/reservation/data/**`
- `test/features/pharmacist_portal/data/**`
- `test/features/reservation_portal_lifecycle_test.dart`

Do NOT modify files owned by other modules.

## Architecture: Synchronized In-Memory Coordinator
Patient requests and Pharmacist portal responses must share a single source of truth in memory:
- Create `InMemoryFlashOrderStore` (e.g. `lib/features/reservation/data/datasources/in_memory_flash_order_store.dart` or a shared memory coordinator):
  - Singleton or injectable instance with thread-safe collections:
    - Active `FlashRequestModel`s
    - Dispatched `IncomingDemandModel`s per pharmacyId
    - Confirmed `ReservationModel`s
    - `PharmacyDailyAnalyticsModel`s per pharmacyId (initialized to 0)
  - Full lifecycle state transitions:
    1. **Patient Flash Request**: When `submitFlashRequest(request)` is called, the request is stored. An initial wave of 2 partner pharmacies in the requested quarter/vicinity is notified (creating `IncomingDemandModel` for those pharmacies with `isResponded: false`).
    2. **Wave Escalation**: `escalateDispatchWave(requestId)` notifies the next 2 partner pharmacies in round-robin order and increments `vagueActuelle`.
    3. **Incoming Demands for Pharmacist**: `getIncomingDemands(pharmacyId)` returns all incoming demands for that pharmacy.
    4. **Pharmacist Counter Quote**: `submitCounterQuote(submission)` receives item responses (each with status: `available`, `unavailable`, `conditional` + counter price `prixUnitaireCommunicParPharmacien`) and total amount. The submission converts to a `PharmacyOfferModel` and is appended to `FlashRequest.offresRecues` in the store. The `IncomingDemand` is marked `isResponded: true`. `PharmacyDailyAnalytics.totalQuotesSubmitted` is incremented.
    5. **Patient Offer Selection & Reservation**: When `selectPharmacyOffer(requestId, offerId, patientPhone)` is called, the request status is updated to `accepted`. A `ReservationModel` is created with a generated 6-digit numeric OTP (`^\d{6}$`), TTL of 2 hours (`DateTime.now().add(const Duration(hours: 2))`), and status `pending`.
    6. **OTP Confirmation / Pickup Validation**: When the pharmacist validates the pickup OTP via `validatePickupOtp(pharmacyId, reservationId, otpCode)` (or patient confirms with `confirmReservationOtp`), the OTP must match the 6-digit code. If matched, the reservation status becomes `confirmed`, and `PharmacyDailyAnalytics.totalReservationsConfirmed` is incremented. If invalid, returns `ValidationFailure` or `AuthFailure`.

## Requirements

### 1. `lib/features/reservation/data/`
- **Models**:
  - `BasketItemModel`
  - `ItemAvailabilityStatusModel`
  - `OfferItemResponseModel`
  - `PharmacyOfferModel`
  - `FlashRequestModel`
  - `ReservationModel`
  - All models must support `toJson`/`fromJson` and `toDomain()`/`fromDomain()`.
- **Data Source**:
  - `InMemoryFlashOrderStore`: Singleton or shared memory engine holding state.
  - `FlashOrderDataSource` (abstract and `FlashOrderDataSourceImpl`): connects to `InMemoryFlashOrderStore`.
- **Repository Implementation**:
  - `ReservationRepositoryImpl` implementing `ReservationRepository`:
    - `submitFlashRequest`, `escalateDispatchWave`, `selectPharmacyOffer`, `confirmReservationOtp`.

### 2. `lib/features/pharmacist_portal/data/`
- **Models**:
  - `IncomingDemandModel`
  - `CounterQuoteSubmissionModel`
  - `PharmacyDailyAnalyticsModel`
  - `toDomain()` / `fromDomain()` mappings.
- **Data Source**:
  - `PharmacistPortalDataSource` (abstract and `PharmacistPortalDataSourceImpl`): connects to `InMemoryFlashOrderStore`.
    - `getIncomingDemands(String pharmacyId)`
    - `submitCounterQuote(CounterQuoteSubmissionModel submission)`
    - `validatePickupOtp(String pharmacyId, String reservationId, String otpCode)`
    - `getPharmacyAnalytics(String pharmacyId, DateTime date)`
- **Repository Implementation**:
  - `PharmacistPortalRepositoryImpl` implementing `PharmacistPortalRepository`.

### 3. Tests
- Unit tests for all models, datasources, and repositories:
  - `test/features/reservation/data/**`
  - `test/features/pharmacist_portal/data/**`
- **End-to-End In-Memory Lifecycle Integration Test** (`test/features/reservation_portal_lifecycle_test.dart`):
  - Step 1: Patient submits flash request.
  - Step 2: Pharmacist A observes incoming demand.
  - Step 3: Pharmacist A submits counter quote with 3 statuses + counter price.
  - Step 4: Patient views received offer in flash request and selects it.
  - Step 5: Reservation created with 6-digit OTP and 2h TTL.
  - Step 6: Pharmacist validates pickup OTP -> status confirmed, daily analytics updated.
  - Step 7: Negative cases (wrong OTP rejected, expired TTL rejected).

## Mandatory Integrity Warning
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

## Quality Gates for Verification
Run:
`/home/charles/development/flutter/bin/dart analyze --fatal-infos --fatal-warnings`
`/home/charles/development/flutter/bin/flutter test test/features/reservation/data test/features/pharmacist_portal/data test/features/reservation_portal_lifecycle_test.dart`

Write your report in `/home/charles/Documents/Work/Me/MedMate/.agents/teamwork/worker_m2_1/handoff.md`.

## 2026-11-09T22:25:40Z
You are worker_m2_1. Your working directory is /home/charles/Documents/Work/Me/MedMate/.agents/teamwork/worker_m2_1/.
You are working on Milestone 2 (R2) of Afya Santé (package:medmate): Synchronized In-Memory Data Layer & Lifecycle Tests for reservation and pharmacist_portal.

