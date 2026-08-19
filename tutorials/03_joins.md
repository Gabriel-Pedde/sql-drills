# 03 — Joins

## 1. Mental model

A join is a **filtered cartesian product**. `FROM a JOIN b ON <cond>` conceptually
pairs every row of `a` with every row of `b` and keeps the pairs where `<cond>` is
TRUE. Engines never actually do that (they use hash/merge/index strategies), but
the semantics are exactly that, and reasoning from it always gives the right answer.

```sql
SELECT o.order_id, o.order_date, c.name
FROM   orders   AS o
JOIN   customers AS c ON c.customer_id = o.customer_id
WHERE  o.order_date >= '2024-01-01' AND o.order_date < '2024-02-01'
ORDER  BY o.order_id;
```

Alias every table and qualify every column. It costs nothing and it saves you the
day two tables both grow a `name` column.

## 2. The join types

| Type | Keeps |
|---|---|
| `[INNER] JOIN` | only rows that matched on both sides |
| `LEFT [OUTER] JOIN` | all left rows; right columns become NULL when unmatched |
| `RIGHT JOIN` | mirror image (SQLite supports it since 3.39; before that, flip the query) |
| `FULL [OUTER] JOIN` | all rows from both sides |
| `CROSS JOIN` | every combination, no condition |

`LEFT JOIN` is how you say "…and show me the ones with nothing on the other side":

```sql
SELECT p.name, s.name AS supplier
FROM   products p
LEFT   JOIN suppliers s ON s.supplier_id = p.supplier_id;   -- in-house products kept, supplier NULL
```

## 3. The #1 outer-join mistake: ON vs WHERE

In an outer join, a condition in `ON` is part of the *matching*; the same
condition in `WHERE` is applied *after* the join and throws away the padded rows —
silently converting your LEFT JOIN back into an INNER JOIN.

```sql
-- Every customer, plus their 2024 orders (customers with none still appear):
SELECT c.name, o.order_id
FROM   customers c
LEFT   JOIN orders o
       ON o.customer_id = c.customer_id
      AND o.order_date >= '2024-01-01';      -- <- in ON: part of the match

-- Same query with the date in WHERE: customers without a 2024 order VANISH,
-- because for them o.order_date is NULL and NULL >= '2024-01-01' is UNKNOWN.
```

Rule of thumb: conditions on the **outer (nullable) side** belong in `ON`;
conditions on the preserved side belong in `WHERE`.

## 4. Anti-joins: rows with no match

Two equivalent spellings — learn both, you'll read both:

```sql
-- LEFT JOIN + IS NULL
SELECT c.customer_id, c.name
FROM   customers c
LEFT   JOIN orders o ON o.customer_id = c.customer_id
WHERE  o.order_id IS NULL;

-- NOT EXISTS (usually clearer, and never risks fan-out)
SELECT c.customer_id, c.name
FROM   customers c
WHERE  NOT EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id);
```

Do **not** use `NOT IN (SELECT ...)` here — if the subquery ever yields a NULL,
`NOT IN` returns no rows at all. Tutorial 04 dissects that.

## 5. Self-joins

A table joined to itself, with two aliases. The hierarchy case:

```sql
SELECT e.name AS employee, m.name AS manager
FROM   employees e
LEFT   JOIN employees m ON m.employee_id = e.manager_id   -- LEFT keeps the CEO
ORDER  BY e.name;
```

## 6. Fan-out: the bug that silently doubles your numbers

Joining a one-to-many relationship **multiplies rows**. Aggregate afterwards and
you count the "one" side once per matching "many" row:

```sql
-- WRONG: an order with 4 line items is counted 4 times
SELECT c.name, count(o.order_id) AS n_orders, sum(i.quantity) AS units
FROM   customers c
JOIN   orders o      ON o.customer_id = c.customer_id
JOIN   order_items i ON i.order_id    = o.order_id
GROUP  BY c.name;

-- RIGHT: count the distinct thing you actually mean
SELECT c.name, count(DISTINCT o.order_id) AS n_orders, sum(i.quantity) AS units
FROM   customers c
JOIN   orders o      ON o.customer_id = c.customer_id
JOIN   order_items i ON i.order_id    = o.order_id
GROUP  BY c.name;
```

Run both against `shop.db` and compare the `n_orders` columns — the first one is
inflated for every customer whose orders had more than one line.

Whenever a query joins then aggregates, ask: *what is one row here?* If the grain
of the join is "one row per line item", then `count(o.order_id)` counts line
items, not orders. `count(DISTINCT ...)` fixes it; aggregating in a subquery
before joining (tutorial 04/05) fixes it more efficiently.

## 7. USING, and why to avoid NATURAL JOIN

When the columns share a name, `USING` is shorter and de-duplicates the column:

```sql
SELECT order_id, product_id, quantity FROM order_items JOIN products USING (product_id);
```

`NATURAL JOIN` joins on *all* same-named columns automatically — including the
`name` column two tables happen to share, or a `created_at` added next quarter.
It turns a schema change into a wrong answer. Never use it in code you keep.

---

## Exercises — `exercises/03.sql`, then `python3 check.py 3`

3.1 `order_id`, `order_date` and customer name for every order placed in January 2024, by `order_id`.
3.2 For every product in the **Electronics** category: product name, category name, supplier name (in-house products must still appear, with NULL supplier), by product name.
3.3 Customers who have never placed an order: `customer_id`, `name`, by id.
3.4 Products that have never been sold: `product_id`, `name`, by id.
3.5 Every employee with their manager's name (the CEO included, with NULL manager), by employee name.
3.6 Revenue per category: category name and revenue rounded to 2, highest first.
3.7 Shipped or delivered orders with no payment recorded: `order_id`, `status`, by `order_id`.
3.8 The five customers with the highest revenue: name and revenue rounded to 2.
3.9 Per customer who has ordered: name, number of distinct orders, number of line items, total units — by name.
3.10 Every employee in the Sales department with the number of orders they handled (0 for those who handled none), most orders first, name as tie-break.
