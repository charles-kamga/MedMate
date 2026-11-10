## 2026-11-09T22:11:37Z
You are spec_miner_e2_survey_1, a teamwork_spec_miner.
Your working directory is: /home/charles/Documents/Work/Me/MedMate/.agents/teamwork/spec_miner_e2_survey_1/
The original request file is at: /home/charles/Documents/Work/Me/MedMate/.agents/teamwork/ORIGINAL_REQUEST.md

Mission:
Mine specific presentation, web platform, and quality gate specifications for Requirements R3 & R4.

Tasks:
1. Read /home/charles/Documents/Work/Me/MedMate/.agents/teamwork/ORIGINAL_REQUEST.md (specifically Étape 2 prompt, R3, R4, Acceptance Criteria).
2. Read project rules and guidelines in:
   - AGENTS.md
   - .agents/rules/architecture.md
   - .agents/rules/coding-standards.md
   - .agents/rules/web-platform.md
   - .agents/rules/testing.md
   - .agents/rules/security.md
3. Extract precise specifications:
   - R3 Auth Presentation:
     - AuthCubit / AuthState (states, events/methods, error handling).
     - pharmacist_sign_in_view.dart: STRICT LINE LIMIT < 300 lines. Medical Teal/Emerald palette (#0D9488, #10B981), Amber for warnings, NO bright red. Plus Jakarta Sans font. Form validation (email, password), accessible touch targets >= 48x48.
   - R3 Responsive Navigation Shell:
     - lib/core/navigation/afya_app_shell.dart: STRICT LINE LIMIT < 350 lines.
     - Responsive Breakpoints:
       * Compact (Mobile < 600px): NavigationBar at the bottom.
       * Medium/Expanded (Desktop >= 600px): NavigationRail on the left.
       * Tabs: e.g. Recherche Pharmacies/Médicaments, Gardes, Réservations Flash, Portail Pharmacien.
   - lib/main.dart:
     - Initialization of services / shared in-memory data sources / repositories / Cubits.
     - App theme configured with AppConfig, Plus Jakarta Sans, Emerald/Teal colors.
     - Responsive shell integration.
   - Widget & Multi-viewport tests:
     - Test viewports: Mobile (390x844 or similar < 600px) verifying NavigationBar is rendered and NavigationRail is absent.
     - Desktop (1280x800 or similar >= 600px) verifying NavigationRail is rendered and NavigationBar is absent.
     - Sign-in form interaction tests.
   - R4 Post-Execution Audit & Quality Gates:
     - Invariance Zero-Price: verify no price fields in domain entities/models outside counter quotes.
     - In-memory state coherence test.
     - Zero-dynamic and Zero-dart:io compliance.
     - dart analyze --fatal-infos --fatal-warnings, flutter test (100%), flutter build web --release.
4. Document all mined requirements, constraints, line limits, and testing criteria in /home/charles/Documents/Work/Me/MedMate/.agents/teamwork/spec_miner_e2_survey_1/handoff.md.
5. Send a concise summary message back to orchestrator.
