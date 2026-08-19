# 04 — Subqueries: scalar, IN, EXISTS, derived tables

A subquery is just a query used as a value, a set, or a table. Which of those
three it is determines everything about how it behaves.

## 1. Scalar subqueries — a subquery used as one value

Must return **at most one row and one column**; more rows is a runtime error
(SQLite is sloppy and takes the first — other engines raise).

```sql
SELECT name, unit_price
FROM   products
WHERE  unit_price > (SELECT avg(unit_price) FROM products);
```

Scalar subqueries can also sit in `SELECT`, where they are evaluated per output
row (a **correlated** subquery when they reference the outer row):

```sql
SELECT c.name,
       (SELECT count(*) FROM orders o WHERE o.customer_id = c.customer_id) AS n_orders
FROM   customers c;
```
Note this returns `0`, not NULL, for customers without orders — `count` over an
empty set is 0. That is a genuinely useful difference from `sum`, which gives NULL.

## 2. IN — a subquery used as a set

```sql
SELECT name FROM customers
WHERE  customer_id IN (SELECT customer_id FROM orders WHERE status = 'cancelled');
```

### The `NOT IN` NULL trap — know this cold

`x NOT IN (a, b, c)` means `x <> a AND x <> b AND x <> c`. If any of those values
is NULL, that conjunct is UNKNOWN, so the whole thing can never be TRUE — and the
query returns **zero rows**, with no error and no warning.

```sql
-- orders.employee_id contains NULLs (web orders), so this returns NOTHING:
SELECT name FROM employees
WHERE  employee_id NOT IN (SELECT employee_id FROM orders);

-- fixes, in order of preference:
WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.employee_id = employees.employee_id)
-- or
WHERE employee_id NOT IN (SELECT employee_id FROM orders WHERE employee_id IS NOT NULL)
```

Plain `IN` is unaffected in the same way (a NULL in the list just never matches).
It is specifically **NOT IN** that explodes. Habit to build: *anti-joins use
`NOT EXISTS`*.

## 3. EXISTS — a subquery used as a yes/no test

`EXISTS` asks "does the inner query produce at least one row?". It is correlated
by definition (it references the outer row) and it stops at the first hit.

```sql
SELECT c.name
FROM   customers c
WHERE  EXISTS (SELECT 1
               FROM   orders o
               JOIN   order_items i ON i.order_id = o.order_id
               WHERE  o.customer_id = c.customer_id
                 AND  i.product_id  = 15);
```

`SELECT 1` is idiomatic: the projection is irrelevant, only row existence matters.

Why `EXISTS` over a join here? A join to a one-to-many table can return the
customer several times, forcing a `DISTINCT`. `EXISTS` filters without changing
the row count — it can't fan out.

## 4. Derived tables — a subquery used as a table

Put a query in `FROM`, alias it, and treat it as a table. This is the standard
cure for the fan-out problem from tutorial 03: **aggregate first, then join**.

```sql
SELECT c.name, t.n_orders, t.revenue
FROM   customers c
JOIN  (SELECT o.customer_id,
              count(DISTINCT o.order_id) AS n_orders,
              round(sum(i.quantity * i.unit_price * (1 - i.discount)), 2) AS revenue
       FROM   orders o
       JOIN   order_items i ON i.order_id = o.order_id
       GROUP  BY o.customer_id) AS t
       ON t.customer_id = c.customer_id
ORDER  BY t.revenue DESC;
```

Each row of the derived table is already one-per-customer, so no multiplication
is possible. When the nesting gets deep, rewrite it as a CTE (tutorial 05) —
same semantics, far more readable.

## 5. Correlated vs uncorrelated

* **Uncorrelated** — independent of the outer query, conceptually evaluated once
  (`(SELECT avg(unit_price) FROM products)`).
* **Correlated** — references an outer column, conceptually evaluated per outer
  row (`WHERE o.customer_id = c.customer_id`).

"Conceptually": the optimiser routinely rewrites correlated subqueries into joins
or semi-joins. Write the clearest version first, measure later (tutorial 09).

The classic correlated pattern is **greatest-n-per-group**:

```sql
SELECT p.category_id, p.name, p.unit_price
FROM   products p
WHERE  p.unit_price = (SELECT max(p2.unit_price)
                       FROM   products p2
                       WHERE  p2.category_id = p.category_id);
```
Note it returns *all* rows tied for the max — sometimes what you want, sometimes
not. Tutorial 06 shows the window-function version where you control ties exactly.

## 6. ANY / ALL

Rarely needed, but read them like English:

```sql
WHERE unit_price > ALL (SELECT unit_price FROM products WHERE category_id = 2)  -- dearer than every snack
WHERE unit_price > ANY (SELECT unit_price FROM products WHERE category_id = 2)  -- dearer than at least one
```
`= ANY` is exactly `IN`. (SQLite doesn't implement ANY/ALL — use `> (SELECT max(...))`
and `> (SELECT min(...))`, which is clearer anyway. The exercises avoid them.)

---

## Exercises — `exercises/04.sql`, then `python3 check.py 4`

4.1 Products priced above the average product price: name and price, dearest first.
4.2 Names of customers who have ever bought product 15, alphabetically.
4.3 Customers who have **never** bought anything from the Electronics category: `customer_id`, `name`, by id. (Customers with no orders at all count.)
4.4 Every customer's name with their order count computed by a correlated subquery, most orders first, then name.
4.5 The average revenue of an order, rounded to 2 — one number. (Revenue per order first, then average it.)
4.6 Orders whose revenue exceeds the average order revenue: `order_id` and revenue rounded to 2, highest first.
4.7 The most expensive product in each category: `category_id`, name, `unit_price`, by `category_id`.
4.8 Employees who manage at least one person: name and title, by name.
4.9 The ten customers with the highest revenue, via aggregate-then-join: name, order count, revenue rounded to 2 — highest revenue first.
4.10 Products priced above the average price **of their own category**: name, `category_id`, `unit_price` — by `category_id`, then name.
