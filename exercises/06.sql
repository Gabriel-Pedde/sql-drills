-- Exercises for tutorial 06 — window functions

-- @ex 6.1 ordered
-- Every product with its price rank inside its category, highest price = 1,
-- ties sharing a rank and leaving gaps.
-- Columns: category_id, name, unit_price, price_rank.
-- Ordered by category_id, price_rank, name.


-- @ex 6.2 ordered
-- The two highest-revenue products per category:
-- category_id, product name, revenue rounded to 2.
-- Ordered by category_id, then revenue descending.


-- @ex 6.3 ordered
-- Monthly revenue for 2024 with a running total.
-- Columns: month ('YYYY-MM'), revenue, running_total — both rounded to 2.
-- Ordered by month.


-- @ex 6.4 ordered
-- Monthly revenue for 2024 with the previous month's revenue and the change.
-- Columns: month, revenue, prev_revenue, change — all rounded to 2,
-- NULL for January. Ordered by month.


-- @ex 6.5 ordered
-- Number each order within its customer, in order_date order.
-- Columns: customer_id, order_id, order_date, seq.
-- Ordered by customer_id, seq.


-- @ex 6.6 ordered
-- Every order with the number of days since that customer's previous order
-- (NULL for their first). Columns: customer_id, order_date, days_since_prev.
-- Ordered by customer_id, order_date.


-- @ex 6.7 ordered
-- Every order's revenue as a percentage of its customer's total revenue.
-- Columns: order_id, revenue (2dp), pct_of_customer (1dp). Ordered by order_id.


-- @ex 6.8 ordered
-- Products split into four price quartiles (1 = cheapest quarter).
-- Columns: name, unit_price, quartile. Ordered by unit_price, then name.


-- @ex 6.9 ordered
-- Monthly revenue for 2024 with a 3-month moving average (current month and
-- the two before it). Columns: month, revenue, moving_avg_3 — rounded to 2.
-- Ordered by month.


-- @ex 6.10 ordered
-- Each customer's single largest order.
-- Columns: customer name, order_id, revenue rounded to 2.
-- Biggest revenue first.
