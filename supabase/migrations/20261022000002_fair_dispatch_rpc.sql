-- ==============================================================================
-- MedMate - Algorithme de Dispatch Équitable (Conformité Déontologique ONPC)
-- Respect de la Loi n° 90-035 et neutralité stricte par Round-Robin pondéré
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.calculate_fair_dispatch(
  p_demande_id UUID,
  p_patient_lat DOUBLE PRECISION,
  p_patient_lon DOUBLE PRECISION,
  p_max_distance_meters INTEGER DEFAULT 3500,
  p_target_officines_count INTEGER DEFAULT 3
)
RETURNS TABLE (
  pharmacy_id UUID,
  pharmacy_name VARCHAR,
  distance_meters DOUBLE PRECISION,
  telephone_garde VARCHAR,
  quartier_name VARCHAR,
  carrefour_name VARCHAR
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_patient_geo GEOGRAPHY;
BEGIN
  -- Construire le point géographique WGS84 du patient
  v_patient_geo := ST_SetSRID(ST_MakePoint(p_patient_lon, p_patient_lat), 4326)::geography;

  -- 1. Sélectionner les officines éligibles par proximité et disponibilité
  -- 2. Appliquer la neutralité Round-Robin basée sur le volume de dispatch des 24h passées
  RETURN QUERY
  WITH eligible_pharmacies AS (
    SELECT 
      p.id AS p_id,
      p.nom AS p_nom,
      p.telephone_garde AS p_tel,
      q.nom AS q_nom,
      COALESCE(c.nom, 'Proximité immédiate') AS c_nom,
      ST_Distance(p.location, v_patient_geo) AS dist_m,
      -- Compter les attributions reçues sur les dernières 24h pour la rotation équitable
      (
        SELECT COUNT(*)
        FROM public.demande_dispatch_log ddl
        WHERE ddl.pharmacy_id = p.id
          AND ddl.created_at >= (timezone('utc'::text, now()) - interval '24 hours')
      ) AS recent_dispatches_count
    FROM public.pharmacies p
    JOIN public.quartiers_yaounde q ON q.id = p.quartier_id
    LEFT JOIN public.carrefours_repere c ON c.id = p.carrefour_proche_id
    WHERE (p.est_ouverte = true OR p.est_de_garde = true)
      AND ST_DWithin(p.location, v_patient_geo, p_max_distance_meters)
  ),
  selected_candidates AS (
    SELECT 
      ep.p_id,
      ep.p_nom,
      ep.dist_m,
      ep.p_tel,
      ep.q_nom,
      ep.c_nom
    FROM eligible_pharmacies ep
    -- Tri par rotation équitable (priorité à celles ayant reçu le moins de demandes), puis distance
    ORDER BY 
      ep.recent_dispatches_count ASC,
      ep.dist_m ASC
    LIMIT p_target_officines_count
  )
  -- Enregistrer l'attribution dans le log pour les prochaines rotations
  , inserted_logs AS (
    INSERT INTO public.demande_dispatch_log (demande_id, pharmacy_id, notified_via, statut_reponse)
    SELECT p_demande_id, sc.p_id, 'realtime', 'pending'
    FROM selected_candidates sc
    ON CONFLICT DO NOTHING
  )
  SELECT 
    sc.p_id AS pharmacy_id,
    sc.p_nom AS pharmacy_name,
    sc.dist_m AS distance_meters,
    sc.p_tel AS telephone_garde,
    sc.q_nom AS quartier_name,
    sc.c_nom AS carrefour_name
  FROM selected_candidates sc;

END;
$$;
