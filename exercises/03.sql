-- Exercises for tutorial 03 — joins

-- @ex 3.1 ordered
-- order_id, order_date and customer name for every order placed in
-- January 2024, ordered by order_id.


-- @ex 3.2 ordered
-- For every product in the 'Electronics' category: product name, category name,
-- supplier name. In-house products (no supplier) must still appear.
-- Ordered by product name.


-- @ex 3.3 ordered
-- customer_id and name of customers who have never placed an order,
-- ordered by customer_id.


-- @ex 3.4 ordered
-- product_id and name of products that have never been sold,
-- ordered by product_id.


-- @ex 3.5 ordered
-- Every employee's name and their manager's name (the CEO must appear
-- with a NULL manager). Ordered by employee name.


-- @ex 3.6 ordered
-- Revenue per category: category name and revenue rounded to 2 decimals,
-- highest revenue first.


-- @ex 3.7 ordered
-- order_id and status of orders that are 'shipped' or 'delivered' but have
-- no row in payments. Ordered by order_id.


-- @ex 3.8 ordered
-- The five customers with the highest revenue: customer name and revenue
-- rounded to 2 decimals.


-- @ex 3.9 ordered
-- For each customer that has at least one order: name, number of distinct
-- orders, number of line items, total units ordered. Ordered by name.


-- @ex 3.10 ordered
-- Every employee in the 'Sales' department and how many orders they handled
-- (0 if none). Most orders first, then name ascending.
