-- Capstone drills — tutorial 11
-- Revenue of a line = quantity * unit_price * (1 - discount)

-- @ex 11.1 ordered
-- Per signup year: number of customers, and how many of them placed their
-- first order within 365 days of signing up.
-- Columns: yr, n_customers, ordered_in_12m. Ordered by yr.


-- @ex 11.2 ordered
-- For each month number '01'..'12': revenue in 2023, revenue in 2024, and the
-- growth percentage ((2024-2023)/2023*100).
-- Columns: mm, rev_2023, rev_2024 (2dp), growth_pct (1dp). Ordered by mm.


-- @ex 11.3 ordered
-- Customers whose most recent order is more than 180 days older than the newest
-- order in the whole database.
-- Columns: name, last_order, days_silent. Longest silence first.


-- @ex 11.4 ordered
-- The product with the most units sold in each category (no ties in this data).
-- Columns: category, product, units. Ordered by category.


-- @ex 11.5 ordered
-- Employees who shipped at least 5 orders (ship_date is not null):
-- name and average days from order_date to ship_date, rounded to 2.
-- Fastest first.


-- @ex 11.6 ordered
-- Orders whose payments total less than the order revenue by more than 0.01,
-- including orders with no payments at all.
-- Columns: order_id, revenue, paid, shortfall (all 2dp).
-- Biggest shortfall first, top 10.


-- @ex 11.7
-- One row: how many customers placed at least one order, how many placed more
-- than one, and the repeat rate as a percentage rounded to 1.
-- Columns: buyers, repeat_buyers, repeat_pct.


-- @ex 11.8 ordered
-- The five product pairs most often bought in the same order.
-- Columns: product_a, product_b (names), times_together.
-- Most frequent first; break ties by the two product ids ascending.


-- @ex 11.9 ordered
-- For each customer, the first order at which their cumulative revenue
-- (orders in date order) passed 1000.
-- Columns: name, order_id, order_date, cumulative (2dp). Ordered by order_date.


-- @ex 11.10 ordered
-- For each employee, the revenue of orders handled by them or by anyone below
-- them in the org chart (0 if none).
-- Columns: name, revenue (2dp). Highest first, then name.


-- @ex 11.11
-- The median order revenue, rounded to 2. One row, one column.


-- @ex 11.12 ordered
-- Per customer with at least 2 orders: name, first_order, last_order,
-- lifetime_days, n_orders, and the average days between consecutive orders
-- rounded to 1. Longest lifetime first.
