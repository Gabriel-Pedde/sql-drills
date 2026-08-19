-- @ex 9.1
INSERT INTO customers (customer_id, name, email, country, city, segment, signup_date)
VALUES (100, 'New Client', 'new@example.com', 'Spain', 'Madrid', 'retail', '2025-01-15');

-- @ex 9.2
CREATE TABLE vip_customers (
    customer_id INTEGER PRIMARY KEY,
    name        TEXT NOT NULL
);
INSERT INTO vip_customers (customer_id, name)
SELECT customer_id, name FROM customers WHERE segment = 'vip';

-- @ex 9.3
UPDATE employees SET salary = salary * 1.10 WHERE title = 'Sales Rep';

-- @ex 9.4
UPDATE products SET units_in_stock = 0 WHERE discontinued = 1;

-- @ex 9.5
ALTER TABLE orders ADD COLUMN total_amount NUMERIC;
UPDATE orders
SET    total_amount = COALESCE((SELECT sum(i.quantity * i.unit_price * (1 - i.discount))
                                FROM   order_items i
                                WHERE  i.order_id = orders.order_id), 0);

-- @ex 9.6
DELETE FROM orders
WHERE  status = 'cancelled'
  AND  NOT EXISTS (SELECT 1 FROM payments p WHERE p.order_id = orders.order_id);

-- @ex 9.7
CREATE TABLE stock_counts (
    product_id INTEGER PRIMARY KEY,
    counted    INTEGER NOT NULL,
    counted_on TEXT    NOT NULL
);
INSERT INTO stock_counts (product_id, counted, counted_on) VALUES (1, 100, '2025-01-01');
INSERT INTO stock_counts (product_id, counted, counted_on)
VALUES (1, 118, '2025-01-15'), (2, 42, '2025-01-15')
ON CONFLICT (product_id) DO UPDATE
    SET counted    = excluded.counted,
        counted_on = excluded.counted_on;

-- @ex 9.8
BEGIN;
UPDATE products SET unit_price = unit_price * 2;
ROLLBACK;

-- @ex 9.9
BEGIN;
INSERT INTO categories (category_id, name) VALUES (8, 'Toys');
SAVEPOINT sp1;
INSERT INTO categories (category_id, name) VALUES (9, 'Oops');
ROLLBACK TO sp1;
COMMIT;

-- @ex 9.10
UPDATE products
SET    units_in_stock = units_in_stock - 5
WHERE  product_id = 1 AND units_in_stock >= 5;
