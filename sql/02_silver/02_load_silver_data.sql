/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
    This stored procedure performs the "Extract, Transform, Load" (ETL) process 
    to move data from the raw Bronze layer into the clean Silver layer.

    Instead of deleting bad data, we use a "Tag, Don't Delete" strategy.
    Anomalies are flagged with BIT columns (1 = True, 0 = False) so they can 
    be filtered dynamically in Power BI.
===============================================================================
*/
CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME; 
	BEGIN TRY
		PRINT '================================================';
		PRINT 'Loading Silver Layer (Tag, Don''t Delete Strategy)';
		PRINT '================================================';

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.online_retail';
		TRUNCATE TABLE silver.online_retail;

		PRINT '>> Transforming and Inserting Data Into: silver.online_retail';
        
        WITH BaseData AS (
            SELECT
                LTRIM(RTRIM(Invoice)) AS Invoice,
                LTRIM(RTRIM(StockCode)) AS Stock_code,
                
                -- Standardize Description:
                -- 1. If NULL or contains NO letters (e.g. '?', '22467'), flag as UNKNOWN PRODUCT
                -- 2. If it starts with '*', strip the asterisk
                -- 3. Capitalize (UPPER) and trim everything else
                CASE 
                    WHEN Description IS NULL THEN 'UNKNOWN PRODUCT'
                    WHEN LTRIM(RTRIM(Description)) NOT LIKE '%[a-zA-Z]%' THEN 'UNKNOWN PRODUCT'
                    WHEN LEFT(LTRIM(RTRIM(Description)), 1) = '*' THEN UPPER(LTRIM(SUBSTRING(LTRIM(RTRIM(Description)), 2, LEN(Description))))
                    ELSE UPPER(LTRIM(RTRIM(Description)))
                END AS Description,
                
                TRY_CAST(Quantity AS INT) AS Quantity,
                -- Use style 105 to properly parse DD-MM-YYYY dates from the CSV
                TRY_CONVERT(DATETIME, InvoiceDate, 105) AS Invoice_date, 
                TRY_CAST(Price AS FLOAT) AS Price,
                
                -- Handle NULL Customers by converting to -1
                COALESCE(TRY_CAST(Customer_ID AS INT), -1) AS Customer_id,
                
                -- Standardize Country names and remove hidden carriage returns from CSV import
                CASE UPPER(REPLACE(LTRIM(RTRIM(Country)), CHAR(13), ''))
                    WHEN 'USA' THEN 'United States of America'
                    WHEN 'RSA' THEN 'Republic of South Africa'
                    WHEN 'EIRE' THEN 'Republic of Ireland'
                    ELSE REPLACE(LTRIM(RTRIM(Country)), CHAR(13), '')
                END AS Country
            FROM bronze.online_retail
        ),
        FlaggedData AS (
            SELECT 
                Invoice, Stock_code, Description, 
                COALESCE(Quantity, 0) AS Quantity, 
                Invoice_date, 
                COALESCE(Price, 0.0) AS Price, 
                Customer_id, Country,
                
                -- Derived Revenue
                (COALESCE(Quantity, 0) * COALESCE(Price, 0.0)) AS Revenue,
                
                -- Date components
                CAST(Invoice_date AS DATE) AS Order_date,
                YEAR(Invoice_date) AS Order_year,
                DATEPART(QUARTER, Invoice_date) AS Order_quarter,
                MONTH(Invoice_date) AS Order_month,
                DATEPART(WEEK, Invoice_date) AS Order_week,
                DAY(Invoice_date) AS Order_day,
                DATENAME(WEEKDAY, Invoice_date) AS Order_day_name,

                -- 1. Cancellation Flag
                CASE WHEN Invoice LIKE 'C%' THEN 1 ELSE 0 END AS Is_cancelled,

                -- 2. Non-Product Flag (POST, M, D, BANK CHARGES, TEST001, etc)
                -- We flag it if it doesn't match standard patterns (i.e., not starting with a number)
                CASE 
                    WHEN Stock_code IN ('POST', 'M', 'D', 'BANK CHARGES', 'TEST001', 'DOT', 'C2', 'S') THEN 1 
                    WHEN Stock_code NOT LIKE '[0-9]%' THEN 1 
                    ELSE 0 
                END AS Is_non_product,

                -- 3. Anonymous Customer Flag
                CASE WHEN Customer_id = -1 THEN 1 ELSE 0 END AS Is_anonymous_customer,

                -- 4. Anomaly Price Flag (Freebies or errors)
                CASE WHEN COALESCE(Price, 0.0) <= 0 THEN 1 ELSE 0 END AS Is_anomaly_price,

                -- 5. Inventory Adjustment Flag (Negative quantity, not a cancellation)
                CASE WHEN COALESCE(Quantity, 0) < 0 AND Invoice NOT LIKE 'C%' THEN 1 ELSE 0 END AS Is_inventory_adjustment,
                
                -- Deduplication
                ROW_NUMBER() OVER(
                    PARTITION BY Invoice, Stock_code, Quantity, Invoice_date, Customer_id 
                    ORDER BY Invoice_date
                ) as rn
            FROM BaseData
        )
        INSERT INTO silver.online_retail (
            Invoice, Stock_code, Description, Quantity, Invoice_date, Price, 
            Customer_id, Country, Revenue, Order_date, Order_year, Order_quarter, 
            Order_month, Order_week, Order_day, Order_day_name,
            Is_cancelled, Is_non_product, Is_anonymous_customer, 
            Is_anomaly_price, Is_inventory_adjustment
        )
        SELECT 
            Invoice, Stock_code, Description, Quantity, Invoice_date, Price, 
            Customer_id, Country, Revenue, Order_date, Order_year, Order_quarter, 
            Order_month, Order_week, Order_day, Order_day_name,
            Is_cancelled, Is_non_product, Is_anonymous_customer, 
            Is_anomaly_price, Is_inventory_adjustment
        FROM FlaggedData
        WHERE rn = 1; -- Drops exact duplicates

		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '=========================================='
		PRINT 'Silver Layer Loading Completed Successfully!';
		PRINT '=========================================='

	END TRY
	BEGIN CATCH
		PRINT '=========================================='
		PRINT 'ERROR OCCURRED DURING LOADING SILVER LAYER'
		PRINT 'Error Message: ' + ERROR_MESSAGE();
		PRINT '=========================================='
	END CATCH
END
GO
