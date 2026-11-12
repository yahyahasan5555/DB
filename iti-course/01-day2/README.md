# Lecture 2: Mapping (ERD to Tables) and SQL Basics

> **In one sentence:** Mapping is a fixed set of rules that turns an ERD into real tables, and then we start writing SQL (DDL, DML, DQL) to build and use those tables.

## Table of Contents

- Part 1: Mapping (ERD to Tables)
    - What is mapping
    - Keys and parent-child relationships
    - Data types and domain constraints
    - Mapping steps
    - Step 1: Regular entities
    - Step 2: Weak entities
    - Step 3: Binary one-to-one relationships
    - Step 4: Binary one-to-many relationships
    - Step 5: Binary many-to-many relationships
    - Step 6: N-ary relationships
    - Step 7: Unary relationships
    - Mapping cheat sheet
- Part 2: SQL Basics
    - SQL families
    - How a database is stored
    - Creating a database
    - Batches
    - DDL: Defining tables
    - DML: Working with data
    - DQL: Querying data
- Common Misunderstandings
- Quick Revision
- Self Test

---

# Part 1: Mapping (ERD to Tables)

## What is mapping

- Mapping is a **set of rules applied to an ERD** to get the tables that really should exist.
- One requirement document can lead to **different ERDs**, but **mapping has fixed rules**: the same ERD always gives the same tables.
- The result is the **schema** (the tables). After that we build it with SQL.
- Things a table cannot show (for example "Address = street + city + state + zip", or the formula of a derived attribute) are written in a separate **constraint file** (a document that goes with the schema).

## Keys and parent-child relationships

**Foreign key (FK)** = a column that points to the primary key of another table.

|Property|Explanation|
|---|---|
|Points to a key|It references the **PK** (or a unique key) of another table|
|Name|Can be **different** from the PK's name|
|Data type|Must be the **same** (or compatible) as the PK it points to|
|Unique?|**Not unique** in 1:M (many rows can point to the same parent). Must be **UNIQUE** in 1:1|
|NULL?|**Can be NULL**, unless you add `NOT NULL` (use it when participation is total)|

**Every relationship is a parent-child relationship.** The table that owns the PK is the **parent**, and the table that holds the FK is the **child**.

By default (`NO ACTION`) you **cannot delete or change a parent row that still has children**. You can change this behavior:

|Rule (`ON DELETE ...`)|What happens when the parent row is deleted|
|---|---|
|`NO ACTION` (default)|Error. The delete is refused|
|`CASCADE`|The children are deleted too|
|`SET NULL`|The FK of the children becomes NULL|
|`SET DEFAULT`|The FK of the children gets its default value|

## Data types and domain constraints

Every column has a **domain**: the set of values it accepts. We build it in two layers:

1. **Data type:** the kind and size of the value (`INT`, `VARCHAR(20)`, `DATE`, ...).
2. **Constraints:** more specific rules, for example `CHECK (age BETWEEN 20 AND 30)`.

Integer types in **SQL Server**:

|Type|Size|Range|
|---|---|---|
|`TINYINT`|1 byte|**0 to 255**|
|`SMALLINT`|2 bytes|-32,768 to 32,767|
|`INT`|4 bytes|-2,147,483,648 to 2,147,483,647|
|`BIGINT`|8 bytes|about -9.2 x 10^18 to 9.2 x 10^18|

> [!NOTE] The range -128 to 127 is a **signed** 1-byte number (used by MySQL's `TINYINT` and by Java's `byte`). In SQL Server `TINYINT` has **no negative values**: it is 0 to 255.



## Mapping steps

Best practice is to follow these steps **in this order**:

1. Regular entities
2. Weak entities
3. Binary 1:1 relationships
4. Binary 1:M relationships
5. Binary M:N relationships
6. N-ary relationships
7. Unary relationships

> [!IMPORTANT] **Before the steps,** look for a **1:1 relationship that is total on both sides**. Those two entities become **one table**, not two.


## Step 1: Regular entities

Create **one table per entity** and choose one of its candidate keys as the **PK**. Then handle the special attributes:

|Attribute type|What to do|
|---|---|
|**Composite** (Address = street, city, state, zip)|Keep **only the parts** as columns. Write "Address = ..." in the constraint file|
|**Multi-valued** (phones)|A **new table**. Its PK is **the owner's PK + the value** (composite PK)|
|**Derived** (Age from BirthDate)|**Do not store it.** Write its formula in the constraint file (it is calculated in queries)|
|**Complex** (composite + multi-valued)|Apply both rules: flatten the composite parts, and put the multi-valued part in its own table|

Example:

```
Employee (emp_id PK, emp_name, street, city, state, zip)
Emp_Phone (emp_id FK, phone)        PK = (emp_id, phone)
```

## Step 2: Weak entities

Create a table for the weak entity. Its **PK = the strong entity's PK (as a FK) + the weak entity's partial key.**

```
Employee (emp_id PK, emp_name)
Dependent (emp_id FK, dep_name, birth_date)     PK = (emp_id, dep_name)
```

It is common to add `ON DELETE CASCADE`, because a dependent has no meaning without its employee.

## Step 3: Binary one-to-one relationships

The rule: **the more partial participation, the more tables.**

|Case|Tables|How|
|---|---|---|
|**Total on both sides**|**1**|Merge both entities into one table. Any key can be the PK, the other key becomes `UNIQUE`|
|**Total on one side**|**2**|The **PK of the partial side** goes into the **total side** as an FK (`NOT NULL` and `UNIQUE`)|
|**Partial on both sides**|**3**|A table for each entity + a **relationship table** with both keys. One is the PK, the other is `UNIQUE`|

Examples:

```
Total + total   (Emp has exactly one PC, PC has exactly one Emp)
  Emp_PC (emp_id PK, emp_name, pc_code UNIQUE, pc_model)

Total on one side   (Emp is partial, PC is total)
  Emp (emp_id PK, emp_name)
  PC  (pc_code PK, pc_model, emp_id FK NOT NULL UNIQUE)

Partial + partial   (Emp may have a Car, Car may belong to an Emp)
  Emp     (emp_id PK, ...)
  Car     (car_id PK, ...)
  Emp_Car (emp_id PK FK, car_id FK UNIQUE)
```

**Why is the FK on the total side?** Because then it can be `NOT NULL`. If we put it on the partial side, it would contain many NULLs.

## Step 4: Binary one-to-many relationships

> [!TIP] In 1:M **look only at the MANY side**: is it total or partial?

|Case|Tables|How|
|---|---|---|
|**Many side is total**|**2**|The **PK of the one side** becomes an **FK in the many side** table (`NOT NULL`)|
|**Many side is partial** (whatever the other side is)|**3**|A table for each entity + a **relationship table**. Its **PK is the many side's PK**|

**Case 1: many side total.** Every employee works for a department.

```
Dept (dept_id PK, dept_name)
Emp  (emp_id PK, emp_name, dept_id FK NOT NULL)
```

**Case 2: many side partial.** Some employees do not work for any department. (This is the case that is confusing, so here is a full example.)

```
Dept      (dept_id PK, dept_name)
Emp       (emp_id PK, emp_name)
Works_For (emp_id PK FK, dept_id FK NOT NULL)
```

```
Dept                Emp                 Works_For
dept_id | name      emp_id | name       emp_id | dept_id
1       | IT        10     | Ali        10     | 1
2       | HR        11     | Eman       11     | 1
                    12     | Omar
```

- Omar has **no department**, so he simply has **no row** in `Works_For`. No NULL is stored anywhere.
- `emp_id` is the **PK** of `Works_For`, so an employee can appear **only once**. That keeps the relationship **1:M** (one department, many employees, but one department per employee).
- If `dept_id` were the PK, a department could appear only once, which would break the "many".

> [!NOTE] This 3-table rule is the course's rule (it avoids NULLs). In real projects many designers simply use a **nullable FK** in the `Emp` table for this case, which is also correct and has fewer joins. Know both.

## Step 5: Binary many-to-many relationships

Always **a new table** whose **PK is the two keys together** (composite PK), each key is also an FK. The participation does **not** matter here.

```
Student (st_id PK, ...)
Course  (crs_id PK, ...)
Takes   (st_id FK, crs_id FK, grade)        PK = (st_id, crs_id)
```

### Where do relationship attributes go?

A relationship attribute does **not** get a table of its own. Put it in the table that **holds the keys of the relationship**:

|Relationship|The attribute goes to|
|---|---|
|1:1|The merged table, the total-side table, or the relationship table|
|1:M|The **many side** table (or the relationship table in the 3-table case)|
|M:N|The new M:N table (`grade` in `Takes`)|
|N-ary|The new N-ary table|

## Step 6: N-ary relationships

(Ternary is the most common.)

1. A table for **each entity**.
2. **One new table** with the **FKs of all the entities** + the relationship attributes.
3. Its PK: look for a **combination that is unique** (often all the FKs, plus a date/time). If none exists, **add an ID column** yourself.

```
Nurse   (nurse_id PK, ...)
Patient (patient_id PK, ...)
Drug    (drug_code PK, ...)
Drug_Administration (nurse_id FK, patient_id FK, drug_code FK, given_at, dosage_mg)
                    PK = (nurse_id, patient_id, drug_code, given_at)
```

The date and time (`given_at`) are in the PK because the same nurse can give the same drug to the same patient many times.

## Step 7: Unary relationships

A unary (recursive) relationship connects an entity **to itself**.

|Cardinality|Mapping|
|---|---|
|**1:M**|An FK in the **same table** that points to its own PK. It is NULL for the top of the hierarchy|
|**M:N**|**2 tables**: the entity table + a relationship table with **two FKs to the same table**|
|**1:1**|A self-referencing FK that is also `UNIQUE`|

```
Employee (emp_id PK, emp_name, super_id FK -> Employee.emp_id)       -- 1:M, boss has super_id = NULL

Course (crs_id PK, crs_name)                                         -- M:N
Prerequisite (crs_id FK, prereq_id FK)   PK = (crs_id, prereq_id)    -- both FKs point to Course
```

> [!NOTE] A self-referencing FK is completely normal. The idea "an FK points to a PK in another table" still works: here the "other table" happens to be the same table.

## Mapping cheat sheet

|Relationship|Tables|Where the key goes|
|---|---|---|
|Regular entity|1 per entity|PK = a candidate key|
|Composite attribute|same table|Only the parts are columns|
|Multi-valued attribute|+1 table|PK = owner's PK + value|
|Weak entity|1|PK = owner's PK + partial key|
|1:1 total + total|**1**|Merge, other key `UNIQUE`|
|1:1 total + partial|**2**|Partial's PK is an FK in the total side|
|1:1 partial + partial|**3**|Relationship table with both keys|
|1:M, many total|**2**|One's PK is an FK in the many side|
|1:M, many partial|**3**|Relationship table, PK = many's PK|
|M:N|**3**|New table, PK = both keys|
|N-ary|entities + **1**|New table with all FKs|
|Unary 1:M|1|FK to its own PK|
|Unary M:N|**2**|Relationship table with two FKs to the entity|

---

# Part 2: SQL Basics

## SQL families



**ANSI SQL** is the standard. Every company builds its own version on top of it:

|Product|Its SQL dialect|
|---|---|
|Microsoft SQL Server|**Transact-SQL (T-SQL)** (the one we study)|
|Oracle|PL/SQL|
|IBM Db2|SQL PL (the slide writes "IBM-PL-SQL")|
|Open source (MySQL, PostgreSQL)|MySQL, PL/pgSQL|

The commands are grouped into 5 languages:

|Language|Full name|Purpose|Commands|
|---|---|---|---|
|**DDL**|Data Definition Language|**Structure** (metadata)|`CREATE TABLE`, `CREATE VIEW`, `CREATE FUNCTION`, `ALTER`, `DROP`, `SELECT INTO`, (`TRUNCATE`)|
|**DML**|Data Manipulation Language|The **data**|`INSERT`, `UPDATE`, `DELETE`, `MERGE`|
|**DCL**|Data Control Language|**Security and permissions**|`GRANT`, `DENY`, `REVOKE`|
|**DQL**|Data Query Language|**Displaying** data|`SELECT` + aggregate functions, grouping, `UNION`, joins, subqueries|
|**TCL**|Transaction Control Language|**Execution** of transactions|`BEGIN TRANSACTION`, `COMMIT`, `ROLLBACK`|

> [!NOTE]
> 
> - `SELECT INTO` is DDL because it **creates a new table**.
> - `TRUNCATE TABLE` is also DDL (it is not in the slide).
> - Some books count `SELECT` as part of DML. This course keeps it separate as DQL.
> - `DENY` exists only in T-SQL.

## How a database is stored

- A database is stored on the hard disk as **files**. In SQL Server there are at least two: a **data file** (`.mdf`) and a **log file** (`.ldf`).
- By default, a table's `PRIMARY KEY` creates a **clustered index**, which means the rows are physically **stored sorted by the PK**, not in the order you inserted them.
- But **never rely on that order** in a query. Without `ORDER BY` the order of the result is **not guaranteed**.

## Creating a database

There are two ways:

1. **Wizard:** right-click in SSMS (Windows).
2. **Code:** `CREATE DATABASE name;` (works everywhere, including Linux and Docker).

Then choose it with `USE name;

## Batches

A **batch** is a series of one or more statements **sent and executed together**.

- If a batch has a **syntax error**, **none** of it runs.
- `GO` is **not a T-SQL command.** It is understood by the client tools (SSMS, `sqlcmd`, VS Code) and means "end of this batch, send it now".
- Selecting several queries and running them together gives **one result set for each query**.

## DDL: Defining tables

|Statement|What it does|
|---|---|
|`CREATE TABLE ...`|Creates a table with its columns and constraints|
|`ALTER TABLE t ADD col type`|Adds a column (old rows get NULL)|
|`ALTER TABLE t ALTER COLUMN col type`|Changes a column's data type|
|`ALTER TABLE t DROP COLUMN col`|Removes a column (with its data)|
|`DROP TABLE t`|Removes the table: **data + structure**|

**Column constraints:**

|Constraint|Meaning|
|---|---|
|`PRIMARY KEY`|Unique and never NULL|
|`NOT NULL`|A value is required|
|`DEFAULT value`|Used **only when the column is not mentioned** in the `INSERT`|
|`CHECK (condition)`|The value must satisfy the condition|
|`UNIQUE`|No repeated values (NULL allowed)|
|`REFERENCES t(col)`|Foreign key|

By default **every column allows NULL**, except the primary key and the columns you mark `NOT NULL`.

**About `DEFAULT`:** if you write `NULL` yourself in the `INSERT`, the column gets `NULL`, **not** the default. To ask for the default explicitly, write the word `DEFAULT`.

**About `ALTER COLUMN`:** the change works only if **every existing value can be converted without loss**:

|Change|Result|
|---|---|
|`INT` to `BIGINT`|Works (bigger)|
|`BIGINT` to `TINYINT`|Fails if any value is outside 0 to 255|
|`INT` to `DATE`|Not allowed|


## DML: Working with data

### INSERT

|Form|Notes|
|---|---|
|`INSERT INTO t VALUES (...)`|You must give **all** the values **in the order the columns were created**|
|`INSERT INTO t (col1, col2) VALUES (...)`|**Any order**. The columns you skip must allow NULL or have a `DEFAULT`|
|`INSERT INTO t (...) VALUES (...), (...), (...)`|**Row constructor**: many rows in one statement|

### UPDATE

```sql
UPDATE t SET col = value [, col2 = value2] WHERE condition;
```

> [!WARNING] Without `WHERE`, **all rows** of the table are updated.

### DELETE, TRUNCATE and DROP

||`DELETE`|`TRUNCATE TABLE`|`DROP TABLE`|
|---|---|---|---|
|Removes|The rows you choose (or all)|**All rows**|The table itself (rows + structure)|
|`WHERE` allowed|Yes|No|No|
|Type|DML|DDL|DDL|

> [!WARNING] `DELETE FROM t` without `WHERE` deletes **all rows** (the empty table stays).

Remember:

- Remove **rows** -> `DELETE`
- Remove a **column** -> `ALTER TABLE ... DROP COLUMN`
- Remove a **table** -> `DROP TABLE`



## DQL: Querying data

|Topic|Explanation|
|---|---|
|`SELECT *`|The `*` means **all columns** (not rows)|
|Specific columns|`SELECT col1, col2 FROM t`|
|`NULL`|NULL means **unknown**, so any comparison with it is _unknown_ and the row is dropped. `= NULL` returns nothing. Use `IS NULL` / `IS NOT NULL`|
|`ORDER BY col [ASC \| DESC]`|Sorts the result. `ASC` is the default. Without it, no order is guaranteed|
|Alias|`col AS name` renames the column in the output. Use brackets for spaces: `AS [Full Name]`|
|Joining text|`first + ' ' + last`. If one part is NULL the whole result is NULL. `CONCAT()` treats NULL as empty text|
|`DISTINCT`|Removes duplicate **rows** (all the selected columns together). It does **not** promise sorted output|
|`AND` / `OR`|Combine conditions. `ssn = 1 AND ssn = 5` is always empty (one row cannot have two values)|
|`IN (a, b, c)`|Shorter than many `OR`s|
|`BETWEEN a AND b`|**Inclusive**: both `a` and `b` are included. Same as `>= a AND <= b`|
|Case sensitivity|SQL keywords and names are **not** case sensitive. Text values depend on the **collation**: the default one is case insensitive, so `'ali' = 'Ali'` is true|

**Dates:** the default date format depends on the server's language settings (for example month/day/year). To avoid surprises, write dates as **`yyyy-mm-dd`**.



---

