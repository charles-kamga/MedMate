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
