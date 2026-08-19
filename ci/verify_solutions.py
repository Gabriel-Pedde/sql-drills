#!/usr/bin/env python3
"""Smoke-test the exercise set against a freshly built database.

    python3 ci/verify_solutions.py

For every exercise it checks that a reference solution exists, executes cleanly
against a fresh copy of shop.db, and comes back with at least one row. Then it
runs the grader end-to-end with the solutions filled in, which exercises
check.py itself.

What this does NOT check is whether a solution answers the question its prose
asks — grading a solution against itself can only ever agree. The point is to
catch a change to db/build.py or the schema that silently breaks a solution, or
leaves one returning nothing.

Exits non-zero on the first problem found.
"""
import importlib.util
import os
import shutil
import sqlite3
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def load_check(root):
    """Borrow check.py's parser and executor so this can't drift from the grader."""
    spec = importlib.util.spec_from_file_location("check", os.path.join(root, "check.py"))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def tutorials(root):
    for name in sorted(os.listdir(os.path.join(root, "exercises"))):
        if name.endswith(".sql"):
            yield name


def check_solutions(chk, root):
    """Every exercise has a solution that runs and returns rows."""
    total = 0
    for name in tutorials(root):
        ex = chk.parse(os.path.join(root, "exercises", name))
        sol = chk.parse(os.path.join(root, "solutions", name))
        for eid, blk in ex.items():
            total += 1
            if eid not in sol:
                sys.exit(f"{name}: no reference solution for {eid}")
            try:
                rows = chk.execute(chk.strip_comments(sol[eid]["sql"]), blk["verify"])
            except sqlite3.Error as e:
                sys.exit(f"{name}: solution {eid} failed to run: {e}")
            if not rows:
                sys.exit(f"{name}: solution {eid} returned no rows")
    print(f"{total} solutions run clean and return rows")
    return total


def check_grader(chk, root, total):
    """Fill the solutions into the exercise slots and run the grader over them."""
    tmp = tempfile.mkdtemp(prefix="sql-drills-")
    try:
        for item in ("check.py", "db", "exercises", "solutions"):
            src, dst = os.path.join(root, item), os.path.join(tmp, item)
            shutil.copytree(src, dst) if os.path.isdir(src) else shutil.copy(src, dst)

        for name in tutorials(tmp):
            ex = chk.parse(os.path.join(tmp, "exercises", name))
            sol = chk.parse(os.path.join(tmp, "solutions", name))
            out = []
            for eid, blk in ex.items():
                out.append(f"-- @ex {eid} {blk['flags']}".rstrip())
                out.append(sol[eid]["sql"].strip())
                if blk["verify"].strip():
                    out.append("-- @verify")
                    out.append(blk["verify"].strip())
                out.append("")
            open(os.path.join(tmp, "exercises", name), "w").write("\n".join(out))

        subprocess.run([sys.executable, os.path.join(tmp, "db", "build.py")],
                       check=True, stdout=subprocess.DEVNULL)
        r = subprocess.run([sys.executable, os.path.join(tmp, "check.py")],
                           capture_output=True, text=True)
        if r.returncode != 0 or f"passed {total} " not in r.stdout:
            print(r.stdout[-2000:] or r.stderr)
            sys.exit("grader did not pass every exercise")
        print(f"grader passes all {total}")
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


def main():
    chk = load_check(ROOT)
    if not os.path.exists(os.path.join(ROOT, "shop.db")):
        sys.exit("shop.db missing — run:  python3 db/build.py")
    total = check_solutions(chk, ROOT)
    check_grader(chk, ROOT, total)


if __name__ == "__main__":
    main()
