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
WHERE f.Is_cancelled = 0 AND f.Is_non_product = 0 AND f.Is_anomaly_price = 0 AND d.Year = 2010
GROUP BY d.Year, d.Month, d.Month_name
ORDER BY d.Year, d.Month;

-- 3. Revenue by Top 5 Countries
SELECT TOP 5
    c.Country,
    SUM(f.Revenue) AS Total_Revenue
FROM gold.fact_sales f
JOIN gold.dim_customer c ON f.Customer_key = c.Customer_key
WHERE f.Is_cancelled = 0 AND f.Is_non_product = 0 AND f.Is_anomaly_price = 0
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

-- 1. Registered vs Anonymous Revenue Split (Donut Chart)
SELECT 
    CASE WHEN c.Customer_id = -1 THEN 'Anonymous' ELSE 'Registered' END AS Customer_Type,
    SUM(f.Revenue) AS Total_Revenue
FROM gold.fact_sales f
JOIN gold.dim_customer c ON f.Customer_key = c.Customer_key
WHERE f.Is_cancelled = 0 AND f.Is_non_product = 0 AND f.Is_anomaly_price = 0
GROUP BY CASE WHEN c.Customer_id = -1 THEN 'Anonymous' ELSE 'Registered' END;

-- 2. RFM Segment Distribution (Bar Chart)
SELECT 
    RFM_Segment, 
    COUNT(Customer_key) AS Total_Customers
FROM gold.dim_customer
WHERE Customer_id != -1
GROUP BY RFM_Segment
ORDER BY Total_Customers DESC;

-- 3. Cohort Retention Matrix (Heatmap)
-- This query validates the number of retained customers for the Jan 2010 cohort at Month 0 and Month 1
SELECT 
    YEAR(c.First_purchase_date) AS Cohort_Year,
    MONTH(c.First_purchase_date) AS Cohort_Month,
    f.Cohort_Month_Offset,
    COUNT(DISTINCT f.Customer_key) AS Retained_Customers
FROM gold.fact_sales f
JOIN gold.dim_customer c ON f.Customer_key = c.Customer_key
WHERE c.Customer_id != -1 AND f.Is_cancelled = 0
  AND YEAR(c.First_purchase_date) = 2010 AND MONTH(c.First_purchase_date) = 1
  AND f.Cohort_Month_Offset IN (0, 1)
GROUP BY YEAR(c.First_purchase_date), MONTH(c.First_purchase_date), f.Cohort_Month_Offset
ORDER BY f.Cohort_Month_Offset;

-- 4. VIP "Champions" List (Table Visual)
SELECT TOP 10
    Customer_id,
    Country,
    Recency,
    Frequency,
    Monetary
FROM gold.dim_customer
WHERE RFM_Segment = 'Champions'
ORDER BY Monetary DESC;


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

-- 4. Pareto Analysis 
WITH ProductSales AS (
    -- Step 1: Calculate total clean revenue for each product (Excluding UNKNOWN PRODUCT)
    SELECT 
        p.Description,
        SUM(f.Revenue) AS Total_Revenue
    FROM gold.fact_sales f
    JOIN gold.dim_product p ON f.Product_key = p.Product_key
    WHERE f.Is_cancelled = 0 
      AND f.Is_non_product = 0 
      AND f.Is_anomaly_price = 0
      AND p.Description != 'UNKNOWN PRODUCT'
    GROUP BY p.Description
),
CumulativeSales AS (
    -- Step 2: Calculate the running total and the grand total using Window Functions
    SELECT 
        Description,
        Total_Revenue,
        -- This creates the running cumulative total, sorting by the highest earners first
        SUM(Total_Revenue) OVER (ORDER BY Total_Revenue DESC) AS Running_Total,
        -- This gets the Grand Total of the entire store
        SUM(Total_Revenue) OVER () AS Grand_Total
    FROM ProductSales
)
-- Step 3: Divide the Running Total by the Grand Total to get the Pareto %
SELECT TOP 50
    Description,
    Total_Revenue,
    Running_Total,
    Grand_Total,
    CAST((Running_Total / Grand_Total) * 100 AS DECIMAL(5,2)) AS Pareto_Percentage
FROM CumulativeSales
ORDER BY Total_Revenue DESC;