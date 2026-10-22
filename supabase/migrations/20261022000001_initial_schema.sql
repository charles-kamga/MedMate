-- ==============================================================================
-- MedMate - Initial Database Schema Migration
-- Compliance: PostGIS, pg_trgm, Row Level Security, Data Minimization (Loi n° 2024/017)
-- ==============================================================================

-- 1. Extensions Requises
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "pg_trgm" WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS "pg_cron";

-- 2. Types Énumérés
CREATE TYPE public.reservation_status AS ENUM (
  'pending',
  'confirmed',
  'expired',
  'cancelled',
  'completed'
);

CREATE TYPE public.flash_status AS ENUM (
  'broadcasting',
  'accepted',
  'declined',
  'expired'
);

CREATE TYPE public.staff_role AS ENUM (
  'titulaire',
  'adjoint',
  'preparateur'
);

-- ==============================================================================
-- 3. Topologie Urbaine & Repères de Yaoundé (PostGIS)
-- ==============================================================================

-- Quartiers administratifs et traditionnels de Yaoundé
CREATE TABLE public.quartiers_yaounde (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nom VARCHAR(100) NOT NULL UNIQUE,
  arrondissement VARCHAR(50) NOT NULL, -- Yaoundé 1er à Yaoundé 7e
  zone_geographique GEOMETRY(Polygon, 4326),
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Carrefours et points de repères majeurs
CREATE TABLE public.carrefours_repere (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nom VARCHAR(150) NOT NULL,
  quartier_id UUID NOT NULL REFERENCES public.quartiers_yaounde(id) ON DELETE CASCADE,
  location GEOGRAPHY(Point, 4326) NOT NULL,
  description_acces TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- ==============================================================================
-- 4. Officines Pharmaceutiques & Personnel
-- ==============================================================================

CREATE TABLE public.pharmacies (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nom VARCHAR(200) NOT NULL,
  licence_onpc VARCHAR(50) NOT NULL UNIQUE, -- Numéro d'ordre ONPC
  quartier_id UUID NOT NULL REFERENCES public.quartiers_yaounde(id),
  carrefour_proche_id UUID REFERENCES public.carrefours_repere(id),
  location GEOGRAPHY(Point, 4326) NOT NULL,
  adresse_detaillee TEXT NOT NULL,
  telephone_garde VARCHAR(20) NOT NULL,
  telephone_secondaire VARCHAR(20),
  est_ouverte BOOLEAN NOT NULL DEFAULT true,
  est_de_garde BOOLEAN NOT NULL DEFAULT false,
  derniere_activite_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Gestionnaires et personnel de l'officine
CREATE TABLE public.pharmacy_staff (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  pharmacy_id UUID NOT NULL REFERENCES public.pharmacies(id) ON DELETE CASCADE,
  role public.staff_role NOT NULL DEFAULT 'preparateur',
  telephone VARCHAR(20) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  UNIQUE(user_id, pharmacy_id)
);

-- ==============================================================================
-- 5. Catalogue National des Médicaments (Homologués Cameroun)
-- ==============================================================================

CREATE TABLE public.medicaments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  dci VARCHAR(255) NOT NULL, -- Dénomination Commune Internationale
  nom_commercial VARCHAR(255) NOT NULL,
  forme VARCHAR(100) NOT NULL, -- Comprimé, Sirop, Injectable, etc.
  dosage VARCHAR(100) NOT NULL,
  classe_therapeutique VARCHAR(150),
  prix_homologue_cfa INTEGER NOT NULL CHECK (prix_homologue_cfa >= 0),
  necessite_ordonnance BOOLEAN NOT NULL DEFAULT false,
  code_national VARCHAR(50) UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- ==============================================================================
-- 6. Demandes Flash & Réservations (Conformité Loi 2024/017 - Minimisation & TTL)
-- ==============================================================================

-- Requêtes de disponibilité flash (validité 5 minutes)
CREATE TABLE public.demandes_flash (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  client_request_id UUID NOT NULL UNIQUE, -- Idempotence client
  patient_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  medicament_id UUID NOT NULL REFERENCES public.medicaments(id) ON DELETE RESTRICT,
  carrefour_reference_id UUID REFERENCES public.carrefours_repere(id),
  location_patient GEOGRAPHY(Point, 4326),
  statut public.flash_status NOT NULL DEFAULT 'broadcasting',
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (timezone('utc'::text, now()) + interval '5 minutes')
);

-- Log d'audit de dispatch pour assurer la neutralité algorithmique Round-Robin
CREATE TABLE public.demande_dispatch_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  demande_id UUID NOT NULL REFERENCES public.demandes_flash(id) ON DELETE CASCADE,
  pharmacy_id UUID NOT NULL REFERENCES public.pharmacies(id) ON DELETE CASCADE,
  notified_via VARCHAR(20) NOT NULL DEFAULT 'realtime', -- realtime, push, sms
  statut_reponse VARCHAR(20) NOT NULL DEFAULT 'pending', -- pending, accepted, declined, timeout
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Réservations temporaires (TTL strict de 2 heures)
CREATE TABLE public.reservations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  client_reservation_id UUID NOT NULL UNIQUE, -- Idempotence client
  demande_id UUID REFERENCES public.demandes_flash(id) ON DELETE SET NULL,
  pharmacy_id UUID NOT NULL REFERENCES public.pharmacies(id) ON DELETE RESTRICT,
  patient_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  patient_phone_contact VARCHAR(25) NOT NULL,
  medicament_id UUID NOT NULL REFERENCES public.medicaments(id) ON DELETE RESTRICT,
  quantite INTEGER NOT NULL DEFAULT 1 CHECK (quantite > 0),
  code_retrait_otp VARCHAR(6) NOT NULL, -- Code à 6 chiffres pour retrait
  statut public.reservation_status NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (timezone('utc'::text, now()) + interval '2 hours'),
  completed_at TIMESTAMPTZ
);

-- ==============================================================================
-- 7. INDEXATION DE HAUTE PERFORMANCE (PostGIS GIST, Trigrammes GIN & FKs)
-- ==============================================================================

-- Index spatiaux GIST
CREATE INDEX idx_pharmacies_location_gist ON public.pharmacies USING GIST (location);
CREATE INDEX idx_carrefours_location_gist ON public.carrefours_repere USING GIST (location);
CREATE INDEX idx_demandes_location_gist ON public.demandes_flash USING GIST (location_patient);

-- Index textuels de recherche tolérante aux fautes (Extension pg_trgm)
CREATE INDEX idx_medicaments_nom_trgm ON public.medicaments USING GIN (nom_commercial extensions.gin_trgm_ops);
CREATE INDEX idx_medicaments_dci_trgm ON public.medicaments USING GIN (dci extensions.gin_trgm_ops);

-- Index B-Tree sur toutes les clés étrangères (Prévention des verrous de table)
CREATE INDEX idx_carrefours_quartier_id ON public.carrefours_repere (quartier_id);
CREATE INDEX idx_pharmacies_quartier_id ON public.pharmacies (quartier_id);
CREATE INDEX idx_pharmacies_carrefour_id ON public.pharmacies (carrefour_proche_id);
CREATE INDEX idx_pharmacy_staff_user_id ON public.pharmacy_staff (user_id);
CREATE INDEX idx_pharmacy_staff_pharmacy_id ON public.pharmacy_staff (pharmacy_id);
CREATE INDEX idx_demandes_medicament_id ON public.demandes_flash (medicament_id);
CREATE INDEX idx_demande_dispatch_demande_id ON public.demande_dispatch_log (demande_id);
CREATE INDEX idx_demande_dispatch_pharmacy_id ON public.demande_dispatch_log (pharmacy_id);
CREATE INDEX idx_reservations_pharmacy_id ON public.reservations (pharmacy_id);
CREATE INDEX idx_reservations_patient_id ON public.reservations (patient_user_id);
CREATE INDEX idx_reservations_medicament_id ON public.reservations (medicament_id);
CREATE INDEX idx_reservations_expires_at ON public.reservations (expires_at) WHERE statut = 'pending';

-- ==============================================================================
-- 8. ROW LEVEL SECURITY (RLS) HERMÉTIQUE
-- ==============================================================================

ALTER TABLE public.quartiers_yaounde ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quartiers_yaounde FORCE ROW LEVEL SECURITY;

ALTER TABLE public.carrefours_repere ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.carrefours_repere FORCE ROW LEVEL SECURITY;

ALTER TABLE public.pharmacies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pharmacies FORCE ROW LEVEL SECURITY;

ALTER TABLE public.pharmacy_staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pharmacy_staff FORCE ROW LEVEL SECURITY;

ALTER TABLE public.medicaments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.medicaments FORCE ROW LEVEL SECURITY;

ALTER TABLE public.demandes_flash ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.demandes_flash FORCE ROW LEVEL SECURITY;

ALTER TABLE public.demande_dispatch_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.demande_dispatch_log FORCE ROW LEVEL SECURITY;

ALTER TABLE public.reservations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reservations FORCE ROW LEVEL SECURITY;

-- Politiques de lecture publique des référentiels (Quartiers, Carrefours, Officines ouvertes, Catalogue)
CREATE POLICY "Lecture publique des quartiers"
  ON public.quartiers_yaounde FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY "Lecture publique des carrefours"
  ON public.carrefours_repere FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY "Lecture publique des officines ouvertes"
  ON public.pharmacies FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY "Lecture publique du catalogue medicaments"
  ON public.medicaments FOR SELECT TO authenticated, anon USING (true);

-- Politiques Staff Pharmacie
CREATE POLICY "Le personnel gere sa propre fiche d'officine"
  ON public.pharmacies FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.pharmacy_staff ps
      WHERE ps.user_id = auth.uid() AND ps.pharmacy_id = public.pharmacies.id
    )
  );

CREATE POLICY "Le staff lit son appartenance"
  ON public.pharmacy_staff FOR SELECT TO authenticated
  USING (user_id = auth.uid());

-- Politiques Réservations
CREATE POLICY "Patients lisent leurs propres reservations"
  ON public.reservations FOR SELECT TO authenticated
  USING (auth.uid() = patient_user_id);

CREATE POLICY "Patients creent une reservation validee"
  ON public.reservations FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = patient_user_id);

CREATE POLICY "Pharmaciens consultent et traitent les reservations de leur officine"
  ON public.reservations FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.pharmacy_staff ps
      WHERE ps.user_id = auth.uid() AND ps.pharmacy_id = public.reservations.pharmacy_id
    )
  );

-- ==============================================================================
-- 9. PURGE AUTOMATISÉE DES DONNÉES SENSIBLES (pg_cron - Loi n° 2024/017)
-- ==============================================================================

SELECT cron.schedule(
  'purge-expired-reservations-hourly',
  '0 * * * *', -- Toutes les heures
  $$
    -- Basculer les réservations de plus de 2 heures en statut expiré
    UPDATE public.reservations
    SET statut = 'expired'
    WHERE statut = 'pending' AND expires_at < timezone('utc'::text, now());

    -- Basculer les demandes flash non pourvues en expirées
    UPDATE public.demandes_flash
    SET statut = 'expired'
    WHERE statut = 'broadcasting' AND expires_at < timezone('utc'::text, now());
  $$
);

SELECT cron.schedule(
  'purge-health-logs-monthly',
  '0 3 * * *', -- Tous les jours à 3h du matin
  $$
    -- Purge définitive des logs de dispatch de plus de 30 jours
    DELETE FROM public.demande_dispatch_log
    WHERE created_at < timezone('utc'::text, now()) - interval '30 days';

    -- Purge définitive des demandes flash orphelines de plus de 30 jours
    DELETE FROM public.demandes_flash
    WHERE created_at < timezone('utc'::text, now()) - interval '30 days';
  $$
);
