## 2026-11-09T19:09:55Z
From: 6756ae02-4558-4e4c-95a6-b9d1af3cbd26 (parent)
Content:
You are Spec Miner 1 on the Survey phase of Phase 1 for Afya Santé (MedMate).
Your working directory is: /home/charles/Documents/Work/Me/MedMate/.agents/teamwork/spec_miner_survey_1/
You must read:
- /home/charles/Documents/Work/Me/MedMate/.agents/teamwork/ORIGINAL_REQUEST.md
- /home/charles/Documents/Work/Me/MedMate/AGENTS.md

Your mission:
1. Systematically extract the complete and exact domain specification for all 5 features:
   Feature 1: auth
   - Entities: PatientSession, PharmacistProfile, UserSession
   - Abstract repository: AuthRepository (Either<Failure, T>)
   - UseCases: GetCurrentSessionUseCase, SignInPharmacistUseCase, SignOutUseCase
   Feature 2: pharmacy_search
   - Entities: Medication (id, codeNational, nomCommercial, dci, forme, dosage, necessiteOrdonnance — ZERO PRICE FIELD), Pharmacy (id, nom, licenceOnpc, quartier, carrefourRepere, latitude, longitude, telephoneGarde, estOuverte, estDeGarde, estPartenaire, distanceMetres)
   - Abstract repository: PharmacySearchRepository
   - UseCases: SearchMedicationsUseCase (fault tolerant query), SearchNearbyPharmaciesUseCase (by Yaoundé landmark or GPS)
   Feature 3: reservation
   - Entities: BasketItem, ItemAvailabilityStatus (available, unavailable, conditional), OfferItemResponse, PharmacyOffer, FlashRequest, Reservation (6-digit OTP, TTL 2h)
   - Abstract repository: ReservationRepository
   - UseCases: SubmitFlashRequestUseCase, EscalateDispatchWaveUseCase (waves of 2 partner pharmacies in Round-Robin), SelectPharmacyOfferUseCase, ConfirmReservationOtpUseCase
   Feature 4: duty_pharmacy
   - Entities: DutySchedule
   - Abstract repository: DutyPharmacyRepository
   - UseCases: GetDutyPharmaciesByQuartierUseCase
   Feature 5: pharmacist_portal
   - Entities: IncomingDemand, CounterQuoteSubmission, PharmacyDailyAnalytics
   - Abstract repository: PharmacistPortalRepository
   - UseCases: SubmitCounterQuoteUseCase, ValidatePickupOtpUseCase, GetPharmacyAnalyticsUseCase
2. Detail all entity field types, nullability, validation rules, repository method signatures, and use case input/output contracts.
3. Detail required unit test cases (happy path, validation errors, failure paths, entity equality and immutability).
4. Write your full report to /home/charles/Documents/Work/Me/MedMate/.agents/teamwork/spec_miner_survey_1/spec_domain.md and handoff.md in your working directory.
5. Use send_message to report completion and summary to the orchestrator.
