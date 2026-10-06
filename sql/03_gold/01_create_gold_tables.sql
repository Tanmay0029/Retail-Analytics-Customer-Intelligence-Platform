IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'gold')
BEGIN
    EXEC('CREATE SCHEMA [gold]');
END
GO

-- 1. dim_date
IF OBJECT_ID('gold.dim_date', 'U') IS NOT NULL DROP TABLE gold.dim_date;
CREATE TABLE gold.dim_date (
    Date_key INT PRIMARY KEY,
    Date DATE,
    Year INT,
    Quarter INT,
    Month INT,
    Month_name VARCHAR(20),
    Week INT,
    Day INT,
    Day_name VARCHAR(20)
);

-- 2. dim_customer (Grain: Customer_id + Country)
IF OBJECT_ID('gold.dim_customer', 'U') IS NOT NULL DROP TABLE gold.dim_customer;
CREATE TABLE gold.dim_customer (
    Customer_key INT IDENTITY(1,1) PRIMARY KEY,
    Customer_id INT,
    Country VARCHAR(100),
    First_purchase_date DATE
);

-- 3. dim_product
IF OBJECT_ID('gold.dim_product', 'U') IS NOT NULL DROP TABLE gold.dim_product;
CREATE TABLE gold.dim_product (
    Product_key INT IDENTITY(1,1) PRIMARY KEY,
    Stock_code VARCHAR(50),
    Description NVARCHAR(MAX)
);

-- 4. fact_sales
IF OBJECT_ID('gold.fact_sales', 'U') IS NOT NULL DROP TABLE gold.fact_sales;
CREATE TABLE gold.fact_sales (
    Sales_key INT IDENTITY(1,1) PRIMARY KEY,
    Invoice_no VARCHAR(50),
    Date_key INT,
    Customer_key INT,
    Product_key INT,
    Quantity INT,
    Unit_price FLOAT,
    Revenue FLOAT,
    
    -- Our awesome Silver flags carry over to the Fact table!
    Is_cancelled BIT,
    Is_non_product BIT,
    Is_anonymous_customer BIT,
    Is_anomaly_price BIT,
    Is_inventory_adjustment BIT,
    
    CONSTRAINT FK_Fact_Sales_Date FOREIGN KEY (Date_key) REFERENCES gold.dim_date(Date_key),
    CONSTRAINT FK_Fact_Sales_Customer FOREIGN KEY (Customer_key) REFERENCES gold.dim_customer(Customer_key),
    CONSTRAINT FK_Fact_Sales_Product FOREIGN KEY (Product_key) REFERENCES gold.dim_product(Product_key)
);
GO
