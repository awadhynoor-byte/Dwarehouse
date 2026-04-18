CREATE DATABASE IF NOT EXISTS dw_dev;
USE dw_dev;

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