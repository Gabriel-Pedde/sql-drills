-- Exercises for tutorial 04 — subqueries

-- @ex 4.1 ordered
-- Products priced above the average product price: name and unit_price,
-- most expensive first.


-- @ex 4.2 ordered
-- Names of customers who have ever bought product 15, alphabetically.


-- @ex 4.3 ordered
-- customer_id and name of customers who have NEVER bought anything from the
-- 'Electronics' category (customers with no orders at all count too).
-- Ordered by customer_id.


-- @ex 4.4 ordered
-- Every customer's name plus their order count, computed with a correlated
-- subquery in the SELECT list. Most orders first, then name ascending.


-- @ex 4.5
-- The average revenue of an order, rounded to 2 decimals. One row, one column.
-- (Compute revenue per order first, then average those.)


-- @ex 4.6 ordered
-- Orders whose revenue is above the average order revenue:
-- order_id and revenue rounded to 2, highest first.


-- @ex 4.7 ordered
-- The most expensive product in each category:
-- category_id, name, unit_price. Ordered by category_id.


-- @ex 4.8 ordered
-- Name and title of employees who manage at least one person, by name.


-- @ex 4.9 ordered
-- The ten customers with the highest revenue: name, number of distinct orders,
-- revenue rounded to 2. Join an already-aggregated derived table.
-- Highest revenue first.


-- @ex 4.10 ordered
-- Products priced above the average unit_price of their own category:
-- name, category_id, unit_price. Ordered by category_id, then name.
