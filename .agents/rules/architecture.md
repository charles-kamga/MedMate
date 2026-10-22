# Architecture & Découpage Système (MedMate)

Ce document définit les principes architecturaux stricts qui régissent la structure du projet MedMate (Frontend Flutter et Backend Supabase/PostgreSQL).

---

## 1. Clean Architecture Modulaire

Le projet applique une **Clean Architecture stricte** découpée en couches étanches avec flux de dépendances unidirectionnel (la couche Présentation dépend du Domaine ; la couche Données implémente les contrats du Domaine ; le Domaine ne dépend d'aucune couche externe).

```text
lib/
├── core/                        # Utilitaires transversaux, erreurs, types scellés Result/Failure
│   ├── errors/
│   ├── network/
│   └── theme/
├── features/
│   └── <feature_name>/          # Découpage vertical par fonctionnalité
│       ├── domain/              # Cœur métier (Pur Dart, zéro dépendance Flutter ou Supabase)
│       │   ├── entities/        # Modèles métier immuables
│       │   ├── repositories/    # Interfaces abstraites (contrats)
│       │   └── usecases/        # Cas d'utilisation métier unitaires
│       ├── data/                # Implémentation technique
│       │   ├── datasources/     # Remote (Supabase client) et Local (SQLite/Cache)
│       │   ├── models/          # DTOs (Data Transfer Objects) + Sérialisation JSON
│       │   └── repositories/    # Implémentation concrète des contrats du domaine
│       └── presentation/        # Interface utilisateur réactive
│           ├── controllers/     # Gestion d'état (BLoC ou StateNotifier Riverpod)
│           └── views/           # Widgets purs sans logique métier
```

### 1.1 Règle de Séparation UI / Logique Métier
- **Widgets passifs** : Aucun appel asynchrone direct (`supabase.from(...)` ou `http.get`) au sein des Widgets Flutter.
- Les widgets émettent des événements (*events/intents*) vers un contrôleur d'état (BLoC ou Riverpod Notifier) et consomment des états immuables.
- Toute validation métier complexe doit résider dans un `UseCase` du domaine.

---

## 2. Cartographie & Repères Urbains de Yaoundé (PostGIS)

### 2.1 Rejet de la Distance Euclidienne Naïve
- La topographie de Yaoundé (« la ville aux sept collines ») et la configuration de son réseau routier rendent la distance euclidienne (vol d'oiseau) inopérante et trompeuse pour un patient en urgence.
- La localisation ne doit pas s'appuyer sur un simple calcul de rayon circulaire `ST_DistanceSphere` isolé.

### 2.2 Modélisation Spatiale Réelle : Carrefours et Quartiers
- Le système associe chaque officine et chaque patient à :
  1. Un **Quartier** de Yaoundé (ex. *Bastos, Mokolo, Biyem-Assi, Omnisports, Tsinga, Essos, Mendong, Nsam, Ngoa-Ekellé*).
  2. Un ou plusieurs **Carrefours / Points de repère remarquables** (ex. *Carrefour Warda, Carrefour Obili, Carrefour Nlongkak, Carrefour Régie, Poste Centrale, Carrefour Emia, Carrefour MEEC*).
- Dans PostgreSQL / PostGIS, les points sont indexés en coordonnées WGS84 (`geography(Point, 4326)`).
- Le filtrage spatial s'effectue en cascade :
  - **Échelon 1 (Zone & Accessibilité)** : Requête sur le secteur ou quartier d'appartenance et carrefours mitoyens (`ST_DWithin` sur réseau topologique).
  - **Échelon 2 (Distance routière/isochrone)** : Prise en compte de l'accessibilité réelle et de la permanence de garde.

```sql
-- Requête type de proximité avec repère urbain (PostGIS)
SELECT 
  p.id, 
  p.nom, 
  p.quartier, 
  p.carrefour_repere,
  ST_Distance(p.location, ST_SetSRID(ST_MakePoint(:user_lon, :user_lat), 4326)::geography) AS distance_metres
FROM pharmacies p
WHERE p.est_ouverte = true 
  AND (p.quartier = :quartier_patient OR ST_DWithin(p.location, ST_SetSRID(ST_MakePoint(:user_lon, :user_lat), 4326)::geography, 3000))
ORDER BY distance_metres ASC;
```

---

## 3. Neutralité Algorithmique & Conformité Déontologique ONPC

### 3.1 Obligation Légale et Déontologique
- En vertu de la **Loi n° 90-035 du 10 août 1990** régissant la profession de pharmacien au Cameroun et du **Code de déontologie de l'Ordre National des Pharmaciens du Cameroun (ONPC)** :
  - Le compérage, l'orientation artificielle de clientèle et le rabattage commercial sont passibles de sanctions ordinales et pénales.
  - Le patient dispose du **libre choix** absolu de son officine.

### 3.2 Algorithme de Dispatch Équitable (Round-Robin Pondéré)
- Lors d'une demande de disponibilité ou de réservation émise par un patient :
  - Le système identifie le groupe des $N$ officines éligibles les plus proches (2 à 3 officines de garde ou ouvertes dans le secteur).
  - La sélection ou la proposition au patient doit appliquer une rotation équitable (**Round-Robin** sans pondération financière).
  - **Interdiction formelle** de :
    - Tout système de référencement payant ("sponsorisé", "mis en avant").
    - Tout algorithme de ranking favorisant une pharmacie en fonction d'un volume de commissionnement ou de partenariat privé.
    - Toute tarification différenciée du médicament (respect du prix homologué nationalement).
