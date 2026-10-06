IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'bronze')
BEGIN
    EXEC('CREATE SCHEMA [bronze]');
END
GO

IF OBJECT_ID('bronze.online_retail', 'U') IS NOT NULL
    DROP TABLE bronze.online_retail;
GO

CREATE TABLE bronze.online_retail (
    Invoice NVARCHAR(MAX),
    StockCode NVARCHAR(MAX),
    Description NVARCHAR(MAX),
    Quantity NVARCHAR(MAX),
    InvoiceDate NVARCHAR(MAX),
    Price NVARCHAR(MAX),
    Customer_ID NVARCHAR(MAX),
    Country NVARCHAR(MAX)
);
GO