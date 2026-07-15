CREATE DATABASE IF NOT EXISTS supply_chain_db;
USE supply_chain_db;

CREATE TABLE orders (
    Type                        VARCHAR(50),
    Days_for_shipping_real      INT,
    Days_for_shipment_scheduled INT,
    Benefit_per_order           DECIMAL(10,2),
    Sales_per_customer          DECIMAL(10,2),
    Delivery_Status             VARCHAR(50),
    Late_delivery_risk          INT,
    Category_Id                 INT,
    Category_Name               VARCHAR(100),
    Customer_City               VARCHAR(100),
    Customer_Country            VARCHAR(100),
    Customer_Email              VARCHAR(150),
    Customer_Fname              VARCHAR(100),
    Customer_Id                 INT,
    Customer_Lname              VARCHAR(100),
    Customer_Password           VARCHAR(100),
    Customer_Segment            VARCHAR(50),
    Customer_State              VARCHAR(100),
    Customer_Street             VARCHAR(200),
    Customer_Zipcode            VARCHAR(20),
    Department_Id               INT,
    Department_Name             VARCHAR(100),
    Latitude                    DECIMAL(10,6),
    Longitude                   DECIMAL(10,6),
    Market                      VARCHAR(50),
    Order_City                  VARCHAR(100),
    Order_Country               VARCHAR(100),
    Order_Customer_Id           INT,
    order_date_DateOrders       DATETIME,
    Order_Id                    INT,
    Order_Item_Cardprod_Id      INT,
    Order_Item_Discount         DECIMAL(10,2),
    Order_Item_Discount_Rate    DECIMAL(10,4),
    Order_Item_Id               INT,
    Order_Item_Product_Price    DECIMAL(10,2),
    Order_Item_Profit_Ratio     DECIMAL(10,4),
    Order_Item_Quantity         INT,
    Sales                       DECIMAL(10,2),
    Order_Item_Total            DECIMAL(10,2),
    Order_Profit_Per_Order      DECIMAL(10,2),
    Order_Region                VARCHAR(100),
    Order_State                 VARCHAR(100),
    Order_Status                VARCHAR(50),
    Order_Zipcode               VARCHAR(20),
    Product_Card_Id             INT,
    Product_Category_Id         INT,
    Product_Description         TEXT,
    Product_Image               TEXT,
    Product_Name                VARCHAR(200),
    Product_Price               DECIMAL(10,2),
    Product_Status              INT,
    shipping_date_DateOrders    DATETIME,
    Shipping_Mode               VARCHAR(50)
);
SET GLOBAL local_infile = 1;

LOAD DATA LOCAL INFILE 'C:/Users/chent/OneDrive/Desktop/Data-analysis/power bi/data-co.csv'
INTO TABLE orders
CHARACTER SET latin1
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

select * from orders ;
SELECT COUNT(*) AS total_rows
FROM orders;

-- 1.2 Check for NULL values in critical columns
SELECT
    SUM(CASE WHEN Days_for_shipping_real IS NULL THEN 1 ELSE 0 END)      AS null_actual_ship_days,
    SUM(CASE WHEN Days_for_shipment_scheduled IS NULL THEN 1 ELSE 0 END) AS null_sched_ship_days,
    SUM(CASE WHEN Sales IS NULL THEN 1 ELSE 0 END)                       AS null_sales,
    SUM(CASE WHEN Order_Profit_Per_Order IS NULL THEN 1 ELSE 0 END)      AS null_profit,
    SUM(CASE WHEN Delivery_Status IS NULL THEN 1 ELSE 0 END)             AS null_delivery_status,
    SUM(CASE WHEN Customer_Segment IS NULL THEN 1 ELSE 0 END)            AS null_segment
FROM orders;

-- 1.3 Distinct values in key categorical columns
SELECT DISTINCT Delivery_Status   FROM orders;
SELECT DISTINCT Shipping_Mode     FROM orders;
SELECT DISTINCT Customer_Segment  FROM orders;
SELECT DISTINCT Market            FROM orders;
SELECT DISTINCT Order_Status      FROM orders;
 
-- 1.5 Distribution of orders by delivery status
-- - For each delivery status, show me how many orders it has and what % of total orders that represents."
SELECT
    Delivery_Status,
    COUNT(*)                          AS order_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM orders), 2) AS pct_of_total
FROM orders
GROUP BY Delivery_Status
ORDER BY order_count DESC;
 
-- 1.6 Distribution by shipping mode
-- On average, does this shipping mode deliver on time, early, or late?
SELECT
    Shipping_Mode,
    COUNT(*)           AS order_count,
    ROUND(AVG(Days_for_shipping_real), 2)      AS avg_actual_days,
    ROUND(AVG(Days_for_shipment_scheduled), 2) AS avg_scheduled_days
FROM orders
GROUP BY Shipping_Mode
ORDER BY order_count DESC;

-- ============================================================
-- SECTION 2: KPI CALCULATIONS
-- ============================================================
 
-- 2.1 Overall KPI Dashboard
-- Out of all orders, what percentage were flagged as late?"
SELECT
    ROUND(SUM(Sales), 2)                                                             AS total_revenue,
    ROUND(SUM(Order_Profit_Per_Order), 2)                                            AS total_profit,
    ROUND(SUM(Order_Profit_Per_Order) / NULLIF(SUM(Sales), 0) * 100, 2)             AS profit_margin_pct,
    COUNT(DISTINCT Order_Id)                                                         AS total_orders,
    COUNT(DISTINCT Customer_Id)                                                      AS total_customers,
    ROUND(AVG(Order_Item_Quantity), 2)                                               AS avg_order_qty,
    ROUND(SUM(CASE WHEN Late_delivery_risk = 1 THEN 1 ELSE 0 END) * 100.0
          / COUNT(*), 2)                                                        AS late_delivery_rate_pct,
-- On average, how many days later (or earlier) than scheduled did deliveries actually arrive?"
    ROUND(AVG(Days_for_shipping_real - Days_for_shipment_scheduled), 2)             AS avg_delay_days
FROM orders;

-- 2.2 On-Time Delivery Rate
SELECT
    ROUND(
        SUM(CASE WHEN Days_for_shipping_real <= Days_for_shipment_scheduled THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 2
    ) AS on_time_delivery_rate_pct,
    ROUND(
        SUM(CASE WHEN Days_for_shipping_real > Days_for_shipment_scheduled THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 2
    ) AS late_delivery_rate_pct
FROM orders
WHERE Days_for_shipping_real IS NOT NULL
  AND Days_for_shipment_scheduled IS NOT NULL;
 
-- 2.3 Average Shipping Delay by Shipping Mode
SELECT
    Shipping_Mode,
    COUNT(*)                                                                          AS total_orders,
    ROUND(AVG(Days_for_shipping_real - Days_for_shipment_scheduled), 2)             AS avg_delay_days,
    SUM(CASE WHEN Late_delivery_risk = 1 THEN 1 ELSE 0 END)                         AS late_orders,
    ROUND(SUM(CASE WHEN Late_delivery_risk = 1 THEN 1 ELSE 0 END) * 100.0
          / COUNT(*), 2)                                                             AS late_rate_pct
FROM orders
GROUP BY Shipping_Mode
ORDER BY avg_delay_days DESC;

-- ============================================================
-- SECTION 3: REVENUE & PROFITABILITY ANALYSIS
-- ============================================================
 
-- 3.1 Revenue & Profit by Market (Region)
SELECT
    Market,
    COUNT(DISTINCT Order_Id)                                              AS total_orders,
    ROUND(SUM(Sales), 2)                                                  AS total_revenue,
    ROUND(SUM(Order_Profit_Per_Order), 2)                                 AS total_profit,
    ROUND(SUM(Order_Profit_Per_Order) / NULLIF(SUM(Sales), 0) * 100, 2)  AS profit_margin_pct,
    ROUND(AVG(Sales), 2)                                                  AS avg_order_value
FROM orders
GROUP BY Market
ORDER BY total_revenue DESC;
 
-- 3.2 Revenue by Customer Segment
SELECT
    Customer_Segment,
    COUNT(DISTINCT Customer_Id)                                           AS unique_customers,
    COUNT(DISTINCT Order_Id)                                              AS total_orders,
    ROUND(SUM(Sales), 2)                                                  AS total_revenue,
    ROUND(SUM(Order_Profit_Per_Order), 2)                                 AS total_profit,
    ROUND(SUM(Order_Profit_Per_Order) / NULLIF(SUM(Sales), 0) * 100, 2)  AS profit_margin_pct
FROM orders
GROUP BY Customer_Segment
ORDER BY total_revenue DESC;
 
-- 3.3 Top 10 Most Profitable Product Categories
SELECT
    Category_Name,
    COUNT(*)                                                              AS order_items,
    ROUND(SUM(Sales), 2)                                                  AS total_revenue,
    ROUND(SUM(Order_Profit_Per_Order), 2)                                 AS total_profit,
    ROUND(AVG(Order_Item_Profit_Ratio) * 100, 2)                         AS avg_profit_ratio_pct
FROM orders
GROUP BY Category_Name
ORDER BY total_profit DESC
LIMIT 10;
 
-- 3.4 Loss-Making Product Categories (negative profit)
SELECT
    Category_Name,
    COUNT(*)                             AS order_items,
    ROUND(SUM(Order_Profit_Per_Order), 2) AS total_profit
FROM orders
GROUP BY Category_Name
HAVING total_profit < 0
ORDER BY total_profit ASC;
 
-- 3.5 Top 10 Products by Revenue
SELECT
    Product_Name,
    COUNT(*)                             AS times_ordered,
    ROUND(SUM(Sales), 2)                 AS total_revenue,
    ROUND(SUM(Order_Profit_Per_Order), 2) AS total_profit,
    ROUND(AVG(Product_Price), 2)         AS avg_product_price
FROM orders
GROUP BY Product_Name
ORDER BY total_revenue DESC
LIMIT 10;
 
-- 3.6 Department-level P&L summary
SELECT
    Department_Name,
    ROUND(SUM(Sales), 2)                                                  AS total_revenue,
    ROUND(SUM(Order_Profit_Per_Order), 2)                                 AS total_profit,
    ROUND(SUM(Order_Profit_Per_Order) / NULLIF(SUM(Sales), 0) * 100, 2)  AS profit_margin_pct,
    COUNT(DISTINCT Order_Id)                                              AS order_count
FROM orders
GROUP BY Department_Name
ORDER BY total_profit DESC;
 
 
-- ============================================================
-- SECTION 4: DELIVERY & OPERATIONS ANALYSIS
-- ============================================================
 
-- 4.1 Late Delivery Rate by Market and Shipping Mode
SELECT
    Market,
    Shipping_Mode,
    COUNT(*)                                                            AS total_orders,
    SUM(Late_delivery_risk)                                             AS late_orders,
    ROUND(SUM(Late_delivery_risk) * 100.0 / COUNT(*), 2)               AS late_rate_pct
FROM orders
GROUP BY Market, Shipping_Mode
ORDER BY late_rate_pct DESC;
 
-- 4.2 Average Delay Days by Order Region
SELECT
    Order_Region,
    COUNT(*)                                                            AS total_orders,
    ROUND(AVG(Days_for_shipping_real), 2)                              AS avg_actual_days,
    ROUND(AVG(Days_for_shipment_scheduled), 2)                         AS avg_scheduled_days,
    ROUND(AVG(Days_for_shipping_real - Days_for_shipment_scheduled), 2) AS avg_delay_days
FROM orders
GROUP BY Order_Region
ORDER BY avg_delay_days DESC;
 
-- 4.3 Orders by Delivery Status and Order Status
SELECT
    Order_Status,
    Delivery_Status,
    COUNT(*) AS order_count
FROM orders
GROUP BY Order_Status, Delivery_Status
ORDER BY order_count DESC;
 
-- 4.4 Discount impact on profit
SELECT
    CASE
        WHEN Order_Item_Discount_Rate = 0              THEN 'No discount'
        WHEN Order_Item_Discount_Rate BETWEEN 0 AND 0.1 THEN '0-10%'
        WHEN Order_Item_Discount_Rate BETWEEN 0.1 AND 0.2 THEN '10-20%'
        WHEN Order_Item_Discount_Rate > 0.2            THEN '>20%'
    END AS discount_bucket,
    COUNT(*)                              AS order_count,
    ROUND(AVG(Order_Profit_Per_Order), 2) AS avg_profit,
    ROUND(AVG(Sales), 2)                  AS avg_revenue
FROM orders
GROUP BY discount_bucket
ORDER BY avg_profit DESC;

-- ============================================================
-- SECTION 5: VIEWS (for Power BI connection)
-- ============================================================
 
-- 5.1 View: Sales summary for Power BI dashboard
CREATE OR REPLACE VIEW vw_sales_summary AS
SELECT
    DATE_FORMAT(order_date_DateOrders, '%Y-%m') AS order_month,
    YEAR(order_date_DateOrders)                 AS order_year,
    QUARTER(order_date_DateOrders)              AS order_quarter,
    Market,
    Order_Region,
    Customer_Segment,
    Category_Name,
    Department_Name,
    Shipping_Mode,
    Delivery_Status,
    Late_delivery_risk,
    COUNT(DISTINCT Order_Id)                    AS total_orders,
    ROUND(SUM(Sales), 2)                        AS total_revenue,
    ROUND(SUM(Order_Profit_Per_Order), 2)       AS total_profit,
    ROUND(SUM(Order_Profit_Per_Order)
          / NULLIF(SUM(Sales), 0) * 100, 2)    AS profit_margin_pct,
    SUM(Order_Item_Quantity)                    AS total_units_sold
FROM orders
WHERE order_date_DateOrders IS NOT NULL
GROUP BY
    order_month, order_year, order_quarter,
    Market, Order_Region, Customer_Segment,
    Category_Name, Department_Name,
    Shipping_Mode, Delivery_Status, Late_delivery_risk;
 
-- 5.2 View: Delivery performance for Power BI ops tab
CREATE OR REPLACE VIEW vw_delivery_performance AS
SELECT
    Shipping_Mode,
    Market,
    Order_Region,
    Delivery_Status,
    COUNT(*)                                                             AS total_shipments,
    ROUND(AVG(Days_for_shipping_real), 2)                               AS avg_actual_days,
    ROUND(AVG(Days_for_shipment_scheduled), 2)                          AS avg_scheduled_days,
    ROUND(AVG(Days_for_shipping_real - Days_for_shipment_scheduled), 2) AS avg_delay_days,
    ROUND(SUM(Late_delivery_risk) * 100.0 / COUNT(*), 2)               AS late_delivery_rate_pct
FROM orders
GROUP BY Shipping_Mode, Market, Order_Region, Delivery_Status;
SHOW COLUMNS FROM orders;

SELECT COUNT(*) AS total_columns
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'orders'
AND TABLE_SCHEMA = 'supply_chain_db';

