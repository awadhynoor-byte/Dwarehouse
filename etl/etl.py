import pandas as pd
import mysql.connector

conn = mysql.connector.connect(
    host="mysql_dev",
    user="root",
    password="root",
    database="dw_dev",
    port=3306
)

cursor = conn.cursor()

df = pd.read_csv('/data/bmw_sales.csv')

models = {}
regions = {}
fuels = {}

for row in df.to_dict("records"):

    model_key = (row['Model'], row['Color'], row['Transmission'])
    if model_key not in models:
        cursor.execute(
            "INSERT INTO dim_model (model, color, transmission) VALUES (%s, %s, %s)",
            (row['Model'], row['Color'], row['Transmission'])
        )
        models[model_key] = cursor.lastrowid

    if row['Region'] not in regions:
        cursor.execute(
            "INSERT INTO dim_region (region) VALUES (%s)",
            (row['Region'],)
        )
        regions[row['Region']] = cursor.lastrowid

    if row['Fuel_Type'] not in fuels:
        cursor.execute(
            "INSERT INTO dim_fuel (fuel_type) VALUES (%s)",
            (row['Fuel_Type'],)
        )
        fuels[row['Fuel_Type']] = cursor.lastrowid

    cursor.execute(
        """INSERT INTO sales 
        (model_id, region_id, fuel_id, year, price, sales_volume, classification)
        VALUES (%s, %s, %s, %s, %s, %s, %s)""",
        (
            models[model_key],
            regions[row['Region']],
            fuels[row['Fuel_Type']],
            int(row['Year']),
            float(row['Price_USD']),
            int(row['Sales_Volume']),
            row['Sales_Classification']
        )
    )

conn.commit()
print(" Data Loaded Successfully")