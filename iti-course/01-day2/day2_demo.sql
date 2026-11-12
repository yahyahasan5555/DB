/*
    Lecture 2 demo: DDL, DML and DQL basics (SQL Server / T-SQL)

    - Written by me while following the lecture.
    - This version is cleaned so it runs from top to bottom without errors.
    - Lines that are expected to FAIL are commented out and marked "ERROR".
    - Read README.md for the explanation of every section.
*/

------------------------------------------------------------
-- 0. Create and select the database
------------------------------------------------------------
-- The lecture shows two ways to create a database: the wizard (SSMS only)
-- and code. Code works everywhere (also on Linux / Docker).
IF DB_ID('DemoDB') IS NULL
    CREATE DATABASE DemoDB;
GO   -- GO is not T-SQL. It is a command of the client tool that ends a batch.

USE DemoDB;
GO


------------------------------------------------------------
-- 1. DDL (Data Definition Language): the structure of tables
------------------------------------------------------------

-- Create a table with constraints
CREATE TABLE Emp (
    eid        INT          PRIMARY KEY,         -- unique, never NULL
    ename      VARCHAR(39)  NOT NULL,            -- NOT NULL: a value is required
    eaddr      VARCHAR(20)  DEFAULT 'Cairo',     -- used only when the column is NOT mentioned in the INSERT
    ehiredate  DATE         DEFAULT GETDATE(),   -- today's date when not mentioned
    deptNum    INT                               -- no constraint: allows NULL (the default)
);
GO

-- What if I forgot a column after creating the table?
-- ADD a column (existing rows get NULL in it)
ALTER TABLE Emp ADD salary INT;
GO

-- Change the data type: int (4 bytes) -> bigint (8 bytes)
-- This works only if EVERY existing value can be converted without loss.
--   int -> bigint        OK (bigger)
--   bigint -> tinyint    fails if any value is outside 0..255
--   int -> date          not allowed (no conversion exists)
ALTER TABLE Emp ALTER COLUMN salary BIGINT;
GO

-- Delete a column from the TABLE (its data is lost too)
ALTER TABLE Emp ADD temp_col INT;
GO
ALTER TABLE Emp DROP COLUMN temp_col;
GO

-- DROP TABLE removes the data AND the structure (metadata).
CREATE TABLE Temp_Demo (id INT);
GO
DROP TABLE Temp_Demo;
GO


-- Domain constraints: data type + CHECK
-- Note: in SQL Server TINYINT is 0..255 (1 byte), NOT -128..127.
CREATE TABLE Student_Demo (
    sid    INT          PRIMARY KEY,
    sname  VARCHAR(30)  NOT NULL,
    age    TINYINT      CHECK (age BETWEEN 20 AND 30)   -- a more specific rule than the data type
);
GO
INSERT INTO Student_Demo VALUES (1, 'Ali', 25);     -- OK
-- INSERT INTO Student_Demo VALUES (2, 'Eman', 40);  -- ERROR: violates the CHECK (20..30)
-- INSERT INTO Student_Demo VALUES (3, 'Nada', 300); -- ERROR: 300 is outside TINYINT (0..255)
-- INSERT INTO Student_Demo VALUES (1, 'Omar', 22);  -- ERROR: duplicate primary key
GO


------------------------------------------------------------
-- 2. DML (Data Manipulation Language): insert / update / delete
------------------------------------------------------------

-- 2.1 INSERT with all values, in the same order the columns were created
--     Order now: eid, ename, eaddr, ehiredate, deptNum, salary
--     Date written in the safe ISO format yyyy-mm-dd.
INSERT INTO Emp
VALUES (1, 'ali', 'alex', '2024-01-02', NULL, NULL);

-- 2.2 INSERT with a column list: any order I want.
--     The columns I leave out must allow NULL or have a DEFAULT.
--     Here eaddr gets 'Cairo' and ehiredate gets today's date (the defaults).
INSERT INTO Emp (eid, ename)
VALUES (2, 'eman');

-- A DEFAULT is NOT used when I write NULL myself:
INSERT INTO Emp (eid, ename, eaddr)
VALUES (4, 'omar', NULL);          -- eaddr = NULL (not 'Cairo')

-- ...but the DEFAULT keyword asks for the default value explicitly:
INSERT INTO Emp (eid, ename, eaddr)
VALUES (5, 'sara', DEFAULT);       -- eaddr = 'Cairo'

-- 2.3 Row constructor: many rows in one statement
INSERT INTO Emp (ename, eid)
VALUES ('eman', 3), ('ali', 6), ('nada', 11);

SELECT * FROM Emp;


-- 2.4 UPDATE
-- WARNING: without WHERE the update changes ALL ROWS of the table.
UPDATE Emp
SET ename = 'Ali'
WHERE eid = 1;

-- Several columns at once
UPDATE Emp
SET ename = 'Eman', salary = 2500
WHERE eid = 2;

-- Update one column for the whole table (no WHERE on purpose)
UPDATE Emp
SET salary = NULL;


-- 2.5 DELETE rows
-- WARNING: without WHERE ALL ROWS are deleted (the table structure stays).
DELETE FROM Emp
WHERE eid = 11;

-- DELETE FROM Emp;        -- would delete every row, the empty table remains
-- TRUNCATE TABLE Emp;     -- also removes every row (faster, no WHERE, resets IDENTITY)
-- DROP TABLE Emp;         -- removes the table itself (rows + structure)

-- Summary:
--   remove rows     -> DELETE (or TRUNCATE for all rows)
--   remove a column -> ALTER TABLE ... DROP COLUMN
--   remove a table  -> DROP TABLE

SELECT * FROM Emp;
GO


------------------------------------------------------------
-- 3. DQL (Data Query Language): SELECT
------------------------------------------------------------

-- Sample table for the queries (the lecture used an Employee table)
CREATE TABLE Employee (
    ssn         INT          PRIMARY KEY,
    first_name  VARCHAR(30),
    last_name   VARCHAR(30),
    age         INT,
    city        VARCHAR(30)
);
GO
INSERT INTO Employee (ssn, first_name, last_name, age, city)
VALUES (1,    'Ali',    'Hassan',  25,   'Cairo'),
       (2,    'Eman',   'Samir',   NULL, 'Alex'),
       (3,    'Nada',   'Adel',    30,   'Cairo'),
       (4,    'Omar',   'Khaled',  22,   NULL),
       (5,    'Sara',   'Hassan',  28,   'Giza'),
       (7,    'Kareem', NULL,      31,   'Giza'),
       (123,  'Ali',    'Mostafa', 35,   'Alex'),
       (1234, 'Mona',   'Said',    NULL, 'Cairo');
GO


-- 3.1 All columns and all rows.
--     The * stands for ALL COLUMNS (it has nothing to do with rows).
SELECT * FROM Employee;

-- Specific columns
SELECT first_name, last_name FROM Employee;


-- 3.2 NULL
-- NULL means "unknown". Any comparison with NULL gives UNKNOWN, so the row is not returned.
SELECT * FROM Employee WHERE age IS NULL;
SELECT * FROM Employee WHERE age IS NOT NULL;
SELECT * FROM Employee WHERE age = NULL;     -- returns NOTHING (no error, but wrong). Use IS NULL.


-- 3.3 ORDER BY
-- Without ORDER BY the order of the result is NOT guaranteed
-- (rows are stored by the primary key, but never rely on it).
SELECT * FROM Employee ORDER BY last_name;        -- ASC is the default
SELECT * FROM Employee ORDER BY last_name DESC;


-- 3.4 Alias and building a new column
SELECT first_name + ' ' + last_name AS Full_Name
FROM Employee;
-- Kareem has last_name = NULL, so NULL + text = NULL (his full name is lost).
-- CONCAT treats NULL as an empty string:
SELECT CONCAT(first_name, ' ', last_name) AS Full_Name
FROM Employee;
-- An alias with spaces needs brackets: AS [Full Name]


-- 3.5 DISTINCT: removes duplicate rows (compares ALL selected columns together)
SELECT DISTINCT first_name FROM Employee;                      -- 'Ali' appears once
SELECT DISTINCT first_name FROM Employee ORDER BY first_name;  -- to be sorted, say it explicitly


-- 3.6 AND / OR
SELECT last_name FROM Employee
WHERE ssn = 1 AND ssn = 5;      -- no row can have two ssn values at once: always empty

-- SQL keywords and names are not case sensitive
SELECT LAST_NAME FROM EMPLOYEE
WHERE ssn = 1 OR ssn = 123;

-- Text comparison is case insensitive too, with the default collation
SELECT * FROM Employee WHERE first_name = 'ali';     -- finds 'Ali'


-- 3.7 IN: instead of many ORs
SELECT last_name FROM Employee
WHERE ssn IN (1, 2, 3, 4, 123, 1234);


-- 3.8 BETWEEN is inclusive (both ends are included)
SELECT * FROM Employee
WHERE ssn BETWEEN 1 AND 3;

-- Same result:
SELECT * FROM Employee
WHERE ssn >= 1 AND ssn <= 3;


-- 3.9 Running several queries together gives one result set for each query
SELECT * FROM Emp;
SELECT * FROM Employee;
GO


------------------------------------------------------------
-- Clean up (optional): uncomment to remove everything
------------------------------------------------------------
-- USE master;
-- DROP DATABASE DemoDB;
