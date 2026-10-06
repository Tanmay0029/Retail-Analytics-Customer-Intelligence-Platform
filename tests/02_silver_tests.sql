/*
===============================================================================
Silver Layer - Data Quality Tests
===============================================================================
Script Purpose:
    Checks if all data cleaning, standardizations, and flag assignments 
    were executed perfectly. All violation queries should return ZERO rows.
===============================================================================
*/

PRINT '================================================';
PRINT 'SILVER LAYER TESTS';
PRINT '================================================';

-- Test 1: Check for NULLs in Customer_id
-- Expected: 0 (They should all be mapped to -1)
SELECT 'Null Customers' AS Test_Name, COUNT(*) AS Failures
FROM silver.online_retail
WHERE Customer_id IS NULL;

-- Test 2: Check Date Parsing
-- Expected: 0 (All British DD-MM-YYYY dates should have parsed correctly)
SELECT 'Null Dates' AS Test_Name, COUNT(*) AS Failures
FROM silver.online_retail
WHERE Invoice_date IS NULL OR Order_date IS NULL;

-- Test 3: Check Cancellation Flag Logic
-- Expected: 0 (Any Invoice starting with 'C' must have Is_cancelled = 1)
SELECT 'Failed Cancel Flag' AS Test_Name, COUNT(*) AS Failures
FROM silver.online_retail
WHERE Invoice LIKE 'C%' AND Is_cancelled = 0;

-- Test 4: Check Anomaly Price Logic
-- Expected: 0 (Any Price <= 0 must have Is_anomaly_price = 1)
SELECT 'Failed Price Flag' AS Test_Name, COUNT(*) AS Failures
FROM silver.online_retail
WHERE Price <= 0 AND Is_anomaly_price = 0;

-- Test 5: Check Description Standardization
-- Expected: 0 (We removed carriage returns and purely numeric descriptions)
SELECT 'Failed Description Standardization' AS Test_Name, COUNT(*) AS Failures
FROM silver.online_retail
WHERE Description IS NULL OR LTRIM(RTRIM(Description)) NOT LIKE '%[a-zA-Z]%';

-- Test 6: Check for Exact Duplicates
-- Expected: 0 (Our CTE logic should have dropped them)
SELECT 'Exact Duplicates Found' AS Test_Name, COUNT(*) AS Failures
FROM (
    SELECT Invoice, Stock_code, Quantity, Invoice_date, Customer_id, COUNT(*) as cnt
    FROM silver.online_retail
    GROUP BY Invoice, Stock_code, Quantity, Invoice_date, Customer_id
    HAVING COUNT(*) > 1
) dupes;
