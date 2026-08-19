-- @ex 8.1
CREATE TABLE reviews (
    review_id   INTEGER PRIMARY KEY,
    product_id  INTEGER NOT NULL REFERENCES products(product_id),
    customer_id INTEGER NOT NULL REFERENCES customers(customer_id),
    rating      INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment     TEXT,
    created_at  TEXT    NOT NULL DEFAULT (date('now'))
);

-- @ex 8.2
CREATE TABLE reviews (
    review_id   INTEGER PRIMARY KEY,
    product_id  INTEGER NOT NULL REFERENCES products(product_id),
    customer_id INTEGER NOT NULL REFERENCES customers(customer_id),
    rating      INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
    UNIQUE (product_id, customer_id)
);

-- @ex 8.3
ALTER TABLE customers ADD COLUMN phone TEXT;

-- @ex 8.4
CREATE TABLE product_tags (
    product_id INTEGER NOT NULL REFERENCES products(product_id),
    tag        TEXT    NOT NULL,
    PRIMARY KEY (product_id, tag)
);

-- @ex 8.5
CREATE TABLE shipments (
    shipment_id INTEGER PRIMARY KEY,
    shipped_on  TEXT DEFAULT (date('now')),
    carrier     TEXT NOT NULL DEFAULT 'DHL'
);
INSERT INTO shipments (shipment_id) VALUES (1);

-- @ex 8.6
CREATE TABLE promotions (
    code      TEXT PRIMARY KEY,
    starts_on TEXT NOT NULL,
    ends_on   TEXT NOT NULL,
    CHECK (ends_on >= starts_on)
);

-- @ex 8.7
CREATE TABLE order_notes (
    note_id  INTEGER PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    note     TEXT NOT NULL
);

-- @ex 8.8
CREATE TABLE assignments (
    assignment_id INTEGER PRIMARY KEY,
    employee_id   INTEGER REFERENCES employees(employee_id) ON DELETE SET NULL,
    task          TEXT NOT NULL
);

-- @ex 8.9
SELECT count(*) AS lines_at_other_price
FROM   order_items i
JOIN   products p ON p.product_id = i.product_id
WHERE  i.unit_price <> p.unit_price;

-- @ex 8.10 ordered
CREATE VIEW order_totals AS
    SELECT   order_id, sum(quantity * unit_price * (1 - discount)) AS total
    FROM     order_items
    GROUP BY order_id;

SELECT   order_id, round(total, 2) AS total
FROM     order_totals
ORDER BY total DESC
LIMIT    5;
