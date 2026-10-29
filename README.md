# Observatoire de l'exposition au risque inondation

**Statut : en cours de développement (lancé en octobre 2026)**

Plateforme qui calcule automatiquement, pour chaque commune d'un département, l'exposition du bâti et des équipements sensibles aux zones inondables, stocke les résultats dans PostGIS et les affiche sur une carte web interactive.

Territoire d'étude : **Val-de-Marne (94)**

## Objectifs

- Construire un pipeline de données reproductible, paramétrable par code département
- Produire des indicateurs d'exposition par commune : nombre de bâtiments exposés, établissements sensibles, part du bâti en zone inondable
- Restituer les résultats sur une carte web interactive

## Données (toutes ouvertes)

| Source | Contenu |
| --- | --- |
| BD TOPO (IGN) | Bâtiments, équipements |
| ADMIN EXPRESS (IGN) | Limites communales |
| Géorisques | Zones inondables (TRI, PPRI) |
| INSEE (données carroyées) | Population (optionnel) |

## Architecture prévue

```
Sources ouvertes ──> Pipeline Python (GeoPandas) ──> PostGIS (Docker) ──> Vues SQL d'indicateurs ──> Carte web (MapLibre)
```

## Feuille de route

- **Étape 1 – Base de données** : PostGIS sous Docker, chargement des données, index spatiaux, premières requêtes SQL spatiales
- **Étape 2 – Pipeline ETL** : téléchargement, nettoyage et chargement automatisés en Python, configuration, logs, gestion d'erreurs
- **Étape 3 – Indicateurs** : vues SQL par commune, exécution automatisée, carte de synthèse sous QGIS
- **Étape 4 – Restitution** : carte web interactive, documentation, résultats

## Stack technique

Python · GeoPandas · PostgreSQL/PostGIS · SQL · Docker · QGIS · JavaScript (MapLibre) · Git

## Limites

Être situé en zone inondable ne signifie pas être vulnérable : ce projet mesure une **exposition**, pas un risque. Les résultats dépendent de la disponibilité et de l'échelle des zonages publiés pour le territoire étudié.

## Auteure

Eunice Wouoda Dongmo – Data Engineer géospatial
