# sql-drills

[![ci](https://github.com/Gabriel-Pedde/sql-drills/actions/workflows/ci.yml/badge.svg)](https://github.com/Gabriel-Pedde/sql-drills/actions/workflows/ci.yml)

111 SQL exercises with an auto-grader, run against a generated dataset built to
contain the awkwardness real data has — customers with no orders, orders with no
sales rep, products never sold, half-paid invoices, a `NULL`-managed CEO.

The grader runs your answer and the reference solution against separate private
in-memory copies of the database and compares the result sets, so **any working
query counts** — not only the one that happens to match the reference. Eleven
tutorials come with it, covering `SELECT` through window functions, transaction
isolation, and query plans.

No installation, no dependencies: it uses the SQLite engine that ships inside
Python 3.

```bash
python3 db/build.py          # build shop.db (already done, but this resets it)
./sqlrun                     # interactive SQL shell
./sqlrun "SELECT * FROM products LIMIT 5"
python3 check.py 3           # grade your answers to tutorial 3
```

## How to work through it

1. Read `tutorials/NN_*.md`. Paste the examples into `./sqlrun` as you go and
   poke at them — changing an example until it breaks teaches more than reading
   it twice. (Most run as-is against `shop.db`; a few are deliberately fragments,
   pseudo-syntax templates, or other engines' dialects, and say so.)
2. Open `exercises/NN.sql` and write each query under its `-- @ex` marker.
3. Run `python3 check.py NN`. Add `-v` to see the expected rows when you're stuck,
   `python3 check.py NN.M` to grade a single exercise.
4. Only then look at `solutions/NN.sql`. Comparing your working query to a
   different working query is where most of the learning is — peeking before you
   have one is where most of it is lost.

`python3 check.py` with no argument grades everything you've attempted.

## The tutorials

| # | Topic | You'll be able to |
|---|---|---|
| 01 | [The shape of a SELECT](tutorials/01_select_filter_order.md) | filter, sort, slice; survive `NULL` and three-valued logic |
| 02 | [Aggregation](tutorials/02_aggregation.md) | `GROUP BY`/`HAVING`, count things correctly, conditional aggregation |
| 03 | [Joins](tutorials/03_joins.md) | every join type, `ON` vs `WHERE`, anti-joins, spotting fan-out |
| 04 | [Subqueries](tutorials/04_subqueries.md) | scalar/`IN`/`EXISTS`/derived tables, the `NOT IN` NULL trap |
| 05 | [CTEs and recursion](tutorials/05_ctes_and_recursion.md) | decompose with `WITH`, walk hierarchies, generate date spines |
| 06 | [Window functions](tutorials/06_window_functions.md) | rankings, running totals, `LAG`/`LEAD`, frames, top-N-per-group |
| 07 | [Set operations and pivots](tutorials/07_set_operations_and_pivots.md) | `UNION`/`INTERSECT`/`EXCEPT`, pivot and unpivot, totals rows |
| 08 | [Modeling, DDL, constraints](tutorials/08_modeling_ddl_constraints.md) | design tables that can't hold wrong data; normalization that means something |
| 09 | [DML and transactions](tutorials/09_dml_and_transactions.md) | `INSERT`/`UPDATE`/`DELETE`, upserts, ACID, isolation, race conditions |
| 10 | [Indexes and performance](tutorials/10_indexes_and_performance.md) | read query plans, index deliberately, write sargable predicates |
| 11 | [Capstone drills](tutorials/11_capstone_drills.md) | twelve realistic problems + a trap checklist |

Tutorials 1–7 are query-writing and build on each other in order. 8–10 stand on
their own — take them whenever you want, though they read best after 7.

## The database

An online shop. `db/schema.sql` is the DDL, `db/seed.sql` the reference data,
`db/build.py` generates the transactional rows (deterministically — same data
every rebuild).

```
customers ──< orders ──< order_items >── products >── categories
                 │                            └──────>── suppliers
                 └──< payments
employees ──< orders          employees.manager_id ──> employees  (self-reference)
```

The data contains deliberate awkwardness, because clean data teaches nothing:
customers with no orders, two customers with an unknown country, orders with no
sales rep, products never sold, orders never paid or half-paid, in-house products
with no supplier, and a self-referencing org chart with a `NULL`-managed CEO.

Revenue, throughout, means `quantity * unit_price * (1 - discount)` on
`order_items`.

## Notes on the grader

* Your answer and the reference solution both run against a **private in-memory
  copy** of `shop.db`, and the result sets are compared. Tutorials 8–10 write,
  create tables, and create indexes — none of it touches the file on disk.
* Column names and aliases are ignored; numbers are compared rounded to 2
  decimals. Row order is ignored unless the exercise is tagged `ordered`.
* Some exercises have a `-- @verify` block: your statements run first, then that
  block inspects the result. Don't edit it — read it, it says exactly what's being
  checked.
* Any working query counts. If yours differs from the reference and both pass,
  both are right.

## Dialect

Everything runs on SQLite 3.46 (bundled with Python 3.13). The tutorials flag
where SQLite differs from PostgreSQL, MySQL, and SQL Server — the leniency SQLite
allows around `GROUP BY`, types, and aliases is called out each time, so nothing
here trains a habit that breaks on a real server.

## Development

```bash
python3 ci/verify_solutions.py
```

Checks that every exercise has a reference solution, that each one executes
against a freshly built database and comes back with rows, and that the grader
passes the full set. CI runs it on Python 3.11–3.13 and confirms the committed
`shop.db` still matches what `db/build.py` produces.

It deliberately does not claim the solutions are *correct* — grading a solution
against itself can only ever agree. What it catches is a schema or generator
change that silently breaks one, or leaves it returning nothing.

## License

MIT — see [LICENSE](LICENSE).
