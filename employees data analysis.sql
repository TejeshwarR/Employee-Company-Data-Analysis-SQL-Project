-- Creating database
CREATE DATABASE emp_dataset;

USE emp_dataset;


-- Creating tables
-- data table import wizards

-- ============================================
-- CLEANING
-- ============================================

ALTER TABLE companies
	change ï»¿company_name company_name text;
    
ALTER TABLE employee
	change ï»¿comp_code_emp comp_code_emp int;

ALTER TABLE functions
	change ï»¿function_code function_code int;

ALTER TABLE salaries
	change ï»¿comp_code comp_code int;
    
SELECT * FROM emp_dataset.employee;
SELECT * FROM emp_dataset.companies;
SELECT * FROM emp_dataset.functions;
SELECT * FROM emp_dataset.salaries;


-- Join all tables and create a new one
-- It's table to merge data from multiple tables

CREATE TABLE merged_employee_data AS
SELECT 
   *
FROM salaries s
	LEFT JOIN companies c
	ON s.comp_name = c.company_name
	LEFT JOIN functions f
	ON s.func_code = f.function_code
	LEFT JOIN employee e
	ON s.employee_id = e.employee_code_emp;


-- Select only relevant columns for further analysis
-- Create an unique identifier code between the columns 'employee_id' and 'date' and call it 'id'
-- Convert the column 'date' to DATE type because it was previously configured as TIMESTAMP
-- Transform this new table into a dataset (df_employee) for analysis


CREATE TABLE df_employee AS
SELECT 
    employee_id ,
    date,
    employee_name,
    gender,
    age,
    salary,
    function_group,
    company_name,
    company_city,
    company_state,
    company_type,
    const_site_category
FROM merged_employee_data;

-- Check for duplicated rows in 'employee_id' column.

SELECT DISTINCT employee_id ,COUNT(employee_id) as duplicated
FROM df_employee
GROUP BY employee_id
HAVING COUNT(employee_id) > 1;



DELETE e
FROM df_employee e
JOIN (
    SELECT 
        employee_id,
        ROW_NUMBER() OVER (
            PARTITION BY date, employee_id 
            ORDER BY employee_id
        ) AS row_num
    FROM df_employee
) t ON e.employee_id = t.employee_id
WHERE t.row_num > 1;

-- Use 'TRIM' to remove all unwanted spaces from all text columns. This is the beginning of standartization

UPDATE df_employee
SET		employee_id	= TRIM(employee_id),
		employee_name = TRIM(employee_name),
		gender = TRIM(gender),
		function_group = TRIM(function_group),
		company_name = TRIM(company_name),
		company_city = TRIM(company_city),
		company_state = TRIM(company_state),
		company_type = TRIM(company_type),
		const_site_category = TRIM(const_site_category);

-- update proper date format
UPDATE df_employee
SET date = STR_TO_DATE(date, '%d-%m-%Y %H:%i');

-- Check for 'NULL' values

SELECT *
	FROM df_employee
	WHERE date IS NULL
	OR employee_id IS NULL
	OR employee_name IS NULL
	OR gender IS NULL
	OR age IS NULL
	OR salary IS NULL
	OR function_group IS NULL
	OR company_name IS NULL
	OR company_city IS NULL
	OR company_state IS NULL
	OR company_type IS NULL
	OR const_site_category IS NULL;

-- Check for 'empty' values (maybe in other databases this step is not needed, but in this case null and empty are different things)

SELECT *
	FROM df_employee
	WHERE employee_id = ''
	OR date = ''
	OR employee_name = ''
	OR gender = ''
	OR age = ''
	OR salary = ''
	OR function_group = ''
	OR company_name = ''
	OR company_city = ''
	OR company_state = ''
	OR company_type = ''
	OR const_site_category = '';
    
-- Confirm missing values in all columns

-- employee_id

SELECT COUNT(employee_id) AS count_missing_id
	FROM df_employee
	WHERE employee_id = '';
		
-- date

SELECT COUNT(date) AS count_missing_month_year
	FROM df_employee
	WHERE date = '';

-- gender

SELECT COUNT(gender) AS count_missing_gender
	FROM df_employee
	WHERE gender = '';

-- age

SELECT COUNT(age) AS count_missing_age
	FROM df_employee
	WHERE age = '';

-- salary

SELECT COUNT(salary) AS count_missing_salary
	FROM df_employee
	WHERE salary = '';
	
-- function_group

SELECT COUNT(function_group) AS count_missing_function_group
	FROM df_employee
	WHERE function_group = '';

-- company_name

SELECT COUNT(company_name) AS count_missing_company_name
	FROM df_employee
	WHERE company_name = '';

-- company_city

SELECT COUNT(company_city) AS count_missing_company_city
	FROM df_employee
	WHERE company_city = '';

-- company_state

SELECT COUNT(company_state) AS count_missing_company_state
	FROM df_employee
	WHERE company_state = '';

-- company_type

SELECT COUNT(company_type) AS count_missing_company_type
	FROM df_employee
	WHERE company_type = '';

-- const_site_category

SELECT COUNT(const_site_category) AS count_missing_const_site_category
	FROM df_employee
	WHERE const_site_category = '';
    
-- Deleting rows of the detected missing values 

-- salary

DELETE FROM df_employee
WHERE salary = '';

-- const_site_category


DELETE FROM df_employee
WHERE const_site_category = '';



-- salary [delete the 1 mi salary because it was used only as a test by the H.R. department]

DELETE FROM df_employee
WHERE salary = 1000000;

	
-- function_group [ok]

SELECT DISTINCT function_group
FROM df_employee
GROUP BY function_group;

-- company_name [ok]

SELECT DISTINCT company_name
FROM df_employee
GROUP BY company_name
ORDER BY company_name;





-- company_city [correct typing]
UPDATE df_employee
SET company_city = 'Goiania'
WHERE company_city = 'Goianiaa';

-- company_state [correct upper case to proper case]
UPDATE df_employee
SET company_state = 'Goias'
WHERE company_state = 'GOIAS';

-- company_type [correct typing]
UPDATE df_employee
SET company_type = 'Construction Site'
WHERE company_type = 'Construction Sites';

-- const_site_category [correct typing]
UPDATE df_employee
SET const_site_category = 'Commercial'
WHERE const_site_category = 'Commerciall';




-- Now we check one last time to ensure that the df_employees table is clean and ready to be used for analysis. 
-- We have done all of this without changing the actual database, which is very important.

SELECT * FROM df_employee;

-- ============================================
-- ANALYSIS
-- ============================================

/*

After cleaning the data we do an analysis to answer some simple questions 

*/

-- How many employees do the companies have today?

SELECT COUNT(DISTINCT employee_id) AS employee_count
FROM df_employee
WHERE date = (SELECT MAX(date) FROM df_employee);


-- Group them by company

SELECT company_name, COUNT(DISTINCT employee_id) AS employee_count
FROM df_employee
WHERE date = (SELECT MAX(date) FROM df_employee)
GROUP BY company_name
ORDER BY employee_count DESC;


------------------------------------------------------------------------------------------------------------------------------------------------

-- What is the total number of employees each city? Add a percentage column

SELECT company_city,
       COUNT(employee_id) AS employee_count,
       COUNT(employee_id) * 100 / SUM(COUNT(employee_id)) OVER () AS percentage
FROM df_employee
WHERE date = (SELECT MAX(date) FROM df_employee)
GROUP BY company_city
ORDER BY employee_count DESC;


------------------------------------------------------------------------------------------------------------------------------------------------

-- What is the total number of employees each month?

SELECT date, COUNT(DISTINCT employee_id) AS employee_count
FROM df_employee
GROUP BY date
ORDER BY date ASC;

-- Average number of employees each month

SELECT (COUNT(employee_id) / COUNT(DISTINCT MONTH(date))) AS avg_employees_per_month
FROM df_employee;

------------------------------------------------------------------------------------------------------------------------------------------------

-- What is the minimum and maximum number of employees throughout all the months? In which months were they?

-- Minimum
SELECT MONTH(date) AS pay_month, COUNT(employee_id) AS count_employees_per_month
FROM df_employee
GROUP BY pay_month
ORDER BY count_employees_per_month ASC
LIMIT 1;

-- Maximum
SELECT MONTH(date) AS pay_month, COUNT(employee_id) AS count_employees_per_month
FROM df_employee
GROUP BY pay_month
ORDER BY count_employees_per_month DESC
LIMIT 1;


------------------------------------------------------------------------------------------------------------------------------------------------

-- What is the monthly average number of employees by function group?

SELECT function_group,
       (COUNT(employee_id) / COUNT(DISTINCT MONTH(date))) AS avg_employees_per_month
FROM df_employee
GROUP BY function_group
ORDER BY avg_employees_per_month DESC;


------------------------------------------------------------------------------------------------------------------------------------------------

-- What is the annual average salary?

SELECT LEFT(date, 4) AS year,
       ROUND(AVG(salary), 2) AS average_salary
FROM df_employee
GROUP BY LEFT(date, 4)
ORDER BY year;

-- What is the monthly average salary?

SELECT MONTH(date) AS pay_month, ROUND(AVG(salary), 2) AS average_salary
FROM df_employee
GROUP BY pay_month
ORDER BY pay_month;


-- What is the average salary by city?

SELECT company_city, ROUND(AVG(salary), 2) AS average_salary
FROM df_employee
GROUP BY company_city
ORDER BY average_salary DESC;


-- What is the average salary by state?

SELECT company_state, ROUND(AVG(salary), 2) AS average_salary
FROM df_employee
GROUP BY company_state
ORDER BY average_salary DESC;


-- What is the  average salary by function group?

SELECT function_group, ROUND(AVG(salary), 2) AS average_salary
FROM df_employee
GROUP BY function_group
ORDER BY average_salary DESC;


------------------------------------------------------------------------------------------------------------------------------------------------

-- What are the employees with the top 10 highest salaries in average?

SELECT employee_name, ROUND(AVG(salary), 2) AS average_salary
FROM df_employee
WHERE date = (SELECT MAX(date) FROM df_employee)
GROUP BY employee_name
ORDER BY average_salary DESC
LIMIT 10;


