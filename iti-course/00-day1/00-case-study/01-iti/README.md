# Case 2: ITI Database (ERD)

## 📋 Case Description

ITI has decided to store information about its students and curriculums in a database. Prepare an E-R diagram that describes its activities according to the following description:

- ITI has a number of students in different departments (tracks). Each student has `St_id` (unique), `studentName` (Fname, Lname), `St_age`, `St_address`.
- Each department has `dept_id` (unique) and `dep_name`.
- Students take many courses. Each course has `crs_id`, `crs_name`, `crs_duration` and `crs_description`.
- A student has a grade in each course.
- Each department contains a set of instructors, and each instructor is located in one department. Each instructor has `ins_id`, `ins_name`, `ins_salary`, `ins_hourRate`, `ins_bonus`, `ins_address`.
- For each department there is always one instructor assigned to manage it, and each manager has a hiring date.
- An instructor may teach many courses and each course may be taught by many instructors. Each instructor has an evaluation in each course.
- A course is classified under one topic, and each topic may have many courses. Each topic has `top_name` and `top_id`.

---

## 🧩 Entities

| Entity | Attributes |
|---|---|
| **Student** | **St_id** (PK), Name *(composite: Fname, Lname)*, Age, Address |
| **Department** | **Dept_id** (PK), Dept_name |
| **Instructor** | **Ins_id** (PK), Ins_name, Ins_salary, Ins_hourRate, Ins_bonus, Ins_address |
| **Course** | **Crs_id** (PK), Crs_name, Crs_duration, Crs_description |
| **Topic** | **Top_id** (PK), Top_name |

---

## 🔗 Relationships

| # | Relationship | Cardinality | Participation | Relationship attribute |
|---|---|---|---|---|
| 1 | Department **has** Student | 1 : M | Student: **total**, Department: partial | - |
| 2 | Department **contains** Instructor | 1 : M | Instructor: **total**, Department: partial | - |
| 3 | Department **managed by** Instructor | 1 : 1 | Department: **total**, Instructor: partial | `Hiring_date` |
| 4 | Student **takes** Course | M : N | Student: partial, Course: partial | `Grade` |
| 5 | Instructor **teaches** Course | M : N | Instructor: partial, Course: partial | `Evaluation` |
| 6 | Topic **classifies** Course | 1 : M | Course: **total**, Topic: partial | - |

### Why each participation?

| # | Reasoning (from the case) |
|---|---|
| 1 | "each student is in a department" → every student must belong to one department (total). A department may exist with no students yet (partial). |
| 2 | "each instructor is located in one department" → total on the instructor side. |
| 3 | "there is **always** one instructor assigned to manage that department" → total on the department side. Not every instructor is a manager → partial on the instructor side. |
| 4 | Not stated as mandatory → partial on both sides (a new student may not have taken a course yet, a new course may have no students yet). |
| 5 | Not stated in the case → see assumption 2 below. |
| 6 | "Course is classified under **one** topic" → total on the course side. A topic may have no courses yet → partial. |

---

## 📌 Assumptions

*The case does not state these explicitly, so I treated them as if I had asked the system analyst and he confirmed them:*

1. **Every `id` is the Primary Key** of its entity: `St_id`, `Dept_id`, `Ins_id`, `Crs_id`, `Top_id`.
2. **Instructor ↔ Course participation is partial on both sides:**
    - An instructor is not required to teach a course (for example a department manager may only manage).
    - A course is not required to have an instructor yet (for example a newly added course).
3. **Student ↔ Course participation is partial on both sides.**
4. `Hiring_date` describes the **manager role**, so it belongs to the *managed by* relationship, not to the Instructor entity.
5. An instructor manages **at most one** department.
6. The attribute is spelled `bonus` (the case writes `bouns`).

---

## ⚠️ Mistakes I Made (and Why)

| #   | Mistake                                          | Why it is wrong                                                                                                                                                                                              | How to avoid it                                                                                                                                                                         |
| --- | ------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | **Forgot the Student ↔ Department relationship** | The first sentence says students are "in different departments (tracks)". Without this relationship, a student is not linked to any department.                                                              | Go through the description **sentence by sentence**. Every sentence that mentions two entities is a possible relationship. Tick each one after drawing it.                              |


### Not mistakes, but lessons

- The case did **not** say which attribute is the key for `Topic` and `Instructor`, nor the participation between `Course` and `Instructor`. Leaving them undecided was not a modeling error, but a real designer must **decide and document** such gaps. That is why they now appear under **Assumptions**.

---
