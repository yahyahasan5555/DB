USE ITI;

-- 1. retrieve number of students who have values in their age.
SELECT COUNT(st_Age) FROM Student;

-- 2. Get all instructors names without repetition.
SELECT DISTINCT Ins_Name  FROM instructor;

-- 3. Display students with the following formate (Use isnull() function).
SELECT st_id AS [Student ID],
       ISNULL(st_fname, ' ') + ' ' + ISNULL(st_lname, ' ') AS [Student Full Name], 
       Dept_name AS [Department Name]
FROM STudent s INNER JOIN Department d
       ON d.Dept_Id = s.Dept_Id;

-- 4. Display the instructor name with its department name 
-- (NOTE: display all instructors either attached to a department or not)
SELECT Ins_name, Dept_name
FROM Instructor ins LEFT JOIN Department dept
ON dept.dept_id = ins.Dept_Id;

-- 5. Display the student full name and the name of the course he's taking for only the courses which have a grade.
SELECT CONCAT(st_fname, ' ', st_lname) AS [Full Name], Crs_name
FROM Student s INNER JOIN Stud_Course sc
       ON s.St_Id = sc.St_Id
       INNER JOIN Course c
       ON c.Crs_Id = sc.Crs_Id
WHERE sc.Grade IS NOT NULL;

-- 6. Display number of courses for each topic name.
SELECT Top_Name, COUNT(Course.Crs_Id) 
FROM Course INNER JOIN Topic
       ON Topic.Top_Id = Course.Top_Id
GROUP BY Top_Name;


-- 7. Display max and min salary for instructors
SELECT MAX(Salary), MIN(Salary) FROM Instructor;


-- 8. Display the instructor who has salary less than the average salaries of all instructors.
SELECT * FROM Instructor
WHERE Salary < (SELECT AVG(Salary) FROM Instructor)


-- 9. Display the department name that contains the instructors who receives the min salary
SELECT Dept_name 
FROM Department D INNER JOIN Instructor I
ON D.Dept_Id = I.Dept_Id
WHERE I.Salary = (SELECT MIN(Salary) FROM Instructor);

-- 10. Select max two salaries in instructor table.
SELECT TOP(2) Salary 
FROM Instructor
ORDER BY Salary DESC;

-- 11. Select instructor name and his salary but if there is no salary display instructor bonus.
-- (NOTE: In my DB there is no bonus column so instead of printing bonus I'll print the instructor's degree)
SELECT ins_name, Coalesce(convert(varchar(20), Salary), Ins_Degree)
FROM Instructor;

-- 12. Select student first name and the data of his supervisor.
SELECT X.st_fname, Y.*
FROM Student X INNER JOIN Student Y
ON Y.st_id = X.st_super;

-- 13. Select AVG sal for ins
SELECT AVG(salary) FROM Instructor;

-- 14. Write a query to select the highest two salaries in each department for instructors who have salaries
-- using one of the ranking functions:
SELECT Dept_id, ins_id, salary
FROM ( SELECT Dept_id, ins_id, salary, 
       DENSE_RANK() OVER (Partition by dept_id ORDER BY Salary DESC) AS DR
       FROM Instructor
) AS newTable
WHERE DR <= 2;



-- 15. choose a random student from each department using one of the ranking functions.
SELECT *
FROM (SELECT *, ROW_NUMBER() OVER(PARTITION BY dept_id ORDER BY NEWID()) AS rn
       FROM STudent) As t
WHERE rn = 1;