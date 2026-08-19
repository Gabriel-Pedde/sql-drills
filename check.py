#!/usr/bin/env python3
"""Auto-grader for the exercises.

    python3 check.py            # grade everything you've attempted
    python3 check.py 4          # grade tutorial 4 only
    python3 check.py 4.3        # grade one exercise
    python3 check.py 4 -v       # ...and show the expected rows when you fail

How it works: your answer and the reference solution both run against a private
in-memory copy of shop.db, and the two result sets are compared. Column names
and column aliases are ignored; floats are compared rounded to 2 decimals.
Row order is ignored UNLESS the exercise is tagged `ordered` (those exercises
ask for a specific ORDER BY, so the order is part of the answer).
Your real shop.db is never modified by the grader.
"""
import os
import re
import sqlite3
import sys

ROOT = os.path.dirname(os.path.abspath(__file__))
DB = os.path.join(ROOT, "shop.db")
HDR = re.compile(r"^--\s*@ex\s+(\d+\.\d+)\s*(.*)$")
VERIFY = re.compile(r"^--\s*@verify\b")


def parse(path):
    """-> {id: {'flags': str, 'sql': str, 'verify': str}} in file order."""
    blocks, cur = {}, None
    if not os.path.exists(path):
        return blocks
    for line in open(path):
        m = HDR.match(line)
        if m:
            cur = {"flags": m.group(2).strip(), "sql": "", "verify": "", "_v": False}
            blocks[m.group(1)] = cur
            continue
        if cur is None:
            continue
        if VERIFY.match(line):
            cur["_v"] = True
            continue
        cur["verify" if cur["_v"] else "sql"] += line
    return blocks


def strip_comments(sql):
    return "\n".join(l for l in sql.splitlines() if not l.strip().startswith("--"))


def execute(sql, verify):
    """Run sql (possibly several statements) on a scratch DB; return rows."""
    src = sqlite3.connect(DB)
    con = sqlite3.connect(":memory:", isolation_level=None)  # autocommit: explicit BEGIN/COMMIT work
    src.backup(con)
    src.close()
    con.execute("PRAGMA foreign_keys = ON")
    cur = con.cursor()

    def run(script):
        """Run a multi-statement script; return the last statement's rows."""
        out, buf = None, ""
        for line in script.splitlines():
            buf += line + "\n"
            if sqlite3.complete_statement(buf):
                if buf.strip():
                    cur.execute(buf)
                    out = cur.fetchall() if cur.description else None
                buf = ""
        if buf.strip():
            cur.execute(buf)
            out = cur.fetchall() if cur.description else None
        return out

    rows = run(sql)
    if verify.strip():
        rows = run(verify)
    con.close()
    return rows


def norm(rows, ordered):
    if rows is None:
        return None
    def cell(v):
        if isinstance(v, float):
            return round(v + 0.0, 2)
        if isinstance(v, int):
            return round(float(v), 2)
        return v
    out = [tuple(cell(v) for v in r) for r in rows]
    return out if ordered else sorted(out, key=lambda r: [(v is None, str(v)) for v in r])


def show(rows, n=6):
    if rows is None:
        return "    (no result set)"
    body = "\n".join("    " + " | ".join("NULL" if v is None else str(v) for v in r)
                     for r in rows[:n])
    more = f"\n    ... {len(rows) - n} more row(s)" if len(rows) > n else ""
    return (body or "    (0 rows)") + more


def grade(num, want=None, verbose=False):
    ex = parse(os.path.join(ROOT, "exercises", f"{num:02d}.sql"))
    sol = parse(os.path.join(ROOT, "solutions", f"{num:02d}.sql"))
    if not ex:
        return 0, 0, 0
    npass = nfail = nskip = 0
    print(f"\n=== Tutorial {num:02d} " + "=" * 46)
    for eid, blk in ex.items():
        if want and eid != want:
            continue
        answer = strip_comments(blk["sql"]).strip()
        if not answer:
            nskip += 1
            print(f"  {eid}  .. not attempted")
            continue
        if eid not in sol:
            print(f"  {eid}  ?? no reference solution")
            continue
        ordered = "ordered" in blk["flags"]
        try:
            got = execute(answer, blk["verify"])
        except sqlite3.Error as e:
            nfail += 1
            print(f"  {eid}  XX SQL error: {e}")
            continue
        exp = execute(strip_comments(sol[eid]["sql"]), blk["verify"])
        if norm(got, ordered) == norm(exp, ordered):
            npass += 1
            print(f"  {eid}  OK")
        else:
            nfail += 1
            g, e_ = norm(got, ordered), norm(exp, ordered)
            hint = ""
            if g is not None and e_ is not None:
                if len(g) != len(e_):
                    hint = f" (you: {len(g)} rows, expected: {len(e_)})"
                elif g and e_ and len(g[0]) != len(e_[0]):
                    hint = f" (you: {len(g[0])} columns, expected: {len(e_[0])})"
                elif not ordered:
                    hint = " (same shape — check the values)"
                else:
                    hint = " (same shape — check values and ORDER BY)"
            print(f"  {eid}  XX wrong result{hint}")
            print("    -- your rows --")
            print(show(got))
            if verbose:
                print("    -- expected --")
                print(show(exp))
            else:
                print("    (re-run with -v to see the expected rows)")
    return npass, nfail, nskip


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("-")]
    verbose = "-v" in sys.argv or "--verbose" in sys.argv
    if not os.path.exists(DB):
        sys.exit("shop.db missing — run:  python3 db/build.py")
    if args and "." in args[0]:
        num, eid = args[0].split(".")
        totals = grade(int(num), f"{int(num)}.{eid}", verbose)
    elif args:
        totals = grade(int(args[0]), None, verbose)
    else:
        totals = (0, 0, 0)
        for n in range(1, 21):
            r = grade(n, None, verbose)
            totals = tuple(a + b for a, b in zip(totals, r))
    p, f, s = totals
    print(f"\npassed {p}   failed {f}   not attempted {s}")
    sys.exit(1 if f else 0)


if __name__ == "__main__":
    main()
