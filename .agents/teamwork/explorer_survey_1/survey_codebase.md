# Rapport d'Exploration du Codebase — Afya Santé (MedMate)

**Date**: 2026-11-09  
**Agent**: Explorer 1 (`explorer_survey_1`)  
**Mission**: Recensement technique complet du projet Afya Santé pour la Phase 1 (Domain Layer & Tests Unitaires).

---

## 1. Analyse de `pubspec.yaml`

- **Nom du package** : `medmate` (conforme à `AGENTS.md` ; préserve tous les imports `package:medmate/...`).
- **Description** : `"Application de mise en relation patients-pharmacies à Yaoundé (Flutter + Supabase/PostGIS)"`
- **Version** : `1.0.0+1`
- **Contraintes SDK** :
  - `sdk: '>=3.2.0 <4.0.0'`
  - `flutter: '>=3.16.0'`
- **Dépendances de Production Clés** :
  - `equatable: ^2.0.5` : Idéal pour l'égalité structurelle par valeur des entités et Failures du domaine sans code généré.
  - `fpdart: ^1.1.0` : Gestion fonctionnelle des erreurs via `Either<Failure, T>` conformément aux règles d'architecture.
  - `freezed_annotation: ^3.1.0` & `json_annotation: ^4.9.0` : Disponibles pour la sérialisation future (couche Data).
  - `flutter_bloc: ^8.1.6` : Gestionnaire d'état de la couche Présentation.
  - `supabase_flutter: ^2.8.3` : Client Backend Supabase (Data Layer).
  - `flutter_map: ^7.0.2` & `latlong2: ^0.9.1` : Cartographie souveraine OpenStreetMap.
  - `geolocator: ^13.0.2` : Capteur de localisation avec repli manuel sur repères urbains.
  - `flutter_secure_storage: ^9.2.2` : Stockage sécurisé mobile.
  - `uuid: ^4.5.1` : Génération d'identifiants idempotents (Outbox pattern).
  - `intl: ^0.20.2` : Formats et dates.
  - `google_fonts: ^9.0.0` : Typographie Plus Jakarta Sans.
- **Dépendances de Développement & Test** :
  - `flutter_test: sdk: flutter`
  - `mocktail: ^1.0.4` : Mocking type-safe sans génération de code (crucial pour tester les UseCases).
  - `bloc_test: ^9.1.7` : Tests BLoC (Présentation future).
  - `build_runner: ^2.4.13`, `freezed: ^3.1.0`, `json_serializable: ^6.9.0`.
  - `very_good_analysis: ^6.0.0` : Règle de linting stricte (`strict-casts: true`, `strict-inference: true`, `strict-raw-types: true`).

---

## 2. Analyse de `lib/core/`

### 2.1 Hiérarchie des Erreurs et Échecs (`lib/core/errors/failures.dart`)
Toutes les `Failure` sont basées sur `equatable` et une classe scellée racine :
```dart
sealed class Failure extends Equatable {
  const Failure(this.message, {this.code});
  final String message;
  final String? code;
  @override
  List<Object?> get props => [message, code];
}
```

Classes filles concrètes actuelles (`final class`) :
1. `NetworkFailure` (`code: 'NETWORK_ERROR'`, message par défaut : `'Connexion réseau instable ou indisponible.'`)
2. `ServerFailure` (`code: 'SERVER_ERROR'`, message par défaut : `'Erreur lors de la communication avec le serveur.'`)
3. `StorageFailure` (`code: 'STORAGE_ERROR'`, message par défaut : `"Impossible d'accéder au stockage local."`)
4. `CacheFailure` (`code: 'CACHE_ERROR'`, message par défaut : `"Impossible d'accéder au cache local."`)
5. `LocationFailure` (`code: 'LOCATION_ERROR'`, message par défaut : `'Géolocalisation indisponible. Veuillez sélectionner votre quartier ou carrefour à Yaoundé.'`)
6. `AuthFailure` (`code: 'AUTH_ERROR'`, message par défaut : `'Identifiants invalides ou session expirée.'`)
7. `NotFoundFailure` (`code: 'NOT_FOUND'`, message par défaut : `'La ressource demandée est introuvable.'`)
8. `InsufficientStockFailure` (`code: 'INSUFFICIENT_STOCK'`, message par défaut : `'Produit indisponible dans cette officine.'`)
9. `ReservationFailure` (`code: 'RESERVATION_ERROR'`, message par défaut : `"La réservation n'a pas pu être enregistrée."`)

> **Observation architecturale** : Si de nouveaux types d'échecs métier sont requis par les UseCases (ex. `ValidationFailure` pour les validations d'entrées comme l'OTP ou le panier vide), ils devront étendre `Failure` dans `failures.dart` ou dans le sous-domaine concerné selon la convention adoptée.

### 2.2 Exceptions Techniques (`lib/core/errors/exceptions.dart`)
- `ServerException([message, statusCode])`
- `CacheException([message])`
- `NetworkException([message])`
- `LocationException([message])`

### 2.3 Configuration Globale & Invariants (`lib/core/config/app_config.dart`)
- `AppConfig.appName`: `'Afya Santé'`
- `AppConfig.appTagline`: `'Disponibilité de médicaments & Pharmacies de garde à Yaoundé'`
- `AppConfig.pricePolicyNotice`: Mention obligatoire d'absence de prix catalogue et tarification au comptoir.
- `AppConfig.emergencyPhone`: `'1510'`
- `AppConfig.mapProviderName`: `'OpenStreetMap'`
- `AppConfig.osmFranceTileUrlTemplate`: `'https://{s}.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png'`
- `AppConfig.osmUserAgent`: `'cm.afyasante.app'`
- `AppConfig.yaoundeLatitude`: `3.8667`, `AppConfig.yaoundeLongitude`: `11.5200`
- `AppConfig.compactBreakpoint`: `600`, `AppConfig.expandedBreakpoint`: `1024`
- `AppConfig.networkTimeout`: `Duration(seconds: 10)`
- `AppConfig.reservationTtl`: `Duration(hours: 2)` (constante réutilisable directement par les entités/UseCases de réservation).

### 2.4 Repères Urbains de Yaoundé (`lib/core/constants/yaounde_landmarks.dart`)
- Entité `YaoundeLandmark` (id, nom, quartier, arrondissement, latitude, longitude, description) étendant `Equatable`.
- Liste de 12 repères majeurs : *Poste Centrale, Carrefour Warda, Carrefour Nlongkak, Marché Mokolo, Carrefour MEEC, Carrefour Obili, Carrefour EMIA, Carrefour Nsam, Carrefour Essos, Stade Omnisports, Carrefour Acacia, Carrefour Mendong*.

### 2.5 Détection Réseau (`lib/core/network/network_info.dart`)
- Contrat abstrait `NetworkInfo` avec `Future<bool> get isConnected;` et implémentation par défaut `NetworkInfoImpl`.

### 2.6 Thème & Widgets Partagés
- `lib/core/theme/app_colors.dart` : Charte sans rouge vif (Teal médical `#0D9488`, Ambre de garde `#F59E0B`, Bleu soignant `#0284C7`).
- `lib/core/theme/app_theme.dart` : Thème Material 3 avec typographie `Plus Jakarta Sans`.
- `lib/core/widgets/bento_card.dart` : Composant visuel Bento responsive.

---

## 3. État des Répertoires `lib/features/`

Tous les répertoires de fonctionnalités existent et sont arborescents (Clean Architecture) mais sont actuellement **entièrement vierges de tout fichier** :
1. `lib/features/auth/` :
   - `domain/{entities, repositories, usecases}` (0 fichiers)
   - `data/{datasources, models, repositories}` (0 fichiers)
   - `presentation/{controllers, views}` (0 fichiers)
2. `lib/features/pharmacy_search/` :
   - `domain/{entities, repositories, usecases}` (0 fichiers)
   - `data/{datasources, models, repositories}` (0 fichiers)
   - `presentation/{controllers, views}` (0 fichiers)
3. `lib/features/reservation/` :
   - `domain/{entities, repositories, usecases}` (0 fichiers)
   - `data/{datasources, models, repositories}` (0 fichiers)
   - `presentation/{controllers, views}` (0 fichiers)
4. `lib/features/duty_pharmacy/` :
   - `domain/{entities, repositories, usecases}` (0 fichiers)
   - `data/{datasources, models, repositories}` (0 fichiers)
   - `presentation/{controllers, views}` (0 fichiers)
5. `lib/features/pharmacist_portal/` :
   - `domain/{entities, repositories, usecases}` (0 fichiers)
   - `data/{datasources, models, repositories}` (0 fichiers)
   - `presentation/{controllers, views}` (0 fichiers)

Le périmètre de la Phase 1 consiste donc à peupler exclusivement les répertoires `domain/` de ces 5 fonctionnalités en Dart pur, sans impacter `data/`, `presentation/` ou `lib/main.dart`.

---

## 4. État des Tests Existants (`test/`)

- Un seul fichier de test existe actuellement : `test/widget_test.dart` (100 lignes).
- Contenu des tests :
  - Invariants métier et configuration (`AppConfig.appName`, politique zéro prix).
  - Souveraineté OSM (URL OSM France, user agent, URL search/point).
  - Référentiel des repères urbains de Yaoundé (`YaoundeLandmarks`).
  - Égalité par valeur des `Failure` du domaine (`NetworkFailure`, `InsufficientStockFailure`).
  - Tests multi-viewport (mobile 390x844 et desktop 1280x800).
- Tous les tests existants passent à 100% (6/6 passés).

---

## 5. Environnement d'Exécution & Tooling

| Outil | Chemin | Version Détectée | Statut |
| :--- | :--- | :--- | :--- |
| **Dart SDK** | `/home/charles/development/flutter/bin/dart` | `3.13.5 (stable)` | Opérationnel |
| **Flutter SDK** | `/home/charles/development/flutter/bin/flutter` | `3.47.7 • channel stable` | Opérationnel |
| **Analyse Statique** | `/home/charles/development/flutter/bin/dart analyze --fatal-infos --fatal-warnings` | Exit 0 (`No issues found!`) | Conforme |
| **Test Runner** | `/home/charles/development/flutter/bin/flutter test` | Exit 0 (6/6 tests réussis avec `BypassSandbox: true` pour le socket WebSocket) | Conforme |

> **Note d'exécution** : Flutter test démarre un serveur local loopback sur WebSocket (`127.0.0.1:<port>`). Dans l'environnement agentique, l'exécution de `flutter test` requiert `BypassSandbox: true` pour autoriser la liaison de socket interne.

---

## 6. Synthèse & Recommandations pour l'Implémentation de l'Étape 1

1. **Pureté du Domaine** :
   - Les entités du domaine doivent étendre `Equatable` (ou utiliser des constructeurs constants avec égalité par valeur explicite) sans aucune dépendance vers Flutter (`import 'package:flutter/material.dart'` strictement interdit dans `domain/`).
   - Seules dépendances autorisées dans `domain/` : `package:equatable/equatable.dart`, `package:fpdart/fpdart.dart`, `package:medmate/core/errors/failures.dart`, et les entités internes.
2. **Invariants Métier Stricts** :
   - Entité `Medication` : AUCUN attribut de prix.
   - Entité `PharmacyOffer` et `OfferItemResponse` : Prix unitaire et montant total autorisés car émis exclusivement par le pharmacien au comptoir.
   - Entité `Reservation` : TTL 2 heures (`AppConfig.reservationTtl`), OTP à 6 chiffres.
   - Cas d'usage `EscalateDispatchWaveUseCase` : Vagues de 2 officines partenaires par intervalle (Round-Robin déontologique ONPC).
3. **Gestion des Erreurs dans les UseCases** :
   - Retour systématique d'un `Future<Either<Failure, T>>` (ou `Stream<Either<Failure, T>>` si nécessaire).
   - Ajout d'une `ValidationFailure` dans `lib/core/errors/failures.dart` pour les cas de validation rejetée (ex. panier vide, code OTP invalide).
4. **Mocks & Tests Unitaires** :
   - Utilisation de `mocktail` (`class MockAuthRepository extends Mock implements AuthRepository {}`).
   - Couverture complète 100% de tous les UseCases nominaux et Failure.
