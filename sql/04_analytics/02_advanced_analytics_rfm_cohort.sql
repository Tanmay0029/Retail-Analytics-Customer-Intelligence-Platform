/*
===============================================================================
Advanced Analytics: RFM Segmentation & Cohort Indexing
===============================================================================
Script Purpose:
    This script performs the heavy mathematical lifting for RFM (Recency, 
    Frequency, Monetary) Segmentation and Cohort Analysis directly in the 
    SQL Data Warehouse. 

    By calculating this in SQL, Power BI runs significantly faster and 
    the logic is centralized.
===============================================================================
*/

PRINT '================================================';
PRINT '1. COHORT ANALYSIS PREP (Fact Table)';
PRINT '================================================';
-- To build a Cohort Retention Matrix in Power BI, we need to know how many 
-- months passed between the customer's FIRST purchase and THIS purchase.

-- Add a column to fact_sales if it doesn't exist
IF NOT EXISTS (
    SELECT * FROM sys.columns 
    WHERE object_id = OBJECT_ID('gold.fact_sales') AND name = 'Cohort_Month_Offset'
)
BEGIN
    ALTER TABLE gold.fact_sales ADD Cohort_Month_Offset INT;
END
GO

-- Calculate the difference in months between the invoice date and their first purchase
UPDATE f
SET f.Cohort_Month_Offset = DATEDIFF(MONTH, c.First_purchase_date, d.Date)
FROM gold.fact_sales f
JOIN gold.dim_customer c ON f.Customer_key = c.Customer_key
JOIN gold.dim_date d ON f.Date_key = d.Date_key
WHERE c.Customer_id != -1; -- Ignore anonymous customers for cohorts
GO
PRINT '>> Cohort Month Offsets successfully calculated in fact_sales.';


PRINT '================================================';
PRINT '2. RFM SEGMENTATION PREP (Customer Dimension)';
PRINT '================================================';
-- R: Recency (Days since last purchase)
-- F: Frequency (Total distinct invoices)
-- M: Monetary (Total revenue)

IF NOT EXISTS (
    SELECT * FROM sys.columns 
    WHERE object_id = OBJECT_ID('gold.dim_customer') AND name = 'Recency'
)
BEGIN
    ALTER TABLE gold.dim_customer ADD 
        Recency INT,
        Frequency INT,
        Monetary FLOAT,
        RFM_Segment VARCHAR(50);
END
GO

-- Step A: Calculate R, F, M scores
WITH Customer_RFM AS (
    SELECT 
        c.Customer_key,
        -- Recency: Days between their last purchase and the absolute max date in our dataset (Dec 2011)
        DATEDIFF(DAY, MAX(d.Date), (SELECT MAX(Date) FROM gold.dim_date)) AS Recency,
        -- Frequency: Count of unique invoices
        COUNT(DISTINCT f.Invoice_no) AS Frequency,
        -- Monetary: Total gross revenue
        SUM(f.Revenue) AS Monetary
    FROM gold.fact_sales f
    JOIN gold.dim_customer c ON f.Customer_key = c.Customer_key
    JOIN gold.dim_date d ON f.Date_key = d.Date_key
    WHERE f.Is_cancelled = 0 AND f.Is_anomaly_price = 0 AND c.Customer_id != -1
    GROUP BY c.Customer_key
)
UPDATE c
SET 
    c.Recency = rfm.Recency,
    c.Frequency = rfm.Frequency,
    c.Monetary = rfm.Monetary
FROM gold.dim_customer c
JOIN Customer_RFM rfm ON c.Customer_key = rfm.Customer_key;

-- Step B: Assign RFM Segments using business logic
UPDATE gold.dim_customer
SET RFM_Segment = 
    CASE 
        WHEN Recency <= 30 AND Frequency >= 5 AND Monetary >= 1000 THEN 'Champions'
        WHEN Recency <= 90 AND Frequency >= 3 AND Monetary >= 500 THEN 'Loyal Customers'
        WHEN Recency <= 30 AND Frequency = 1 THEN 'Recent / New'
        WHEN Recency > 180 AND Frequency >= 3 THEN 'At Risk (Churning)'
        WHEN Recency > 180 AND Frequency = 1 THEN 'Lost / One-Time'
        ELSE 'Regular / Average'
    END
WHERE Customer_id != -1;
GO
PRINT '>> RFM Segmentation successfully applied to dim_customer.';
