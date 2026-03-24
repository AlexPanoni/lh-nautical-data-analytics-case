/*===============================================================================
  Script: 06_validate_silver.sql
  Purpose: Validates data quality and integrity in the silver layer.

  Description:
  This step performs validation checks on the cleaned data, including:
    - null and missing value checks
    - duplicate detection
    - data type and format validation
    - referential integrity checks
===============================================================================*/


/*============================ CUSTOMERS ===========================*/

select * from silver.customers

-- Validate location formatting to ensure City, State order
SELECT location 
FROM silver.customers 
WHERE SPLIT_PART(location, ',', 1) ~ '^[A-Z]{2}$';

-- => No results


-- Validate emails all use "@"
SELECT email 
FROM silver.customers 
WHERE email LIKE '%#%' OR email NOT LIKE '%@%';

-- => No results


-- Validate successful INTEGER conversion and identifying nulls
SELECT 
    COUNT(*) as total,
    COUNT(code) as valids,
    COUNT(*) - COUNT(code) as nulls
FROM silver.customers;

-- => No nulls


/*============================ PRODUCTS ===========================*/

select * from silver.products


-- Check for duplicates
SELECT name, code, COUNT(*)
FROM silver.products
GROUP BY name, code
HAVING COUNT(*) > 1;

-- => No duplicates


-- Verify price consistency
SELECT 
    MIN(price) AS min_price,
    MAX(price) AS max_price,
    COUNT(*) FILTER (WHERE price <= 0) AS invalid_price
FROM silver.products;

-- => No invalids

-- Verify code uniqueness
SELECT 
    COUNT(DISTINCT code) AS unique_code,
    COUNT(*) FILTER (WHERE code IS NULL) AS null_code
FROM silver.products;

-- => No null code. 150 codes in total

-- Check category normalization
SELECT 
    (SELECT COUNT(DISTINCT actual_category) FROM bronze.products_raw) AS categories_bronze,
    (SELECT COUNT(DISTINCT actual_category) FROM silver.products) AS categories_silver;

-- => drop from 39 original categories to 19


/*============================ COSTS ===========================*/


select * from silver.costs limit 10

-- Ensure start_date consistency and identifying potential data entry errors
SELECT 
    MIN(start_date) AS min_start_date,
    MAX(start_date) AS max_start_date,
    COUNT(*) FILTER (WHERE start_date > CURRENT_DATE) AS future_date
FROM silver.costs;

-- => No invalid dates


-- Verify average price consistency and catching invalid records
SELECT 
    AVG(usd_price) AS avg_price,
    COUNT(*) FILTER (WHERE usd_price <= 0 OR usd_price IS NULL) AS invalid_price
FROM silver.costs;

-- => No invalid prices

-- Check for products with no match
SELECT c.product_id, c.product_name
FROM silver.costs c
LEFT JOIN silver.products p ON c.product_id = p.code
WHERE p.code IS NULL;

-- => No invalid code/product_id


-- Check duplicates
SELECT product_id, start_date, COUNT(*)
FROM silver.costs
GROUP BY product_id, start_date
HAVING COUNT(*) > 1;

-- => No product with duplicate date


/*============================ SALES ===========================*/

select * from silver.sales limit 25

-- Check sales with no Product match
SELECT s.id_product, COUNT(*) 
FROM silver.sales s
LEFT JOIN silver.products p ON s.id_product = p.code
WHERE p.code IS NULL
GROUP BY 1;

-- => No mismatch

-- Check Sales with no Client match
SELECT s.id_client, COUNT(*) 
FROM silver.sales s
LEFT JOIN silver.customers c ON s.id_client = c.code
WHERE c.code IS NULL
GROUP BY 1;

-- => No mismatch

-- Check duplicate ids
SELECT id, COUNT(*)
FROM silver.sales
GROUP BY id
HAVING COUNT(*) > 1;

-- => No duplicate

-- Verify quantity and total consistency and catching invalid records
SELECT 
    MIN(qtd) AS qtd_min,
    MIN(total) AS total_min,
    MAX(qtd) AS qtd_max,
    MAX(total) AS total_max,
    COUNT(*) FILTER (WHERE total <= 0 OR qtd <= 0) AS invalid_register
FROM silver.sales;

-- => No invalid registers

-- Check if there are null dates
SELECT *
FROM silver.sales
WHERE sale_date IS NULL;

-- => No null dates

-- Ensure start_date consistency and identifying potential data entry errors
SELECT 
	MIN(sale_date), 
	MAX(sale_date)
FROM silver.sales;

-- => No invalid dates. Dates go from 2023-01-01 to 2024-12-31 as expected

/*============================ EXCHANGE_RATE ===========================*/

select * from silver.exchange_rate limit 25

-- Ensure date consistency and identifying potential data entry errors
SELECT 
	MIN(date), 
	MAX(date)
FROM silver.exchange_rate;

-- => No issue

-- Check usd to brl numbers
SELECT 
	MIN(usd_to_brl), 
	MAX(usd_to_brl),
	AVG(usd_to_brl)
FROM silver.exchange_rate;

-- No issue
