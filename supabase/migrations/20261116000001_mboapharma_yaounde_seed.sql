-- ==============================================================================
-- Afya-Health (ex-MedMate) - Seed Données Réelles MboaPHARMA (Yaoundé)
-- 21 Pharmacies de garde actives + Coordonnées GPS précises Zone Pilote Melen/Ngoa-Ekellé
-- Conformité Database Guard : PostGIS ST_MakePoint(lng, lat), RLS & Idempotence
-- ==============================================================================

-- 1. Quartiers complémentaires de Yaoundé
INSERT INTO public.quartiers_yaounde (nom, arrondissement) VALUES
  ('Melen', 'Yaoundé 3e'),
  ('Emombo', 'Yaoundé 4e'),
  ('Nkondongo', 'Yaoundé 4e'),
  ('Madagascar', 'Yaoundé 2e'),
  ('Nsimeyong', 'Yaoundé 3e'),
  ('Jamot', 'Yaoundé 1er'),
  ('Olembe', 'Yaoundé 1er'),
  ('Ngousso', 'Yaoundé 5e'),
  ('Nkomo', 'Yaoundé 4e'),
  ('Nkondengui', 'Yaoundé 4e'),
  ('Messamendongo', 'Yaoundé 4e'),
  ('Odza', 'Yaoundé 4e')
ON CONFLICT (nom) DO NOTHING;

-- 2. Carrefours repères Zone Pilote & Yaoundé
WITH q AS (SELECT id, nom FROM public.quartiers_yaounde)
INSERT INTO public.carrefours_repere (nom, quartier_id, location, description_acces) VALUES
  (
    'Carrefour Melen / CHU',
    (SELECT id FROM q WHERE nom = 'Melen'),
    ST_SetSRID(ST_MakePoint(11.4870, 3.8539), 4326)::geography,
    'Face au Centre Hospitalier Universitaire (CHU) de Yaoundé - Cœur zone pilote Afya-Health'
  ),
  (
    'Ngoa-Ekellé (ENSP / Campus)',
    (SELECT id FROM q WHERE nom = 'Ngoa-Ekellé'),
    ST_SetSRID(ST_MakePoint(11.5003, 3.8622), 4326)::geography,
    'Campus Université Yaoundé I & École Nationale Supérieure Polytechnique'
  )
ON CONFLICT DO NOTHING;

-- 3. Insertion / Mise à jour des 21 Pharmacies de Garde MboaPHARMA + Pilote Melen/Obili
WITH q AS (SELECT id, nom FROM public.quartiers_yaounde)
INSERT INTO public.pharmacies (
  nom, licence_onpc, quartier_id, location, adresse_detaillee, telephone_garde, telephone_secondaire, est_ouverte, est_de_garde
) VALUES
  -- Zone 1
  (
    'Pharmacie Saint Martin',
    'ONPC-MBOA-001',
    (SELECT id FROM q WHERE nom = 'Poste Centrale'),
    ST_SetSRID(ST_MakePoint(11.5200, 3.8667), 4326)::geography,
    'À côté Katios, Centre-ville',
    '+237222231869',
    NULL,
    true,
    true
  ),
  -- Zone 2
  (
    'Pharmacie Hortensia',
    'ONPC-MBOA-002',
    (SELECT id FROM q WHERE nom = 'Tsinga'),
    ST_SetSRID(ST_MakePoint(11.5050, 3.8820), 4326)::geography,
    'Face Polyclinique Tsinga',
    '+237243607984',
    '+237698648095',
    true,
    true
  ),
  (
    'Pharmacie K''Four Moto Georges',
    'ONPC-MBOA-003',
    (SELECT id FROM q WHERE nom = 'Tsinga'),
    ST_SetSRID(ST_MakePoint(11.5010, 3.8780), 4326)::geography,
    'Carrefour Moto Georges, Tsinga',
    '+237242192827',
    '+237698010519',
    true,
    true
  ),
  -- Zone 3
  (
    'Pharmacie Isis',
    'ONPC-MBOA-004',
    (SELECT id FROM q WHERE nom = 'Emombo'),
    ST_SetSRID(ST_MakePoint(11.548491, 3.864770), 4326)::geography,
    'Emombo 2e Carrefour',
    '+237222233578',
    NULL,
    true,
    true
  ),
  -- Zone 4
  (
    'Pharmacie Chekem',
    'ONPC-MBOA-005',
    (SELECT id FROM q WHERE nom = 'Essos'),
    ST_SetSRID(ST_MakePoint(11.5380, 3.8710), 4326)::geography,
    'Face Sun City, Essos',
    '+237672518919',
    NULL,
    true,
    true
  ),
  (
    'Pharmacie Grande Famille',
    'ONPC-MBOA-006',
    (SELECT id FROM q WHERE nom = 'Essos'),
    ST_SetSRID(ST_MakePoint(11.5410, 3.8735), 4326)::geography,
    'Nouvelle Route Fougerole, à 200m du Groupe Scolaire André Malraux',
    '+237653250276',
    '+237640779942',
    true,
    true
  ),
  -- Zone 5
  (
    'Pharmacie Nkondongo',
    'ONPC-MBOA-007',
    (SELECT id FROM q WHERE nom = 'Nkondongo'),
    ST_SetSRID(ST_MakePoint(11.5360, 3.8550), 4326)::geography,
    'Nkondongo École',
    '+237683055608',
    '+237658570866',
    true,
    true
  ),
  (
    'Pharmacie La Rose',
    'ONPC-MBOA-008',
    (SELECT id FROM q WHERE nom = 'Nsam'),
    ST_SetSRID(ST_MakePoint(11.5120, 3.8290), 4326)::geography,
    'Nsam Escale',
    '+237683086695',
    NULL,
    true,
    true
  ),
  -- Zone 6
  (
    'Pharmacie Moliva',
    'ONPC-MBOA-009',
    (SELECT id FROM q WHERE nom = 'Madagascar'),
    ST_SetSRID(ST_MakePoint(11.4980, 3.8760), 4326)::geography,
    'Mobil (Oil Lybia) Madagascar',
    '+237650649072',
    NULL,
    true,
    true
  ),
  -- Zone 7 : ZONE PILOTE PRINCIPALE
  (
    'Pharmacie Mandela',
    'ONPC-MBOA-010',
    (SELECT id FROM q WHERE nom = 'Melen'),
    ST_SetSRID(ST_MakePoint(11.487012, 3.853898), 4326)::geography,
    'Face CHU de Yaoundé (Melen)',
    '+237242792985',
    NULL,
    true,
    true
  ),
  -- Zone 8
  (
    'Pharmacie Well',
    'ONPC-MBOA-011',
    (SELECT id FROM q WHERE nom = 'Biyem-Assi'),
    ST_SetSRID(ST_MakePoint(11.485219, 3.837638), 4326)::geography,
    'Rond-Point Express / Face Niki Biyem-Assi',
    '+237698987832',
    NULL,
    true,
    true
  ),
  (
    'Pharmacie Grâce',
    'ONPC-MBOA-012',
    (SELECT id FROM q WHERE nom = 'Mendong'),
    ST_SetSRID(ST_MakePoint(11.4780, 3.8310), 4326)::geography,
    'Mendong - Quincaillerie de la Paix',
    '+237242041561',
    NULL,
    true,
    true
  ),
  -- Zone 9
  (
    'Pharmacie des Acacias',
    'ONPC-MBOA-013',
    (SELECT id FROM q WHERE nom = 'Biyem-Assi'),
    ST_SetSRID(ST_MakePoint(11.487958, 3.841540), 4326)::geography,
    'Biyem-Assi Centre, Carrefour Acacias',
    '+237671038945',
    NULL,
    true,
    true
  ),
  (
    'Pharmacie Nsimeyong',
    'ONPC-MBOA-014',
    (SELECT id FROM q WHERE nom = 'Nsimeyong'),
    ST_SetSRID(ST_MakePoint(11.494335, 3.836074), 4326)::geography,
    'Chapelle Nsimeyong',
    '+237694011246',
    '+237620263689',
    true,
    true
  ),
  -- Zone 10
  (
    'Pharmacie Cana',
    'ONPC-MBOA-015',
    (SELECT id FROM q WHERE nom = 'Jamot'),
    ST_SetSRID(ST_MakePoint(11.5210, 3.8910), 4326)::geography,
    'Carrefour Jamot',
    '+237222209751',
    NULL,
    true,
    true
  ),
  (
    'Pharmacie Dignité',
    'ONPC-MBOA-016',
    (SELECT id FROM q WHERE nom = 'Olembe'),
    ST_SetSRID(ST_MakePoint(11.5230, 3.9210), 4326)::geography,
    'Olembe - Entrée École',
    '+237651531283',
    '+237697682688',
    true,
    true
  ),
  -- Zone 11
  (
    'Pharmacie Bleue Plus',
    'ONPC-MBOA-017',
    (SELECT id FROM q WHERE nom = 'Ngousso'),
    ST_SetSRID(ST_MakePoint(11.5450, 3.8890), 4326)::geography,
    'Face Hôpital Général, Ngousso',
    '+237656036467',
    '+237682315085',
    true,
    true
  ),
  -- Zone 12
  (
    'Pharmacie Sainte Élisabeth de Nkomo',
    'ONPC-MBOA-018',
    (SELECT id FROM q WHERE nom = 'Nkomo'),
    ST_SetSRID(ST_MakePoint(11.5620, 3.8480), 4326)::geography,
    'Carrefour Nkomo, Face Boulangerie Fontana',
    '+237243153058',
    NULL,
    true,
    true
  ),
  (
    'Pharmacie Thériaque',
    'ONPC-MBOA-019',
    (SELECT id FROM q WHERE nom = 'Nkondengui'),
    ST_SetSRID(ST_MakePoint(11.5510, 3.8540), 4326)::geography,
    'À côté Sous-Préfecture Nkondengui',
    '+237679680511',
    '+237695764115',
    true,
    true
  ),
  -- Zone 13
  (
    'Pharmacie Messamendongo',
    'ONPC-MBOA-020',
    (SELECT id FROM q WHERE nom = 'Messamendongo'),
    ST_SetSRID(ST_MakePoint(11.5430, 3.8210), 4326)::geography,
    'Carrefour Messamendongo',
    '+237693055375',
    '+237650265141',
    true,
    true
  ),
  (
    'Pharmacie Odza',
    'ONPC-MBOA-021',
    (SELECT id FROM q WHERE nom = 'Odza'),
    ST_SetSRID(ST_MakePoint(11.5380, 3.8150), 4326)::geography,
    'Carrefour Mbog-Abang, Odza',
    '+237685327385',
    NULL,
    true,
    true
  ),
  -- Officines de jour clés de la zone pilote
  (
    'Pharmacie Melen 8',
    'ONPC-MBOA-PILOT-01',
    (SELECT id FROM q WHERE nom = 'Melen'),
    ST_SetSRID(ST_MakePoint(11.486503, 3.850888), 4326)::geography,
    'Melen 8, Axe Melen - Mini Ferme',
    '',
    NULL,
    true,
    false
  ),
  (
    'Pharmacie Chapelle Obili',
    'ONPC-MBOA-PILOT-02',
    (SELECT id FROM q WHERE nom = 'Obili'),
    ST_SetSRID(ST_MakePoint(11.493457, 3.850930), 4326)::geography,
    'Face Chapelle Obili, Carrefour Obili',
    '',
    NULL,
    true,
    false
  ),
  (
    'Pharmacie de Biyem-Assi',
    'ONPC-MBOA-PILOT-03',
    (SELECT id FROM q WHERE nom = 'Biyem-Assi'),
    ST_SetSRID(ST_MakePoint(11.485264, 3.837717), 4326)::geography,
    'Biyem-Assi Montée',
    '',
    NULL,
    true,
    false
  )
ON CONFLICT (licence_onpc) DO UPDATE SET
  nom = EXCLUDED.nom,
  quartier_id = EXCLUDED.quartier_id,
  location = EXCLUDED.location,
  adresse_detaillee = EXCLUDED.adresse_detaillee,
  telephone_garde = EXCLUDED.telephone_garde,
  telephone_secondaire = EXCLUDED.telephone_secondaire,
  est_ouverte = EXCLUDED.est_ouverte,
  est_de_garde = EXCLUDED.est_de_garde,
  updated_at = timezone('utc'::text, now());
