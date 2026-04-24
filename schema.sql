CREATE DATABASE IF NOT EXISTS dw_dev;
USE dw_dev;

-- ============================================================
-- DIMENSIONS
-- ============================================================

-- Dimension Model
CREATE TABLE IF NOT EXISTS dim_model (
    id INT AUTO_INCREMENT PRIMARY KEY,
    model VARCHAR(50),
    color VARCHAR(30),
    transmission VARCHAR(30)
);

-- Dimension Region
CREATE TABLE IF NOT EXISTS dim_region (
    id INT AUTO_INCREMENT PRIMARY KEY,
    region VARCHAR(50)
);

-- Dimension Fuel
CREATE TABLE IF NOT EXISTS dim_fuel (
    id INT AUTO_INCREMENT PRIMARY KEY,
    fuel_type VARCHAR(30)
);

-- Table de faits
CREATE TABLE IF NOT EXISTS sales (
    id INT AUTO_INCREMENT PRIMARY KEY,
    model_id INT,
    region_id INT,
    fuel_id INT,
    year INT,
    price DECIMAL(10,2),
    sales_volume INT,
    classification VARCHAR(20),
    FOREIGN KEY (model_id) REFERENCES dim_model(id),
    FOREIGN KEY (region_id) REFERENCES dim_region(id),
    FOREIGN KEY (fuel_id) REFERENCES dim_fuel(id)
);

-- ============================================================
-- KPI 1 — Chiffre d'Affaires Total
-- Formule : SUM(price * sales_volume)
-- Analyse  : par année, région, modèle
-- ============================================================
CREATE OR REPLACE VIEW kpi_chiffre_affaires AS
SELECT
    s.year                          AS annee,
    r.region                        AS region,
    m.model                         AS modele,
    SUM(s.price * s.sales_volume)   AS chiffre_affaires_total
FROM sales s
JOIN dim_model  m ON s.model_id  = m.id
JOIN dim_region r ON s.region_id = r.id
JOIN dim_fuel   f ON s.fuel_id   = f.id
GROUP BY s.year, r.region, m.model
ORDER BY chiffre_affaires_total DESC;

-- ============================================================
-- KPI 2 — Volume de Ventes par Modèle
-- Formule : SUM(sales_volume) GROUP BY model
-- Analyse  : par couleur, transmission, région
-- ============================================================
CREATE OR REPLACE VIEW kpi_volume_ventes AS
SELECT
    m.model                     AS modele,
    m.color                     AS couleur,
    m.transmission              AS transmission,
    r.region                    AS region,
    SUM(s.sales_volume)         AS volume_ventes
FROM sales s
JOIN dim_model  m ON s.model_id  = m.id
JOIN dim_region r ON s.region_id = r.id
GROUP BY m.model, m.color, m.transmission, r.region
ORDER BY volume_ventes DESC;

-- ============================================================
-- KPI 3 — Prix Moyen de Vente (ASP — Average Selling Price)
-- Formule : SUM(price * sales_volume) / SUM(sales_volume)
-- Analyse  : par classification, région, année
-- ============================================================
CREATE OR REPLACE VIEW kpi_prix_moyen AS
SELECT
    s.classification                                        AS classification,
    r.region                                                AS region,
    s.year                                                  AS annee,
    ROUND(
        SUM(s.price * s.sales_volume) / SUM(s.sales_volume),
        2
    )                                                       AS prix_moyen_vente
FROM sales s
JOIN dim_region r ON s.region_id = r.id
GROUP BY s.classification, r.region, s.year
ORDER BY prix_moyen_vente DESC;

-- ============================================================
-- KPI 4 — Part de Marché par Type de Carburant (%)
-- Formule : SUM(vol. par fuel) / SUM(vol. total) * 100
-- Analyse  : par année, région
-- ============================================================
CREATE OR REPLACE VIEW kpi_part_marche_carburant AS
SELECT
    f.fuel_type                                             AS type_carburant,
    s.year                                                  AS annee,
    r.region                                                AS region,
    SUM(s.sales_volume)                                     AS volume_fuel,
    ROUND(
        SUM(s.sales_volume) * 100.0 /
        SUM(SUM(s.sales_volume)) OVER (PARTITION BY s.year, r.region),
        2
    )                                                       AS part_marche_pct
FROM sales s
JOIN dim_fuel   f ON s.fuel_id   = f.id
JOIN dim_region r ON s.region_id = r.id
GROUP BY f.fuel_type, s.year, r.region
ORDER BY s.year, r.region, part_marche_pct DESC;

-- ============================================================
-- KPI 5 — Indice de Performance Régionale
-- Formule : volume région / moyenne nationale * 100
-- Analyse  : par modèle, année, carburant
-- ============================================================
CREATE OR REPLACE VIEW kpi_performance_regionale AS
SELECT
    r.region                                                AS region,
    s.year                                                  AS annee,
    SUM(s.sales_volume)                                     AS volume_region,
    ROUND(AVG(SUM(s.sales_volume)) OVER (PARTITION BY s.year), 2)
                                                            AS moyenne_nationale,
    ROUND(
        SUM(s.sales_volume) * 100.0 /
        AVG(SUM(s.sales_volume)) OVER (PARTITION BY s.year),
        2
    )                                                       AS indice_performance
FROM sales s
JOIN dim_region r ON s.region_id = r.id
GROUP BY r.region, s.year
ORDER BY s.year, indice_performance DESC;