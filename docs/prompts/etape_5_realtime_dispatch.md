# Prompt Étape 5 : Synchronisation Temps Réel Supabase & Dispatching Géospatial PostGIS

Vous êtes l'équipe d'ingénierie et d'architecture Flutter / Dart en charge de l'implémentation de l'Étape 5 du projet Afya Santé (`package:medmate`).

---

## ☁️ Environnement Cloud & Protocole de Synchronisation Git OBLIGATOIRE

> [!IMPORTANT]
> **Vous opérez dans un environnement Cloud distant.** Pour garantir la traçabilité et permettre le rapatriement sans conflit sur la machine locale du développeur :
>
> 1. **Démarrage (Pré-requis)** :
>    - Avant de modifier ou d'ajouter le moindre fichier, synchroniser impérativement le dépôt distant :
>      ```bash
>      git fetch origin
>      git checkout -b feat/etape-5-realtime-dispatch origin/feat/etape-4-pharmacist-portal
>      ```
>    - S'assurer que la branche part bien de la dernière version stable et consolidée de l'Étape 4 (`feat/etape-4-pharmacist-portal`).
>
> 2. **Finalisation & Livraison Distante** :
>    - Une fois l'implémentation terminée et validée par les quality gates :
>      ```bash
>      git status
>      git add .
>      git commit -m "feat(realtime-dispatch): etape 5 - supabase realtime, websocket streams, postgis dispatch et fallbacks offline"
>      git push origin feat/etape-5-realtime-dispatch
>      ```
>    - Fournir explicitement à la fin de votre rapport les commandes exactes que le développeur doit exécuter sur sa machine locale pour récupérer votre travail :
>      ```bash
>      git fetch origin
>      git checkout feat/etape-5-realtime-dispatch
>      git pull origin feat/etape-5-realtime-dispatch
>      ```

---

## 🛡️ Invariants du Projet & Garde-fous Architecturaux

1. **Réutilisation stricte des entités du domaine (Zéro Duplication)** :
   - Ne **JAMAIS** recréer ni dupliquer d'entités déjà existantes.
   - Réutiliser impérativement les modèles et contrats existants :
     * `package:medmate/features/flash_order/domain/entities/flash_order.dart`
     * `package:medmate/features/flash_order/domain/entities/pharmacy_offer.dart`
     * `package:medmate/features/flash_order/domain/entities/basket_item.dart`
     * `package:medmate/features/pharmacy_search/domain/entities/medication.dart`
     * `package:medmate/features/pharmacy_search/domain/entities/pharmacy.dart`
     * `package:medmate/features/pharmacy_search/domain/entities/reservation.dart`
     * `package:medmate/features/reservation/domain/repositories/reservation_repository.dart`
     * `package:medmate/features/pharmacist_portal/domain/repositories/pharmacist_portal_repository.dart`
   - Si de nouvelles abstractions réseau ou de flux temps réel sont nécessaires, implémenter des datasources/repositories qui respectent ces interfaces existantes.

2. **Politique Tarifaire & Éthique ONPC (Zéro Prix Catalogue)** :
   - Aucun prix ne doit être affiché avant la réponse officielle de l'officine.
   - Les offres officines restent soumises aux 3 statuts stricts de l'ONPC :
     1. `fullyAvailable` (Disponible immédiatement au comptoir avec tarif officiel).
     2. `conditional` (Disponible avec réserve : ordonnance requise, dosage adapté).
     3. `unavailable` (Rupture ou non disponible).
   - Les frais mototaxi éventuels doivent être explicitement distincts du coût des médicaments.

3. **Cartographie et Repères Urbains de Yaoundé (PostGIS)** :
   - Les requêtes spatiales et le dispatching par vague s'appuient sur les carrefours emblématiques (*Carrefour Warda, Carrefour Obili, Poste Centrale, Nlongkak, Acacia...*) et les quartiers (*Bastos, Mokolo, Biyem-Assi, Essos, Tsinga...*).
   - Filtrage spatial par échelons topologiques (isochrone / réseau routier) et non par simple distance euclidienne à vol d'oiseau.

4. **Résilience Réseau Intermittent (Mode Dégradé 3G/EDGE)** :
   - Yaoundé subit des instabilités régulières de connectivité mobile.
   - L'implémentation doit intégrer un fallback automatique en polling adaptatif (`Stream` résilient ou reconnexion avec backoff exponentiel) si le canal WebSocket Supabase Realtime est coupé.
   - Aucun crash en cas de perte de signal ; affichage d'un indicateur de synchronisation non bloquant.

5. **Découpage Granulaire Stricte (< 400 lignes par fichier)** :
   - Aucun fichier Dart ne doit dépasser 400 lignes.
   - Séparer nettement les datasources distants (Supabase WebSocket / REST), les mappers DTO, les contrôleurs de connectivité et les composants d'état UI.

---

## 🎯 Périmètre Fonctionnel de l'Étape 5

### 1. Couche Données & Synchronisation Temps Réel (`lib/features/realtime_dispatch/` ou extension des datasources existants)
- **Supabase Realtime Stream Provider / Data Source** :
  * Écoute en temps réel des changements sur les tables `flash_orders` et `pharmacy_quotes`.
  * Filtre par vague active (`wave_number`) et périmètre géographique (officines ciblées par la vague).
  * Diffusion en flux Dart (`Stream<List<FlashOrder>>`, `Stream<List<PharmacyOffer>>`).
- **Gestionnaire de Reconnexion & Fallback Hors-Ligne** :
  * Détection de perte de connexion WebSocket.
  * Bascule automatique en polling temporisé (ex: rafraîchissement toutes les 10 secondes) avec backoff si déconnecté.
  * Re-synchronisation transparente dès le rétablissement de la connexion.

### 2. Intégration Bidirectionnelle Patient <-> Pharmacien
- **Côté Patient (`FlashReservationCubit`)** :
  * Réception instantanée des devis émis par les pharmacies sans rechargement manuel.
  * Déclenchement automatique de l'escalade de vague si le délai (2 minutes) expire sans offre suffisante.
  * Notification en temps réel de l'acceptation de la commande ou du statut de délivrance.
- **Côté Pharmacien (`PharmacistCounterCubit`)** :
  * Arrivée instantanée des nouvelles demandes de patients entrant dans la vague de l'officine.
  * Notification visuelle et sonore discrète d'une nouvelle demande entrante.
  * Retrait immédiat d'une commande de l'Inbox si le patient a validé l'offre d'une autre officine (gestion de la concurrence et arrêt de la course).

### 3. Sécurité, RLS & Traçabilité Déontologique (Loi n° 2024/017)
- Transmission chiffrée de l'OTP de validation.
- Anonymisation des données patients lors de l'émission dans la vague (seuls les médicaments et le repère urbain sont transmis aux officines).
- Archivage sécurisé du ticket de délivrance une fois l'OTP validé au comptoir.

---

## 🧪 Suite de Tests Automatisés Requise

1. **Tests Unitaires & Mocks Streams** :
   * Simulation de réceptions d'offres en streaming (`StreamController`).
   * Test de la bascule en mode dégradé (simulation de déconnexion réseau puis reconnexion).
   * Test de concurrence : retrait instantané d'une demande dès qu'elle est pourvue par un confrère.
2. **Tests d'Intégration BLoC / Cubit** :
   * Alignement des états entre `FlashReservationCubit` (Patient) et `PharmacistCounterCubit` (Officine).
   * Vérification de l'escalade de vagues synchronisée.
3. **Quality Gates Strictes** :
   * `dart analyze --fatal-infos --fatal-warnings lib/ test/` : **0 issue**.
   * `flutter test` : **100% vert** sur l'ensemble des suites (y compris rétrocompatibilité étapes 1, 2, 3 et 4).
