import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

df = pd.read_csv(r'C:\Users\chent\OneDrive\Desktop\DataCO-SupplyChain.csv', encoding='latin-1')

print("Shape:", df.shape)
print("\nColumns:", df.columns.tolist())
print("\nFirst 5 rows:")
print(df.head())

# How many rows and columns
print("Total Rows & Columns:", df.shape)

# Column names
print("\nAll Columns:\n", df.columns.tolist())

# Data types
print("\nData Types:\n", df.dtypes)

# Check missing values
print("\nMissing Values:\n", df.isnull().sum())

# Basic statistics
print("\nBasic Statistics:\n", df.describe())

# Fix date columns
# Fix date columns
df['order date (DateOrders)'] = pd.to_datetime(df['order date (DateOrders)'], format='mixed', dayfirst=True)
df['shipping date (DateOrders)'] = pd.to_datetime(df['shipping date (DateOrders)'], format='mixed', dayfirst=True)

# Extract useful date parts
df['order_year'] = df['order date (DateOrders)'].dt.year
df['order_month'] = df['order date (DateOrders)'].dt.month
df['order_quarter'] = df['order date (DateOrders)'].dt.quarter

# Calculate actual delay
df['delay_days'] = df['Days for shipping (real)'] - df['Days for shipment (scheduled)']

# Drop columns not needed
df.drop(columns=['Customer Email', 'Customer Password', 
                 'Product Image', 'Product Description'], 
        inplace=True, errors='ignore')

print("Cleaning done!")
print("New columns added:", ['order_year', 'order_month', 'order_quarter', 'delay_days'])
print("Shape after cleaning:", df.shape)

market_sales = df.groupby('Market')['Sales'].sum().sort_values(ascending=False)

plt.figure(figsize=(8, 5))
sns.barplot(x=market_sales.index, y=market_sales.values, palette='Blues_d')
plt.title('Total Sales by Market')
plt.xlabel('Market')
plt.ylabel('Total Sales')
plt.tight_layout()
plt.savefig('chart1_sales_by_market.png')
plt.show()
print("Chart 1 saved!")

# ============================================
# STEP 5 - CHART 2: Late Delivery Rate by Shipping Mode
# ============================================

late_delivery = df.groupby('Shipping Mode')['Late_delivery_risk'].mean() * 100

plt.figure(figsize=(8, 5))
sns.barplot(x=late_delivery.index, y=late_delivery.values, palette='Reds_d')
plt.title('Late Delivery Rate by Shipping Mode (%)')
plt.xlabel('Shipping Mode')
plt.ylabel('Late Delivery Rate (%)')
plt.tight_layout()
plt.savefig('chart2_late_delivery.png')
plt.show()
print("Chart 2 saved!")

# ============================================
# STEP 6 - CHART 3: Monthly Sales Trend
# ============================================

monthly_sales = df.groupby(['order_year', 'order_month'])['Sales'].sum().reset_index()
monthly_sales['period'] = monthly_sales['order_year'].astype(str) + '-' + monthly_sales['order_month'].astype(str).str.zfill(2)

plt.figure(figsize=(12, 5))
plt.plot(monthly_sales['period'], monthly_sales['Sales'], marker='o', color='steelblue')
plt.title('Monthly Sales Trend')
plt.xlabel('Month')
plt.ylabel('Total Sales')
plt.xticks(rotation=45)
plt.tight_layout()
plt.savefig('chart3_monthly_trend.png')
plt.show()
print("Chart 3 saved!")

# ============================================
# STEP 7 - CHART 4: Profit by Customer Segment
# ============================================

segment_profit = df.groupby('Customer Segment')['Order Profit Per Order'].sum().sort_values(ascending=False)

plt.figure(figsize=(8, 5))
sns.barplot(x=segment_profit.index, y=segment_profit.values, palette='Greens_d')
plt.title('Total Profit by Customer Segment')
plt.xlabel('Customer Segment')
plt.ylabel('Total Profit')
plt.tight_layout()
plt.savefig('chart4_profit_by_segment.png')
plt.show()
print("Chart 4 saved!")



# ============================================
# STEP 8 - CHART 5: Delay Days by Shipping Mode
# ============================================

plt.figure(figsize=(8, 5))
sns.boxplot(x='Shipping Mode', y='delay_days', data=df, palette='Set2')
plt.title('Shipping Delay Distribution by Shipping Mode')
plt.xlabel('Shipping Mode')
plt.ylabel('Delay Days')
plt.tight_layout()
plt.savefig('chart5_delay_boxplot.png')
plt.show()
print("Chart 5 saved!")

print("\n✅ All 5 charts completed! EDA Phase 2 done!")
