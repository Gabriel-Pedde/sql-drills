#!/usr/bin/env python3
"""Build shop.db from schema.sql + seed.sql, then generate transactional data.

Deterministic: same seed -> byte-identical data, so every tutorial answer is stable.
Run:  python3 db/build.py        (from the repo root, or anywhere)
"""
import os
import random
import sqlite3
from datetime import date, timedelta

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
DB = os.path.join(ROOT, "shop.db")

random.seed(7)

# Customers deliberately left with zero orders (LEFT JOIN / anti-join practice)
NO_ORDER_CUSTOMERS = {13, 22, 25}
# Products deliberately never sold (NOT EXISTS practice)
NEVER_SOLD = {21, 22}

def main():
    if os.path.exists(DB):
        os.remove(DB)
    con = sqlite3.connect(DB)
    con.executescript(open(os.path.join(HERE, "schema.sql")).read())
    con.executescript(open(os.path.join(HERE, "seed.sql")).read())

    prices = {pid: float(p) for pid, p in con.execute(
        "SELECT product_id, unit_price FROM products WHERE product_id NOT IN (21,22)")}
    pids = sorted(prices)
    customers = [c for (c,) in con.execute("SELECT customer_id FROM customers")
                 if c not in NO_ORDER_CUSTOMERS]
    signup = dict(con.execute("SELECT customer_id, signup_date FROM customers"))
    reps = [6, 7, 8, 9, 4, 5]

    start, end = date(2023, 1, 1), date(2024, 12, 20)
    span = (end - start).days

    orders, items, payments = [], [], []
    order_id, payment_id = 1000, 5000

    for _ in range(140):
        cust = random.choice(customers)
        d = start + timedelta(days=random.randint(0, span))
        if d.isoformat() < signup[cust]:            # never order before signing up
            continue
        order_id += 1
        emp = None if random.random() < 0.30 else random.choice(reps)
        age = (end - d).days
        r = random.random()
        if r < 0.06:
            status, ship = "cancelled", None
        elif age < 25:
            status, ship = "pending", None
        elif r < 0.35:
            status, ship = "shipped", d + timedelta(days=random.randint(1, 6))
        else:
            status, ship = "delivered", d + timedelta(days=random.randint(2, 9))
        orders.append((order_id, cust, emp, d.isoformat(),
                       ship.isoformat() if ship else None, status))

        # ---- lines ----
        n = random.choices([1, 2, 3, 4, 5], weights=[30, 30, 20, 13, 7])[0]
        chosen = random.sample(pids, n)
        total = 0.0
        for line_no, pid in enumerate(chosen, start=1):
            qty = random.choices([1, 2, 3, 5, 8, 12], weights=[35, 25, 15, 12, 8, 5])[0]
            drift = 1.0 + (d.year - 2023) * 0.03          # mild price inflation over time
            price = round(prices[pid] * drift, 2)
            disc = random.choices([0.0, 0.05, 0.10, 0.15, 0.20],
                                  weights=[65, 10, 12, 8, 5])[0]
            items.append((order_id, line_no, pid, qty, price, disc))
            total += qty * price * (1 - disc)

        # ---- payments: some orders unpaid, a few paid in two instalments ----
        if status in ("shipped", "delivered") and random.random() < 0.85:
            paid_on = (ship or d) + timedelta(days=random.randint(0, 10))
            method = random.choices(["card", "transfer", "paypal"], weights=[55, 25, 20])[0]
            if random.random() < 0.12:
                payment_id += 1
                payments.append((payment_id, order_id, round(total * 0.5, 2),
                                 paid_on.isoformat(), method))
                payment_id += 1
                payments.append((payment_id, order_id, round(total - round(total * 0.5, 2), 2),
                                 (paid_on + timedelta(days=14)).isoformat(), method))
            else:
                payment_id += 1
                payments.append((payment_id, order_id, round(total, 2),
                                 paid_on.isoformat(), method))

    con.executemany("INSERT INTO orders VALUES (?,?,?,?,?,?)", orders)
    con.executemany("INSERT INTO order_items VALUES (?,?,?,?,?,?)", items)
    con.executemany("INSERT INTO payments VALUES (?,?,?,?,?)", payments)
    con.commit()

    print(f"built {DB}")
    for t in ("customers", "employees", "categories", "suppliers", "products",
              "orders", "order_items", "payments"):
        (n,) = con.execute(f"SELECT count(*) FROM {t}").fetchone()
        print(f"  {t:<12} {n:>5} rows")
    con.close()

if __name__ == "__main__":
    main()
