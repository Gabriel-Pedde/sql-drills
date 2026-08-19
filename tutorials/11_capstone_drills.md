# 11 — Capstone: mixed drills

No new syntax here. Twelve problems of the kind you actually get asked, each
needing two or three ideas from the previous tutorials at once.

## How to attack a query you can't immediately see

1. **Say the grain out loud.** "One row per customer per month." Half of all SQL
   bugs are a mismatch between the grain you meant and the grain your `FROM`
   produced.
2. **Work backwards from the output columns.** Which table holds each one? What
   has to be aggregated, and at what level?
3. **Build it in CTE layers**, and run each layer on its own. `WITH a AS (…) SELECT * FROM a`
   is a debugger. Check row counts as you go: if a join multiplied them, you found
   fan-out before it reached a `sum()`.
4. **Sanity-check the numbers.** Does the total match a simpler query? Is the
   count plausible? A query that runs is not a query that's right.
5. **Then** make it fast, and only if it's slow.

## The trap checklist

Before you call a query finished, run down this list — every item is a bug you've
now met at least once:

- [ ] `NULL` — does any column here allow it? `<>` and `NOT IN` will drop those rows.
- [ ] `NOT IN` on a nullable subquery → use `NOT EXISTS`.
- [ ] `LEFT JOIN` with the outer table's column in `WHERE` → you made it an inner join.
- [ ] Joined one-to-many, then aggregated → fan-out; `count(DISTINCT …)` or aggregate first.
- [ ] Integer division: `100 * a / b` where both are ints → write `100.0 *`.
- [ ] `sum()` over no rows is NULL, `count()` is 0.
- [ ] `WHERE` vs `HAVING`: row condition or group condition?
- [ ] Window `ORDER BY` with ties and the default `RANGE` frame → say `ROWS`.
- [ ] `ORDER BY` absent → the order you saw in testing is not guaranteed.
- [ ] Date ranges half-open (`>= start AND < next_start`), and sargable.

---

## Drills — `exercises/11.sql`, then `python3 check.py 11`

11.1 **Cohort activation.** Per signup year: how many customers, and how many placed their first order within 365 days of signing up. (The 2021 cohort scores 0 — the order history only starts in 2023. Noticing that the data, not the query, explains a weird number is part of the job.)

11.2 **Year over year.** For each month number 01–12: 2023 revenue, 2024 revenue, and the growth percentage, all rounded to 2 (growth to 1).

11.3 **Churn.** Customers whose most recent order is more than 180 days before the newest order in the database: name, last order date, days since — longest silence first.

11.4 **Best seller per category.** The product with the most units sold in each category: category name, product name, units — by category name. (Assume no ties.)

11.5 **Fulfilment speed.** For employees who shipped at least 5 orders: name and average days from order to ship, rounded to 2 — fastest first.

11.6 **Underpaid orders.** Orders where the payments recorded total less than the order's revenue by more than one cent, including orders with no payment at all: `order_id`, revenue, paid, shortfall — biggest shortfall first, top 10.

11.7 **Repeat rate.** One row: how many customers ordered at all, how many ordered more than once, and the repeat rate as a percentage rounded to 1. (Spoiler, so you don't doubt a correct query: in this data every buyer came back, so the answer really is 100.0.)

11.8 **Basket affinity.** The five product pairs most often bought in the same order: `product_a`, `product_b` (names), times bought together — most frequent first, then by product ids.

11.9 **Crossing the line.** For each customer, the first order at which their cumulative revenue passed 1000: name, `order_id`, `order_date`, cumulative revenue rounded to 2 — by date.

11.10 **Org rollup.** For each employee, the revenue of orders handled by them *or by anyone below them* in the org chart: name, revenue rounded to 2 (0 if none) — highest first, name as tie-break.

11.11 **Median.** The median order revenue, rounded to 2. (There is no `median()` in SQLite: rank the rows and take the middle one — or the average of the middle two when the count is even.)

11.12 **Customer lifetime.** Per customer with at least 2 orders: name, first order, last order, days between, number of orders, and average days between consecutive orders rounded to 1 — longest lifetime first.
