# INFOMAN1 — Week 8 Lab Answers

Name: Stephanie Mhay D. De Leon

Student ID: <YOUR_STUDENT_ID>

GitHub repo: https://github.com/stepanotchie/infoman1.git

Date submitted: 18 November 2026

**Dataset check:** `SELECT COUNT(*) FROM employee;` returned: **500** (also visible in the first result of `task2_output.png`, where `COUNT(*)` = 500).

## Task 1 — Pattern Matching Basics

**Approach / explanation:**
I used `LIKE` with `%` (zero or more characters) for the name searches: `'%ez'` finds last names ending in "ez" and `'Ma%'` finds first names starting with "Ma". For `emp_code` I used only `_` (exactly one character), since the code length is fixed. `'E____'` matched all 500 rows, which proves every code is "E" plus four characters. `'E_0__'` then pins the third character to `0`.

**Code / query used (if applicable):**
```sql
-- 1.1 Last name ends in 'ez'
SELECT emp_id, first_name, last_name FROM employee WHERE last_name LIKE '%ez';

-- 1.2 First name starts with 'Ma'
SELECT emp_id, first_name, department FROM employee WHERE first_name LIKE 'Ma%';

-- 1.3a Prove every emp_code matches E____ (expect 500)
SELECT COUNT(*) AS matching_rows FROM employee WHERE emp_code LIKE 'E____';

-- 1.3b Third character is 0
SELECT emp_code, first_name, last_name FROM employee WHERE emp_code LIKE 'E_0__';
```

**Evidence (screenshot filename, output, or file reference in this folder):**

| Query | Rows returned | Evidence file |
|-------|---------------|---------------|
| 1.1 `LIKE '%ez'` | **161** | `task1_1_output.txt` |
| 1.2 `LIKE 'Ma%'` | **112** | `task1_2_output.txt` |
| 1.3a `LIKE 'E____'` | **500** (all rows) | `task1_3a_output.png` |
| 1.3b `LIKE 'E_0__'` | **48** | `task1_3b_output.txt` |

**Reflection question:**
Why do we use the `%` wildcard instead of the `_` wildcard when searching for fields containing a specific keyword?

`%` matches zero or more characters, so `'%Database%'` finds the keyword no matter how much text comes before or after it. `_` matches exactly one character, so it would only work if we knew the exact length and position of the surrounding text. A keyword can appear anywhere in a value of any length, which is why `%` is the right choice.

## Task 2 — Basic Aggregation

**Approach / explanation:**
I ran each aggregate over the whole table with no `GROUP BY`, so each query returns one row. `COUNT(*)` counts all rows, while `COUNT(commission)` skips NULLs. `MIN` and `MAX` are applied to the `hire_date` column to get the earliest and latest dates. For total compensation I wrapped `commission` in `COALESCE(commission, 0)` so NULLs count as zero.

**Code / query used (if applicable):**
```sql
-- 2.1 COUNT(*) vs COUNT(commission)
SELECT COUNT(*) AS total_employees, COUNT(commission) AS employees_with_commission FROM employee;

-- 2.2 Total monthly payroll
SELECT SUM(salary) AS total_monthly_payroll FROM employee;

-- 2.3 Average salary, earliest and latest hire dates
SELECT AVG(salary) AS avg_salary, MIN(hire_date) AS earliest_hire_date, MAX(hire_date) AS latest_hire_date FROM employee;

-- 2.4 Total compensation (NULL commission treated as 0)
SELECT SUM(salary + COALESCE(commission, 0)) AS total_compensation FROM employee;
```

**Evidence (screenshot filename, output, or file reference in this folder):**
Screenshot: `task2_output.png`

| Measure | Result |
|---------|--------|
| 2.1 `COUNT(*)` | 500 |
| 2.1 `COUNT(commission)` | 352 |
| 2.2 `SUM(salary)` | 33,282,250.00 |
| 2.3 `AVG(salary)` | 66,564.50 |
| 2.3 Earliest hire date | 2015-01-03 |
| 2.3 Latest hire date | 2026-09-14 |
| 2.4 Total compensation (with `COALESCE`) | 35,387,750.00 |

**Explanation of the 2.1 gap and why COALESCE was needed in 2.4:**
`COUNT(*)` counts every row (500), but `COUNT(commission)` ignores NULLs, so it only counts the 352 employees who have a commission. The gap of 148 is the employees in roles with no commission, which are stored as NULL. In 2.4, `salary + NULL` evaluates to NULL, so any row with a NULL commission would silently drop out of the `SUM`. `COALESCE(commission, 0)` turns the NULL into 0, so every employee's salary is still counted.

**Reflection question:**
What is the difference between `COUNT(*)` and `COUNT(column_name)`?

`COUNT(*)` counts every row in the result, regardless of NULLs. `COUNT(column_name)` counts only the rows where that column is not NULL. In this lab, `COUNT(*)` gave 500 while `COUNT(commission)` gave 352.

## Task 3 — Grouping Data

**Approach / explanation:**
For 3.1 I used `GROUP BY department` and computed `COUNT(*)`, `AVG(salary)` and `COUNT(DISTINCT job_title)` for each department. For 3.2 I grouped by both `department` and `job_title`, which gives one row for each unique pair (15 rows: 5 departments with 3 titles each). Every non-aggregated column in the `SELECT` is listed in the `GROUP BY`.

**Code / query used (if applicable):**
```sql
-- 3.1 Per department
SELECT department, COUNT(*) AS headcount, AVG(salary) AS avg_salary, COUNT(DISTINCT job_title) AS distinct_job_titles
FROM employee
GROUP BY department;

-- 3.2 Per department and job title
SELECT department, job_title, COUNT(*) AS headcount
FROM employee
GROUP BY department, job_title
ORDER BY department, job_title;
```

**Evidence (screenshot filename, output, or file reference in this folder):**
Screenshot: `task3_output.png` (shows both 3.1 and 3.2).

3.1 output (5 rows):

| department | headcount | avg_salary | distinct_job_titles |
|------------|-----------|------------|---------------------|
| Engineering | 125 | 75160.00 | 3 |
| Finance | 69 | 79513.04 | 3 |
| HR | 50 | 62610.00 | 3 |
| Sales | 144 | 71799.65 | 3 |
| Support | 112 | 44028.57 | 3 |

3.2 output: 15 rows (see screenshot). The headcounts add up to 500.

**Reflection question:**
Why is it generally invalid to include columns in the `SELECT` list that are not in the `GROUP BY` clause, unless they are inside an aggregate function?

After grouping, each group collapses into one output row, but a group can contain many different values of a non-grouped column. The database cannot know which one to show, so the result would be ambiguous or arbitrary. Every column in `SELECT` must either be a grouping column (one value per group) or be summarized by an aggregate function (one value per group).

## Task 4 — Advanced Filtering with HAVING

**Approach / explanation:**
For 4.1, I looked at the Task 3.1 averages and chose the company-wide average salary from Task 2.3 (66,564.50) as the threshold. For 4.2, `WHERE status = 'Active'` filters individual rows before grouping, and `HAVING COUNT(*) > 50` filters the groups after they are formed.

**Code / query used (if applicable):**
```sql
-- 4.1 Departments with average salary above 66,564.50
SELECT department, AVG(salary) AS avg_salary
FROM employee
GROUP BY department
HAVING AVG(salary) > 66564.50;

-- 4.2 Active employees only; departments with more than 50 active employees
SELECT department, COUNT(*) AS headcount
FROM employee
WHERE status = 'Active'
GROUP BY department
HAVING COUNT(*) > 50;
```

**Evidence (screenshot filename, output, or file reference in this folder):**
Screenshot: `task4_output.png` (shows both 4.1 and 4.2).

**Threshold chosen and why:** 66,564.50, the company-wide average salary (Task 2.3). The department averages in Task 3.1 range from 44,028.57 to 79,513.04, so this threshold gives a meaningful split. It answers "which departments pay above the company average?" Three departments are above it and two (HR and Support) are below.

4.1 output (3 rows):

| department | avg_salary |
|------------|------------|
| Sales | 71799.65 |
| Engineering | 75160.00 |
| Finance | 79513.04 |

4.2 output (4 rows):

| department | headcount |
|------------|-----------|
| Sales | 116 |
| Engineering | 104 |
| Finance | 52 |
| Support | 99 |

HR is excluded because it has only 40 active employees.

**Why HAVING instead of WHERE:**
- **4.1:** The average salary is an aggregate that only exists after rows are grouped by department. `WHERE` runs before grouping and cannot use `AVG(salary)`, while `HAVING` filters on the finished group values.
- **4.2:** `WHERE status = 'Active'` correctly filters individual rows before grouping, but the condition `COUNT(*) > 50` depends on the size of each group, which is only known after `GROUP BY`, so it must go in `HAVING`.

**Reflection question:**
Why must we use the `HAVING` clause here instead of the `WHERE` clause to filter by the average value?

SQL processes `WHERE` first (filtering individual rows), then `GROUP BY`, then computes the aggregates, and only then applies `HAVING`. An average does not exist yet at the `WHERE` stage, so `WHERE AVG(salary) > ...` raises an error. `HAVING` is evaluated after the aggregates are calculated, so it can filter on them.

## Self-Check

- [x] All tasks committed with individual, meaningful commit messages
- [x] All files placed inside `week08/`
- [x] This file completed and renamed `answers.md`
- [x] Repository link pasted into Moodle (no files uploaded)