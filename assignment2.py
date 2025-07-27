import pandas as pd

# Load the dataset
df = pd.read_csv("Superstore.csv")

# Task 1: Preview and inspect
print(df.head())  # Top 5 records
print(df.shape)   # (rows, columns)
print(df.dtypes)  # Column types

# Task 2: Clean column names and convert date columns
df.columns = df.columns.str.strip().str.replace(' ', '_').str.replace('/', '_')
df['Order_Date'] = pd.to_datetime(df['Order_Date'], format='%d-%m-%Y')
df['Ship_Date'] = pd.to_datetime(df['Ship_Date'], format='%d-%m-%Y')

# Task 3: Profitability by Region and Category
profitability = df.groupby(['Region', 'Category']).agg({
    'Sales': 'sum',
    'Profit': 'sum',
    'Discount': 'mean'
}).reset_index()
most_profitable = profitability.sort_values(by='Profit', ascending=False).head(1)
print(profitability)
print("Most Profitable Region+Category:\n", most_profitable)

# Task 4: Top 5 Most Profitable Products
top_5_products = df.groupby('Product_Name')['Profit'].sum().sort_values(ascending=False).head(5)
print("Top 5 Most Profitable Products:\n", top_5_products)

# Task 5: Monthly Sales Trend
df['Order_Month'] = df['Order_Date'].dt.to_period('M')
monthly_sales = df.groupby('Order_Month')['Sales'].sum().reset_index()
print("Monthly Sales Trend:\n", monthly_sales)

# Task 6: Cities with Highest Average Order Value
df['Order_Value'] = df['Sales'] / df['Quantity']
top_cities = df.groupby('City')['Order_Value'].mean().sort_values(ascending=False).head(10)
print("Top 10 Cities by Average Order Value:\n", top_cities)

# Task 7: Identify and Save Orders with Loss
loss_orders = df[df['Profit'] < 0]
loss_orders.to_csv("loss_orders.csv", index=False)
print("Loss-making orders saved to loss_orders.csv")

# Task 8: Detect Nulls and Fill Missing Price
df['Price'] = df['Sales'] / df['Quantity']
null_counts = df.isnull().sum()
print("Missing Values:\n", null_counts)

if 'Price' in df.columns:
    df['Price'] = df['Price'].fillna(1)
