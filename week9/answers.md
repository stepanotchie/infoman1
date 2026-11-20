# INFOMAN1 — Week 9 Lab Answers

Name: Stephanie Mhay D. De Leon

Student ID: 2510576

GitHub repo: https://github.com/stepanotchie/infoman1.git

Date submitted: November 20, 2026

## Task 1 — INNER JOIN Basics

**Approach / explanation:**
I joined `students` (alias `s`) to `orders` (alias `o`) with `INNER JOIN`, using the explicit key link `s.student_id = o.student_id` (primary key to foreign key). Only students with a matching order are returned, so the result shows the buyers: Ana (two orders) and Dan (one order). The rows are sorted by `order_id`. Ben and Cara do not appear because they have no orders.

**Code / query used (if applicable):**
```sql
SELECT s.student_name, s.program, o.order_id, o.order_date
FROM students s INNER JOIN orders o ON s.student_id = o.student_id
ORDER BY o.order_id;
```

**Evidence (screenshot filename, output, or file reference in this folder):**
`screenshots/task1_output.png` — 3 rows returned:

| student_name | program | order_id | order_date |
|--------------|---------|----------|------------|
| Ana Cruz     | BSIT    | 101      | 2026-08-10 |
| Ana Cruz     | BSIT    | 102      | 2026-08-15 |
| Dan Reyes    | BSIT    | 103      | 2026-08-16 |

![Task 1 output](screenshots/task1_output.png)

**Reflection question:**
An INNER JOIN returns only rows that have a match on both sides. Ben and Cara have no row in `orders`, so they have nothing to match and are removed by design, which is not data loss. This is exactly what a completed-sales report wants: only students who actually bought something, with no blank rows.

## Task 2 — Finding Missing Relationships

**Approach / explanation:**
For (a), I used `LEFT JOIN` from `students` to `orders`, so every student is kept and unmatched order columns show `NULL`. For (b), I added `WHERE o.order_id IS NULL` to the same join so only unmatched students remain. Ben Lim and Cara Yu appear in (b) because they have no row in `orders`: the LEFT JOIN preserved them with `NULL` in `order_id`, and `IS NULL` kept only those rows.

**Code / query used (if applicable):**
```sql
-- Task 2a: every student, NULL where no order exists
SELECT s.student_name, s.program, o.order_id, o.order_date
FROM students s LEFT JOIN orders o ON s.student_id = o.student_id
ORDER BY s.student_id;

-- Task 2b: only students who never ordered
SELECT s.student_name, s.program, o.order_id, o.order_date
FROM students s LEFT JOIN orders o ON s.student_id = o.student_id
WHERE o.order_id IS NULL
ORDER BY s.student_id;
```

**Evidence (screenshot filename, output, or file reference in this folder):**
`screenshots/task2a_output.png` — 5 rows returned (all four students; Ben and Cara show NULL):

| student_name | program | order_id | order_date |
|--------------|---------|----------|------------|
| Ana Cruz     | BSIT    | 102      | 2026-08-15 |
| Ana Cruz     | BSIT    | 101      | 2026-08-10 |
| Ben Lim      | BSCS    | NULL     | NULL       |
| Cara Yu      | BSIS    | NULL     | NULL       |
| Dan Reyes    | BSIT    | 103      | 2026-08-16 |

![Task 2a output](screenshots/task2a_output.png)

`screenshots/task2b_output.png` — 2 rows returned (only students who never ordered):

| student_name | program | order_id | order_date |
|--------------|---------|----------|------------|
| Ben Lim      | BSCS    | NULL     | NULL       |
| Cara Yu      | BSIS    | NULL     | NULL       |

![Task 2b output](screenshots/task2b_output.png)

**Reflection question:**
In a LEFT JOIN, `NULL` means no matching row exists on the right side; it is not zero or an empty string. `NULL` is never equal to anything, not even another `NULL`, so `= NULL` evaluates to unknown and does not match the rows. `IS NULL` is the correct test for the missing state.

## Task 3 — Four-Table Canteen Report

**Approach / explanation:**
I chained four tables, giving each new table its own `ON` condition that compares a key to its matching key: `students` to `orders` on `student_id`, `orders` to `order_items` on `order_id`, and `order_items` to `menu_items` on `menu_id`. Every column is qualified with an alias (`s`, `o`, `oi`, `m`), so the shared `order_id` is not ambiguous. The line total is computed as `quantity * price`, and the rows are ordered by `order_id`, then `item_name`.

**Code / query used (if applicable):**
```sql
SELECT s.student_name, s.program, o.order_id, m.item_name, oi.quantity, m.price, (oi.quantity * m.price) AS line_total
FROM students s
INNER JOIN orders o ON s.student_id = o.student_id
INNER JOIN order_items oi ON o.order_id = oi.order_id
INNER JOIN menu_items m ON oi.menu_id = m.menu_id
ORDER BY o.order_id, m.item_name;
```

**Evidence (screenshot filename, output, or file reference in this folder):**
`screenshots/task3_output.png` — 4 rows returned:

| student_name | program | order_id | item_name    | quantity | price | line_total |
|--------------|---------|----------|--------------|----------|-------|------------|
| Ana Cruz     | BSIT    | 101      | Iced Tea     | 1        | 30.00 | 30.00      |
| Ana Cruz     | BSIT    | 101      | Siomai Rice  | 2        | 65.00 | 130.00     |
| Ana Cruz     | BSIT    | 102      | Burger Steak | 1        | 89.00 | 89.00      |
| Dan Reyes    | BSIT    | 103      | Siomai Rice  | 1        | 65.00 | 65.00      |

![Task 3 output](screenshots/task3_output.png)

**Reflection question:**
Each join links a different pair of tables through a different key, so each needs its own `ON` to tell MySQL how the new table's rows pair with the rows already built. If an `ON` is missing, or two joins share one, the rows pair incorrectly. Leaving `ON` out gives a Cartesian product (every combination of rows), which inflates the row count with wrong data.

## Task 4 — Aliases, Filters, and the Silent Inner Join

**Approach / explanation:**
Version A uses `INNER JOIN` with `WHERE o.order_date >= '2026-08-01'`, sorted newest first. Version B starts from a `LEFT JOIN` of `students` to `orders` but puts the same date rule in `WHERE`. Both return 4 rows, because Ben and Cara have a `NULL` `order_date`, and `NULL >= '2026-08-01'` is not true, so `WHERE` removes the rows the LEFT JOIN just preserved. Version B is therefore a silent inner join. The fix (Version C) moves the date rule into the `ON` clause, so the filter only decides which orders pair with a student, and all 6 rows are returned with Ben and Cara kept as `NULL` rows.

**Code / query used (if applicable):**
```sql
-- Task 4 Version A (INNER JOIN)
SELECT s.student_name AS buyer, m.item_name AS item, (oi.quantity * m.price) AS line_total
FROM students s
INNER JOIN orders o ON s.student_id = o.student_id
INNER JOIN order_items oi ON o.order_id = oi.order_id
INNER JOIN menu_items m ON oi.menu_id = m.menu_id
WHERE o.order_date >= '2026-08-01'
ORDER BY o.order_date DESC, m.item_name;

-- Task 4 Version B (LEFT JOIN with WHERE - the broken one)
SELECT s.student_name AS buyer, m.item_name AS item, (oi.quantity * m.price) AS line_total
FROM students s
LEFT JOIN orders o ON s.student_id = o.student_id
LEFT JOIN order_items oi ON o.order_id = oi.order_id
LEFT JOIN menu_items m ON oi.menu_id = m.menu_id
WHERE o.order_date >= '2026-08-01'
ORDER BY o.order_date DESC, m.item_name;

-- Task 4 Version C (THE FIX: date rule moved into ON, so NULL rows survive)
SELECT s.student_name AS buyer, m.item_name AS item, (oi.quantity * m.price) AS line_total
FROM students s
LEFT JOIN orders o ON s.student_id = o.student_id AND o.order_date >= '2026-08-01'
LEFT JOIN order_items oi ON o.order_id = oi.order_id
LEFT JOIN menu_items m ON oi.menu_id = m.menu_id
ORDER BY o.order_date DESC, m.item_name, s.student_name;
```

**Evidence (screenshot filename, output, or file reference in this folder):**
`screenshots/task4a_output.png` — Version A, 4 rows:

| buyer     | item         | line_total |
|-----------|--------------|------------|
| Dan Reyes | Siomai Rice  | 65.00      |
| Ana Cruz  | Burger Steak | 89.00      |
| Ana Cruz  | Iced Tea     | 30.00      |
| Ana Cruz  | Siomai Rice  | 130.00     |

![Task 4 Version A](screenshots/task4a_output.png)

`screenshots/task4b_output.png` — Version B, 4 rows (identical to Version A; Ben and Cara are gone):

![Task 4 Version B](screenshots/task4b_output.png)

`screenshots/task4c_output.png` — Version C (fix), 6 rows:

| buyer     | item         | line_total |
|-----------|--------------|------------|
| Dan Reyes | Siomai Rice  | 65.00      |
| Ana Cruz  | Burger Steak | 89.00      |
| Ana Cruz  | Iced Tea     | 30.00      |
| Ana Cruz  | Siomai Rice  | 130.00     |
| Ben Lim   | NULL         | NULL       |
| Cara Yu   | NULL         | NULL       |

![Task 4 Version C](screenshots/task4c_output.png)

**Row-count comparison:**

| Version | Join style | Rows | Ben and Cara kept? |
|---------|-----------|------|--------------------|
| A | INNER JOIN + WHERE | 4 | No (by design) |
| B | LEFT JOIN + WHERE on right-side date | 4 | No (silently dropped) |
| C | LEFT JOIN, date rule in ON | 6 | Yes, with NULLs |

**Fix:** Move the right-side date rule into the `ON` clause (Version C). A second valid fix is to keep it in `WHERE` and handle `NULL`: `WHERE o.order_date >= '2026-08-01' OR o.order_date IS NULL`.

**Reflection question:**
`WHERE` runs after the join. The rows a LEFT JOIN preserves have `NULL` in the right-side columns, and a comparison like `NULL >= '2026-08-01'` is not true, so `WHERE` removes them and the LEFT JOIN behaves like an INNER JOIN. A rule on the optional (right) side should live in the `ON` clause, or `WHERE` must explicitly allow `NULL` with `OR ... IS NULL`.

## Task 5 — Reflection

**Approach / explanation:**
This task is a written reflection (no query). I contrasted INNER JOIN and LEFT JOIN using examples from Tasks 1, 2, and 4, and described the Task 4 mistake where `WHERE` broke a LEFT JOIN, its symptom, and the fix.



I choose INNER JOIN when a report only needs rows that match on both sides, and LEFT JOIN when the report must keep every row from the main table, even without a match. In Task 1, an INNER JOIN of students and orders is correct for a list of buyers, because Ben and Cara have no orders and should not appear. In Task 2, the question flips to "who never ordered?", which needs a LEFT JOIN with WHERE o.order_id IS NULL, since an INNER JOIN would hide the very students I am looking for. The mistake I observed was in Task 4: I wrote a LEFT JOIN from students but put WHERE o.order_date >= '2026-08-01' on the right-side table. The symptom was that Ben and Cara disappeared and only 4 rows returned, identical to the INNER JOIN version, so the LEFT JOIN had silently become an inner join. The cause is that their order_date is NULL, and a NULL fails the comparison in WHERE. I fixed it by moving the date rule into the ON clause, which returned 6 rows, keeping Ben and Cara with NULLs.

**Reflection question:**
For an "all students including non-buyers" roster I would use a LEFT JOIN starting from `students`; for a "completed sales only" report I would use an INNER JOIN. The symptom of the wrong choice is the row count: if expected students (such as Ben and Cara) are missing from a roster, an INNER JOIN, or a `WHERE` that broke the LEFT JOIN, is the cause. If a sales report shows blank `NULL` rows for people who bought nothing, a LEFT JOIN was used where an INNER JOIN belonged.

## Self-Check

- [ ] All tasks committed with individual, meaningful commit messages
- [x] All files placed inside `week9/`
- [x] This file completed and renamed `answers.md`
- [ ] Repository link pasted into Moodle (no files uploaded)