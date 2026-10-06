# Dashboard 3: Product Performance & Pareto

## 🎯 Goal Description
Provide actionable insights to Supply Chain and Product Managers by proving the Pareto Principle (80/20 rule) and tracking warehouse shrinkage.

## 🧮 DAX Measures

**1. Cumulative Pareto %**
*Why it was needed:* To plot a line curve proving that a small percentage of products drive the vast majority of revenue. It uses a dynamic running total that ranks products from highest to lowest.
```dax
Pareto % = 
VAR GrandTotal = 
    CALCULATE(
        [Total Revenue], 
        ALL('gold dim_product'),
        'gold dim_product'[Description] <> "UNKNOWN PRODUCT"
    )
VAR CurrentProductRevenue = [Total Revenue]
VAR CumulativeRevenue = 
    SUMX(
        FILTER(
            ALL('gold dim_product'[Stock_code], 'gold dim_product'[Description]),
            [Total Revenue] >= CurrentProductRevenue &&
            'gold dim_product'[Description] <> "UNKNOWN PRODUCT"
        ),
        [Total Revenue]
    )
RETURN
    DIVIDE(CumulativeRevenue, GrandTotal)
```

**2. Total Units Returned**
*Why it was needed:* We needed to count how many physical items were shipped back to the warehouse, allowing Supply Chain to identify defective product lines.
```dax
Units Returned = 
CALCULATE(
    ABS(SUM('gold fact_sales'[Quantity])),
    'gold fact_sales'[Is_cancelled] = True
)
```

**3. Warehouse Shrinkage (Units)**
*Why it was needed:* This uses our custom Silver flag to show how many items the warehouse lost due to breakage or miscounting. 
```dax
Warehouse Shrinkage (Units) = 
CALCULATE(
    ABS(SUM('gold fact_sales'[Quantity])),
    'gold fact_sales'[Is_inventory_adjustment] = True
)
```

## 📊 Visualizations (The Canvas)

**A. The Pareto Chart (Top Half)**
- Add a **Line and Stacked Column Chart**.
- **X-axis:** `Description` (from `dim_product`). Filter to **Top 50**.
- **Column y-axis:** `[Total Revenue]`.
- **Line y-axis:** `[Pareto %]`.
- **Sort:** Sort Axis -> Total Revenue -> Descending.

**B. Top 10 Most Returned Products (Bottom Left)**
- Add a **Bar Chart**.
- **Y-axis:** `Description`.
- **X-axis:** `[Units Returned]`.
- **Filter:** Top 10 by `[Units Returned]`.

**C. Warehouse Shrinkage KPI (Bottom Right)**
- Add a **Card** visual.
- Drag in `[Warehouse Shrinkage (Units)]`.

## 🧠 Key Technical Learnings & Discussions
* **The Pareto DAX Logic:** We used a combination of `SUMX` and `FILTER` to create a dynamic running total. By asking DAX to sum the revenue of all products that have a revenue `>=` the current product, we forced a cumulative curve across the chart.
* **The "UNKNOWN PRODUCT" Outlier:** When graphing the data, we noticed the curve was completely flattened by a massive $1M+ outlier. This was the "UNKNOWN PRODUCT" bucket we created in the Silver layer to catch missing descriptions. We had to apply a filter directly inside the DAX measure to exclude it so the chart tracked *real* physical items.
* **The ALL vs ALLSELECTED DAX Trap:** Initially, the Pareto line stopped at 94.5% instead of hitting 100%. We realized that if we use `ALLSELECTED` while a "Top 50" visual filter is active, the denominator shrinks to match only the Top 50 products. To calculate the percentage against the *entire company catalog* ($18.5M), we reverted to `ALL('gold dim_product')`. This correctly forced the right side of the chart to end at 21.03%, proving that 50 items drive 21% of the entire 4,000+ item catalog.
* **Shrinkage by Quantity vs Revenue:** Our original `Warehouse Shrinkage ($)` DAX kept returning $0, while SQL was returning negative numbers. We realized that warehouse workers log inventory adjustments (broken stock) with a Unit Price of `$0.00`. Therefore, measuring shrinkage by *Revenue* is impossible. The negative numbers in SQL were actually from `Is_anomaly_price` (Bad Debt). We pivoted and changed the measure to track Shrinkage by *Quantity* (Units Lost).
