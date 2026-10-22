# Sécurité, Confidentialité & Données de Santé (MedMate)

Ce document établit les exigences de sécurité et de conformité légale applicables à l'ensemble des modules de MedMate.

---

## 1. OWASP Mobile & API Top 10

### 1.1 Validation Stricte des Entrées (Défense en Profondeur)
- Ne jamais faire confiance aux données transmises par le client mobile.
- Chaque point d'entrée API (Supabase RPC, Edge Function, Webhook) doit valider la structure, le format, la taille et le type des paramètres avant tout traitement.
- Utiliser des contraintes SQL explicites (`CHECK`, `NOT NULL`, `FOREIGN KEY`) au niveau de la base de données.
- Prévention des injections SQL : utiliser exclusivement les requêtes préparées et l'ORM/Query Builder Supabase ; proscrire toute concaténation de chaînes dans les requêtes brutes.

### 1.2 Chiffrement en Transit et au Repos
- Toutes les communications réseau doivent utiliser exclusivement **TLS 1.3** avec *Certificate Pinning* sur les domaines Supabase et passerelles critiques.
- Données locales sensibles (identifiants de session, clés de cache) chiffrées au repos via `SQLCipher` et le Keystore/Keychain de la plateforme.

---

## 2. Gestion et Isolation des Secrets

### 2.1 Bannissement du `service_role` dans le Client
- **Règle absolue** : La clé secrète `SUPABASE_SERVICE_ROLE_KEY` donne un accès de contournement total à la base de données. Elle ne doit **JAMAIS** figurer dans le code source de l'application mobile Flutter ni dans aucun bundle distribué.
- Seule la clé publique anonyme `SUPABASE_ANON_KEY` et l'URL du projet sont autorisées côté client, injectées via `--dart-define` ou `.env` exclu de Git.
- Toute opération nécessitant des privilèges d'administration doit être exécutée dans une **Supabase Edge Function** isolée, dont les secrets sont stockés dans Supabase Vault.

---

## 3. Row Level Security (RLS) PostgreSQL Stricte

### 3.1 Règle de l'Activation Systématique
- Chaque table sensible créée (`patients`, `pharmacies`, `demandes_disponibilite`, `reservations`) **DOIT** exécuter :
  ```sql
  ALTER TABLE public.<table_name> ENABLE ROW LEVEL SECURITY;
  ALTER TABLE public.<table_name> FORCE ROW LEVEL SECURITY;
  ```
- Par défaut, sans politique explicite, l'accès est entièrement fermé (`deny all`).

### 3.2 Modèle de Politiques RLS
- **Patients** : Accès limité aux enregistrements où `auth.uid() = patient_id`.
- **Pharmaciens** : Accès limité aux demandes et réservations attribuées à l'officine dont ils sont gestionnaires vérifiés (`EXISTS (SELECT 1 FROM pharmacy_staff WHERE staff_id = auth.uid() AND pharmacy_id = reservations.pharmacy_id)`).
- **Consultations Anonymes** : Si un patient effectue une recherche sans créer de compte, la requête utilise un jeton HMAC de session éphémère limitant l'accès à la réservation créée pendant une durée maximale de 2 heures.

```sql
-- Exemple de politique RLS sur la table des réservations
CREATE POLICY "Les patients consultent uniquement leurs reservations"
ON public.reservations
FOR SELECT
TO authenticated
USING (auth.uid() = patient_id);

CREATE POLICY "Les pharmaciens gerent les reservations de leur officine"
ON public.reservations
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.pharmacy_staff ps 
    WHERE ps.user_id = auth.uid() 
      AND ps.pharmacy_id = reservations.pharmacy_id
  )
);
```

---

## 4. Données de Santé & Conformité Réglementaire Camerounaise

### 4.1 Cadre Légal : Loi n° 2024/017 du 23 décembre 2024 (ANTIC / APDP)
- Au Cameroun, les données de santé constituent des **données sensibles** soumises à la Loi n° 2024/017 et sous supervision technique de l'ANTIC et de l'APDP.
- Le traitement requiert le consentement éclairé et explicite du patient.

### 4.2 Principe de Minimisation Absolue
- Ne collecter que le strict minimum nécessaire à la mise en relation pour la disponibilité du produit.
- **Photos d'ordonnances** : Traitées en mémoire tampon pour lecture par le pharmacien ; suppression automatique du stockage objet (Supabase Storage) dès que la disponibilité est confirmée ou au plus tard après 24 heures.
- Dissocier l'identité civile du patient de l'historique des requêtes pharmacologiques (pseudonymisation).

### 4.3 Politiques d'Expiration et Purge Automatisée (pg_cron)
1. **Réservations temporaires** :
   - TTL de **2 heures**. Si l'officine ne confirme pas ou si le patient ne récupère pas le médicament dans ce créneau, la réservation bascule en état `expired`.
2. **Historique des recherches et traces de géolocalisation** :
   - Purge automatique à **30 jours**. Aucun log géolocalisé de déplacement patient ne doit subsister au-delà de ce délai.

```sql
-- Job de purge automatique quotidien avec pg_cron
SELECT cron.schedule(
  'purge-expired-health-data-daily',
  '0 2 * * *', -- Tous les jours à 2h du matin
  $$
    -- Expiration des réservations > 2h non réclamées
    UPDATE public.reservations 
    SET statut = 'expired' 
    WHERE statut = 'pending' AND created_at < NOW() - INTERVAL '2 hours';

    -- Purge définitive des logs de recherche et de positionnement > 30 jours
    DELETE FROM public.search_logs WHERE created_at < NOW() - INTERVAL '30 days';
  $$
);
```
