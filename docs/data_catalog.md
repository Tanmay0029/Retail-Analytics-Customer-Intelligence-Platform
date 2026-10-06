# Data Catalog / Dictionary

This document describes the final Business-Ready tables available in the Gold Layer (`gold` schema) for reporting and analytics.

## 1. gold.fact_sales
The core fact table recording every individual line-item transaction.

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `Sales_key` | INT (PK) | Surrogate primary key for the transaction row. |
| `Invoice_no` | VARCHAR | The original invoice/receipt number. |
| `Date_key` | INT (FK) | Foreign key linking to `dim_date`. Formatted as YYYYMMDD. |
| `Customer_key` | INT (FK) | Foreign key linking to `dim_customer`. |
| `Product_key` | INT (FK) | Foreign key linking to `dim_product`. |
| `Quantity` | INT | Number of items purchased (or returned, if negative). |
| `Unit_price` | FLOAT | The price per single unit. |
| `Revenue` | FLOAT | Calculated metric: `Quantity * Unit_price`. |
| `Is_cancelled` | BIT | Flag (1/0) indicating if the invoice represents a cancelled order (starts with 'C'). |
| `Is_non_product` | BIT | Flag (1/0) indicating if the item is an operational charge (e.g. Postage, Bank Charges). |
| `Is_anonymous_customer` | BIT | Flag (1/0) indicating if the transaction lacked a registered Customer ID. |
| `Is_anomaly_price` | BIT | Flag (1/0) indicating if the price was <= 0 (e.g., freebies, bad debt adjustments). |
| `Is_inventory_adjustment` | BIT | Flag (1/0) indicating a warehouse stock adjustment (negative quantity without a 'C' invoice). |

## 2. gold.dim_customer
The customer profile dimension. The grain is `Customer_id` + `Country`.

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `Customer_key` | INT (PK) | Surrogate key representing a unique customer profile. |
| `Customer_id` | INT | The original natural key from the source system. `-1` represents anonymous checkouts. |
| `Country` | VARCHAR | The geographical location of the customer for this specific profile. |
| `First_purchase_date` | DATE | The date this specific customer profile made their very first purchase (Used for Cohort Analysis). |

## 3. gold.dim_product
The product dimension containing standardized item descriptions.

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `Product_key` | INT (PK) | Surrogate key representing a unique product. |
| `Stock_code` | VARCHAR | The original alphanumeric barcode/stock code from the source system. |
| `Description` | NVARCHAR | Standardized, capitalized product description. Missing descriptions are mapped to 'UNKNOWN PRODUCT'. |

## 4. gold.dim_date
A standard calendar dimension for advanced Time Intelligence in Power BI.

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `Date_key` | INT (PK) | Smart key formatted as YYYYMMDD (e.g., `20101231`). |
| `Date` | DATE | The standard SQL Date. |
| `Year` | INT | The calendar year (e.g., 2010). |
| `Quarter` | INT | The calendar quarter (1-4). |
| `Month` | INT | The calendar month (1-12). |
| `Month_name` | VARCHAR | The full name of the month (e.g., 'January'). |
| `Week` | INT | The week number of the year. |
| `Day` | INT | The day of the month (1-31). |
| `Day_name` | VARCHAR | The name of the day (e.g., 'Monday'). |
