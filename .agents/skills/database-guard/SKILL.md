---
name: database-guard
description: >-
  Audite et valide les migrations SQL Supabase, les schémas PostgreSQL, les politiques RLS,
  les index spatiaux PostGIS et les index trigrammes textuels du projet MedMate.
  À utiliser avant d'appliquer une nouvelle migration SQL ou lors de la revue d'un schéma de base de données.
---

# Database Guard — Protocole d'Audit SQL Supabase

Ce runbook opérationnel permet à l'agent de vérifier la conformité, la sécurité et la performance de toute migration SQL ou définition de schéma dans MedMate.

---

## Protocole d'Audit pas-à-pas

### Étape 1 : Vérification de la Sécurité RLS (Row Level Security)

Pour chaque table créée ou modifiée dans le schéma public :
1. Vérifier la présence obligatoire de l'activation RLS :
   ```sql
   ALTER TABLE public.<table_name> ENABLE ROW LEVEL SECURITY;
   ALTER TABLE public.<table_name> FORCE ROW LEVEL SECURITY;
   ```
2. Vérifier qu'au moins une politique explicite (`CREATE POLICY`) est définie.
3. **Alerte Rouge** : Rejeter immédiatement les migrations contenant :
   - `GRANT ALL ON ALL TABLES IN SCHEMA public TO anon;`
   - Politiques `USING (true)` sans condition d'authentification ou de rôle sur des tables sensibles.

Requête SQL d'audit des tables sans RLS :
```sql
SELECT tablename 
FROM pg_tables 
WHERE schemaname = 'public' 
  AND rowsecurity = false;
```

---

## Étape 2 : Vérification des Index Spatiaux PostGIS (GIST)

Toute table stockant une position géographique (ex. officines, carrefours, positions de garde) doit :
1. Utiliser le type `geography(Point, 4326)` ou `geometry(Point, 4326)`.
2. Avoir un index spatial de type **GIST** dédié pour accélérer les requêtes `ST_DWithin` et `ST_Distance`.

```sql
-- Pattern conforme obligatoire
CREATE INDEX IF NOT EXISTS idx_pharmacies_location_gist 
ON public.pharmacies USING GIST (location);
```

Requête SQL d'audit des colonnes géographiques orphelines d'index :
```sql
SELECT c.table_name, c.column_name, c.data_type
FROM information_schema.columns c
WHERE c.table_schema = 'public' 
  AND c.udt_name IN ('geometry', 'geography')
  AND NOT EXISTS (
    SELECT 1 FROM pg_indexes i 
    WHERE i.tablename = c.table_name 
      AND i.indexdef ILIKE '%USING gist%'
  );
```

---

## Étape 3 : Indexation Textuelle Médicaments (Extension `pg_trgm` & GIN)

La recherche de médicaments dans un contexte patient nécessite la tolérance aux fautes d'orthographe (recherche floue / phonétique sur les dénominations commerciales et DCI).

1. Vérifier l'activation préalable de l'extension :
   ```sql
   CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA extensions;
   ```
2. Vérifier la présence d'un index **GIN** utilisant l'opérateur de trigrammes `gin_trgm_ops` :
   ```sql
   CREATE INDEX IF NOT EXISTS idx_medicaments_nom_trgm 
   ON public.medicaments USING gin (nom extensions.gin_trgm_ops);

   CREATE INDEX IF NOT EXISTS idx_medicaments_dci_trgm 
   ON public.medicaments USING gin (dci extensions.gin_trgm_ops);
   ```
3. Rejeter les recherches basées sur des `ILIKE '%terme%'` sans index trigramme associé (cause de scans séquentiels massifs).

---

## Étape 4 : Détection des Anti-Patterns & Prévention N+1

1. **Foreign Keys sans Index** : Vérifier que chaque clé étrangère possède un index btree sur la colonne fille (évite les verrous de table en cascade lors des DELETE/UPDATE) :
   ```sql
   CREATE INDEX IF NOT EXISTS idx_reservations_patient_id ON public.reservations (patient_id);
   CREATE INDEX IF NOT EXISTS idx_reservations_pharmacy_id ON public.reservations (pharmacy_id);
   ```
2. **Relations N+1 dans l'API Supabase** :
   - Côté Flutter / client Dart, interdire les boucles d'appels `await supabase.from(...).select()` dans une boucle `for`.
   - Utiliser systématiquement la syntaxe relationnelle Supabase :
     ```dart
     // ✅ Requête jointe en 1 seul aller-retour réseau
     final response = await supabase
         .from('reservations')
         .select('id, statut, created_at, pharmacies (id, nom, quartier, telephone)');
     ```
3. **Locks Bloquants** :
   - Éviter `ALTER TABLE ... ADD COLUMN ... DEFAULT <valeur_non_constante>` sur de grosses tables de production sans `SET lock_timeout = '2s'`.

---

## Checklist de Validation d'une Migration

Avant d'approuver une migration SQL, vérifier chaque case :

- [ ] Extension `postgis` et `pg_trgm` initialisées si des types géographiques ou du texte flou sont manipulés.
- [ ] `ENABLE ROW LEVEL SECURITY` et `FORCE ROW LEVEL SECURITY` présents pour chaque nouvelle table.
- [ ] Politiques RLS distinctes pour `SELECT`, `INSERT`, `UPDATE`, `DELETE` avec rôles explicites (`authenticated`, `anon`).
- [ ] Index spatial `GIST` présent sur chaque colonne géographique.
- [ ] Index `GIN` trigramme présent sur les colonnes de recherche de catalogue pharmaceutique.
- [ ] Index `BTREE` créés sur toutes les colonnes de clés étrangères (`FK`).
- [ ] Purge automatique programmée (via `pg_cron`) si la table stocke des données de santé temporaires ou des logs.
