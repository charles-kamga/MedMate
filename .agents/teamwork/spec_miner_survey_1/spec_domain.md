# Authoritative Domain Specification — Afya Santé (`package:medmate`)

**Phase 1 Survey — Spec Miner 1 Report**  
**Date**: 2026-11-09  
**Target Package**: `medmate` (`lib/features/*/domain/`, `test/features/*/domain/`)  
**Compliance Standard**: Pure Dart (SDK >=3.2.0 <4.0.0), `equatable` ^2.0.5, `fpdart` ^1.1.0, Zero UI / Flutter imports, Zero `dart:io`, Zero `dynamic`.

---

## 1. Executive Summary & Inviolable Domain Invariants

Afya Santé connects patients with community pharmacies across Yaoundé, Cameroon. The domain layer encapsulates all critical business rules, ethical legal mandates (ONPC), and health data privacy regulations (Cameroon Law n° 2024/017 ANTIC/APDP).

### 1.1 Inviolable Business & Legal Invariants
1. **Politique Zéro Prix Affiché (Tarification au Comptoir)**:
   - **Absolute prohibition** of any price field in the `Medication` entity (`lib/features/pharmacy_search/domain/entities/medication.dart`).
   - Prices exist **exclusively** in pharmacist counter quotes/offers (`OfferItemResponse.prixUnitaireCommunicParPharmacien`, `PharmacyOffer.montantTotalPropose`, `CounterQuoteSubmission`).
2. **Souveraineté Cartographique OpenStreetMap (OSM) & Repères Urbains de Yaoundé**:
   - Location queries rely on Yaoundé urban landmarks (Carrefours, Quartiers) and WGS84 coordinates (`latitude`, `longitude`, `distanceMetres`).
   - Absolute prohibition of Google Maps (`google_maps_flutter`, Google Places API) and Mapbox.
3. **Neutralité Déontologique ONPC (Loi n° 90-035)**:
   - Free choice of pharmacy by the patient. No sponsored or paid pharmacy rankings.
   - Algorithmic dispatch escalation operates in **fair Round-Robin waves of 2 partner pharmacies** (`vagues de 2 pharmacies partenaires`).
4. **Sécurité & Protection des Données de Santé (Loi n° 2024/017 ANTIC/APDP)**:
   - **OTP 6 Chiffres**: Reservations require a strictly 6-digit numeric OTP code (`codeRetraitOtp6Chiffres`, regex `^\d{6}$`).
   - **TTL 2 Heures**: Reservations strictly expire after 2 hours (`AppConfig.reservationTtl = Duration(hours: 2)`).
   - **Minimisation Patient**: Patient browsing is anonymous/ephemeral; phone number is only requested at reservation confirmation.
   - **Zero PII Analytics**: Pharmacy daily analytics report aggregated counts only; zero patient names, zero phone numbers, zero prescription content.
5. **Pure Dart Domain Architecture**:
   - Every file under `lib/features/*/domain/` must be pure Dart. Zero imports of `package:flutter/...` or `dart:io`.
   - Immutable entities extending `Equatable`.
   - All repository and usecase methods return `Future<Either<Failure, T>>` from `package:fpdart/fpdart.dart`.
   - Zero `dynamic`: complete static type safety.

---

## 2. Architecture & Design Patterns

### 2.1 Directory Structure
```text
lib/features/
├── auth/
│   └── domain/
│       ├── entities/
│       │   ├── patient_session.dart
│       │   ├── pharmacist_profile.dart
│       │   └── user_session.dart
│       ├── repositories/
│       │   └── auth_repository.dart
│       └── usecases/
│           ├── get_current_session_usecase.dart
│           ├── sign_in_pharmacist_usecase.dart
│           └── sign_out_usecase.dart
├── pharmacy_search/
│   └── domain/
│       ├── entities/
│       │   ├── medication.dart
│       │   └── pharmacy.dart
│       ├── repositories/
│       │   └── pharmacy_search_repository.dart
│       └── usecases/
│           ├── search_medications_usecase.dart
│           └── search_nearby_pharmacies_usecase.dart
├── reservation/
│   └── domain/
│       ├── entities/
│       │   ├── basket_item.dart
│       │   ├── flash_request.dart
│       │   ├── item_availability_status.dart
│       │   ├── offer_item_response.dart
│       │   ├── pharmacy_offer.dart
│       │   └── reservation.dart
│       ├── repositories/
│       │   └── reservation_repository.dart
│       └── usecases/
│           ├── confirm_reservation_otp_usecase.dart
│           ├── escalate_dispatch_wave_usecase.dart
│           ├── select_pharmacy_offer_usecase.dart
│           └── submit_flash_request_usecase.dart
├── duty_pharmacy/
│   └── domain/
│       ├── entities/
│       │   └── duty_schedule.dart
│       ├── repositories/
│       │   └── duty_pharmacy_repository.dart
│       └── usecases/
│           └── get_duty_pharmacies_by_quartier_usecase.dart
└── pharmacist_portal/
    └── domain/
        ├── entities/
        │   ├── counter_quote_submission.dart
        │   ├── incoming_demand.dart
        │   └── pharmacy_daily_analytics.dart
        ├── repositories/
        │   └── pharmacist_portal_repository.dart
        └── usecases/
            ├── get_pharmacy_analytics_usecase.dart
            ├── submit_counter_quote_usecase.dart
            └── validate_pickup_otp_usecase.dart
```

### 2.2 Base UseCase Contract
Each UseCase implements a callable signature:
```dart
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

class NoParams extends Equatable {
  const NoParams();
  @override
  List<Object?> get props => [];
}
```

---

## 3. Feature 1: `auth` Domain Specification

### 3.1 Entities

#### 1. `PatientSession` (`patient_session.dart`)
- **Purpose**: Represents the patient session, which is anonymous/ephemeral during initial browsing and medication search, and takes a phone number at the time of reservation.
- **Fields**:
  - `sessionId`: `String` (UUID v4 / unique token) — **non-nullable**
  - `phoneNumber`: `String?` (null initially, mandatory at reservation) — **nullable**
  - `createdAt`: `DateTime` — **non-nullable**
  - `lastActiveAt`: `DateTime` — **non-nullable**
- **Computed Properties**:
  - `bool get isAnonymous => phoneNumber == null || phoneNumber!.isEmpty;`
- **Validation Rules**:
  - `sessionId.trim().isNotEmpty`
  - If `phoneNumber != null`, must match Cameroon format: `RegExp(r'^(?:(?:\+237)|(?:237))?[26]\d{8}$')`.
- **Immutability & Equality**: Extends `Equatable`. Props: `[sessionId, phoneNumber, createdAt, lastActiveAt]`. Supports `copyWith`.

#### 2. `PharmacistProfile` (`pharmacist_profile.dart`)
- **Purpose**: Represents an authenticated, ONPC-registered pharmacist managing counter operations.
- **Fields**:
  - `userId`: `String` (Supabase auth user UUID) — **non-nullable**
  - `pharmacyId`: `String` (associated pharmacy UUID) — **non-nullable**
  - `licenceOnpc`: `String` (ONPC registration number, e.g., "ONPC-CMR-8472") — **non-nullable**
  - `role`: `PharmacistRole` (enum: `titulaire`, `adjoint`, `gerant`, `comptoir`) — **non-nullable**
  - `fullName`: `String` (e.g. "Dr. Amadou Bello") — **non-nullable**
  - `email`: `String` — **non-nullable**
  - `telephone`: `String` — **non-nullable**
  - `isVerified`: `bool` (ONPC verification flag) — **non-nullable**
- **Validation Rules**:
  - `userId`, `pharmacyId`, `licenceOnpc`, `fullName`, `email`, `telephone` must not be empty.
  - `email` must contain `@`.
- **Immutability & Equality**: Extends `Equatable`. Props: `[userId, pharmacyId, licenceOnpc, role, fullName, email, telephone, isVerified]`. Supports `copyWith`.

#### 3. `UserSession` (`user_session.dart`)
- **Purpose**: Unified session wrapper indicating the active session type (Patient vs Pharmacist).
- **Fields**:
  - `sessionId`: `String` — **non-nullable**
  - `patientSession`: `PatientSession?` — **nullable**
  - `pharmacistProfile`: `PharmacistProfile?` — **nullable**
  - `createdAt`: `DateTime` — **non-nullable**
  - `isActive`: `bool` — **non-nullable**
- **Computed Properties**:
  - `bool get isPharmacist => pharmacistProfile != null;`
  - `bool get isPatient => patientSession != null;`
  - `bool get isAuthenticated => isPharmacist || (patientSession != null && !patientSession!.isAnonymous);`
- **Validation Rules**:
  - `sessionId` not empty.
  - At least one of `patientSession` or `pharmacistProfile` should be present when active.
- **Immutability & Equality**: Extends `Equatable`. Props: `[sessionId, patientSession, pharmacistProfile, createdAt, isActive]`. Supports `copyWith`.

### 3.2 Abstract Repository (`auth_repository.dart`)
```dart
abstract class AuthRepository {
  /// Fetches the currently active session (Patient or Pharmacist)
  Future<Either<Failure, UserSession>> getCurrentSession();

  /// Authenticates a pharmacist with email and password
  Future<Either<Failure, PharmacistProfile>> signInPharmacist({
    required String email,
    required String password,
  });

  /// Signs out current user/session and cleans up local session state
  Future<Either<Failure, void>> signOut();

  /// Initializes or retrieves an ephemeral patient session
  Future<Either<Failure, PatientSession>> getOrCreatePatientSession({
    String? phoneNumber,
  });
}
```

### 3.3 UseCases

#### 1. `GetCurrentSessionUseCase`
- **Input**: `NoParams`
- **Output**: `Future<Either<Failure, UserSession>>`
- **Logic**: Directly queries `AuthRepository.getCurrentSession()`.

#### 2. `SignInPharmacistUseCase`
- **Input**: `SignInPharmacistParams(email: String, password: String)`
- **Output**: `Future<Either<Failure, PharmacistProfile>>`
- **Validation**:
  - `email.trim().isNotEmpty` and valid format; else returns `Left(AuthFailure('Adresse email invalide.'))`.
  - `password.length >= 6`; else returns `Left(AuthFailure('Le mot de passe doit comporter au moins 6 caractères.'))`.
- **Logic**: Once validated, delegates to `AuthRepository.signInPharmacist(...)`.

#### 3. `SignOutUseCase`
- **Input**: `NoParams`
- **Output**: `Future<Either<Failure, void>>`
- **Logic**: Delegates to `AuthRepository.signOut()`.

---

## 4. Feature 2: `pharmacy_search` Domain Specification

### 4.1 Entities

#### 1. `Medication` (`medication.dart`)
- **CRITICAL INVARIANT**: **ABSOLUTELY NO PRICE FIELD**. No `prix`, `price`, `cout`, `tarif`, `prixCatalogue`.
- **Fields**:
  - `id`: `String` (UUID or national identifier) — **non-nullable**
  - `codeNational`: `String` (CIP / Code national du médicament) — **non-nullable**
  - `nomCommercial`: `String` (Brand name, e.g. "Paracétamol Biogaran", "Amoxicilline Arrow") — **non-nullable**
  - `dci`: `String` (Dénomination Commune Internationale, e.g. "Paracétamol", "Amoxicilline") — **non-nullable**
  - `forme`: `String` (Galenic form, e.g. "Comprimé effervescent", "Sirop", "Gélule") — **non-nullable**
  - `dosage`: `String` (e.g. "500 mg", "1 g", "125 mg/5 ml") — **non-nullable**
  - `necessiteOrdonnance`: `bool` (prescription requirement flag) — **non-nullable**
- **Validation Rules**:
  - `id`, `codeNational`, `nomCommercial`, `dci`, `forme`, `dosage` must not be empty.
- **Immutability & Equality**: Extends `Equatable`. Props: `[id, codeNational, nomCommercial, dci, forme, dosage, necessiteOrdonnance]`. Supports `copyWith`.

#### 2. `Pharmacy` (`pharmacy.dart`)
- **Fields**:
  - `id`: `String` (UUID) — **non-nullable**
  - `nom`: `String` (e.g. "Pharmacie Bastos", "Pharmacie du Soleil") — **non-nullable**
  - `licenceOnpc`: `String` (ONPC official license number) — **non-nullable**
  - `quartier`: `String` (e.g. "Bastos", "Mokolo", "Biyem-Assi") — **non-nullable**
  - `carrefourRepere`: `String` (e.g. "Carrefour Warda", "Carrefour Obili") — **non-nullable**
  - `latitude`: `double` (WGS84, Yaoundé: ~3.80 - 3.95) — **non-nullable**
  - `longitude`: `double` (WGS84, Yaoundé: ~11.45 - 11.58) — **non-nullable**
  - `telephoneGarde`: `String` (Phone number for emergency contact, e.g. "+237699000000") — **non-nullable**
  - `estOuverte`: `bool` (currently open) — **non-nullable**
  - `estDeGarde`: `bool` (on duty) — **non-nullable**
  - `estPartenaire`: `bool` (partner officine accepting digital flash requests) — **non-nullable**
  - `distanceMetres`: `double?` (distance from patient / query reference point in metres) — **nullable**
- **Validation Rules**:
  - `latitude` must be between -90 and 90; `longitude` between -180 and 180.
  - `nom`, `licenceOnpc`, `quartier`, `carrefourRepere`, `telephoneGarde` must not be empty.
- **Immutability & Equality**: Extends `Equatable`. Props: `[id, nom, licenceOnpc, quartier, carrefourRepere, latitude, longitude, telephoneGarde, estOuverte, estDeGarde, estPartenaire, distanceMetres]`. Supports `copyWith`.

### 4.2 Abstract Repository (`pharmacy_search_repository.dart`)
```dart
abstract class PharmacySearchRepository {
  /// Searches medications with fault-tolerant fuzzy/trigram matching
  Future<Either<Failure, List<Medication>>> searchMedications(String query);

  /// Searches nearby pharmacies filtered by Yaoundé landmark or GPS coordinates
  Future<Either<Failure, List<Pharmacy>>> searchNearbyPharmacies({
    String? quartier,
    String? carrefourRepere,
    double? latitude,
    double? longitude,
    double? radiusMetres,
    bool? onlyOpen,
    bool? onlyDuty,
  });

  /// Fetches pharmacy details by ID
  Future<Either<Failure, Pharmacy>> getPharmacyById(String pharmacyId);
}
```

### 4.3 UseCases

#### 1. `SearchMedicationsUseCase`
- **Input**: `SearchMedicationsParams(query: String)`
- **Output**: `Future<Either<Failure, List<Medication>>>`
- **Validation & Business Logic**:
  - Trims `query`.
  - If `query.trim().length < 2`: returns immediate `Right([])` without hitting repository (avoids noisy network/server load).
  - Otherwise, delegates to `PharmacySearchRepository.searchMedications(query.trim())`.

#### 2. `SearchNearbyPharmaciesUseCase`
- **Input**: `SearchNearbyPharmaciesParams({String? quartier, String? carrefourRepere, double? latitude, double? longitude, double? radiusMetres, bool? onlyOpen, bool? onlyDuty})`
- **Output**: `Future<Either<Failure, List<Pharmacy>>>`
- **Validation & Business Logic**:
  - Validates that at least one location parameter is provided (`quartier != null || carrefourRepere != null || (latitude != null && longitude != null)`).
  - If neither is provided: returns `Left(LocationFailure('Veuillez fournir un quartier, un carrefour ou des coordonnées GPS.'))`.
  - Coordinates check: if provided, `latitude >= -90 && latitude <= 90` and `longitude >= -180 && longitude <= 180`.
  - Delegates to `PharmacySearchRepository.searchNearbyPharmacies(...)`.

---

## 5. Feature 3: `reservation` Domain Specification

### 5.1 Entities

#### 1. `BasketItem` (`basket_item.dart`)
- **Fields**:
  - `medication`: `Medication` — **non-nullable**
  - `quantite`: `int` — **non-nullable**
  - `precision`: `String?` (e.g. "Générique accepté si disponible", "Boîte de 30") — **nullable**
- **Validation Rules**:
  - `quantite >= 1`. If `quantite < 1`, throws or triggers domain validation failure.
- **Immutability & Equality**: Extends `Equatable`. Props: `[medication, quantite, precision]`. Supports `copyWith`.

#### 2. `ItemAvailabilityStatus` (`item_availability_status.dart`)
- **Enum**:
  - `available`: Product in stock and reserved at the counter.
  - `unavailable`: Product completely out of stock.
  - `conditional`: Available under condition (e.g., generic substitution, partial quantity, or prescription required).

#### 3. `OfferItemResponse` (`offer_item_response.dart`)
- **Fields**:
  - `medicationId`: `String` — **non-nullable**
  - `status`: `ItemAvailabilityStatus` — **non-nullable**
  - `prixUnitaireCommunicParPharmacien`: `double` (in FCFA, strictly entered at counter by pharmacist; 0.0 if unavailable) — **non-nullable**
  - `conditionDelivrance`: `String?` (e.g. "Ordonnance originale requise") — **nullable**
  - `commentaire`: `String?` (e.g. "Remplacement par générique Biogaran") — **nullable**
- **Validation Rules**:
  - `prixUnitaireCommunicParPharmacien >= 0`.
- **Immutability & Equality**: Extends `Equatable`. Props: `[medicationId, status, prixUnitaireCommunicParPharmacien, conditionDelivrance, commentaire]`. Supports `copyWith`.

#### 4. `PharmacyOffer` (`pharmacy_offer.dart`)
- **Fields**:
  - `id`: `String` (UUID) — **non-nullable**
  - `demandeId`: `String` (ID of FlashRequest) — **non-nullable**
  - `pharmacyId`: `String` (UUID) — **non-nullable**
  - `pharmacyNom`: `String` — **non-nullable**
  - `quartier`: `String` — **non-nullable**
  - `distanceMetres`: `double?` — **nullable**
  - `items`: `List<OfferItemResponse>` — **non-nullable**
  - `montantTotalPropose`: `double` (Total sum in FCFA) — **non-nullable**
  - `livraisonDisponible`: `bool` — **non-nullable**
  - `fraisLivraison`: `double?` (in FCFA) — **nullable**
  - `delaiLivraisonMinutes`: `int?` — **nullable**
  - `createdAt`: `DateTime` — **non-nullable**
- **Validation Rules**:
  - `items` must not be empty.
  - `montantTotalPropose >= 0`.
- **Immutability & Equality**: Extends `Equatable`. Props: `[id, demandeId, pharmacyId, pharmacyNom, quartier, distanceMetres, items, montantTotalPropose, livraisonDisponible, fraisLivraison, delaiLivraisonMinutes, createdAt]`. Supports `copyWith`.

#### 5. `FlashRequest` (`flash_request.dart`)
- **Fields**:
  - `id`: `String` (UUID) — **non-nullable**
  - `clientRequestId`: `String` (Client-generated UUID for idempotency) — **non-nullable**
  - `items`: `List<BasketItem>` — **non-nullable**
  - `quartierOuCarrefour`: `String` (Yaoundé landmark, e.g. "Carrefour Warda") — **non-nullable**
  - `statut`: `FlashRequestStatus` (enum: `pending`, `active`, `partiallyAnswered`, `fulfilled`, `expired`, `cancelled`) — **non-nullable**
  - `vagueActuelle`: `int` (wave index, 1-based: 1, 2, 3...) — **non-nullable**
  - `pharmaciesNotifieesIds`: `List<String>` (IDs of pharmacies notified) — **non-nullable**
  - `offresRecues`: `List<PharmacyOffer>` — **non-nullable**
  - `createdAt`: `DateTime` — **non-nullable**
  - `expiresAt`: `DateTime` — **non-nullable**
- **Computed Properties**:
  - `bool get hasOffers => offresRecues.isNotEmpty;`
  - `bool get isExpired => DateTime.now().isAfter(expiresAt);`
- **Validation Rules**:
  - `items.isNotEmpty`
  - `vagueActuelle >= 1`
- **Immutability & Equality**: Extends `Equatable`. Props: `[id, clientRequestId, items, quartierOuCarrefour, statut, vagueActuelle, pharmaciesNotifieesIds, offresRecues, createdAt, expiresAt]`. Supports `copyWith`.

#### 6. `Reservation` (`reservation.dart`)
- **Fields**:
  - `id`: `String` (UUID) — **non-nullable**
  - `clientReservationId`: `String` (UUID for idempotency) — **non-nullable**
  - `demandeId`: `String` (FlashRequest ID) — **non-nullable**
  - `offreId`: `String` (Selected PharmacyOffer ID) — **non-nullable**
  - `pharmacyId`: `String` — **non-nullable**
  - `codeRetraitOtp6Chiffres`: `String` (strictly 6 numeric digits, e.g. "482910") — **non-nullable**
  - `statut`: `ReservationStatus` (enum: `pending`, `confirmedAtCounter`, `completed`, `cancelled`, `expired`) — **non-nullable**
  - `createdAt`: `DateTime` — **non-nullable**
  - `expiresAt`: `DateTime` (Strict TTL of 2 hours) — **non-nullable**
- **Computed Properties**:
  - `bool get isExpired => DateTime.now().isAfter(expiresAt);`
  - `Duration get remainingTime => expiresAt.difference(DateTime.now());`
- **Validation Rules**:
  - `codeRetraitOtp6Chiffres` must match `RegExp(r'^\d{6}$')`.
  - `expiresAt.difference(createdAt)` equals `Duration(hours: 2)` (tolerance +/- 1 second).
- **Immutability & Equality**: Extends `Equatable`. Props: `[id, clientReservationId, demandeId, offreId, pharmacyId, codeRetraitOtp6Chiffres, statut, createdAt, expiresAt]`. Supports `copyWith`.

### 5.2 Abstract Repository (`reservation_repository.dart`)
```dart
abstract class ReservationRepository {
  /// Submits an initial flash request to find medication availability
  Future<Either<Failure, FlashRequest>> submitFlashRequest({
    required String clientRequestId,
    required List<BasketItem> items,
    required String quartierOuCarrefour,
    double? latitude,
    double? longitude,
  });

  /// Escalates dispatch to the next wave of 2 partner pharmacies in Round-Robin order
  Future<Either<Failure, FlashRequest>> escalateDispatchWave({
    required String demandeId,
    required int nextWaveNumber,
    required List<String> eligiblePharmacyIds,
  });

  /// Selects an offer and creates a 2-hour reservation with a 6-digit OTP
  Future<Either<Failure, Reservation>> selectPharmacyOffer({
    required String clientReservationId,
    required String demandeId,
    required String offreId,
    required String patientPhone,
  });

  /// Confirms reservation at counter by submitting/verifying 6-digit OTP
  Future<Either<Failure, Reservation>> confirmReservationOtp({
    required String reservationId,
    required String otpCode,
  });

  /// Retrieves a flash request by ID
  Future<Either<Failure, FlashRequest>> getFlashRequestById(String demandeId);

  /// Retrieves a reservation by ID
  Future<Either<Failure, Reservation>> getReservationById(String reservationId);
}
```

### 5.3 UseCases

#### 1. `SubmitFlashRequestUseCase`
- **Input**: `SubmitFlashRequestParams({required String clientRequestId, required List<BasketItem> items, required String quartierOuCarrefour, double? latitude, double? longitude})`
- **Output**: `Future<Either<Failure, FlashRequest>>`
- **Validation Rules**:
  - `items.isNotEmpty`; else returns `Left(ReservationFailure('Le panier ne peut pas être vide.'))`.
  - For every item in `items`: `item.quantite >= 1`; else returns `Left(ReservationFailure('La quantité de chaque médicament doit être au moins 1.'))`.
  - `clientRequestId.trim().isNotEmpty` and `quartierOuCarrefour.trim().isNotEmpty`; else returns `Left(ReservationFailure('Paramètres de demande invalides.'))`.
- **Logic**: Validates params, then delegates to `ReservationRepository.submitFlashRequest(...)`.

#### 2. `EscalateDispatchWaveUseCase`
- **Input**: `EscalateDispatchWaveParams({required String demandeId, required int currentWave, required List<String> candidatePharmacyIds, required List<String> alreadyNotifiedPharmacyIds})`
- **Output**: `Future<Either<Failure, FlashRequest>>`
- **Validation Rules & Round-Robin Invariant**:
  - `demandeId.trim().isNotEmpty`.
  - Filter `candidatePharmacyIds` to exclude `alreadyNotifiedPharmacyIds`.
  - Next wave takes **up to 2 unnotified partner pharmacies** (`take(2).toList()`), adhering strictly to ONPC fair round-robin dispatch.
  - If no unnotified pharmacies remain, returns `Left(ReservationFailure('Aucune officine partenaire supplémentaire disponible pour escalade.'))`.
  - `nextWaveNumber = currentWave + 1`.
- **Logic**: Calls `ReservationRepository.escalateDispatchWave(demandeId: demandeId, nextWaveNumber: nextWaveNumber, eligiblePharmacyIds: nextTwoPharmacies)`.

#### 3. `SelectPharmacyOfferUseCase`
- **Input**: `SelectPharmacyOfferParams({required String clientReservationId, required String demandeId, required String offreId, required String patientPhone})`
- **Output**: `Future<Either<Failure, Reservation>>`
- **Validation Rules**:
  - `clientReservationId.trim().isNotEmpty`, `demandeId.trim().isNotEmpty`, `offreId.trim().isNotEmpty`.
  - `patientPhone`: must match Cameroon phone format: `RegExp(r'^(?:(?:\+237)|(?:237))?[26]\d{8}$')`. Else returns `Left(ReservationFailure('Numéro de téléphone camerounais invalide (+237...).'))`.
- **Logic**: Validates params, delegates to `ReservationRepository.selectPharmacyOffer(...)`.

#### 4. `ConfirmReservationOtpUseCase`
- **Input**: `ConfirmReservationOtpParams({required String reservationId, required String otpCode})`
- **Output**: `Future<Either<Failure, Reservation>>`
- **Validation Rules**:
  - `reservationId.trim().isNotEmpty`.
  - `otpCode.trim()` must be strictly 6 numeric digits: `RegExp(r'^\d{6}$').hasMatch(otpCode.trim())`.
  - If not: returns `Left(ReservationFailure("Le code OTP doit comporter exactement 6 chiffres."))`.
- **Logic**: Validates OTP format, delegates to `ReservationRepository.confirmReservationOtp(...)`.

---

## 6. Feature 4: `duty_pharmacy` Domain Specification

### 6.1 Entities

#### 1. `DutySchedule` (`duty_schedule.dart`)
- **Fields**:
  - `id`: `String` (UUID) — **non-nullable**
  - `pharmacy`: `Pharmacy` — **non-nullable**
  - `dateGarde`: `DateTime` (Date of duty) — **non-nullable**
  - `heureDebut`: `String` (e.g. "20:00") — **non-nullable**
  - `heureFin`: `String` (e.g. "08:00") — **non-nullable**
  - `verifieParOnpc`: `bool` (ONPC official verification) — **non-nullable**
  - `groupeGarde`: `String?` (e.g. "Groupe Centre 1", "Secteur Ouest") — **nullable**
- **Validation Rules**:
  - `id`, `heureDebut`, `heureFin` must not be empty.
  - `pharmacy` must be valid.
- **Immutability & Equality**: Extends `Equatable`. Props: `[id, pharmacy, dateGarde, heureDebut, heureFin, verifieParOnpc, groupeGarde]`. Supports `copyWith`.

### 6.2 Abstract Repository (`duty_pharmacy_repository.dart`)
```dart
abstract class DutyPharmacyRepository {
  /// Fetches on-duty pharmacies for a specific quartier and date
  Future<Either<Failure, List<DutySchedule>>> getDutyPharmaciesByQuartier({
    required String quartier,
    DateTime? targetDate,
  });

  /// Fetches all active duty schedules in Yaoundé for a given date/time
  Future<Either<Failure, List<DutySchedule>>> getAllActiveDutySchedules({
    DateTime? targetDate,
  });
}
```

### 6.3 UseCases

#### 1. `GetDutyPharmaciesByQuartierUseCase`
- **Input**: `GetDutyPharmaciesByQuartierParams({required String quartier, DateTime? targetDate})`
- **Output**: `Future<Either<Failure, List<DutySchedule>>>`
- **Validation Rules**:
  - `quartier.trim().isNotEmpty`; else returns `Left(LocationFailure('Le quartier doit être spécifié.'))`.
- **Logic**: Delegates to `DutyPharmacyRepository.getDutyPharmaciesByQuartier(quartier: quartier.trim(), targetDate: targetDate)`.

---

## 7. Feature 5: `pharmacist_portal` Domain Specification

### 7.1 Entities

#### 1. `IncomingDemand` (`incoming_demand.dart`)
- **Fields**:
  - `id`: `String` (UUID) — **non-nullable**
  - `demandeId`: `String` (FlashRequest ID) — **non-nullable**
  - `patientReference`: `String` (Anonymized / pseudonymized patient identifier) — **non-nullable**
  - `items`: `List<BasketItem>` — **non-nullable**
  - `quartierPatient`: `String` (e.g. "Mokolo", "Bastos") — **non-nullable**
  - `recueAt`: `DateTime` — **non-nullable**
  - `expiresAt`: `DateTime` (Response window limit, e.g. 5 to 10 min) — **non-nullable**
  - `statut`: `DemandStatus` (enum: `enAttente`, `repondue`, `expiree`, `rejetee`) — **non-nullable**
- **Computed Properties**:
  - `bool get isExpired => DateTime.now().isAfter(expiresAt);`
- **Validation Rules**:
  - `id`, `demandeId`, `items` must not be empty.
- **Immutability & Equality**: Extends `Equatable`. Props: `[id, demandeId, patientReference, items, quartierPatient, recueAt, expiresAt, statut]`. Supports `copyWith`.

#### 2. `CounterQuoteSubmission` (`counter_quote_submission.dart`)
- **Fields**:
  - `demandeId`: `String` — **non-nullable**
  - `pharmacyId`: `String` — **non-nullable**
  - `itemsResponse`: `List<OfferItemResponse>` — **non-nullable**
  - `montantTotal`: `double` (Total quote calculated or confirmed at counter) — **non-nullable**
  - `livraisonPossible`: `bool` — **non-nullable**
  - `fraisLivraison`: `double?` (in FCFA) — **nullable**
  - `delaiEstimeMinutes`: `int?` — **nullable**
  - `commentairePharmacien`: `String?` — **nullable**
- **INVARIANT**:
  - Prices are entered **exclusively** by the pharmacist here (`prixUnitaireCommunicParPharmacien` and `montantTotal >= 0`).
- **Validation Rules**:
  - `demandeId.trim().isNotEmpty` and `pharmacyId.trim().isNotEmpty`.
  - `itemsResponse.isNotEmpty`.
  - `montantTotal >= 0`.
  - For every item in `itemsResponse`, if `status == ItemAvailabilityStatus.available` or `conditional`, `prixUnitaireCommunicParPharmacien >= 0`.
- **Immutability & Equality**: Extends `Equatable`. Props: `[demandeId, pharmacyId, itemsResponse, montantTotal, livraisonPossible, fraisLivraison, delaiEstimeMinutes, commentairePharmacien]`. Supports `copyWith`.

#### 3. `PharmacyDailyAnalytics` (`pharmacy_daily_analytics.dart`)
- **HEALTH DATA PRIVACY INVARIANT (Loi n° 2024/017 ANTIC)**:
  - **Zero PII**: No patient names, no patient phone numbers, no specific drug prescription histories.
  - Only anonymized aggregate operational metrics.
- **Fields**:
  - `id`: `String` (UUID) — **non-nullable**
  - `pharmacyId`: `String` (UUID) — **non-nullable**
  - `date`: `DateTime` — **non-nullable**
  - `totalDemandesRecues`: `int` — **non-nullable**
  - `totalDevisEnvoyes`: `int` — **non-nullable**
  - `totalReservationsConfirmees`: `int` — **non-nullable**
  - `tauxConversion`: `double` (e.g. 0.85 = 85%) — **non-nullable**
  - `tempsMoyenReponseSecondes`: `int` — **non-nullable**
- **Validation Rules**:
  - Counts must be non-negative (`>= 0`).
  - `tauxConversion >= 0.0 && tauxConversion <= 1.0`.
- **Immutability & Equality**: Extends `Equatable`. Props: `[id, pharmacyId, date, totalDemandesRecues, totalDevisEnvoyes, totalReservationsConfirmees, tauxConversion, tempsMoyenReponseSecondes]`. Supports `copyWith`.

### 7.2 Abstract Repository (`pharmacist_portal_repository.dart`)
```dart
abstract class PharmacistPortalRepository {
  /// Fetches incoming patient demands currently pending for this pharmacy
  Future<Either<Failure, List<IncomingDemand>>> getIncomingDemands({
    required String pharmacyId,
  });

  /// Submits counter quote with items pricing and delivery options
  Future<Either<Failure, PharmacyOffer>> submitCounterQuote(
    CounterQuoteSubmission submission,
  );

  /// Validates patient 6-digit OTP code at the counter to release medication
  Future<Either<Failure, Reservation>> validatePickupOtp({
    required String pharmacyId,
    required String reservationId,
    required String otpCode,
  });

  /// Retrieves aggregated daily analytics for the pharmacy
  Future<Either<Failure, PharmacyDailyAnalytics>> getPharmacyAnalytics({
    required String pharmacyId,
    required DateTime date,
  });
}
```

### 7.3 UseCases

#### 1. `SubmitCounterQuoteUseCase`
- **Input**: `CounterQuoteSubmission`
- **Output**: `Future<Either<Failure, PharmacyOffer>>`
- **Validation Rules**:
  - `submission.itemsResponse.isNotEmpty`; else returns `Left(ReservationFailure('La réponse doit contenir au moins un article.'))`.
  - `submission.montantTotal >= 0`; else returns `Left(ReservationFailure('Le montant total ne peut pas être négatif.'))`.
  - For available items: `prixUnitaireCommunicParPharmacien >= 0`.
- **Logic**: Validates submission, delegates to `PharmacistPortalRepository.submitCounterQuote(submission)`.

#### 2. `ValidatePickupOtpUseCase`
- **Input**: `ValidatePickupOtpParams({required String pharmacyId, required String reservationId, required String otpCode})`
- **Output**: `Future<Either<Failure, Reservation>>`
- **Validation Rules**:
  - `pharmacyId.trim().isNotEmpty` and `reservationId.trim().isNotEmpty`.
  - `otpCode.trim()` must be exactly 6 numeric digits: `RegExp(r'^\d{6}$').hasMatch(otpCode.trim())`.
  - If not: returns `Left(ReservationFailure('Le code OTP doit comporter exactement 6 chiffres.'))`.
- **Logic**: Validates OTP format, delegates to `PharmacistPortalRepository.validatePickupOtp(...)`.

#### 3. `GetPharmacyAnalyticsUseCase`
- **Input**: `GetPharmacyAnalyticsParams({required String pharmacyId, required DateTime date})`
- **Output**: `Future<Either<Failure, PharmacyDailyAnalytics>>`
- **Validation Rules**:
  - `pharmacyId.trim().isNotEmpty`; else returns `Left(AuthFailure('Identifiant pharmacie manquant.'))`.
- **Logic**: Delegates to `PharmacistPortalRepository.getPharmacyAnalytics(pharmacyId: pharmacyId.trim(), date: date)`.

---

## 8. Features Discovered & Edge Cases Matrix

### 8.1 Features Discovered
| # | Category | Feature | Description | Inputs | Outputs | Error Behavior | Discovered Via |
|---|----------|---------|-------------|--------|---------|----------------|----------------|
| 1 | `auth` | `GetCurrentSessionUseCase` | Retrieves active user/patient/pharmacist session | `NoParams` | `UserSession` | Returns `AuthFailure` on storage/server error | `ORIGINAL_REQUEST.md` R1 |
| 2 | `auth` | `SignInPharmacistUseCase` | Pharmacist credentials authentication with ONPC profile | `SignInPharmacistParams(email, password)` | `PharmacistProfile` | Returns `AuthFailure` on bad credentials or format error | `ORIGINAL_REQUEST.md` R1 |
| 3 | `auth` | `SignOutUseCase` | Revokes and clears session tokens | `NoParams` | `void` | Returns `AuthFailure` or `StorageFailure` | `ORIGINAL_REQUEST.md` R1 |
| 4 | `pharmacy_search` | `SearchMedicationsUseCase` | Fault-tolerant medication search (fuzzy/trigram) with zero catalogue price | `SearchMedicationsParams(query)` | `List<Medication>` | Short queries (<2 chars) return `Right([])`; DB errors return `ServerFailure` | `ORIGINAL_REQUEST.md` R1 & `AGENTS.md` Invariant 1 |
| 5 | `pharmacy_search` | `SearchNearbyPharmaciesUseCase` | Proximity search via Yaoundé landmarks (Carrefours/Quartiers) or GPS | `SearchNearbyPharmaciesParams(...)` | `List<Pharmacy>` | Returns `LocationFailure` if no landmark or GPS provided | `ORIGINAL_REQUEST.md` R1 & `architecture.md` §2 |
| 6 | `reservation` | `SubmitFlashRequestUseCase` | Creates multi-pharmacy availability inquiry | `SubmitFlashRequestParams(...)` | `FlashRequest` | Returns `ReservationFailure` if empty basket or non-positive quantity | `ORIGINAL_REQUEST.md` R2 |
| 7 | `reservation` | `EscalateDispatchWaveUseCase` | Escalates to next wave of 2 partner pharmacies in Round-Robin order | `EscalateDispatchWaveParams(...)` | `FlashRequest` | Returns `ReservationFailure` if no candidate pharmacies remain | `ORIGINAL_REQUEST.md` R2 & `AGENTS.md` Invariant 3 |
| 8 | `reservation` | `SelectPharmacyOfferUseCase` | Selects pharmacy offer and generates 2-hour reservation with 6-digit OTP | `SelectPharmacyOfferParams(...)` | `Reservation` | Returns `ReservationFailure` on invalid Cameroonian phone format | `ORIGINAL_REQUEST.md` R2 & `security.md` §4.3 |
| 9 | `reservation` | `ConfirmReservationOtpUseCase` | Confirms reservation using 6-digit OTP code | `ConfirmReservationOtpParams(reservationId, otpCode)` | `Reservation` | Returns `ReservationFailure` if OTP is not 6 digits or expired | `ORIGINAL_REQUEST.md` R2 & `security.md` §4.3 |
| 10 | `duty_pharmacy` | `GetDutyPharmaciesByQuartierUseCase` | Retrieves on-duty pharmacies for a Yaoundé quartier | `GetDutyPharmaciesByQuartierParams(quartier, date)` | `List<DutySchedule>` | Returns `LocationFailure` if quartier is empty | `ORIGINAL_REQUEST.md` R2 |
| 11 | `pharmacist_portal` | `SubmitCounterQuoteUseCase` | Pharmacist sets item availability and counter price | `CounterQuoteSubmission` | `PharmacyOffer` | Returns `ReservationFailure` on negative price or empty response | `ORIGINAL_REQUEST.md` R3 & `AGENTS.md` Invariant 1 |
| 12 | `pharmacist_portal` | `ValidatePickupOtpUseCase` | Pharmacist validates patient 6-digit OTP at counter | `ValidatePickupOtpParams(...)` | `Reservation` | Returns `ReservationFailure` if OTP format invalid or mismatch | `ORIGINAL_REQUEST.md` R3 |
| 13 | `pharmacist_portal` | `GetPharmacyAnalyticsUseCase` | Retrieves aggregated daily operational statistics (Zero PII) | `GetPharmacyAnalyticsParams(pharmacyId, date)` | `PharmacyDailyAnalytics` | Returns `AuthFailure` if pharmacyId is invalid | `ORIGINAL_REQUEST.md` R3 & `security.md` §4 |

### 8.2 Edge Cases Matrix
| # | Feature | Input | Observed Behavior |
|---|---------|-------|-------------------|
| 1 | `SearchMedicationsUseCase` | Query is 1 character (e.g. `"A"`) or whitespace `"   "` | Returns `Right([])` without calling remote repository to prevent excessive DB load. |
| 2 | `SearchMedicationsUseCase` | Query contains accents / special characters (e.g. `"paracétamol"`) | Normalized and searched via fault-tolerant trigram query. Zero price field in output. |
| 3 | `SearchNearbyPharmaciesUseCase` | Both landmark and GPS coordinates are null/empty | Returns `Left(LocationFailure('Veuillez fournir un quartier, un carrefour ou des coordonnées GPS.'))`. |
| 4 | `SearchNearbyPharmaciesUseCase` | GPS coordinates outside valid ranges (e.g. `lat: 100.0`) | Returns `Left(LocationFailure('Coordonnées géographiques invalides.'))`. |
| 5 | `SubmitFlashRequestUseCase` | Basket items list is empty `[]` | Returns `Left(ReservationFailure('Le panier ne peut pas être vide.'))`. |
| 6 | `SubmitFlashRequestUseCase` | Item quantity is 0 or negative | Returns `Left(ReservationFailure('La quantité de chaque médicament doit être au moins 1.'))`. |
| 7 | `EscalateDispatchWaveUseCase` | Candidate list has only 1 pharmacy left | Dispatches wave with that 1 pharmacy without failing; if 0 left, returns `Left(ReservationFailure(...))`. |
| 8 | `EscalateDispatchWaveUseCase` | Candidate list has 5 pharmacies left | Dispatches exactly the first 2 unnotified pharmacies in Round-Robin sequence (wave size = 2). |
| 9 | `SelectPharmacyOfferUseCase` | Invalid phone number (e.g. `"12345"` or `"abc"`) | Returns `Left(ReservationFailure('Numéro de téléphone camerounais invalide (+237...).'))`. |
| 10 | `ConfirmReservationOtpUseCase` | OTP code has 5 digits (`"12345"`) or letters (`"12345A"`) | Returns `Left(ReservationFailure("Le code OTP doit comporter exactement 6 chiffres."))`. |
| 11 | `ConfirmReservationOtpUseCase` | OTP code has exactly 6 digits (`"482910"`) | Passes regex validation and calls repository. |
| 12 | `Reservation` Entity | Expiration calculation `expiresAt.difference(createdAt)` | Must strictly equal `Duration(hours: 2)`. |
| 13 | `SubmitCounterQuoteUseCase` | `montantTotal` is negative (`-500.0`) | Returns `Left(ReservationFailure('Le montant total ne peut pas être négatif.'))`. |
| 14 | `ValidatePickupOtpUseCase` | OTP code has 7 digits (`"1234567"`) | Returns `Left(ReservationFailure('Le code OTP doit comporter exactement 6 chiffres.'))`. |
| 15 | `PharmacyDailyAnalytics` | Negative metrics (e.g. `-1` requests) | Domain rejects negative values; counts must be non-negative. |

---

## 9. Comprehensive Unit Testing Matrix

The unit testing suite (`test/features/*/domain/`) must provide 100% test coverage across all domain components using `mocktail` and `fpdart`.

### 9.1 Test File Organization
```text
test/features/
├── auth/
│   └── domain/
│       ├── entities/
│       │   ├── patient_session_test.dart
│       │   ├── pharmacist_profile_test.dart
│       │   └── user_session_test.dart
│       └── usecases/
│           ├── get_current_session_usecase_test.dart
│           ├── sign_in_pharmacist_usecase_test.dart
│           └── sign_out_usecase_test.dart
├── pharmacy_search/
│   └── domain/
│       ├── entities/
│       │   ├── medication_test.dart
│       │   └── pharmacy_test.dart
│       └── usecases/
│           ├── search_medications_usecase_test.dart
│           └── search_nearby_pharmacies_usecase_test.dart
├── reservation/
│   └── domain/
│       ├── entities/
│       │   ├── basket_item_test.dart
│       │   ├── flash_request_test.dart
│       │   ├── offer_item_response_test.dart
│       │   ├── pharmacy_offer_test.dart
│       │   └── reservation_test.dart
│       └── usecases/
│           ├── confirm_reservation_otp_usecase_test.dart
│           ├── escalate_dispatch_wave_usecase_test.dart
│           ├── select_pharmacy_offer_usecase_test.dart
│           └── submit_flash_request_usecase_test.dart
├── duty_pharmacy/
│   └── domain/
│       ├── entities/
│       │   └── duty_schedule_test.dart
│       └── usecases/
│           └── get_duty_pharmacies_by_quartier_usecase_test.dart
└── pharmacist_portal/
    └── domain/
        ├── entities/
        │   ├── counter_quote_submission_test.dart
        │   ├── incoming_demand_test.dart
        │   └── pharmacy_daily_analytics_test.dart
        └── usecases/
            ├── get_pharmacy_analytics_usecase_test.dart
            ├── submit_counter_quote_usecase_test.dart
            └── validate_pickup_otp_usecase_test.dart
```

### 9.2 Test Scenarios Breakdown

#### Group 1: `auth` Domain Tests
1. **`PatientSession` Tests**:
   - `patient_session_test.dart`:
     - Test equality and `props`: identical instances are equal.
     - Test `isAnonymous`: true when `phoneNumber` is null, false when phone provided.
     - Test `copyWith`: updates fields correctly.
2. **`PharmacistProfile` Tests**:
   - `pharmacist_profile_test.dart`:
     - Test equality and `props`.
     - Test `copyWith`.
3. **`UserSession` Tests**:
   - `user_session_test.dart`:
     - Test `isPharmacist`, `isPatient`, `isAuthenticated`.
     - Test equality and `props`.
4. **`GetCurrentSessionUseCase` Tests**:
   - `get_current_session_usecase_test.dart`:
     - Happy path: returns `Right(UserSession)`.
     - Failure path: repository returns `Left(AuthFailure)`.
5. **`SignInPharmacistUseCase` Tests**:
   - `sign_in_pharmacist_usecase_test.dart`:
     - Happy path: valid email/password returns `Right(PharmacistProfile)`.
     - Validation: empty/invalid email returns `Left(AuthFailure)`.
     - Validation: short password (< 6 chars) returns `Left(AuthFailure)`.
     - Failure path: repository returns `Left(AuthFailure('Identifiants invalides'))`.
6. **`SignOutUseCase` Tests**:
   - `sign_out_usecase_test.dart`:
     - Happy path: returns `Right(null)`.
     - Failure path: repository returns `Left(StorageFailure)`.

#### Group 2: `pharmacy_search` Domain Tests
1. **`Medication` Invariant & Entity Tests**:
   - `medication_test.dart`:
     - **CRITICAL**: Verify by reflection or field inspection that `Medication` contains NO price field (`price`, `prix`, `cout`).
     - Test equality and `props`: instances with identical properties are equal.
     - Test `copyWith`.
2. **`Pharmacy` Tests**:
   - `pharmacy_test.dart`:
     - Test equality, `props`, and `copyWith`.
     - Test coordinate values within Yaoundé boundaries.
3. **`SearchMedicationsUseCase` Tests**:
   - `search_medications_usecase_test.dart`:
     - Happy path: query `"paracétamol"` returns `Right(List<Medication>)`.
     - Short query edge case: query `""` or `"a"` returns `Right([])` without calling repository.
     - Failure path: repository returns `Left(ServerFailure)`.
4. **`SearchNearbyPharmaciesUseCase` Tests**:
   - `search_nearby_pharmacies_usecase_test.dart`:
     - Happy path (Landmark): `quartier: 'Bastos'` returns `Right(List<Pharmacy>)`.
     - Happy path (GPS): `latitude: 3.8688, longitude: 11.5175` returns `Right(List<Pharmacy>)`.
     - Validation failure: no location info returns `Left(LocationFailure)`.
     - Failure path: repository returns `Left(ServerFailure)`.

#### Group 3: `reservation` Domain Tests
1. **`BasketItem` Tests**:
   - `basket_item_test.dart`:
     - Test equality and `props`.
     - Test quantity >= 1.
2. **`Reservation` Invariant & Entity Tests**:
   - `reservation_test.dart`:
     - Test 6-digit OTP validation (`RegExp(r'^\d{6}$')`).
     - Test 2h TTL: `expiresAt.difference(createdAt) == Duration(hours: 2)`.
     - Test `isExpired`: true when `DateTime.now()` is past `expiresAt`.
     - Test equality and `props`.
3. **`SubmitFlashRequestUseCase` Tests**:
   - `submit_flash_request_usecase_test.dart`:
     - Happy path: valid basket and landmark returns `Right(FlashRequest)`.
     - Validation: empty basket returns `Left(ReservationFailure('Le panier ne peut pas être vide.'))`.
     - Validation: item with quantity 0 returns `Left(ReservationFailure)`.
     - Failure path: repository returns `Left(ServerFailure)`.
4. **`EscalateDispatchWaveUseCase` Tests (Round-Robin Invariant)**:
   - `escalate_dispatch_wave_usecase_test.dart`:
     - Happy path: escalates from wave 1 to wave 2 with exactly the next 2 partner pharmacies.
     - Escalation selection: given 4 candidate pharmacies and 2 already notified, calls repository with the remaining 2.
     - Edge case: given 0 remaining pharmacies, returns `Left(ReservationFailure)`.
     - Failure path: repository returns `Left(ServerFailure)`.
5. **`SelectPharmacyOfferUseCase` Tests**:
   - `select_pharmacy_offer_usecase_test.dart`:
     - Happy path: valid offer and Cameroonian phone returns `Right(Reservation)`.
     - Validation: invalid phone format returns `Left(ReservationFailure)`.
     - Failure path: repository returns `Left(ServerFailure)`.
6. **`ConfirmReservationOtpUseCase` Tests**:
   - `confirm_reservation_otp_usecase_test.dart`:
     - Happy path: valid 6-digit OTP (`"482910"`) returns `Right(Reservation)`.
     - Validation: 5-digit OTP returns `Left(ReservationFailure)`.
     - Validation: alphanumeric OTP (`"48291A"`) returns `Left(ReservationFailure)`.
     - Validation: 7-digit OTP returns `Left(ReservationFailure)`.
     - Failure path: repository returns `Left(ReservationFailure('Code OTP expiré ou incorrect.'))`.

#### Group 4: `duty_pharmacy` Domain Tests
1. **`DutySchedule` Tests**:
   - `duty_schedule_test.dart`:
     - Test equality and `props`.
     - Test `copyWith`.
2. **`GetDutyPharmaciesByQuartierUseCase` Tests**:
   - `get_duty_pharmacies_by_quartier_usecase_test.dart`:
     - Happy path: valid quartier returns `Right(List<DutySchedule>)`.
     - Validation: empty quartier returns `Left(LocationFailure)`.
     - Failure path: repository returns `Left(ServerFailure)`.

#### Group 5: `pharmacist_portal` Domain Tests
1. **`CounterQuoteSubmission` Tests (Tarification au Comptoir Invariant)**:
   - `counter_quote_submission_test.dart`:
     - Test equality and `props`.
     - Test that unit prices and total are non-negative.
2. **`PharmacyDailyAnalytics` Tests (Health Data Privacy Invariant)**:
   - `pharmacy_daily_analytics_test.dart`:
     - Test that entity contains NO patient names, phone numbers, or individual patient data.
     - Test equality and `props`.
3. **`SubmitCounterQuoteUseCase` Tests**:
   - `submit_counter_quote_usecase_test.dart`:
     - Happy path: valid counter quote with prices returns `Right(PharmacyOffer)`.
     - Validation: empty itemsResponse returns `Left(ReservationFailure)`.
     - Validation: negative total price returns `Left(ReservationFailure)`.
     - Failure path: repository returns `Left(ServerFailure)`.
4. **`ValidatePickupOtpUseCase` Tests**:
   - `validate_pickup_otp_usecase_test.dart`:
     - Happy path: valid 6-digit OTP validated at counter returns `Right(Reservation)`.
     - Validation: non-6-digit OTP returns `Left(ReservationFailure)`.
     - Failure path: repository returns `Left(ReservationFailure)`.
5. **`GetPharmacyAnalyticsUseCase` Tests**:
   - `get_pharmacy_analytics_usecase_test.dart`:
     - Happy path: valid pharmacy ID and date returns `Right(PharmacyDailyAnalytics)`.
     - Validation: empty pharmacy ID returns `Left(AuthFailure)`.
     - Failure path: repository returns `Left(ServerFailure)`.

---

## 10. Verification & Quality Gates Reference

Every subsequent milestone implementation must verify against:
1. **Static Analysis**:
   ```bash
   /home/charles/development/flutter/bin/dart analyze --fatal-infos --fatal-warnings
   ```
   *Requirement*: 0 errors, 0 warnings, 0 infos.
2. **Unit Tests Execution**:
   ```bash
   /home/charles/development/flutter/bin/flutter test
   ```
   *Requirement*: 100% passing tests.
3. **Web Build Validation**:
   ```bash
   /home/charles/development/flutter/bin/flutter build web --release
   ```
   *Requirement*: Successful compilation without broken imports or `dart:io` violations.
4. **Main Screen Integrity**:
   *Requirement*: `lib/main.dart` must remain completely intact and unmodified.
