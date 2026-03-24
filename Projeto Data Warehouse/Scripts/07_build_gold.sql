/*===============================================================================
  Script: 07_build_gold.sql
  Purpose: Builds curated, business-ready datasets in the Gold layer.

  Description:
  This step transforms cleaned Silver data into analytical models, including:
    - creation of dimension tables (dimensional modeling)
    - application of business rules and semantic standardization
    - integration of datasets through defined relationships
    - preparation of fact and dimension tables for analysis and reporting
===============================================================================*/


/*============================ DIM_CUSTOMER ===========================*/

-- Ensure script idempotency by dropping the table before re-creation
DROP TABLE IF EXISTS gold.dim_customer;

CREATE TABLE gold.dim_customer AS
SELECT
    code AS id,

    full_name AS name,
    
-- Geolocation Parsing: Extracting primary city and parenthetical reference city for regional clustering
    -- Original city
    TRIM(
        REGEXP_REPLACE(
            SPLIT_PART(location, ',', 1),
            '\s*\(.*\)',
            ''
        )
    ) AS city,

    -- Reference city
    COALESCE(
        TRIM(
            REGEXP_REPLACE(
                SPLIT_PART(location, ',', 1),
                '.*\((.*)\).*',
                '\1'
            )
        ),
        TRIM(SPLIT_PART(location, ',', 1))
    ) AS reference_city,

    TRIM(SPLIT_PART(location, ',', 2)) AS state,

    email as email

FROM silver.customers;


/*============================ DIM_PRODUCT ===========================*/

-- Ensure script idempotency by dropping the table before re-creation
DROP TABLE IF EXISTS gold.dim_product;
DROP TABLE IF EXISTS gold.category_mapping;

-- Creating auxiliary table for categories

CREATE TABLE gold.category_mapping AS
    SELECT DISTINCT 
        actual_category AS raw_category,
        CASE 
            WHEN REPLACE(actual_category, ' ', '') ILIKE '%eletr%' THEN 'Eletrônicos'
            WHEN REPLACE(actual_category, ' ', '') ILIKE '%ncora%' THEN 'Ancoragem'
            WHEN REPLACE(actual_category, ' ', '') ILIKE '%prop%'  THEN 'Propulsão'
            ELSE 'Review Needed' 
        END AS clean_category
    FROM bronze.products_raw

/*======== Sanity Check ========*/

SELECT * FROM gold.category_mapping 
SELECT * FROM gold.category_mapping WHERE clean_category = 'Review Needed' 

/*======== ============ ========*/

CREATE TABLE gold.dim_product AS

WITH unique_lookup AS (
    -- CTE: Bridging Silver and Mapping tables by enforcing a single clean category per normalized product key.
    SELECT DISTINCT ON (LOWER(REPLACE(raw_category, ' ', '')))
        LOWER(REPLACE(raw_category, ' ', '')) AS join_key,
        clean_category AS clean_category
    FROM gold.category_mapping
)

SELECT
    sp.code AS id,

    sp.name AS name,

    COALESCE(ul.clean_category, 'Unknown') AS category,

    sp.price AS sale_price

FROM silver.products sp
LEFT JOIN unique_lookup ul
    ON sp.actual_category = ul.join_key
ORDER BY id;

/*============================ FACT_COSTS ===========================*/

-- Ensure script idempotency by dropping the table before re-creation
DROP TABLE IF EXISTS gold.fact_costs;

CREATE TABLE gold.fact_costs AS
SELECT
    ROW_NUMBER() OVER (ORDER BY product_id, start_date) AS id,

    product_id,

    start_date,

    usd_price

FROM silver.costs
ORDER BY product_id, start_date;


/*============================ DIM_DATE ===========================*/

-- Ensure script idempotency by dropping the table before re-creation
DROP TABLE IF EXISTS gold.dim_date;

CREATE TABLE gold.dim_date AS
SELECT
    CAST(TO_CHAR(datum, 'YYYYMMDD') AS INTEGER) AS date_id,
    datum::DATE AS date,
    EXTRACT(DAY FROM datum) AS day,
    EXTRACT(MONTH FROM datum) AS month,
    -- Month name in Portuguese
    TO_CHAR(datum, 'TMMonth') AS month_name,
    EXTRACT(YEAR FROM datum) AS year,
    EXTRACT(QUARTER FROM datum) AS quarter,
    -- 0 for Sunday, 6 for Saturday 
    EXTRACT(DOW FROM datum) AS day_of_week,
    TO_CHAR(datum, 'TMDay') AS day_name,
    -- Boolean flag to identify weekend days
    CASE 
        WHEN EXTRACT(DOW FROM datum) IN (0, 6) THEN TRUE 
        ELSE FALSE 
    END AS is_weekend
FROM generate_series(
    '2016-01-01'::date, 
    '2025-12-31'::date, 
    '1 day'::interval
) AS datum;

/*============================ DIM_EXCHANGE_RATE ===========================*/

-- Ensure script idempotency by dropping the table before re-creation
DROP TABLE IF EXISTS gold.dim_exchange_rate;


CREATE TABLE gold.dim_exchange_rate AS
SELECT
    date,
    
    FIRST_VALUE(usd_to_brl) OVER (
        PARTITION BY grp
        ORDER BY date
    ) AS usd_to_brl
FROM (
    SELECT
        d.date,
        
        er.usd_to_brl,
        
        COUNT(er.usd_to_brl) OVER (ORDER BY d.date) AS grp
    FROM gold.dim_date d
    LEFT JOIN silver.exchange_rate er
            ON d.date = er.date
) t;



/*============================ FACT_SALES ===========================*/

-- Ensure script idempotency by dropping the table before re-creation
DROP TABLE IF EXISTS gold.fact_sales;

CREATE TABLE gold.fact_sales AS
SELECT
    id,
    id_client AS client_id,
    id_product AS product_id,
    sale_date,
    qtd AS quantity,
    total AS total_amount
FROM silver.sales
ORDER BY id;

