-- Exercises for tutorial 02 — aggregation
-- Revenue of a line = quantity * unit_price * (1 - discount)

-- @ex 2.1 ordered
-- Number of customers per segment, biggest group first,
-- ties broken by segment name ascending.

-- @ex 2.2 ordered
-- Per category_id: number of products and average unit_price rounded to
-- 2 decimals. Ordered by category_id.

-- @ex 2.3
-- A single row with three columns: total number of customer rows,
-- how many have a country recorded, and how many distinct countries there are.


-- @ex 2.4 ordered
-- Order statuses that occur at least 10 times: status and the count,
-- most frequent first.


-- @ex 2.5 ordered
-- The five orders with the highest revenue: order_id and revenue rounded to 2.


-- @ex 2.6 ordered
-- Products appearing in at least 15 distinct orders: product_id,
-- total units sold, number of distinct orders.
-- Most units first, then product_id ascending.


-- @ex 2.7 ordered
-- Per calendar year of order_date: number of orders, number of cancelled
-- orders, and the cancelled percentage rounded to 1 decimal. By year.


-- @ex 2.8 ordered
-- Per department: headcount, min salary, max salary, average salary
-- rounded to 2. Ordered by department.


-- @ex 2.9 ordered
-- Number of customers per signup year, ordered by year.


-- @ex 2.10 ordered
-- Customers with at least 6 non-cancelled orders: customer_id and that count.
-- Highest count first, then customer_id ascending.
