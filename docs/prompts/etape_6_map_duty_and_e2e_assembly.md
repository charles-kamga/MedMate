# Prompt Étape 6 (Finale) : Carte OpenStreetMap, Pharmacies de Garde & Assemblage E2E (`main.dart`)

Vous êtes l'équipe d'ingénierie et d'architecture Flutter / Dart en charge de l'implémentation de l'**Étape 6 (Finale)** du projet Afya Santé (`package:medmate`).

---

## ☁️ Environnement Cloud & Protocole de Synchronisation Git OBLIGATOIRE

> [!IMPORTANT]
> **Vous opérez dans un environnement Cloud distant.** Pour garantir la traçabilité et permettre le rapatriement sans conflit sur la machine locale du développeur :
>
> 1. **Démarrage (Pré-requis)** :
>    - Avant de modifier ou d'ajouter le moindre fichier, synchroniser impérativement le dépôt distant :
>      ```bash
>      git fetch origin
>      git checkout -b feat/etape-6-map-duty-e2e origin/feat/etape-5-realtime-dispatch
>      ```
>    - S'assurer que la branche part bien de la dernière version certifiée de l'Étape 5 (`feat/etape-5-realtime-dispatch`, commit `32950b2` ou ultérieur).
>
> 2. **Finalisation & Livraison Distante** :
>    - Une fois l'implémentation terminée et validée par toutes les quality gates :
>      ```bash
>      git status
>      git add .
>      git commit -m "feat(map-duty-e2e): etape 6 - refonte clean architecture gardes/carte OSM (<400L) et assemblage E2E main.dart"
>      git push origin feat/etape-6-map-duty-e2e
>      ```
>    - Fournir explicitement à la fin de votre rapport les commandes exactes que le développeur doit exécuter sur sa machine locale pour récupérer votre travail :
>      ```bash
>      git fetch origin
>      git checkout feat/etape-6-map-duty-e2e
>      git pull origin feat/etape-6-map-duty-e2e
>      ```

---

## 🛡️ Invariants du Projet & Garde-fous Architecturaux

1. **Règle stricte des `< 400 lignes` par fichier Dart** :
   - Aucun fichier créé ou modifié dans le périmètre de l'Étape 6 ne doit dépasser **400 lignes**.
   - **Cibles prioritaires de refonte modulaire** (actuellement au-dessus de 400 lignes) :
     * `lib/features/duty_pharmacy/presentation/views/duty_pharmacy_screen.dart` (actuellement `571` lignes $\rightarrow$ doit passer strictement $< 400$ lignes).
     * `lib/features/pharmacy_search/presentation/views/pharmacy_map_view.dart` (actuellement `507` lignes $\rightarrow$ doit passer strictement $< 400$ lignes).
     * `lib/features/pharmacy_search/presentation/views/medication_catalog_view.dart` (actuellement `422` lignes $\rightarrow$ doit passer strictement $< 400$ lignes).
     * `lib/features/home/presentation/views/main_navigation_screen.dart` (actuellement `374` lignes $\rightarrow$ maintenir strictement $< 400$ lignes).
     * `lib/core/navigation/afya_app_shell.dart` (actuellement `320` lignes $\rightarrow$ maintenir strictement $< 400$ lignes).

2. **Réutilisation stricte des entités du domaine (Zéro Duplication)** :
   - Réutiliser les entités existantes :
     * `package:medmate/features/pharmacy_search/domain/entities/pharmacy.dart`
     * `package:medmate/features/pharmacy_search/domain/entities/medication.dart`
     * `package:medmate/features/flash_order/domain/entities/flash_order.dart`
     * `package:medmate/features/flash_order/domain/entities/pharmacy_offer.dart`
     * `package:medmate/core/constants/yaounde_landmarks.dart`
   - Pour `duty_pharmacy/`, structurer une Clean Architecture propre (`domain/entities/`, `domain/repositories/`, `domain/usecases/`, `data/repositories/`, `presentation/controllers/duty_pharmacy_cubit.dart`, `presentation/widgets/`) tout en préservant l'export ou la compatibilité de `DutyPharmacyItem` et `DutyPharmacyScreen` pour ne casser aucun import ni test existant.

3. **Souveraineté Cartographique OpenStreetMap & Compatibilité Tests** :
   - **Interdiction formelle** d'utiliser Google Maps ou Mapbox (ni package, ni URL `google.com/maps`).
   - Utiliser exclusivement `flutter_map`, `latlong2` et `AppConfig.buildOsmSearchUrl(...)` pour les itinéraires externes.
   - Respecter systématiquement le flag `enableNetworkTiles` (`false` dans les tests de widgets pour éviter toute requête HTTP externe en test).
   - Aucun import `dart:io` dans `lib/`.

4. **Politique Tarifaire & Déontologie ONPC (Zéro Prix Catalogue Patient)** :
   - Dans `MedicationCatalogView` et `DutyPharmacyScreen`, aucun prix fixe en FCFA ne doit être affiché au patient avant devis officine (remplacer tout affichage de prix catalogue côté patient par la mention réglementaire *« Tarif au comptoir »* ou *« Selon devis officine »*, tout en gardant la propriété interne de l'entité intacte pour les tests unitaires existants).
   - Distinguer visuellement sur la carte OpenStreetMap et dans les fiches officines :
     * **Officines Partenaires Afya Santé** (éligibles aux demandes Flash en vagues et à la réservation OTP).
     * **Officines Non-Partenaires / Référencées** (consultation des horaires de garde, appel téléphonique direct et itinéraire OSM uniquement).

5. **Non-Régression Absolue sur `test/widget_test.dart` et les 169 tests existants** :
   - Le fichier `test/widget_test.dart` vérifie des libellés précis dans `DutyPharmacyScreen` :
     * `'Pharmacies de garde'`
     * `'Trouvez une pharmacie de garde près de vous'`
     * `'Programme de garde'`
     * `'Plus proches'` et `'Toutes les gardes'`
     * `'Appeler'` et `'Itinéraire'`
     * Présence d'un `TextField` dans l'onglet `'Toutes les gardes'` et d'un bouton retour (`BackButton` ou `Icons.arrow_back`).
   - **Tous ces libellés et comportements doivent rester 100 % intacts** après le découpage modulaire de `DutyPharmacyScreen`.

---

## 🎯 Périmètre Fonctionnel de l'Étape 6

### 1. Refonte Clean Architecture de `lib/features/duty_pharmacy/` (`< 400 lignes/fichier`)
- **Couche Domain & Data** :
  * Créer `DutyPharmacyRepository` et `DutyPharmacyRepositoryImpl` (avec les données officielles de garde de Yaoundé — Poste Centrale, Warda, Bastos, Melen/CHU, Biyem-Assi, Essos, Obili, Nlongkak — et des grandes villes camerounaises).
  * Créer `GetDutyPharmaciesUseCase`.
- **Couche Presentation (`DutyPharmacyCubit` + Widgets granulaires)** :
  * Créer `DutyPharmacyCubit` et `DutyPharmacyState` (filtrage par ville, par proximité / toutes les gardes, et recherche textuelle par nom ou quartier/carrefour).
  * Extraire les sous-widgets dans `lib/features/duty_pharmacy/presentation/widgets/` :
    - `duty_schedule_header_card.dart` (bandeau `'Programme de garde'`, horaires 20h00–08h00 et sélecteur de ville).
    - `duty_pharmacy_card.dart` (carte d'officine de garde avec badges de garde 24h/24, repère urbain, boutons `'Appeler'` et `'Itinéraire'` via `AppConfig.buildOsmSearchUrl`).
  * Réduire `duty_pharmacy_screen.dart` à nettement moins de **400 lignes**.

### 2. Découpage Modulaire de `lib/features/pharmacy_search/presentation/` (`< 400 lignes/fichier`)
- **`pharmacy_map_view.dart` ($< 400$ lignes)** :
  * Extraire les composants dans `lib/features/pharmacy_search/presentation/widgets/` :
    - `yaounde_landmark_filter_bar.dart` : barre horizontale de sélection rapide des Carrefours emblématiques de Yaoundé (*Carrefour Warda, Obili, Poste Centrale, Nlongkak, Acacia, Bastos, Melen...*) qui recentre la carte OpenStreetMap.
    - `pharmacy_map_bottom_card.dart` : fiche détaillée de l'officine sélectionnée sur la carte (distinction **Officine Partenaire** vs **Officine de Garde**, horaires, responsable, appel et itinéraire OSM).
- **`medication_catalog_view.dart` ($< 400$ lignes)** :
  * Extraire la carte d'élément médicament et la barre de filtres par classe thérapeutique dans `lib/features/pharmacy_search/presentation/widgets/medication_catalog_item_card.dart`.
  * S'assurer qu'aucun prix catalogue en FCFA n'est affiché en dur côté patient (afficher le badge *« Tarif au comptoir »*).
- **Intégration dans l'onglet « Gardes & Carte » de `AfyaAppShell`** :
  * Permettre à l'utilisateur dans l'onglet 2 (`Gardes & Carte`) de basculer proprement entre la **Carte interactive OpenStreetMap** et la **Liste des Pharmacies de Garde**, sans aucun `RenderFlex overflow` sur mobile (`390x844`) ni desktop (`1280x800`).

### 3. Assemblage Général de Bout en Bout (E2E) dans `lib/main.dart` et `main_navigation_screen.dart`
- **Correction de l'aiguillage du Portail Pharmacien dans `main_navigation_screen.dart`** :
  * Actuellement, `lib/features/home/presentation/views/main_navigation_screen.dart` importe encore l'ancien écran `package:medmate/features/flash_order/presentation/views/pharmacist_portal_view.dart`.
  * Le remplacer par le nouveau portail officiel de l'Étape 4 : `package:medmate/features/pharmacist_portal/presentation/views/pharmacist_portal_view.dart`, afin que le clic sur **« Portail Officine Partenaire (Pharmacien) »** depuis le Profil ouvre le vrai Portail Comptoir (Inbox par vague, Devis 3 statuts ONPC, Pavé numérique OTP à 6 chiffres).
- **Pont Temps Réel / Mémoire Partagée entre Patient et Pharmacien pour `flutter run`** :
  * Lorsqu'on lance l'application en démo locale (`flutter run` sans backend externe), créer ou relier un pont réactif partagé entre `ReservationRepositoryImpl` / `PharmacistPortalRepositoryImpl` (ou via `RealtimeDispatchRepository`) injecté dans `lib/main.dart` :
    1. Conserver les commandes de démonstration initiales (`ORD-YAO-101` et `ORD-YAO-102` avec l'OTP `482910`) dans le portail pharmacien.
    2. Lorsqu'un **Patient** soumet une nouvelle demande Flash dans `PatientFlashFlowView`, cette demande est également enregistrée et diffusée dans le référentiel du **Pharmacien** (`PharmacistCounterCubit`).
    3. Lorsqu'un **Pharmacien** soumet un devis 3 statuts ONPC ou valide un code OTP dans `PharmacistPortalView`, l'état de la commande est mis à jour côté **Patient** (`FlashReservationCubit`).
  * Préserver tous les paramètres optionnels du constructeur `MedMateApp` (`enableNetworkTiles`, `pharmacyRepository`, `reservationRepository`, `pharmacistPortalRepository`, `useAfyaAppShell`) pour garantir 100 % de rétrocompatibilité avec les tests existants.

---

## 🧪 Suite de Tests Automatisés & Quality Gates Requises

1. **Nouveaux Tests Unitaires & Widgets (Étape 6)** :
   * `test/features/duty_pharmacy/` :
     - Tests unitaires de `DutyPharmacyCubit` (chargement, filtrage par ville, filtrage par recherche textuelle/quartier).
     - Tests de widgets multi-viewport (`390x844` et `1280x800`) de `DutyPharmacyScreen` et `DutyPharmacyCard` sans overflow.
   * `test/features/pharmacy_search/presentation/views/pharmacy_map_view_test.dart` :
     - Rendu avec `enableNetworkTiles: false`, sélection d'un carrefour de Yaoundé, sélection d'une officine partenaire vs non-partenaire sans overflow.
   * `test/core/navigation/e2e_patient_pharmacist_sync_test.dart` :
     - Test d'intégration vérifiant que le pont partagé dans `MedMateApp` synchronise bien une demande créée côté Patient avec l'Inbox côté Pharmacien.
2. **Vérification de la taille des fichiers** :
   * Vérifier que `duty_pharmacy_screen.dart`, `pharmacy_map_view.dart`, `medication_catalog_view.dart`, `main_navigation_screen.dart` et `afya_app_shell.dart` font tous strictement **moins de 400 lignes** (`wc -l`).
3. **Quality Gates Zéro-Tolérance** :
   * `dart analyze --fatal-infos --fatal-warnings lib/ test/` $\rightarrow$ **0 issue** (`No issues found!`).
   * `flutter test` $\rightarrow$ **100 % des tests au vert** (les 169 tests existants + les nouveaux tests de l'Étape 6).
