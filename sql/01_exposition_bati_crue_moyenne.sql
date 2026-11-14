-- Observatoire de l'exposition au risque inondation - Val-de-Marne (94)
-- Script 01 : exposition du bâti à la crue moyenne (scénario centennal du TRI)
--
-- Base : PostgreSQL 18 + PostGIS 3.6
-- Données (chargées au préalable dans le schéma "source" via QGIS) :
--   - source.batiment     : BD TOPO v3.5 IGN, département 094, édition 2026-09-15
--   - source.commune      : BD TOPO v3.5 IGN, département 094, édition 2026-09-15
--   - source.tri_hauteurs : TRI Métropole francilienne, classes de hauteur d'eau
--                           (Directive inondation), géométries réparées dans QGIS
-- Système de coordonnées : Lambert-93 (EPSG:2154)
-- =============================================================================


-- 0. Préparation de la base ---------------------------------------------------
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE SCHEMA IF NOT EXISTS source;     -- données brutes
CREATE SCHEMA IF NOT EXISTS resultats;  -- tables calculées


-- 1. Contrôle du chargement ---------------------------------------------------
-- Attendu : 22 zones TRI ; communes et bâtiments incluant les communes voisines
SELECT 'batiment' AS table_, count(*) FROM source.batiment
UNION ALL SELECT 'commune', count(*) FROM source.commune
UNION ALL SELECT 'tri_hauteurs', count(*) FROM source.tri_hauteurs;

-- Attendu : 47 communes dans le Val-de-Marne
SELECT count(*) FROM source.commune
WHERE code_insee_du_departement = '94';


-- 2. Découpage des zones inondables -------------------------------------------
-- Les 22 polygones du TRI couvrent tout le territoire : leur rectangle englobant
-- rend l'index spatial inefficace. ST_Subdivide les découpe en morceaux de
-- 255 sommets maximum pour accélérer les intersections.
-- On ne garde que la Seine et la Marne (l'Oise ne traverse pas le 94).
DROP TABLE IF EXISTS resultats.tri_decoupe;

CREATE TABLE resultats.tri_decoupe AS
SELECT id_zone, scenario, ht_min, ht_max, legende,
       ST_Subdivide(geom, 255) AS geom
FROM source.tri_hauteurs
WHERE cours_deau = 'SEINE ET MARNE';

CREATE INDEX ON resultats.tri_decoupe USING GIST (geom);

-- Nombre de morceaux par scénario (01For = fréquent, 02Moy = moyen, 04Fai = extrême)
SELECT scenario, count(*)
FROM resultats.tri_decoupe
GROUP BY scenario
ORDER BY scenario;


-- 3. Bâtiments exposés à la crue moyenne --------------------------------------
-- Un bâtiment est "exposé" si son emprise touche la zone inondable du scénario
-- moyen. EXISTS évite les doublons quand un bâtiment touche plusieurs morceaux
-- ou plusieurs classes de hauteur.
DROP TABLE IF EXISTS resultats.bati_expose_moyen;

CREATE TABLE resultats.bati_expose_moyen AS
SELECT b.cleabs, b.usage_1, b.nombre_de_logements, b.geom
FROM source.batiment b
WHERE EXISTS (
  SELECT 1
  FROM resultats.tri_decoupe t
  WHERE t.scenario = '02Moy'
    AND ST_Intersects(t.geom, b.geom)
);

CREATE INDEX ON resultats.bati_expose_moyen (cleabs);

SELECT count(*) FROM resultats.bati_expose_moyen;


-- 4a. Rattachement de chaque bâtiment du Val-de-Marne à sa commune ------------
-- ST_PointOnSurface : un point garanti à l'intérieur du bâtiment, pour qu'un
-- bâtiment à cheval sur une limite communale ne soit compté qu'une fois.
DROP TABLE IF EXISTS resultats.bati_commune;

CREATE TABLE resultats.bati_commune AS
SELECT b.cleabs, c.code_insee, c.nom_officiel
FROM source.batiment b
JOIN source.commune c
  ON ST_Intersects(c.geom, ST_PointOnSurface(b.geom))
WHERE c.code_insee_du_departement = '94';

CREATE INDEX ON resultats.bati_commune (cleabs);


-- 4b. Classement des communes par nombre de bâtiments exposés -----------------
SELECT bc.nom_officiel AS commune,
       count(*) AS nb_batiments,
       count(e.cleabs) AS nb_exposes,
       round(100.0 * count(e.cleabs) / count(*), 1) AS pct_exposes,
       sum(e.nombre_de_logements) AS logements_exposes
FROM resultats.bati_commune bc
LEFT JOIN resultats.bati_expose_moyen e ON e.cleabs = bc.cleabs
GROUP BY bc.nom_officiel
HAVING count(e.cleabs) > 0
ORDER BY nb_exposes DESC;
