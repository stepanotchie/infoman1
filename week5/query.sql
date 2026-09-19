
-- INFOMAN1 - Week 5 Lab: SQL 2 (SELECT with Conditions)

USE infoman1_vetclinic;

-- Sample data
-- Check owner_id / vet_id / pet_id values with SELECT * first;
-- adjust the IDs below if yours do not start at 1.
-- INSERT INTO owner (first_name, last_name, phone_number) VALUES
--   ('Owen', 'Anchola', '09453217890'),
--   ('Geoff', 'Carino', '09176542311'),
--   ('Wendy', 'Bustamante', '09328765432');
--
-- INSERT INTO veterinarian (first_name, last_name, specialization) VALUES
--   ('Ahron', 'Miranda', 'Small Animal Medicine'),
--   ('Prian', 'Gallardo', 'Surgery'),
--   ('Liam', 'Arias', 'Dermatology');
--
-- INSERT INTO pet (name, species, age, owner_id) VALUES
--   ('Kiko', 'Bird', 4, 1),
--   ('Mimi', 'Cat', 2, 2),
--   ('Tweety', 'Bird', 7, 3),
--   ('Luna', 'Cat', 5, 1);
--
-- INSERT INTO appointment (appointment_date, reason_for_visit, vet_id, pet_id) VALUES
--   ('2026-07-10 09:00:00', 'Annual checkup', 1, 1),
--   ('2026-08-15 14:30:00', 'Vaccination', 2, 2),
--   ('2026-09-01 10:00:00', 'Wing injury', 3, 3);

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
