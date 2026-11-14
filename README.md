# Observatoire de l'exposition au risque inondation

**Statut : en cours de développement (lancé en octobre 2026) – étape 1 terminée**

Plateforme qui calcule automatiquement, pour chaque commune d'un département, l'exposition du bâti et des équipements sensibles aux zones inondables, stocke les résultats dans PostGIS et les affiche sur une carte web interactive.

Territoire d'étude : **Val-de-Marne (94)**

## Objectifs

- Construire un pipeline de données reproductible, paramétrable par code département
- Produire des indicateurs d'exposition par commune : nombre de bâtiments exposés, établissements sensibles, part du bâti en zone inondable
- Restituer les résultats sur une carte web interactive

## Données (toutes ouvertes)

| Source | Contenu | Version utilisée |
| --- | --- | --- |
| BD TOPO (IGN) | Bâtiments, communes | v3.5, département 94, édition du 15/09/2026 |
| TRI Métropole francilienne (Directive inondation, DRIEAT Île-de-France, via data.gouv.fr) | Zones inondables par scénario de crue et classe de hauteur d'eau | cartographie de 2013 |
| INSEE (données carroyées) | Population | prévu (optionnel) |

Les fichiers de données ne sont pas stockés dans ce dépôt (voir la section Reproduire).

## Architecture

1. Téléchargement des données ouvertes (IGN, data.gouv.fr)
2. Nettoyage et préparation (QGIS pour l'étape 1, Python/GeoPandas à partir de l'étape 2)
3. Stockage dans une base PostgreSQL/PostGIS : schéma `source` pour les données brutes, schéma `resultats` pour les tables calculées
4. Calcul des indicateurs en SQL
5. Affichage sur une carte web interactive (MapLibre)

## Feuille de route

- **Étape 1 – Base de données (terminée)** : base PostgreSQL 18 / PostGIS 3.6, chargement des données du Val-de-Marne, index spatiaux, premières requêtes SQL spatiales
- **Étape 2 – Pipeline ETL (à venir)** : téléchargement, nettoyage et chargement automatisés en Python, configuration, logs, gestion d'erreurs
- **Étape 3 – Indicateurs (à venir)** : vues SQL par commune et par scénario, exécution automatisée, carte de synthèse sous QGIS
- **Étape 4 – Restitution (à venir)** : carte web interactive, documentation, résultats

## Premiers résultats : crue moyenne, Val-de-Marne

Le scénario moyen du TRI correspond à une crue de période de retour comprise entre 100 et 300 ans.

- **22 communes** du Val-de-Marne ont au moins un bâtiment dont l'emprise touche la zone inondable.
- **Alfortville** est presque entièrement concernée : 99,4 % de ses bâtiments.
- Classement complet : [`resultats/classement_communes_crue_moyenne.csv`](resultats/classement_communes_crue_moyenne.csv)

## Choix techniques

- **Contrôle qualité** : géométries invalides détectées dans la couche TRI source et corrigées avant intégration ; projection IGNF:LAMB93 redéclarée en EPSG:2154 (Lambert-93).
- **Performance** : découpage des zones inondables avec `ST_Subdivide` (22 polygones → environ 59 000 morceaux) et index spatiaux GIST.
- **Pas de double comptage** : `EXISTS` pour les bâtiments qui touchent plusieurs classes de hauteur ; `ST_PointOnSurface` pour rattacher chaque bâtiment à une seule commune.

## Stack technique

Python · GeoPandas · PostgreSQL/PostGIS · SQL · QGIS · JavaScript (MapLibre) · Git

## Limites

- Être situé en zone inondable ne signifie pas être vulnérable : ce projet mesure une **exposition**, pas un risque.
- Un bâtiment est compté comme exposé dès que son emprise touche la zone inondable : cela ne dit pas si l'eau entre dans le bâtiment, ni à quelle hauteur.
- La cartographie du TRI date de 2013, alors que le bâti date de 2026.
- Le nombre de logements n'est pas renseigné pour tous les bâtiments de la BD TOPO : le total de logements exposés est un minimum.
- Dans la donnée source, un polygone du scénario moyen a une légende (1 à 2 m) incohérente avec ses hauteurs (1 à 10 m).

## Reproduire

1. Télécharger les données listées dans la section Données.
2. Les charger dans PostGIS (schéma `source`), en Lambert-93 (EPSG:2154).
3. Exécuter [`sql/01_exposition_bati_crue_moyenne.sql`](sql/01_exposition_bati_crue_moyenne.sql).

## Auteure

Eunice Wouoda Dongmo – Géomaticienne
