-- @ex 5.1 ordered
WITH cust_revenue AS (
    SELECT   o.customer_id,
             sum(i.quantity * i.unit_price * (1 - i.discount)) AS revenue
    FROM     orders o
    JOIN     order_items i ON i.order_id = o.order_id
    GROUP BY o.customer_id
)
SELECT   c.name, round(r.revenue, 2) AS revenue
FROM     cust_revenue r
JOIN     customers c ON c.customer_id = r.customer_id
ORDER BY r.revenue DESC
LIMIT    5;

-- @ex 5.2 ordered
WITH cat_revenue AS (
    SELECT   p.category_id,
             sum(i.quantity * i.unit_price * (1 - i.discount)) AS revenue
    FROM     order_items i
    JOIN     products p ON p.product_id = i.product_id
    GROUP BY p.category_id
),
total AS (SELECT sum(revenue) AS grand_total FROM cat_revenue)
SELECT   c.name,
         round(r.revenue, 2) AS revenue,
         round(100.0 * r.revenue / t.grand_total, 1) AS pct_of_total
FROM     cat_revenue r
CROSS JOIN total t
JOIN     categories c ON c.category_id = r.category_id
ORDER BY r.revenue DESC;

-- @ex 5.3 ordered
WITH RECURSIVE months(m) AS (
    SELECT '2024-01'
    UNION ALL
    SELECT strftime('%Y-%m', date(m || '-01', '+1 month')) FROM months WHERE m < '2024-12'
)
SELECT m FROM months ORDER BY m;

-- @ex 5.4 ordered
WITH RECURSIVE months(m) AS (
    SELECT '2024-01'
    UNION ALL
    SELECT strftime('%Y-%m', date(m || '-01', '+1 month')) FROM months WHERE m < '2024-12'
),
sales AS (
    SELECT   strftime('%Y-%m', o.order_date) AS m,
             sum(i.quantity * i.unit_price * (1 - i.discount)) AS revenue
    FROM     orders o
    JOIN     order_items i ON i.order_id  = o.order_id
    JOIN     products p    ON p.product_id = i.product_id
    JOIN     categories c  ON c.category_id = p.category_id
    WHERE    c.name = 'Stationery'
    GROUP BY m
)
SELECT   months.m AS month, round(COALESCE(s.revenue, 0), 2) AS revenue
FROM     months
LEFT     JOIN sales s ON s.m = months.m
ORDER BY months.m;

-- @ex 5.5 ordered
WITH RECURSIVE tree(employee_id, name, level) AS (
    SELECT employee_id, name, 1 FROM employees WHERE manager_id IS NULL
    UNION ALL
    SELECT e.employee_id, e.name, t.level + 1
    FROM   employees e JOIN tree t ON e.manager_id = t.employee_id
)
SELECT name, level FROM tree ORDER BY level, name;

-- @ex 5.6 ordered
WITH RECURSIVE sub(employee_id, name) AS (
    SELECT employee_id, name FROM employees WHERE employee_id = 2
    UNION ALL
    SELECT e.employee_id, e.name
    FROM   employees e JOIN sub s ON e.manager_id = s.employee_id
)
SELECT name FROM sub WHERE employee_id <> 2 ORDER BY name;

-- @ex 5.7 ordered
WITH RECURSIVE tree(employee_id, name, path) AS (
    SELECT employee_id, name, name FROM employees WHERE manager_id IS NULL
    UNION ALL
    SELECT e.employee_id, e.name, t.path || ' > ' || e.name
    FROM   employees e JOIN tree t ON e.manager_id = t.employee_id
)
SELECT name, path FROM tree ORDER BY path;

-- @ex 5.8 ordered
WITH RECURSIVE chain(root, emp) AS (
    SELECT employee_id, employee_id FROM employees
    UNION ALL
    SELECT c.root, e.employee_id
    FROM   employees e JOIN chain c ON e.manager_id = c.emp
)
SELECT   e.name, count(*) - 1 AS n_reports
FROM     chain c
JOIN     employees e ON e.employee_id = c.root
GROUP BY c.root, e.name
ORDER BY n_reports DESC, e.name;

-- @ex 5.9 ordered
WITH cust_revenue AS (
    SELECT   o.customer_id,
             sum(i.quantity * i.unit_price * (1 - i.discount)) AS revenue
    FROM     orders o
    JOIN     order_items i ON i.order_id = o.order_id
    GROUP BY o.customer_id
)
SELECT   c.name, round(r.revenue, 2) AS revenue
FROM     cust_revenue r
JOIN     customers c ON c.customer_id = r.customer_id
WHERE    r.revenue > (SELECT avg(revenue) FROM cust_revenue)
ORDER BY r.revenue DESC;

-- @ex 5.10 ordered
WITH per_year AS (
    SELECT   substr(hire_date, 1, 4) AS yr, count(*) AS hires
    FROM     employees
    GROUP BY yr
)
SELECT   a.yr, a.hires, sum(b.hires) AS running_total
FROM     per_year a
JOIN     per_year b ON b.yr <= a.yr
GROUP BY a.yr, a.hires
ORDER BY a.yr;
