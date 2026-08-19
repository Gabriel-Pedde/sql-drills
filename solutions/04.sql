-- @ex 4.1 ordered
SELECT name, unit_price
FROM   products
WHERE  unit_price > (SELECT avg(unit_price) FROM products)
ORDER  BY unit_price DESC;

-- @ex 4.2 ordered
SELECT c.name
FROM   customers c
WHERE  EXISTS (SELECT 1
               FROM   orders o
               JOIN   order_items i ON i.order_id = o.order_id
               WHERE  o.customer_id = c.customer_id
                 AND  i.product_id  = 15)
ORDER  BY c.name;

-- @ex 4.3 ordered
SELECT c.customer_id, c.name
FROM   customers c
WHERE  NOT EXISTS (SELECT 1
                   FROM   orders o
                   JOIN   order_items i ON i.order_id  = o.order_id
                   JOIN   products p    ON p.product_id = i.product_id
                   JOIN   categories cat ON cat.category_id = p.category_id
                   WHERE  o.customer_id = c.customer_id
                     AND  cat.name = 'Electronics')
ORDER  BY c.customer_id;

-- @ex 4.4 ordered
SELECT c.name,
       (SELECT count(*) FROM orders o WHERE o.customer_id = c.customer_id) AS n_orders
FROM   customers c
ORDER  BY n_orders DESC, c.name;

-- @ex 4.5
SELECT round(avg(revenue), 2) AS avg_order_revenue
FROM  (SELECT order_id, sum(quantity * unit_price * (1 - discount)) AS revenue
       FROM   order_items
       GROUP  BY order_id);

-- @ex 4.6 ordered
SELECT order_id, round(revenue, 2) AS revenue
FROM  (SELECT order_id, sum(quantity * unit_price * (1 - discount)) AS revenue
       FROM   order_items
       GROUP  BY order_id)
WHERE  revenue > (SELECT avg(revenue)
                  FROM  (SELECT sum(quantity * unit_price * (1 - discount)) AS revenue
                         FROM   order_items
                         GROUP  BY order_id))
ORDER  BY revenue DESC;

-- @ex 4.7 ordered
SELECT p.category_id, p.name, p.unit_price
FROM   products p
WHERE  p.unit_price = (SELECT max(p2.unit_price)
                       FROM   products p2
                       WHERE  p2.category_id = p.category_id)
ORDER  BY p.category_id;

-- @ex 4.8 ordered
SELECT e.name, e.title
FROM   employees e
WHERE  EXISTS (SELECT 1 FROM employees s WHERE s.manager_id = e.employee_id)
ORDER  BY e.name;

-- @ex 4.9 ordered
SELECT c.name, t.n_orders, round(t.revenue, 2) AS revenue
FROM   customers c
JOIN  (SELECT o.customer_id,
              count(DISTINCT o.order_id) AS n_orders,
              sum(i.quantity * i.unit_price * (1 - i.discount)) AS revenue
       FROM   orders o
       JOIN   order_items i ON i.order_id = o.order_id
       GROUP  BY o.customer_id) AS t ON t.customer_id = c.customer_id
ORDER  BY t.revenue DESC
LIMIT  10;

-- @ex 4.10 ordered
SELECT p.name, p.category_id, p.unit_price
FROM   products p
WHERE  p.unit_price > (SELECT avg(p2.unit_price)
                       FROM   products p2
                       WHERE  p2.category_id = p.category_id)
ORDER  BY p.category_id, p.name;
