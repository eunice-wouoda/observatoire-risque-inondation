"""Test de connexion à la base PostGIS du projet.

Vérifie trois choses :
1. Python arrive à se connecter à PostgreSQL avec les paramètres du fichier .env
2. PostGIS répond
3. GeoPandas sait lire une table géographique de la base
"""
import os
import sys

import geopandas as gpd
from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL


def creer_moteur():
    """Crée la connexion à la base à partir du fichier .env."""
    load_dotenv()
    url = URL.create(
        drivername="postgresql+psycopg2",
        username=os.getenv("PG_USER", "postgres"),
        password=os.getenv("PG_PASSWORD"),
        host=os.getenv("PG_HOST", "localhost"),
        port=int(os.getenv("PG_PORT", "5432")),
        database=os.getenv("PG_DATABASE", "inondation"),
    )
    return create_engine(url)


def main():
    moteur = creer_moteur()

    try:
        with moteur.connect() as connexion:
            version = connexion.execute(text("SELECT postgis_full_version()")).scalar()
    except Exception as erreur:
        print("Connexion impossible :", erreur)
        print("Vérifie que le service PostgreSQL est démarré et que le fichier .env est rempli.")
        sys.exit(1)

    print("Connexion réussie.")
    print("Version :", version.split()[0])

    bati = gpd.read_postgis(
        "SELECT cleabs, usage_1, geom FROM resultats.bati_expose_moyen LIMIT 5",
        moteur,
        geom_col="geom",
    )
    print(f"Lecture GeoPandas réussie : {len(bati)} bâtiments, SCR = {bati.crs}")
    print(bati.head())


if __name__ == "__main__":
    main()
