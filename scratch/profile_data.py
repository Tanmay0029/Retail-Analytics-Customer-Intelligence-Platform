import pandas as pd
import json

def analyze_data():
    print("Loading data...")
    df1 = pd.read_csv(r"datasets\online_retail_II.csv", encoding="windows-1252", on_bad_lines="skip")
    df2 = pd.read_csv(r"datasets\online_retail_II_2.csv", encoding="windows-1252", on_bad_lines="skip")
    
    df = pd.concat([df1, df2], ignore_index=True)
    
    report = {}
    report["Total_Rows"] = len(df)
    
    # 1. Invoice Analysis
    invoices = df['Invoice'].astype(str)
    report["Invoice"] = {
        "Cancellations_Count": int(invoices.str.startswith('C', na=False).sum()),
        "Other_Letters_Count": int(invoices.str.contains('^[A-B,D-Z]', na=False, regex=True).sum()),
        "Nulls": int(df['Invoice'].isna().sum())
    }
    
    # 2. StockCode Analysis
    stock_codes = df['StockCode'].astype(str)
    non_standard = stock_codes[~stock_codes.str.match(r'^\d{5}[a-zA-Z]?$', na=False)]
    report["StockCode"] = {
        "Nulls": int(df['StockCode'].isna().sum()),
        "Unique_Non_Standard": non_standard.unique().tolist()[:20] # get top 20 weird codes
    }
    
    # 3. Description Analysis
    report["Description"] = {
        "Nulls": int(df['Description'].isna().sum()),
        "Unique_Descriptions": int(df['Description'].nunique())
    }
    
    # 4. Quantity Analysis
    report["Quantity"] = {
        "Nulls": int(df['Quantity'].isna().sum()),
        "Negatives": int((df['Quantity'] < 0).sum()),
        "Zeros": int((df['Quantity'] == 0).sum()),
        "Max": int(df['Quantity'].max()),
        "Min": int(df['Quantity'].min())
    }
    
    # 5. Price Analysis
    report["Price"] = {
        "Nulls": int(df['Price'].isna().sum()),
        "Negatives": int((df['Price'] < 0).sum()),
        "Zeros": int((df['Price'] == 0).sum()),
        "Max": float(df['Price'].max()),
        "Min": float(df['Price'].min())
    }
    
    # 6. Customer ID Analysis
    report["Customer_ID"] = {
        "Nulls": int(df['Customer ID'].isna().sum()),
        "Unique_Customers": int(df['Customer ID'].nunique())
    }
    
    # 7. Country Analysis
    report["Country"] = {
        "Nulls": int(df['Country'].isna().sum()),
        "Unspecified_Count": int((df['Country'] == 'Unspecified').sum()),
        "Unique_Countries": int(df['Country'].nunique())
    }
    
    with open("scratch/data_profiling.json", "w") as f:
        json.dump(report, f, indent=4)
        
    print("Analysis complete. Saved to scratch/data_profiling.json")

if __name__ == "__main__":
    analyze_data()
