# Prompt Étape 6 (Finale — Instance Locale) : Carte OpenStreetMap, Pharmacies de Garde & Assemblage E2E (`main.dart`)

Vous êtes l'équipe d'ingénierie et d'architecture Flutter / Dart en charge de l'implémentation de l'**Étape 6 (Finale)** du projet Afya Santé (`package:medmate`), directement sur la machine **locale** (`/home/charles/Documents/Work/Me/MedMate`).

---

## 💻 Environnement Local & Protocole Git OBLIGATOIRE

> [!IMPORTANT]
> **Vous opérez directement sur le dépôt local `/home/charles/Documents/Work/Me/MedMate` (SDK Flutter : `/home/charles/development/flutter/bin/flutter`).**
>
> 1. **Démarrage (Initialisation de la branche locale)** :
>    - Vérifier que vous partez de la branche `feat/etape-5-realtime-dispatch` (commit `6258069` ou `32950b2`) et créer la branche dédiée :
>      ```bash
>      git status
>      git checkout -B feat/etape-6-map-duty-e2e
>      ```
>
> 2. **Finalisation, Commit & Push** :
>    - Une fois toutes les quality gates validées à 100 % :
>      ```bash
>      git status
>      git add .
>      git commit -m "feat(map-duty-e2e): etape 6 - refonte clean architecture gardes/carte OSM (<400L) et assemblage E2E main.dart"
>      git push -u origin feat/etape-6-map-duty-e2e
>      ```

---

## 🔍 Diagnostic Exact de l'État Actuel du Code (Points à Traiter)

1. **Fichiers dépassant la limite stricte des `< 400 lignes`** :
   - `lib/features/duty_pharmacy/presentation/views/duty_pharmacy_screen.dart` : **571 lignes** (monolithique, données en dur dans le `State`, zéro `Cubit`/`Repository`).
   - `lib/features/pharmacy_search/presentation/views/pharmacy_map_view.dart` : **507 lignes** (doit être découpé en sous-widgets `< 400 lignes`).
   - `lib/features/pharmacy_search/presentation/views/medication_catalog_view.dart` : **422 lignes** (doit être découpé en sous-widgets `< 400 lignes`).
   - `lib/features/home/presentation/views/main_navigation_screen.dart` (**374 lignes**) et `lib/core/navigation/afya_app_shell.dart` (**320 lignes**) : à maintenir strictement `< 400 lignes`.

2. **Violations résiduelles de souveraineté OpenStreetMap à éliminer** :
   - `lib/features/duty_pharmacy/presentation/views/duty_pharmacy_screen.dart:139` contient encore `https://www.google.com/maps/search/?api=1&query=$query`.
   - `lib/features/patient_flow/presentation/views/patient_home_flow_view.dart:142` contient encore `https://www.google.com/maps/search/?api=1&query=$query`.
   - **Action requise** : remplacer ces deux occurrences par `AppConfig.buildOsmSearchUrl(...)` pour que `! grep -rnE "google\.com/maps|maps\.googleapis|google_maps_flutter|mapbox" lib/` retourne **0 occurrence**.

3. **Aiguillage et Pont Réactif E2E dans `main.dart` & `main_navigation_screen.dart`** :
   - Dans `lib/features/home/presentation/views/main_navigation_screen.dart` (ligne 9), remplacer l'import obsolète `package:medmate/features/flash_order/presentation/views/pharmacist_portal_view.dart` par le portail officiel de l'Étape 4 : `package:medmate/features/pharmacist_portal/presentation/views/pharmacist_portal_view.dart`.
   - Dans `lib/main.dart`, `ReservationRepositoryImpl` (Patient) et `PharmacistPortalRepositoryImpl` (Pharmacien) utilisent actuellement deux `Map<String, FlashOrder>` isolées. Il faut créer un pont mémoire réactif partagé (`SharedInMemoryDispatchBridge` implémentant `ReservationRepository`, `PharmacistPortalRepository` et `RealtimeDispatchRepository`) injecté par défaut dans `MedMateApp` pour que toute action Patient $\leftrightarrow$ Pharmacien se synchronise en direct lors d'un `flutter run`.

---

## 🛡️ Invariants du Projet & Garde-fous Architecturaux

1. **Réutilisation stricte des entités du domaine (Zéro Duplication)** :
   - Réutiliser `Pharmacy`, `Medication`, `FlashOrder`, `PharmacyOffer`, `BasketItem`, `Reservation` et `YaoundeLandmarks`.
   - Conserver la classe `DutyPharmacyItem` accessible (ou ré-exportée depuis `duty_pharmacy_screen.dart`) pour ne casser aucun import existant.

2. **Politique Tarifaire & Déontologie ONPC (Zéro Prix Catalogue Patient)** :
   - Dans `MedicationCatalogView` et ses sous-widgets, n'afficher **aucun prix fixe en FCFA** au patient : afficher le badge déontologique *« Tarif au comptoir »* (tout en conservant le champ interne `prixHomologueCfa` sur l'entité `Medication` pour la rétrocompatibilité des tests unitaires).
   - Sur la carte OpenStreetMap et ses fiches, distinguer clairement les **Officines Partenaires** (éligibles aux vagues Flash et à l'OTP) des **Officines de Garde Référencées** (appel direct et itinéraire OSM uniquement).

3. **Non-Régression Absolue sur `test/widget_test.dart` (et les 169 tests existants)** :
   - `test/widget_test.dart` vérifie dans `DutyPharmacyScreen` les textes exacts :
     * `'Pharmacies de garde'`
     * `'Trouvez une pharmacie de garde près de vous'`
     * `'Programme de garde'`
     * `'Plus proches'` et `'Toutes les gardes'`
     * `'Appeler'` et `'Itinéraire'`
     * Un `TextField` visible sur l'onglet `'Toutes les gardes'` et le bouton retour (`BackButton` / `Icons.arrow_back`).
   - Tous ces éléments doivent rester strictement présents et fonctionnels.

4. **Robustesse Multi-Viewport & Anti-Overflow** :
   - Utiliser `Flexible`, `Expanded` ou `Wrap` dans les en-têtes, sélecteurs de villes, barres de carrefours et cartes d'officines pour éviter tout `RenderFlex overflow`, y compris sur petit écran mobile (`320x568` et `390x844`) et sur écran comptoir (`1280x800`).

---

## 🎯 Plan d'Implémentation en 3 Chantiers

### Chantier 1 : Clean Architecture `lib/features/duty_pharmacy/` (`< 400 lignes/fichier`)
- Créer :
  * `lib/features/duty_pharmacy/domain/entities/duty_pharmacy_item.dart` (ré-exporté dans `duty_pharmacy_screen.dart`).
  * `lib/features/duty_pharmacy/domain/repositories/duty_pharmacy_repository.dart` & `domain/usecases/get_duty_pharmacies.dart`.
  * `lib/features/duty_pharmacy/data/repositories/duty_pharmacy_repository_impl.dart` (avec les officines de garde de Yaoundé, Douala, Bertoua, Bafoussam).
  * `lib/features/duty_pharmacy/presentation/controllers/duty_pharmacy_cubit.dart` & `duty_pharmacy_state.dart`.
  * `lib/features/duty_pharmacy/presentation/widgets/duty_schedule_header_card.dart` et `duty_pharmacy_card.dart` (utilisant `AppConfig.buildOsmSearchUrl`).
- Réduire `duty_pharmacy_screen.dart` à `< 260` lignes.

### Chantier 2 : Modularisation de `lib/features/pharmacy_search/presentation/` (`< 400 lignes/fichier`)
- Extraire dans `lib/features/pharmacy_search/presentation/widgets/` :
  * `yaounde_landmark_filter_bar.dart` : sélection rapide des carrefours de Yaoundé (*Warda, Obili, Poste Centrale, Nlongkak, Acacia...*).
  * `pharmacy_map_bottom_card.dart` : fiche d'officine sélectionnée sur la carte OSM.
  * `medication_catalog_item_card.dart` : carte médicament avec mention *« Tarif au comptoir »*.
- Réduire `pharmacy_map_view.dart` et `medication_catalog_view.dart` sous les **320 lignes** chacun.
- Dans l'onglet 2 (`Gardes & Carte`) de `AfyaAppShell`, permettre de basculer sans overflow entre la **Carte OpenStreetMap** et la vue **Pharmacies de Garde**.

### Chantier 3 : Pont Réactif Partagé E2E & Câblage `lib/main.dart`
- Créer `lib/features/realtime_dispatch/data/repositories/shared_in_memory_dispatch_bridge.dart` (`< 380` lignes) :
  * Implémente `ReservationRepository`, `PharmacistPortalRepository` et `RealtimeDispatchRepository`.
  * Pré-charge les commandes de démonstration (`ORD-YAO-101` en Vague 1 et `ORD-YAO-102` prête au retrait avec OTP `482910`).
  * Synchronise en temps réel (via `StreamController.broadcast()`) :
    - Toute nouvelle commande soumise par le Patient $\rightarrow$ apparaît immédiatement dans l'Inbox du Pharmacien (`watchPendingOrdersForPharmacy`).
    - Tout devis 3 statuts ONPC ou validation OTP soumis par le Pharmacien $\rightarrow$ met à jour immédiatement l'état côté Patient (`watchOffersForOrder`, `watchFlashOrder`).
- Brancher ce `SharedInMemoryDispatchBridge` par défaut dans `lib/main.dart` (tout en respectant les paramètres optionnels `reservationRepository` et `pharmacistPortalRepository` passés dans les tests).
- Corriger l'import de `PharmacistPortalView` dans `lib/features/home/presentation/views/main_navigation_screen.dart`.

---

## 🧪 Tests Automatisés & Quality Gates Obligatoires

1. **Tests Unitaires, Widgets & E2E à ajouter** :
   - `test/features/duty_pharmacy/` : tests du `DutyPharmacyCubit` et tests de widgets multi-viewport (`390x844` et `1280x800`) de `DutyPharmacyScreen`.
   - `test/features/pharmacy_search/presentation/views/pharmacy_map_view_test.dart` : test de `PharmacyMapView(enableNetworkTiles: false)` et de `MedicationCatalogView`.
   - `test/core/navigation/e2e_patient_pharmacist_sync_test.dart` : test vérifiant qu'une commande créée côté Patient via le pont partagé remonte instantanément côté Pharmacien, puis que le devis et la validation OTP synchronisent les deux Cubits.
2. **Commandes de Validation Finale (Zéro Tolérance)** :
   ```bash
   # 1. Zéro référence Google Maps / Mapbox
   ! grep -rnE "google\.com/maps|maps\.googleapis|google_maps_flutter|mapbox" lib/

   # 2. Vérification < 400 lignes sur tous les fichiers refondus
   wc -l lib/features/duty_pharmacy/presentation/views/duty_pharmacy_screen.dart \
         lib/features/pharmacy_search/presentation/views/pharmacy_map_view.dart \
         lib/features/pharmacy_search/presentation/views/medication_catalog_view.dart \
         lib/features/home/presentation/views/main_navigation_screen.dart \
         lib/core/navigation/afya_app_shell.dart \
         lib/main.dart

   # 3. Analyse statique stricte (0 issue)
   /home/charles/development/flutter/bin/dart analyze --fatal-infos --fatal-warnings lib/ test/

   # 4. Suite complète de tests (100% au vert)
   /home/charles/development/flutter/bin/flutter test
   ```
