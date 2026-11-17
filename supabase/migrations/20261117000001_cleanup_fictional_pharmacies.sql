-- ==============================================================================
-- Afya-Health - Nettoyage des 4 officines fictives du seed initial (ONPC-YDE-*)
-- Idempotent : sûr même si 20261022000003 a déjà été rejouée en base.
-- Respecte la contrainte FK ON DELETE RESTRICT sur public.reservations.
-- ==============================================================================

-- 1. Supprime les officines fictives qui n'ont aucune réservation liée
DELETE FROM public.pharmacies p
WHERE p.licence_onpc IN (
  'ONPC-YDE-0042',
  'ONPC-YDE-0105',
  'ONPC-YDE-0211',
  'ONPC-YDE-0188'
)
AND NOT EXISTS (
  SELECT 1
  FROM public.reservations r
  WHERE r.pharmacy_id = p.id
);

-- 2. Si une officine fictive était déjà référencée par une réservation historique,
--    la désactive hors ligne et hors garde pour ne jamais l'exposer aux patients.
UPDATE public.pharmacies
SET
  est_ouverte = false,
  est_de_garde = false,
  updated_at = timezone('utc'::text, now())
WHERE licence_onpc IN (
  'ONPC-YDE-0042',
  'ONPC-YDE-0105',
  'ONPC-YDE-0211',
  'ONPC-YDE-0188'
);
