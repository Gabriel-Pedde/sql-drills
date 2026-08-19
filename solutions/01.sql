-- @ex 1.1 ordered
SELECT name_id, city, segment -- Added mistake to check git CI
FROM   customers
WHERE  country = 'Germany'
ORDER  BY name;

-- @ex 1.2 ordered
SELECT customer_id, name, signup_date
FROM   customers
WHERE  signup_date >= '2023-01-01' AND signup_date < '2024-01-01'
ORDER  BY signup_date;

-- @ex 1.3 ordered
SELECT name, unit_price
FROM   products
WHERE  discontinued = 0
  AND  unit_price BETWEEN 5 AND 20
ORDER  BY unit_price DESC;

-- @ex 1.4
SELECT customer_id, name, city
FROM   customers
WHERE  country IS NULL;

-- @ex 1.5 ordered
SELECT DISTINCT country
FROM   customers
WHERE  country IS NOT NULL
ORDER  BY country;

-- @ex 1.6 ordered
SELECT name,
       unit_price,
       CASE WHEN unit_price < 5  THEN 'budget'
            WHEN unit_price < 20 THEN 'mid'
            ELSE                      'premium'
       END AS price_band
FROM   products
ORDER  BY unit_price;

-- @ex 1.7 ordered
SELECT customer_id, name, COALESCE(country, 'Unknown') AS country
FROM   customers
ORDER  BY customer_id;

-- @ex 1.8 ordered
SELECT name, unit_price
FROM   products
WHERE  discontinued = 0
ORDER  BY unit_price DESC
LIMIT  3;

-- @ex 1.9 ordered
SELECT name, email
FROM   customers
WHERE  email NOT LIKE '%@example.com'
ORDER  BY name;
