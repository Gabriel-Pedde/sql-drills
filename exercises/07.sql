-- Exercises for tutorial 07 — set operations and pivots

-- @ex 7.1 ordered
-- Every country appearing as a customer country or a supplier country,
-- once each, alphabetically. Ignore unknown countries.


-- @ex 7.2
-- One row, two columns: how many rows the UNION ALL of those two country
-- lists produces (n_union_all) and how many the UNION produces (n_union).
-- Ignore unknown countries.


-- @ex 7.3 ordered
-- Countries we have customers in but no suppliers in, alphabetically.


-- @ex 7.4 ordered
-- Countries where we have both a customer and a supplier, alphabetically.


-- @ex 7.5 ordered
-- Revenue per category for 2023 and 2024 as two separate columns.
-- Columns: category, rev_2023, rev_2024 (rounded to 2). By category name.


-- @ex 7.6 ordered
-- Order counts per year broken out by status.
-- Columns: yr, pending, shipped, delivered, cancelled. Ordered by yr.


-- @ex 7.7 ordered
-- Products 1, 2 and 3 in long format.
-- Columns: product_id, metric ('price' or 'stock'), value.
-- Ordered by product_id, then metric.


-- @ex 7.8 ordered
-- The three highest-revenue customers, followed by a TOTAL row for those three.
-- Columns: label, revenue (rounded to 2). Customers by revenue descending,
-- TOTAL last.


-- @ex 7.9 ordered
-- Using EXCEPT: the product_ids that have never been sold, ascending.


-- @ex 7.10 ordered
-- customer_ids that are either in the 'vip' segment or have placed at least
-- 8 orders. Each id once, ascending.
