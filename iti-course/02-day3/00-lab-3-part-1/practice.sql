-- 1. Display the Department id, name and id and the name of its manager.
SELECT Dnum, Dname, SSN, MGRSSN, CONCAT(fname, ' ', lname) AS [Manager Name]
FROM Departments INNER JOIN Employee
ON Departments.MGRSSN = Employee.SSN; 



-- 2. Display the name of the departments and the name of the projects under its control.
SELECT Dname, Pname
FROM Departments INNER JOIN Project
ON Departments.Dnum = Project.Dnum;


-- 3.Display the full data about all the dependence associated with the name of the employee they depend on him/her.
SELECT CONCAT(Fname, ' ', Lname) AS [Employee Name], Dependent.*
FRom Employee INNER JOIN Dependent
ON SSN = ESSN

-- 4. Display the Id, name and location of the projects in Cairo or Alex city.
SELECT Pnumber, Pname, Plocation   
FROM Project
WHERE City = 'Cairo' or City = 'Alex'


-- 5.Display the Projects full data of the projects with a name starts with "a" letter.
SELECT *
FROM Project
WHERE Pname like 'a%'


-- 6.display all the employees in department 30 whose salary from 1000 to 2000 LE monthly
SELECT *
FROM Employee
WHERE Dno = 30 and  salary BETWEEN 1000 AND 2000;


-- 7. Retrieve the names of all employees in department 10 who works more than or equal 10 hours per week on "AL Rabwah" project.
SELECT CONCAT(Fname, ' ', Lname) AS [Employee Name]
FROM Employee INNER JOIN Works_for
              ON SSN = Works_for.ESSn
              INNER JOIN Project
              ON Project.Pnumber = Works_for.pno
WHERE Employee.Dno = 10 AND  Works_for.Hours >= 10 AND Pname = 'AL Rabwah';


-- 8.Find the names of the employees who directly supervised with Kamel Mohamed.
SELECT X.Fname 
FROM Employee X INNER JOIN Employee Y
ON Y.SSN = x.Superssn AND CONCAT(Y.Fname, ' ', Y.Lname) = 'Kamel Mohamed';


-- 9. Retrieve the names of all employees and the names of the projects they are working on, sorted by the project name.
SELECT CONCAT(Fname, ' ', Lname) AS [Employee Name], Pname
FROM Employee INNER JOIN Works_for
              ON Employee.SSN = Works_for.ESSn
              INNER JOIN Project P
              ON P.Pnumber = Pno
ORDER BY P.Pname;


-- 10. For each project located in Cairo City , find the project number, the controlling department name ,the department manager last name ,address and birthdate.
SELECT P.Pnumber, Dname, Emp.Lname, Emp.Address, Emp.BDate
FROM Project P  INNER JOIN Departments Dept
              ON Dept.Dnum = P.Dnum
              INNER JOIN Employee Emp
              ON Emp.SSN = Dept.MGRSSN
WHERE P.City = 'Cairo';


-- 11. Display All Data of the mangers
SELECT Emp.*
FROM Employee Emp INNER JOIN Departments
ON Emp.SSN = Departments.MGRSSN;



-- 12. Display All Employees data and the data of their dependents even if they have no dependents
SELECT Emp.*, Depen.*
FROM Employee Emp LEFT JOIN Dependent Depen
ON Emp.SSN = Depen.ESSN;


---------------------------------------------
-- DML
-- 1. Insert your personal data to the employee table as a new employee in department number 30, SSN = 102672, Superssn = 112233.
INSERT INTO Employee 
VALUES('Yahya', 'Hasan', 102672, '2005-11-7', 'Tamalay Menouf Menofia', 'M', 1200, 112233, 30);

-- 2. Insert another employee with personal data your friend as new employee in department number 30, SSN = 102660, but don’t enter any value for salary or manager number to him.
INSERT INTO Employee (Fname, Lname, SSN, Bdate, Address, Sex, Dno)
VALUES('Ahmed', 'Badawy', 102660, '2001-1-1', 'Mansoura', 'M', 30);

