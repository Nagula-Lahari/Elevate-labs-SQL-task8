
# SQL Developer Internship - Task 8: Stored Procedures and Functions

## Objective

This task focuses on understanding and implementing reusable SQL blocks using Stored Procedures and User-Defined Functions. The goal is to gain the ability to modularize SQL logic for better organization, performance, and security.

## Tools Used

* **MySQL Workbench:** Fully supports the creation and execution of stored procedures and functions. The provided SQL code is directly compatible with MySQL.
* **DB Browser for SQLite:** While SQLite does not natively support stored procedures or user-defined functions written in SQL, this tool can be used to manage the base tables and understand the underlying data. The conceptual benefits of modularization still apply, even if implementation differs.

## Deliverables

This repository contains:

1.  **SQL Stored Procedure Definition and Usage:** Demonstrates how to create a stored procedure with input/output parameters and conditional logic, and how to call it.
2.  **SQL User-Defined Function Definition and Usage:** Illustrates how to create a function that returns a scalar value, incorporating conditional logic, and how to use it in `SELECT` queries.
3.  **Interview Questions and Answers:** Detailed responses to common questions related to stored procedures, functions, and triggers.
4.  **Complete Query Code:** A single `.sql` file (`complete_query_code.sql`) containing all necessary SQL commands for schema setup, data insertion, routine creation, and usage examples.

---

## 1. Database Setup and Sample Data

To facilitate the demonstration of stored routines, the `Employees` and `Departments` tables (reused from previous tasks) are set up, and sample data is inserted.

```sql
-- Schema Setup for demonstration purposes (truncated for brevity here, full code in .sql file)

-- Create Departments Table
CREATE TABLE Departments (
    department_id INT PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL
);

-- Insert sample data into Departments
INSERT INTO Departments (department_id, department_name) VALUES
(101, 'Human Resources'), (102, 'Engineering');
-- ... more data

-- Create Employees Table
CREATE TABLE Employees (
    employee_id INT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    salary DECIMAL(10, 2),
    department_id INT,
    FOREIGN KEY (department_id) REFERENCES Departments(department_id)
);

-- Insert sample data into Employees
INSERT INTO Employees (employee_id, first_name, last_name, salary, department_id) VALUES
(1, 'Alice', 'Smith', 75000.00, 102),
(2, 'Bob', 'Johnson', 60000.00, 101);
-- ... more data
````

The complete setup code can be found in `complete_query_code.sql`.

-----

## 2\. Stored Procedure: `UpdateEmployeeSalary`

This stored procedure updates an employee's salary by a given percentage. It includes:

  * `IN` parameters for `employee_id` and `percentage_increase`.
  * An `OUT` parameter (`p_status_message`) to return a status message.
  * Conditional logic (`IF` statements) to handle cases where the employee is not found or if the calculated new salary would be negative.

<!-- end list -->

```sql
DELIMITER //

DROP PROCEDURE IF EXISTS UpdateEmployeeSalary //

CREATE PROCEDURE UpdateEmployeeSalary(
    IN p_employee_id INT,
    IN p_percentage_increase DECIMAL(5, 2),
    OUT p_status_message VARCHAR(255)
)
BEGIN
    DECLARE current_salary DECIMAL(10, 2);
    DECLARE new_salary DECIMAL(10, 2);

    SELECT salary INTO current_salary FROM Employees WHERE employee_id = p_employee_id;

    IF current_salary IS NULL THEN
        SET p_status_message = CONCAT('Error: Employee with ID ', p_employee_id, ' not found.');
    ELSE
        SET new_salary = current_salary * (1 + (p_percentage_increase / 100));

        IF new_salary < 0 THEN
            SET p_status_message = 'Error: Calculated new salary would be negative. Update aborted.';
        ELSE
            UPDATE Employees SET salary = new_salary WHERE employee_id = p_employee_id;
            IF ROW_COUNT() = 1 THEN
                SET p_status_message = CONCAT('Success: Salary for Employee ID ', p_employee_id, ' updated.');
            ELSE
                SET p_status_message = 'Error: Salary update failed for an unknown reason.';
            END IF;
        END IF;
    END IF;
END //

DELIMITER ;
```

### Usage Example for `UpdateEmployeeSalary`:

```sql
-- Increase Alice Smith's salary by 10%
CALL UpdateEmployeeSalary(1, 10.00, @status);
SELECT @status AS UpdateStatus;
SELECT employee_id, first_name, salary FROM Employees WHERE employee_id = 1;

-- Try to update a non-existent employee
CALL UpdateEmployeeSalary(999, 5.00, @status_non_existent);
SELECT @status_non_existent AS UpdateStatus_NonExistent;
```

-----

## 3\. User-Defined Function: `CalculateAnnualBonus`

This function calculates an employee's annual bonus based on their salary and a performance rating. It demonstrates:

  * `IN` parameters for `employee_id` and `performance_rating`.
  * A `RETURNS` clause for the scalar value.
  * Conditional logic (`IF...ELSEIF...ELSE`) to apply different bonus percentages.

<!-- end list -->

```sql
DELIMITER //

DROP FUNCTION IF EXISTS CalculateAnnualBonus //

CREATE FUNCTION CalculateAnnualBonus(
    p_employee_id INT,
    p_performance_rating INT
)
RETURNS DECIMAL(10, 2)
READS SQL DATA
BEGIN
    DECLARE emp_salary DECIMAL(10, 2);
    DECLARE bonus_percentage DECIMAL(5, 2);
    DECLARE annual_bonus DECIMAL(10, 2);

    SELECT salary INTO emp_salary FROM Employees WHERE employee_id = p_employee_id;

    IF emp_salary IS NULL THEN
        RETURN 0.00;
    END IF;

    IF p_performance_rating = 4 THEN
        SET bonus_percentage = 0.15; -- 15% for excellent
    ELSEIF p_performance_rating = 3 THEN
        SET bonus_percentage = 0.10; -- 10% for good
    ELSEIF p_performance_rating = 2 THEN
        SET bonus_percentage = 0.05; -- 5% for average
    ELSE
        SET bonus_percentage = 0.00; -- 0% for poor or invalid rating
    END IF;

    SET annual_bonus = emp_salary * bonus_percentage;

    RETURN annual_bonus;
END //

DELIMITER ;
```

### Usage Example for `CalculateAnnualBonus`:

```sql
-- Calculate bonus for Alice Smith (ID 1) with excellent performance (rating 4)
SELECT
    E.first_name,
    E.last_name,
    E.salary,
    CalculateAnnualBonus(E.employee_id, 4) AS AnnualBonus_Alice
FROM
    Employees AS E
WHERE
    E.employee_id = 1;

-- Calculate bonus for all employees with varying performance ratings
SELECT
    E.employee_id,
    E.first_name,
    E.last_name,
    E.salary,
    CalculateAnnualBonus(E.employee_id,
        CASE
            WHEN E.employee_id % 2 = 0 THEN 3 -- Even IDs get Good
            ELSE 4 -- Odd IDs get Excellent
        END
    ) AS EstimatedAnnualBonus
FROM
    Employees AS E;
```

-----

## 4\. Important Note on SQLite Compatibility

As mentioned, **DB Browser for SQLite does not directly support `CREATE PROCEDURE` or `CREATE FUNCTION` statements written in SQL.** The SQL code provided for the procedure and function is specifically for MySQL.

When using DB Browser for SQLite for this task, you should:

  * Run the **Table Creation and Data Insertion** sections as these are standard SQL.
  * Understand the *logic* of the stored procedure and function. In a real-world application using SQLite, this logic would typically be implemented in your application's programming language (e.g., Python, Java, C\#) rather than directly in the database.
  * You can demonstrate the results of the logic by running the underlying `UPDATE` or `SELECT` queries directly, which the procedure/function would encapsulate.

-----

## 5\. Interview Questions

### 1\. Difference between procedure and function?

| Feature        | Stored Procedure                               | User-Defined Function (UDF)                            |
| :------------- | :--------------------------------------------- | :----------------------------------------------------- |
| **Return Value** | Can return zero, one (via `OUT` parameters), or multiple values (via result sets). | Must return a single scalar value. Some DBMS (e.g., SQL Server) also support table-valued functions. |
| **Call Method** | Executed using the `CALL` statement (in MySQL), or `EXEC` (in SQL Server). | Called within SQL expressions (e.g., `SELECT` list, `WHERE` clause, `HAVING` clause). |
| **DML Operations** | Can perform DML operations (`INSERT`, `UPDATE`, `DELETE`). | Generally **cannot** perform DML operations (MySQL UDFs cannot; SQL Server scalar UDFs cannot, but table-valued functions can). |
| **Transaction**| Can manage transactions (`COMMIT`, `ROLLBACK`).    | Cannot manage transactions.                           |
| **Usage Context** | Used for executing a sequence of SQL statements, complex business logic, or multi-step processes. | Primarily used for calculations, data transformations, or returning a single derived value. |
| **Error Handling**| Can include extensive error handling and custom error messages.          | Limited error handling within SQL itself; errors often propagate to the calling query.    |

### 2\. What is IN/OUT parameter?

  * **IN Parameter (Input Parameter):** Used to pass a value *into* the stored routine (procedure or function). The routine can read this value, but it cannot modify it. This is the default parameter type.
  * **OUT Parameter (Output Parameter):** Used exclusively by **stored procedures** to pass a value *back out* to the calling program or environment. The parameter's value is `NULL` when the procedure starts and is set within the procedure.
  * **INOUT Parameter (Input/Output Parameter):** Used exclusively by **stored procedures** to pass an initial value *into* the routine, and the routine can then modify this value to pass a new value *back out* to the caller.

### 3\. Can functions return tables?

Yes, in some database management systems like SQL Server and PostgreSQL, functions can return tables. These are known as **Table-Valued Functions (TVFs)**. They can be used in the `FROM` clause of a `SELECT` statement, much like a table or a view. MySQL's native functions typically return only scalar values, though stored procedures can return result sets that mimic a table.

### 4\. What is RETURN used for?

The `RETURN` statement is used within a **function** to specify the single scalar value that the function will send back to the calling SQL expression. When `RETURN` is encountered, the function's execution immediately terminates, and the specified value is returned. In stored **procedures**, `RETURN` can be used to exit the procedure prematurely, but it does not return a value.

### 5\. How to call stored procedures?

Stored procedures are executed using the `CALL` statement, followed by the procedure's name and its parameters (if any).

**Syntax:**

```sql
CALL procedure_name(parameter1, parameter2, ...);
```

**Example:**

```sql
CALL UpdateEmployeeSalary(101, 5.00, @message);
SELECT @message;
```

### 6\. What is the benefit of stored routines (procedures and functions)?

  * **Modularization & Reusability:** Break down complex logic into smaller, independent, and reusable units. This promotes code organization and reduces redundancy.
  * **Performance:** Routines can be pre-compiled (parsed, optimized) and stored in the database, reducing compilation overhead for repeated executions. They can also reduce network traffic by sending a single `CALL` statement instead of multiple complex SQL queries.
  * **Security:** Users can be granted execution rights on a stored routine without needing direct permissions on the underlying tables, thus restricting direct data access and enhancing security.
  * **Data Integrity & Consistency:** Business rules and data validation logic can be centralized within routines, ensuring that data modifications adhere to defined standards consistently across all applications.
  * **Maintainability:** Changes to business logic only need to be made in one central place (the routine definition) rather than in numerous application codes.

### 7\. Can procedures have loops?

Yes, stored procedures in MySQL (and other SQL DBMS like SQL Server, Oracle, PostgreSQL) support various looping constructs, including:

  * `LOOP ... END LOOP`: A simple loop that requires explicit `LEAVE` to exit.
  * `WHILE ... DO ... END WHILE`: Executes a block of code repeatedly as long as a specified condition is true.
  * `REPEAT ... UNTIL ... END REPEAT`: Executes a block of code at least once and then repeatedly until a specified condition becomes true.
    These loops are often used with cursors to process result sets row by row.

### 8\. Difference between scalar and table-valued functions?

  * **Scalar-Valued Function (SFV):** Returns a single, atomic data value (e.g., an integer, string, date, boolean, decimal). These are typically used in `SELECT` lists, `WHERE` clauses, or other expressions where a single value is expected.
  * **Table-Valued Function (TVF):** Returns a table (a set of rows and columns). These are used in the `FROM` clause of a `SELECT` statement, behaving like a dynamic view or a parameterized table. TVFs are supported in DBMS like SQL Server and PostgreSQL.

### 9\. What is a trigger?

A trigger is a special type of stored procedure that automatically executes (or "fires") when a specific event occurs on a particular database table or view. These events are typically Data Manipulation Language (DML) operations: `INSERT`, `UPDATE`, or `DELETE`. Triggers are used to enforce complex business rules, maintain data integrity (e.g., by cascading updates/deletes), audit data changes, or automate related tasks. They can fire *before* or *after* the DML operation.

### 10\. How to debug stored procedures?

Debugging stored procedures can be challenging since they run on the database server. Common methods include:

  * **Print/Logging Statements:** Inserting `SELECT` statements (MySQL), `PRINT` (SQL Server), or `RAISE NOTICE` (PostgreSQL) within the procedure to output variable values, track execution flow, or confirm logic paths.
  * **Output Parameters:** Using `OUT` or `INOUT` parameters to return intermediate values or status messages that can be inspected by the calling client.
  * **Error Handling:** Implementing robust error handling (`DECLARE CONTINUE HANDLER` in MySQL, `TRY...CATCH` in SQL Server) to catch exceptions and log detailed error information.
  * **IDE/DBMS Debugging Tools:** Many modern database IDEs (like MySQL Workbench, SQL Server Management Studio, DBeaver) offer integrated debugging features that allow developers to set breakpoints, step through code line by line, and inspect variables.
  * **Temporary Tables:** Inserting intermediate results into temporary tables to examine data at various stages of the procedure's execution.
