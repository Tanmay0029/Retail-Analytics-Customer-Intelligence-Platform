/*
===============================================================================
Power BI Dashboard Validation Scripts
===============================================================================
Script Purpose:
    These queries are designed to act as the "Source of Truth". 
    When you build your Power BI dashboards, compare your visual totals 
    to the results of these queries to guarantee your DAX and filters are 100% correct.
===============================================================================
*/

PRINT '================================================';
PRINT 'PAGE 1: EXECUTIVE SALES SUMMARY';
PRINT '================================================';

-- 1. High-Level KPIs (Total Revenue, Total Items Sold, Total Invoices)
-- Filter out Cancellations and Anomalies to get clean "Gross Sales"
SELECT 
    SUM(Revenue) AS Total_Revenue,
    SUM(Quantity) AS Total_Items_Sold,
    COUNT(DISTINCT Invoice_no) AS Total_Valid_Orders
FROM gold.fact_sales
WHERE Is_cancelled = 0 
  AND Is_anomaly_price = 0 
  AND Is_non_product = 0;

-- 2. Monthly Revenue Trend (2010 Only)
SELECT 
    d.Year,
    d.Month,
    d.Month_name,
    SUM(f.Revenue) AS Monthly_Revenue
FROM gold.fact_sales f
JOIN gold.dim_date d ON f.Date_key = d.Date_key
WHERE f.Is_cancelled = 0 AND f.Is_non_product = 0 AND d.Year = 2010
GROUP BY d.Year, d.Month, d.Month_name
ORDER BY d.Year, d.Month;

-- 3. Revenue by Top 5 Countries
SELECT TOP 5
    c.Country,
    SUM(f.Revenue) AS Total_Revenue
FROM gold.fact_sales f
JOIN gold.dim_customer c ON f.Customer_key = c.Customer_key
WHERE f.Is_cancelled = 0 AND f.Is_non_product = 0
GROUP BY c.Country
ORDER BY Total_Revenue DESC;

-- 4. Lost Revenue due to Cancellations
SELECT 
    SUM(Revenue) AS Lost_Revenue
FROM gold.fact_sales
WHERE Is_cancelled = 1;


PRINT '================================================';
PRINT 'PAGE 2: CUSTOMER INSIGHTS & RETENTION';
PRINT '================================================';

-- 1. Top 10 Most Valuable Customers (By Revenue)
SELECT TOP 10
    c.Customer_id,
    c.Country,
    SUM(f.Revenue) AS Total_Lifetime_Value
FROM gold.fact_sales f
JOIN gold.dim_customer c ON f.Customer_key = c.Customer_key
WHERE f.Is_cancelled = 0 AND c.Customer_id != -1 -- Exclude anonymous
GROUP BY c.Customer_id, c.Country
ORDER BY Total_Lifetime_Value DESC;

-- 2. Registered vs Anonymous Revenue Split
SELECT 
    CASE WHEN c.Customer_id = -1 THEN 'Anonymous' ELSE 'Registered' END AS Customer_Type,
    SUM(f.Revenue) AS Total_Revenue,
    CAST(SUM(f.Revenue) / (SELECT SUM(Revenue) FROM gold.fact_sales WHERE Is_cancelled = 0 AND Is_non_product = 0) * 100 AS DECIMAL(5,2)) AS Percentage_of_Total
FROM gold.fact_sales f
JOIN gold.dim_customer c ON f.Customer_key = c.Customer_key
WHERE f.Is_cancelled = 0 AND f.Is_non_product = 0
GROUP BY CASE WHEN c.Customer_id = -1 THEN 'Anonymous' ELSE 'Registered' END;

-- 3. New Customer Acquisition by Month (2010)
SELECT 
    YEAR(First_purchase_date) AS Year,
    MONTH(First_purchase_date) AS Month,
    COUNT(Customer_key) AS New_Customers_Acquired
FROM gold.dim_customer
WHERE Customer_id != -1 AND YEAR(First_purchase_date) = 2010
GROUP BY YEAR(First_purchase_date), MONTH(First_purchase_date)
ORDER BY Year, Month;


PRINT '================================================';
PRINT 'PAGE 3: PRODUCT PERFORMANCE & INVENTORY';
PRINT '================================================';

-- 1. Top 10 Best-Selling Products
SELECT TOP 10
    p.Stock_code,
    p.Description,
    SUM(f.Revenue) AS Total_Revenue,
    SUM(f.Quantity) AS Total_Units_Sold
FROM gold.fact_sales f
JOIN gold.dim_product p ON f.Product_key = p.Product_key
WHERE f.Is_cancelled = 0 AND f.Is_non_product = 0
GROUP BY p.Stock_code, p.Description
ORDER BY Total_Revenue DESC;

-- 2. Most Cancelled/Returned Products
SELECT TOP 10
    p.Stock_code,
    p.Description,
    SUM(ABS(f.Quantity)) AS Total_Units_Returned
FROM gold.fact_sales f
JOIN gold.dim_product p ON f.Product_key = p.Product_key
WHERE f.Is_cancelled = 1
GROUP BY p.Stock_code, p.Description
ORDER BY Total_Units_Returned DESC;

-- 3. Financial Impact of "Bad Debt" & Manual Adjustments (Using our Silver Flags!)
SELECT 
    SUM(Revenue) AS Financial_Impact
FROM gold.fact_sales
WHERE Is_anomaly_price = 1 OR Is_inventory_adjustment = 1;
