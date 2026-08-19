-- @ex 6.1 ordered
SELECT   category_id, name, unit_price,
         rank() OVER (PARTITION BY category_id ORDER BY unit_price DESC) AS price_rank
FROM     products
ORDER BY category_id, price_rank, name;

-- @ex 6.2 ordered
WITH prod_revenue AS (
    SELECT   p.category_id, p.name,
             sum(i.quantity * i.unit_price * (1 - i.discount)) AS revenue
    FROM     order_items i
    JOIN     products p ON p.product_id = i.product_id
    GROUP BY p.category_id, p.product_id, p.name
),
ranked AS (
    SELECT *, row_number() OVER (PARTITION BY category_id ORDER BY revenue DESC, name) AS rn
    FROM   prod_revenue
)
SELECT   category_id, name, round(revenue, 2) AS revenue
FROM     ranked
WHERE    rn <= 2
ORDER BY category_id, revenue DESC;

-- @ex 6.3 ordered
WITH monthly AS (
    SELECT   strftime('%Y-%m', o.order_date) AS month,
             sum(i.quantity * i.unit_price * (1 - i.discount)) AS revenue
    FROM     orders o
    JOIN     order_items i ON i.order_id = o.order_id
    WHERE    o.order_date >= '2024-01-01' AND o.order_date < '2025-01-01'
    GROUP BY month
)
SELECT   month,
         round(revenue, 2) AS revenue,
         round(sum(revenue) OVER (ORDER BY month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 2)
             AS running_total
FROM     monthly
ORDER BY month;

-- @ex 6.4 ordered
WITH monthly AS (
    SELECT   strftime('%Y-%m', o.order_date) AS month,
             sum(i.quantity * i.unit_price * (1 - i.discount)) AS revenue
    FROM     orders o
    JOIN     order_items i ON i.order_id = o.order_id
    WHERE    o.order_date >= '2024-01-01' AND o.order_date < '2025-01-01'
    GROUP BY month
)
SELECT   month,
         round(revenue, 2)                                   AS revenue,
         round(lag(revenue) OVER (ORDER BY month), 2)         AS prev_revenue,
         round(revenue - lag(revenue) OVER (ORDER BY month), 2) AS change
FROM     monthly
ORDER BY month;

-- @ex 6.5 ordered
SELECT   customer_id, order_id, order_date,
         row_number() OVER (PARTITION BY customer_id ORDER BY order_date, order_id) AS seq
FROM     orders
ORDER BY customer_id, seq;

-- @ex 6.6 ordered
SELECT   customer_id, order_date,
         julianday(order_date)
           - julianday(lag(order_date) OVER (PARTITION BY customer_id
                                             ORDER BY order_date, order_id)) AS days_since_prev
FROM     orders
ORDER BY customer_id, order_date;

-- @ex 6.7 ordered
WITH order_revenue AS (
    SELECT   o.order_id, o.customer_id,
             sum(i.quantity * i.unit_price * (1 - i.discount)) AS revenue
    FROM     orders o
    JOIN     order_items i ON i.order_id = o.order_id
    GROUP BY o.order_id, o.customer_id
)
SELECT   order_id,
         round(revenue, 2) AS revenue,
         round(100.0 * revenue / sum(revenue) OVER (PARTITION BY customer_id), 1) AS pct_of_customer
FROM     order_revenue
ORDER BY order_id;

-- @ex 6.8 ordered
SELECT   name, unit_price, ntile(4) OVER (ORDER BY unit_price) AS quartile
FROM     products
ORDER BY unit_price, name;

-- @ex 6.9 ordered
WITH monthly AS (
    SELECT   strftime('%Y-%m', o.order_date) AS month,
             sum(i.quantity * i.unit_price * (1 - i.discount)) AS revenue
    FROM     orders o
    JOIN     order_items i ON i.order_id = o.order_id
    WHERE    o.order_date >= '2024-01-01' AND o.order_date < '2025-01-01'
    GROUP BY month
)
SELECT   month,
         round(revenue, 2) AS revenue,
         round(avg(revenue) OVER (ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2)
             AS moving_avg_3
FROM     monthly
ORDER BY month;

-- @ex 6.10 ordered
WITH order_revenue AS (
    SELECT   o.order_id, o.customer_id,
             sum(i.quantity * i.unit_price * (1 - i.discount)) AS revenue
    FROM     orders o
    JOIN     order_items i ON i.order_id = o.order_id
    GROUP BY o.order_id, o.customer_id
),
ranked AS (
    SELECT *, row_number() OVER (PARTITION BY customer_id ORDER BY revenue DESC, order_id) AS rn
    FROM   order_revenue
)
SELECT   c.name, r.order_id, round(r.revenue, 2) AS revenue
FROM     ranked r
JOIN     customers c ON c.customer_id = r.customer_id
WHERE    r.rn = 1
ORDER BY r.revenue DESC;
