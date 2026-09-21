
-- INFOMAN1 - Week 5 Lab: SQL 2 (SELECT with Conditions)

USE infoman1_vetclinic;

-- TASK 1: Basic SELECT statements

-- 1a. Every column, every row from pet
SELECT * FROM pet;

-- 1b. Only name and species from pet
SELECT name, species FROM pet;

-- TASK 2: Filtering with equality

-- Return name and species of every pet where species = 'Bird'
SELECT name, species
FROM pet
WHERE species = 'Bird';

-- TASK 3: Filtering with relational operators

-- 3a. pet rows filtered on a numeric column (age)
SELECT name, species, age
FROM pet
WHERE age > 3;

-- 3b. appointment rows filtered on a date column
SELECT appointment_id, appointment_date, reason_for_visit
FROM appointment
WHERE appointment_date >= '2026-08-01';

-- TASK 4: Combine and debug

-- 4a. Original (working) query: column list + WHERE on a string column,
--     correct quoting
SELECT name, age
FROM pet
WHERE species = 'Cat';

-- 4b. Deliberately broken copy: quotes removed around the string literal
--     (a bareword instead of a quoted string)
SELECT name, age
FROM pet
WHERE species = Cat;
