/*===============================================================================
  Script: 08_validate_gold.sql
  Purpose: Validates data quality, integrity, and consistency in the Gold layer.

  Description:
  This step performs validation checks on the final analytical model, including:
    - referential integrity between fact and dimension tables
    - consistency of calculated measures (e.g., sales totals)
    - detection of missing or anomalous values
    - overall readiness of the data warehouse for analysis and reporting
===============================================================================*/


/*============================ DIM_CUSTOMER ===========================*/

select * from gold.dim_customer dc

SELECT 
id, 
COUNT(*) 
FROM gold.dim_customer 
GROUP BY id HAVING COUNT(*) > 1;

SELECT 
name, 
COUNT(*) 
FROM gold.dim_customer 
GROUP BY name HAVING COUNT(*) > 1;

-- => No duplicates

SELECT 
city, 
COUNT(*) 
FROM gold.dim_customer 
GROUP BY city
ORDER BY COUNT(*) DESC;

SELECT 
reference_city, 
COUNT(*) 
FROM gold.dim_customer 
GROUP BY reference_city
ORDER BY COUNT(*) DESC;

/*============================ DIM_PRODUCT ===========================*/

select * from gold.dim_product dp

SELECT id, COUNT(*) 
FROM gold.dim_product 
GROUP BY id HAVING COUNT(*) > 1;

SELECT 
name, 
COUNT(*) 
FROM gold.dim_product
GROUP BY name HAVING COUNT(*) > 1;

-- => No duplicates

SELECT 
category, 
COUNT(*) 
FROM gold.dim_product 
GROUP BY category
ORDER BY COUNT(*) DESC;

SELECT 
	COUNT(*) 
FROM gold.dim_product 
WHERE category IS NULL;

-- => No NULLs found

/*============================ DIM_DATE ===========================*/

select * from gold.dim_date dd limit 100

/*============================ DIM_EXCHANGE_RATE ===========================*/

select * from gold.dim_exchange_rate der 

SELECT 
	COUNT(*) 
FROM gold.dim_exchange_rate 
WHERE usd_to_brl IS NULL;

-- => 3 NULL (first 3 days of 2016)

SELECT 
	MIN(date), 
	MAX(date)
FROM gold.dim_exchange_rate der;

-- => No issue

-- Check usd to brl numbers
SELECT 
	MIN(usd_to_brl), 
	MAX(usd_to_brl),
	AVG(usd_to_brl)
FROM gold.dim_exchange_rate der;

-- => No issue

/*============================ FACT_COSTS ===========================*/

select * from gold.fact_costs fc limit 100

SELECT 
id, 
COUNT(*) 
FROM gold.fact_costs fc  
GROUP BY id HAVING COUNT(*) > 1;

-- => No duplicates

SELECT 
	MIN(usd_price), 
	MAX(usd_price),
	AVG(usd_price)
FROM gold.fact_costs fc;

SELECT 
	MIN(start_date), 
	MAX(start_date)
FROM gold.fact_costs fc;

SELECT 
    (SELECT SUM(usd_price) FROM silver.costs) AS silver_total,
    (SELECT SUM(usd_price) FROM gold.fact_costs) AS gold_total;

-- => Perfect match

/*============================ FACT_SALES ===========================*/

select * from gold.fact_sales t limit 100

SELECT 
id, 
COUNT(*) 
FROM gold.fact_sales  
GROUP BY id HAVING COUNT(*) > 1;

-- => No duplicates

SELECT 
client_id, 
COUNT(*) 
FROM gold.fact_sales  
GROUP BY client_id
ORDER BY COUNT(*) DESC;

SELECT 
client_id, 
SUM(total_amount) 
FROM gold.fact_sales  
GROUP BY client_id
ORDER BY SUM(total_amount) DESC;

SELECT 
product_id, 
COUNT(*) 
FROM gold.fact_sales  
GROUP BY product_id
ORDER BY COUNT(*) DESC;

SELECT 
    (SELECT SUM(total) FROM silver.sales) AS silver_total,
    (SELECT SUM(total_amount) FROM gold.fact_sales) AS gold_total;

-- => Perfect match

SELECT
    fs.id,
    fs.product_id,
    fs.quantity,
    fs.total_amount,
    dp.sale_price,
    (fs.quantity * dp.sale_price) AS expected_total,
    (fs.total_amount - (fs.quantity * dp.sale_price)) AS difference
FROM gold.fact_sales fs
JOIN gold.dim_product dp
    ON fs.product_id = dp.id
WHERE ABS(fs.total_amount - (fs.quantity * dp.sale_price)) > 1
ORDER BY difference DESC;

-- => Discrepancies between expected and real sales