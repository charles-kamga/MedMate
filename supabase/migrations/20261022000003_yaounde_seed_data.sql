-- ==============================================================================
-- MedMate - Données Initiales de Référence (Yaoundé & Médicaments Cameroun)
-- Données réelles : Quartiers, Carrefours repères et Catalogue National
-- ==============================================================================

-- 1. Quartiers Majeurs de Yaoundé
INSERT INTO public.quartiers_yaounde (nom, arrondissement) VALUES
  ('Bastos', 'Yaoundé 1er'),
  ('Nlongkak', 'Yaoundé 1er'),
  ('Tsinga', 'Yaoundé 2e'),
  ('Mokolo', 'Yaoundé 2e'),
  ('Ngoa-Ekellé', 'Yaoundé 3e'),
  ('Obili', 'Yaoundé 3e'),
  ('Poste Centrale', 'Yaoundé 1er'),
  ('Essos', 'Yaoundé 5e'),
  ('Biyem-Assi', 'Yaoundé 6e'),
  ('Mendong', 'Yaoundé 6e'),
  ('Nsam', 'Yaoundé 3e'),
  ('Omnisports', 'Yaoundé 5e')
ON CONFLICT (nom) DO NOTHING;

-- 2. Carrefours et Points de Repères Célèbres de Yaoundé
WITH q AS (
  SELECT id, nom FROM public.quartiers_yaounde
)
INSERT INTO public.carrefours_repere (nom, quartier_id, location, description_acces) VALUES
  (
    'Carrefour Warda',
    (SELECT id FROM q WHERE nom = 'Poste Centrale'),
    ST_SetSRID(ST_MakePoint(11.5175, 3.8688), 4326)::geography,
    'Face au Bois Sainte-Anastasie, nœud central entre le centre-ville et Bastos'
  ),
  (
    'Rond-Point Poste Centrale',
    (SELECT id FROM q WHERE nom = 'Poste Centrale'),
    ST_SetSRID(ST_MakePoint(11.5200, 3.8667), 4326)::geography,
    'Cœur commercial et administratif de Yaoundé'
  ),
  (
    'Carrefour Obili',
    (SELECT id FROM q WHERE nom = 'Obili'),
    ST_SetSRID(ST_MakePoint(11.4920, 3.8540), 4326)::geography,
    'Zone universitaire, carrefour chapelle Obili vers Ngoa-Ekellé'
  ),
  (
    'Carrefour Nlongkak',
    (SELECT id FROM q WHERE nom = 'Nlongkak'),
    ST_SetSRID(ST_MakePoint(11.5250, 3.8833), 4326)::geography,
    'Rond-point Nlongkak vers Dragages et Bastos'
  ),
  (
    'Carrefour Biyem-Assi (Acacia)',
    (SELECT id FROM q WHERE nom = 'Biyem-Assi'),
    ST_SetSRID(ST_MakePoint(11.4880, 3.8375), 4326)::geography,
    'Carrefour Acacia, axe commerçant dense vers Mendong et Rond-Point Express'
  ),
  (
    'Carrefour EMIA',
    (SELECT id FROM q WHERE nom = 'Ngoa-Ekellé'),
    ST_SetSRID(ST_MakePoint(11.5050, 3.8610), 4326)::geography,
    'Axe École Militaire Interarmées et CHU de Yaoundé'
  ),
  (
    'Marché Mokolo (Entrée Principale)',
    (SELECT id FROM q WHERE nom = 'Mokolo'),
    ST_SetSRID(ST_MakePoint(11.5020, 3.8740), 4326)::geography,
    'Zone de grand trafic vers Madagascar et Tsinga'
  );

-- 3. Officines de Référence à Yaoundé
WITH q AS (SELECT id, nom FROM public.quartiers_yaounde),
     c AS (SELECT id, nom FROM public.carrefours_repere)
INSERT INTO public.pharmacies (
  nom, licence_onpc, quartier_id, carrefour_proche_id, location, adresse_detaillee, telephone_garde, est_ouverte, est_de_garde
) VALUES
  (
    'Grande Pharmacie du Centre',
    'ONPC-YDE-0042',
    (SELECT id FROM q WHERE nom = 'Poste Centrale'),
    (SELECT id FROM c WHERE nom = 'Rond-Point Poste Centrale'),
    ST_SetSRID(ST_MakePoint(11.5205, 3.8665), 4326)::geography,
    'Avenue Kennedy, en face de la Cathédrale Notre-Dame',
    '+237699112233',
    true,
    true
  ),
  (
    'Pharmacie du Soleil',
    'ONPC-YDE-0105',
    (SELECT id FROM q WHERE nom = 'Poste Centrale'),
    (SELECT id FROM c WHERE nom = 'Carrefour Warda'),
    ST_SetSRID(ST_MakePoint(11.5170, 3.8692), 4326)::geography,
    'Boulevard du 20 Mai, à proximité du carrefour Warda',
    '+237677445566',
    true,
    false
  ),
  (
    'Pharmacie d''Obili',
    'ONPC-YDE-0211',
    (SELECT id FROM q WHERE nom = 'Obili'),
    (SELECT id FROM c WHERE nom = 'Carrefour Obili'),
    ST_SetSRID(ST_MakePoint(11.4925, 3.8542), 4326)::geography,
    'Carrefour Chapelle Obili, face collège Vogt',
    '+237695332211',
    true,
    true
  ),
  (
    'Pharmacie Acacia Biyem-Assi',
    'ONPC-YDE-0188',
    (SELECT id FROM q WHERE nom = 'Biyem-Assi'),
    (SELECT id FROM c WHERE nom = 'Carrefour Biyem-Assi (Acacia)'),
    ST_SetSRID(ST_MakePoint(11.4885, 3.8372), 4326)::geography,
    'Carrefour Acacia, Montée Biyem-Assi',
    '+237670998877',
    true,
    false
  );

-- 4. Catalogue National Homologué des Médicaments Essentiels (Cameroun)
INSERT INTO public.medicaments (
  nom_commercial, dci, forme, dosage, classe_therapeutique, prix_homologue_cfa, necessite_ordonnance, code_national
) VALUES
  (
    'Doliprane 1000mg',
    'Paracétamol',
    'Comprimé effervescent',
    '1000 mg',
    'Antalgique / Antipyrétique',
    1500,
    false,
    'CAM-MED-001'
  ),
  (
    'Efferalgan 500mg',
    'Paracétamol',
    'Comprimé',
    '500 mg',
    'Antalgique / Antipyrétique',
    1200,
    false,
    'CAM-MED-002'
  ),
  (
    'Coartem 20/120',
    'Artéméther + Luméfantrine',
    'Comprimé',
    '20 mg / 120 mg',
    'Antipaludique (CTA)',
    2800,
    false,
    'CAM-MED-003'
  ),
  (
    'Clamoxyl 500mg',
    'Amoxicilline',
    'Gélule',
    '500 mg',
    'Antibiotique Bêta-lactamine',
    3200,
    true,
    'CAM-MED-004'
  ),
  (
    'Advil 400mg',
    'Ibuprofène',
    'Capsule molle',
    '400 mg',
    'Anti-inflammatoire non stéroïdien (AINS)',
    2400,
    false,
    'CAM-MED-005'
  ),
  (
    'Oralyte (SRO)',
    'Sels de Réhydratation Orale',
    'Sachet pour solution buvable',
    'Sachet 20.5 g',
    'Réhydratation',
    400,
    false,
    'CAM-MED-006'
  ),
  (
    'Ciflox 500mg',
    'Ciprofloxacine',
    'Comprimé pelliculé',
    '500 mg',
    'Antibiotique Fluoroquinolone',
    4500,
    true,
    'CAM-MED-007'
  ),
  (
    'Mopral 20mg',
    'Oméprazole',
    'Gélule gastro-résistante',
    '20 mg',
    'Antiulcéreux / Inhibiteur de la pompe à protons',
    3800,
    false,
    'CAM-MED-008'
  )
ON CONFLICT (code_national) DO NOTHING;
