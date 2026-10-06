IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'silver')
BEGIN
    EXEC('CREATE SCHEMA [silver]');
END
GO

IF OBJECT_ID('silver.online_retail', 'U') IS NOT NULL
    DROP TABLE silver.online_retail;
GO

CREATE TABLE silver.online_retail (
    Invoice_line_item_id INT IDENTITY(1,1) PRIMARY KEY,
    Invoice VARCHAR(50),
    Stock_code VARCHAR(50),
    Description NVARCHAR(MAX),
    Quantity INT,
    Invoice_date DATETIME,
    Price FLOAT,
    Customer_id INT,
    Country VARCHAR(100),
    
    -- Derived Metrics
    Revenue FLOAT,
    
    -- Date Columns
    Order_date DATE,
    Order_year INT,
    Order_quarter INT,
    Order_month INT,
    Order_week INT,
    Order_day INT,
    Order_day_name VARCHAR(20),

    -- Anomaly & Data Quality Flags
    Is_cancelled BIT,
    Is_non_product BIT,
    Is_anonymous_customer BIT,
    Is_anomaly_price BIT,
    Is_inventory_adjustment BIT
);
GO
