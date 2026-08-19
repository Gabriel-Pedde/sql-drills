# 01 — The shape of a SELECT

> Prereq: none. Run every example: `./sqlrun "SELECT ..."`

## 1. The one idea that fixes most confusion

SQL is written in one order and *evaluated* in another. Almost every "why doesn't
my alias work?" question dissolves once you know the logical order:

```
FROM      -> which tables, joined how
WHERE     -> throw away rows
GROUP BY  -> collapse rows into groups
HAVING    -> throw away groups
SELECT    -> compute the output columns (aliases are born here)
DISTINCT  -> de-duplicate the output rows
ORDER BY  -> sort what's left
LIMIT     -> take a slice
```

Two consequences you can predict from that list alone:

* `WHERE` cannot see a `SELECT` alias (WHERE runs first) — but `ORDER BY` can
  (it runs last). This is not a quirk, it falls straight out of the ordering.
* `WHERE` filters **rows**, `HAVING` filters **groups**. Using `HAVING` for a
  plain row condition works in some engines but says the wrong thing.

```sql
-- works everywhere: ORDER BY sees the alias
SELECT name, unit_price * 1.22 AS price_with_vat FROM products ORDER BY price_with_vat DESC LIMIT 3;

-- portable: WHERE repeats the expression instead of naming the alias
SELECT name, unit_price * 1.22 AS price_with_vat FROM products WHERE unit_price * 1.22 > 100;
```

SQLite is lenient here: it *will* run `WHERE price_with_vat > 100`, so the query
above works in `./sqlrun`. PostgreSQL and SQL Server reject it
(`column "price_with_vat" does not exist`). Repeat the expression in `WHERE` and
the query runs on all of them.

The leniency stops at `WHERE` and `HAVING` — an alias is never visible to the
rest of its own `SELECT` list, in any engine:

```sql
SELECT unit_price * 1.22 AS v, unit_price * 2 FROM products;
--> no such column: v
```

## 2. Projection and filtering

```sql
SELECT name, city, segment, country          -- projection: choose columns
FROM   customers
WHERE  country = 'Germany'          -- restriction: choose rows
ORDER  BY name;                     -- sort (ASC is the default)
```

`SELECT *` is fine when exploring, a liability in code: it breaks when a column
is added, ships bytes you don't need, and hides which columns a query depends on.

Useful predicates:

| Predicate | Meaning | Note |
|---|---|---|
| `x BETWEEN a AND b` | `x >= a AND x <= b` | **inclusive** on both ends |
| `x IN (1,2,3)` | equals any of them | shorthand for OR-chains |
| `name LIKE 'A%'` | `%` = any run of chars, `_` = exactly one | SQLite `LIKE` is case-insensitive for ASCII; Postgres' is not (`ILIKE` there) |
| `x IS NULL` | x is unknown | **never** `x = NULL` |

## 3. NULL: the part that catches everyone

`NULL` is not a value, it's "unknown". So SQL uses **three-valued logic**:
every comparison returns TRUE, FALSE, or UNKNOWN, and `WHERE` keeps only TRUE.

```sql
SELECT NULL = NULL, NULL <> 'x', NULL + 1;   -- all NULL (unknown), not true/false/1
```

The consequences you must internalise:

```sql
SELECT count(*) FROM customers WHERE country = 'France';      -- 3
SELECT count(*) FROM customers WHERE country <> 'France';     -- 20, NOT 22
SELECT count(*) FROM customers WHERE country IS NULL;         -- 2  <- the missing rows
```

`country <> 'France'` is UNKNOWN for the two NULL-country customers, so they are
dropped by **both** the positive and the negative filter. If you want them:

```sql
WHERE country <> 'France' OR country IS NULL
-- or, more compactly in SQLite/Postgres:
SELECT count(*) FROM customers WHERE country IS DISTINCT FROM 'France';   -- SQLite spells this  IS NOT 'France'
```

`COALESCE(a, b, ...)` returns the first non-NULL argument — the standard way to
substitute a default:

```sql
SELECT name, COALESCE(country, '(unknown)') as country FROM customers WHERE country IS NULL;
```

Also remember: aggregate functions **ignore** NULLs (`avg` divides by the count
of non-NULL values), but `count(*)` counts rows including all-NULL ones. More on
that in tutorial 02.

## 4. CASE — the if/else of SQL

```sql
SELECT name,
       unit_price,
       CASE WHEN unit_price <  5  THEN 'budget'
            WHEN unit_price < 20  THEN 'mid'
            ELSE                       'premium'
       END AS price_band
FROM   products
ORDER  BY unit_price;
```

Branches are tested top to bottom, first match wins, and a missing `ELSE` yields
`NULL`. `CASE` is an expression, so it works anywhere a value works — inside
`SELECT`, `WHERE`, `ORDER BY`, even inside `sum()` (a trick you'll use in 02).

## 5. Sorting and slicing

```sql
SELECT name, unit_price FROM products
ORDER BY unit_price DESC, name ASC     -- tie-break with a second key
LIMIT 5 OFFSET 10;                     -- rows 11..15
```

* Sorting is the only way to get ordered output. **Without `ORDER BY` there is no
  order** — a result that looks sorted today can come back shuffled tomorrow when
  the plan changes.
* NULLs sort together, but *where* is engine-dependent (SQLite/Postgres:
  `NULLS LAST` on `DESC`, first on `ASC`... Postgres lets you say
  `ORDER BY x NULLS FIRST` explicitly; be explicit when it matters).
* `LIMIT` without `ORDER BY` gives you an arbitrary sample, not "the top N".

## 6. Dates in SQLite

SQLite has no date type: dates are `'YYYY-MM-DD'` **text**, which sorts correctly
as text. Comparisons and `BETWEEN` work as expected, plus helpers:

```sql
SELECT strftime('%Y', order_date) AS yr, count(*) FROM orders GROUP BY yr;
SELECT date('2024-03-10', '+10 days') AS current_date;           -- 2024-04-10
SELECT count(*) FROM orders
WHERE  order_date >= '2024-01-01' AND order_date < '2025-01-01';
```

That last filter is the habit to build: a **half-open range**
(`>= start AND < next_start`) rather than `BETWEEN '2024-01-01' AND '2024-12-31'`.
It stays correct when the column later gains a time component — `BETWEEN` would
silently drop everything after midnight on the last day.

---

## Exercises

Open `exercises/01.sql`, write each query under its `@ex` marker, then run:

```bash
python3 check.py 1          # add -v to see expected rows when you're stuck
```

1.1 Name, city and segment of every customer in Germany, sorted by name.
1.2 `customer_id`, `name`, `signup_date` for customers who signed up during 2023, oldest first.
1.3 Name and price of products that are not discontinued and cost from 5 to 20 inclusive, most expensive first.
1.4 The customers whose country is unknown: `customer_id`, `name`, `city`.
1.5 The distinct countries customers come from, excluding unknown, alphabetically.
1.6 Name, price and a `price_band` label (`budget` < 5, `mid` < 20, else `premium`) for every product, cheapest first.
1.7 Every customer's `customer_id`, `name`, and country with unknowns shown as the text `Unknown`, by id.
1.8 The three most expensive products that are still sold: name and price.
1.9 Name and email of customers whose email is **not** an `example.com` address, by name.
