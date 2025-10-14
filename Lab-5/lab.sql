DROP DATABASE IF EXISTS advanced_lab;

CREATE DATABASE advanced_lab;

\c advanced_lab

DO
$$
DECLARE
    r RECORD;
BEGIN
    -- Перебираем все таблицы в public-схеме
    FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public') LOOP
        EXECUTE 'DROP TABLE IF EXISTS public.' || quote_ident(r.tablename) || ' CASCADE';
    END LOOP;
END;
$$;
DROP DATABASE advanced_lab;


-- ==================================================================
-- Part 1: CHECK Constraints
-- Task 1.1: Basic CHECK Constraint: employees
-- ==================================================================
DROP TABLE IF EXISTS employees CASCADE;
CREATE TABLE employees (
    employee_id INTEGER,
    first_name TEXT,
    last_name TEXT,
    age INTEGER CHECK (age BETWEEN 18 AND 65), -- ensure age in [18,65]
    salary NUMERIC CHECK (salary > 0)           -- salary must be positive
);

-- Insert valid rows (at least 2)
INSERT INTO employees (employee_id, first_name, last_name, age, salary) VALUES
(1, 'Aida', 'Bek', 30, 45000),
(2, 'Daniyar', 'Suleiman', 45, 72000);



-- ==================================================================
-- Task 1.2: Named CHECK Constraint: products_catalog
-- ==================================================================
DROP TABLE IF EXISTS products_catalog CASCADE;
CREATE TABLE products_catalog (
    product_id INTEGER,
    product_name TEXT,
    regular_price NUMERIC,
    discount_price NUMERIC,
    CONSTRAINT valid_discount CHECK (
        regular_price > 0
        AND discount_price > 0
        AND discount_price < regular_price
    )
);

-- Valid inserts
INSERT INTO products_catalog (product_id, product_name, regular_price, discount_price) VALUES
(101, 'Wireless Mouse', 25.00, 20.00),
(102, 'Keyboard', 40.00, 35.00);


-- ==================================================================
-- Task 1.3: Multiple Column CHECK: bookings
-- ==================================================================
DROP TABLE IF EXISTS bookings CASCADE;
CREATE TABLE bookings (
    booking_id INTEGER,
    check_in_date DATE,
    check_out_date DATE,
    num_guests INTEGER CHECK (num_guests BETWEEN 1 AND 10),
    CHECK (check_out_date > check_in_date) -- ensures checkout after checkin
);

-- Valid inserts
INSERT INTO bookings (booking_id, check_in_date, check_out_date, num_guests) VALUES
(201, '2025-11-01', '2025-11-05', 2),
(202, '2025-12-20', '2025-12-25', 4);



-- ==================================================================
-- Part 2: NOT NULL Constraints
-- Task 2.1: NOT NULL Implementation: customers
-- ==================================================================
DROP TABLE IF EXISTS customers CASCADE;
CREATE TABLE customers (
    customer_id INTEGER NOT NULL,
    email TEXT NOT NULL,
    phone TEXT, -- nullable
    registration_date DATE NOT NULL
);

-- Valid inserts
INSERT INTO customers (customer_id, email, phone, registration_date) VALUES
(1, 'ali@example.com', '+7-701-000-0001', '2025-01-15'),
(2, 'nursultan@example.com', NULL, '2025-02-10'); -- phone can be NULL



-- ==================================================================
-- Task 2.2: Combining Constraints: inventory
-- ==================================================================
DROP TABLE IF EXISTS inventory CASCADE;
CREATE TABLE inventory (
    item_id INTEGER NOT NULL,
    item_name TEXT NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity >= 0),
    unit_price NUMERIC NOT NULL CHECK (unit_price > 0),
    last_updated TIMESTAMP NOT NULL
);

-- Valid inserts
INSERT INTO inventory (item_id, item_name, quantity, unit_price, last_updated) VALUES
(1, 'USB Cable', 100, 5.50, '2025-09-01 10:00:00'),
(2, 'Charger', 50, 12.90, '2025-09-02 11:00:00');


-- Task 2.3: Testing NOT NULL
-- Insert records with NULLs in nullable columns (phone is nullable in customers):
INSERT INTO customers (customer_id, email, phone, registration_date) VALUES
(3, 'meri@example.com', NULL, '2025-05-05');


-- ==================================================================
-- Part 3: UNIQUE Constraints
-- Task 3.1: Single Column UNIQUE: users
-- ==================================================================
DROP TABLE IF EXISTS users CASCADE;
CREATE TABLE users (
    user_id INTEGER,
    username TEXT UNIQUE,
    email TEXT UNIQUE,
    created_at TIMESTAMP
);

-- Valid inserts
INSERT INTO users (user_id, username, email, created_at) VALUES
(1, 'ali', 'ali@domain.com', '2025-01-01 09:00:00'),
(2, 'nura', 'nura@domain.com', '2025-02-01 10:00:00');


-- ==================================================================
-- Task 3.2: Multi-Column UNIQUE: course_enrollments
-- ==================================================================
DROP TABLE IF EXISTS course_enrollments CASCADE;
CREATE TABLE course_enrollments (
    enrollment_id INTEGER,
    student_id INTEGER,
    course_code TEXT,
    semester TEXT,
    UNIQUE (student_id, course_code, semester)
);

-- Valid inserts
INSERT INTO course_enrollments (enrollment_id, student_id, course_code, semester) VALUES
(1, 1001, 'CS101', '2025-Fall'),
(2, 1002, 'CS101', '2025-Fall');



-- ==================================================================
-- Task 3.3: Named UNIQUE Constraints: modify users
-- ==================================================================
DROP TABLE IF EXISTS users_named CASCADE;
CREATE TABLE users_named (
    user_id INTEGER,
    username TEXT,
    email TEXT,
    created_at TIMESTAMP,
    CONSTRAINT unique_username UNIQUE (username),
    CONSTRAINT unique_email UNIQUE (email)
);

-- Valid inserts
INSERT INTO users_named (user_id, username, email, created_at) VALUES
(1, 'bek', 'bek@example.com', '2025-03-01 12:00:00'),
(2, 'marat', 'marat@example.com', '2025-03-02 13:00:00');



-- ==================================================================
-- Part 4: PRIMARY KEY Constraints
-- Task 4.1: Single Column Primary Key: departments
-- ==================================================================
DROP TABLE IF EXISTS departments CASCADE;
CREATE TABLE departments (
    dept_id INTEGER PRIMARY KEY,
    dept_name TEXT NOT NULL,
    location TEXT
);

-- Valid inserts
INSERT INTO departments (dept_id, dept_name, location) VALUES
(10, 'Computer Science', 'Building A'),
(20, 'Mathematics', 'Building B'),
(30, 'Physics', 'Building C');


-- ==================================================================
-- Task 4.2: Composite Primary Key: student_courses
-- ==================================================================
DROP TABLE IF EXISTS student_courses CASCADE;
CREATE TABLE student_courses (
    student_id INTEGER,
    course_id INTEGER,
    enrollment_date DATE,
    grade TEXT,
    PRIMARY KEY (student_id, course_id)
);

-- Valid inserts
INSERT INTO student_courses (student_id, course_id, enrollment_date, grade) VALUES
(1001, 501, '2025-09-01', 'A'),
(1002, 501, '2025-09-01', 'B');


-- ==================================================================
-- Part 5: FOREIGN KEY Constraints
-- Task 5.1: Basic Foreign Key: employees_dept referencing departments
-- ==================================================================
DROP TABLE IF EXISTS employees_dept CASCADE;
CREATE TABLE employees_dept (
    emp_id INTEGER PRIMARY KEY,
    emp_name TEXT NOT NULL,
    dept_id INTEGER REFERENCES departments(dept_id), -- foreign key to departments
    hire_date DATE
);

-- Valid inserts (dept_id exists)
INSERT INTO employees_dept (emp_id, emp_name, dept_id, hire_date) VALUES
(100, 'Aisha', 10, '2025-02-01'),
(101, 'Ruslan', 20, '2025-03-01');


-- ==================================================================
-- Task 5.2: Multiple Foreign Keys: library schema
-- ==================================================================
DROP TABLE IF EXISTS books CASCADE;
DROP TABLE IF EXISTS authors CASCADE;
DROP TABLE IF EXISTS publishers CASCADE;

CREATE TABLE authors (
    author_id INTEGER PRIMARY KEY,
    author_name TEXT NOT NULL,
    country TEXT
);

CREATE TABLE publishers (
    publisher_id INTEGER PRIMARY KEY,
    publisher_name TEXT NOT NULL,
    city TEXT
);

CREATE TABLE books (
    book_id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    author_id INTEGER REFERENCES authors(author_id),
    publisher_id INTEGER REFERENCES publishers(publisher_id),
    publication_year INTEGER,
    isbn TEXT UNIQUE
);

-- Sample inserts
INSERT INTO authors (author_id, author_name, country) VALUES
(1, 'Ernest Hemingway', 'USA'),
(2, 'Gabriel Garcia Marquez', 'Colombia'),
(3, 'Chinua Achebe', 'Nigeria');

INSERT INTO publishers (publisher_id, publisher_name, city) VALUES
(1, 'Penguin Books', 'London'),
(2, 'HarperCollins', 'New York'),
(3, 'Vintage', 'London');

INSERT INTO books (book_id, title, author_id, publisher_id, publication_year, isbn) VALUES
(1001, 'The Old Man and the Sea', 1, 1, 1952, 'ISBN-0001'),
(1002, 'One Hundred Years of Solitude', 2, 2, 1967, 'ISBN-0002'),
(1003, 'Things Fall Apart', 3, 3, 1958, 'ISBN-0003');


-- ==================================================================
-- Task 5.3: ON DELETE Options
-- ==================================================================
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products_fk CASCADE;
DROP TABLE IF EXISTS categories CASCADE;

CREATE TABLE categories (
    category_id INTEGER PRIMARY KEY,
    category_name TEXT NOT NULL
);

CREATE TABLE products_fk (
    product_id INTEGER PRIMARY KEY,
    product_name TEXT NOT NULL,
    category_id INTEGER REFERENCES categories(category_id) ON DELETE RESTRICT
);

CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY,
    order_date DATE NOT NULL
);

CREATE TABLE order_items (
    item_id INTEGER PRIMARY KEY,
    order_id INTEGER REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products_fk(product_id),
    quantity INTEGER CHECK (quantity > 0)
);

-- Sample data
INSERT INTO categories (category_id, category_name) VALUES
(1, 'Electronics'),
(2, 'Books');

INSERT INTO products_fk (product_id, product_name, category_id) VALUES
(1, 'Smartphone', 1),
(2, 'Laptop', 1),
(3, 'Novel', 2);

INSERT INTO orders (order_id, order_date) VALUES
(5001, '2025-10-01'),
(5002, '2025-10-02');

INSERT INTO order_items (item_id, order_id, product_id, quantity) VALUES
(9001, 5001, 1, 2),
(9002, 5001, 3, 1),
(9003, 5002, 2, 1);


-- ==================================================================
-- Part 6: Practical Application (E-commerce Database Design)
-- ==================================================================
DROP TABLE IF EXISTS order_details CASCADE;
DROP TABLE IF EXISTS orders_ecom CASCADE;
DROP TABLE IF EXISTS products_ecom CASCADE;
DROP TABLE IF EXISTS customers_ecom CASCADE;

-- customers
CREATE TABLE customers_ecom (
    customer_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    phone TEXT,
    registration_date DATE NOT NULL
);

-- products
CREATE TABLE products_ecom (
    product_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    price NUMERIC NOT NULL CHECK (price >= 0), -- price non-negative
    stock_quantity INTEGER NOT NULL CHECK (stock_quantity >= 0)
);

-- orders: order status constraint
CREATE TABLE orders_ecom (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER REFERENCES customers_ecom(customer_id) ON DELETE SET NULL,
    order_date DATE NOT NULL,
    total_amount NUMERIC NOT NULL CHECK (total_amount >= 0),
    status TEXT NOT NULL CHECK (status IN ('pending','processing','shipped','delivered','cancelled'))
);

-- order_details
CREATE TABLE order_details (
    order_detail_id INTEGER PRIMARY KEY,
    order_id INTEGER REFERENCES orders_ecom(order_id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products_ecom(product_id),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC NOT NULL CHECK (unit_price >= 0)
);

-- Sample records (at least 5 per table)
-- customers_ecom
INSERT INTO customers_ecom (customer_id, name, email, phone, registration_date) VALUES
(1, 'Ali Nur', 'ali.nur@example.com', '+7-701-111-1111', '2025-01-10'),
(2, 'Gulzhan', 'gul@example.com', '+7-701-222-2222', '2025-02-12'),
(3, 'Dina', 'dina@example.com', NULL, '2025-03-05'),
(4, 'Marlen', 'marlen@example.com', '+7-701-333-3333', '2025-04-20'),
(5, 'Ermek', 'ermek@example.com', '+7-701-444-4444', '2025-05-15');

-- products_ecom
INSERT INTO products_ecom (product_id, name, description, price, stock_quantity) VALUES
(10, 'Wireless Earbuds', 'Noise-cancelling earbuds', 59.99, 150),
(11, 'Gaming Mouse', 'Ergonomic mouse', 39.99, 200),
(12, 'Mechanical Keyboard', 'RGB keyboard', 89.99, 80),
(13, 'USB-C Cable', '1m cable', 5.99, 1000),
(14, 'Portable Charger', '10000 mAh', 29.99, 300);

-- orders_ecom
INSERT INTO orders_ecom (order_id, customer_id, order_date, total_amount, status) VALUES
(2001, 1, '2025-10-01', 99.98, 'processing'),
(2002, 2, '2025-10-02', 39.99, 'pending'),
(2003, 3, '2025-10-03', 119.98, 'shipped'),
(2004, 4, '2025-10-04', 5.99, 'delivered'),
(2005, 5, '2025-10-05', 29.99, 'cancelled');

-- order_details
INSERT INTO order_details (order_detail_id, order_id, product_id, quantity, unit_price) VALUES
(3001, 2001, 10, 1, 59.99),
(3002, 2001, 13, 2, 5.99),
(3003, 2002, 11, 1, 39.99),
(3004, 2003, 12, 1, 89.99),
(3005, 2003, 13, 1, 5.99);

