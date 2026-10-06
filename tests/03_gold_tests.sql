/*
===============================================================================
Gold Layer - Data Quality Tests
===============================================================================
Script Purpose:
    Checks if the Star Schema was built correctly, ensuring no data was lost 
    during the Joins and that all Foreign Keys match their Dimensions perfectly.
===============================================================================
*/

PRINT '================================================';
PRINT 'GOLD LAYER TESTS';
PRINT '================================================';

-- Test 1: Row Count Reconciliation (Fact vs Silver)
-- Expected: PASS (The counts must match exactly)
SELECT 
    (SELECT COUNT(*) FROM silver.online_retail) AS Silver_Row_Count,
    (SELECT COUNT(*) FROM gold.fact_sales) AS Gold_Fact_Count,
    CASE 
        WHEN (SELECT COUNT(*) FROM silver.online_retail) = (SELECT COUNT(*) FROM gold.fact_sales) THEN 'PASS' 
        ELSE 'FAIL' 
    END AS Row_Count_Test;

-- Test 2: Revenue Reconciliation (Fact vs Silver)
-- Expected: PASS (The total Revenue must match exactly)
SELECT 
    (SELECT SUM(Revenue) FROM silver.online_retail) AS Silver_Total_Revenue,
    (SELECT SUM(Revenue) FROM gold.fact_sales) AS Gold_Total_Revenue,
    CASE 
        WHEN (SELECT SUM(Revenue) FROM silver.online_retail) = (SELECT SUM(Revenue) FROM gold.fact_sales) THEN 'PASS' 
        ELSE 'FAIL' 
    END AS Revenue_Test;

-- Test 3: Foreign Key Integrity - Customers
-- Expected: 0 (No sales assigned to a Customer_key that doesn't exist)
SELECT 'Orphaned Customers in Fact' AS Test_Name, COUNT(*) AS Failures
FROM gold.fact_sales f
LEFT JOIN gold.dim_customer c ON f.Customer_key = c.Customer_key
WHERE c.Customer_key IS NULL;

-- Test 4: Foreign Key Integrity - Products
-- Expected: 0 (No sales assigned to a Product_key that doesn't exist)
SELECT 'Orphaned Products in Fact' AS Test_Name, COUNT(*) AS Failures
FROM gold.fact_sales f
LEFT JOIN gold.dim_product p ON f.Product_key = p.Product_key
WHERE p.Product_key IS NULL;

-- Test 5: Foreign Key Integrity - Dates
-- Expected: 0 (No sales assigned to a Date_key that doesn't exist)
SELECT 'Orphaned Dates in Fact' AS Test_Name, COUNT(*) AS Failures
FROM gold.fact_sales f
LEFT JOIN gold.dim_date d ON f.Date_key = d.Date_key
WHERE d.Date_key IS NULL;
