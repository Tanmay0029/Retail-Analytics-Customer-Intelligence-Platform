# Dashboard 4: Geographic Trends

## 🎯 Goal Description
Analyze international growth markets and Average Order Values (AOV) by explicitly removing the massive domestic (UK) bias from the visuals, allowing executives to actually see foreign performance.

## 🧮 DAX Measures & Calculated Columns

**1. Market_Type (Calculated Column)**
*Why it was needed:* We needed a clean way to bucket customers into Domestic or International so we can easily filter them on visuals without writing complex DAX every time.
*Location:* Added as a New Column in `gold dim_customer`.
```dax
Market_Type = IF('gold dim_customer'[Country] = "United Kingdom", "Domestic (UK)", "International")
```

**2. Average Order Value (AOV)**
*Why it was needed:* To see which countries place the largest/wealthiest orders on average, regardless of their total volume. We divide Total Revenue by the distinct count of valid invoices.
```dax
AOV = 
VAR ValidOrders = 
    CALCULATE(
        DISTINCTCOUNT('gold fact_sales'[Invoice_no]),
        'gold fact_sales'[Is_cancelled] = False,
        'gold fact_sales'[Is_anomaly_price] = False,
        'gold fact_sales'[Is_non_product] = False
    )
RETURN 
    DIVIDE([Total Revenue], ValidOrders)
```

## 📊 Visualizations (The Canvas)

**A. Domestic vs International Split (Top Left)**
- Add a **Donut Chart**.
- **Legend:** `Market_Type` (from `dim_customer`).
- **Values:** `[Total Revenue]`.
- *Insight:* Immediately shows executives how much of the business relies on the UK vs global expansion.

**B. Global Revenue Map (Top Right - Large)**
- Add a **Map** visual (the globe icon).
- **Location:** `Country` (from `dim_customer`).
- **Bubble Size:** `[Total Revenue]`.
- **Tooltips:** Drag `[AOV]`, `[Retained Customers]`, and `[Total Items Sold]` here to create a "Rich Tooltip" dossier when hovering over a country.
- **Bubble Colors (Conditional Formatting):** Set to Gradient based on `[AOV]`. 

**C. Top 5 International Growth Markets (Bottom Left)**
- Add a **Clustered Bar Chart**.
- **Y-axis:** `Country`.
- **X-axis:** `[Total Revenue]`.
- **Filter:** Filter `Market_Type` to ONLY show "International". Then filter `Country` to Top 5.

**D. Average Order Value by Country (Bottom Right)**
- Add a **Table** visual.
- **Columns:** `Country`, `[Total Revenue]`, and `[AOV]`.
- **Sort:** Sort by `AOV` Descending.

## 🧠 Key Technical Learnings & Discussions
* **Rich Tooltips & Conditional Formatting:** We elevated a basic Map visual to an executive-level tool by dragging multiple metrics into the Tooltips well. We also applied Gradient Conditional Formatting to the bubble colors based on AOV. This allowed users to instantly spot a 4-dimensional insight: a country with a small, dark bubble places very few, but extremely expensive orders!
* **The "Missing $8.5M" Power BI Trap:** We encountered a major discrepancy where the Donut Chart showed UK Revenue as $16.8M, but the Table visual only showed $8.25M. We diagnosed this through a 3-step audit checklist:
  1. **Visual Filters:** Checking if Anonymous checkouts (`Customer_id = -1`) were accidentally filtered out of the table via the filter pane.
  2. **Measure Mismatch:** Ensuring both visuals used the clean `[Total Revenue]` measure, rather than the raw `Revenue` column which inflates numbers with bad debt and anomalies.
  3. **The Blank Hiding Trap:** If a custom measure like `AOV` evaluates to `BLANK` for a specific grouping of data, Power BI will literally hide the entire row from the table, rendering millions of dollars invisible without warning!
