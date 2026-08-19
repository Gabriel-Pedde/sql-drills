# 10 — Indexes, query plans, and making it fast

## 1. Read the plan, don't guess

Every engine will tell you how it intends to run a query:

```sql
EXPLAIN QUERY PLAN SELECT order_id FROM orders WHERE customer_id = 9;   -- SQLite
EXPLAIN ANALYZE    SELECT ...;                                          -- Postgres/MySQL: plan + real timings
```

SQLite's vocabulary is small enough to learn in a minute:

| Plan text | Meaning |
|---|---|
| `SCAN t` | reads every row of `t` — fine for 24 products, fatal for 24M |
| `SEARCH t USING INDEX ix (col=?)` | jumps straight to matching rows via `ix` |
| `USING COVERING INDEX ix` | answered entirely from the index; the table was never touched |
| `USE TEMP B-TREE FOR ORDER BY` | it had to sort — no index provided the order |
| `SEARCH t USING INTEGER PRIMARY KEY (rowid=?)` | direct row lookup, the cheapest access there is |

Optimisation loop: **plan → change one thing → plan again**. Guessing which query
is faster is the single most reliable way to waste an afternoon.

## 2. What an index is

A B-tree keeping `(indexed columns → row location)` **sorted**. That buys three
things: equality lookup, range scans, and *pre-sorted order*. It costs storage and
write time — every INSERT/UPDATE/DELETE must maintain every affected index. That
is the whole trade-off: **indexes make reads faster and writes slower.**

```sql
CREATE INDEX        idx_orders_customer ON orders(customer_id);
CREATE UNIQUE INDEX idx_customers_email ON customers(email);   -- also enforces uniqueness
CREATE INDEX        idx_orders_pending  ON orders(order_date) WHERE status = 'pending';  -- partial
DROP INDEX idx_orders_customer;
```

What to index, in priority order:

1. **Foreign key columns.** `order_items.order_id` is joined on constantly; without
   an index every join re-scans the whole child table.
2. Columns in selective `WHERE` clauses.
3. Columns in `ORDER BY` that pair with `LIMIT`.

Primary keys and `UNIQUE` constraints are indexed automatically — don't duplicate
them. And an index on a column with three distinct values across a million rows
(`status`) usually won't be used for a plain scan-and-filter; the engine correctly
decides a table scan is cheaper. Selectivity is what makes an index worth having.

## 3. Sargability — why your index is being ignored

A predicate is *sargable* (Search-ARGument-able) if the engine can use an index
for it. The rule is simple: **the indexed column must appear bare on one side of
the comparison.** Wrap it in a function or arithmetic and the index is dead,
because the index stores `order_date`, not `strftime('%Y', order_date)`.

| Not sargable | Sargable rewrite |
|---|---|
| `strftime('%Y', order_date) = '2024'` | `order_date >= '2024-01-01' AND order_date < '2025-01-01'` |
| `unit_price * 1.22 > 100` | `unit_price > 100 / 1.22` |
| `substr(email, -12) = '@example.com'` | `email LIKE '%@example.com'` (still a scan — see below) |
| `lower(name) = 'marta silva'` | index the expression: `CREATE INDEX … ON customers(lower(name))` |

`LIKE 'Espresso%'` can use an index (it's a range on the prefix);
`LIKE '%Espresso'` cannot — a leading wildcard has no prefix to seek to. Full-text
search is the answer there, not a bigger index.

**Expression indexes** (SQLite 3.9+, Postgres) are the escape hatch when the
function really is unavoidable: index exactly the expression you query on.

## 4. Composite indexes and the left-most prefix rule

`CREATE INDEX ix ON order_items(product_id, quantity)` sorts by `product_id`
first, then by `quantity` inside each product. So it serves:

* `WHERE product_id = 5`  ✔
* `WHERE product_id = 5 AND quantity > 2`  ✔
* `WHERE quantity > 2` alone  ✘ — nothing to seek on; it's a scan

Think of a phone book sorted by (surname, first name): useless for finding
everyone called "Maria". **Order the columns: equality predicates first, then the
range/sort column.**

A **covering index** contains every column the query touches, so the table is
never read:

```sql
CREATE INDEX idx_products_cat_price ON products(category_id, unit_price);
EXPLAIN QUERY PLAN SELECT unit_price FROM products WHERE category_id = 4;
--> SEARCH products USING COVERING INDEX idx_products_cat_price (category_id=?)
```

## 5. Other things that decide the plan

* **Statistics.** The optimiser is a cost estimator; it needs to know how big and
  how skewed the data is. Run `ANALYZE` (SQLite/Postgres) after big data changes;
  Postgres autovacuum usually handles it.
* **`ORDER BY … LIMIT`** is served straight from an index when one matches the
  sort — no temp B-tree, and it stops early. Without it, the engine sorts the
  whole result to hand you 5 rows.
* **`OFFSET` doesn't skip work.** `LIMIT 20 OFFSET 100000` still walks 100,020
  rows. For deep pagination use keyset pagination:
  `WHERE (order_date, order_id) < (:last_date, :last_id) ORDER BY … LIMIT 20`.
* **`SELECT *` defeats covering indexes** by definition — it asks for columns the
  index doesn't have.
* **`count(*)` on a huge table is not free** in Postgres (MVCC means it must
  visit rows). An approximate count from statistics is often what you actually want.
* **N+1 queries** — one query per row in application code — beat any index you
  can build. One join, or one `IN (…)`, instead of 500 round trips.

## 6. A working order

1. Find the slow query (log, `pg_stat_statements`, APM) — don't optimise by vibes.
2. Read its plan; look for `SCAN` on a big table and for sorts.
3. Make the predicate sargable, or add the index the plan is missing.
4. Re-run the plan **and** the timing. Keep the change only if it earned its keep.
5. Check what the new index costs your write path.

---

## Exercises — `exercises/10.sql`, then `python3 check.py 10`

These are plan-reading exercises: each answer creates the index (**use exactly the
index name given** — the plan text is compared) and ends with an
`EXPLAIN QUERY PLAN` statement whose output the grader checks. Your index is
created on the grader's private copy, not on `shop.db`.

10.1 Index `orders(customer_id)` as `idx_orders_customer`, then show the plan for looking up one customer's orders.
10.2 Index `orders(order_date)` as `idx_orders_date`, then show the plan for a **sargable** "orders placed in 2024" query.
10.3 With `idx_items_prod_qty` on `order_items(product_id, quantity)`, show the plan for filtering on `quantity` alone — and see the left-most prefix rule bite.
10.4 Build a covering index `idx_products_cat_price` so that fetching prices for one category never touches the table.
10.5 Index `products(unit_price)` as `idx_products_price` so that "5 cheapest products" needs no sort.
10.6 With `idx_products_price2` on `products(unit_price)`, show the plan for a sargable rewrite of `unit_price * 1.22 > 100`.
10.7 Index `order_items(order_id)` as `idx_items_order`, then show the plan for joining one order to its lines.
10.8 Create the partial index `idx_orders_pending` on `orders(order_date) WHERE status = 'pending'` and show it being used.
10.9 Create the expression index `idx_customers_lower_name` on `customers(lower(name))` and show a case-insensitive name lookup using it.
10.10 Create `idx_items_prod_cover` on `order_items(product_id, quantity)` and show that units-sold-per-product is answered by a covering index alone.
