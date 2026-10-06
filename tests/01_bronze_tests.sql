/*
===============================================================================
Bronze Layer - Data Quality Tests
===============================================================================
Script Purpose:
    Checks if the raw data was loaded completely from the CSVs.
===============================================================================
*/

PRINT '================================================';
PRINT 'BRONZE LAYER TESTS';
PRINT '================================================';

-- Test 1: Check total row count
-- Expected: > 0 (Should be approx 1,067,371 based on the source CSVs)
SELECT 'Bronze Row Count' AS Test_Name, COUNT(*) AS Result 
FROM bronze.online_retail;

-- Test 2: Check for complete emptiness
-- Expected: 0 (If > 0, the table was loaded successfully)
SELECT 
    CASE 
        WHEN COUNT(*) > 0 THEN 'PASS' 
        ELSE 'FAIL - Table is Empty' 
    END AS Bronze_Load_Status
FROM bronze.online_retail;
