-- @ex 7.1 ordered
SELECT country FROM customers WHERE country IS NOT NULL
UNION
SELECT country FROM suppliers
ORDER BY country;

-- @ex 7.2
SELECT (SELECT count(*) FROM (SELECT country FROM customers WHERE country IS NOT NULL
                              UNION ALL
                              SELECT country FROM suppliers)) AS n_union_all,
       (SELECT count(*) FROM (SELECT country FROM customers WHERE country IS NOT NULL
                              UNION
                              SELECT country FROM suppliers)) AS n_union;

-- @ex 7.3 ordered
SELECT country FROM customers WHERE country IS NOT NULL
EXCEPT
SELECT country FROM suppliers
ORDER BY country;

-- @ex 7.4 ordered
SELECT country FROM customers WHERE country IS NOT NULL
INTERSECT
SELECT country FROM suppliers
ORDER BY country;

-- @ex 7.5 ordered
SELECT   cat.name AS category,
         round(sum(CASE WHEN strftime('%Y', o.order_date) = '2023'
                        THEN i.quantity * i.unit_price * (1 - i.discount) ELSE 0 END), 2) AS rev_2023,
         round(sum(CASE WHEN strftime('%Y', o.order_date) = '2024'
                        THEN i.quantity * i.unit_price * (1 - i.discount) ELSE 0 END), 2) AS rev_2024
FROM     orders o
JOIN     order_items i ON i.order_id   = o.order_id
JOIN     products p    ON p.product_id = i.product_id
JOIN     categories cat ON cat.category_id = p.category_id
GROUP BY cat.name
ORDER BY cat.name;

-- @ex 7.6 ordered
SELECT   strftime('%Y', order_date) AS yr,
         sum(CASE WHEN status = 'pending'   THEN 1 ELSE 0 END) AS pending,
         sum(CASE WHEN status = 'shipped'   THEN 1 ELSE 0 END) AS shipped,
         sum(CASE WHEN status = 'delivered' THEN 1 ELSE 0 END) AS delivered,
         sum(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) AS cancelled
FROM     orders
GROUP BY yr
ORDER BY yr;

-- @ex 7.7 ordered
SELECT product_id, 'price' AS metric, unit_price AS value
FROM   products WHERE product_id IN (1, 2, 3)
UNION ALL
SELECT product_id, 'stock', units_in_stock
FROM   products WHERE product_id IN (1, 2, 3)
ORDER BY product_id, metric;

-- @ex 7.8 ordered
WITH top3 AS (
    SELECT   c.name AS label,
             sum(i.quantity * i.unit_price * (1 - i.discount)) AS revenue
    FROM     customers c
    JOIN     orders o      ON o.customer_id = c.customer_id
    JOIN     order_items i ON i.order_id    = o.order_id
    GROUP BY c.customer_id, c.name
    ORDER BY revenue DESC
    LIMIT    3
)
SELECT label, round(revenue, 2) AS revenue
FROM  (SELECT 0 AS sort_key, label, revenue FROM top3
       UNION ALL
       SELECT 1, 'TOTAL', sum(revenue) FROM top3)
ORDER BY sort_key, revenue DESC;

-- @ex 7.9 ordered
SELECT product_id FROM products
EXCEPT
SELECT product_id FROM order_items
ORDER BY product_id;

-- @ex 7.10 ordered
SELECT customer_id FROM customers WHERE segment = 'vip'
UNION
SELECT customer_id FROM orders GROUP BY customer_id HAVING count(*) >= 8
ORDER BY customer_id;
