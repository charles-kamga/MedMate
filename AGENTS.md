# Afya Santé (MedMate) — Guide Agent & Règles du Projet

## 1. Identité & Contexte Métier
- **Nom Produit** : **Afya Santé** (`AppConfig.appName` dans `lib/core/config/app_config.dart`).
- **Nom du Package Dart** : `medmate` (`pubspec.yaml` — conservé pour la stabilité des imports `package:medmate/...`).
- **Mission** : Plateforme Web et Mobile de mise en relation entre patients et pharmacies d'officine à **Yaoundé (Cameroun)** (recherche de disponibilité de médicaments, pharmacies de garde en temps réel, commande flash sur ordonnance, portail pharmacien au comptoir).

---

## 2. Invariants Métier & Techniques Inviolables

1. **Politique Zéro Prix Affiché (Tarification au Comptoir)** :
   - **Interdiction absolue** d'afficher ou de fixer des prix de médicaments dans l'application côté patient.
   - Le prix et la disponibilité finale sont exclusivement confirmés par le pharmacien au comptoir lors de la réponse à la demande.
2. **Souveraineté Cartographique OpenStreetMap (OSM)** :
   - **Interdiction formelle** de Google Maps (`google.com/maps`, `google_maps_flutter`, Google Places API) et de Mapbox.
   - Utiliser exclusivement **OpenStreetMap** via `flutter_map`, le serveur de tuiles OSM France (`AppConfig.osmFranceTileUrlTemplate`), le `User-Agent` déclaré (`AppConfig.osmUserAgent`) et le générateur de liens externes `AppConfig.buildOsmSearchUrl(...)`.
3. **Neutralité Déontologique ONPC & Charte Santé** :
   - Respect strict de la Loi n° 90-035 et du Code de déontologie de l'ONPC : libre choix du patient, algorithme **Round-Robin** équitable sans référencement payant ni officine sponsorisée.
   - **Charte chromatique santé** : Émeraude / Teal médical (`#0D9488`, `#10B981`), Ambre (`#F59E0B`) pour les gardes et alertes. **Bannir le rouge vif** pour le branding ou les indicateurs médicaux courants (anxiogène dans le domaine de la santé).
   - **Typographie** : Police `Plus Jakarta Sans` (`google_fonts`).

---

## 3. Stack Technique & Cible Flutter Web
- **Cible prioritaire** : **Flutter Web** (`web/`, compilation WASM/CanvasKit, responsive Mobile / Tablette / Desktop comptoir pharmacie) + Android.
- **SDK Flutter** : `/home/charles/development/flutter/bin/flutter` (et `/home/charles/development/flutter/bin/dart`).
- **Navigateur de test** : `/usr/bin/google-chrome-stable` (`CHROME_EXECUTABLE=/usr/bin/google-chrome-stable`).
- **Backend** : Supabase (`supabase_flutter`, PostgreSQL 15+, PostGIS `geography(Point, 4326)`, `pg_trgm`, Row Level Security forcée, `pg_cron`).

---

## 4. Matrice de Maturité Architecturale des Modules

| Module (`lib/features/`) | Statut | Règle d'évolution |
| :--- | :--- | :--- |
| `auth/` | Socle Vierge (Clean Arch) | Construire `domain/` + `data/` + `presentation/` (BLoC, `Either<Failure, T>`, PKCE) |
| `pharmacy_search/` | Socle Vierge (Clean Arch) | Construire `domain/` + `data/` + `presentation/` (PostGIS + OSM `flutter_map`) |
| `reservation/` | Socle Vierge (Clean Arch) | Construire `domain/` + `data/` + `presentation/` (Vagues Round-Robin, TTL 2h, OTP) |
| `pharmacist_portal/` | Socle Vierge (Clean Arch) | Construire `domain/` + `data/` + `presentation/` (Portail comptoir Web/Desktop) |
| `duty_pharmacy/` | Socle Vierge (Clean Arch) | Construire `domain/` + `data/` + `presentation/` (Officines de garde en temps réel) |

> **Règle sur tout nouveau code** : Aucun nouveau fichier Widget ne doit dépasser **400 lignes**. Aucune logique métier ni appel réseau direct dans un Widget.

---

## 5. Commandes de Vérification Obligatoires (Quality Gates)

Avant de conclure toute tâche de modification de code, exécuter le skill [verify-web](.agents/skills/verify-web/SKILL.md) :
```bash
/home/charles/development/flutter/bin/dart analyze --fatal-infos --fatal-warnings
/home/charles/development/flutter/bin/flutter test
/home/charles/development/flutter/bin/flutter build web --release
```

---

## 6. Règles Détaillées & Skills du Projet

@[Architecture & Découpage Système](.agents/rules/architecture.md)
@[Coding Standards & Rigueur Technique](.agents/rules/coding-standards.md)
@[Plateforme Flutter Web & Responsive](.agents/rules/web-platform.md)

- **Sécurité, RLS & Loi n° 2024/017 (Données de Santé)** : consulter [.agents/rules/security.md](.agents/rules/security.md) avant toute modification touchant à l'authentification, au stockage, aux politiques RLS ou aux en-têtes Web.
- **Stratégie de Tests & Quality Gates** : consulter [.agents/rules/testing.md](.agents/rules/testing.md) lors de l'écriture ou de la modification de tests dans `test/`.
- **Skills disponibles dans le workspace** :
  - `database-guard` ([.agents/skills/database-guard/SKILL.md](.agents/skills/database-guard/SKILL.md)) : Audit des migrations SQL Supabase, index PostGIS/trigrammes et RLS.
  - `verify-web` ([.agents/skills/verify-web/SKILL.md](.agents/skills/verify-web/SKILL.md)) : Pipeline complet de validation statique, souveraineté OSM, tests unitaires/widgets et build Flutter Web.
