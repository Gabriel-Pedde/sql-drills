# 06 — Window functions

## 1. The idea

`GROUP BY` collapses rows. A window function computes a value **over a set of
related rows while keeping every row**. That single property — aggregate without
collapsing — is what makes running totals, rankings, and "compare this row to the
previous one" possible in plain SQL.

```sql
SELECT name, category_id, unit_price,
       avg(unit_price) OVER (PARTITION BY category_id) AS cat_avg,
       unit_price - avg(unit_price) OVER (PARTITION BY category_id) AS diff
FROM   products;
```
24 products in, 24 rows out — each carrying its category's average.

Anatomy:

```
function(args) OVER ( PARTITION BY ...   -- split rows into independent groups (optional)
                      ORDER BY ...       -- order within each partition (optional)
                      <frame>            -- which rows around the current one count (optional)
                    )
```

Everything after `OVER` is optional. `OVER ()` alone = one window over the whole
result set.

## 2. Where window functions run

They are evaluated **after** `WHERE`, `GROUP BY` and `HAVING`, and before
`ORDER BY`/`LIMIT`. Two consequences:

* You cannot filter on a window function in `WHERE` or `HAVING`. To filter,
  compute it in a subquery/CTE and filter outside. (Snowflake/BigQuery/DuckDB
  offer `QUALIFY` for this; Postgres/SQLite/MySQL do not.)
* Window functions see the *post-aggregation* rows, so they can be layered on
  top of a `GROUP BY` — `sum(sum(x)) OVER (...)` is legal and useful.

```sql
-- rank categories by revenue, in one query
SELECT   p.category_id,
         sum(i.quantity * i.unit_price * (1 - i.discount)) AS revenue,
         rank() OVER (ORDER BY sum(i.quantity * i.unit_price * (1 - i.discount)) DESC) AS rk
FROM     order_items i JOIN products p ON p.product_id = i.product_id
GROUP BY p.category_id;
```

## 3. Ranking functions

```sql
WITH t(v) AS (VALUES (10),(20),(20),(30))
SELECT v,
       row_number() OVER (ORDER BY v) AS rn,
       rank()       OVER (ORDER BY v) AS rk,
       dense_rank() OVER (ORDER BY v) AS dr,
       ntile(2)     OVER (ORDER BY v) AS half
FROM   t;
```

| v | row_number | rank | dense_rank |
|---|---|---|---|
| 10 | 1 | 1 | 1 |
| 20 | 2 | 2 | 2 |
| 20 | 3 | 2 | 2 |
| 30 | 4 | **4** | **3** |

* `row_number()` — always unique, ties broken arbitrarily (add tie-break columns
  to `ORDER BY` if you need determinism).
* `rank()` — ties share a rank, then it **skips**.
* `dense_rank()` — ties share a rank, no gaps.
* `ntile(n)` — split into n roughly equal buckets (quartiles etc.).

### Top-N per group — the pattern to memorise

```sql
WITH ranked AS (
    SELECT p.category_id, p.name, p.unit_price,
           row_number() OVER (PARTITION BY p.category_id
                              ORDER BY p.unit_price DESC, p.name) AS rn
    FROM   products p
)
SELECT category_id, name, unit_price FROM ranked WHERE rn <= 2 ORDER BY category_id, rn;
```
Swap `row_number` for `rank` if you want to keep ties, `dense_rank` for "top 2
distinct prices". This is *the* window-function interview question.

## 4. Offset functions: LAG and LEAD

```sql
SELECT   order_date,
         lag(order_date)  OVER (PARTITION BY customer_id ORDER BY order_date) AS prev_order,
         julianday(order_date)
           - julianday(lag(order_date) OVER (PARTITION BY customer_id ORDER BY order_date))
                                                                              AS days_since
FROM     orders;
```
`lag(x, n, default)` looks n rows back (default 1) and yields `default` (NULL
unless given) when there is no such row — the first row of every partition.
`lead` looks forward. Together they give you deltas, gaps, and churn analysis.

## 5. Aggregate windows and frames

With `ORDER BY` inside `OVER`, an aggregate becomes **cumulative**:

```sql
WITH monthly AS (
    SELECT   strftime('%Y-%m', o.order_date) AS month,
             sum(i.quantity * i.unit_price * (1 - i.discount)) AS revenue
    FROM     orders o JOIN order_items i ON i.order_id = o.order_id
    GROUP BY month
)
SELECT month, round(revenue, 2) AS revenue,
       round(sum(revenue) OVER (ORDER BY month), 2) AS running_total,
       round(avg(revenue) OVER (ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS ma3
FROM   monthly;
```

The **frame** decides which rows around the current one are included:

```
ROWS  BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW   -- physical rows
RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW   -- logical: peers = same ORDER BY value
ROWS  BETWEEN 2 PRECEDING AND CURRENT ROW           -- 3-row moving window
ROWS  BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING  -- the whole partition
```

Two traps worth the ink:

1. **The default frame is `RANGE UNBOUNDED PRECEDING`**, not `ROWS`. With ties in
   the `ORDER BY` column, all tied rows share one cumulative value — a "running
   total" that jumps in blocks. If you mean physical rows, say `ROWS`.
2. **`last_value()` looks broken by default.** With the default frame ending at
   CURRENT ROW, `last_value()` returns the current row. Write the frame out:
   `last_value(x) OVER (PARTITION BY ... ORDER BY ... ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)`.
   `first_value()` happens to work by accident with the default frame.

Omit `ORDER BY` inside `OVER` and the frame is the whole partition — that's how
`avg(unit_price) OVER (PARTITION BY category_id)` in §1 got a partition-wide
average.

## 6. Share-of-total, the one-liner

```sql
SELECT name, unit_price,
       round(100.0 * unit_price / sum(unit_price) OVER (PARTITION BY category_id), 1) AS pct_of_cat
FROM   products;
```
No self-join, no second pass. This is the shape most reporting queries want.

---

## Exercises — `exercises/06.sql`, then `python3 check.py 6`

6.1 Every product with its price rank inside its category (ties share a rank, gaps allowed): `category_id`, name, `unit_price`, rank — by `category_id`, rank, name.
6.2 The two highest-revenue products per category: `category_id`, product name, revenue rounded to 2 — by `category_id` then revenue desc.
6.3 Monthly revenue for 2024 with a running total, both rounded to 2 — by month.
6.4 Monthly revenue for 2024 with the previous month's revenue and the change, all rounded to 2 (NULL for January) — by month.
6.5 Every order numbered per customer in date order: `customer_id`, `order_id`, `order_date`, sequence number — by `customer_id`, sequence.
6.6 Every order with the days elapsed since that customer's previous order (NULL for the first): `customer_id`, `order_date`, `days_since_prev` — by `customer_id`, `order_date`.
6.7 Every order's revenue as a percentage of its customer's total revenue: `order_id`, revenue rounded to 2, pct rounded to 1 — by `order_id`.
6.8 Products split into price quartiles: name, `unit_price`, quartile — cheapest first, name as tie-break.
6.9 Monthly revenue for 2024 with a 3-month moving average, rounded to 2 — by month.
6.10 Each customer's single largest order: customer name, `order_id`, revenue rounded to 2 — biggest first.
