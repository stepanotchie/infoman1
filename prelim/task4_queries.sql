USE toolshare_prelim;

-- Q1. Names and categories of all tools in the "Power Tools" category
SELECT tool_name, category
FROM tool
WHERE category = 'Power Tools';

/* RESULT:
+----------------+-------------+
| tool_name      | category    |
+----------------+-------------+
| Cordless Drill | Power Tools |
| Circular Saw   | Power Tools |
| Angle Grinder  | Power Tools |
+----------------+-------------+
*/

-- Q2. Members who joined after January 1, 2025
SELECT member_id, member_name, join_date
FROM member
WHERE join_date > '2025-01-01';

/* RESULT:
+-----------+-------------+------------+
| member_id | member_name | join_date  |
+-----------+-------------+------------+
|         2 | Jose Rizal  | 2025-02-10 |
|         3 | Ana Reyes   | 2025-06-01 |
|         5 | Liza Gomez  | 2025-01-15 |
|         6 | Kevin Lim   | 2025-08-05 |
+-----------+-------------+------------+
*/

-- Q3. Borrowing records currently on loan (not yet returned)
SELECT borrow_id, member_id, tool_id, borrow_date, return_date
FROM borrowing
WHERE return_date IS NULL;

/* RESULT:
+-----------+-----------+---------+-------------+-------------+
| borrow_id | member_id | tool_id | borrow_date | return_date |
+-----------+-----------+---------+-------------+-------------+
|         2 |         1 |       2 | 2025-09-12  | NULL        |
|         3 |         2 |       7 | 2025-09-05  | NULL        |
+-----------+-----------+---------+-------------+-------------+
*/

-- Q4. All borrowing records for one specific member (member_id = 1, Maria Santos)
SELECT borrow_id, member_id, tool_id, borrow_date, return_date
FROM borrowing
WHERE member_id = 1;

/* RESULT:
+-----------+-----------+---------+-------------+-------------+
| borrow_id | member_id | tool_id | borrow_date | return_date |
+-----------+-----------+---------+-------------+-------------+
|         1 |         1 |       1 | 2025-09-01  | 2025-09-10  |
|         2 |         1 |       2 | 2025-09-12  | NULL        |
+-----------+-----------+---------+-------------+-------------+
*/

-- Q5. Tools purchased before January 1, 2024
SELECT tool_id, tool_name, purchase_date
FROM tool
WHERE purchase_date < '2024-01-01';

/* RESULT:
+---------+----------------+---------------+
| tool_id | tool_name      | purchase_date |
+---------+----------------+---------------+
|       1 | Cordless Drill | 2023-05-10    |
|       2 | Circular Saw   | 2023-08-22    |
|       4 | Garden Shovel  | 2023-12-01    |
+---------+----------------+---------------+
*/