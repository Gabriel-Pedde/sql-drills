# 02 — Aggregation: GROUP BY, HAVING, and counting things correctly

## 1. What an aggregate actually does

An aggregate function collapses **many rows into one value**. With no `GROUP BY`,
the whole table is one group and you always get exactly one row back:

```sql
SELECT count(*) AS n_products, avg(unit_price) AS avg_price, max(unit_price) AS dearest
FROM   products;
```

With `GROUP BY`, rows are partitioned into buckets and each bucket yields one row:

```sql
SELECT segment, count(*) AS n
FROM   customers
GROUP  BY segment
ORDER  BY n DESC;
```

Rule that follows from "one row per group": every column in `SELECT` must be
either **in the `GROUP BY`** or **inside an aggregate**. Otherwise the engine
cannot say which of the group's values to show.

```sql
-- Wrong in Postgres/MySQL-strict; SQLite silently picks an arbitrary row:
SELECT segment, name, count(*) FROM customers GROUP BY segment;
```
SQLite's leniency here is a trap. Don't rely on it — if you want a name, decide
*which* name (`min(name)`, or a window function from tutorial 06).

## 2. count: three different questions

```sql
SELECT count(*)                AS rows_total,       -- 25  rows, NULLs included
       count(country)          AS with_country,     -- 23  non-NULL values
       count(DISTINCT country) AS distinct_countries-- 15  distinct non-NULL values
FROM   customers;
```

* `count(*)` — how many rows.
* `count(col)` — how many rows where `col` is not NULL. This is the idiomatic way
  to count "how many have X filled in".
* `count(DISTINCT col)` — how many different values.

**All aggregates ignore NULLs** (except `count(*)`). That matters most for `avg`:

```sql
-- avg divides by the number of non-NULL values, not by the number of rows
SELECT avg(x) FROM (SELECT 10 AS x UNION ALL SELECT 20 UNION ALL SELECT NULL);  -- 15, not 10
```
If NULL should mean zero, say so: `avg(COALESCE(x, 0))`.

Also: `sum()` over zero rows returns **NULL**, not 0. Wrap it when a number is
required: `COALESCE(sum(x), 0)`.

## 3. WHERE vs HAVING

```sql
SELECT   customer_id, count(*) AS n_orders
FROM     orders
WHERE    status <> 'cancelled'     -- filters ROWS, before grouping
GROUP BY customer_id
HAVING   count(*) >= 5             -- filters GROUPS, after aggregation
ORDER BY n_orders DESC;
```

Put a condition in `WHERE` whenever it can be decided per row — it is evaluated
earlier, on fewer rows, and is usually indexable. `HAVING` is only for conditions
about the aggregate itself.

## 4. Conditional aggregation — the workhorse

`CASE` inside an aggregate lets you compute several filtered numbers in **one
pass**, which is how you build report rows and pivots:

```sql
SELECT strftime('%Y', order_date)                            AS yr,
       count(*)                                              AS n_orders,
       sum(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) AS n_cancelled,
       round(100.0 * sum(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) / count(*), 1)
                                                             AS pct_cancelled
FROM   orders
GROUP  BY yr
ORDER  BY yr;
```

Two idioms in there worth stealing:

* `sum(CASE WHEN cond THEN 1 ELSE 0 END)` = "count of rows matching cond".
  The standard spelling, supported by SQLite ≥3.30 and Postgres, is
  `count(*) FILTER (WHERE cond)` — cleaner when available.
* `100.0 *` — force floating point. `100 * 3 / 4` is **0** in integer arithmetic
  (SQLite, Postgres, and friends all do integer division on integers).

## 5. Grouping by an expression

You can group by any expression, not just a column:

```sql
SELECT substr(signup_date, 1, 4) AS yr, count(*) FROM customers GROUP BY yr ORDER BY yr;
```
Postgres and SQLite let you reuse the `SELECT` alias in `GROUP BY`; strict engines
want the expression repeated. Repeating it is always safe.

## 6. The revenue convention used from here on

`order_items` stores the price *at the time of sale* plus a discount fraction, so
the money value of a line is:

```sql
quantity * unit_price * (1 - discount)
```

Every exercise that says "revenue" means exactly that, rounded to 2 decimals
where asked. Example — the ten highest-grossing orders:

```sql
SELECT   order_id, round(sum(quantity * unit_price * (1 - discount)), 2) AS revenue
FROM     order_items
GROUP BY order_id
ORDER BY revenue DESC
LIMIT    10;
```

---

## Exercises — `exercises/02.sql`, then `python3 check.py 2`

2.1 Number of customers per segment, biggest first, ties broken by segment name.
2.2 Per `category_id`: how many products, and their average price rounded to 2 decimals, by category_id.
2.3 One row with `rows_total`, `with_country`, `distinct_countries` for the customers table.
2.4 Order statuses that occur at least 10 times: status and the count, most frequent first.
2.5 The five orders with the highest revenue: `order_id` and revenue rounded to 2.
2.6 Products that appear in at least 15 distinct orders: `product_id`, total units sold, number of distinct orders — most units first, `product_id` as tie-break.
2.7 Per calendar year of `order_date`: number of orders, number cancelled, and cancelled percentage rounded to 1 decimal, by year.
2.8 Per department: headcount, lowest salary, highest salary, average salary rounded to 2 — by department name.
2.9 Number of customers per signup year, by year.
2.10 Customers with at least 6 non-cancelled orders: `customer_id` and that count, highest first, `customer_id` as tie-break.
