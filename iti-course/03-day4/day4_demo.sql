/*
    Day 4 demo: Aggregates, GROUP BY / HAVING, Subqueries, Set operators,
                the parent-child rule (foreign keys) and more built-in functions
                (SQL Server / T-SQL)

    The script creates its own database (Day4Demo) with small sample tables,
    so it runs from top to bottom without any other database.
    It can be re-run: it drops and recreates Day4Demo (only this database).

    Sample tables
      Department (dept_id, dept_name)
      Employee   (emp_id, emp_name, salary NULL, city, gender, dept_id NULL)
      Student    (st_id, st_fname, st_age NULL, dept_id NULL, address)
      Instructor (inst_id, inst_name, salary)
      St_Course  (st_id, crs_id, grade)

    Lines that fail on purpose are written as comments ("-- error: ...")
    or wrapped in TRY...CATCH, so the script itself never stops.
*/

------------------------------------------------------------
-- Part 0: a clean database and the sample data
------------------------------------------------------------
USE master;
GO
IF DB_ID('Day4Demo') IS NOT NULL
BEGIN
    ALTER DATABASE Day4Demo SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE Day4Demo;
END
GO
CREATE DATABASE Day4Demo;
GO
USE Day4Demo;
GO

CREATE TABLE Department (
    dept_id    INT          PRIMARY KEY,
    dept_name  VARCHAR(30)  NOT NULL
);
CREATE TABLE Employee (
    emp_id    INT            PRIMARY KEY,
    emp_name  VARCHAR(30)    NOT NULL,
    salary    DECIMAL(10,2)  NULL,            -- NULL = unknown salary
    city      VARCHAR(20),
    gender    CHAR(1),
    dept_id   INT            NULL REFERENCES Department(dept_id)   -- NULL = no department
);
CREATE TABLE Student (
    st_id     INT          PRIMARY KEY,
    st_fname  VARCHAR(30)  NOT NULL,
    st_age    INT          NULL,              -- NULL = unknown age
    dept_id   INT          NULL REFERENCES Department(dept_id),
    address   VARCHAR(20)
);
CREATE TABLE Instructor (
    inst_id    INT            PRIMARY KEY,
    inst_name  VARCHAR(30)    NOT NULL,
    salary     DECIMAL(10,2)
);
CREATE TABLE St_Course (
    st_id   INT  NOT NULL REFERENCES Student(st_id),
    crs_id  INT  NOT NULL,
    grade   INT,
    PRIMARY KEY (st_id, crs_id)
);
GO

INSERT INTO Department (dept_id, dept_name)
VALUES (10, 'HR'), (20, 'IT'), (30, 'Sales'), (40, 'Legal');   -- Legal has no employees and no students
GO
INSERT INTO Employee (emp_id, emp_name, salary, city, gender, dept_id)
VALUES (1, 'Ahmed',   5000, 'Cairo', 'M', 10),
       (2, 'Mona',    6000, 'Giza',  'F', 10),
       (3, 'Omar',    7000, 'Cairo', 'M', 20),
       (4, 'Sara',    8000, 'Cairo', 'F', 20),
       (5, 'Khaled',  NULL, 'Giza',  'M', 20),     -- salary unknown
       (6, 'Hana',    4000, 'Cairo', 'F', 30),
       (7, 'Youssef', NULL, 'Alex',  'M', NULL),   -- no salary, no department
       (8, 'Laila',   5500, 'Giza',  'F', 30);
INSERT INTO Student (st_id, st_fname, st_age, dept_id, address)
VALUES (1, 'Ali',   20,   10,   'Cairo'),
       (2, 'Mona',  22,   10,   'Giza'),
       (3, 'Omar',  NULL, 20,   'Cairo'),          -- age unknown
       (4, 'Sara',  25,   20,   'Alex'),
       (5, 'Zeina', 18,   NULL, 'Cairo'),          -- no department
       (6, 'Ali',   21,   30,   'Giza');           -- same name as student 1 on purpose
INSERT INTO Instructor (inst_id, inst_name, salary)
VALUES (1, 'Mona',   9000),
       (2, 'Hassan', 10000),
       (3, 'Nadia',  8500),
       (4, 'Sara',   9500);
INSERT INTO St_Course (st_id, crs_id, grade)
VALUES (1, 1, 80), (2, 1, 90), (3, 2, 60), (4, 2, 70), (6, 1, 75);
GO


------------------------------------------------------------
-- Part 1: Aggregate functions
------------------------------------------------------------
-- An aggregate function takes MANY rows and returns ONE value.

SELECT salary FROM Instructor;                          -- 4 rows (all the salaries)
SELECT SUM(salary) FROM Instructor;                     -- 1 value: 37000 (the column has no name)
SELECT SUM(salary) AS [Total salary] FROM Instructor;   -- give the result a name with AS

SELECT MIN(salary) AS [Min value], MAX(salary) AS [Max value]
FROM Instructor;                                        -- 8500, 10000

-- COUNT(*) counts ROWS. COUNT(column) counts the rows where the column is NOT NULL.
-- Student: 6 rows, and one age is NULL  ->  6, 6, 6, 5
SELECT COUNT(*)        AS [rows],
       COUNT(st_id)    AS [ids],
       COUNT(st_fname) AS [names],
       COUNT(st_age)   AS [ages]
FROM Student;

-- Employee: 8 rows, 2 salaries are NULL  ->  8 and 6
SELECT COUNT(*) AS [rows], COUNT(salary) AS [known salaries]
FROM Employee;

-- COUNT(DISTINCT col): how many different values (NULL is not counted)
SELECT COUNT(DISTINCT city) AS [cities] FROM Employee;       -- 3

-- Aggregates ignore NULL, so AVG(col) = SUM(col) / COUNT(col)  (NOT / COUNT(*))
-- Known salaries: 35500 / 6 = 5916.67
SELECT SUM(salary)             AS total,
       COUNT(salary)           AS known,
       AVG(salary)             AS avg_ignoring_nulls,        -- 5916.666666
       SUM(salary) / COUNT(*)  AS total_div_all_rows,        -- 4437.5 (the NULL salaries count as 0)
       AVG(ISNULL(salary, 0))  AS avg_nulls_as_zero          -- 4437.5 (the same thing)
FROM Employee;

-- WARNING: AVG of an INT column returns an INT (the decimals are cut)
-- Student ages: 20 + 22 + 25 + 18 + 21 = 106, 106 / 5 = 21.2
SELECT AVG(st_age)        AS avg_int,          -- 21     (cut)
       AVG(st_age * 1.0)  AS avg_decimal       -- 21.2
FROM Student;

-- Treating the unknown age as 0 is a business decision, and here it hurts:
-- 106 / 6 = 17 (the unknown age pulls the average down)
SELECT AVG(ISNULL(st_age, 0)) AS avg_unknown_as_zero FROM Student;

-- MIN and MAX also work on text and dates (alphabetical / oldest-newest)
SELECT MIN(emp_name) AS first_name_alphabetically,
       MAX(emp_name) AS last_name_alphabetically
FROM Employee;

-- Mixing an aggregate with a normal column WITHOUT GROUP BY is an error:
-- SELECT emp_name, SUM(salary) FROM Employee;
-- error: Column 'emp_name' is invalid in the select list because it is not
--        contained in either an aggregate function or the GROUP BY clause.


------------------------------------------------------------
-- Part 2: GROUP BY, WHERE and HAVING
------------------------------------------------------------
-- RULE: every column in SELECT that is NOT inside an aggregate must be in GROUP BY.

-- The sum of the salaries in each department
SELECT dept_id, SUM(salary) AS total_salary
FROM Employee
GROUP BY dept_id;
-- 10 -> 11000 | 20 -> 15000 (Khaled's NULL is ignored) | 30 -> 9500 | NULL -> NULL (its own group)

-- The number of employees in each city
SELECT city, COUNT(emp_id) AS employees
FROM Employee
GROUP BY city;
-- Cairo 4 | Giza 3 | Alex 1

-- Two tables: the group is really decided by dept_id alone, but SQL Server
-- still asks for dept_name in GROUP BY (it is not inside an aggregate).
-- Also: dept_id exists in BOTH tables, so it needs d. (the table name)
SELECT d.dept_id, d.dept_name, SUM(e.salary) AS total_salary
FROM Employee e INNER JOIN Department d
     ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name;
-- error if written "GROUP BY dept_id, dept_name":  Ambiguous column name 'dept_id'.

-- GROUP BY on many columns = ONE group for each different COMBINATION (not nested steps)
SELECT dept_id, gender, COUNT(*) AS employees
FROM Employee
GROUP BY dept_id, gender;
-- (10,F) 1 | (10,M) 1 | (20,F) 1 | (20,M) 2 | (30,F) 2 | (NULL,M) 1

-- You can GROUP BY a column that is not in SELECT (the groups exist, you just do not see their names)
SELECT COUNT(*) AS employees
FROM Employee
GROUP BY city;

-- WHERE filters ROWS before they are grouped
SELECT dept_id, COUNT(*) AS employees
FROM Employee
WHERE city = 'Cairo'
GROUP BY dept_id;
-- 10 -> 1 | 20 -> 2 | 30 -> 1   (only the Cairo employees were counted)

-- An aggregate is NOT allowed in WHERE (WHERE works on single rows):
-- SELECT * FROM Employee WHERE salary > AVG(salary);
-- error: An aggregate may not appear in the WHERE clause ...

-- HAVING filters the GROUPS after they are built (so it can use aggregates)
SELECT dept_id, SUM(salary) AS total_salary
FROM Employee
GROUP BY dept_id
HAVING SUM(salary) > 10000;
-- 10 -> 11000 | 20 -> 15000

-- HAVING can use an aggregate that is NOT in SELECT
SELECT dept_id
FROM Employee
GROUP BY dept_id
HAVING COUNT(*) > 1 AND AVG(salary) > 5500;
-- 10 (avg 5500 is NOT > 5500), 20 (avg 7500), 30 (avg 4750)  ->  only 20

-- WHERE + GROUP BY + HAVING + ORDER BY together (the order of writing is fixed)
SELECT   dept_id, COUNT(*) AS employees, SUM(salary) AS total_salary
FROM     Employee
WHERE    dept_id IS NOT NULL
GROUP BY dept_id
HAVING   COUNT(*) >= 2
ORDER BY total_salary DESC;          -- ORDER BY is the only place where a SELECT alias works

-- HAVING without GROUP BY: the whole table is ONE group
SELECT COUNT(*) AS employees
FROM Employee
HAVING COUNT(*) > 5;

-- Execution order:  FROM / JOIN -> WHERE -> GROUP BY -> HAVING -> SELECT -> ORDER BY
-- That is why a SELECT alias cannot be used in WHERE / GROUP BY / HAVING.


------------------------------------------------------------
-- Part 3: Subqueries (a query inside a query)
------------------------------------------------------------

-- The students younger than the average age.
-- This does NOT work:   SELECT * FROM Student WHERE st_age < AVG(st_age);   (aggregate in WHERE)
-- The subquery returns ONE value, and the outer query compares with it:
SELECT *
FROM Student
WHERE st_age < (SELECT AVG(st_age) FROM Student);
-- AVG of an INT column is 21 (cut)  ->  Ali(20) and Zeina(18)

-- With a decimal average the answer changes: 21.2  ->  Ali(20), Zeina(18) and Ali(21)
SELECT *
FROM Student
WHERE st_age < (SELECT AVG(st_age * 1.0) FROM Student);

-- Replacing the unknown ages by 0 gives average 17, and nobody is younger than that
SELECT *
FROM Student
WHERE st_age < (SELECT AVG(ISNULL(st_age, 0)) FROM Student);   -- 0 rows
-- (Students whose age is NULL never appear: NULL < x is never true.)

-- A subquery with MANY values is used with IN.
-- The departments that have students (not empty):
SELECT dept_name
FROM Department
WHERE dept_id IN (SELECT dept_id FROM Student WHERE dept_id IS NOT NULL);
-- HR, IT, Sales
-- (DISTINCT is not needed: IN only asks "is the value in the list?".
--  DISTINCT is a keyword, not a function, so write  DISTINCT dept_id  without brackets.)

-- The same result with a JOIN needs DISTINCT, otherwise a department is repeated for each student:
SELECT dept_name
FROM Department INNER JOIN Student
     ON Department.dept_id = Student.dept_id;                 -- 5 rows (HR x2, IT x2, Sales)
SELECT DISTINCT dept_name
FROM Department INNER JOIN Student
     ON Department.dept_id = Student.dept_id;                 -- 3 rows

-- EXISTS: "is there at least one row?"  (the inner query uses the outer row = correlated)
SELECT dept_name
FROM Department d
WHERE EXISTS (SELECT 1 FROM Student s WHERE s.dept_id = d.dept_id);   -- HR, IT, Sales

-- The NOT IN trap: if the subquery returns even ONE NULL, NOT IN returns NOTHING.
SELECT dept_name
FROM Department
WHERE dept_id NOT IN (SELECT dept_id FROM Student);                          -- 0 rows (Zeina's NULL)
SELECT dept_name
FROM Department
WHERE dept_id NOT IN (SELECT dept_id FROM Student WHERE dept_id IS NOT NULL);  -- Legal
SELECT dept_name
FROM Department d
WHERE NOT EXISTS (SELECT 1 FROM Student s WHERE s.dept_id = d.dept_id);        -- Legal (safe)

-- A scalar subquery can also sit in SELECT: each student with the overall average age
SELECT st_fname, st_age, (SELECT AVG(st_age * 1.0) FROM Student) AS avg_age
FROM Student;

-- To see how the optimizer treats a query, ask for the plan instead of running it:
--   SET SHOWPLAN_TEXT ON;   (run the query)   SET SHOWPLAN_TEXT OFF;
-- (In SSMS: "Display Estimated Execution Plan". Compare the IN, JOIN and EXISTS versions above.)


------------------------------------------------------------
-- Part 4: Subqueries with DML
------------------------------------------------------------

-- DELETE: remove the course ROWS (enrollments) of the students who live in Cairo
DELETE FROM St_Course
WHERE st_id IN (SELECT st_id FROM Student WHERE address = 'Cairo');
-- 2 rows deleted (students 1 and 3; student 5 has no rows)
SELECT * FROM St_Course;

-- UPDATE: raise by 10% the salary of the employees who work in the IT department
UPDATE Employee
SET    salary = salary * 1.1
WHERE  dept_id IN (SELECT dept_id FROM Department WHERE dept_name = 'IT');
-- Omar 7700, Sara 8800, Khaled stays NULL (NULL * 1.1 = NULL)
SELECT emp_name, salary FROM Employee WHERE dept_id = 20;

-- INSERT ... SELECT: copy the employees who earn more than the average into a new table
CREATE TABLE High_Paid (emp_id INT, emp_name VARCHAR(30), salary DECIMAL(10,2));
INSERT INTO High_Paid (emp_id, emp_name, salary)
SELECT emp_id, emp_name, salary
FROM Employee
WHERE salary > (SELECT AVG(salary) FROM Employee);
-- After the raise the average is 37000 / 6 = 6166.67  ->  Omar (7700) and Sara (8800)
SELECT * FROM High_Paid;


------------------------------------------------------------
-- Part 5: Set operators (UNION family)
------------------------------------------------------------
-- Rules: same NUMBER of columns, COMPATIBLE data types, column names come from the FIRST query.
-- ORDER BY is allowed once, at the very end.

-- UNION ALL: puts the second result under the first one. Keeps the duplicates. (6 + 4 = 10 rows)
SELECT st_fname AS name FROM Student
UNION ALL
SELECT inst_name FROM Instructor;

-- UNION: like UNION ALL, then removes the duplicates (7 rows). Slower: it has to find the duplicates.
SELECT st_fname AS name FROM Student
UNION
SELECT inst_name FROM Instructor
ORDER BY name;

-- INTERSECT: the names that exist in BOTH results (distinct): Mona, Sara
SELECT st_fname FROM Student
INTERSECT
SELECT inst_name FROM Instructor;

-- EXCEPT: in the first result and NOT in the second (distinct): Ali, Omar, Zeina
SELECT st_fname FROM Student
EXCEPT
SELECT inst_name FROM Instructor;

-- The order matters: Hassan, Nadia
SELECT inst_name FROM Instructor
EXCEPT
SELECT st_fname FROM Student;


------------------------------------------------------------
-- Part 6: The parent-child rule (foreign keys)
------------------------------------------------------------
-- A parent row that still has children can NOT be deleted, and its key can NOT be changed.

CREATE TABLE DeptA (
    dept_id    INT          PRIMARY KEY,
    dept_name  VARCHAR(30)  NOT NULL
);
CREATE TABLE EmpA (
    emp_id    INT          PRIMARY KEY,
    emp_name  VARCHAR(30)  NOT NULL,
    dept_id   INT          NULL REFERENCES DeptA(dept_id)
);
GO
INSERT INTO DeptA (dept_id, dept_name) VALUES (10, 'HR'), (20, 'IT'), (30, 'Sales');
INSERT INTO EmpA  (emp_id, emp_name, dept_id)
VALUES (1, 'Ahmed', 10), (2, 'Omar', 20), (3, 'Sara', 20), (4, 'Hana', 30);
GO

-- Both fail with error 547 (the REFERENCE constraint conflict). TRY...CATCH shows the message.
BEGIN TRY
    DELETE FROM DeptA WHERE dept_id = 20;
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS ErrNum, ERROR_MESSAGE() AS ErrMsg;
END CATCH;

BEGIN TRY
    UPDATE DeptA SET dept_id = 200 WHERE dept_id = 20;
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS ErrNum, ERROR_MESSAGE() AS ErrMsg;
END CATCH;
GO

-- The manual way to CHANGE a key: new parent -> move the children -> remove the old parent.
INSERT INTO DeptA (dept_id, dept_name) VALUES (200, 'IT');
UPDATE EmpA SET dept_id = 200 WHERE dept_id = 20;       -- ONE statement moves all the children
DELETE FROM DeptA WHERE dept_id = 20;
SELECT * FROM EmpA;

-- The manual way to DELETE a parent: children first, then the parent.
DELETE FROM EmpA  WHERE dept_id = 30;
DELETE FROM DeptA WHERE dept_id = 30;
SELECT * FROM DeptA;
GO

-- The automatic way: tell the foreign key what to do (referential actions).
--   ON DELETE CASCADE   -> delete the children too
--   ON DELETE SET NULL  -> keep the children, their FK becomes NULL
--   ON UPDATE CASCADE   -> the new key value is copied to the children
CREATE TABLE DeptB (
    dept_id    INT          PRIMARY KEY,
    dept_name  VARCHAR(30)  NOT NULL
);
CREATE TABLE EmpB (
    emp_id    INT          PRIMARY KEY,
    emp_name  VARCHAR(30)  NOT NULL,
    dept_id   INT          NULL,
    CONSTRAINT FK_EmpB_DeptB FOREIGN KEY (dept_id) REFERENCES DeptB(dept_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);
GO
INSERT INTO DeptB (dept_id, dept_name) VALUES (10, 'HR'), (20, 'IT'), (30, 'Sales');
INSERT INTO EmpB  (emp_id, emp_name, dept_id)
VALUES (1, 'Ahmed', 10), (2, 'Omar', 20), (3, 'Sara', 20), (4, 'Hana', 30);
GO

UPDATE DeptB SET dept_id = 200 WHERE dept_id = 20;   -- Omar and Sara follow: 200
DELETE FROM DeptB WHERE dept_id = 30;                -- Hana stays, her dept_id becomes NULL
SELECT * FROM EmpB;
GO


------------------------------------------------------------
-- Part 7: More built-in functions
------------------------------------------------------------

-- Date and time
SELECT GETDATE()                 AS now_date_and_time,    -- date + time of the server
       CAST(GETDATE() AS DATE)   AS today_only;           -- the date part only

SELECT YEAR(GETDATE())  AS the_year,
       MONTH(GETDATE()) AS the_month,
       DAY(GETDATE())   AS the_day;

SELECT YEAR(CAST('2026-11-20' AS DATE))  AS y,
       MONTH(CAST('2026-11-20' AS DATE)) AS m,
       DAY(CAST('2026-11-20' AS DATE))   AS d;                      -- 2026, 11, 20

-- CONVERT with a style number turns a date into text: 103 = dd/mm/yyyy, 120 = yyyy-mm-dd hh:mi:ss
SELECT CONVERT(VARCHAR(10), GETDATE(), 103) AS dd_mm_yyyy;

-- SUBSTRING(text, start, length): the position starts from 1. First 3 letters of each name:
SELECT emp_name, SUBSTRING(emp_name, 1, 3) AS first_3_letters
FROM Employee;

-- Information about where you are
SELECT DB_NAME()    AS current_database,    -- Day4Demo
       SUSER_NAME() AS login_name;          -- the login you connected to the server with
