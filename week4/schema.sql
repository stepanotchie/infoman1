CREATE DATABASE infoman1_vetclinic;
SHOW DATABASES;
USE infoman1_vetclinic;
CREATE TABLE owner (
    owner_id      INT UNSIGNED AUTO_INCREMENT,
    first_name    VARCHAR(50) NOT NULL,
    last_name     VARCHAR(50) NOT NULL,
    phone_number  VARCHAR(15) NOT NULL,
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
    age       TINYINT UNSIGNED NOT NULL,
    owner_id  INT UNSIGNED NOT NULL,
    PRIMARY KEY (pet_id),
    CONSTRAINT fk_pet_owner
        FOREIGN KEY (owner_id) REFERENCES owner (owner_id)
);
CREATE TABLE appointment (
    appointment_id    INT UNSIGNED AUTO_INCREMENT,
    appointment_date  DATETIME     NOT NULL,
    reason_for_visit  VARCHAR(255) NOT NULL,
    vet_id            INT UNSIGNED NOT NULL,
    pet_id            INT UNSIGNED NOT NULL,
    PRIMARY KEY (appointment_id),
    CONSTRAINT fk_appointment_vet
        FOREIGN KEY (vet_id) REFERENCES veterinarian (vet_id),
    CONSTRAINT fk_appointment_pet
        FOREIGN KEY (pet_id) REFERENCES pet (pet_id)
);
CREATE TABLE vaccination_record (
    pet_id            INT UNSIGNED NOT NULL,
    vaccine_name      VARCHAR(100) NOT NULL,
    vaccination_date  DATE         NOT NULL,
    PRIMARY KEY (pet_id, vaccine_name, vaccination_date),
    CONSTRAINT fk_vaccination_pet
        FOREIGN KEY (pet_id) REFERENCES pet (pet_id)
);
SHOW TABLES;
DESCRIBE owner;
DESCRIBE veterinarian;
DESCRIBE pet;
DESCRIBE appointment;
DESCRIBE vaccination_record;
ALTER TABLE owner MODIFY COLUMN phone_number INT NOT NULL;
DESCRIBE owner;
ALTER TABLE owner MODIFY COLUMN phone_number VARCHAR(15) NOT NULL;
DESCRIBE owner;