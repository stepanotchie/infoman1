-- ============================================================
-- INFOMAN1 - Week 4 Lab: SQL 1 (DDL & Table Creation)
-- Database: infoman1_vetclinic
-- Implements the Week 3 relational schema:
--   owner(owner_id, first_name, last_name, phone_number)
--   veterinarian(vet_id, first_name, last_name, specialization)
--   pet(pet_id, name, species, age, owner_id FK)
--   appointment(appointment_id, appointment_date, reason_for_visit, vet_id FK, pet_id FK)
--   vaccination_record(pet_id FK, vaccine_name, vaccination_date)  -- composite PK
-- ============================================================

-- ------------------------------------------------------------
-- TASK 1: Create the database
-- ------------------------------------------------------------
CREATE DATABASE infoman1_vetclinic;
SHOW DATABASES;
USE infoman1_vetclinic;

-- ------------------------------------------------------------
-- TASK 2: Core tables (owner, veterinarian, pet)
-- ------------------------------------------------------------
CREATE TABLE owner (
    owner_id      INT UNSIGNED AUTO_INCREMENT,
    first_name    VARCHAR(50) NOT NULL,
    last_name     VARCHAR(50) NOT NULL,
    phone_number  VARCHAR(15) NOT NULL,   -- VARCHAR keeps the leading 0 and "+63"
    PRIMARY KEY (owner_id)
);

CREATE TABLE veterinarian (
    vet_id          INT UNSIGNED AUTO_INCREMENT,
    first_name      VARCHAR(50)  NOT NULL,
    last_name       VARCHAR(50)  NOT NULL,
    specialization  VARCHAR(100) NOT NULL,
    PRIMARY KEY (vet_id)
);

CREATE TABLE pet (
    pet_id    INT UNSIGNED AUTO_INCREMENT,
    name      VARCHAR(50)  NOT NULL,
    species   VARCHAR(30)  NOT NULL,
    age       TINYINT UNSIGNED NOT NULL,  -- age in years (0-255)
    owner_id  INT UNSIGNED NOT NULL,      -- every pet must have exactly one owner
    PRIMARY KEY (pet_id),
    CONSTRAINT fk_pet_owner
        FOREIGN KEY (owner_id) REFERENCES owner (owner_id)
);

-- ------------------------------------------------------------
-- TASK 3: Relationship tables (appointment, vaccination_record)
-- ------------------------------------------------------------
CREATE TABLE appointment (
    appointment_id    INT UNSIGNED AUTO_INCREMENT,
    appointment_date  DATETIME     NOT NULL,
    reason_for_visit  VARCHAR(255) NOT NULL,
    vet_id            INT UNSIGNED NOT NULL,  -- exactly one veterinarian
    pet_id            INT UNSIGNED NOT NULL,  -- exactly one pet
    PRIMARY KEY (appointment_id),
    CONSTRAINT fk_appointment_vet
        FOREIGN KEY (vet_id) REFERENCES veterinarian (vet_id),
    CONSTRAINT fk_appointment_pet
        FOREIGN KEY (pet_id) REFERENCES pet (pet_id)
);

-- Weak entity: PK = parent key (pet_id) + partial key (vaccine_name, vaccination_date)
CREATE TABLE vaccination_record (
    pet_id            INT UNSIGNED NOT NULL,
    vaccine_name      VARCHAR(100) NOT NULL,
    vaccination_date  DATE         NOT NULL,
    PRIMARY KEY (pet_id, vaccine_name, vaccination_date),
    CONSTRAINT fk_vaccination_pet
        FOREIGN KEY (pet_id) REFERENCES pet (pet_id)
);

-- ------------------------------------------------------------
-- TASK 4: Verify the schema
-- ------------------------------------------------------------
SHOW TABLES;
DESCRIBE owner;
DESCRIBE veterinarian;
DESCRIBE pet;
DESCRIBE appointment;
DESCRIBE vaccination_record;

-- ------------------------------------------------------------
-- TASK 5: Deliberate mistake, diagnosis, correction
-- ------------------------------------------------------------
-- 5a. The mistake: change phone_number to INT
ALTER TABLE owner MODIFY COLUMN phone_number INT NOT NULL;

-- 5b. Diagnose
DESCRIBE owner;
-- Optional proof that INT is wrong (max INT = 2147483647):
-- INSERT INTO owner (first_name, last_name, phone_number)
-- VALUES ('Test', 'Owner', 09171234567);
--   -> ERROR 1264: Out of range value for column 'phone_number'
--   (even if it fit, the leading 0 would be lost)

-- 5c. Correct it
ALTER TABLE owner MODIFY COLUMN phone_number VARCHAR(15) NOT NULL;

-- 5d. Confirm
DESCRIBE owner;
