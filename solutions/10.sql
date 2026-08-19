-- @ex 10.1
CREATE INDEX idx_orders_customer ON orders(customer_id);
EXPLAIN QUERY PLAN SELECT order_id FROM orders WHERE customer_id = 9;

-- @ex 10.2
CREATE INDEX idx_orders_date ON orders(order_date);
EXPLAIN QUERY PLAN
SELECT order_id FROM orders
WHERE  order_date >= '2024-01-01' AND order_date < '2025-01-01';

-- @ex 10.3
CREATE INDEX idx_items_prod_qty ON order_items(product_id, quantity);
EXPLAIN QUERY PLAN SELECT order_id FROM order_items WHERE quantity > 2;
-- SCAN: the index is sorted by product_id first, so a filter on quantity alone
-- has nothing to seek to.

-- @ex 10.4
CREATE INDEX idx_products_cat_price ON products(category_id, unit_price);
EXPLAIN QUERY PLAN SELECT unit_price FROM products WHERE category_id = 4;

-- @ex 10.5
CREATE INDEX idx_products_price ON products(unit_price);
EXPLAIN QUERY PLAN SELECT product_id, unit_price FROM products ORDER BY unit_price LIMIT 5;

-- @ex 10.6
CREATE INDEX idx_products_price2 ON products(unit_price);
EXPLAIN QUERY PLAN SELECT name FROM products WHERE unit_price > 100 / 1.22;

-- @ex 10.7
CREATE INDEX idx_items_order ON order_items(order_id);
EXPLAIN QUERY PLAN
SELECT o.order_id, i.quantity
FROM   orders o JOIN order_items i ON i.order_id = o.order_id
WHERE  o.order_id = 1005;

-- @ex 10.8
CREATE INDEX idx_orders_pending ON orders(order_date) WHERE status = 'pending';
EXPLAIN QUERY PLAN
SELECT order_id FROM orders WHERE status = 'pending' AND order_date > '2024-01-01';

-- @ex 10.9
CREATE INDEX idx_customers_lower_name ON customers(lower(name));
EXPLAIN QUERY PLAN SELECT customer_id FROM customers WHERE lower(name) = 'marta silva';

-- @ex 10.10
CREATE INDEX idx_items_prod_cover ON order_items(product_id, quantity);
EXPLAIN QUERY PLAN SELECT product_id, sum(quantity) FROM order_items GROUP BY product_id;
