# Naming Conventions

To ensure consistency, readability, and a professional standard across the entire Data Warehouse, the following naming conventions are strictly enforced.

## 1. Schemas
**Convention:** `lowercase`

All schemas are entirely lowercase to cleanly separate logical layers.
* **Valid Examples:** `bronze`, `silver`, `gold`
* **Invalid Examples:** `Bronze`, `SILVER`

## 2. Tables
**Convention:** `snake_case` (lowercase with underscores)

Tables are named using descriptive, pluralized (where appropriate) nouns. For the Gold layer, table prefixes denote their role in the dimensional model.
* **Valid Examples:** `online_retail`, `dim_customer`, `fact_sales`
* **Invalid Examples:** `OnlineRetail`, `DimCustomer`, `FactSales`

## 3. Columns
**Convention:** `Capitalized_snake_case` (First word capitalized, subsequent words lowercase, separated by underscores).

* **Standard Columns:** `Invoice_date`, `Stock_code`, `Unit_price`
* **Primary / Surrogate Keys:** Must end in `_key` (e.g., `Customer_key`, `Product_key`, `Date_key`).
* **Natural / Source IDs:** Must end in `_id` or `_no` (e.g., `Customer_id`, `Invoice_no`).
* **Boolean Flags:** Must begin with `Is_` to clearly indicate a True(1)/False(0) state (e.g., `Is_cancelled`, `Is_anomaly_price`).

## 4. SQL Scripts and Stored Procedures
**Convention:** Numbered prefixes for execution order, followed by descriptive `snake_case`.

* **Scripts:** `01_create_silver_table.sql`, `02_load_silver_data.sql`
* **Procedures:** `silver.load_silver`, `gold.load_gold`
