# System Architecture & Data Flow

This document outlines the architectural decisions and data flow for the Retail Analytics Data Warehouse.

## 1. High Level Architecture

The pipeline follows a Medallion Architecture pattern built entirely within SQL Server using Stored Procedures for ETL orchestration.

```mermaid
flowchart LR
    subgraph Sources [Sources]
        CSV[Raw CSV Files]
    end

    subgraph DataWarehouse [SQL Server Data Warehouse]
        direction LR
        Bronze[(Bronze Layer\nRaw Data)]
        Silver[(Silver Layer\nCleansed Data)]
        Gold[(Gold Layer\nStar Schema)]
        
        Bronze -- Stored Proc --> Silver
        Silver -- Stored Proc --> Gold
    end

    subgraph Consume [Consumption]
        PBI[Power BI\nDashboards]
        SQL[Ad-Hoc SQL]
    end

    CSV -- Bulk Insert --> Bronze
    Gold --> PBI
    Gold --> SQL
```

## 2. Data Flow (Lineage)

```mermaid
flowchart LR
    CSV1[online_retail_II.csv] --> B_OR[bronze.online_retail]
    CSV2[online_retail_II_2.csv] --> B_OR
    
    B_OR --> S_OR[silver.online_retail]
    
    S_OR --> G_DD[gold.dim_date]
    S_OR --> G_DC[gold.dim_customer]
    S_OR --> G_DP[gold.dim_product]
    S_OR --> G_FS[gold.fact_sales]
```

## 3. Data Integration & Transformations (Silver Layer)
Instead of filtering out messy data, the Silver layer uses a **"Tag, Don't Delete"** strategy. 

* **Type Casting:** Strings safely cast to `INT`, `FLOAT`, and `DATETIME`.
* **String Standardization:** Leading/trailing spaces and hidden carriage returns (`CHAR(13)`) removed.
* **Date Parsing:** Explicitly parsing British date formats (`DD-MM-YYYY`) using style `105`.
* **Business Logic Flags:**
  * `Is_cancelled`: Flags invoices starting with 'C'.
  * `Is_non_product`: Flags operational stock codes (e.g., 'POST', 'M').
  * `Is_anonymous_customer`: Flags transactions missing a Customer ID (Mapped to `-1`).
  * `Is_anomaly_price`: Flags rows where Price <= 0.
  * `Is_inventory_adjustment`: Flags rows where Quantity < 0 without a cancellation invoice.

## 4. Sales Data Mart (Gold Layer Star Schema)

The Gold layer implements a Kimball Star Schema. A key design decision was generating Customer "Profiles" by combining `Customer_id` and `Country` to accurately track geographic sales even for anonymous users.

```mermaid
erDiagram
    dim_customer ||--o{ fact_sales : "Customer_key"
    dim_product ||--o{ fact_sales : "Product_key"
    dim_date ||--o{ fact_sales : "Date_key"

    dim_customer {
        INT Customer_key PK
        INT Customer_id
        VARCHAR Country
        DATE First_purchase_date
    }

    dim_product {
        INT Product_key PK
        VARCHAR Stock_code
        NVARCHAR Description
    }
    
    dim_date {
        INT Date_key PK
        DATE Date
        INT Year
        INT Quarter
        INT Month
        VARCHAR Month_name
        INT Week
        INT Day
        VARCHAR Day_name
    }

    fact_sales {
        INT Sales_key PK
        VARCHAR Invoice_no
        INT Date_key FK
        INT Customer_key FK
        INT Product_key FK
        INT Quantity
        FLOAT Unit_price
        FLOAT Revenue
        BIT Is_cancelled
        BIT Is_non_product
        BIT Is_anonymous_customer
        BIT Is_anomaly_price
        BIT Is_inventory_adjustment
    }
```
