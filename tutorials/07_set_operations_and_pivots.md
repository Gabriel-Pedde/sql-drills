# 07 — Set operations, pivots, and reshaping

## 1. UNION, INTERSECT, EXCEPT

These combine the *result sets* of two queries vertically. The rule: both sides
must have the **same number of columns with compatible types**; column names come
from the first query.

```sql
SELECT country FROM customers WHERE country IS NOT NULL
UNION                                   -- removes duplicates (a sort/hash: costs something)
SELECT country FROM suppliers;

SELECT country FROM customers UNION ALL SELECT country FROM suppliers;  -- keeps everything
SELECT country FROM customers INTERSECT SELECT country FROM suppliers;  -- in both
SELECT country FROM customers EXCEPT    SELECT country FROM suppliers;  -- in the first only
```

* **`UNION ALL` is the default you should reach for.** `UNION` silently
  de-duplicates, which is extra work *and* can hide a real duplicate-row bug.
  Use `UNION` only when you actually want distinct rows.
* `INTERSECT` and `EXCEPT` also de-duplicate (`EXCEPT ALL` / `INTERSECT ALL`
  exist in Postgres, not in SQLite).
* NULLs are treated as *equal* here, unlike in `=`. `SELECT NULL UNION SELECT NULL`
  gives one row. Set operations use "not distinct" semantics.
* `ORDER BY` applies to the **whole** result and goes at the very end, once.

`EXCEPT` is excellent for reconciliation — "which ids are in A but not B?" — and
for regression-testing a query rewrite: if `old EXCEPT new` and `new EXCEPT old`
are both empty, the two return the same set.

## 2. Pivot: rows to columns

Standard SQL has no `PIVOT` (SQL Server and Oracle do). Everyone else writes
conditional aggregation, which is just tutorial 02's trick with more columns:

```sql
SELECT   c.name AS category,
         round(sum(CASE WHEN strftime('%Y', o.order_date) = '2023'
                        THEN i.quantity * i.unit_price * (1 - i.discount) ELSE 0 END), 2) AS rev_2023,
         round(sum(CASE WHEN strftime('%Y', o.order_date) = '2024'
                        THEN i.quantity * i.unit_price * (1 - i.discount) ELSE 0 END), 2) AS rev_2024
FROM     orders o
JOIN     order_items i ON i.order_id  = o.order_id
JOIN     products   p ON p.product_id = i.product_id
JOIN     categories c ON c.category_id = p.category_id
GROUP BY c.name
ORDER BY c.name;
```

The columns are fixed at *write* time — a pivot with a dynamic number of columns
is not expressible in one static SQL statement. That's a property of the language,
not a gap in your knowledge: the shape of a result set must be known before
execution. Generate the SQL, or pivot in the application/BI layer.

## 3. Unpivot: columns to rows

The inverse, via `UNION ALL`:

```sql
SELECT product_id, 'price' AS metric, unit_price     AS value FROM products
UNION ALL
SELECT product_id, 'stock',           units_in_stock        FROM products
ORDER BY product_id, metric;
```
Long format like this is what charting libraries and `GROUP BY` want. Note the
types must be compatible in each column position — here both are numbers.

## 4. Adding a totals row

A report often wants its own summary line. Attach an explicit sort key, since
`ORDER BY` runs over the union and knows nothing about your intent:

```sql
WITH top3 AS (
    SELECT   c.name AS label, sum(i.quantity * i.unit_price * (1 - i.discount)) AS revenue
    FROM     customers c
    JOIN     orders o      ON o.customer_id = c.customer_id
    JOIN     order_items i ON i.order_id    = o.order_id
    GROUP BY c.customer_id, c.name
    ORDER BY revenue DESC
    LIMIT    3
)
SELECT label, round(revenue, 2) AS revenue FROM (
    SELECT 0 AS sort_key, label, revenue FROM top3
    UNION ALL
    SELECT 1, 'TOTAL', sum(revenue) FROM top3
) ORDER BY sort_key, revenue DESC;
```
(Postgres/SQL Server also offer `GROUPING SETS`, `ROLLUP` and `CUBE`, which
produce subtotal rows natively. SQLite has none of them, so the union idiom is
worth knowing regardless.)

---

## Exercises — `exercises/07.sql`, then `python3 check.py 7`

7.1 Every country that appears as a customer country or a supplier country, once each, alphabetically (ignore unknown).
7.2 One row showing how many rows `UNION ALL` produces vs `UNION`, for those same two country lists: `n_union_all`, `n_union`.
7.3 Countries we have customers in but no suppliers in, alphabetically.
7.4 Countries where we have both a customer and a supplier, alphabetically.
7.5 Revenue per category for 2023 and 2024 as two columns, rounded to 2, by category name.
7.6 Order counts per year broken out by status: `yr`, `pending`, `shipped`, `delivered`, `cancelled`, by year.
7.7 Products 1, 2 and 3 in long format: `product_id`, `metric` (`'price'` / `'stock'`), `value` — by `product_id` then `metric`.
7.8 The three highest-revenue customers followed by a `TOTAL` row for those three: `label`, `revenue` rounded to 2.
7.9 Using `EXCEPT`: the `product_id`s that have never been sold, ascending.
7.10 The `customer_id`s that are either in the `vip` segment or have placed at least 8 orders — each once, ascending.
