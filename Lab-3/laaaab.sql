-- PART A: Database and Table Setup
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

-- 1. CREATE DATABASE
CREATE DATABASE advanced_lab;

-- Table: departments
CREATE TABLE departments (
    dept_id    int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    dept_name  varchar(100) NOT NULL UNIQUE,
    budget     integer NOT NULL CHECK (budget >= 0),
    manager_id integer  -- can store an emp_id if needed; no FK to avoid circular dependency
);

-- Table: employees
CREATE TABLE employees (
    emp_id     int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name varchar(50) NOT NULL,
    last_name  varchar(50) NOT NULL,
    -- department stored as name (string) per spec; can be NULL or DEFAULT 'Unassigned'
    department varchar(100) DEFAULT 'Unassigned',
    salary     integer DEFAULT 30000 CHECK (salary >= 0),
    hire_date  date NOT NULL,
    status     varchar(20) DEFAULT 'Active'
);

-- Table: projects
CREATE TABLE projects (
    project_id   int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    project_name varchar(150) NOT NULL,
    -- store dept_id to link to departments
    dept_id      int REFERENCES departments(dept_id) ON DELETE SET NULL,
    start_date   date NOT NULL,
    end_date     date,
    budget       integer NOT NULL CHECK (budget >= 0)
);


-- Insert some departments (will be used throughout)
INSERT INTO departments (dept_name, budget, manager_id)
VALUES
    ('IT', 150000, NULL),
    ('Sales', 120000, NULL),
    ('HR', 60000, NULL),
    ('R&D', 250000, NULL);

-- Insert sample employees (explicitly include hire_date)
INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES
    ('Alice', 'Ivanova', 'IT',     70000, '2018-06-15', 'Active'),
    ('Bob',   'Petrov',  'Sales',  48000, '2021-02-20', 'Active'),
    ('Clara', 'Sidorov', 'HR',     52000, '2019-09-01', 'Active'),
    ('Dan',   'Kuznets', NULL,     35000, '2024-03-10', 'Active'), -- department NULL
    ('Evan',  'Moroz',   'IT',     82000, '2015-11-05', 'Active'),
    ('Fiona', 'Orlova',  'Sales',  42000, '2023-06-30', 'Terminated'),
    ('George','Zaitsev', 'R&D',   110000, '2016-12-12', 'Active'),
    ('Helen', 'Novo',    'IT',     60000, '2010-01-02', 'Inactive');

-- Insert sample projects
INSERT INTO projects (project_name, dept_id, start_date, end_date, budget)
VALUES
    ('Platform Upgrade', (SELECT dept_id FROM departments WHERE dept_name='IT'), '2023-01-01', '2023-12-31', 40000),
    ('Sales Push',       (SELECT dept_id FROM departments WHERE dept_name='Sales'), '2022-07-01', '2023-03-31', 30000),
    ('NextGen R&D',      (SELECT dept_id FROM departments WHERE dept_name='R&D'), '2024-01-01', NULL, 120000),
    ('HR Onboarding',    (SELECT dept_id FROM departments WHERE dept_name='HR'), '2021-03-01', '2022-02-28', 15000);

-- PART B: Advanced INSERT Operations

-- 2. INSERT with column specification (only certain columns)
INSERT INTO employees (first_name, last_name, department, hire_date)
VALUES ('Ivan', 'Semenov', 'R&D', CURRENT_DATE);  -- salary and status use defaults

-- 3. INSERT with DEFAULT values
INSERT INTO employees (first_name, last_name, department, hire_date, salary, status)
VALUES ('Julia', 'Kovalev', 'HR', CURRENT_DATE, DEFAULT, DEFAULT);

-- 4. INSERT multiple rows in single statement (3 departments)
INSERT INTO departments (dept_name, budget, manager_id)
VALUES
    ('Legal',  50000, NULL),
    ('Support', 40000, NULL),
    ('QA',     90000, NULL);

-- 5. INSERT with expressions
INSERT INTO employees (first_name, last_name, department, hire_date, salary)
VALUES ('Ken', 'Sokolov', 'IT', CURRENT_DATE, (50000 * 1.1)::integer);

-- 6. INSERT from SELECT (subquery) -> create temporary table and fill with IT employees
CREATE TEMP TABLE temp_employees AS
SELECT * FROM employees WHERE department = 'IT';


-- PART C: Complex UPDATE Operations

-- 7. UPDATE with arithmetic expressions
UPDATE employees
SET salary = (salary * 1.10)::integer
WHERE salary IS NOT NULL;

-- 8. UPDATE with WHERE clause and multiple conditions
UPDATE employees
SET status = 'Senior'
WHERE salary > 60000
  AND hire_date < DATE '2020-01-01';

-- 9. UPDATE using CASE expression

UPDATE employees
SET department = CASE
    WHEN salary > 80000 THEN 'Management'
    WHEN salary BETWEEN 50000 AND 80000 THEN 'Senior'
    ELSE 'Junior'
END
WHERE TRUE;


-- 10. UPDATE with DEFAULT
UPDATE employees
SET department = DEFAULT
WHERE status = 'Inactive';

-- 11. UPDATE with subquery
UPDATE departments d
SET budget = GREATEST(0, ( -- ensure non-negative
        (SELECT CEILING(AVG(e.salary)::numeric) FROM employees e WHERE e.department = d.dept_name) * 1.20
    )::integer)
WHERE EXISTS (SELECT 1 FROM employees e WHERE e.department = d.dept_name);

-- 12. UPDATE multiple columns
UPDATE employees
SET salary = (salary * 1.15)::integer,
    status = 'Promoted'
WHERE department = 'Sales';

-- PART D: Advanced DELETE Operations

-- 13. DELETE with simple WHERE condition
DELETE FROM employees
WHERE status = 'Terminated';

-- 14. DELETE with complex WHERE clause
DELETE FROM employees
WHERE salary < 40000
  AND hire_date > DATE '2023-01-01'
  AND department IS NULL;

-- 15. DELETE with subquery
DELETE FROM departments
WHERE dept_name NOT IN (
    SELECT DISTINCT department
    FROM employees
    WHERE department IS NOT NULL
);

-- 16. DELETE with RETURNING clause
DELETE FROM projects
WHERE end_date < DATE '2023-01-01'
RETURNING *;

-- PART E: Operations with NULL Values

-- 17. INSERT with NULL values
INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES ('Ivanov', 'Nullov', NULL, NULL, CURRENT_DATE, 'Active');

-- 18. UPDATE NULL handling
UPDATE employees
SET department = 'Unassigned'
WHERE department IS NULL;

-- 19. DELETE with NULL conditions
DELETE FROM employees
WHERE salary IS NULL OR department IS NULL;

-- PART F: RETURNING Clause Operations

-- 20. INSERT with RETURNING
INSERT INTO employees (first_name, last_name, department, hire_date, salary)
VALUES ('Marina', 'Gromova', 'QA', CURRENT_DATE, 45000)
RETURNING emp_id, (first_name || ' ' || last_name) AS full_name;

-- 21. UPDATE with RETURNING
WITH updated AS (
    SELECT emp_id, salary AS old_salary
    FROM employees
    WHERE department = 'IT'
)
UPDATE employees e
SET salary = e.salary + 5000
FROM updated u
WHERE e.emp_id = u.emp_id
RETURNING e.emp_id, u.old_salary, e.salary AS new_salary;

-- 22. DELETE with RETURNING all columns
DELETE FROM employees
WHERE hire_date < DATE '2020-01-01'
RETURNING *;

-- PART G: Advanced DML Patterns

-- 23. Conditional INSERT
INSERT INTO employees (first_name, last_name, department, hire_date, salary)
SELECT 'Olga', 'Baranova', 'Support', CURRENT_DATE, 38000
WHERE NOT EXISTS (
    SELECT 1 FROM employees e
    WHERE e.first_name = 'Olga' AND e.last_name = 'Baranova'
);

-- 24. UPDATE with JOIN logic using subqueries
UPDATE employees e
SET salary = CASE
    WHEN d.budget > 100000 THEN (e.salary * 1.10)::integer
    ELSE (e.salary * 1.05)::integer
END
FROM departments d
WHERE e.department = d.dept_name;

-- 25. Bulk operations
-- Insert 5 employees in single statement
INSERT INTO employees (first_name, last_name, department, hire_date, salary)
VALUES
    ('Pavel', 'Kirov', 'Support', CURRENT_DATE, 40000),
    ('Rita',  'Belova','Support', CURRENT_DATE, 41000),
    ('Sasha', 'Ivanov','QA',      CURRENT_DATE, 39000),
    ('Tanya', 'Pavlova','QA',     CURRENT_DATE, 42000),
    ('Umar',  'Nur',   'Support', CURRENT_DATE, 37000)
RETURNING emp_id;

UPDATE employees
SET salary = (salary * 1.10)::integer
WHERE hire_date = CURRENT_DATE
  AND first_name IN ('Pavel','Rita','Sasha','Tanya','Umar');

-- 26. Data migration simulation
CREATE TABLE IF NOT EXISTS employee_archive AS
SELECT * FROM employees WHERE false;

-- Move data in a transaction to ensure atomicity
BEGIN;

-- Insert into archive
INSERT INTO employee_archive
SELECT * FROM employees WHERE status = 'Inactive';

-- Delete from original
DELETE FROM employees WHERE status = 'Inactive';

COMMIT;

-- 27. Complex business logic

WITH dept_employee_counts AS (
    SELECT department AS dept_name, COUNT(*) AS emp_count
    FROM employees
    GROUP BY department
)
UPDATE projects p
SET end_date = (COALESCE(p.end_date, CURRENT_DATE) + INTERVAL '30 days')::date
FROM departments d
JOIN dept_employee_counts dec ON dec.dept_name = d.dept_name
WHERE p.dept_id = d.dept_id
  AND p.budget > 50000
  AND dec.emp_count > 3
RETURNING p.project_id, p.project_name, p.end_date;

-- Final: Some checks / useful queries to verify results

-- Check employees
SELECT * FROM employees ORDER BY emp_id;

-- Check departments and budgets
SELECT * FROM departments ORDER BY dept_id;

-- Check projects
SELECT * FROM projects ORDER BY project_id;

-- Check temp table
SELECT * FROM temp_employees;

-- Check archive
SELECT * FROM employee_archive ORDER BY emp_id;
