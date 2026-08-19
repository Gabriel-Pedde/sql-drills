-- Exercises for tutorial 10 — indexes and query plans
--
-- Each answer: create the index with EXACTLY the given name, then finish with an
-- EXPLAIN QUERY PLAN statement. The grader compares the plan output, so the
-- index name and the shape of your query both matter.
-- Indexes are created on a private copy; shop.db is untouched.

-- @ex 10.1
-- Create idx_orders_customer on orders(customer_id), then show the query plan of
--     SELECT order_id FROM orders WHERE customer_id = 9


-- @ex 10.2
-- Create idx_orders_date on orders(order_date), then show the query plan of a
-- SARGABLE query returning order_id for orders placed during 2024.
-- (If your plan says SCAN, your predicate isn't sargable yet.)


-- @ex 10.3
-- Create idx_items_prod_qty on order_items(product_id, quantity), then show the
-- plan of
--     SELECT order_id FROM order_items WHERE quantity > 2
-- Observe what the left-most prefix rule does to it.


-- @ex 10.4
-- Create idx_products_cat_price on products(category_id, unit_price), then show
-- the plan of
--     SELECT unit_price FROM products WHERE category_id = 4
-- The plan should say COVERING INDEX.


-- @ex 10.5
-- Create idx_products_price on products(unit_price), then show the plan of
--     SELECT product_id, unit_price FROM products ORDER BY unit_price LIMIT 5
-- There should be no TEMP B-TREE in it.


-- @ex 10.6
-- Create idx_products_price2 on products(unit_price), then show the plan of a
-- sargable rewrite of
--     SELECT name FROM products WHERE unit_price * 1.22 > 100


-- @ex 10.7
-- Create idx_items_order on order_items(order_id), then show the plan of
--     SELECT o.order_id, i.quantity
--     FROM orders o JOIN order_items i ON i.order_id = o.order_id
--     WHERE o.order_id = 1005


-- @ex 10.8
-- Create the partial index idx_orders_pending on orders(order_date)
-- restricted to status = 'pending', then show the plan of
--     SELECT order_id FROM orders WHERE status = 'pending' AND order_date > '2024-01-01'


-- @ex 10.9
-- Create the expression index idx_customers_lower_name on customers(lower(name)),
-- then show the plan of
--     SELECT customer_id FROM customers WHERE lower(name) = 'marta silva'


-- @ex 10.10
-- Create idx_items_prod_cover on order_items(product_id, quantity), then show
-- the plan of
--     SELECT product_id, sum(quantity) FROM order_items GROUP BY product_id
