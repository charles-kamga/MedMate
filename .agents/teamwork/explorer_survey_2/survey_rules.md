# Afya Santé (MedMate) — Règles Métier & Contraintes Architecturales du Domaine Pure Dart

> **Auteur** : Explorer Survey 2  
> **Date** : 2026-11-09  
> **Statut** : Document de référence validé pour l'Étape 1 (Couche Domain & Tests Unitaires)  
> **Conformité** : `AGENTS.md`, `architecture.md`, `coding-standards.md`, `testing.md`, `security.md`, `ORIGINAL_REQUEST.md`

---

## 1. Contraintes Architecturales de la Couche Domaine Pure Dart

### 1.1 Principe d'Isolation & Dépendances
- **Dart Pur Uniquement** : Le dossier `lib/features/<feature>/domain/` ne doit contenir aucune dépendance externe lourde ni code lié à la plateforme.
- **Interdiction formelle des bibliothèques UI / Framework** :
  - **ZÉRO import** de `package:flutter/...` (aucun `BuildContext`, `Widget`, `Color`, `State`, etc.).
  - **ZÉRO import** de `package:supabase_flutter/...` ou de clients HTTP/WebSockets (`http`, `dio`).
  - **ZÉRO import** de `dart:io` (pour garantir la portabilité Web absolue et la compilation WASM/JS).
- **Dépendances autorisées dans le Domaine** :
  - `package:equatable/equatable.dart` : pour l'égalité structurelle par valeur des entités et value objects.
  - `package:fpdart/fpdart.dart` : pour le pattern fonctionnel `Either<Failure, T>`, `Left` et `Right`.
  - `package:medmate/core/errors/failures.dart` : pour la hiérarchie scellée des erreurs métier.
  - Types standards du SDK Dart : `String`, `int`, `double`, `bool`, `DateTime`, `Duration`, `List`, `Map`, `Set`, `Uri`.

### 1.2 Structure Interne du Domaine par Module
Chaque module sous `lib/features/<feature>/domain/` respecte le découpage vertical strict en 3 sous-dossiers :
```text
lib/features/<feature>/domain/
├── entities/       # Modèles métier immuables étendant Equatable
├── repositories/   # Interfaces abstraites (contrats) définissant les méthodes métier
└── usecases/       # Cas d'utilisation métier unitaires (Single Responsibility)
```

### 1.3 Typage Strict & Règle du Zéro `dynamic`
- **Interdiction absolue** de `dynamic`, `Object?` non casté ou collections lâches comme `Map<String, dynamic>` dans le domaine.
- Tous les types de retour, paramètres, collections et champs d'entités doivent être explicitement annotés :
  - Ex: `final List<BasketItem> items;` (et non `List<dynamic>`).
  - Ex: `Future<Either<Failure, Reservation>> call(...)` (et non `Future<dynamic>`).
- Validation à la frontière : les DTOs JSON sont confinés dans `data/models/` et traduits en entités typées avant d'atteindre le domaine.

### 1.4 Immuabilité & Égalité par Valeur
- Toutes les entités sont des classes immuables dont l'ensemble des attributs est marqué `final`.
- Chaque entité étend `Equatable` et surcharge `List<Object?> get props` en énumérant exhaustivement tous ses champs.
- Mutation d'état interdite : toute modification d'entité s'effectue via une méthode `.copyWith(...)` retournant une nouvelle instance.

### 1.5 Pattern Fonctionnel `Either<Failure, T>`
- Toutes les opérations asynchrones susceptibles d'échouer retournent `Future<Either<Failure, T>>`.
- Les UseCases capturent les résultats des Repositories sans laisser propager d'exceptions non gérées.
- Les erreurs dérivent de la classe scellée `Failure` (`core/errors/failures.dart`) :
  - `NetworkFailure` : coupures et timeouts réseau.
  - `ServerFailure` : anomalies serveur ou backend Supabase.
  - `StorageFailure` / `CacheFailure` : soucis de persistance locale.
  - `LocationFailure` : indisponibilité ou refus GPS.
  - `AuthFailure` : échecs de session ou droits insuffisants.
  - `NotFoundFailure` : ressource absente.
  - `InsufficientStockFailure` : rupture de stock en officine.
  - `ReservationFailure` : conflit d'idempotence, TTL expiré ou validation OTP échouée.

### 1.6 Standard de Conception des UseCases
- Chaque `UseCase` isole un traitement métier unitaire et implémente la méthode `call(...)`.
- Injection des dépendances par constructeur (reçoit l'interface abstraite du Repository).
- Testabilité unitaire pure avec `mocktail` sans nécessité de `flutter_test` UI ni d'émulateur.

---

## 2. Invariants Métier d'Afya Santé (MedMate)

### 2.1 Repères Urbains & Topographie de Yaoundé (PostGIS / OSM)
- **Rejet de la distance euclidienne naïve** : En raison du relief vallonné de Yaoundé (« la ville aux sept collines ») et de son maillage viaire discontinu, la distance à vol d'oiseau ne reflète pas l'accessibilité réelle.
- **Référentiel des Quartiers de Yaoundé** (spécifié dans `AGENTS.md` et `yaounde_landmarks.dart`) :
  - **Bastos** (Yaoundé 1er — résidentiel, ambassades)
  - **Mokolo** (Yaoundé 2e — pôle commercial dense, marché)
  - **Tsinga** (Yaoundé 2e — zone administrative et d'habitation)
  - **Biyem-Assi** (Yaoundé 6e — quartier populaire très dense, axe Acacia)
  - **Mendong** (Yaoundé 6e — pôle résidentiel, Camp SIC, Simbock)
  - **Ngoa-Ekellé** (Yaoundé 3e — campus universitaire, CHU)
  - **Nsam** (Yaoundé 3e — axe Sud sortie Mbalmayo)
  - **Essos** (Yaoundé 5e — pôle hospitalier CNPS, avenue Germaine)
  - **Omnisports** (Yaoundé 5e — esplanade du stade Ahmadou Ahidjo, Mfandena)
  - *(Quartiers complémentaires référencés : Poste Centrale, Nlongkak, Obili)*
- **Référentiel des Carrefours & Points de Repère Remarquables** :
  - **Carrefour Warda** (Bastos / Centre, face au Bois Sainte-Anastasie)
  - **Carrefour Obili** (Chapelle Obili, jonction Ngoa-Ekellé et Université de Yaoundé I)
  - **Carrefour Nlongkak** (Rond-point vers Dragages, Bastos et Etoa-Meki)
  - **Carrefour Régie** (Axe Bastos / Yaoundé 1er)
  - **Poste Centrale** (Rond-point central, cœur administratif et kilométrique zéro)
  - **Carrefour EMIA** (École Militaire Interarmées, proximité CHU de Yaoundé)
  - **Carrefour MEEC** (Tsinga, axe Palais des Congrès)
  - *(Repères complémentaires dans `YaoundeLandmarks.list` : Marché Mokolo, Carrefour Acacia, Entrée Simbock/Mendong, Carrefour Nsam, Carrefour Essos)*
- **Comportement métier** :
  - Si le GPS est désactivé ou refusé par le navigateur/OS, le système bascule sur la sélection explicite d'un Quartier ou Carrefour de repère.
  - La recherche spatiale s'effectue en cascade : filtrage par secteur/quartier ou carrefour mitoyen, puis tri par proximité et disponibilité.

### 2.2 Politique Zéro Prix Affiché (Tarification au Comptoir)
- **Principe inviolable** : L'entité `Medication` ne contient **AUCUN champ de prix** (`price`, `prix`, `cout`, `tarif` sont strictement proscrits).
- **Justification réglementaire et déontologique** :
  - Au Cameroun, la délivrance du médicament en officine relève de l'acte pharmaceutique sous contrôle du pharmacien.
  - Le patient ne consulte pas un catalogue marchand. Afya Santé facilite la localisation et la disponibilité.
- **Où vit le prix ?**
  - Le prix unitaire et le montant total existent **EXCLUSIVEMENT** dans les offres formulées par le pharmacien en réponse à une demande flash :
    - `OfferItemResponse.prixUnitaireCommunicParPharmacien` (double).
    - `PharmacyOffer.montantTotalPropose` (double).
    - `CounterQuoteSubmission` (saisie au comptoir par le pharmacien).

### 2.3 Neutralité Déontologique ONPC & Algorithme Round-Robin
- **Cadre légal** : Loi camerounaise n° 90-035 du 10 août 1990 (exercice de la profession de pharmacien) et Code de déontologie de l'Ordre National des Pharmaciens du Cameroun (ONPC) :
  - Interdiction stricte de tout compérage, rabattage ou entente commerciale.
  - Respect scrupuleux du libre choix du patient.
  - Interdiction absolue de tout référencement payant, sponsoring, badge publicitaire ou mise en avant rémunérée.
- **Algorithme d'escalade par vagues (Round-Robin équitable)** :
  - Lorsqu'une demande de disponibilité (`FlashRequest`) est émise :
    - Elle est notifiée aux officines éligibles par **vagues de 2 pharmacies partenaires toutes les 2 minutes**.
    - La sélection respecte une rotation équitable (*fair Round-Robin*) sans favoritisme financier.
    - L'entité `FlashRequest` modélise explicitement :
      - `vagueActuelle` (int, commence à 1).
      - `pharmaciesNotifieesIds` (liste ordonnée des officines ayant reçu la vague).
      - `offresRecues` (liste des propositions transmises par les pharmaciens).
      - `expiresAt` (durée de validité de la recherche).

### 2.4 Réservation Flash, Code OTP à 6 Chiffres & TTL de 2 Heures
- **Code de retrait sécurisé** :
  - L'entité `Reservation` contient `codeRetraitOtp6Chiffres` (chaîne de 6 caractères numériques).
  - Validation formelle : doit vérifier l'expression régulière `r'^\d{6}$'`.
  - La vérification de ce code au comptoir par le pharmacien (`ValidatePickupOtpUseCase` / `ConfirmReservationOtpUseCase`) valide définitivement la délivrance.
- **Durée de Validité (TTL 2 Heures)** :
  - La réservation est éphémère : durée maximale de **2 heures** (`AppConfig.reservationTtl = Duration(hours: 2)`).
  - Au-delà de ce délai (`now.isAfter(expiresAt)`), la réservation bascule en statut `expired` et les produits sont remis en stock libre.
- **Conformité Loi n° 2024/017 (ANTIC / APDP Cameroun)** :
  - Protection des données à caractère personnel de santé : minimisation des données, sessions patients éphémères (`PatientSession`), aucune trace médicale en clair sur le navigateur, purge des réservations expirées.

### 2.5 Permanence de Garde & Homologation ONPC
- **Officines de garde** :
  - L'entité `DutySchedule` associe une pharmacie à un créneau de garde (`dateGarde`, `heureDebut`, `heureFin`).
  - Champ d'homologation obligatoire : `verifieParOnpc` (bool).
  - Seules les gardes officiellement arrêtées et publiées par l'Ordre National des Pharmaciens du Cameroun sont attestées comme vérifiées.

---

## 3. Matrice Exhaustive des Modules du Domaine Pure Dart

### Module 1 : Authentification (`lib/features/auth/domain/`)
| Élément | Nom | Rôle & Attributs |
| :--- | :--- | :--- |
| **Entité** | `PatientSession` | Session éphémère du patient (`id`, `estAnonyme`, `telephone`, `createdAt`, `expiresAt`). |
| **Entité** | `PharmacistProfile` | Profil vérifié du pharmacien (`userId`, `pharmacyId`, `licenceOnpc`, `role`, `nom`, `prenom`). |
| **Entité** | `UserSession` | Wrapper d'état de session (`id`, `patientSession`, `pharmacistProfile`, `estConnecte`). |
| **Repository** | `AuthRepository` | Contrat abstrait : `getCurrentSession()`, `signInPharmacist(email, password)`, `signOut()`. |
| **UseCase** | `GetCurrentSessionUseCase` | Récupère la session courante (active ou éphémère). |
| **UseCase** | `SignInPharmacistUseCase` | Authentification du pharmacien d'officine au comptoir. |
| **UseCase** | `SignOutUseCase` | Déconnexion sécurisée et révocation de session. |

### Module 2 : Recherche de Pharmacies & Médicaments (`lib/features/pharmacy_search/domain/`)
| Élément | Nom | Rôle & Attributs |
| :--- | :--- | :--- |
| **Entité** | `Medication` | Médicament sans prix (`id`, `codeNational`, `nomCommercial`, `dci`, `forme`, `dosage`, `necessiteOrdonnance`). **AUCUN PRIX**. |
| **Entité** | `Pharmacy` | Officine physique (`id`, `nom`, `licenceOnpc`, `quartier`, `carrefourRepere`, `latitude`, `longitude`, `telephoneGarde`, `estOuverte`, `estDeGarde`, `estPartenaire`, `distanceMetres`). |
| **Repository** | `PharmacySearchRepository` | Contrat abstrait : `searchMedications(query)`, `searchNearbyPharmacies(quartier, carrefour, lat, lon, rayon)`, `getPharmacyById(id)`. |
| **UseCase** | `SearchMedicationsUseCase` | Recherche textuelle tolérante aux fautes dans le référentiel national. |
| **UseCase** | `SearchNearbyPharmaciesUseCase` | Filtrage géographique et par repère urbain (quartier / carrefour) de Yaoundé. |

### Module 3 : Réservation Flash & Dispatch Équitable (`lib/features/reservation/domain/`)
| Élément | Nom | Rôle & Attributs |
| :--- | :--- | :--- |
| **Enum** | `ItemAvailabilityStatus` | Statuts de disponibilité : `available`, `unavailable`, `conditional`. |
| **Entité** | `BasketItem` | Ligne de panier (`medication`, `quantite`, `precision`). |
| **Entité** | `OfferItemResponse` | Ligne de proposition officine (`medicationId`, `status`, `prixUnitaireCommunicParPharmacien`, `conditionDelivrance`, `commentaire`). |
| **Entité** | `PharmacyOffer` | Offre comptoir (`id`, `demandeId`, `pharmacyId`, `pharmacyNom`, `quartier`, `distanceMetres`, `items`, `montantTotalPropose`, `livraisonDisponible`, `fraisLivraison`, `delaiLivraisonMinutes`, `createdAt`). |
| **Entité** | `FlashRequest` | Demande flash du patient (`id`, `clientRequestId`, `items`, `quartierOuCarrefour`, `statut`, `vagueActuelle`, `pharmaciesNotifieesIds`, `offresRecues`, `createdAt`, `expiresAt`). |
| **Entité** | `Reservation` | Réservation confirmée (`id`, `clientReservationId`, `demandeId`, `offreId`, `pharmacyId`, `codeRetraitOtp6Chiffres`, `statut`, `createdAt`, `expiresAt` — TTL 2h). |
| **Repository** | `ReservationRepository` | Contrat abstrait : `submitFlashRequest`, `escalateDispatchWave`, `selectPharmacyOffer`, `confirmReservationOtp`. |
| **UseCase** | `SubmitFlashRequestUseCase` | Soumission de la demande flash avec validation de panier non vide. |
| **UseCase** | `EscalateDispatchWaveUseCase` | Escalade par vagues de 2 officines partenaires toutes les 2 minutes (Round-Robin ONPC). |
| **UseCase** | `SelectPharmacyOfferUseCase` | Sélection d'une proposition par le patient et génération de la réservation avec OTP. |
| **UseCase** | `ConfirmReservationOtpUseCase` | Validation du code OTP à 6 chiffres pour retrait au comptoir. |

### Module 4 : Pharmacie de Garde (`lib/features/duty_pharmacy/domain/`)
| Élément | Nom | Rôle & Attributs |
| :--- | :--- | :--- |
| **Entité** | `DutySchedule` | Tour de garde (`id`, `pharmacy`, `dateGarde`, `heureDebut`, `heureFin`, `verifieParOnpc`). |
| **Repository** | `DutyPharmacyRepository` | Contrat abstrait : `getDutyPharmaciesByQuartier(quartier, date)`, `getAllActiveDutyPharmacies(date)`. |
| **UseCase** | `GetDutyPharmaciesByQuartierUseCase` | Liste les pharmacies de garde d'un quartier de Yaoundé pour un créneau donné. |

### Module 5 : Portail Pharmacien (`lib/features/pharmacist_portal/domain/`)
| Élément | Nom | Rôle & Attributs |
| :--- | :--- | :--- |
| **Entité** | `IncomingDemand` | Demande patient reçue au comptoir (`id`, `flashRequestId`, `items`, `quartierPatient`, `createdAt`, `expiresAt`). |
| **Entité** | `CounterQuoteSubmission` | Offre formulée au comptoir avec saisie manuelle des prix (`flashRequestId`, `pharmacyId`, `items`, `montantTotal`, `livraisonDisponible`, `fraisLivraison`, `delaiLivraisonMinutes`). |
| **Entité** | `PharmacyDailyAnalytics` | Statistiques officinales anonymisées conformes Loi n° 2024/017 (`pharmacyId`, `date`, `totalDemandesRecues`, `totalOffresSoumises`, `totalReservationsConfirmees`, `tempsMoyenReponseSecondes`). |
| **Repository** | `PharmacistPortalRepository` | Contrat abstrait : `getIncomingDemands`, `submitCounterQuote`, `validatePickupOtp`, `getPharmacyAnalytics`. |
| **UseCase** | `SubmitCounterQuoteUseCase` | Envoi d'une cotation comptoir avec statut des articles et prix unitaire. |
| **UseCase** | `ValidatePickupOtpUseCase` | Validation par le pharmacien du code OTP à 6 chiffres présenté par le patient. |
| **UseCase** | `GetPharmacyAnalyticsUseCase` | Consultation du tableau de bord de réactivité et d'impact officinal. |

---

## 4. Spécifications & Exigences pour la Suite de Tests Unitaires (`test/features/`)

1. **Couverture des UseCases (100 %)** :
   - Chaque `UseCase` doit disposer de tests couvrant :
     - Le flux nominal (retour `Right(data)`).
     - Les échecs métier et techniques (retour `Left(Failure)` : ex. `NotFoundFailure`, `NetworkFailure`, `ReservationFailure`).
2. **Vérification des Invariants Métier par Test Dédié** :
   - **Absence de prix dans `Medication`** : test statique ou d'instanciation prouvant l'absence de champ prix.
   - **Présence du prix exclusivement dans l'offre comptoir** : tests validant `OfferItemResponse` et `PharmacyOffer`.
   - **Validation OTP 6 Chiffres** : rejet d'un OTP de 5 chiffres, 7 chiffres ou contenant des lettres/espaces.
   - **Durée TTL de 2 Heures** : rejet d'une tentative de réservation ou de retrait expirée (`expiresAt < now`).
   - **Escalade Round-Robin** : test unitaire simulant le passage de vague incrémentant `vagueActuelle` et ajoutant 2 officines à `pharmaciesNotifieesIds`.
   - **Panier non vide** : rejet de toute demande flash avec une liste d'articles vide.
3. **Immuabilité & Égalité Structurelle** :
   - Deux instances d'entités avec les mêmes paramètres doivent être égales (`expect(entityA, equals(entityB))`).
   - `.props` doit être exhaustif sur toutes les entités.
4. **Outillage de Test** :
   - `package:mocktail/mocktail.dart` pour les mocks des Repositories abstraits.
   - `package:fpdart/fpdart.dart` pour la manipulation de `Left` et `Right`.
   - Aucun besoin d'initialiser Supabase ou Flutter Widgets pour les tests domain.
