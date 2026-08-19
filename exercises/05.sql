-- Exercises for tutorial 05 — CTEs and recursion

-- @ex 5.1 ordered
-- Using a CTE: the five customers with the highest revenue.
-- Columns: name, revenue rounded to 2.


-- @ex 5.2 ordered
-- Per category: name, revenue rounded to 2, and percent of total revenue
-- rounded to 1. Highest revenue first.


-- @ex 5.3 ordered
-- Generate the twelve months of 2024 as text: '2024-01' ... '2024-12', in order.
-- One column.


-- @ex 5.4 ordered
-- Revenue from the 'Stationery' category per month of 2024, including the
-- months with no stationery sales (0.0 there), rounded to 2.
-- Columns: month ('YYYY-MM'), revenue. Ordered by month.


-- @ex 5.5 ordered
-- Every employee with their depth in the org chart (the CEO is level 1):
-- name, level. Ordered by level, then name.


-- @ex 5.6 ordered
-- Names of everyone below Bruno Costa (employee_id 2) at any depth,
-- excluding Bruno himself. Alphabetically.


-- @ex 5.7 ordered
-- Every employee's chain of command as a path like
-- 'Ada Nowak > Bruno Costa > Dmitri Ivanov'. Columns: name, path.
-- Ordered by path.


-- @ex 5.8 ordered
-- For each employee: name and how many people report to them directly or
-- indirectly (0 for those with nobody). Largest first, then name.


-- @ex 5.9 ordered
-- Customers whose total revenue is above the average customer revenue:
-- name and revenue rounded to 2, highest first.


-- @ex 5.10 ordered
-- Hires per year and the running total of headcount, by year.
-- Columns: year, hires, running_total.  Do it without window functions.
