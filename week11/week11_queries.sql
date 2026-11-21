
-- TASK 1 - DIAGNOSE THE ANOMALIES (SELECT only)

-- [Task 1a] UPDATE ANOMALY: rows a D01 rename must touch (expect 3)
SELECT dept_id, department_name, COUNT(*) AS rows_a_rename_must_touch
FROM student_enrollment
WHERE dept_id = 'D01'
GROUP BY dept_id, department_name;

-- [Task 1b] INSERT ANOMALY: IT103 has no row to live in (expect empty set)
SELECT * FROM student_enrollment WHERE course_id = 'IT103';

-- [Task 1b] INSERT ANOMALY: placeholder student the table would force
SELECT NULL AS student_id, 'PLACEHOLDER' AS student_name, NULL AS enrolled_courses,
       'IT103' AS course_id, 'Intro to Networks' AS course_title,
       'D01' AS dept_id, 'Computing Studies' AS department_name, NULL AS grade
UNION ALL
SELECT student_id, student_name, enrolled_courses, course_id,
       course_title, dept_id, department_name, grade
FROM student_enrollment;

-- [Task 1c] DELETE ANOMALY: Ana's IT102 row is the only copy of IT102 (expect 1)
SELECT course_id, course_title, dept_id, COUNT(*) AS rows_holding_this_course
FROM student_enrollment
WHERE course_id = 'IT102'
GROUP BY course_id, course_title, dept_id;

-- [Task 1c] DELETE ANOMALY: courses left if that row is removed (only IT101)
SELECT DISTINCT course_id, course_title
FROM student_enrollment
WHERE NOT (student_id = 101 AND course_id = 'IT102');



-- TASK 2 - FIRST NORMAL FORM (1NF)


-- [Task 2] Create 1NF table: one row per student-course pair, composite PK
CREATE TABLE student_enrollment_1nf (
  student_id      INT           NOT NULL,
  student_name    VARCHAR(100)  NOT NULL,
  course_id       VARCHAR(10)   NOT NULL,
  course_title    VARCHAR(100)  NOT NULL,
  dept_id         VARCHAR(10)   NOT NULL,
  department_name VARCHAR(100)  NOT NULL,
  grade           DECIMAL(4,2),
  PRIMARY KEY (student_id, course_id)
);

-- [Task 2] Load the 1NF table
INSERT INTO student_enrollment_1nf
  (student_id, student_name, course_id, course_title, dept_id, department_name, grade)
SELECT student_id, student_name, course_id, course_title, dept_id, department_name, grade
FROM student_enrollment;

-- [Task 2] Evidence: every cell is atomic
SELECT * FROM student_enrollment_1nf ORDER BY student_id, course_id;

-- [Task 2] Evidence: no comma-separated lists remain (expect 0)
SELECT COUNT(*) AS cells_with_lists
FROM student_enrollment_1nf
WHERE course_id LIKE '%,%' OR course_title LIKE '%,%' OR dept_id LIKE '%,%';

-- [Task 2] Evidence: one row per student-course pair (Ana = 2, Ben = 1)
SELECT student_id, COUNT(*) AS courses_taken
FROM student_enrollment_1nf
GROUP BY student_id;


-- TASK 3 - SECOND NORMAL FORM (2NF)
-- Composite key: (student_id, course_id)
-- FDs: student_id -> student_name | course_id -> course_title, dept_id,
--      department_name | dept_id -> department_name |
--      (student_id, course_id) -> grade

-- [Task 3a] students(student_id, student_name)
CREATE TABLE students (
  student_id   INT           NOT NULL,
  student_name VARCHAR(100)  NOT NULL,
  PRIMARY KEY (student_id)
);

-- [Task 3b] courses_stage: course facts
CREATE TABLE courses_stage (
  course_id       VARCHAR(10)   NOT NULL,
  course_title    VARCHAR(100)  NOT NULL,
  dept_id         VARCHAR(10)   NOT NULL,
  department_name VARCHAR(100)  NOT NULL,
  PRIMARY KEY (course_id)
);

-- [Task 3c] enrollments: full key + grade
CREATE TABLE enrollments (
  student_id INT          NOT NULL,
  course_id  VARCHAR(10)  NOT NULL,
  grade      DECIMAL(4,2),
  PRIMARY KEY (student_id, course_id),
  CONSTRAINT fk_enroll_student FOREIGN KEY (student_id) REFERENCES students (student_id),
  CONSTRAINT fk_enroll_course  FOREIGN KEY (course_id)  REFERENCES courses_stage (course_id)
);

-- [Task 3] Load the 2NF tables (parents first)
INSERT INTO students (student_id, student_name)
SELECT DISTINCT student_id, student_name FROM student_enrollment_1nf;

INSERT INTO courses_stage (course_id, course_title, dept_id, department_name)
SELECT DISTINCT course_id, course_title, dept_id, department_name FROM student_enrollment_1nf;

INSERT INTO enrollments (student_id, course_id, grade)
SELECT student_id, course_id, grade FROM student_enrollment_1nf;

-- [Task 3] Evidence: contents of the 2NF tables
SELECT * FROM students;
SELECT * FROM courses_stage;
SELECT * FROM enrollments;

-- [Task 3] Reconstructing JOIN (rebuilds the original wide report, 3 rows)
SELECT s.student_id, s.student_name, c.course_id, c.course_title,
       c.dept_id, c.department_name, e.grade
FROM enrollments e
JOIN students      s ON s.student_id = e.student_id
JOIN courses_stage c ON c.course_id  = e.course_id
ORDER BY s.student_id, c.course_id;
-- Grade stays with the full key: it describes one student in one course.


-- TASK 4 - THIRD NORMAL FORM (3NF)
-- Transitive chain: course_id -> dept_id -> department_name

-- [Task 4a] departments(dept_id, department_name)
CREATE TABLE departments (
  dept_id         VARCHAR(10)   NOT NULL,
  department_name VARCHAR(100)  NOT NULL,
  PRIMARY KEY (dept_id)
);

INSERT INTO departments (dept_id, department_name)
SELECT DISTINCT dept_id, department_name FROM courses_stage;

-- [Task 4b] Reduce courses to (course_id, course_title, dept_id) + FK link
ALTER TABLE courses_stage DROP COLUMN department_name;

ALTER TABLE courses_stage
  ADD CONSTRAINT fk_courses_dept FOREIGN KEY (dept_id) REFERENCES departments (dept_id);

RENAME TABLE courses_stage TO courses;

-- [Task 4] Evidence: contents of departments and courses
SELECT * FROM departments;
SELECT * FROM courses;

-- [Task 4c] Decision-path verdict per final table
SELECT 'students' AS table_name, 'student_id' AS primary_key,
       'No' AS multi_valued, 'No (single-column key)' AS partial_dependency,
       'No (student_name depends directly on student_id)' AS transitive_dependency,
       'PASS - 3NF' AS verdict
UNION ALL
SELECT 'departments', 'dept_id', 'No', 'No (single-column key)',
       'No (department_name depends directly on dept_id)', 'PASS - 3NF'
UNION ALL
SELECT 'courses', 'course_id', 'No', 'No (single-column key)',
       'No (dept_id is a foreign key; department_name moved out)', 'PASS - 3NF'
UNION ALL
SELECT 'enrollments', '(student_id, course_id)', 'No', 'No (grade needs the full key)',
       'No (grade is the only non-key column)', 'PASS - 3NF';

-- [Task 4] FOUR-TABLE JOIN: student name, course title, department name, grade
SELECT s.student_id, s.student_name, c.course_id, c.course_title,
       d.department_name, e.grade
FROM enrollments e
JOIN students    s ON s.student_id = e.student_id
JOIN courses     c ON c.course_id  = e.course_id
JOIN departments d ON d.dept_id    = c.dept_id
ORDER BY s.student_id, c.course_id;

-- [Task 4] Lossless check: 1NF rows missing from the rebuilt report (expect 0)
SELECT COUNT(*) AS rows_lost
FROM student_enrollment_1nf w
LEFT JOIN (
  SELECT s.student_id, s.student_name, c.course_id, c.course_title,
         c.dept_id, d.department_name, e.grade
  FROM enrollments e
  JOIN students    s ON s.student_id = e.student_id
  JOIN courses     c ON c.course_id  = e.course_id
  JOIN departments d ON d.dept_id    = c.dept_id
) r ON  r.student_id = w.student_id AND r.course_id = w.course_id
    AND r.student_name = w.student_name AND r.course_title = w.course_title
    AND r.dept_id = w.dept_id AND r.department_name = w.department_name
    AND r.grade = w.grade
WHERE r.student_id IS NULL;