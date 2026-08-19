-- Exercises for tutorial 08 — DDL, keys, constraints
--
-- These exercises WRITE to the database. The grader runs them against a private
-- in-memory copy, so shop.db is never modified.
--
-- Each block ends with a `-- @verify` section: leave it alone, it is what the
-- grader checks. Everything you write goes ABOVE it.

-- @ex 8.1
-- Create table `reviews` with columns, in this order:
--   review_id   integer, primary key
--   product_id  integer, NOT NULL, references products(product_id)
--   customer_id integer, NOT NULL, references customers(customer_id)
--   rating      integer, NOT NULL, must be between 1 and 5
--   comment     text, nullable
--   created_at  text, NOT NULL, defaults to today's date
-- The verify block checks the column list and that ratings outside 1..5 bounce.


-- @verify
INSERT OR IGNORE INTO reviews (review_id, product_id, customer_id, rating)
VALUES (1, 1, 1, 5), (2, 1, 2, 0), (3, 2, 3, 6), (4, 2, 4, 1);
SELECT (SELECT group_concat(name) FROM pragma_table_info('reviews')) AS cols,
       (SELECT group_concat("notnull") FROM pragma_table_info('reviews')) AS notnulls,
       (SELECT count(*) FROM reviews) AS rows_accepted,
       (SELECT created_at IS NOT NULL FROM reviews LIMIT 1) AS default_applied;


-- @ex 8.2
-- Create a `reviews` table (review_id, product_id, customer_id, rating are enough)
-- plus whatever it takes to guarantee one customer cannot review the same
-- product twice.


-- @verify
INSERT OR IGNORE INTO reviews (review_id, product_id, customer_id, rating)
VALUES (1, 1, 1, 5), (2, 1, 1, 3), (3, 1, 2, 4);
SELECT count(*) AS rows_accepted FROM reviews;


-- @ex 8.3
-- Add a nullable text column `phone` to the customers table.


-- @verify
SELECT name, "notnull" FROM pragma_table_info('customers') ORDER BY cid;


-- @ex 8.4
-- Create `product_tags`, a many-to-many tag table in 1NF: one row per
-- (product_id, tag) pair, both NOT NULL, the pair unique, product_id
-- referencing products.


-- @verify
INSERT OR IGNORE INTO product_tags (product_id, tag)
VALUES (1, 'coffee'), (1, 'gift'), (1, 'coffee'), (2, 'coffee');
SELECT count(*) AS rows_accepted FROM product_tags;


-- @ex 8.5
-- Create `shipments` (shipment_id integer primary key, shipped_on text defaulting
-- to today, carrier text NOT NULL defaulting to 'DHL'), then insert one row
-- supplying only shipment_id = 1.


-- @verify
SELECT shipment_id, shipped_on = date('now') AS dated_today, carrier FROM shipments;


-- @ex 8.6
-- Create `promotions` (code text primary key, starts_on text NOT NULL,
-- ends_on text NOT NULL) where ends_on can never be earlier than starts_on.


-- @verify
INSERT OR IGNORE INTO promotions (code, starts_on, ends_on)
VALUES ('OK1', '2024-01-01', '2024-01-31'),
       ('BAD', '2024-03-01', '2024-02-01'),
       ('OK2', '2024-05-01', '2024-05-01');
SELECT count(*) AS rows_accepted FROM promotions;


-- @ex 8.7
-- Create `order_notes` (note_id integer primary key, order_id integer NOT NULL,
-- note text NOT NULL) whose rows disappear when their order is deleted.


-- @verify
INSERT INTO order_notes (note_id, order_id, note)
SELECT 1, min(o.order_id), 'call before delivery' FROM orders o
WHERE  NOT EXISTS (SELECT 1 FROM payments p WHERE p.order_id = o.order_id);
DELETE FROM orders WHERE order_id = (SELECT order_id FROM order_notes WHERE note_id = 1);
SELECT count(*) AS notes_left FROM order_notes;


-- @ex 8.8
-- Create `assignments` (assignment_id integer primary key, employee_id integer
-- referencing employees, task text NOT NULL) where employee_id becomes NULL
-- if the employee row is deleted.


-- @verify
INSERT INTO assignments (assignment_id, employee_id, task) VALUES (1, 12, 'inventory count');
DELETE FROM employees WHERE employee_id = 12;
SELECT assignment_id, employee_id, task FROM assignments;


-- @ex 8.9
-- How many order_items lines were sold at a price different from the product's
-- current unit_price? One row, one column.


-- @ex 8.10 ordered
-- Create the view `order_totals` (order_id, total) from the tutorial, then
-- select the five largest totals from it: order_id, total rounded to 2.
