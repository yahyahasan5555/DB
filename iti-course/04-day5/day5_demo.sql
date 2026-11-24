/*
    Day 5 demo (SQL Server / T-SQL):
    TOP, WITH TIES, NEWID, object names and cross-database queries, SELECT INTO / INSERT ... SELECT,
    HAVING without GROUP BY, ranking functions, data types, CASE / IIF, CAST / CONVERT / FORMAT / EOMONTH.

    It creates its own databases (Day5Demo and Day5Other), so it runs from top to bottom.
    Re-runnable: it drops and recreates only these two databases.
    The expected result is written next to each query.
*/

------------------------------------------------------------
-- Setup
------------------------------------------------------------
USE master;
GO
IF DB_ID('Day5Demo') IS NOT NULL
BEGIN
    ALTER DATABASE Day5Demo SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE Day5Demo;
END
IF DB_ID('Day5Other') IS NOT NULL
BEGIN
    ALTER DATABASE Day5Other SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE Day5Other;
END
GO
CREATE DATABASE Day5Demo;
CREATE DATABASE Day5Other;
GO

USE Day5Other;
GO
CREATE TABLE dbo.Project (pnumber INT PRIMARY KEY, pname VARCHAR(30) NOT NULL);
INSERT INTO dbo.Project VALUES (100, 'Website'), (200, 'Mobile App');
GO

USE Day5Demo;
GO
CREATE TABLE Department (dept_id INT PRIMARY KEY, name VARCHAR(30) NOT NULL);
CREATE TABLE Student (
    St_Id INT PRIMARY KEY, St_Name VARCHAR(30) NOT NULL,
    Age INT NULL,                                               -- NULL = unknown age
    City VARCHAR(20)
);
CREATE TABLE Employee (emp_id INT PRIMARY KEY, emp_name VARCHAR(30) NOT NULL, salary DECIMAL(10,2) NULL);
CREATE TABLE Ages (v INT);                                      -- the instructor's example: 1,2,2,3,4,4,4
GO
INSERT INTO Department VALUES (10, 'HR'), (20, 'IT');
INSERT INTO Student (St_Id, St_Name, Age, City)
VALUES (1, 'Ali', 22, 'Cairo'),  (2, 'Mona', 20, 'Giza'),  (3, 'Omar', 22, 'Cairo'), (4, 'Sara', 25, 'Alex'),
       (5, 'Zeina', 20, 'Cairo'), (6, 'Hassan', NULL, 'Giza'), (7, 'Nadia', 25, 'Cairo'), (8, 'Karim', 18, 'Alex');
INSERT INTO Employee VALUES (1, 'Ahmed', 5000), (2, 'Mona', 6000), (3, 'Omar', 7000),
                            (4, 'Sara', 8000), (5, 'Khaled', NULL), (6, 'Hana', 8000);
INSERT INTO Ages VALUES (1), (2), (2), (3), (4), (4), (4);
GO


------------------------------------------------------------
-- 1. TOP, WITH TIES, NEWID
------------------------------------------------------------
-- TOP without ORDER BY: SQL Server may return ANY 2 of the Cairo students
SELECT TOP(2) St_Name FROM Student WHERE City = 'Cairo';

-- With ORDER BY the result is defined: the 2 oldest students (both are 25)
SELECT TOP(2) St_Name, Age FROM Student ORDER BY Age DESC;

SELECT MAX(salary) AS max_salary FROM Employee;                          -- 8000
SELECT TOP(2) salary FROM Employee ORDER BY salary DESC;                 -- 8000, 8000  (the 2 highest ROWS)
SELECT DISTINCT TOP(2) salary FROM Employee ORDER BY salary DESC;        -- 8000, 7000  (the 2 highest VALUES)

-- WITH TIES: after the last row, also return the rows that have the SAME ORDER BY value as it
SELECT TOP(1) WITH TIES St_Name, Age FROM Student ORDER BY Age DESC;     -- 2 rows (both 25)
SELECT TOP(3) WITH TIES St_Name, Age FROM Student ORDER BY Age DESC;     -- 4 rows (25, 25, 22, 22)

-- The instructor's example, values 1, 2, 2, 3, 4, 4, 4
SELECT TOP(2) WITH TIES v FROM Ages ORDER BY v;      -- 1, 2, 2     (the 2nd row is 2, and the next row is 2 too)
SELECT TOP(3) WITH TIES v FROM Ages ORDER BY v;      -- 1, 2, 2     (the 3rd row is 2, and the next row is 3: no tie)
SELECT TOP(5) WITH TIES v FROM Ages ORDER BY v;      -- 7 rows      (the 5th row is 4, and the next two are 4 too)
-- WITH TIES needs ORDER BY (an error without it).

SELECT TOP(25) PERCENT St_Name FROM Student ORDER BY Age DESC;           -- 2 rows (25% of 8)

-- NEWID() makes a new random GUID for EACH row, every time the query runs. Nothing is saved.
SELECT St_Name, NEWID() AS guid FROM Student;
SELECT TOP(3) * FROM Student ORDER BY NEWID();                           -- 3 random students


------------------------------------------------------------
-- 2. Object names and cross-database queries
------------------------------------------------------------
-- [Server].[Database].[Schema].[Object]  -- the parts you leave out come from your connection / USE / default schema
SELECT DB_NAME() AS current_database, SCHEMA_NAME() AS default_schema;   -- Day5Demo, dbo

SELECT * FROM Student;
SELECT * FROM Day5Demo.dbo.Student;               -- the same table, with the full database.schema.object name
SELECT * FROM Day5Other.dbo.Project;              -- a table from another database on the same server

SELECT name FROM Day5Demo.dbo.Department
UNION ALL
SELECT pname FROM Day5Other.dbo.Project;          -- HR, IT, Website, Mobile App

-- Another SERVER: first create a linked server (sp_addlinkedserver), then
-- SELECT * FROM [OtherServer].[SomeDb].[dbo].[SomeTable];


------------------------------------------------------------
-- 3. SELECT INTO and INSERT ... SELECT
------------------------------------------------------------
-- SELECT INTO creates a NEW table (same column names and types) and fills it with the result
SELECT * INTO Student_Copy FROM Student;                                 -- 8 rows
-- SELECT * INTO Student FROM Student;            -- error: There is already an object named 'Student'

-- An impossible condition copies the structure only
SELECT * INTO Student_Empty FROM Student WHERE 1 = 2;                    -- 0 rows

-- The copy has NO constraints: the primary key is not copied
SELECT OBJECT_NAME(parent_object_id) AS table_name, name AS constraint_name
FROM sys.key_constraints
WHERE OBJECT_NAME(parent_object_id) IN ('Student', 'Student_Copy');      -- only Student has a primary key

-- Into a table in ANOTHER database
SELECT * INTO Day5Other.dbo.Student FROM Student;
SELECT COUNT(*) AS rows_copied FROM Day5Other.dbo.Student;               -- 8

-- INSERT ... SELECT fills an EXISTING table. List the columns: the number and the types must match.
INSERT INTO Student_Empty (St_Id, St_Name, Age, City)
SELECT St_Id, St_Name, Age, City
FROM Student
WHERE City = 'Cairo';                                                    -- 4 rows
SELECT * FROM Student_Empty;


------------------------------------------------------------
-- 4. HAVING without GROUP BY (the whole table is one group)
------------------------------------------------------------
SELECT SUM(salary) AS total FROM Employee HAVING COUNT(*) < 100;        -- 34000
SELECT SUM(salary) AS total FROM Employee HAVING COUNT(*) >= 100;       -- no rows
-- SELECT emp_name, SUM(salary) FROM Employee HAVING COUNT(*) < 100;    -- error: emp_name is not in an aggregate


------------------------------------------------------------
-- 5. Ranking functions
------------------------------------------------------------
-- Age DESC:   Nadia 25 | Sara 25 | Ali 22 | Omar 22 | Mona 20 | Zeina 20 | Karim 18 | Hassan NULL
SELECT St_Name, Age,
       ROW_NUMBER() OVER (ORDER BY Age DESC, St_Name) AS rn,           -- 1 2 3 4 5 6 7 8   (always different)
       RANK()       OVER (ORDER BY Age DESC)          AS rnk,          -- 1 1 3 3 5 5 7 8   (ties share, then a gap)
       DENSE_RANK() OVER (ORDER BY Age DESC)          AS dr,           -- 1 1 2 2 3 3 4 5   (ties share, no gap)
       NTILE(3)     OVER (ORDER BY Age DESC, St_Name) AS grp          -- 1 1 1 2 2 2 3 3   (3 buckets)
FROM Student
ORDER BY rn;

-- A window function cannot be used in WHERE (WHERE runs before SELECT):
-- SELECT *, ROW_NUMBER() OVER (ORDER BY Age DESC) AS rn FROM Student WHERE rn = 1;     -- error
-- So put the query in a derived table (it needs an alias) and filter outside:
SELECT *
FROM (SELECT *, ROW_NUMBER() OVER (ORDER BY Age DESC, St_Name) AS rn FROM Student) AS t
WHERE rn = 1;                                                            -- Nadia only (like TOP(1))

SELECT *
FROM (SELECT *, DENSE_RANK() OVER (ORDER BY Age DESC) AS dr FROM Student) AS t
WHERE dr = 1;                                                            -- Nadia and Sara (like TOP(1) WITH TIES)

-- PARTITION BY restarts the numbering for each group: the oldest student in each city
SELECT *
FROM (SELECT *, ROW_NUMBER() OVER (PARTITION BY City ORDER BY Age DESC, St_Name) AS rn FROM Student) AS t
WHERE rn = 1;                                                            -- Nadia (Cairo), Mona (Giza), Sara (Alex)


------------------------------------------------------------
-- 6. Data types
------------------------------------------------------------
-- FLOAT is approximate, DECIMAL is exact
SELECT CASE WHEN CAST(0.1 AS FLOAT) + CAST(0.2 AS FLOAT) = CAST(0.3 AS FLOAT)
            THEN 'equal' ELSE 'NOT equal' END AS float_check,            -- NOT equal
       CASE WHEN CAST(0.1 AS DECIMAL(3,1)) + CAST(0.2 AS DECIMAL(3,1)) = CAST(0.3 AS DECIMAL(3,1))
            THEN 'equal' ELSE 'NOT equal' END AS decimal_check;          -- equal

-- Storage: CHAR is padded, VARCHAR is as long as the text, NVARCHAR uses 2 bytes for each character
SELECT DATALENGTH(CAST('abc'  AS CHAR(10)))     AS char10,               -- 10
       DATALENGTH(CAST('abc'  AS VARCHAR(10)))  AS varchar10,            -- 3
       DATALENGTH(CAST(N'abc' AS NVARCHAR(10))) AS nvarchar10;           -- 6

-- Arabic (Unicode) text: the literal needs the N prefix. On a Latin collation the first one becomes ????
SELECT 'أحمد' AS without_N, N'أحمد' AS with_N;

-- SELECT CAST(300 AS TINYINT);          -- error: Arithmetic overflow (TINYINT is 0 to 255)

-- The date and time types, from the same value
DECLARE @t DATETIME2(7) = '2026-11-24 13:45:30.1234567';
SELECT CAST(@t AS DATE)           AS d,        -- 2026-11-24
       CAST(@t AS TIME(3))        AS t3,       -- 13:45:30.123
       CAST(@t AS SMALLDATETIME)  AS sdt,      -- 2026-11-24 13:46:00      (rounded to the minute)
       CAST(@t AS DATETIME)       AS dt,       -- 2026-11-24 13:45:30.123  (rounded to 1/300 second)
       CAST(@t AS DATETIME2(4))   AS dt2;      -- 2026-11-24 13:45:30.1235
SELECT SYSDATETIMEOFFSET() AS date_time_and_time_zone;                   -- DATETIMEOFFSET


------------------------------------------------------------
-- 7. CASE and IIF
------------------------------------------------------------
SELECT St_Name, Age,
       CASE WHEN Age > 20  THEN 'old'
            WHEN Age <= 20 THEN 'young'
            ELSE 'No Age'                                                -- Hassan (NULL)
       END AS category
FROM Student;

-- The simple form: compare ONE value with several constants
SELECT St_Name,
       CASE City WHEN 'Cairo' THEN 'C' WHEN 'Giza' THEN 'G' ELSE 'Other' END AS city_code
FROM Student;

-- IIF(condition, if true, if false) is a short CASE with 2 results.
-- A NULL condition is not true, so Hassan falls in the false side:  'young'
SELECT St_Name, IIF(Age > 20, 'old', 'young') AS category FROM Student;

-- CASE in UPDATE (on the copy): known ages +1, unknown ages = 18
UPDATE Student_Copy
SET    Age = CASE WHEN Age IS NOT NULL THEN Age + 1 ELSE 18 END;
SELECT St_Name, Age FROM Student_Copy;                                   -- Hassan is 18, everybody else +1

-- CASE in ORDER BY: Cairo first, then the others
SELECT St_Name, City
FROM Student
ORDER BY CASE WHEN City = 'Cairo' THEN 0 ELSE 1 END, St_Name;


------------------------------------------------------------
-- 8. Dates as text: CAST, CONVERT, FORMAT, EOMONTH
------------------------------------------------------------
SELECT CAST(GETDATE() AS VARCHAR(30))         AS cast_no_style,          -- CAST has no style
       CONVERT(VARCHAR(10), GETDATE(), 101)   AS style_101_mm_dd_yyyy,
       CONVERT(VARCHAR(10), GETDATE(), 102)   AS style_102_yyyy_mm_dd,
       CONVERT(VARCHAR(10), GETDATE(), 103)   AS style_103_dd_mm_yyyy,
       CONVERT(VARCHAR(10), GETDATE(), 104)   AS style_104_dd_mm_yyyy_dots,
       CONVERT(VARCHAR(8),  GETDATE(), 108)   AS style_108_time_24h,
       CONVERT(VARCHAR(19), GETDATE(), 120)   AS style_120_iso;

-- FORMAT uses a pattern. The case matters:  MM = month, mm = MINUTES, HH = 24 hours, hh = 12 hours
SELECT FORMAT(GETDATE(), 'MM/dd/yy')              AS month_day_year,
       FORMAT(GETDATE(), 'mm/dd/yy')              AS minutes_day_year,   -- a common mistake
       FORMAT(GETDATE(), 'dd-MM-yyyy hh-mm-ss tt') AS day_month_year_12h,
       FORMAT(GETDATE(), 'dd')                    AS day_as_text,        -- text
       DAY(GETDATE())                             AS day_as_int;         -- number

-- EOMONTH(date [, months to add]) = the last day of the month
SELECT EOMONTH(GETDATE())                          AS end_of_this_month,
       EOMONTH(GETDATE(), 1)                       AS end_of_next_month,
       EOMONTH(CAST('2026-02-10' AS DATE))         AS end_of_february,   -- 2026-02-28
       DAY(EOMONTH(CAST('2026-02-10' AS DATE)))    AS days_in_february;  -- 28

-- Cleanup (optional):
-- USE master;  DROP DATABASE Day5Demo;  DROP DATABASE Day5Other;