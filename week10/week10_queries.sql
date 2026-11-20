-- Queries each task --

-- Task 1 — Safe INSERT
-- Task 1: Insert Scientific Calculator
INSERT INTO products (product_name, sku, price, stock_quantity, status)
VALUES ('Scientific Calculator', 'CALC-SCI-001', 850.00, 20, 'Active');

-- Task 1: Confirm Scientific Calculator
SELECT product_id, product_name, sku, price, stock_quantity, status
FROM products
WHERE sku = 'CALC-SCI-001';

-- Task 1: Insert Compass
INSERT INTO products (product_name, sku, price, stock_quantity, status)
VALUES ('Compass', 'CMP-001', 120.00, 50, 'Active');

-- Task 1: Confirm Compass
SELECT product_id, product_name, sku, price, stock_quantity, status
FROM products
WHERE sku = 'CMP-001';

-- Task 1: Rejected insert (wrong data type for price)
INSERT INTO products (product_name, sku, price, stock_quantity, status)
VALUES ('Sticky Notes', 'SN-001', 'free', 40, 'Active');

-- Task 1: Confirm rejected insert stored nothing
SELECT COUNT(*) AS sticky_notes_rows FROM products WHERE sku = 'SN-001';


-- Task 2 — UPDATE & DELETE Without Collateral Damage
-- Task 2 (a): Preview UPDATE
SELECT product_id, product_name, price FROM products WHERE product_id = 6;

-- Task 2 (b): Execute UPDATE
UPDATE products
SET price = 875.00
WHERE product_id = 6;

-- Task 2 (c): Verify UPDATE
SELECT product_id, product_name, price FROM products WHERE product_id = 6;

-- Task 2 (a): Preview DELETE
SELECT product_id, product_name, sku FROM products WHERE product_id = 5;

-- Task 2 (a): Check the product has no sales before deleting
SELECT COUNT(*) AS eraser_sales FROM sales WHERE product_id = 5;

-- Task 2 (b): Execute DELETE
DELETE FROM products
WHERE product_id = 5;

-- Task 2 (c): Verify DELETE
SELECT product_id, product_name, sku FROM products WHERE product_id = 5;


-- Task 3 — Self Join & Cross Join
-- Task 3 (a): Self join with LEFT JOIN
SELECT e.employee_id, e.employee_name AS employee, m.employee_name AS manager
FROM employees AS e
LEFT JOIN employees AS m
ON e.manager_id = m.employee_id
ORDER BY e.employee_id;

-- Task 3 (b): Cross join of colors and sizes
SELECT c.color_name, s.size_name
FROM colors AS c
CROSS JOIN sizes AS s
ORDER BY c.color_name, s.size_name;

-- Task 3 (b): Cross join row count
SELECT COUNT(*) AS total_combinations
FROM colors AS c
CROSS JOIN sizes AS s;


-- Task 4 — Constraints & Table Evolution
-- Task 4 (a): Add contact_number column
ALTER TABLE products
ADD COLUMN contact_number VARCHAR(20);

-- Task 4 (b): Check existing data before adding constraints
SELECT COUNT(*) AS null_names FROM products WHERE product_name IS NULL;
SELECT sku, COUNT(*) AS copies FROM products GROUP BY sku HAVING COUNT(*) > 1;
SELECT COUNT(*) AS bad_prices FROM products WHERE price <= 0 OR price IS NULL;

-- Task 4 (b): Rule 1 — product_name NOT NULL
ALTER TABLE products
MODIFY product_name VARCHAR(100) NOT NULL;

-- Task 4 (b): Rule 1 — valid write
INSERT INTO products (product_name, sku, price, stock_quantity, status)
VALUES ('Stapler', 'STP-001', 95.00, 40, 'Active');

-- Task 4 (b): Rule 1 — invalid write (rejected)
INSERT INTO products (product_name, sku, price, stock_quantity, status)
VALUES (NULL, 'XXX-001', 50.00, 10, 'Active');

-- Task 4 (b): Rule 2 — sku UNIQUE
ALTER TABLE products
ADD CONSTRAINT uq_products_sku UNIQUE (sku);

-- Task 4 (b): Rule 2 — valid write
INSERT INTO products (product_name, sku, price, stock_quantity, status)
VALUES ('Highlighter', 'HL-001', 30.00, 60, 'Active');

-- Task 4 (b): Rule 2 — invalid write (rejected)
INSERT INTO products (product_name, sku, price, stock_quantity, status)
VALUES ('Notebook Copy', 'NB-001', 45.00, 10, 'Active');

-- Task 4 (b): Rule 3 — CHECK (price > 0)
ALTER TABLE products
ADD CONSTRAINT chk_products_price CHECK (price > 0);

-- Task 4 (b): Rule 3 — valid write
INSERT INTO products (product_name, sku, price, stock_quantity, status)
VALUES ('Pencil Case', 'PC-001', 85.00, 25, 'Active');

-- Task 4 (b): Rule 3 — invalid write (rejected)
INSERT INTO products (product_name, sku, price, stock_quantity, status)
VALUES ('Free Pen', 'FP-001', -5.00, 10, 'Active');

-- Task 4: DEFAULT on stock_quantity
ALTER TABLE products
MODIFY stock_quantity INT DEFAULT 0;

-- Task 4: DEFAULT test (stock_quantity omitted)
INSERT INTO products (product_name, sku, price, status)
VALUES ('Paper Clips', 'PCL-001', 20.00, 'Active');


-- Task 4: Final table contents
SELECT product_id, product_name, sku, price, stock_quantity, status, contact_number
FROM products
ORDER BY product_id;
