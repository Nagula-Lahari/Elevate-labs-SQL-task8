-- SQL Developer Internship - Task 8: Stored Procedures and Functions
-- Full Code for MySQL Workbench

-- IMPORTANT NOTE FOR DB Browser for SQLite USERS:
-- SQLite does NOT natively support stored procedures or user-defined functions (UDFs)
-- written directly in SQL like MySQL. The 'CREATE PROCEDURE' and 'CREATE FUNCTION'
-- syntax below is specific to MySQL. For SQLite, you would typically implement
-- this logic in your application code or use language-specific UDFs (e.g., in Python/C++).
-- You can still use DB Browser for SQLite to run the table creation and data insertion parts.

-- Section 1: Schema Setup and Sample Data Insertion

-- Drop existing tables if they exist to ensure a clean run
DROP TABLE IF EXISTS Employees;
DROP TABLE IF EXISTS Departments;

-- Create Departments Table
CREATE TABLE Departments (
    department_id INT PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL
);

-- Insert sample data into Departments
INSERT INTO Departments (department_id, department_name) VALUES
(101, 'Human Resources'),
(102, 'Engineering'),
(103, 'Sales'),
(104, 'Marketing');

-- Create Employees Table
CREATE TABLE Employees (
    employee_id INT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE,
    phone_number VARCHAR(20),
    hire_date DATE,
    job_id VARCHAR(50),
    salary DECIMAL(10, 2),
    department_id INT,
    FOREIGN KEY (department_id) REFERENCES Departments(department_id)
);

-- Insert sample data into Employees
INSERT INTO Employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, department_id) VALUES
(1, 'Alice', 'Smith', 'alice.smith@example.com', '111-222-3333', '2020-01-15', 'Software Engineer', 75000.00, 102),
(2, 'Bob', 'Johnson', 'bob.johnson@example.com', '444-555-6666', '2019-03-20', 'HR Specialist', 60000.00, 101),
(3, 'Charlie', 'Brown', 'charlie.brown@example.com', '777-888-9999', '2021-06-01', 'Sales Manager', 85000.00, 103),
(4, 'Diana', 'Prince', 'diana.prince@example.com', '123-456-7890', '2022-02-10', 'Marketing Coordinator', 55000.00, 104),
(5, 'Eve', 'Davis', 'eve.davis@example.com', '987-654-3210', '2018-09-01', 'Lead Engineer', 95000.00, 102),
(6, 'Frank', 'White', 'frank.white@example.com', '111-333-5555', '2023-01-05', 'HR Assistant', 45000.00, 101);

-- Verify initial data
SELECT * FROM Employees;


-- Section 2: Stored Procedure Definition

-- Change DELIMITER to allow ';' inside the procedure body
DELIMITER //

-- Drop the procedure if it already exists to allow re-running the script
DROP PROCEDURE IF EXISTS UpdateEmployeeSalary //

CREATE PROCEDURE UpdateEmployeeSalary(
    IN p_employee_id INT,
    IN p_percentage_increase DECIMAL(5, 2), -- e.g., 5.00 for 5%
    OUT p_status_message VARCHAR(255)       -- Output parameter for status
)
BEGIN
    DECLARE current_salary DECIMAL(10, 2);
    DECLARE new_salary DECIMAL(10, 2);

    -- Check if employee exists
    SELECT salary INTO current_salary FROM Employees WHERE employee_id = p_employee_id;

    IF current_salary IS NULL THEN
        SET p_status_message = CONCAT('Error: Employee with ID ', p_employee_id, ' not found.');
    ELSE
        -- Calculate new salary
        SET new_salary = current_salary * (1 + (p_percentage_increase / 100));

        -- Conditional logic: Prevent new salary from being negative
        IF new_salary < 0 THEN
            SET p_status_message = 'Error: Calculated new salary would be negative. Update aborted.';
        ELSE
            -- Update the salary
            UPDATE Employees
            SET salary = new_salary
            WHERE employee_id = p_employee_id;

            -- Check if update was successful (ROW_COUNT() returns the number of rows affected by the last statement)
            IF ROW_COUNT() = 1 THEN
                SET p_status_message = CONCAT('Success: Salary for Employee ID ', p_employee_id, ' updated to ', new_salary, '.');
            ELSE
                SET p_status_message = 'Error: Salary update failed for an unknown reason (e.g., no change).';
            END IF;
        END IF;
    END IF;
END //

-- Reset DELIMITER back to default
DELIMITER ;


-- Section 3: Stored Procedure Usage Examples

SELECT '--- Calling Stored Procedure UpdateEmployeeSalary ---' AS 'Procedure Usage Examples';

-- Example 1: Increase Alice Smith's salary by 10% (employee_id = 1)
CALL UpdateEmployeeSalary(1, 10.00, @status1);
SELECT @status1 AS UpdateStatus_AliceSmith;
SELECT employee_id, first_name, last_name, salary FROM Employees WHERE employee_id = 1;

-- Example 2: Increase Bob Johnson's salary by 5% (employee_id = 2)
CALL UpdateEmployeeSalary(2, 5.00, @status2);
SELECT @status2 AS UpdateStatus_BobJohnson;
SELECT employee_id, first_name, last_name, salary FROM Employees WHERE employee_id = 2;

-- Example 3: Try to update a non-existent employee
CALL UpdateEmployeeSalary(999, 7.50, @status3);
SELECT @status3 AS UpdateStatus_NonExistentEmployee;

-- Example 4: Try to decrease a salary by a large percentage that would make it negative
-- This demonstrates the conditional logic preventing a negative salary.
CALL UpdateEmployeeSalary(3, -150.00, @status4); -- Charlie Brown, salary 85000.00, -150% means 85000 * (1 - 1.5) = -42500
SELECT @status4 AS UpdateStatus_CharlieBrown_NegativeTry;
SELECT employee_id, first_name, last_name, salary FROM Employees WHERE employee_id = 3;


-- Section 4: User-Defined Function Definition

-- Change DELIMITER again for the function
DELIMITER //

-- Drop the function if it already exists
DROP FUNCTION IF EXISTS CalculateAnnualBonus //

CREATE FUNCTION CalculateAnnualBonus(
    p_employee_id INT,
    p_performance_rating INT -- e.g., 1 (poor), 2 (average), 3 (good), 4 (excellent)
)
RETURNS DECIMAL(10, 2)
READS SQL DATA -- Indicates that the function reads data but does not modify it
BEGIN
    DECLARE emp_salary DECIMAL(10, 2);
    DECLARE bonus_percentage DECIMAL(5, 2);
    DECLARE annual_bonus DECIMAL(10, 2);

    -- Get employee's current salary
    SELECT salary INTO emp_salary FROM Employees WHERE employee_id = p_employee_id;

    -- If employee not found, return 0 bonus
    IF emp_salary IS NULL THEN
        RETURN 0.00;
    END IF;

    -- Conditional logic to determine bonus percentage based on performance rating
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

-- Reset DELIMITER back to default
DELIMITER ;


-- Section 5: User-Defined Function Usage Examples

SELECT '--- Calling User-Defined Function CalculateAnnualBonus ---' AS 'Function Usage Examples';

-- Example 1: Calculate bonus for Alice Smith (ID 1) with excellent performance (rating 4)
SELECT
    E.first_name,
    E.last_name,
    E.salary,
    CalculateAnnualBonus(E.employee_id, 4) AS AnnualBonus_Excellent
FROM
    Employees AS E
WHERE
    E.employee_id = 1;

-- Example 2: Calculate bonus for Bob Johnson (ID 2) with average performance (rating 2)
SELECT
    E.first_name,
    E.last_name,
    E.salary,
    CalculateAnnualBonus(E.employee_id, 2) AS AnnualBonus_Average
FROM
    Employees AS E
WHERE
    E.employee_id = 2;

-- Example 3: Calculate bonus for Charlie Brown (ID 3) with good performance (rating 3)
SELECT
    E.first_name,
    E.last_name,
    E.salary,
    CalculateAnnualBonus(E.employee_id, 3) AS AnnualBonus_Good
FROM
    Employees AS E
WHERE
    E.employee_id = 3;

-- Example 4: Calculate bonus for all employees with varying performance ratings
-- This demonstrates how a function can be used in a SELECT statement for each row.
SELECT
    E.employee_id,
    E.first_name,
    E.last_name,
    E.salary,
    CASE
        WHEN E.employee_id = 1 THEN CalculateAnnualBonus(E.employee_id, 4) -- Alice: Excellent
        WHEN E.employee_id = 2 THEN CalculateAnnualBonus(E.employee_id, 2) -- Bob: Average
        WHEN E.employee_id = 3 THEN CalculateAnnualBonus(E.employee_id, 3) -- Charlie: Good
        WHEN E.employee_id = 4 THEN CalculateAnnualBonus(E.employee_id, 1) -- Diana: Poor
        WHEN E.employee_id = 5 THEN CalculateAnnualBonus(E.employee_id, 4) -- Eve: Excellent
        WHEN E.employee_id = 6 THEN CalculateAnnualBonus(E.employee_id, 3) -- Frank: Good
        ELSE CalculateAnnualBonus(E.employee_id, 0) -- Default to 0 for others / poor
    END AS EstimatedAnnualBonus
FROM
    Employees AS E;

-- Verify final state of employees table after procedure calls
SELECT '--- Final Employee Salaries after Procedure Calls ---' AS 'Final State';
SELECT employee_id, first_name, last_name, salary FROM Employees;