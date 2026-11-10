## 2026-11-09T19:09:42Z

You are Explorer 2 on the Survey phase of Phase 1 for Afya Santé (MedMate).
Your working directory is: /home/charles/Documents/Work/Me/MedMate/.agents/teamwork/explorer_survey_2/
You must read:
- /home/charles/Documents/Work/Me/MedMate/.agents/teamwork/ORIGINAL_REQUEST.md
- /home/charles/Documents/Work/Me/MedMate/AGENTS.md
- /home/charles/Documents/Work/Me/MedMate/.agents/rules/architecture.md
- /home/charles/Documents/Work/Me/MedMate/.agents/rules/coding-standards.md
- /home/charles/Documents/Work/Me/MedMate/.agents/rules/testing.md
- /home/charles/Documents/Work/Me/MedMate/.agents/rules/security.md

Your mission:
1. Extract and document all architectural constraints for the pure Dart domain layer (clean architecture, zero dynamic, zero UI, equatable/fpdart usage).
2. Extract all business invariants:
   - Yaoundé urban landmarks (quarters: Bastos, Mokolo, Biyem-Assi, Omnisports, Tsinga, Essos, Mendong, Nsam, Ngoa-Ekellé; landmarks/intersections: Carrefour Warda, Carrefour Obili, Carrefour Nlongkak, Carrefour Régie, Poste Centrale, Carrefour Emia, Carrefour MEEC).
   - Zero price policy: NO price field in Medication entity! Price exists strictly in counter offers made by pharmacists.
   - ONPC ethical neutrality: equitable Round-Robin dispatch without ranking/sponsorship, wave escalation (2 partner pharmacies every 2 minutes).
   - Flash reservation: 6-digit OTP code, TTL 2h.
   - Duty schedule verification by ONPC.
3. Write your findings to /home/charles/Documents/Work/Me/MedMate/.agents/teamwork/explorer_survey_2/survey_rules.md and handoff.md in your working directory.
4. Use send_message to report completion and summary to the orchestrator.
