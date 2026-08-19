-- Exercises for tutorial 09 — DML and transactions
-- Writes go to a private in-memory copy; shop.db is never modified.
-- Leave the `-- @verify` sections alone: they are what the grader checks.

-- @ex 9.1
-- Insert a customer: id 100, name 'New Client', email 'new@example.com',
-- country 'Spain', city 'Madrid', segment 'retail', signup_date '2025-01-15'.


-- @verify
SELECT customer_id, name, country, city, segment, signup_date
FROM   customers WHERE customer_id >= 100;


-- @ex 9.2
-- Create a table vip_customers(customer_id INTEGER PRIMARY KEY, name TEXT NOT NULL)
-- and fill it with every 'vip' customer using a single INSERT statement.


-- @verify
SELECT customer_id, name FROM vip_customers ORDER BY customer_id;


-- @ex 9.3
-- Give every employee with the title 'Sales Rep' a 10% raise.


-- @verify
SELECT employee_id, round(salary, 2) FROM employees ORDER BY employee_id;


-- @ex 9.4
-- Set units_in_stock to 0 for every discontinued product.


-- @verify
SELECT product_id, units_in_stock, discontinued FROM products ORDER BY product_id;


-- @ex 9.5
-- Add a column total_amount to orders, then populate it with each order's
-- revenue. Orders with no line items must end up with 0, not NULL.


-- @verify
SELECT order_id, round(total_amount, 2) FROM orders ORDER BY order_id;


-- @ex 9.6
-- Delete every cancelled order that has no payment recorded.
-- Their line items must disappear as well.


-- @verify
SELECT (SELECT count(*) FROM orders)      AS orders_left,
       (SELECT count(*) FROM order_items) AS items_left,
       (SELECT count(*) FROM orders WHERE status = 'cancelled') AS cancelled_left;


-- @ex 9.7
-- Create stock_counts(product_id INTEGER PRIMARY KEY, counted INTEGER NOT NULL,
-- counted_on TEXT NOT NULL). Insert (1, 100, '2025-01-01').
-- Then, with ONE upsert statement, apply the counts
-- (1, 118, '2025-01-15') and (2, 42, '2025-01-15'):
-- product 1 must end up updated, product 2 inserted.


-- @verify
SELECT product_id, counted, counted_on FROM stock_counts ORDER BY product_id;


-- @ex 9.8
-- In an explicit transaction: double every product's unit_price, then roll back.


-- @verify
SELECT product_id, unit_price FROM products ORDER BY product_id;


-- @ex 9.9
-- In an explicit transaction: insert category (8, 'Toys'), set a savepoint,
-- insert category (9, 'Oops'), roll back to the savepoint, then commit.


-- @verify
SELECT category_id, name FROM categories ORDER BY category_id;


-- @ex 9.10
-- Reduce product 1's units_in_stock by 5 in a single statement that could never
-- leave the stock negative, whatever the current value is.


-- @verify
SELECT product_id, units_in_stock FROM products WHERE product_id IN (1, 2) ORDER BY product_id;
