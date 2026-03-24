/*===============================================================================
  Script: 05_load_silver.sql
  Purpose: Cleans and standardizes customer data into the silver layer.

  Description:
  This step applies data cleaning rules to the raw customer data, including:
    - data type casting (text to numeric and date types)
    - text normalization (trimming, casing, and formatting corrections)
    - conditional parsing for inconsistent formats (e.g., mixed date patterns)
    - removal of exact duplicates when applicable
    - preparation of data for downstream modeling while preserving original structure
    
  Notes:
  	- Column names are preserved from Bronze to maintain traceability across layers
===============================================================================*/


/*============================ CUSTOMERS ===========================*/

-- Ensure script idempotency by dropping the table before re-creation
DROP TABLE IF EXISTS silver.customers;

/*===============================================================================
  Customer Data Cleaning - Silver Layer

  Identified Issues:
  - Inconsistent location formats (different separators and order: city/state)
  - Invalid email formatting (use of '#' instead of '@')

  Cleaning Strategy:
  - Standardize location by normalizing separators and correcting order when needed
  - Fix email formatting using string replacement
  - Cast 'code' to INTEGER for proper typing
  - Preserve full_name as-is (no duplicates identified)

  Notes:
  - Location standardization is heuristic-based (UF assumed as 2-letter code)
  - Full normalization (city/state split) deferred to Gold layer
===============================================================================*/

CREATE TABLE silver.customers AS
WITH base AS (
    SELECT
        full_name,
        code,
        email,
        -- Normalize separators and trim leading/trailing whitespace
        TRIM(REGEXP_REPLACE(
            REPLACE(REPLACE(location, '/', ','), '-', ','),
            '\s*,\s*',
            ',',
            'g'
        )) AS clean_loc
    FROM bronze.customers_raw
)
SELECT
    TRIM(full_name) AS full_name,
    
    -- Final location field, swapping city and state when necessary
    TRIM(
    CASE
        WHEN LENGTH(SPLIT_PART(clean_loc, ',', 1)) = 2
        THEN
            TRIM(SPLIT_PART(clean_loc, ',', 2)) || ',' || TRIM(SPLIT_PART(clean_loc, ',', 1))
        ELSE
            clean_loc
    END
) AS location,

    -- Cast 'code' column to INTEGER
    CAST(NULLIF(code, '') AS INT) AS code,
    
    -- Email cleaning: convert to lowercase and replace '#' with '@'
    LOWER(REPLACE(email, '#', '@')) AS email 

FROM base;

/*============================ PRODUCTS ===========================*/

-- Ensure script idempotency by dropping the table before re-creation
DROP TABLE IF EXISTS silver.products;

/*===============================================================================
  Product Data Cleaning - Silver Layer

  Identified Issues:
  - Duplicate records for the same product (same name, price, and code, with variations in category)
  - 'price' column stored as TEXT with currency symbol ("R$") and spacing
  - Highly inconsistent category values (variations in casing, spacing, and spelling)

  Cleaning Strategy:
  - Remove exact product duplicates based on (name, price, code), keeping a single record per group
  - Clean and convert 'price' to NUMERIC by removing currency symbol and whitespace
  - Cast 'code' to INTEGER for proper typing
  - Normalize 'actual_category' using lowercase and trimming for consistency
  - Trim 'name' to remove leading/trailing whitespace

  Notes:
  - Deduplication is limited to exact matches; no semantic product consolidation is performed
  - Category normalization is syntactic only; semantic standardization is deferred to Gold layer
===============================================================================*/

CREATE TABLE silver.products AS
WITH deduplicated AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY name, price, code
            ORDER BY actual_category
        ) AS rn
    FROM bronze.products_raw
)

SELECT
    TRIM(name) AS name,
    
    -- transform price column into numeric with no symbol
    CAST(
        REPLACE(REPLACE(price, 'R$', ''), ' ', '')
        AS NUMERIC(10,2)
    ) AS price,
    
    -- Cast 'code' column to INTEGER
    CAST(NULLIF(code, '') AS INT) AS code,
    
    -- Normalize category column
    LOWER(
  TRIM(
    REGEXP_REPLACE(actual_category, '(\w)\s+(?=\w)', '\1', 'g')
  )
) AS actual_category

FROM deduplicated
WHERE rn = 1;


/*============================ COSTS ===========================*/

-- Ensure script idempotency by dropping the table before re-creation
DROP TABLE IF EXISTS silver.costs;

/*===============================================================================
  Cost Data Cleaning - Silver Layer

  Identified Issues:
  - 'start_date' requires parsing from 'DD/MM/YYYY' format
  - 'usd_price' requires conversion to numeric
  - Minor formatting inconsistencies in text fields

  Cleaning Strategy:
  - Cast 'product_id' to INTEGER
  - Convert 'usd_price' to NUMERIC
  - Parse 'start_date' using TO_DATE
  - Apply TRIM to 'product_name' and normalize 'category' (lowercase + trim)

  Notes:
  - Data represents historical pricing (multiple records per product are expected)
  - No deduplication is performed
===============================================================================*/

CREATE TABLE silver.costs AS
SELECT
    CAST(product_id AS INT) AS product_id,

    TRIM(product_name) AS product_name,

    LOWER(TRIM(category)) AS category,

    TO_DATE(start_date, 'DD/MM/YYYY') AS start_date,

    CAST(usd_price AS NUMERIC(10,2)) AS usd_price

FROM bronze.costs_raw;



/*============================ SALES ===========================*/

-- Ensure script idempotency by dropping the table before re-creation
DROP TABLE IF EXISTS silver.sales;

/*===============================================================================
  Sales Data Cleaning - Silver Layer

  Identified Issues:
  - Mixed date formats in 'sale_date' (YYYY-MM-DD and DD-MM-YYYY)
  - Numeric fields require proper typing

  Cleaning Strategy:
  - Cast 'id', 'id_client', and 'id_product' to INTEGER
  - Convert 'qtd' to INTEGER and 'total' to NUMERIC
  - Parse 'sale_date' conditionally based on detected format

  Notes:
  - Each row represents a unique sale (no deduplication required)
  - Original identifiers are preserved for traceability (first id is 0, not 1)
===============================================================================*/

CREATE TABLE silver.sales AS
SELECT
    CAST(id AS INT) AS id,

    CAST(id_client AS INT) AS id_client,

    CAST(id_product AS INT) AS id_product,

    CAST(qtd AS INT) AS qtd,

    CAST(total AS NUMERIC(10,2)) AS total,

	CASE
	  WHEN sale_date ~ '^\d{4}-\d{2}-\d{2}$'
	    THEN TO_DATE(sale_date, 'YYYY-MM-DD')
	  WHEN sale_date ~ '^\d{2}-\d{2}-\d{4}$'
	    THEN TO_DATE(sale_date, 'DD-MM-YYYY')
	  ELSE NULL
	END AS sale_date

FROM bronze.sales_raw;

/*============================ EXCHANGE_RATE ===========================*/

-- Ensure script idempotency by dropping the table before re-creation
DROP TABLE IF EXISTS silver.exchange_rate;

/*===============================================================================
  Exchange Rate Data Cleaning - Silver Layer

  Identified Issues:
  - Date and Exchange Rate need to be converted to the appropriate type

  Cleaning Strategy:
  - Parse 'date' using TO_DATE
  - Convert 'usd_to_brl' to NUMERIC
===============================================================================*/

CREATE TABLE silver.exchange_rate AS
SELECT
    TO_DATE(date, 'YYYY-MM-DD') AS date,

    CAST(usd_to_brl AS NUMERIC(10,4)) AS usd_to_brl

FROM bronze.exchange_rate;
