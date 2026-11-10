# BRIEFING — 2026-11-09T19:15:00Z

## Mission
Extract and document the complete, exact, and authoritative domain specification for all 5 features of Afya Santé (`auth`, `pharmacy_search`, `reservation`, `duty_pharmacy`, `pharmacist_portal`), defining entity fields, nullability, validation rules, repository interfaces, use case contracts, and unit test requirements.

## 🔒 My Identity
- Archetype: teamwork_spec_miner
- Roles: spec_miner
- Working directory: /home/charles/Documents/Work/Me/MedMate/.agents/teamwork/spec_miner_survey_1
- Original parent: 6756ae02-4558-4e4c-95a6-b9d1af3cbd26
- Milestone: Survey Phase 1

## 🔒 Key Constraints
- Pure Dart domain layer: zero UI/Flutter dependencies, only `equatable` and `fpdart` (`Either<Failure, T>`).
- Zero `dynamic`: strict typing across all domain models, repositories, and usecases.
- Zéro Prix Affiché dans Medication: absolutely no price field in `Medication` entity; prices exist exclusively in pharmacist counter quotes/offers.
- Cartographie souveraine OpenStreetMap: yaounde landmarks, carrefours, quartiers (no Google Maps/Mapbox).
- Neutralité déontologique ONPC: round-robin dispatch in waves of 2 pharmacies, no sponsored rankings.
- Security & Cameroun Law n° 2024/017 compliance: OTP 6 digits, TTL 2h on reservations, patient session minimization.
- Read-only analysis: do NOT implement source code or tests, only document complete specification.
- Subagent results must be sent via send_message to parent (6756ae02-4558-4e4c-95a6-b9d1af3cbd26).

## Current Parent
- Conversation ID: 6756ae02-4558-4e4c-95a6-b9d1af3cbd26
- Updated: 2026-11-09T19:09:55Z

## Task Summary
- **What to build**: Comprehensive domain specification document `spec_domain.md` for all 5 features, plus 5-component `handoff.md`.
- **Success criteria**: Exhaustive specification of entity types, immutability, validation, repository contracts, use case inputs/outputs, failure mappings, and comprehensive unit test matrix.
- **Interface contracts**: `ORIGINAL_REQUEST.md`, `AGENTS.md`, `.agents/rules/*.md`.
- **Code layout**: `lib/features/<feature>/domain/{entities,repositories,usecases}/` and `test/features/<feature>/domain/`.

## Key Decisions Made
- All 15 domain entities defined with explicit field types, nullability, immutability (`Equatable`), and validation rules.
- Strictly enforced Invariant 1 (zero price in `Medication`, prices exclusively at counter in `OfferItemResponse` and `PharmacyOffer`).
- Strictly enforced Invariant 2 (Yaoundé landmarks & OSM coordinates in `Pharmacy`).
- Strictly enforced Invariant 3 (Fair Round-Robin dispatch in waves of 2 partner pharmacies in `EscalateDispatchWaveUseCase`).
- Strictly enforced Invariant 4 (6-digit OTP regex `^\d{6}$`, 2-hour TTL in `Reservation`, Zero-PII daily analytics in `PharmacyDailyAnalytics`).
- All 5 repositories and 13 UseCases fully specified with parameter objects and `Either<Failure, T>` return signatures.
- Detailed unit test matrix defined covering 100% of UseCases, validation errors, failure paths, and entity immutability.

## Artifact Index
- `/home/charles/Documents/Work/Me/MedMate/.agents/teamwork/ORIGINAL_REQUEST.md` — Authoritative requirements
- `/home/charles/Documents/Work/Me/MedMate/AGENTS.md` — Project guide & inviolable invariants
- `/home/charles/Documents/Work/Me/MedMate/.agents/teamwork/spec_miner_survey_1/DISPATCH.md` — Dispatch log
- `/home/charles/Documents/Work/Me/MedMate/.agents/teamwork/spec_miner_survey_1/progress.md` — Heartbeat & status
- `/home/charles/Documents/Work/Me/MedMate/.agents/teamwork/spec_miner_survey_1/spec_domain.md` — Authoritative domain specification
- `/home/charles/Documents/Work/Me/MedMate/.agents/teamwork/spec_miner_survey_1/handoff.md` — Handoff report
