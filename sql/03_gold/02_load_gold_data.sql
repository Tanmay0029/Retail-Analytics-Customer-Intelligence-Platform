/*
===============================================================================
Stored Procedure: Load Gold Layer (Silver -> Gold)
===============================================================================
Script Purpose:
    This stored procedure takes the cleaned Silver table and splits it into a 
    Star Schema consisting of Fact and Dimension tables for Power BI.
===============================================================================
*/
CREATE OR ALTER PROCEDURE gold.load_gold AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME; 
	BEGIN TRY
		PRINT '================================================';
		PRINT 'Loading Gold Layer (Star Schema)';
		PRINT '================================================';

		-- Truncate Fact table first because of Foreign Key constraints
		PRINT '>> Truncating fact_sales';
		TRUNCATE TABLE gold.fact_sales; 

		--------------------------------------------------
		-- 1. Load dim_product
		--------------------------------------------------
		SET @start_time = GETDATE();
		PRINT '>> Loading dim_product';
		DELETE FROM gold.dim_product;
		DBCC CHECKIDENT ('gold.dim_product', RESEED, 0);

		-- Use ROW_NUMBER to get the most recent description for a stock code
		WITH RankedProducts AS (
			SELECT 
				Stock_code, 
				Description,
				ROW_NUMBER() OVER(PARTITION BY Stock_code ORDER BY Invoice_date DESC) as rn
			FROM silver.online_retail
		)
		INSERT INTO gold.dim_product (Stock_code, Description)
		SELECT 
			Stock_code, 
			Description
		FROM RankedProducts
		WHERE rn = 1;
		SET @end_time = GETDATE();
		PRINT '   - Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';

		--------------------------------------------------
		-- 2. Load dim_customer
		--------------------------------------------------
		SET @start_time = GETDATE();
		PRINT '>> Loading dim_customer';
		DELETE FROM gold.dim_customer;
		DBCC CHECKIDENT ('gold.dim_customer', RESEED, 0);

		-- Grain is Customer_id + Country 
		WITH CustomerGroup AS (
			SELECT 
				Customer_id,
				Country,
				MIN(Order_date) AS First_purchase_date
			FROM silver.online_retail
			GROUP BY Customer_id, Country
		)
		INSERT INTO gold.dim_customer (Customer_id, Country, First_purchase_date)
		SELECT Customer_id, Country, First_purchase_date
		FROM CustomerGroup;
		SET @end_time = GETDATE();
		PRINT '   - Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';

		--------------------------------------------------
		-- 3. Load dim_date
		--------------------------------------------------
		SET @start_time = GETDATE();
		PRINT '>> Loading dim_date';
		DELETE FROM gold.dim_date;

		-- Power BI requires a Date Table to have NO gaps in dates. 
        -- So instead of picking distinct dates from sales, we generate a continuous calendar.
		DECLARE @StartDate DATE = (SELECT MIN(Order_date) FROM silver.online_retail);
		DECLARE @EndDate DATE = (SELECT MAX(Order_date) FROM silver.online_retail);

		WITH DateGenerator AS (
			SELECT @StartDate AS DateValue
			UNION ALL
			SELECT DATEADD(day, 1, DateValue)
			FROM DateGenerator
			WHERE DateValue < @EndDate
		)
		INSERT INTO gold.dim_date (Date_key, Date, Year, Quarter, Month, Month_name, Week, Day, Day_name)
		SELECT 
			CAST(CONVERT(VARCHAR(8), DateValue, 112) AS INT) AS Date_key, 
			DateValue AS Date,
			YEAR(DateValue) AS Year,
			DATEPART(QUARTER, DateValue) AS Quarter,
			MONTH(DateValue) AS Month,
			DATENAME(MONTH, DateValue) AS Month_name,
			DATEPART(WEEK, DateValue) AS Week,
			DAY(DateValue) AS Day,
			DATENAME(WEEKDAY, DateValue) AS Day_name
		FROM DateGenerator
		OPTION (MAXRECURSION 0); -- Allows infinite recursion for large date ranges
		SET @end_time = GETDATE();
		PRINT '   - Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';

		--------------------------------------------------
		-- 4. Load fact_sales
		--------------------------------------------------
		SET @start_time = GETDATE();
		PRINT '>> Loading fact_sales';
		
		INSERT INTO gold.fact_sales (
			Invoice_no, Date_key, Customer_key, Product_key, 
			Quantity, Unit_price, Revenue, Is_cancelled, Is_non_product, 
			Is_anonymous_customer, Is_anomaly_price, Is_inventory_adjustment
		)
		SELECT 
			s.Invoice,
			CAST(CONVERT(VARCHAR(8), s.Order_date, 112) AS INT) AS Date_key,
			c.Customer_key,
			p.Product_key,
			s.Quantity,
			s.Price,
			s.Revenue,
			s.Is_cancelled,
			s.Is_non_product,
			s.Is_anonymous_customer,
			s.Is_anomaly_price,
			s.Is_inventory_adjustment
		FROM silver.online_retail s
        -- Crucial: Join on BOTH Customer_id and Country to get the correct profile key!
		LEFT JOIN gold.dim_customer c ON s.Customer_id = c.Customer_id AND s.Country = c.Country
		LEFT JOIN gold.dim_product p ON s.Stock_code = p.Stock_code;
		
		SET @end_time = GETDATE();
		PRINT '   - Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';

		PRINT '=========================================='
		PRINT 'Gold Layer Loading Completed Successfully!';
		PRINT '=========================================='

	END TRY
	BEGIN CATCH
		PRINT '=========================================='
		PRINT 'ERROR OCCURRED DURING LOADING GOLD LAYER'
		PRINT 'Error Message: ' + ERROR_MESSAGE();
		PRINT '=========================================='
	END CATCH
END
GO
