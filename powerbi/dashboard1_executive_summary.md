# Dashboard 1: Executive Sales Summary

## 🎯 Goal Description
Provide the CEO and executive team with a high-level overview of business health, tracking pure Gross Sales by explicitly filtering out noise (cancellations, bad debt, and non-product fees).

## 🧮 DAX Measures
Before building visuals, we created a dedicated `_Key Measures` table to hold our core calculations.

**1. Total Revenue**
*Why it was needed:* We needed a clean revenue number that ignored operational fees, refunds, and accounting adjustments.
```dax
Total Revenue = 
CALCULATE(
    SUM('gold fact_sales'[Revenue]),
    'gold fact_sales'[Is_cancelled] = False,
    'gold fact_sales'[Is_anomaly_price] = False,
    'gold fact_sales'[Is_non_product] = False
)
```

**2. Total Items Sold**
*Why it was needed:* To track physical volume moved by the warehouse.
```dax
Total Items Sold = 
CALCULATE(
    SUM('gold fact_sales'[Quantity]),
    'gold fact_sales'[Is_cancelled] = False,
    'gold fact_sales'[Is_anomaly_price] = False,
    'gold fact_sales'[Is_non_product] = False
)
```

**3. Total Valid Orders**
*Why it was needed:* To track how many successful checkout events occurred.
```dax
Total Valid Orders = 
CALCULATE(
    DISTINCTCOUNT('gold fact_sales'[Invoice_no]),
    'gold fact_sales'[Is_cancelled] = False,
    'gold fact_sales'[Is_anomaly_price] = False,
    'gold fact_sales'[Is_non_product] = False
)
```

**4. Lost Revenue (Cancellations)**
*Why it was needed:* To show the financial hit the company took from returns.
```dax
Lost Revenue = 
CALCULATE(
    SUM('gold fact_sales'[Revenue]),
    'gold fact_sales'[Is_cancelled] = True
)
```

## 📊 Visualizations (The Canvas)
**A. High-Level KPIs (Top Row)**
- Add **Card** visuals for `[Total Revenue]`, `[Total Items Sold]`, and `[Total Valid Orders]`.

**B. Monthly Revenue Trend (Middle Large)**
- Add a **Line Chart**.
- **X-Axis:** `Year` and `Month` (from `gold dim_date`).
- **Y-Axis:** `[Total Revenue]`.
- *Insight:* Shows seasonality and overall growth trajectory over the two-year period.

**C. Revenue by Top 5 Countries (Bottom Left)**
- Add a **Clustered Bar Chart**.
- **Y-Axis:** `Country` (from `gold dim_customer`).
- **X-Axis:** `[Total Revenue]`.
- **Filter:** Top N = 5 by Total Revenue.

**D. Lost Revenue KPI (Bottom Right)**
- Add a **Card** visual with a red font color.
- **Value:** `[Lost Revenue]`.

## 🧠 Key Technical Learnings & Discussions
* **The "Tag, Don't Delete" Principle:** Instead of deleting cancelled orders in the ETL pipeline, we flagged them. This allowed us to instantly calculate "Lost Revenue" on the dashboard by simply flipping the `Is_cancelled` DAX switch from `False` to `True`.
* **Handling Fees & Postage:** We explicitly filtered out `Is_non_product = False` to ensure operational costs like "BANK CHARGES" didn't artificially inflate our gross product sales.
* **Continuous Date Tables:** Power BI requires gapless date tables for time intelligence. We generated a recursive CTE in SQL to build `dim_date` rather than relying on standard auto-date features.
