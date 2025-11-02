-- Laboratory Work 6: SQL JOINs
-- This file contains all SQL queries and answers for Lab 6 (in English)
-- Automatically generated
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
-- Create tables
-- === Part 1: Database Setup ===
-- Step 1.1: Create Sample Tables
CREATE TABLE employees (
  emp_id INT PRIMARY KEY,
  emp_name VARCHAR(50),
  dept_id INT,
  salary DECIMAL(10,2)
);

CREATE TABLE departments (
  dept_id INT PRIMARY KEY,
  dept_name VARCHAR(50),
  location VARCHAR(50)
);

CREATE TABLE projects (
  project_id INT PRIMARY KEY,
  project_name VARCHAR(50),
  dept_id INT,
  budget DECIMAL(10,2)
);

-- Step 1.2: Insert Sample Data
INSERT INTO employees (emp_id, emp_name, dept_id, salary) VALUES
(1, 'John Smith', 101, 50000),
(2, 'Jane Doe', 102, 60000),
(3, 'Mike Johnson', 101, 55000),
(4, 'Sarah Williams', 103, 65000),
(5, 'Tom Brown', NULL, 45000);

INSERT INTO departments (dept_id, dept_name, location) VALUES
(101, 'IT', 'Building A'),
(102, 'HR', 'Building B'),
(103, 'Finance', 'Building C'),
(104, 'Marketing', 'Building D');

INSERT INTO projects (project_id, project_name, dept_id, budget) VALUES
(1, 'Website Redesign', 101, 100000),
(2, 'Employee Training', 102, 50000),
(3, 'Budget Analysis', 103, 75000),
(4, 'Cloud Migration', 101, 150000),
(5, 'AI Research', NULL, 200000);

-- === Part 2: CROSS JOIN ===
SELECT e.emp_name, d.dept_name
FROM employees e CROSS JOIN departments d;
-- Number of rows = N × M (5 × 4 = 20)

SELECT e.emp_name, p.project_name
FROM employees e CROSS JOIN projects p;
-- 5 × 5 = 25 rows

-- === Part 3: INNER JOIN ===
SELECT e.emp_name, d.dept_name, d.location
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id;
-- Tom Brown is excluded because dept_id is NULL.

SELECT emp_name, dept_name, location
FROM employees
INNER JOIN departments USING (dept_id);
-- USING removes duplicate column dept_id.

SELECT emp_name, dept_name, location
FROM employees
NATURAL INNER JOIN departments;

SELECT e.emp_name, d.dept_name, p.project_name
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
INNER JOIN projects p ON d.dept_id = p.dept_id;
-- Excludes NULL dept_id rows.

-- === Part 4: LEFT JOIN ===
SELECT e.emp_name, e.dept_id AS emp_dept, d.dept_id AS dept_dept, d.dept_name
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id;
-- Tom Brown appears with NULL dept fields.

SELECT emp_name, dept_id, dept_name
FROM employees
LEFT JOIN departments USING (dept_id);

SELECT e.emp_name, e.dept_id
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE d.dept_id IS NULL;
-- Returns Tom Brown.

SELECT d.dept_name, COUNT(e.emp_id) AS employee_count
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
ORDER BY employee_count DESC;

-- === Part 5: RIGHT JOIN ===
SELECT e.emp_name, d.dept_name
FROM employees e
RIGHT JOIN departments d ON e.dept_id = d.dept_id;

SELECT e.emp_name, d.dept_name
FROM departments d
LEFT JOIN employees e ON e.dept_id = d.dept_id;

SELECT d.dept_name, d.location
FROM departments d
LEFT JOIN employees e ON e.dept_id = d.dept_id
WHERE e.emp_id IS NULL;
-- Returns departments without employees (Marketing).

-- === Part 6: FULL JOIN ===
SELECT e.emp_name, e.dept_id AS emp_dept, d.dept_id AS dept_dept, d.dept_name
FROM employees e
FULL JOIN departments d ON e.dept_id = d.dept_id;
-- NULL on left = departments without employees, NULL on right = employees without departments.

SELECT d.dept_name, p.project_name, p.budget
FROM departments d
FULL JOIN projects p ON d.dept_id = p.dept_id;

SELECT
  CASE
    WHEN e.emp_id IS NULL THEN 'Department without employees'
    WHEN d.dept_id IS NULL THEN 'Employee without department'
    ELSE 'Matched'
  END AS record_status,
  e.emp_name,
  d.dept_name
FROM employees e
FULL JOIN departments d ON e.dept_id = d.dept_id
WHERE e.emp_id IS NULL OR d.dept_id IS NULL;

-- === Part 7: ON vs WHERE ===
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id AND d.location = 'Building A';

SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE d.location = 'Building A';
-- In Query1, all employees appear; in Query2, only those in Building A.

-- === Part 8: Complex JOINs ===
SELECT d.dept_name, e.emp_name, e.salary, p.project_name, p.budget
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
LEFT JOIN projects p ON d.dept_id = p.dept_id
ORDER BY d.dept_name, e.emp_name;

ALTER TABLE employees ADD COLUMN manager_id INT;

UPDATE employees SET manager_id = 3 WHERE emp_id IN (1,2,4,5);
UPDATE employees SET manager_id = NULL WHERE emp_id = 3;

SELECT e.emp_name AS employee, m.emp_name AS manager
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.emp_id;

SELECT d.dept_name, AVG(e.salary) AS avg_salary
FROM departments d
INNER JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
HAVING AVG(e.salary) > 50000;

-- === Lab Questions ===
-- 1) Difference between INNER and LEFT JOIN: INNER returns only matching rows, LEFT returns all from the left.
-- 2) Use CROSS JOIN to generate combinations (e.g., employee × project schedules).
-- 3) ON vs WHERE matters for outer joins because WHERE filters after joining.
-- 4) SELECT COUNT(*) FROM table1 CROSS JOIN table2 → N×M rows.
-- 5) NATURAL JOIN uses all columns with same names.
-- 6) Risks: NATURAL JOIN may break if schema changes.
-- 7) LEFT JOIN equivalent to RIGHT JOIN by swapping table order.
-- 8) Use FULL JOIN when you need all records from both tables.

-- === Additional Challenges ===
SELECT d.dept_id, d.dept_name, e.emp_id, e.emp_name
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
UNION
SELECT d.dept_id, d.dept_name, e.emp_id, e.emp_name
FROM departments d
RIGHT JOIN employees e ON d.dept_id = e.dept_id;

SELECT DISTINCT e.emp_name, d.dept_name
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
JOIN (
  SELECT dept_id FROM projects WHERE dept_id IS NOT NULL GROUP BY dept_id HAVING COUNT(*) > 1
) p2 ON d.dept_id = p2.dept_id;

SELECT e.emp_name AS employee, m.emp_name AS manager, mm.emp_name AS manager_of_manager
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.emp_id
LEFT JOIN employees mm ON m.manager_id = mm.emp_id;

SELECT a.emp_name AS emp1, b.emp_name AS emp2, a.dept_id
FROM employees a
JOIN employees b ON a.dept_id = b.dept_id AND a.emp_id < b.emp_id;

-- End of File
