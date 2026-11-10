## 2026-11-09T20:03:20Z
[Message] timestamp=2026-11-09T20:03:20Z sender=6756ae02-4558-4e4c-95a6-b9d1af3cbd26 priority=MESSAGE_PRIORITY_HIGH content=DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

You are Worker M2 (Replacement Generation 2) implementing Milestone 2: Pure Dart Domain Layer & Unit Tests for `reservation`, `duty_pharmacy`, and `pharmacist_portal` features in Afya Santé (`package:medmate`).
Working directory: /home/charles/Documents/Work/Me/MedMate/.agents/teamwork/worker_m2_gen2/

Authoritative references to read:
- /home/charles/Documents/Work/Me/MedMate/.agents/teamwork/ORIGINAL_REQUEST.md
- /home/charles/Documents/Work/Me/MedMate/.agents/teamwork/PROJECT.md
- /home/charles/Documents/Work/Me/MedMate/.agents/teamwork/spec_miner_survey_1/spec_domain.md
- /home/charles/Documents/Work/Me/MedMate/.agents/teamwork/worker_m1/handoff.md
- Existing domain entities: lib/features/pharmacy_search/domain/entities/medication.dart, lib/features/pharmacy_search/domain/entities/pharmacy.dart
- Core failures: lib/core/errors/failures.dart
- Core usecase sentinel: lib/core/usecases/no_params.dart

Your Scope & Files Owned Exclusively:
1. `lib/features/reservation/domain/`:
   - `entities/basket_item.dart`: `BasketItem` (medication, quantite, precision, copyWith, Equatable)
   - `entities/item_availability_status.dart`: enum `ItemAvailabilityStatus` (`available`, `unavailable`, `conditional`)
   - `entities/offer_item_response.dart`: `OfferItemResponse` (medicationId, status, prixUnitaireCommunicParPharmacien, conditionDelivrance, commentaire, copyWith, Equatable)
   - `entities/pharmacy_offer.dart`: `PharmacyOffer` (id, demandeId, pharmacyId, pharmacyNom, quartier, distanceMetres, items, montantTotalPropose, livraisonDisponible, fraisLivraison, delaiLivraisonMinutes, createdAt, copyWith, Equatable)
   - `entities/flash_request.dart`: `FlashRequest` (id, clientRequestId, items, quartierOuCarrefour, statut, vagueActuelle, pharmaciesNotifieesIds, offresRecues, createdAt, expiresAt, copyWith, Equatable)
   - `entities/reservation.dart`: `Reservation` (id, clientReservationId, demandeId, offreId, pharmacyId, codeRetraitOtp6Chiffres, statut, createdAt, expiresAt — TTL 2h, copyWith, Equatable)
   - `repositories/reservation_repository.dart`: abstract contract `ReservationRepository` returning `Future<Either<Failure, T>>`
   - `usecases/submit_flash_request_usecase.dart`: `SubmitFlashRequestUseCase` (validates non-empty items/basket, returns Left(ValidationFailure) if empty)
   - `usecases/escalate_dispatch_wave_usecase.dart`: `EscalateDispatchWaveUseCase` (implements fair ONPC Round-Robin wave escalation: increments wave and notifies 2 partner pharmacies in batches)
   - `usecases/select_pharmacy_offer_usecase.dart`: `SelectPharmacyOfferUseCase` (validates phone number and offerId)
   - `usecases/confirm_reservation_otp_usecase.dart`: `ConfirmReservationOtpUseCase` (validates 6-digit numeric OTP `^\d{6}$`, checks TTL 2h expiry)

2. `lib/features/duty_pharmacy/domain/`:
   - `entities/duty_schedule.dart`: `DutySchedule` (pharmacy, dateGarde, heureDebut, heureFin, verifieParOnpc, copyWith, Equatable)
   - `repositories/duty_pharmacy_repository.dart`: abstract contract `DutyPharmacyRepository`
   - `usecases/get_duty_pharmacies_by_quartier_usecase.dart`: `GetDutyPharmaciesByQuartierUseCase` (validates non-empty quartier)

3. `lib/features/pharmacist_portal/domain/`:
   - `entities/incoming_demand.dart`: `IncomingDemand` (id, flashRequest, distanceMetres, receivedAt, isResponded, copyWith, Equatable)
   - `entities/counter_quote_submission.dart`: `CounterQuoteSubmission` (demandId, pharmacyId, itemResponses, montantTotal, livraisonPossible, fraisLivraison, delaiMinutes, notes, copyWith, Equatable)
   - `entities/pharmacy_daily_analytics.dart`: `PharmacyDailyAnalytics` (pharmacyId, date, totalDemandsReceived, totalQuotesSubmitted, totalReservationsConfirmed, conversionRate — ZERO PII, Loi n° 2024/017, copyWith, Equatable)
   - `repositories/pharmacist_portal_repository.dart`: abstract contract `PharmacistPortalRepository`
   - `usecases/submit_counter_quote_usecase.dart`: `SubmitCounterQuoteUseCase`
   - `usecases/validate_pickup_otp_usecase.dart`: `ValidatePickupOtpUseCase` (validates 6-digit numeric OTP)
   - `usecases/get_pharmacy_analytics_usecase.dart`: `GetPharmacyAnalyticsUseCase`

4. Unit Tests under `test/features/`:
   - `test/features/reservation/domain/`:
     - Test all entities equality and copyWith
     - Test all 4 usecases (nominal success and failure/validation flows: empty basket rejection, wave escalation batches of 2 in Round-Robin, OTP 6-digit validation, TTL 2h check)
   - `test/features/duty_pharmacy/domain/`:
     - Test DutySchedule equality and verifieParOnpc flag
     - Test GetDutyPharmaciesByQuartierUseCase (nominal and empty quartier failure)
   - `test/features/pharmacist_portal/domain/`:
     - Test entities equality, zero PII in analytics
     - Test all 3 usecases (nominal and failure flows)

Quality Requirements:
- Pure Dart in domain: NO `package:flutter/...` imports, NO `dart:io`.
- Strict zero `dynamic`.
- DO NOT MODIFY `lib/main.dart`.
- Run `/home/charles/development/flutter/bin/dart analyze --fatal-infos --fatal-warnings` -> must be 0 errors, 0 warnings.
- Run `/home/charles/development/flutter/bin/flutter test` -> all tests must pass 100%. (Use BypassSandbox: true if executing flutter test).

When done, write `handoff.md` in your working directory and send a completion message to the orchestrator via `send_message`.
