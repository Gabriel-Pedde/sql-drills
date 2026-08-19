-- =====================================================================
--  Reference data (hand-written so you can eyeball it).
--  Transactional data (orders/order_items/payments) is generated
--  deterministically by db/build.py.
--  NOTE: the odd-looking rows are intentional teaching material:
--    * customers with no orders          -> LEFT JOIN / anti-join
--    * a customer with NULL country      -> three-valued logic
--    * the CEO with NULL manager_id      -> recursive CTE
--    * products never ordered            -> NOT EXISTS
--    * in-house products (NULL supplier) -> outer joins
-- =====================================================================

INSERT INTO categories (category_id, name) VALUES
 (1,'Beverages'), (2,'Snacks'), (3,'Household'), (4,'Electronics'), (5,'Stationery');

INSERT INTO suppliers (supplier_id, name, country) VALUES
 (1,'Alpine Foods','Switzerland'),
 (2,'Baltic Trading','Poland'),
 (3,'Cascade Electronics','Germany'),
 (4,'Dolomiti SRL','Italy'),
 (5,'Everest Paper','India');

INSERT INTO products (product_id, name, category_id, supplier_id, unit_price, units_in_stock, discontinued) VALUES
 ( 1,'Espresso Beans 1kg',     1, 4, 18.50, 120, 0),
 ( 2,'Green Tea 100 bags',     1, 5,  9.90,  80, 0),
 ( 3,'Sparkling Water 6x1L',   1, 1,  4.20, 300, 0),
 ( 4,'Cold Brew Concentrate',  1, 4, 12.00,   0, 1),   -- discontinued
 ( 5,'Potato Chips 200g',      2, 2,  2.80, 450, 0),
 ( 6,'Dark Chocolate 70%',     2, 1,  3.60, 210, 0),
 ( 7,'Mixed Nuts 500g',        2, 2, 11.40,  95, 0),
 ( 8,'Protein Bars 12pk',      2, NULL, 16.00, 60, 0), -- in-house
 ( 9,'Dish Soap 750ml',        3, 1,  3.10, 180, 0),
 (10,'Laundry Pods 40ct',      3, 2, 14.75,  70, 0),
 (11,'Microfiber Cloths 5pk',  3, NULL, 6.50, 140, 0), -- in-house
 (12,'Trash Bags 60L 30ct',    3, 2,  7.20, 160, 0),
 (13,'USB-C Cable 2m',         4, 3,  8.99, 240, 0),
 (14,'Bluetooth Mouse',        4, 3, 24.50,  55, 0),
 (15,'27in Monitor',           4, 3,229.00,  12, 0),
 (16,'Mechanical Keyboard',    4, 3, 89.00,  30, 0),
 (17,'Webcam 1080p',           4, 3, 45.00,   0, 1),   -- discontinued
 (18,'Notebook A5 Dotted',     5, 5,  6.80, 320, 0),
 (19,'Gel Pens 10pk',          5, 5,  4.40, 400, 0),
 (20,'Sticky Notes 12pk',      5, 5,  5.25, 260, 0),
 (21,'Desk Organizer',         5, NULL, 19.90, 25, 0), -- never ordered (in-house)
 (22,'Fountain Pen Deluxe',    5, 5, 74.00,   8, 0),   -- never ordered
 (23,'Herbal Infusion 50 bags',1, 5,  8.10,  90, 0),
 (24,'Energy Drink 4pk',       1, 2,  6.60, 130, 0);

INSERT INTO employees (employee_id, name, title, department, manager_id, hire_date, salary) VALUES
 (1,'Ada Nowak',      'CEO',              'Executive', NULL, '2014-01-15', 185000),
 (2,'Bruno Costa',    'VP Sales',         'Sales',        1, '2015-03-01', 132000),
 (3,'Carla Rossi',    'VP Operations',    'Operations',   1, '2015-06-10', 128000),
 (4,'Dmitri Ivanov',  'Sales Manager',    'Sales',        2, '2016-09-05',  96000),
 (5,'Elena Petrova',  'Sales Manager',    'Sales',        2, '2017-02-20',  94000),
 (6,'Farid Haddad',   'Sales Rep',        'Sales',        4, '2018-05-14',  61000),
 (7,'Greta Lind',     'Sales Rep',        'Sales',        4, '2019-08-01',  58000),
 (8,'Hugo Martins',   'Sales Rep',        'Sales',        5, '2020-01-13',  57000),
 (9,'Ines Vidal',     'Sales Rep',        'Sales',        5, '2021-11-02',  53000),
 (10,'Jonas Weber',   'Warehouse Lead',   'Operations',   3, '2018-04-09',  64000),
 (11,'Kaia Berg',     'Warehouse Clerk',  'Operations',  10, '2022-03-21',  41000),
 (12,'Liam O''Brien', 'Support Agent',    'Operations',  10, '2023-06-05',  39000);

INSERT INTO customers (customer_id, name, email, country, city, segment, signup_date) VALUES
 ( 1,'Marta Silva',      'marta@example.com',   'Portugal','Lisbon',    'retail',  '2021-02-11'),
 ( 2,'Orion Labs',       'ops@orionlabs.io',    'Germany', 'Berlin',    'business','2021-04-03'),
 ( 3,'Yuki Tanaka',      'yuki@example.com',    'Japan',   'Osaka',     'vip',     '2021-05-19'),
 ( 4,'Pedro Alves',      'pedro@example.com',   'Brazil',  'Recife',    'retail',  '2021-07-30'),
 ( 5,'Nord Supplies AB', 'buy@nordsupplies.se', 'Sweden',  'Malmo',     'business','2021-09-12'),
 ( 6,'Amina Diallo',     'amina@example.com',   'France',  'Lyon',      'retail',  '2021-11-25'),
 ( 7,'Ivan Horvat',      'ivan@example.com',    'Croatia', 'Split',     'retail',  '2022-01-08'),
 ( 8,'Delta Robotics',   'proc@deltarob.com',   'Germany', 'Munich',    'business','2022-02-17'),
 ( 9,'Sofia Marino',     'sofia@example.com',   'Italy',   'Bologna',   'vip',     '2022-03-29'),
 (10,'Chen Wei',         'chen@example.com',    'China',   'Chengdu',   'retail',  '2022-06-14'),
 (11,'Helena Fischer',   'helena@example.com',  'Germany', 'Hamburg',   'retail',  '2022-08-02'),
 (12,'Atlas Freight',    'ap@atlasfreight.com', NULL,      'Rotterdam', 'business','2022-09-21'),
 (13,'Noor Rahman',      'noor@example.com',    'Bangladesh','Dhaka',   'retail',  '2022-11-11'),
 (14,'Tomas Novak',      'tomas@example.com',   'Czechia', 'Brno',      'retail',  '2023-01-05'),
 (15,'Bright Studio',    'hello@brightstudio.fr','France', 'Paris',     'business','2023-02-27'),
 (16,'Lucia Ferrari',    'lucia@example.com',   'Italy',   'Turin',     'vip',     '2023-04-16'),
 (17,'Omar Zayed',       'omar@example.com',    'Egypt',   'Cairo',     'retail',  '2023-06-30'),
 (18,'Peak Outdoors',    'orders@peakout.co',   'Austria', 'Innsbruck', 'business','2023-08-19'),
 (19,'Riya Kapoor',      'riya@example.com',    'India',   'Pune',      'retail',  '2023-10-07'),
 (20,'Jan Kowalski',     'jan@example.com',     'Poland',  'Gdansk',    'retail',  '2023-12-01'),
 (21,'Zoe Fontaine',     'zoe@example.com',     'France',  'Nice',      'retail',  '2024-01-22'),
 (22,'Quiet Books Ltd',  'ap@quietbooks.uk',    NULL,      'Leeds',     'business','2024-02-14'),
 (23,'Ravi Menon',       'ravi@example.com',    'India',   'Kochi',     'vip',     '2024-03-08'),
 (24,'Ana Duarte',       'ana@example.com',     'Portugal','Porto',     'retail',  '2024-04-19'),
 (25,'Felix Braun',      'felix@example.com',   'Germany', 'Cologne',   'retail',  '2024-05-27');
