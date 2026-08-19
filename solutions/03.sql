-- @ex 3.1 ordered
SELECT o.order_id, o.order_date, c.name
FROM   orders o
JOIN   customers c ON c.customer_id = o.customer_id
WHERE  o.order_date >= '2024-01-01' AND o.order_date < '2024-02-01'
ORDER  BY o.order_id;

-- @ex 3.2 ordered
SELECT p.name, cat.name AS category, s.name AS supplier
FROM   products p
JOIN   categories cat ON cat.category_id = p.category_id
LEFT   JOIN suppliers s ON s.supplier_id = p.supplier_id
WHERE  cat.name = 'Electronics'
ORDER  BY p.name;

-- @ex 3.3 ordered
SELECT c.customer_id, c.name
FROM   customers c
WHERE  NOT EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id)
ORDER  BY c.customer_id;

-- @ex 3.4 ordered
SELECT p.product_id, p.name
FROM   products p
LEFT   JOIN order_items i ON i.product_id = p.product_id
WHERE  i.product_id IS NULL
ORDER  BY p.product_id;

-- @ex 3.5 ordered
SELECT e.name AS employee, m.name AS manager
FROM   employees e
LEFT   JOIN employees m ON m.employee_id = e.manager_id
ORDER  BY e.name;

-- @ex 3.6 ordered
SELECT   cat.name AS category,
         round(sum(i.quantity * i.unit_price * (1 - i.discount)), 2) AS revenue
FROM     order_items i
JOIN     products p   ON p.product_id  = i.product_id
JOIN     categories cat ON cat.category_id = p.category_id
GROUP BY cat.name
ORDER BY revenue DESC;

-- @ex 3.7 ordered
SELECT o.order_id, o.status
FROM   orders o
LEFT   JOIN payments p ON p.order_id = o.order_id
WHERE  o.status IN ('shipped', 'delivered')
  AND  p.payment_id IS NULL
ORDER  BY o.order_id;

-- @ex 3.8 ordered
SELECT   c.name,
         round(sum(i.quantity * i.unit_price * (1 - i.discount)), 2) AS revenue
FROM     customers c
JOIN     orders o      ON o.customer_id = c.customer_id
JOIN     order_items i ON i.order_id    = o.order_id
GROUP BY c.customer_id, c.name
ORDER BY revenue DESC
LIMIT    5;

-- @ex 3.9 ordered
SELECT   c.name,
         count(DISTINCT o.order_id) AS n_orders,
         count(*)                   AS n_lines,
         sum(i.quantity)            AS units
FROM     customers c
JOIN     orders o      ON o.customer_id = c.customer_id
JOIN     order_items i ON i.order_id    = o.order_id
GROUP BY c.customer_id, c.name
ORDER BY c.name;

-- @ex 3.10 ordered
SELECT   e.name, count(o.order_id) AS n_orders
FROM     employees e
LEFT     JOIN orders o ON o.employee_id = e.employee_id
WHERE    e.department = 'Sales'
GROUP BY e.employee_id, e.name
ORDER BY n_orders DESC, e.name;
