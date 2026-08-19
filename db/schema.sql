-- =====================================================================
--  SQL Practice Database: "Northwind-lite" online shop
--  Dialect: SQLite 3.46
-- =====================================================================
PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS suppliers;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    customer_id  INTEGER PRIMARY KEY,
    name         TEXT    NOT NULL,
    email        TEXT    UNIQUE,
    country      TEXT,               -- deliberately nullable: NULL practice
    city         TEXT,
    segment      TEXT    NOT NULL CHECK (segment IN ('retail','business','vip')),
    signup_date  TEXT    NOT NULL    -- ISO 'YYYY-MM-DD'
);

CREATE TABLE employees (
    employee_id  INTEGER PRIMARY KEY,
    name         TEXT    NOT NULL,
    title        TEXT    NOT NULL,
    department   TEXT    NOT NULL,
    manager_id   INTEGER REFERENCES employees(employee_id),  -- NULL for the CEO
    hire_date    TEXT    NOT NULL,
    salary       NUMERIC NOT NULL CHECK (salary > 0)
);

CREATE TABLE categories (
    category_id  INTEGER PRIMARY KEY,
    name         TEXT    NOT NULL UNIQUE
);

CREATE TABLE suppliers (
    supplier_id  INTEGER PRIMARY KEY,
    name         TEXT    NOT NULL,
    country      TEXT    NOT NULL
);

CREATE TABLE products (
    product_id   INTEGER PRIMARY KEY,
    name         TEXT    NOT NULL,
    category_id  INTEGER NOT NULL REFERENCES categories(category_id),
    supplier_id  INTEGER          REFERENCES suppliers(supplier_id),  -- some in-house products: NULL
    unit_price   NUMERIC NOT NULL CHECK (unit_price >= 0),
    units_in_stock INTEGER NOT NULL DEFAULT 0,
    discontinued INTEGER NOT NULL DEFAULT 0 CHECK (discontinued IN (0,1))
);

CREATE TABLE orders (
    order_id     INTEGER PRIMARY KEY,
    customer_id  INTEGER NOT NULL REFERENCES customers(customer_id),
    employee_id  INTEGER          REFERENCES employees(employee_id),  -- web orders have no rep
    order_date   TEXT    NOT NULL,
    ship_date    TEXT,             -- NULL while unshipped
    status       TEXT    NOT NULL CHECK (status IN ('pending','shipped','delivered','cancelled'))
);

CREATE TABLE order_items (
    order_id     INTEGER NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    line_no      INTEGER NOT NULL,
    product_id   INTEGER NOT NULL REFERENCES products(product_id),
    quantity     INTEGER NOT NULL CHECK (quantity > 0),
    unit_price   NUMERIC NOT NULL,          -- price *at time of sale*
    discount     NUMERIC NOT NULL DEFAULT 0 CHECK (discount BETWEEN 0 AND 0.5),
    PRIMARY KEY (order_id, line_no)
);

CREATE TABLE payments (
    payment_id   INTEGER PRIMARY KEY,
    order_id     INTEGER NOT NULL REFERENCES orders(order_id),
    amount       NUMERIC NOT NULL,
    paid_at      TEXT    NOT NULL,
    method       TEXT    NOT NULL CHECK (method IN ('card','transfer','paypal'))
);
