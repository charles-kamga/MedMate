-- ==============================================================================
-- MedMate - Migration Étape 5: Realtime Dispatching & Offline Resilience
-- Tables: public.flash_orders, public.pharmacy_quotes
-- Compliance: PostGIS, pg_trgm, Row Level Security, Supabase Realtime Publication
-- Strict Law Compliance: Loi n° 2024/017 (Protection données santé) & ONPC Neutrality
-- ==============================================================================

-- 1. Extensions Requises
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "pg_trgm" WITH SCHEMA extensions;

-- ==============================================================================
-- 2. Table: public.flash_orders (Commandes Flash & Suivi de Dispatching en Vagues)
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.flash_orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  quarter VARCHAR(150) NOT NULL,
  carrefour_repere_id UUID REFERENCES public.carrefours_repere(id) ON DELETE SET NULL,
  location_patient GEOGRAPHY(Point, 4326),
  items JSONB NOT NULL DEFAULT '[]'::jsonb,
  targets JSONB NOT NULL DEFAULT '[]'::jsonb,
  current_wave INTEGER NOT NULL DEFAULT 1 CHECK (current_wave >= 1),
  wave_time_remaining_seconds INTEGER NOT NULL DEFAULT 120,
  status VARCHAR(50) NOT NULL DEFAULT 'dispatchingWave',
  payment_method VARCHAR(50),
  payment_status VARCHAR(50) NOT NULL DEFAULT 'pending',
  phone_number VARCHAR(30),
  reservation_otp_code VARCHAR(6),
  selected_offer_id UUID,
  is_picked_up BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (timezone('utc'::text, now()) + interval '2 hours'),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- ==============================================================================
-- 3. Table: public.pharmacy_quotes (Devis et Réponses d'Officines aux Vagues)
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.pharmacy_quotes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id UUID NOT NULL REFERENCES public.flash_orders(id) ON DELETE CASCADE,
  pharmacy_id UUID NOT NULL REFERENCES public.pharmacies(id) ON DELETE CASCADE,
  pharmacy_name VARCHAR(255) NOT NULL,
  quarter VARCHAR(150) NOT NULL,
  distance_km DOUBLE PRECISION NOT NULL DEFAULT 0.0 CHECK (distance_km >= 0),
  phone VARCHAR(30) NOT NULL,
  availability_type VARCHAR(50) NOT NULL DEFAULT 'fullyAvailable',
  quoted_price_cfa INTEGER NOT NULL CHECK (quoted_price_cfa >= 0),
  available_item_ids JSONB NOT NULL DEFAULT '[]'::jsonb,
  missing_item_ids JSONB NOT NULL DEFAULT '[]'::jsonb,
  condition_requirements JSONB NOT NULL DEFAULT '[]'::jsonb,
  condition_note TEXT,
  proposes_delivery BOOLEAN NOT NULL DEFAULT false,
  delivery_fee_cfa INTEGER NOT NULL DEFAULT 0 CHECK (delivery_fee_cfa >= 0),
  estimated_delivery_minutes INTEGER CHECK (estimated_delivery_minutes IS NULL OR estimated_delivery_minutes >= 0),
  is_accepted BOOLEAN NOT NULL DEFAULT false,
  submitted_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- ==============================================================================
-- 4. Indexation Haute Performance (PostGIS GIST & BTREE Clés Étrangères)
-- ==============================================================================

-- Spatial GIST Index
CREATE INDEX IF NOT EXISTS idx_flash_orders_location_gist
  ON public.flash_orders USING GIST (location_patient);

-- Foreign Key & Filter Indexes
CREATE INDEX IF NOT EXISTS idx_flash_orders_patient_id
  ON public.flash_orders (patient_id);

CREATE INDEX IF NOT EXISTS idx_flash_orders_carrefour_repere_id
  ON public.flash_orders (carrefour_repere_id);

CREATE INDEX IF NOT EXISTS idx_flash_orders_status
  ON public.flash_orders (status);

CREATE INDEX IF NOT EXISTS idx_flash_orders_created_at
  ON public.flash_orders (created_at DESC);

CREATE INDEX IF NOT EXISTS idx_pharmacy_quotes_order_id
  ON public.pharmacy_quotes (order_id);

CREATE INDEX IF NOT EXISTS idx_pharmacy_quotes_pharmacy_id
  ON public.pharmacy_quotes (pharmacy_id);

CREATE INDEX IF NOT EXISTS idx_pharmacy_quotes_submitted_at
  ON public.pharmacy_quotes (submitted_at DESC);

-- ==============================================================================
-- 5. Row Level Security (RLS) Stricte & Hermétique
-- ==============================================================================

ALTER TABLE public.flash_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.flash_orders FORCE ROW LEVEL SECURITY;

ALTER TABLE public.pharmacy_quotes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pharmacy_quotes FORCE ROW LEVEL SECURITY;

-- Politiques flash_orders pour les patients
CREATE POLICY "Patients lisent leurs commandes flash"
  ON public.flash_orders FOR SELECT TO authenticated, anon
  USING (
    patient_id IS NULL OR
    (auth.uid() IS NOT NULL AND auth.uid() = patient_id)
  );

CREATE POLICY "Patients creent des commandes flash"
  ON public.flash_orders FOR INSERT TO authenticated, anon
  WITH CHECK (
    patient_id IS NULL OR
    (auth.uid() IS NOT NULL AND auth.uid() = patient_id)
  );

CREATE POLICY "Patients et officiers mettent a jour leurs commandes"
  ON public.flash_orders FOR UPDATE TO authenticated, anon
  USING (
    patient_id IS NULL OR
    (auth.uid() IS NOT NULL AND auth.uid() = patient_id) OR
    EXISTS (
      SELECT 1 FROM public.pharmacy_staff ps
      WHERE ps.user_id = auth.uid()
    )
  );

-- Politiques flash_orders pour les pharmaciens (inbox des vagues)
CREATE POLICY "Pharmaciens consultent les commandes assignees"
  ON public.flash_orders FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.pharmacy_staff ps
      WHERE ps.user_id = auth.uid()
    )
  );

-- Politiques pharmacy_quotes pour patients et pharmaciens
CREATE POLICY "Lecture des devis de commande"
  ON public.pharmacy_quotes FOR SELECT TO authenticated, anon
  USING (
    EXISTS (
      SELECT 1 FROM public.flash_orders fo
      WHERE fo.id = public.pharmacy_quotes.order_id
        AND (fo.patient_id IS NULL OR fo.patient_id = auth.uid())
    ) OR
    EXISTS (
      SELECT 1 FROM public.pharmacy_staff ps
      WHERE ps.user_id = auth.uid() AND ps.pharmacy_id = public.pharmacy_quotes.pharmacy_id
    )
  );

CREATE POLICY "Pharmaciens soumettent des devis"
  ON public.pharmacy_quotes FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.pharmacy_staff ps
      WHERE ps.user_id = auth.uid() AND ps.pharmacy_id = public.pharmacy_quotes.pharmacy_id
    )
  );

CREATE POLICY "Mise a jour devis par pharmacie ou selection patient"
  ON public.pharmacy_quotes FOR UPDATE TO authenticated, anon
  USING (
    EXISTS (
      SELECT 1 FROM public.pharmacy_staff ps
      WHERE ps.user_id = auth.uid() AND ps.pharmacy_id = public.pharmacy_quotes.pharmacy_id
    ) OR
    EXISTS (
      SELECT 1 FROM public.flash_orders fo
      WHERE fo.id = public.pharmacy_quotes.order_id
        AND (fo.patient_id IS NULL OR fo.patient_id = auth.uid())
    )
  );

-- ==============================================================================
-- 6. Supabase Realtime Publication
-- ==============================================================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime'
  ) THEN
    CREATE PUBLICATION supabase_realtime;
  END IF;
END $$;

ALTER PUBLICATION supabase_realtime ADD TABLE public.flash_orders, public.pharmacy_quotes;
