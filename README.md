# MedMate — Pharmacies de Proximité à Yaoundé

<p align="center">
  <img src="https://raw.githubusercontent.com/charles-kamga/MedMate/main/assets/branding/banner.png" alt="MedMate Banner" width="100%" onerror="this.style.display='none'"/>
</p>

<p align="center">
  <b>Application mobile et web de mise en relation d'urgence entre patients et officines pharmaceutiques à Yaoundé (Cameroun).</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white" alt="Dart"/>
  <img src="https://img.shields.io/badge/State-BLoC-blue?logo=bloc" alt="BLoC"/>
  <img src="https://img.shields.io/badge/Backend-Supabase%20%2F%20PostgreSQL-3ECF8E?logo=supabase&logoColor=white" alt="Supabase"/>
  <img src="https://img.shields.io/badge/GIS-PostGIS-336791?logo=postgresql&logoColor=white" alt="PostGIS"/>
  <img src="https://img.shields.io/badge/Maps-OpenStreetMap-7EBC6F?logo=openstreetmap&logoColor=white" alt="OpenStreetMap"/>
  <img src="https://img.shields.io/badge/Security-RLS%20%26%20OWASP-critical" alt="Security"/>
  <img src="https://img.shields.io/badge/Compliance-Loi%202024%2F017%20%7C%20ONPC-success" alt="Compliance"/>
</p>

---

## Contexte & Problématique

À **Yaoundé** (« la ville aux sept collines »), trouver un médicament d'urgence relève souvent du parcours du combattant :
-  **Relief collinaire et circulation saturée** : parcourir la ville de nuit d'officine en officine sans certitude de disponibilité engendre un coût financier et un risque vital.
-  **Inadéquation de la distance à vol d'oiseau** : les usagers et chauffeurs ne s'orientent pas par coordonnées GPS brutes, mais par **Carrefours emblématiques** (*Carrefour Warda, Carrefour Obili, Poste Centrale, Carrefour Nlongkak, Acacia...*) et **Quartiers** (*Bastos, Mokolo, Biyem-Assi, Essos, Tsinga...*).
-  **Réseau mobile intermittent (3G/EDGE)** : l'application doit fonctionner en mode dégradé (*offline-first*) et préserver la data du patient.

**MedMate** apporte une solution souveraine, rapide, économe et déontologiquement neutre.

---

## Fonctionnalités Clés

-  **Recherche par Repères Urbains & PostGIS** : Sélection directe par carrefours connus de Yaoundé ou géolocalisation fine via calculs topologiques PostGIS réels (`geography(Point, 4326)`).
-  **Catalogue National Tolérant aux Fautes** : Recherche instantanée de médicaments et DCI homologués au Cameroun, avec tolérance aux fautes de frappe via l'extension PostgreSQL `pg_trgm`.
-  **Confirmation Flash & Neutralité ONPC** : Notification en temps réel des officines du secteur et rotation équitable (*Round-Robin*) sans aucun favoritisme commercial ni référencement payant.
-  **Réservation Sécurisée (Code Retrait OTP)** : Réservation bloquée avec TTL strict de 2 heures pour retirer le produit au comptoir.
-  **Résilience Réseau & Mode Hors-Ligne** : Cache local SQLite chiffré (`SQLCipher`) pour consulter les officines de garde même sans connexion internet.
-  **Protection des Données de Santé** : Conformité à la **Loi camerounaise n° 2024/017 du 23 décembre 2024** (régulée par l'ANTIC / APDP) et purge automatique des historiques à 30 jours via `pg_cron`.

---

## Architecture Logicielle

Le projet est structuré selon les règles strictes de la **Clean Architecture** avec une séparation étanche des responsabilités :

```text
MedMate/
├── .agents/                                # Configuration Agentique Google Antigravity
│   ├── rules/                              # Règles obligatoires : coding, architecture, security, testing
│   └── skills/database-guard/SKILL.md      # Runbook d'audit SQL (RLS, PostGIS GIST, Trigrammes GIN)
├── supabase/
│   └── migrations/                         # Migrations SQL versionnées, auditées et idempotentes
├── lib/
│   ├── core/                               # Utilitaires transversaux, Failures scellées, Repères Yaoundé
│   ├── features/pharmacy_search/
│   │   ├── domain/                         # Entités immuables, Contrats de dépôts, UseCases
│   │   ├── data/                           # DTOs, Mappers, Remote (Supabase) & Local (SQLite)
│   │   └── presentation/                   # Gestion d'état BLoC et Widgets réactifs
│   └── main.dart                           # Point d'entrée de l'application
└── test/                                   # Pyramide de tests unitaires (Mocktail, 100% domain)
```

---

## Conformité Légale & Déontologique

### 1. Neutralité Pharmaceutique (ONPC & Loi n° 90-035)
MedMate respecte scrupuleusement la **Loi n° 90-035 du 10 août 1990** et le Code de déontologie de l'**Ordre National des Pharmaciens du Cameroun (ONPC)** :
- **Interdiction formelle du compérage et du rabattage commercial**.
- L'algorithme de dispatch attribue les demandes de disponibilité selon une rotation équitable (*Round-Robin* équipondéré) entre officines ouvertes/de garde du secteur géographique.
- Aucun système de sponsoring payant, d'enchère ou de publicité déguisée.
- Respect absolu du libre choix de l'officine par le patient.

### 2. Données Personnelles et de Santé (Loi n° 2024/017 & ANTIC)
- **Minimisation des données** : Le patient consulte et cherche librement sans inscription préalable. Le numéro de téléphone n'est collecté que pour la confirmation d'une réservation effective.
- **Rétention éphémère** : Réservations non réclamées expirées sous **2 heures**.
- **Droit à l'oubli automatisé** : Purge quotidienne automatique des historiques de localisation et requêtes de plus de **30 jours** via `pg_cron`.

---

##  Démarrage Rapide

### Prérequis
- [Flutter SDK](https://docs.flutter.dev/get-started/install/linux) (v3.16.0 ou supérieure)
- [Dart SDK](https://dart.dev/get-dart) (v3.2.0 ou supérieure)
- [Docker Engine](https://docs.docker.com/engine/install/) (pour Supabase en local)
- [Supabase CLI](https://supabase.com/docs/guides/local-development/cli/getting-started) : `npm install -g supabase`

### 1. Cloner le Dépôt
```bash
git clone git@github.com:charles-kamga/MedMate.git
cd MedMate
```

### 2. Installer les Dépendances Flutter
```bash
flutter pub get
```

### 3. Lancer le Backend Local Supabase (PostGIS & pg_trgm)
```bash
# Démarrer les conteneurs PostgreSQL, PostGIS et l'API Supabase
supabase start

# Appliquer les migrations et les données initiales de Yaoundé
supabase db reset
```

### 4. Lancer l'Application Mobile
```bash
flutter run
```

---

## Tests & Qualité de Code

Le projet impose une politique de **zéro warning** et une validation continue obligatoire :

```bash
# 1. Analyse statique stricte (règles very_good_analysis + zéro dynamic)
dart analyze --fatal-infos --fatal-warnings

# 2. Exécution de la suite de tests unitaires avec couverture
flutter test --coverage
```

---

## Configuration Agentique (Antigravity)

Ce repository inclut une configuration d'agent d'élite dans `.agents/`, conçue pour guider les assistants d'IA (Google Antigravity) :
- **`.agents/rules/coding-standards.md`** : Règle du zéro `dynamic`, typage strict, modèles immuables, pattern `Result` / `Either`.
- **`.agents/rules/architecture.md`** : Découpage Clean Architecture, cartographie PostGIS par repères et neutralité ONPC.
- **`.agents/rules/security.md`** : OWASP Mobile/API, secrets distants, politiques RLS obligatoires et conformité ANTIC.
- **`.agents/rules/testing.md`** : Pyramide de tests et quality gates.
- **`.agents/skills/database-guard/`** : Runbook d'audit automatique des migrations SQL Supabase.

---

## Auteur & Licence

Développé par **Charles Kamga** ([@charles-kamga](https://github.com/charles-kamga)).  
Sous licence propriétaire / MIT pour le socle open-source. Tous droits réservés pour la marque MedMate Cameroun.
