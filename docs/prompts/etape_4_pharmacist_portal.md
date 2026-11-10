# Prompt Étape 4 : Portail Comptoir Pharmacien (Pharmacist Counter Portal)

Vous êtes l'équipe d'ingénierie et d'architecture Flutter / Dart en charge de l'implémentation de l'Étape 4 du projet Afya Santé (`package:medmate`).

---

## ☁️ Environnement Cloud & Protocole de Synchronisation Git OBLIGATOIRE

> [!IMPORTANT]
> **Vous opérez dans un environnement Cloud distant.** Pour garantir la traçabilité et permettre le rapatriement sans conflit sur la machine locale du développeur :
>
> 1. **Démarrage (Pré-requis)** :
>    - Avant de modifier ou d'ajouter le moindre fichier, synchroniser impérativement le dépôt distant :
>      ```bash
>      git fetch origin
>      git checkout -b feat/etape-4-pharmacist-portal origin/feat/etape-3-patient-flow
>      ```
>    - S'assurer que la branche part bien de la dernière version stable de l'Étape 3 (`feat/etape-3-patient-flow`).
>
> 2. **Finalisation & Livraison Distante** :
>    - Une fois l'implémentation terminée et validée par les quality gates :
>      ```bash
>      git status
>      git add .
>      git commit -m "feat(pharmacist-portal): etape 4 - portail comptoir, devis 3 statuts, validation OTP"
>      git push origin feat/etape-4-pharmacist-portal
>      ```
>    - Fournir explicitement à la fin de votre rapport les commandes exactes que le développeur doit exécuter sur sa machine locale pour récupérer votre travail :
>      ```bash
>      git fetch origin
>      git checkout feat/etape-4-pharmacist-portal
>      git pull origin feat/etape-4-pharmacist-portal
>      ```

---

## 🛡️ Invariants du Projet & Garde-fous Architecturaux

1. **Réutilisation stricte des entités du domaine (Zéro Duplication)** :
   - Ne **JAMAIS** redéfinir de modèles `BasketItem`, `FlashOrder`, `PharmacyOffer` ou `Reservation`.
   - Réutiliser directement :
     * `package:medmate/features/flash_order/domain/entities/flash_order.dart`
     * `package:medmate/features/flash_order/domain/entities/pharmacy_offer.dart`
     * `package:medmate/features/flash_order/domain/entities/basket_item.dart`
     * `package:medmate/features/pharmacy_search/domain/entities/medication.dart`
     * `package:medmate/features/pharmacy_search/domain/entities/reservation.dart`
     * `package:medmate/features/reservation/domain/repositories/reservation_repository.dart`
   - Si un besoin d'extension se présente, enrichir les entités existantes ou créer un repository dédié `PharmacistPortalRepository` qui référence ces mêmes types sans casser les imports de l'Étape 3.

2. **Politique Tarifaire & Éthique ONPC (Zéro Prix Catalogue)** :
   - L'officine est l'unique entité habilitée à communiquer une offre tarifaire au comptoir (`quotedPriceCfa`).
   - Respect strict des 3 statuts ONPC :
     * `fullyAvailable` (Disponible)
     * `conditional` / `partiallyAvailable` (Disponible sous conditions : ex. ordonnance physique requise ou substitution équivalente DCI homologuée)
     * `unavailable` (Indisponible avec motif médical/technique sobre).

3. **Maîtrise des Timers Asynchrones & Testabilité (`WidgetTester`)** :
   - Tout timer d'auto-rafraîchissement (polling de l'inbox) ou décompte de vague doit obligatoirement pouvoir être désactivé via un paramètre dédié (ex. : `enableAutoRefresh: false`, `enableTicker: false`).
   - Les `AnimationController` ou répétitions en boucle doivent respecter `TickerMode.valuesOf(context).enabled`. Aucun timer orphelin ne doit faire échouer `pumpAndSettle()`.

4. **Résilience Réseau & Concurrence (Race Conditions)** :
   - Gérer explicitement les cas de conflit serveur :
     * Demande déjà acceptée par un autre confrère de la même vague (`OrderAlreadyClaimedException`).
     * Vague expirée / commande réattribuée (`WaveExpiredException`).
     * Code OTP invalide, déjà consommé ou expiré (> 2 heures).
   - Présenter un feedback visuel immédiat (SnackBar ou bannière d'information ambre/rouge) sans crash de l'interface.

5. **Règles de Code & Limites de Fichiers** :
   - Fichiers widgets strictement **< 400 lignes**. Si une vue dépasse 300 lignes, extraire immédiatement ses sous-composants dans des fichiers dédiés.
   - Zéro type `dynamic` non justifié.
   - Zéro warning sous analyse stricte (`dart analyze --fatal-infos --fatal-warnings`).
   - Couverture complète par tests automatisés (`bloc_test` et `mocktail`).

---

## 🎯 Périmètre Fonctionnel de l'Étape 4

### 1. Contrôleur d'État Officine (`PharmacistCounterCubit` & `PharmacistCounterState`)
- **Gestion de la file d'attente (Inbox des demandes Flash reçues)** :
  * Réception de la liste des demandes assignées à l'officine pour la vague courante.
  * Gestion du compte à rebours de vague (2 minutes max pour soumissionner).
- **Émission de l'offre officine** :
  * Choix parmi les 3 statuts ONPC.
  * Saisie du prix total en FCFA (`quotedPriceCfa`).
  * Option mototaxi partenaire : case à cocher, saisie des frais de livraison en FCFA (`deliveryFeeCfa`) et du délai estimé en minutes.
  * Pour le statut conditionnel : sélection/saisie des conditions (ordonnance originale, dosage alternatif).
- **Validation du Retrait OTP au Comptoir** :
  * Saisie d'un code OTP à 6 chiffres.
  * Validation métier : conformité du code, vérification de validité (< 2h).
  * Transition vers l'état `delivered` et archivage conforme Loi Santé Cameroun n° 2024/017.

---

### 2. Composants UI Responsives & Découpage Granulaire (< 400 lignes/fichier)
- `pharmacist_request_inbox_card.dart` :
  * Affiche le récapitulatif des médicaments demandés, quantités, mentions d'ordonnance et repère urbain (carrefour Yaoundé).
- `pharmacist_quote_reply_sheet.dart` :
  * Formulaire modal ergonomique pour saisir la proposition avec bascule des 3 statuts et frais mototaxi.
- `counter_otp_validation_keypad.dart` :
  * Pavé numérique tactile de saisie rapide (6 digits) avec confirmation visuelle en Émeraude médical (`#10B981`).
- `pharmacist_portal_view.dart` :
  * Assemblage responsive :
    * Écran de caisse / Tablette / Desktop ($\ge 900\,\text{px}$) : vue scindée en 2 colonnes (Inbox à gauche, saisie devis / validation OTP à droite).
    * Mobile officine ($< 600\,\text{px}$) : onglets ou pile d'écrans fluides sans débordement.
  * Accessible via l'onglet Profil de `AfyaAppShell`.

---

### 3. Suite de Tests Automatisés Requise
- **Tests unitaires Cubit** :
  * Émission d'une offre pour chacun des 3 statuts.
  * Gestion des erreurs de conflit (commande déjà pourvue, vague dépassée).
  * Validation d'un code OTP valide, expiré et erroné.
- **Tests de Widgets (Multi-Viewport)** :
  * Rendu sans aucun overflow `RenderFlex` sur mobile (`390x844`) et écran comptoir (`1280x800`).
  * Interaction complète : sélection d'une demande -> saisie du devis -> soumission -> validation OTP.
- **Validation Quality Gates** :
  * `dart analyze --fatal-infos --fatal-warnings` : 0 issue.
  * `flutter test test/features/pharmacist_portal/` : 100% vert.
