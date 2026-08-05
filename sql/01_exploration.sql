-- exploring the orders table
SELECT * 
FROM ecom.orders
LIMIT 10;

-- columns and thier respective data types in orders table
SELECT 
    column_name, 
    data_type
FROM information_schema.columns
WHERE table_name = 'orders'
AND table_schema = 'ecom';

SELECT 
    COUNT(*) AS total_orders
FROM ecom.orders;

-- total no. of unique customers
SELECT 
    COUNT(DISTINCT customer_id) AS total_customers
FROM ecom.orders;

-- earliest and the most recent order_date
SELECT 
    MIN(created_at) AS first_order_date, 
    MAX(created_at) AS most_recent_order_date
FROM ecom.orders;

-- exploring the status in orders
SELECT 
    DISTINCT status
FROM ecom.orders;

-- exploring the payment status in orders
SELECT 
    DISTINCT payment_status
FROM ecom.orders;

-- total no. of orders per status
SELECT 
    LOWER(status) order_status, 
    COUNT(*) AS total_orders
FROM ecom.orders
GROUP BY status;

-- finding the avg. no. of orders per customer
SELECT
    COUNT(*) AS total_orders,
    COUNT(DISTINCT customer_id) AS total_customers,
    ROUND((COUNT(*) * 1.0 / COUNT(DISTINCT customer_id)), 2) AS orders_per_customer
FROM ecom.orders;

-- finding the total orders per status along with their payment status
SELECT
    LOWER(status) AS order_status,
    payment_status,
    COUNT(*) AS total_orders
FROM ecom.orders
GROUP BY
    LOWER(status),
    payment_status
ORDER BY 
    order_status,
    payment_status;

-- exploring the customers table to understand the customer info available
SELECT *
FROM ecom.customers
LIMIT 10;

-- exploring the order_items table to understand the products contained in each order
SELECT *
FROM ecom.order_items
LIMIT 50;

-- exploring product_variants to understand what each variant_id represents
SELECT * 
FROM ecom.product_variants
LIMIT 10;

-- Exploring products to understand what the business actually sells
SELECT *
FROM ecom.products
LIMIT 10;

-- checking the size and active status of the product catalog
SELECT
    COUNT(*) AS total_products,
    COUNT(*) FILTER (WHERE is_active = TRUE) AS active_products,
    COUNT(*) FILTER (WHERE is_active = FALSE) AS inactive_products
FROM ecom.products;

-- Exploring categories to understand the different types of products the business sells
SELECT *
FROM ecom.categories
LIMIT 10;

-- finding all the parent categories
SELECT 
    category_id,
    category_name
FROM ecom.categories
WHERE parent_id IS NULL;

-- Exploring brands table to understand the brands sold by the business
SELECT *
FROM ecom.brands
LIMIT 10;

-- total number of brands carried by the business
SELECT
    COUNT(*) AS total_brands
FROM ecom.brands;

-- checking for orders with customer_ids that do not exist in the customers table
-- zero rows indicates no unmatched customer records
SELECT 
    o.order_id,
    o.customer_id,
    c.first_name,
    c.last_name
FROM ecom.orders o
LEFT JOIN ecom.customers c 
    ON c.customer_id = o.customer_id
WHERE c.customer_id IS NULL;

-- finding the total revenue and revenue share percent per parent category for paid orders
WITH category_revenue AS
(
    SELECT 
        parent_c.category_name,
        SUM((oi.qty * oi.unit_price) - oi.line_discount) AS paid_revenue
    FROM ecom.order_items oi 
    JOIN ecom.orders o 
        ON o.order_id = oi.order_id
    JOIN ecom.product_variants pv 
        ON pv.variant_id = oi.variant_id
    JOIN ecom.products p 
        ON p.product_id = pv.product_id
    JOIN ecom.categories c 
        ON c.category_id = p.category_id
    JOIN ecom.categories parent_c 
        ON parent_c.category_id = c.parent_id
    WHERE o.payment_status = 'paid'
    GROUP BY parent_c.category_name
)
SELECT
    category_name,
    paid_revenue,
    ROUND((paid_revenue * 100.0 / SUM(paid_revenue) OVER ()), 2) AS revenue_share_percent
FROM category_revenue
ORDER BY paid_revenue DESC;

-- finding the number of active products in each parent category
SELECT
    parent_c.category_name,
    COUNT(DISTINCT p.product_id) AS active_products
FROM ecom.products p
JOIN ecom.categories c
    ON c.category_id = p.category_id
JOIN ecom.categories parent_c
    ON parent_c.category_id = c.parent_id
WHERE p.is_active = TRUE
GROUP BY parent_c.category_name
ORDER BY active_products DESC;