CREATE DATABASE logistics_system;
USE logistics_system;

CREATE TABLE customers (
  customer_id   BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name          VARCHAR(255) NOT NULL,
  email         VARCHAR(255) UNIQUE,
  phone         VARCHAR(20),
  address       VARCHAR(255),
  country       VARCHAR(100),
  created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE warehouses (
  warehouse_id  BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name          VARCHAR(255) NOT NULL,
  city          VARCHAR(100),
  state         VARCHAR(100),
  country       VARCHAR(100),
  -- store coordinates as POINT (longitude, latitude)
  location      POINT NOT NULL SRID 4326,
  created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  SPATIAL INDEX sp_idx_location (location)
);
INSERT INTO warehouses (name, city, state, country, location)
VALUES
('Mumbai Central Hub', 'Mumbai', 'Maharashtra', 'India', ST_SRID(POINT(72.8777, 19.0760), 4326)),
('Delhi North Depot', 'Delhi', 'Delhi', 'India', ST_SRID(POINT(77.1025, 28.7041), 4326)),
('Bangalore South Center', 'Bangalore', 'Karnataka', 'India', ST_SRID(POINT(77.5946, 12.9716), 4326));

SELECT
  warehouse_id,
  name,
  city,
  ST_X(location) AS longitude,
  ST_Y(location) AS latitude
FROM warehouses;


SELECT
  ST_Distance_Sphere(
    (SELECT location FROM warehouses WHERE name = 'Mumbai Central Hub'),
    (SELECT location FROM warehouses WHERE name = 'Delhi North Depot')
  ) AS distance_meters;
  
-- STEP 1️⃣: Create a table to store distances between warehouses
CREATE TABLE warehouse_distances (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  from_warehouse_id BIGINT UNSIGNED NOT NULL,
  to_warehouse_id   BIGINT UNSIGNED NOT NULL,
  distance_meters   DOUBLE NOT NULL,
  created_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (from_warehouse_id) REFERENCES warehouses(warehouse_id),
  FOREIGN KEY (to_warehouse_id) REFERENCES warehouses(warehouse_id)
);

-- STEP 2️ Populate existing distances for all warehouse pairs
INSERT INTO warehouse_distances (from_warehouse_id, to_warehouse_id, distance_meters)
SELECT 
  w1.warehouse_id,
  w2.warehouse_id,
  ST_Distance_Sphere(w1.location, w2.location)
FROM warehouses w1
JOIN warehouses w2
  ON w1.warehouse_id < w2.warehouse_id;

-- STEP 3️⃣: Create a trigger so future inserts auto-update the distance table
DELIMITER //

CREATE TRIGGER trg_after_warehouse_insert
AFTER INSERT ON warehouses
FOR EACH ROW
BEGIN
  INSERT INTO warehouse_distances (from_warehouse_id, to_warehouse_id, distance_meters)
  SELECT 
    w.warehouse_id,
    NEW.warehouse_id,
    ST_Distance_Sphere(w.location, NEW.location)
  FROM warehouses w
  WHERE w.warehouse_id <> NEW.warehouse_id;
END //

DELIMITER ;

-- STEP 4️⃣: (Optional) Test the trigger with a new warehouse
INSERT INTO warehouses (name, city, state, country, location)
VALUES ('Chennai Coastal Hub', 'Chennai', 'Tamil Nadu', 'India', ST_SRID(POINT(80.2707, 13.0827), 4326));

-- STEP 5️⃣: View all distances (in km) in a readable format
SELECT 
  w1.name AS from_warehouse,
  w2.name AS to_warehouse,
  ROUND(d.distance_meters / 1000, 2) AS distance_km,
  d.created_at
FROM warehouse_distances d
JOIN warehouses w1 ON d.from_warehouse_id = w1.warehouse_id
JOIN warehouses w2 ON d.to_warehouse_id = w2.warehouse_id
ORDER BY distance_km;

-- Check all tables
SHOW TABLES;

-- Verify structure of each
DESCRIBE customers;
DESCRIBE warehouses;
DESCRIBE warehouse_distances;

-- 1️⃣ List all warehouses with coordinates
SELECT 
  warehouse_id, name, city, state, 
  ST_X(location) AS longitude, 
  ST_Y(location) AS latitude
FROM warehouses;

-- 2️⃣ See all warehouse-to-warehouse distances (sorted)
SELECT 
  w1.name AS from_warehouse,
  w2.name AS to_warehouse,
  ROUND(d.distance_meters / 1000, 2) AS distance_km
FROM warehouse_distances d
JOIN warehouses w1 ON d.from_warehouse_id = w1.warehouse_id
JOIN warehouses w2 ON d.to_warehouse_id = w2.warehouse_id
ORDER BY distance_km;

-- 3️⃣ Find the farthest two warehouses
SELECT 
  w1.name AS from_warehouse,
  w2.name AS to_warehouse,
  ROUND(d.distance_meters / 1000, 2) AS distance_km
FROM warehouse_distances d
JOIN warehouses w1 ON d.from_warehouse_id = w1.warehouse_id
JOIN warehouses w2 ON d.to_warehouse_id = w2.warehouse_id
ORDER BY d.distance_meters DESC
LIMIT 1;
-- 4️⃣ Find the nearest two warehouses
SELECT 
  w1.name AS from_warehouse,
  w2.name AS to_warehouse,
  ROUND(d.distance_meters / 1000, 2) AS distance_km
FROM warehouse_distances d
JOIN warehouses w1 ON d.from_warehouse_id = w1.warehouse_id
JOIN warehouses w2 ON d.to_warehouse_id = w2.warehouse_id
ORDER BY d.distance_meters ASC
LIMIT 1;
-- 4️⃣ Find the nearest two warehouses
SELECT 
  w1.name AS from_warehouse,
  w2.name AS to_warehouse,
  ROUND(d.distance_meters / 1000, 2) AS distance_km
FROM warehouse_distances d
JOIN warehouses w1 ON d.from_warehouse_id = w1.warehouse_id
JOIN warehouses w2 ON d.to_warehouse_id = w2.warehouse_id
ORDER BY d.distance_meters ASC
LIMIT 1;

ALTER TABLE customers ADD COLUMN location POINT SRID 4326;

INSERT INTO customers (name, email, phone, address, country, location)
VALUES
('Aarav Sharma', 'aarav@example.com', '9876543210', 'Andheri, Mumbai', 'India', ST_SRID(POINT(72.8330, 19.1197), 4326)),
('Riya Mehta', 'riya@example.com', '9123456780', 'Koramangala, Bangalore', 'India', ST_SRID(POINT(77.6229, 12.9352), 4326)),
('Karan Singh', 'karan@example.com', '9988776655', 'Connaught Place, Delhi', 'India', ST_SRID(POINT(77.2190, 28.6328), 4326));

SELECT 
  c.name AS customer_name,
  w.name AS nearest_warehouse,
  ROUND(ST_Distance_Sphere(c.location, w.location) / 1000, 2) AS distance_km
FROM customers c
JOIN warehouses w
ON ST_Distance_Sphere(c.location, w.location) = (
  SELECT MIN(ST_Distance_Sphere(c.location, w2.location))
  FROM warehouses w2
);

CREATE TABLE shipments (
  shipment_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  customer_id BIGINT UNSIGNED NOT NULL,
  warehouse_id BIGINT UNSIGNED NOT NULL,
  product_name VARCHAR(255),
  status ENUM('Pending','Shipped','Delivered') DEFAULT 'Pending',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
  FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id)
);

-- Create a shipment from the nearest warehouse to Riya
INSERT INTO shipments (customer_id, warehouse_id, product_name, status)
VALUES (
  (SELECT customer_id FROM customers WHERE name = 'Riya Mehta'),
  (SELECT w.warehouse_id FROM warehouses w 
    ORDER BY ST_Distance_Sphere(
      (SELECT location FROM customers WHERE name = 'Riya Mehta'),
      w.location
    ) ASC LIMIT 1),
  'Smartphone',
  'Pending'
);

-- Check all shipments with warehouse and customer info
SELECT 
  s.shipment_id,
  c.name AS customer_name,
  w.name AS warehouse_name,
  s.product_name,
  s.status,
  s.created_at
FROM shipments s
JOIN customers c ON s.customer_id = c.customer_id
JOIN warehouses w ON s.warehouse_id = w.warehouse_id;

CREATE TABLE financial_transactions (
  transaction_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  shipment_id BIGINT UNSIGNED,
  revenue DECIMAL(10,2),
  cost DECIMAL(10,2),
  profit DECIMAL(10,2),
  transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (shipment_id) REFERENCES shipments(shipment_id)
);

DELIMITER //

CREATE TRIGGER trg_calc_profit
BEFORE INSERT ON financial_transactions
FOR EACH ROW
BEGIN
  SET NEW.profit = NEW.revenue - NEW.cost;
END //

DELIMITER ;

INSERT INTO shipments (customer_id, warehouse_id, product_name, status)
VALUES
(1, 1, 'Laptop', 'Delivered'),
(3, 2, 'Office Chair', 'Delivered');

INSERT INTO financial_transactions (shipment_id, revenue, cost)
VALUES
(1, 1500, 800),
(1, 2000, 1200),
(2, 3000, 1800),
(3, 2500, 900);

SELECT * FROM shipments;


-- Total revenue, cost, and profit
SELECT 
  COALESCE(ROUND(SUM(revenue),2),0) AS total_revenue,
  COALESCE(ROUND(SUM(cost),2),0) AS total_cost,
  COALESCE(ROUND(SUM(profit),2),0) AS total_profit
FROM financial_transactions;


-- Monthly profit trend
SELECT 
  DATE_FORMAT(transaction_date, '%Y-%m') AS month,
  SUM(revenue) AS total_revenue,
  SUM(cost) AS total_cost,
  SUM(profit) AS total_profit
FROM financial_transactions
GROUP BY month
ORDER BY month;

-- Top 3 most profitable warehouses
SELECT 
  w.name AS warehouse_name,
  SUM(f.profit) AS total_profit
FROM financial_transactions f
JOIN shipments s ON f.shipment_id = s.shipment_id
JOIN warehouses w ON s.warehouse_id = w.warehouse_id
GROUP BY warehouse_name
ORDER BY total_profit DESC
LIMIT 3;

SELECT 
  DATE_FORMAT(transaction_date, '%Y-%m') AS month,
  SUM(revenue) AS monthly_revenue,
  SUM(cost) AS monthly_cost,
  SUM(profit) AS monthly_profit
FROM financial_transactions
GROUP BY month
ORDER BY month;

