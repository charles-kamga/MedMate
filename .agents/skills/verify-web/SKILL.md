---
name: verify-web
description: Exécute le pipeline complet de vérification d'Afya Santé (MedMate) pour Flutter Web et Mobile : analyse statique zéro-tolérance, audit de souveraineté OpenStreetMap et de compatibilité Web (absence de dart:io et de Google Maps), tests unitaires/widgets multi-viewport, compilation Flutter Web et inspection Chrome DevTools. À utiliser systématiquement avant de terminer une étape de développement ou un refactoring.
---

# Verify-Web — Pipeline de Validation Continue (Afya Santé / MedMate)

## Objectif

Garantir qu'aucune modification de code n'introduit :
1. D'erreur ou d'avertissement d'analyse statique (`very_good_analysis`).
2. D'import natif incompatible avec le navigateur (`dart:io` non protégé).
3. De violation des invariants métier (URLs ou SDK Google Maps/Mapbox, clé secrète `service_role`, prix fixe en dur).
4. De régression fonctionnelle ou de débordement d'interface (`RenderFlex overflow`) sur Mobile ou Desktop.
5. D'échec de compilation du bundle **Flutter Web**.

---

## Procédure d'Exécution Pas-à-Pas

### Étape 1 — Audit de Souveraineté & Compatibilité Web (`lib/`)

Vérifier qu'aucun fichier de `lib/` n'utilise de dépendance ou d'URL interdite :

```bash
# 1. Vérifier l'absence totale de Google Maps ou Mapbox dans lib/
! grep -rnE "google\.com/maps|maps\.googleapis|google_maps_flutter|mapbox" lib/

# 2. Vérifier l'absence d'import dart:io non conditionnel dans lib/
! grep -rn "import 'dart:io'" lib/

# 3. Vérifier l'absence de clé service_role dans lib/ et web/
! grep -rn "SERVICE_ROLE" lib/ web/
```

Si l'une de ces commandes retourne une correspondance, **corriger immédiatement** :
- Remplacer tout lien externe de carte par `AppConfig.buildOsmSearchUrl(...)`.
- Remplacer `dart:io` par `kIsWeb` (`package:flutter/foundation.dart`) ou des flux d'octets en mémoire (`Uint8List`).

### Étape 2 — Analyse Statique Zéro-Tolérance

```bash
/home/charles/development/flutter/bin/dart analyze --fatal-infos --fatal-warnings
```

- Résultat exigé : `No issues found!`.
- En cas d'avertissement ou d'info, corriger le typage, les constructeurs `const`, ou la documentation manquante avant de poursuivre.

### Étape 3 — Suite de Tests Unitaires & Widgets

```bash
/home/charles/development/flutter/bin/flutter test
```

- Tous les tests doivent passer à 100 %.
- Pour tout nouvel écran ou composant majeur, inclure dans `test/` une vérification sur viewport Mobile (`390x844`) et Desktop (`1280x800`).

### Étape 4 — Compilation Release Flutter Web

```bash
/home/charles/development/flutter/bin/flutter build web --release
```

- Vérifier que `build/web/main.dart.js` et `build/web/index.html` sont générés sans erreur.

### Étape 5 — Inspection Visuelle & Console (Lorsque l'UI est modifiée)

Lors d'une modification visuelle significative :
1. Servir `build/web` ou lancer l'application Web en local.
2. Utiliser Chrome DevTools MCP (`chrome-devtools` skill) pour vérifier :
   - **Console** : Zéro exception non gérée ni erreur CORS/CSP.
   - **Network** : Chargement HTTP 200 des tuiles `tile.openstreetmap.fr`.
   - **Responsive** : Rendu propre en mode Smartphone (`390x844`) et Comptoir Pharmacie (`1280x800`).
