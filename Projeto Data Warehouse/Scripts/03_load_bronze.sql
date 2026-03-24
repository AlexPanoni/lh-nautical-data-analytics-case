/*===============================================================================
  Script: 03_load_bronze.sql
  Purpose: Loads raw CSV data into bronze layer tables.

  Description:
  This script performs full loads from CSV files into the bronze schema using
  \copy. All data is ingested as-is, without transformation.
===============================================================================*/

BEGIN;

COPY bronze.customers_raw
FROM '/data/customers_raw.csv'
DELIMITER ','
CSV HEADER;

COPY bronze.products_raw
FROM '/data/produtos_raw.csv'
DELIMITER ','
CSV HEADER;

COPY bronze.sales_raw
FROM PROGRAM 'sed "/^[[:space:],]*$/d" /data/vendas_2023_2024.csv'  /* Treatment to ensure that ingestion bypasses completely empty lines. */
DELIMITER ','
CSV header;

COPY bronze.costs_raw
FROM '/data/costs_raw.csv'
DELIMITER ','
CSV header;

COPY bronze.exchange_rate
FROM '/data/exchange_rates_bcb.csv'
DELIMITER ','
CSV header;

COMMIT;