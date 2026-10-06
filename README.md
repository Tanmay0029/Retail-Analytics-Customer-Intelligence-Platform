# Retail Analytics Data Warehouse

## 📌 Project Overview
This project is an end-to-end Data Engineering and Analytics pipeline built on SQL Server. It processes over 1 million rows of messy, real-world retail transaction data into a pristine Data Warehouse optimized for Power BI reporting. 

The architecture follows the **Medallion Architecture** (Bronze, Silver, Gold) combined with **Kimball Dimensional Modeling** to create a highly performant Star Schema.

## 🏗️ Architecture
The data pipeline consists of three distinct layers:
1. **Bronze Layer (Raw):** Ingests raw CSV data using `BULK INSERT`. All columns are loaded as `NVARCHAR(MAX)` to prevent ingestion failures.
2. **Silver Layer (Cleansed):** Transforms the data by casting data types, standardizing strings, stripping hidden carriage returns, handling missing customers, and generating calculated columns (Revenue). Instead of hard-deleting messy data, we employ a **"Tag, Don't Delete"** strategy using bit flags (e.g., `Is_cancelled`, `Is_inventory_adjustment`).
3. **Gold Layer (Business-Ready):** Restructures the flat Silver table into a classic **Star Schema** with Surrogate Keys, enabling highly performant joins and complex time-intelligence reporting in Power BI.

For full architectural details and diagrams, see [docs/architecture.md](docs/architecture.md).

## 🗂️ Repository Structure
* `/datasets`: Contains the raw source CSV files.
* `/sql/01_bronze`: DDL and ETL scripts for the raw data ingestion.
* `/sql/02_silver`: DDL and ETL scripts for data cleansing and standardization.
* `/sql/03_gold`: DDL and ETL scripts for building the Dimensional Model (Star Schema).
* `/tests`: Data Quality (DQ) scripts to validate row counts, foreign key integrity, and business logic across all layers.
* `/docs`: Project documentation, data dictionaries, and naming conventions.
* `/powerbi`: Contains the final Power BI dashboard documentation, DAX logic, and deep-dive technical discussions:
  * [Dashboard 1: Executive Sales Summary](powerbi/dashboard1_executive_summary.md)
  * [Dashboard 2: Customer Insights & Retention](powerbi/dashboard2_customer_retention.md)
  * [Dashboard 3: Product Performance & Pareto](powerbi/dashboard3_product_performance.md)
  * [Dashboard 4: Geographic Trends](powerbi/dashboard4_geographic_trends.md)

## 📚 Documentation
* [Architecture & Data Flow](docs/architecture.md)
* [Data Catalog / Dictionary](docs/data_catalog.md)
* [Naming Conventions](docs/naming_conventions.md)
