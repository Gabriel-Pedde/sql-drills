# 05 — CTEs and recursive queries

## 1. `WITH`: naming the steps

A Common Table Expression is a named subquery defined before the query that uses
it. Semantically it is a derived table; practically it changes how you *write*
SQL, because you can decompose a problem into named steps instead of nesting.

```sql
WITH order_revenue AS (
    SELECT order_id, sum(quantity * unit_price * (1 - discount)) AS revenue
    FROM   order_items
    GROUP  BY order_id
)
SELECT round(avg(revenue), 2) AS avg_order_revenue FROM order_revenue;
```

Compare with exercise 4.6, where the same aggregate had to be written twice
inside a nested subquery. A CTE is written once and referenced as often as needed.

CTEs chain — each may reference the ones defined before it:

```sql
WITH cat_revenue AS (
    SELECT   p.category_id, sum(i.quantity * i.unit_price * (1 - i.discount)) AS revenue
    FROM     order_items i JOIN products p ON p.product_id = i.product_id
    GROUP BY p.category_id
),
total AS (
    SELECT sum(revenue) AS grand_total FROM cat_revenue
)
SELECT   c.name,
         round(r.revenue, 2) AS revenue,
         round(100.0 * r.revenue / t.grand_total, 1) AS pct_of_total
FROM     cat_revenue r
CROSS JOIN total t                       -- a single-row table: cross join is the clean way in
JOIN     categories c ON c.category_id = r.category_id
ORDER BY revenue DESC;
```

**When to prefer a CTE over a derived table:** when the step deserves a name,
when it is used twice, or when nesting has passed two levels. **When not to:**
never for correctness reasons — they're equivalent — but be aware of one
performance wrinkle. Postgres ≤11 always materialised CTEs (an optimisation
fence); Postgres 12+ inlines single-use, side-effect-free CTEs unless you write
`AS MATERIALIZED`. SQLite may or may not materialise. If a CTE-based query is
slow, try the inlined form and compare plans (tutorial 09).

A **view** is the same idea persisted in the schema:
`CREATE VIEW v AS SELECT ...` — a stored query, not stored data.

## 2. Recursive CTEs

`WITH RECURSIVE` lets a query reference itself. The shape is always the same:

```sql
WITH RECURSIVE name(cols) AS (
        <anchor query>            -- the starting rows, evaluated once
    UNION ALL                     -- or UNION, which also de-duplicates
        <recursive query>         -- references `name`; re-run until it returns 0 rows
)
SELECT ... FROM name;
```

Execution: run the anchor; feed its rows to the recursive term; feed *those*
results back in; stop when an iteration produces nothing.

### A number series

```sql
WITH RECURSIVE n(i) AS (
    SELECT 1
    UNION ALL
    SELECT i + 1 FROM n WHERE i < 10        -- the WHERE is the stop condition
)
SELECT i FROM n;
```
Forget the stop condition and you loop forever. Postgres has `LIMIT`-style
protection only if you add it; SQLite will happily spin. Always be able to point
at the line that terminates the recursion.

### A date spine

Reporting queries need "every month, including the empty ones". Generate the
calendar, then LEFT JOIN the data to it:

```sql
WITH RECURSIVE months(m) AS (
    SELECT '2024-01'
    UNION ALL
    SELECT strftime('%Y-%m', date(m || '-01', '+1 month')) FROM months WHERE m < '2024-12'
)
SELECT m, count(o.order_id) AS n_orders
FROM   months
LEFT   JOIN orders o ON strftime('%Y-%m', o.order_date) = months.m
GROUP  BY m
ORDER  BY m;
```

### Walking a hierarchy

`employees.manager_id` is a self-reference; recursion turns it into an org chart:

```sql
WITH RECURSIVE tree(employee_id, name, manager_id, level, path) AS (
    SELECT employee_id, name, manager_id, 1, name
    FROM   employees
    WHERE  manager_id IS NULL                       -- anchor: the root
    UNION ALL
    SELECT e.employee_id, e.name, e.manager_id, t.level + 1, t.path || ' > ' || e.name
    FROM   employees e
    JOIN   tree t ON e.manager_id = t.employee_id   -- one level down per iteration
)
SELECT level, path FROM tree ORDER BY path;
```

Two things to carry with you:

* **Depth** = a counter you add yourself (`t.level + 1`). Nothing gives it to you.
* **Cycles**: if the data ever contains a loop (A manages B manages A), `UNION ALL`
  recurses forever. Guard with the `path` (`WHERE instr(t.path, e.name) = 0`),
  with a depth cap, or use `UNION` when duplicates are the only risk.

Change the anchor to start anywhere: `WHERE employee_id = 2` gives you Bruno's
entire subtree. Reverse the join (`t.manager_id = e.employee_id`) to walk *up*
to the root instead.

---

## Exercises — `exercises/05.sql`, then `python3 check.py 5`

5.1 Using a CTE: the five customers with the highest revenue — name and revenue rounded to 2.
5.2 Per category: name, revenue rounded to 2, and percentage of total revenue rounded to 1 — highest revenue first.
5.3 Generate the twelve months of 2024 as text `'2024-01' … '2024-12'`, in order.
5.4 **Stationery** revenue per month of 2024, including the months with no stationery sales at all (0 there), rounded to 2, by month. (Three months are empty — a plain `GROUP BY` would simply omit them.)
5.5 Every employee with their depth in the org chart (CEO = 1): name and level, by level then name.
5.6 Everyone below Bruno Costa (`employee_id` 2) at any depth — names, alphabetically, excluding Bruno.
5.7 Every employee's full chain of command as a `>`-separated path, ordered by that path.
5.8 For each employee, how many people report to them directly or indirectly — name and count, largest first, name as tie-break.
5.9 Customers whose total revenue is above the average customer revenue: name and revenue rounded to 2, highest first.
5.10 Hires per year and the running total of headcount, by year. (No window functions — this one is a self-join, so you feel what tutorial 06 buys you.)
