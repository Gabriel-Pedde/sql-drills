-- @ex 2.1 ordered
SELECT   segment, count(*) AS n
FROM     customers
GROUP BY segment
ORDER BY n DESC, segment;

-- @ex 2.2 ordered
SELECT   category_id, count(*) AS n_products, round(avg(unit_price), 2) AS avg_price
FROM     products
GROUP BY category_id
ORDER BY category_id;

-- @ex 2.3
SELECT count(*)                 AS rows_total,
       count(country)           AS with_country,
       count(DISTINCT country)  AS distinct_countries
FROM   customers;

-- @ex 2.4 ordered
SELECT   status, count(*) AS n
FROM     orders
GROUP BY status
HAVING   count(*) >= 10
ORDER BY n DESC;

-- @ex 2.5 ordered
SELECT   order_id, round(sum(quantity * unit_price * (1 - discount)), 2) AS revenue
FROM     order_items
GROUP BY order_id
ORDER BY revenue DESC
LIMIT    5;

-- @ex 2.6 ordered
SELECT   product_id,
         sum(quantity)            AS units_sold,
         count(DISTINCT order_id) AS n_orders
FROM     order_items
GROUP BY product_id
HAVING   count(DISTINCT order_id) >= 15
ORDER BY units_sold DESC, product_id;

-- @ex 2.7 ordered
SELECT   strftime('%Y', order_date) AS yr,
         count(*)                                              AS n_orders,
         sum(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) AS n_cancelled,
         round(100.0 * sum(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END)
               / count(*), 1)                                  AS pct_cancelled
FROM     orders
GROUP BY yr
ORDER BY yr;

-- @ex 2.8 ordered
SELECT   department,
         count(*)             AS headcount,
         min(salary)          AS min_salary,
         max(salary)          AS max_salary,
         round(avg(salary),2) AS avg_salary
FROM     employees
GROUP BY department
ORDER BY department;

-- @ex 2.9 ordered
SELECT   substr(signup_date, 1, 4) AS yr, count(*) AS n
FROM     customers
GROUP BY yr
ORDER BY yr;

-- @ex 2.10 ordered
SELECT   customer_id, count(*) AS n_orders
FROM     orders
WHERE    status <> 'cancelled'
GROUP BY customer_id
HAVING   count(*) >= 6
ORDER BY n_orders DESC, customer_id;
