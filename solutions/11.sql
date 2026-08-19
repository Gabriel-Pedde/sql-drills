-- @ex 11.1 ordered
WITH first_order AS (
    SELECT customer_id, min(order_date) AS first_date FROM orders GROUP BY customer_id
)
SELECT   substr(c.signup_date, 1, 4) AS yr,
         count(*) AS n_customers,
         sum(CASE WHEN f.first_date < date(c.signup_date, '+365 day') THEN 1 ELSE 0 END)
             AS ordered_in_12m
FROM     customers c
LEFT     JOIN first_order f ON f.customer_id = c.customer_id
GROUP BY yr
ORDER BY yr;

-- @ex 11.2 ordered
WITH monthly AS (
    SELECT   strftime('%m', o.order_date) AS mm,
             strftime('%Y', o.order_date) AS yy,
             sum(i.quantity * i.unit_price * (1 - i.discount)) AS revenue
    FROM     orders o
    JOIN     order_items i ON i.order_id = o.order_id
    GROUP BY mm, yy
)
SELECT   mm,
         round(sum(CASE WHEN yy = '2023' THEN revenue ELSE 0 END), 2) AS rev_2023,
         round(sum(CASE WHEN yy = '2024' THEN revenue ELSE 0 END), 2) AS rev_2024,
         round(100.0 * (sum(CASE WHEN yy = '2024' THEN revenue ELSE 0 END)
                        - sum(CASE WHEN yy = '2023' THEN revenue ELSE 0 END))
               / sum(CASE WHEN yy = '2023' THEN revenue ELSE 0 END), 1) AS growth_pct
FROM     monthly
GROUP BY mm
ORDER BY mm;

-- @ex 11.3 ordered
WITH last_per_customer AS (
    SELECT   customer_id, max(order_date) AS last_order
    FROM     orders
    GROUP BY customer_id
)
SELECT   c.name,
         l.last_order,
         CAST(julianday((SELECT max(order_date) FROM orders))
              - julianday(l.last_order) AS INTEGER) AS days_silent
FROM     last_per_customer l
JOIN     customers c ON c.customer_id = l.customer_id
WHERE    julianday((SELECT max(order_date) FROM orders)) - julianday(l.last_order) > 180
ORDER BY days_silent DESC;

-- @ex 11.4 ordered
WITH units AS (
    SELECT   p.category_id, p.product_id, p.name AS product, sum(i.quantity) AS units
    FROM     order_items i
    JOIN     products p ON p.product_id = i.product_id
    GROUP BY p.category_id, p.product_id, p.name
),
ranked AS (
    SELECT *, row_number() OVER (PARTITION BY category_id ORDER BY units DESC, product) AS rn
    FROM   units
)
SELECT   c.name AS category, r.product, r.units
FROM     ranked r
JOIN     categories c ON c.category_id = r.category_id
WHERE    r.rn = 1
ORDER BY c.name;

-- @ex 11.5 ordered
SELECT   e.name,
         round(avg(julianday(o.ship_date) - julianday(o.order_date)), 2) AS avg_days_to_ship
FROM     orders o
JOIN     employees e ON e.employee_id = o.employee_id
WHERE    o.ship_date IS NOT NULL
GROUP BY e.employee_id, e.name
HAVING   count(*) >= 5
ORDER BY avg_days_to_ship;

-- @ex 11.6 ordered
WITH order_revenue AS (
    SELECT   order_id, sum(quantity * unit_price * (1 - discount)) AS revenue
    FROM     order_items
    GROUP BY order_id
),
order_paid AS (
    SELECT   order_id, sum(amount) AS paid
    FROM     payments
    GROUP BY order_id
)
SELECT   r.order_id,
         round(r.revenue, 2)                          AS revenue,
         round(COALESCE(p.paid, 0), 2)                AS paid,
         round(r.revenue - COALESCE(p.paid, 0), 2)    AS shortfall
FROM     order_revenue r
LEFT     JOIN order_paid p ON p.order_id = r.order_id
WHERE    r.revenue - COALESCE(p.paid, 0) > 0.01
ORDER BY shortfall DESC
LIMIT    10;

-- @ex 11.7
WITH per_customer AS (
    SELECT customer_id, count(*) AS n FROM orders GROUP BY customer_id
)
SELECT count(*)                                          AS buyers,
       sum(CASE WHEN n > 1 THEN 1 ELSE 0 END)            AS repeat_buyers,
       round(100.0 * sum(CASE WHEN n > 1 THEN 1 ELSE 0 END) / count(*), 1) AS repeat_pct
FROM   per_customer;

-- @ex 11.8 ordered
SELECT   pa.name AS product_a, pb.name AS product_b, count(*) AS times_together
FROM     order_items a
JOIN     order_items b ON b.order_id = a.order_id AND b.product_id > a.product_id
JOIN     products pa ON pa.product_id = a.product_id
JOIN     products pb ON pb.product_id = b.product_id
GROUP BY a.product_id, b.product_id, pa.name, pb.name
ORDER BY times_together DESC, a.product_id, b.product_id
LIMIT    5;

-- @ex 11.9 ordered
WITH order_revenue AS (
    SELECT   o.order_id, o.customer_id, o.order_date,
             sum(i.quantity * i.unit_price * (1 - i.discount)) AS revenue
    FROM     orders o
    JOIN     order_items i ON i.order_id = o.order_id
    GROUP BY o.order_id, o.customer_id, o.order_date
),
running AS (
    SELECT *,
           sum(revenue) OVER (PARTITION BY customer_id
                              ORDER BY order_date, order_id
                              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative
    FROM   order_revenue
),
crossings AS (
    SELECT *, row_number() OVER (PARTITION BY customer_id ORDER BY order_date, order_id) AS rn
    FROM   running
    WHERE  cumulative > 1000
)
SELECT   c.name, x.order_id, x.order_date, round(x.cumulative, 2) AS cumulative
FROM     crossings x
JOIN     customers c ON c.customer_id = x.customer_id
WHERE    x.rn = 1
ORDER BY x.order_date;

-- @ex 11.10 ordered
WITH RECURSIVE chain(root, emp) AS (
    SELECT employee_id, employee_id FROM employees
    UNION ALL
    SELECT c.root, e.employee_id
    FROM   employees e JOIN chain c ON e.manager_id = c.emp
),
order_revenue AS (
    SELECT   o.employee_id,
             sum(i.quantity * i.unit_price * (1 - i.discount)) AS revenue
    FROM     orders o
    JOIN     order_items i ON i.order_id = o.order_id
    WHERE    o.employee_id IS NOT NULL
    GROUP BY o.employee_id
)
SELECT   e.name,
         round(COALESCE(sum(r.revenue), 0), 2) AS revenue
FROM     employees e
JOIN     chain c ON c.root = e.employee_id
LEFT     JOIN order_revenue r ON r.employee_id = c.emp
GROUP BY e.employee_id, e.name
ORDER BY revenue DESC, e.name;

-- @ex 11.11
WITH order_revenue AS (
    SELECT   order_id, sum(quantity * unit_price * (1 - discount)) AS revenue
    FROM     order_items
    GROUP BY order_id
),
ranked AS (
    SELECT revenue,
           row_number() OVER (ORDER BY revenue) AS rn,
           count(*)     OVER ()                 AS n
    FROM   order_revenue
)
SELECT round(avg(revenue), 2) AS median_order_revenue
FROM   ranked
WHERE  rn IN ((n + 1) / 2, (n + 2) / 2);

-- @ex 11.12 ordered
WITH per_customer AS (
    SELECT   customer_id,
             min(order_date) AS first_order,
             max(order_date) AS last_order,
             count(*)        AS n_orders
    FROM     orders
    GROUP BY customer_id
    HAVING   count(*) >= 2
)
SELECT   c.name,
         p.first_order,
         p.last_order,
         CAST(julianday(p.last_order) - julianday(p.first_order) AS INTEGER) AS lifetime_days,
         p.n_orders,
         round((julianday(p.last_order) - julianday(p.first_order)) / (p.n_orders - 1), 1)
             AS avg_days_between
FROM     per_customer p
JOIN     customers c ON c.customer_id = p.customer_id
ORDER BY lifetime_days DESC, c.name;
