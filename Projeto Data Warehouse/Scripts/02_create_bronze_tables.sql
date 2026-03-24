/*===============================================================================
  Script: 02_create_bronze_tables.sql
  Purpose: Creates raw tables in the bronze layer to store CSV data as-is.

  Description:
  All columns are defined as TEXT to preserve the original structure and avoid
  data loss during ingestion. Data typing and cleaning will be handled in the
  silver layer.
===============================================================================*/

CREATE TABLE bronze.customers_raw (
    full_name TEXT,
    location TEXT,
    code TEXT,
    email TEXT
);

CREATE TABLE bronze.products_raw (
    name TEXT,
    price TEXT,
    code TEXT,
    actual_category TEXT
);

CREATE TABLE bronze.sales_raw (
    id TEXT,
    id_client TEXT,
    id_product TEXT,
    qtd TEXT,
    total TEXT,
    sale_date TEXT
);

CREATE TABLE bronze.costs_raw (
    product_id TEXT,
    product_name TEXT,
    category TEXT,
    start_date TEXT,
    usd_price TEXT
);


CREATE TABLE bronze.exchange_rate (
    date TEXT,
    usd_to_brl TEXT
);