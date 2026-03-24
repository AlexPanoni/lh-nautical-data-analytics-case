/*===============================================================================
  Script: 04_validate_bronze.sql
  Purpose: Performs data validation checks on bronze layer tables.

  Description:
  This script validates whether the raw data was correctly loaded into the
  bronze layer by checking row counts, null values, and basic data integrity.
===============================================================================*/

SELECT 'customers_raw' AS table, COUNT(*) FROM bronze.customers_raw
UNION ALL
SELECT 'products_raw', COUNT(*) FROM bronze.products_raw
UNION ALL
SELECT 'sales_raw', COUNT(*) FROM bronze.sales_raw
UNION ALL
SELECT 'costs_raw', COUNT(*) FROM bronze.costs_raw
UNION ALL
SELECT 'exchange_rate', COUNT(*) FROM bronze.exchange_rate;

/* Verification of critical null values */

SELECT *
FROM bronze.sales_raw
WHERE id IS NULL
   OR id_client IS NULL
   OR id_product IS NULL;

/* => No value found */

/* Checking for duplicate IDs */

SELECT id, COUNT(*)
FROM bronze.sales_raw
GROUP BY id
HAVING COUNT(*) > 1;

/* => No value found */

/* Key consistency verification
 
- Customers that appear in sales but do not exist in customers. */

SELECT DISTINCT s.id_client
FROM bronze.sales_raw s
LEFT JOIN bronze.customers_raw c
    ON s.id_client = c.code
WHERE c.code IS NULL;

/* => No value found */

/* Products that appear in sales but do not exist in products. */

SELECT DISTINCT s.id_product
FROM bronze.sales_raw s
LEFT JOIN bronze.products_raw p
    ON s.id_product = p.code
WHERE p.code IS NULL;

/* => No value found */