/*
    Day 3 demo: Joins, built-in functions, LIKE, ORDER BY (SQL Server / T-SQL)

    The script creates its own database (Day3Demo) with small sample tables,
    so it runs from top to bottom without any other database.
    It can be re-run: it drops and recreates Day3Demo (only this database).

    Sample tables
      Employee   (SSN, FName, DeptNum, SuperSSN)          -> self relation (supervisor)
      Department (DeptNum, Name, MgrSSN, MgrHireDate)     -> "works in" and "manages"
      Student, Course, StudentCourse                        -> M:N with a grade
*/

------------------------------------------------------------
-- Part 0: a clean database and the sample data
------------------------------------------------------------
USE master;
GO
IF DB_ID('Day3Demo') IS NOT NULL
BEGIN
    ALTER DATABASE Day3Demo SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE Day3Demo;
END
GO
CREATE DATABASE Day3Demo;
GO
USE Day3Demo;
GO

-- Department is created first (Employee points to it).
-- Department.MgrSSN points back to Employee, so its FK is added after the data (circular relation).
CREATE TABLE Department (
    DeptNum      INT          PRIMARY KEY,
    Name         VARCHAR(30)  NOT NULL,
    MgrSSN       INT          NOT NULL,
    MgrHireDate  DATE
);
GO
CREATE TABLE Employee (
    SSN       INT          PRIMARY KEY,
    FName     VARCHAR(30)  NOT NULL,
    DeptNum   INT          NULL REFERENCES Department(DeptNum),   -- NULL = no department
    SuperSSN  INT          NULL REFERENCES Employee(SSN)          -- NULL = no supervisor
);
GO

INSERT INTO Department (DeptNum, Name, MgrSSN, MgrHireDate)
VALUES (1, 'HR',    101, '2009-05-01'),
       (2, 'IT',    103, '2012-03-15'),
       (3, 'Sales', 102, '2015-07-20');   -- Sales has no employees on purpose
GO
-- The supervisor is inserted before the employees he supervises
INSERT INTO Employee (SSN, FName, DeptNum, SuperSSN)
VALUES (101, 'Ahmed',  1,    NULL),
       (102, 'Mona',   1,    101),
       (103, 'Omar',   2,    101),
       (104, 'Sara',   2,    102),
       (105, 'Khaled', NULL, 103);        -- Khaled has no department on purpose
GO
ALTER TABLE Department
ADD CONSTRAINT FK_Department_Manager FOREIGN KEY (MgrSSN) REFERENCES Employee(SSN);
GO

CREATE TABLE Student (
    Id    INT          PRIMARY KEY,
    Name  VARCHAR(30)  NOT NULL,
    Age   INT          NULL,
    City  VARCHAR(20)
);
CREATE TABLE Course (
    Id    INT          PRIMARY KEY,
    Name  VARCHAR(30)  NOT NULL
);
CREATE TABLE StudentCourse (
    Sid    INT  NOT NULL REFERENCES Student(Id),
    Cid    INT  NOT NULL REFERENCES Course(Id),
    Grade  INT,
    PRIMARY KEY (Sid, Cid)
);
GO
INSERT INTO Student (Id, Name, Age, City)
VALUES (1, 'Ali',  20,   'Cairo'),
       (2, 'Mona', 22,   'Giza'),
       (3, 'Omar', NULL, 'Cairo');        -- Omar's age is unknown
INSERT INTO Course (Id, Name)
VALUES (1, 'SQL'), (2, 'OOP');
INSERT INTO StudentCourse (Sid, Cid, Grade)
VALUES (1, 1, 80), (1, 2, 70), (2, 1, 90), (3, 2, 60);
GO


------------------------------------------------------------
-- Part 1: Cross join (Cartesian product)
------------------------------------------------------------

-- Every employee with every department: 5 x 3 = 15 rows (rows multiply, not columns)
SELECT FName, Name
FROM Employee, Department;

-- The same thing with the explicit keyword
SELECT FName, Name
FROM Employee CROSS JOIN Department;


------------------------------------------------------------
-- Part 2: Inner join (equi join)
------------------------------------------------------------

-- Old syntax (comma + WHERE): each employee with the department he works in
-- DeptNum exists in both tables, so it MUST be written with the table name
SELECT FName, Department.Name
FROM Employee, Department
WHERE Employee.DeptNum = Department.DeptNum;

-- Each department manager's name (the manager is an employee). 3 rows.
SELECT FName, Name
FROM Department, Employee
WHERE SSN = MgrSSN;

-- "SELECT FName, *" prints the name AND every column of both tables
SELECT FName, *
FROM Department, Employee
WHERE SSN = MgrSSN;

-- To get all the columns of ONE table only, put its name before the star
SELECT FName, Department.*
FROM Department, Employee
WHERE SSN = MgrSSN;

-- Filter and sort as before.
-- The original line "MgrHireDate >= 2010" compares a date with the number 2010: it is an error
-- (or a wrong result for DATETIME). Write the date as text, or use YEAR().
SELECT FName, Department.*
FROM Department, Employee
WHERE SSN = MgrSSN AND MgrHireDate >= '2010-01-01'
ORDER BY Department.Name;

-- The new syntax: INNER JOIN ... ON (same result as the old one)
SELECT FName, Department.*
FROM Department INNER JOIN Employee
     ON SSN = MgrSSN;

-- WHERE still works after ON ...
SELECT FName, Department.*
FROM Department INNER JOIN Employee
     ON SSN = MgrSSN
WHERE MgrHireDate >= '2010-01-01';

-- ... but for an INNER join it is the same to put the condition in ON.
-- (For OUTER joins it is NOT the same, see Part 3.)
SELECT FName, Department.*
FROM Department INNER JOIN Employee
     ON SSN = MgrSSN AND MgrHireDate >= '2010-01-01';


------------------------------------------------------------
-- Part 3: Outer join
------------------------------------------------------------

-- LEFT: all the employees, with or without a department. Khaled gets NULL. 5 rows.
SELECT FName, Department.Name
FROM Employee LEFT JOIN Department
     ON Department.DeptNum = Employee.DeptNum;

-- RIGHT: all the departments, with or without employees. Sales gets NULL. 5 rows.
SELECT FName, Department.Name
FROM Employee RIGHT JOIN Department
     ON Department.DeptNum = Employee.DeptNum;

-- FULL: both sides together. Khaled AND Sales appear. 6 rows.
SELECT FName, Department.Name
FROM Employee FULL JOIN Department
     ON Department.DeptNum = Employee.DeptNum;

-- Only the "orphans": employees with NO department (a typical use of outer join)
SELECT FName
FROM Employee LEFT JOIN Department
     ON Department.DeptNum = Employee.DeptNum
WHERE Department.DeptNum IS NULL;

-- Departments with NO employees
SELECT Department.Name
FROM Department LEFT JOIN Employee
     ON Department.DeptNum = Employee.DeptNum
WHERE Employee.SSN IS NULL;


------------------------------------------------------------
-- Part 4: Self join
------------------------------------------------------------
-- One table, two aliases. x = the child (has the FK), y = the parent (the supervisor).
-- There is no "SELF JOIN" keyword: a self join is a normal INNER / LEFT JOIN on the same table.
-- Once a table has an alias, the alias must be used (x.FName, not Employee.FName).

-- Employee with his supervisor. Ahmed (no supervisor) disappears. 4 rows.
SELECT x.FName AS [Employee], y.FName AS [Supervisor]
FROM Employee x INNER JOIN Employee y
     ON y.SSN = x.SuperSSN;

-- LEFT keeps Ahmed, with a NULL supervisor. 5 rows.
SELECT x.FName AS [Employee], y.FName AS [Supervisor]
FROM Employee x LEFT JOIN Employee y
     ON y.SSN = x.SuperSSN;

-- The comma version (the same as a cross join + WHERE)
SELECT x.FName AS [Employee], y.FName AS [Supervisor]
FROM Employee x, Employee y
WHERE y.SSN = x.SuperSSN;


------------------------------------------------------------
-- Part 5: Joining more than two tables
------------------------------------------------------------
-- Rule: at least (number of tables - 1) join conditions. 3 tables -> 2 conditions.

-- Student name, course name and the grade. Old syntax. Aliases are used everywhere.
SELECT S.Name AS [Student name], C.Name AS [Course name], SC.Grade
FROM Student S, StudentCourse SC, Course C
WHERE S.Id = SC.Sid
  AND C.Id = SC.Cid;

-- INNER JOIN syntax: each JOIN adds one more table to the result so far
SELECT S.Name AS [Student name], C.Name AS [Course name], SC.Grade
FROM Student S INNER JOIN StudentCourse SC
         ON S.Id = SC.Sid
     INNER JOIN Course C
         ON C.Id = SC.Cid;


------------------------------------------------------------
-- Part 6: Joins with DML
------------------------------------------------------------

-- Without a join, ALL the grades change:   UPDATE StudentCourse SET Grade += 10;

-- Raise by 10 only the grades of the students who live in Cairo.
-- With a join, UPDATE names the ALIAS (SC) and the join goes in FROM.
UPDATE SC
SET    Grade += 10
FROM   Student S INNER JOIN StudentCourse SC
       ON S.Id = SC.Sid
WHERE  S.City = 'Cairo';
-- 3 rows changed: Ali 80 -> 90, Ali 70 -> 80, Omar 60 -> 70

SELECT S.Name, S.City, SC.Cid, SC.Grade
FROM Student S INNER JOIN StudentCourse SC ON S.Id = SC.Sid;

-- INSERT with a join: copy a result into another table (INSERT ... SELECT)
CREATE TABLE GradeReport (
    StudentName  VARCHAR(30),
    CourseName   VARCHAR(30),
    Grade        INT
);
INSERT INTO GradeReport (StudentName, CourseName, Grade)
SELECT S.Name, C.Name, SC.Grade
FROM Student S INNER JOIN StudentCourse SC ON S.Id = SC.Sid
               INNER JOIN Course C         ON C.Id = SC.Cid;

SELECT * FROM GradeReport;

-- DELETE with a join: delete the grades of the students who live in Giza
DELETE SC
FROM   Student S INNER JOIN StudentCourse SC
       ON S.Id = SC.Sid
WHERE  S.City = 'Giza';
-- 1 row deleted (Mona's grade in SQL)

SELECT * FROM StudentCourse;


------------------------------------------------------------
-- Part 7: Built-in functions
------------------------------------------------------------

-- ISNULL(a, b): if a is NULL give b (exactly two arguments)
SELECT Name, ISNULL(Age, 0) AS Age
FROM Student;

-- If both are NULL the result is NULL too
SELECT ISNULL(NULL, NULL) AS Result;

-- COALESCE(a, b, c, ...): the first value that is NOT NULL (any number of arguments)
SELECT FName, COALESCE(CAST(DeptNum AS VARCHAR(10)), CAST(SuperSSN AS VARCHAR(10)), 'No data') AS Info
FROM Employee;

-- IS NULL is a CONDITION (used in WHERE / ON), ISNULL() is a FUNCTION (used in SELECT to replace)
SELECT Name FROM Student WHERE Age IS NULL;          -- finds the rows
SELECT Name, ISNULL(Age, 0) FROM Student;            -- replaces the value, keeps all the rows

-- CONVERT(type, value): change the data type. NULL stays NULL.
SELECT Name, CONVERT(VARCHAR(4), Age) AS AgeText
FROM Student;

-- "text + number" does NOT work (SQL Server tries to turn the text into a number)
-- SELECT Name + ' ' + Age FROM Student;             -- error
SELECT Name + ' ' + CONVERT(VARCHAR(4), Age) AS Info -- works, but Omar's result is NULL
FROM Student;

-- CONCAT converts everything to text and treats NULL as an empty string
SELECT CONCAT(Name, ' ', Age) AS Info
FROM Student;

-- The long way to get the same result as CONCAT
SELECT ISNULL(Name, '') + ' ' + ISNULL(CONVERT(VARCHAR(4), Age), '') AS Info
FROM Student;


------------------------------------------------------------
-- Part 8: LIKE
------------------------------------------------------------
-- %  = any number of characters (zero or more)
-- _  = exactly one character
-- [] = one character from a set or range:  [abc]  [a-h]   ([^a-h] = NOT in the range)
-- To search for a real % or _ put it inside []:  [%]  [_]
-- (the default collation is case-insensitive, so 'ah' also matches 'Ah')

CREATE TABLE LikeDemo (Txt VARCHAR(20));
INSERT INTO LikeDemo (Txt)
VALUES ('Ahmed'), ('Hanah'), ('Zeina'), ('a_b'), ('axb'), ('100%'), ('50% off'), ('Chair'), ('Sahar');

SELECT Txt FROM LikeDemo WHERE Txt LIKE '%ah%';       -- contains "ah"             : Ahmed, Hanah, Sahar
SELECT Txt FROM LikeDemo WHERE Txt LIKE 'ah%';        -- starts with "ah"          : Ahmed
SELECT Txt FROM LikeDemo WHERE Txt LIKE '_[_]_';      -- 3 chars, the middle is _  : a_b
SELECT Txt FROM LikeDemo WHERE Txt LIKE '%[%]';       -- ends with %               : 100%
SELECT Txt FROM LikeDemo WHERE Txt LIKE '%[%]%';      -- contains %                : 100%, 50% off
SELECT Txt FROM LikeDemo WHERE Txt LIKE '_[a-h]_%';   -- 2nd char is a..h, at least 3 chars : Ahmed, Hanah, Zeina, Chair, Sahar


------------------------------------------------------------
-- Part 9: ORDER BY
------------------------------------------------------------

-- Order by a column that is NOT in the SELECT list: allowed
SELECT FName
FROM Employee
ORDER BY SSN DESC;

-- Order by the position of the column in the SELECT list (works, but avoid it:
-- it breaks silently when the SELECT list changes)
SELECT FName, DeptNum
FROM Employee
ORDER BY 2;

-- Order by many columns: DeptNum first, then FName inside each department.
-- Each column can have its own ASC / DESC (ASC is the default).
SELECT FName, DeptNum
FROM Employee
ORDER BY DeptNum ASC, FName DESC;