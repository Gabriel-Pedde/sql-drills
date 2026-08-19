# 08 — Designing tables: DDL, keys, constraints, normalization

Up to here you've been reading. This tutorial is about the decisions that make
reading easy — or impossible.

## 1. CREATE TABLE and types

```sql
CREATE TABLE reviews (
    review_id   INTEGER PRIMARY KEY,                     -- surrogate key
    product_id  INTEGER NOT NULL REFERENCES products(product_id),
    customer_id INTEGER NOT NULL REFERENCES customers(customer_id),
    rating      INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment     TEXT,
    created_at  TEXT    NOT NULL DEFAULT (date('now'))
);
```

**Types.** SQLite is unusual: types are *affinities*, and it will happily store
`'banana'` in an `INTEGER` column (unless the table is declared `STRICT`, added in
3.37). Every other engine enforces types. Don't learn sloppy habits from SQLite —
declare the type you mean.

Portable type choices: `INTEGER`/`BIGINT`, `NUMERIC(p,s)` or `DECIMAL` for money
(**never** `FLOAT`/`REAL` for money — 0.1 + 0.2 ≠ 0.3 in binary floating point),
`TEXT`/`VARCHAR(n)`, `DATE`/`TIMESTAMP` where they exist, `BOOLEAN` where it
exists (SQLite uses 0/1).

## 2. Constraints: the cheapest correctness you will ever buy

| Constraint | Guarantees |
|---|---|
| `PRIMARY KEY` | unique + not null; the row's identity |
| `UNIQUE` | no duplicate values (NULLs usually still allowed, and multiple NULLs are permitted) |
| `NOT NULL` | value is always present |
| `CHECK (expr)` | domain rule, e.g. `quantity > 0`, `discount BETWEEN 0 AND 0.5` |
| `DEFAULT expr` | value used when the column is omitted on INSERT |
| `FOREIGN KEY` | the referenced row exists |

A constraint is enforced for *every* writer — your app, a colleague's script, a
midnight backfill. Application-level validation is not a substitute; it is a
nicer error message on top.

**Natural vs surrogate keys.** A natural key is real data (`email`, ISO country
code); a surrogate is a meaningless id. Surrogates are the default choice because
real-world data changes (people change emails) and keys should not. Keep the
natural key as a `UNIQUE` constraint — you get identity stability *and* the
uniqueness rule.

**Composite keys** are right when a row is identified by a combination:
`order_items` uses `PRIMARY KEY (order_id, line_no)` because a line number only
means something inside an order.

## 3. Foreign keys and what happens on delete

```sql
FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE
```

| Action | Effect when the parent row is deleted |
|---|---|
| `NO ACTION` / `RESTRICT` (default) | the delete is refused |
| `CASCADE` | children are deleted too |
| `SET NULL` | the child's FK column becomes NULL (column must be nullable) |
| `SET DEFAULT` | the child's FK column reverts to its default |

Choose by meaning: order lines *belong to* an order → `CASCADE`. An order
*references* an employee who may leave → `SET NULL`. Products referenced by
historic orders → `RESTRICT`, because deleting them would erase history.

**SQLite gotcha:** foreign keys are checked only when
`PRAGMA foreign_keys = ON` — off by default, per connection. `sqlrun` and the
grader both switch it on.

## 4. Normalization, without the incantations

Normalization = store each fact once, in the place it belongs.

* **1NF** — one value per cell. No `'red,green,blue'` in a `tags` column, no
  `phone1`/`phone2`/`phone3`. A repeating group becomes a child table.
* **2NF** — no column depending on only *part* of a composite key. In
  `order_items(order_id, line_no, …)`, storing `customer_name` would break this:
  the customer depends on the order, not on the line.
* **3NF** — no column depending on another non-key column. Storing
  `category_name` in `products` breaks it: the name depends on `category_id`, not
  on the product. Rename a category and you'd have to update every product row —
  and until you finish, the database disagrees with itself.

The practical test is not "which normal form is this?" but **"can this database
contradict itself?"** Every duplicated fact is a future inconsistency.

### When to denormalize deliberately

Two legitimate reasons:

1. **Point-in-time snapshots.** `order_items.unit_price` duplicates
   `products.unit_price` *on purpose*: the price on the invoice must not change
   when the catalogue price changes tomorrow. This is not redundancy — it is a
   different fact ("price charged" ≠ "price today").
2. **Measured performance.** A cached aggregate (`orders.total_amount`) when the
   join genuinely costs too much — accepted with a plan for keeping it correct
   (trigger, scheduled recompute) and the knowledge that it *will* drift.

"It's faster" without a measurement is not a reason.

## 5. Changing tables

```sql
ALTER TABLE customers ADD COLUMN phone TEXT;
CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE VIEW order_totals AS
    SELECT order_id, sum(quantity * unit_price * (1 - discount)) AS total
    FROM   order_items GROUP BY order_id;
DROP VIEW order_totals;
```

SQLite's `ALTER TABLE` supports only `ADD COLUMN`, `RENAME`, and `DROP COLUMN`
(3.35+); anything else means create-new/copy/rename. Postgres can alter almost
anything, but a type change rewrites the table and takes a heavy lock — on a big
production table, that's an outage. Adding a **nullable** column with no default
is the cheap operation everywhere; that's why "add nullable, backfill, then
enforce" is the standard migration dance.

A `VIEW` stores a query, not data: it costs nothing to keep and always reflects
current rows. A **materialized** view (Postgres, not SQLite) stores results and
must be refreshed.

---

## Exercises — `exercises/08.sql`, then `python3 check.py 8`

These write to the database. That's safe: the grader runs every answer against a
private in-memory copy, so `shop.db` on disk is never touched. If you experiment
in `./sqlrun` and make a mess, `./sqlrun --fresh` rebuilds it.

Each exercise has a `-- @verify` block below your answer — **don't edit it**, it
is what the grader inspects. Read it: it tells you exactly what is being tested.

8.1 Create the `reviews` table from §1 (same column names, `NOT NULL`s and primary key).
8.2 Create a `reviews` table plus a constraint that stops one customer reviewing the same product twice.
8.3 Add a nullable `phone` column to `customers`.
8.4 Create a `product_tags` table implementing a many-to-many tag relation in 1NF.
8.5 Create a `shipments` table where `shipped_on` defaults to today and `carrier` defaults to `'DHL'`, then insert a row giving only the id.
8.6 Create a `promotions` table where the end date can never precede the start date.
8.7 Create an `order_notes` child table that is deleted along with its order.
8.8 Create an `assignments` table whose `employee_id` becomes NULL when the employee row is deleted.
8.9 Show that `order_items.unit_price` really is a snapshot: count the lines whose price differs from the product's current price.
8.10 Create the `order_totals` view from §5 and select the five largest totals from it.
