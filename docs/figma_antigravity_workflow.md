# Guide Opérationnel : Génération de Maquettes Figma avec Antigravity (MedMate / Afya Santé)

Ce document formalise la procédure officielle pour connecter le plugin Figma à Google Antigravity, extraire les tokens graphiques du projet Flutter MedMate et générer des écrans fidèles et animables pour un pitch ou un hackathon.

---

## 1. Prérequis & Architecture de l'Intégration

L'intégration repose sur le **Figma MCP Server** officiel (`antigravity-plugins-partners/plugin/figma`) qui dispose de capacités d'écriture (*Write to Canvas*). Il permet à l'agent d'injecter directement des éléments vectoriels, des conteneurs Auto-Layout et du texte dans un fichier Figma distant via l'API REST/Plugin de Figma.

---

## 2. Procédure Étape par Étape

### Étape 1 : Activer et Authentifier le Plugin Figma dans Antigravity

1. Dans Antigravity, installe le plugin partenaire Figma depuis le catalogue ou l'interface de gestion des extensions :
   - Identifiant : `antigravity-plugins-partners/plugin/figma`
2. Ouvre le panneau **Plugins Manager** (accessible via le menu latéral ou les paramètres).
3. Connecte ton compte Figma :
   - Sélectionne l'authentification OAuth (ou renseigne un *Personal Access Token* généré depuis *Figma > Account Settings > Personal access tokens*).
4. Vérifie que la connexion est active avant de lancer la session de génération.

---

### Étape 2 : Préparer le Fichier Figma Cible

1. Dans Figma, crée un nouveau fichier de design (par exemple nommé `MedMate - Hackathon Pitch`).
2. Assure-toi que le fichier est situé dans un projet où tu disposes des **droits d'édition** (Edit access).
3. Copie l'URL complète du fichier depuis ton navigateur, par exemple :
   ```text
   https://www.figma.com/design/AbCdEf123456/MedMate-Hackathon-Pitch?node-id=0-1
   ```
4. Note la clé unique du fichier (`<FILE_KEY>`, ici `AbCdEf123456`).

---

### Étape 3 : Cartographie des Tokens & Écrans MedMate

Antigravity exploitera directement les sources de vérité du code Flutter existant :

| Ressource | Fichier Source dans MedMate | Rôle / Valeurs Clés |
| :--- | :--- | :--- |
| **Couleurs Primaires** | `lib/core/theme/app_colors.dart` | Primary (`#075B55`), primarySoft (`#DDF2EF`), secondary (`#087E83`), fond (`#F5F7F6`), surface (`#FFFFFF`), bordure (`#E0E7E5`). |
| **Couleurs Sémantiques** | `lib/core/theme/app_colors.dart` | success (`#075B55`), alert/erreur (`#E11D48`), alertSoft (`#FFE4E6`), warning (`#087E83`). Textes : `#263238` / `#546E7A` / `#90A4AE`. |
| **Navigation Shell** | `lib/core/navigation/afya_app_shell.dart` | 4 onglets principaux + bascule Liste/Carte OSM. |
| **Écran Accueil** | `lib/features/patient_flow/presentation/views/patient_home_flow_view.dart` | En-tête, recherche, carrousel d'urgences. |
| **Demande Flash Yango** | `lib/features/reservation/presentation/views/patient_flash_flow_view.dart` | Saisie du panier, carrefours repères de Yaoundé (Warda, Obili, etc.). |
| **Ticket OTP / QR Code** | `lib/features/reservation/presentation/widgets/reservation_otp_ticket_card.dart` | Carte officielle de retrait, OTP à 6 chiffres, QR code. |
| **Gardes & Carte OSM** | `lib/features/duty_pharmacy/` & `lib/features/pharmacy_search/` | Liste des officines ouvertes la nuit, filtres de carrefours, carte OpenStreetMap. |
| **Portail Pharmacien** | `lib/features/pharmacist_portal/presentation/views/pharmacist_portal_view.dart` | Vue comptoir (`1280×800`), file des alertes, validation OTP. |

---

### Étape 4 : Prompts Prêts à l'Emploi — UNE frame par étape

> [!IMPORTANT]
> **Modèle recommandé : Gemini 4 Argon** (ou Hydrogen / Pro) — recommandation de principe, non testée sur Figma MCP. **Valide d'abord l'Étape 4.0 sur une seule frame avant de continuer.** Si l'orchestrateur délègue de l'exploration de code, la règle `.agents/rules/orchestration.md` impose `flash` / `flash_lite` aux sous-agents.

> [!TIP]
> Inutile de recopier le tableau de l'Étape 3 : l'agent lit ce guide sur le disque. Lance **un prompt par frame, dans un même chat**, et ne passe à la suivante qu'après validation visuelle dans Figma.

#### Étape 4.0 — Cadrage + Frame 1 (Accueil Patient)

```markdown
Plugin Figma connecté. Je prépare une maquette propre (pas parfaite) de MedMate / Afya Santé pour un hackathon. L'app est inachevée : ne représente que ce que le code montre réellement, sans inventer de fonctionnalités.

Fichier Figma cible : https://www.figma.com/design/<TA_CLE_DE_FICHIER>/MedMate-Hackathon-Pitch

1. Lis `/home/charles/Documents/Work/Me/MedMate/docs/figma_antigravity_workflow.md` (tableau de l'Étape 3), puis `lib/core/theme/app_colors.dart` et `lib/features/patient_flow/presentation/views/patient_home_flow_view.dart`. Ignore `flash_order/` (déprécié).
2. Crée d'abord les variables Figma de couleur à partir des tokens d'`app_colors.dart` (valeurs exactes, pas de hex inventés).
3. Crée UNE seule frame « 01 - Accueil Patient » (390×844) en Auto-Layout vertical (espacements 8/16/24), calques nommés clairement (ex. `Header`, `SearchBar`, `QuickActions`), couleurs liées aux variables.
4. Les éléments non reproductibles fidèlement (icônes, carte) sont de simples placeholders étiquetés.
5. Arrête-toi, donne-moi le lien de la frame et liste ce que tu as approximé. N'enchaîne pas.
```

#### Étapes 4.1 à 4.4 — Frames suivantes (un prompt chacune)

Modèle de prompt (à répéter en changeant la ligne « Frame ») :

```markdown
Frame 1 validée. Crée UNIQUEMENT la frame suivante, à droite de la précédente avec 80 px d'espacement, en réutilisant les variables et composants existants, avec les MÊMES noms de calques pour les éléments communs (header, barre de navigation) afin de permettre Smart Animate.
Frame : <voir tableau ci-dessous>
Lis d'abord les fichiers sources indiqués. Ne représente que ce que le code affiche. Arrête-toi ensuite et liste tes approximations.
```

| Étape | Frame | Taille | Sources à lire |
| :--- | :--- | :--- | :--- |
| 4.1 | 02 - Demande Flash | 390×844 | `lib/features/reservation/presentation/views/patient_flash_flow_view.dart`, `widgets/patient_basket_composer_card.dart`, `widgets/yango_pulse_flash_button.dart` |
| 4.2 | 03 - Offres & Ticket OTP | 390×844 | `widgets/pharmacy_offer_comparison_card.dart`, `widgets/reservation_otp_ticket_card.dart`, `widgets/reservation_qr_code_box.dart` (QR = placeholder) |
| 4.3 | 04 - Gardes & Carte | 390×844 | `lib/features/duty_pharmacy/presentation/views/duty_pharmacy_screen.dart`, `lib/features/pharmacy_search/presentation/views/pharmacy_map_view.dart` (carte = placeholder) |
| 4.4 | 05 - Portail Pharmacien | 1280×800 | `lib/features/pharmacist_portal/presentation/views/pharmacist_portal_view.dart` |

---

### Étape 5 : Motion Design & Prototypage dans Figma

Une fois les 5 frames validées une par une :
1. Dans Figma, bascule en mode **Prototype**.
2. Relie les interactions clés :
   - Bouton d'action Flash de la Frame 01 → Frame 02 (On click > Navigate to).
   - Envoi de la demande (Frame 02) → Frame 03 avec **Smart Animate** (Ease out, 300 ms). Smart Animate ne fonctionne que si les calques communs portent le même nom d'une frame à l'autre.
   - Accès à la carte → Frame 04.
3. Lance **Figma Present** pour la démo, ou capture/exporte la vidéo pour ta présentation.

---

### Points de vigilance
- **Fidélité** : l'agent lit du code sans rendu visuel. Pour de meilleurs résultats, fournis-lui des captures réelles de l'app (`docs/hackathon_visuals/`) comme références.
- **Droits Figma** : l'écriture sur canevas dépend de ton plan et d'un siège « Full ».
- **App inachevée** : précise quels écrans montrer, sinon des états de démo incomplets apparaîtront.
