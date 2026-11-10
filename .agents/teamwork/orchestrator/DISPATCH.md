# Dispatch Log

## 2026-11-09T19:07:22Z

Sender: 942ec685-4b19-4e48-9954-62be82ee2786
Priority: MESSAGE_PRIORITY_HIGH

Content:
Mode d'exécution : Orchestration par Sous-Agents (`invoke_subagent`) : Découpe le travail et délègue la réalisation à des sous-agents spécialisés (type `self`) travaillant de manière coordonnée, puis consolide et vérifie l'ensemble.
Implémenter l'Étape 1 (Couche Domain pure Dart & Tests Unitaires) en production pour Afya Santé (`package:medmate`), en se basant strictement sur `AGENTS.md` et les règles de `.agents/rules/` (`architecture.md`, `coding-standards.md`, `testing.md`, `security.md`).

Working directory: /home/charles/Documents/Work/Me/MedMate
Integrity mode: development

## Requirements

### R1. Domaine Auth & Recherche de Pharmacies (`auth` & `pharmacy_search`)
Implémenter la couche domain pure Dart pour l'authentification et la recherche d'officines et de médicaments :
- `lib/features/auth/domain/` :
  - Entités : `PatientSession` (anonyme/éphémère + téléphone au moment de la réservation), `PharmacistProfile` (userId, pharmacyId, licenceOnpc, role), `UserSession`.
  - Repository abstrait : `AuthRepository` (`Either<Failure, T>`).
  - UseCases : `GetCurrentSessionUseCase`, `SignInPharmacistUseCase`, `SignOutUseCase`.
- `lib/features/pharmacy_search/domain/` :
  - Entités : `Medication` (id, codeNational, nomCommercial, dci, forme, dosage, necessiteOrdonnance — INTERDICTION ABSOLUE de champ prix dans Medication), `Pharmacy` (id, nom, licenceOnpc, quartier, carrefourRepere, latitude, longitude, telephoneGarde, estOuverte, estDeGarde, estPartenaire, distanceMetres).
  - Repository abstrait : `PharmacySearchRepository`.
  - UseCases : `SearchMedicationsUseCase` (tolérant aux fautes), `SearchNearbyPharmaciesUseCase` (filtrage par repère urbain de Yaoundé ou coordonnées GPS).

### R2. Domaine Réservation & Pharmacie de Garde (`reservation` & `duty_pharmacy`)
Implémenter la couche domain pure Dart pour la réservation flash et les pharmacies de garde :
- `lib/features/reservation/domain/` :
  - Entités : `BasketItem` (medication, quantite, precision), `ItemAvailabilityStatus` (`available`, `unavailable`, `conditional`), `OfferItemResponse` (medicationId, status, prixUnitaireCommunicParPharmacien, conditionDelivrance, commentaire), `PharmacyOffer` (id, demandeId, pharmacyId, pharmacyNom, quartier, distanceMetres, items, montantTotalPropose, livraisonDisponible, fraisLivraison, delaiLivraisonMinutes, createdAt), `FlashRequest` (id, clientRequestId, items, quartierOuCarrefour, statut, vagueActuelle, pharmaciesNotifieesIds, offresRecues, createdAt, expiresAt), `Reservation` (id, clientReservationId, demandeId, offreId, pharmacyId, codeRetraitOtp6Chiffres, statut, createdAt, expiresAt — TTL 2h).
  - Repository abstrait : `ReservationRepository`.
  - UseCases : `SubmitFlashRequestUseCase`, `EscalateDispatchWaveUseCase` (vagues de 2 pharmacies partenaires toutes les 2 minutes en Round-Robin équitable ONPC), `SelectPharmacyOfferUseCase`, `ConfirmReservationOtpUseCase`.
- `lib/features/duty_pharmacy/domain/` :
  - Entités : `DutySchedule` (pharmacy, dateGarde, heureDebut, heureFin, verifieParOnpc).
  - Repository abstrait : `DutyPharmacyRepository`.
  - UseCases : `GetDutyPharmaciesByQuartierUseCase`.

### R3. Domaine Portail Pharmacien (`pharmacist_portal`)
Implémenter la couche domain pure Dart pour le portail officinal :
- `lib/features/pharmacist_portal/domain/` :
  - Entités : `IncomingDemand`, `CounterQuoteSubmission` (réponse en 3 statuts + prix saisi exclusivement par le pharmacien au comptoir), `PharmacyDailyAnalytics` (statistiques anonymisées de redirections patients, conformes Loi n° 2024/017 ANTIC).
  - Repository abstrait : `PharmacistPortalRepository`.
  - UseCases : `SubmitCounterQuoteUseCase`, `ValidatePickupOtpUseCase`, `GetPharmacyAnalyticsUseCase`.

### R4. Suite de Tests Unitaires (`test/features/`)
Écrire une suite de tests unitaires complète (`mocktail` + `fpdart`) couvrant :
- 100 % des UseCases implémentés (flux nominaux et retours `Failure`).
- Les validations métier : panier non vide, OTP à 6 chiffres, escalade par vagues de 2 officines en Round-Robin équitable ONPC, politique zéro prix catalogue (prix présent uniquement dans les offres comptoir).
- L'égalité et l'immuabilité de toutes les entités du domaine.

### R5. Contraintes Techniques et d'Architecture
- Zéro dépendance UI ou externe dans `domain/` : uniquement du Dart pur, `equatable` et `fpdart` (`Either<Failure, T>`).
- Zéro `dynamic` : typage strict partout.
- Ne pas modifier `lib/main.dart` (aucune modification d'interface graphique dans cette étape).
- Respect strict de `AGENTS.md` et des règles `.agents/rules/` (`architecture.md`, `coding-standards.md`, `testing.md`, `security.md`).

## Acceptance Criteria

### Code Quality & Static Analysis
- [ ] `/home/charles/development/flutter/bin/dart analyze --fatal-infos --fatal-warnings` s'exécute avec 0 avertissement et 0 erreur.
- [ ] Zéro utilisation de `dynamic` ou d'import UI/Flutter dans les fichiers de la couche `domain/`.
- [ ] Aucun import de `dart:io` non protégé.
- [ ] `lib/main.dart` reste intact et non modifié.

### Unit Tests
- [ ] `/home/charles/development/flutter/bin/flutter test` s'exécute avec 100% de succès.
- [ ] 100 % des UseCases disposent de tests unitaires validant les flux nominaux et les échecs (`Failure`).
- [ ] Les tests vérifient l'absence absolue de champ prix dans l'entité `Medication` et sa présence uniquement dans les offres comptoir.
- [ ] Les tests vérifient la validation de l'OTP (6 chiffres requis) et la durée de validité TTL de 2h pour `Reservation`.
- [ ] Les tests vérifient l'escalade par vagues de 2 officines en Round-Robin.

### Build Verification
- [ ] `/home/charles/development/flutter/bin/flutter build web --release` réussit sans erreur.


## 2026-11-09T22:07:01Z

Sender: 19de9777-b45b-427e-9a7b-5315f346fbda
Priority: MESSAGE_PRIORITY_HIGH

Content:
Exécuter avec orchestration par sous-agents (invoke_subagent) : Sous-Agent 1 (auth, pharmacy_search & duty_pharmacy — data layer + tests), Sous-Agent 2 (reservation & pharmacist_portal — data layer + tests), Sous-Agent 3 (auth/presentation/, coquille AfyaAppShell responsive & lib/main.dart). Implémenter l'Étape 2 d'Afya Santé (package:medmate) en se basant sur AGENTS.md, .agents/rules/ et les contrats domain de l'Étape 1.

Integrity mode: development

## Requirements

### R1. Couche Data Synchronisée pour auth, pharmacy_search et duty_pharmacy
Implémenter la couche data pour les modules auth, pharmacy_search et duty_pharmacy :
- `lib/features/auth/data/` : modèles, `AuthLocalDataSource` (gestion de session patient et comptes pharmaciens de référence), repositories.
- `lib/features/pharmacy_search/data/` : modèles garantissant zéro champ prix, `YaoundéPharmacyDataSource` (catalogue homologué, recherche tolérante, officines partenaires/non-partenaires en coordonnées WGS84), repositories.
- `lib/features/duty_pharmacy/data/` : modèles, `DutyPharmacyDataSource`, repositories.
- Tests unitaires et de widgets complets pour chaque data source et repository.

### R2. Couche Data Synchronisée pour reservation et pharmacist_portal
Implémenter la couche data pour reservation et pharmacist_portal partageant un état cohérent en mémoire (zéro mock dans l'UI) :
- `lib/features/reservation/data/` : modèles, `FlashOrderDataSource` (gestion en mémoire des vagues et des offres), repositories.
- `lib/features/pharmacist_portal/data/` : modèles, `PharmacistPortalDataSource` (soumission de devis à 3 statuts + prix comptoir, validation OTP, incrémentation anonymisée de `PharmacyDailyAnalytics`), repositories.
- Tests unitaires et d'intégration couvrant le cycle de vie de bout en bout (demande patient suivie de la réponse pharmacien).

### R3. Couche Présentation Auth et Coquille de Navigation Responsive (AfyaAppShell)
Implémenter la présentation auth et la coquille de navigation responsive :
- `lib/features/auth/presentation/` : `AuthCubit` et vue `pharmacist_sign_in_view.dart` (< 300 lignes).
- `lib/core/navigation/afya_app_shell.dart` (< 350 lignes) : navigation responsive avec `NavigationBar` sur Mobile (< 600px) et `NavigationRail` sur Desktop (>= 600px).
- Mise à jour de `lib/main.dart` et tests multi-viewports.

### R4. Protocole d'Audit Post-Exécution et Auto-Correction
Exécuter et vérifier les contrôles de qualité avec remédiation immédiate en cas d'échec :
- Audit d'invariance Zéro Prix : scanner l'intégralité des fichiers dans `domain/` et `data/` pour s'assurer qu'aucun modèle/entité ne contient de champ prix ou tarif hors des devis explicites.
- Vérification de cohérence d'état en mémoire : test d'intégration simulant une demande patient suivie d'une réponse pharmacien validant la mise à jour sans désynchronisation de l'instance `FlashRequest`.
- Validation de stabilité Web et Zero-dart:io : analyse statique stricte et compilation Web sans dépendance `dart:io` non protégée.

## Acceptance Criteria

### Architecture & Intégrité Métier
- [ ] Aucun modèle ou entité dans `domain/` et `data/` ne contient de champ prix ou tarif en dehors des devis explicites au comptoir.
- [ ] Les actions Patient et Pharmacien partagent un état en mémoire cohérent et synchronisé sans désynchronisation.
- [ ] Aucun fichier Widget ne dépasse 400 lignes (avec `pharmacist_sign_in_view.dart` < 300 lignes et `afya_app_shell.dart` < 350 lignes).
- [ ] Zéro utilisation de type `dynamic` non casté dans l'ensemble du code généré ou modifié.
- [ ] Zéro import `dart:io` non protégé dans les modules exécutables sur le Web.

### Quality Gates & Tests
- [ ] `/home/charles/development/flutter/bin/dart analyze --fatal-infos --fatal-warnings` passe avec 0 avertissement et 0 erreur.
- [ ] `/home/charles/development/flutter/bin/flutter test` passe à 100 % sur l'ensemble des tests unitaires, widgets et d'intégration.
- [ ] `/home/charles/development/flutter/bin/flutter build web --release` compile avec succès.
