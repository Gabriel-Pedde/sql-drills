# 09 — Changing data: INSERT, UPDATE, DELETE, transactions

## 1. INSERT

```sql
INSERT INTO customers (customer_id, name, email, country, city, segment, signup_date)
VALUES (100, 'New Client', 'new@example.com', 'Spain', 'Madrid', 'retail', '2025-01-15');

-- several rows at once (one statement = one round trip = much faster than a loop)
INSERT INTO categories (category_id, name) VALUES (6, 'Garden'), (7, 'Pet');

-- insert the result of a query
-- (vip_customers is not in shop.db — you create it in exercise 9.2)
INSERT INTO vip_customers (customer_id, name)
SELECT customer_id, name FROM customers WHERE segment = 'vip';
```

Always list the target columns. `INSERT INTO t VALUES (...)` binds to column
*position*, so it breaks the day someone adds a column — a silent, data-corrupting
break.

Conflict handling:

```sql
-- (product_tags and stock_counts are not in shop.db — exercises 8.4 and 9.7)
INSERT OR IGNORE INTO product_tags (product_id, tag) VALUES (1, 'coffee');  -- skip violations
INSERT INTO stock_counts (product_id, counted, counted_on)                  -- UPSERT
VALUES (1, 118, '2025-01-15')
ON CONFLICT (product_id) DO UPDATE
    SET counted    = excluded.counted,     -- `excluded` = the row you tried to insert
        counted_on = excluded.counted_on;
```
`ON CONFLICT … DO UPDATE` is the SQLite/Postgres spelling; MySQL says
`ON DUPLICATE KEY UPDATE`; the standard says `MERGE`. All solve "insert it, or
update it if it's already there" **atomically** — unlike a SELECT-then-INSERT in
application code, which two concurrent workers can both pass.

`RETURNING` (SQLite 3.35+, Postgres, and now MySQL 8.0.x variants) hands back the
rows you just wrote — the clean way to get a generated id:

```sql
INSERT INTO categories (name) VALUES ('Garden') RETURNING category_id;
```

## 2. UPDATE

```sql
UPDATE employees SET salary = salary * 1.10 WHERE title = 'Sales Rep';
```

The `WHERE` clause is the whole job. Discipline that costs three seconds and
saves your afternoon: **write it as a `SELECT` first**, check the row count,
then swap `SELECT *` for `UPDATE … SET`. Inside an explicit transaction you also
get an undo button (§4).

Updating from another table:

```sql
-- correlated subquery: portable everywhere
-- (orders.total_amount is not in shop.db — you add the column in exercise 9.5)
UPDATE orders
SET    total_amount = (SELECT sum(quantity * unit_price * (1 - discount))
                       FROM   order_items i WHERE i.order_id = orders.order_id);

-- UPDATE ... FROM: SQLite 3.33+, Postgres; shorter when several columns are involved
UPDATE orders AS o
SET    total_amount = t.total
FROM  (SELECT order_id, sum(quantity * unit_price * (1 - discount)) AS total
       FROM order_items GROUP BY order_id) AS t
WHERE  t.order_id = o.order_id;
```
Careful with the correlated form: orders with no items get `NULL`, not 0, because
`sum` over no rows is NULL. Add `WHERE EXISTS (...)` or wrap in `COALESCE`.

## 3. DELETE

```sql
DELETE FROM orders WHERE status = 'cancelled' AND order_date < '2023-01-01';
```
`DELETE FROM t` with no `WHERE` empties the table. `TRUNCATE` (not in SQLite)
does the same much faster but usually can't be rolled back and ignores triggers.

Deletes interact with foreign keys: a child row referencing the target either
blocks the delete (`RESTRICT`), follows it (`CASCADE`), or is orphaned to NULL
(`SET NULL`) — tutorial 08 §3. In this database, deleting an order cascades to
its `order_items` but is *blocked* while a `payments` row references it.

## 4. Transactions

A transaction groups statements into one all-or-nothing unit:

```sql
-- (accounts is not in shop.db — the classic transfer, shown for the shape)
BEGIN;
    UPDATE accounts SET balance = balance - 100 WHERE id = 1;
    UPDATE accounts SET balance = balance + 100 WHERE id = 2;
COMMIT;          -- or ROLLBACK; to undo everything since BEGIN
```

**ACID:**

* **Atomicity** — all statements commit, or none do. A crash mid-transaction
  leaves no half-transfer.
* **Consistency** — constraints hold at transaction boundaries.
* **Isolation** — concurrent transactions don't see each other's partial work
  (how strictly: see below).
* **Durability** — once `COMMIT` returns, the data survives a power cut.

`SAVEPOINT` gives partial rollback inside a transaction:

```sql
BEGIN;
    INSERT INTO categories (category_id, name) VALUES (8, 'Toys');
    SAVEPOINT sp1;
    INSERT INTO categories (category_id, name) VALUES (9, 'Oops');
    ROLLBACK TO sp1;        -- undoes only 'Oops'; 'Toys' still pending
COMMIT;
```

### Isolation levels and the anomalies they prevent

| Level | Dirty read | Non-repeatable read | Phantom |
|---|---|---|---|
| READ UNCOMMITTED | possible | possible | possible |
| READ COMMITTED (Postgres/Oracle default) | no | possible | possible |
| REPEATABLE READ (MySQL InnoDB default) | no | no | possible* |
| SERIALIZABLE | no | no | no |

* **Dirty read** — you see another transaction's uncommitted change.
* **Non-repeatable read** — you read a row twice in one transaction and get
  different values, because someone committed in between.
* **Phantom** — you re-run the same `WHERE` and new *rows* have appeared.

(*InnoDB's snapshot reads actually avoid phantoms too. Details vary by engine —
which is the real lesson: know your engine's default. SQLite is effectively
SERIALIZABLE: one writer at a time.)

### The read-modify-write race

```sql
-- BROKEN under concurrency: two sessions read 10, both write 9, one sale vanishes
SELECT units_in_stock FROM products WHERE product_id = 1;   -- app computes 10 - 1
UPDATE products SET units_in_stock = 9 WHERE product_id = 1;

-- CORRECT: let the database do the arithmetic in one atomic statement
UPDATE products SET units_in_stock = units_in_stock - 1
WHERE  product_id = 1 AND units_in_stock >= 1;              -- and never go negative
```
Check the affected row count: 0 means the stock guard rejected it. When the logic
genuinely can't fit in one statement, take an explicit lock
(`SELECT … FOR UPDATE` in Postgres/MySQL) or use optimistic concurrency
(a `version` column in the `WHERE`).

---

## Exercises — `exercises/09.sql`, then `python3 check.py 9`

Same as tutorial 08: your writes go to a private copy, `shop.db` is safe, and each
block's `-- @verify` section shows exactly what is being checked.

9.1 Insert customer 100, 'New Client', Spain/Madrid, retail, signed up 2025-01-15.
9.2 Create `vip_customers(customer_id, name)` and fill it from the `vip` segment with one statement.
9.3 Give every Sales Rep a 10% raise.
9.4 Set `units_in_stock` to 0 for all discontinued products.
9.5 Add a `total_amount` column to `orders` and populate it from `order_items` (0 where an order has no lines).
9.6 Delete every cancelled order that has no payment (the line items must go too).
9.7 Create `stock_counts(product_id PK, counted, counted_on)`, insert a count for product 1, then upsert a second count for product 1 and a first for product 2.
9.8 Inside a transaction, double every product price, then roll it back.
9.9 Using a savepoint: insert category 8 'Toys', then insert category 9 'Oops' and undo only that one, then commit.
9.10 Decrement stock for product 1 by 5 the safe way — a single statement that can never push stock below zero.
