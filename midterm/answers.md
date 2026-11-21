# INFOMAN1 — Midterm Practical Assessment: Answer Document

**Name:** Stephanie Mhay D. De Leon  

**Student ID:** 2510576 

**Repository URL:** https://github.com/stepanotchie/infoman1

**Date Submitted:** November 21, 2026

---

## Task 1: Normalization Audit & 3NF Decomposition

### Approach
I first read `event_booking_flat` row by row and wrote down what each column describes. I identified the composite key `(booking_id, session_code)`, then tested every other column against it: *"if I know only `booking_id`, can I name this value?"* and *"if I know only this non-key column, can I name another column?"*. The first question exposes partial dependencies (2NF), the second exposes transitive dependencies (3NF). I also noticed that `ticket_price` is **not** determined by `ticket_category` (Standard is 500.00, 350.00 and 600.00 in different rows), so ticket data stays with the session row instead of becoming a lookup table. I decomposed in the required order: 1NF (atomic speakers) → 2NF (remove partial dependencies) → 3NF (remove transitive dependencies).

### 1. Data Anomalies in `event_booking_flat`

- **Update Anomaly:** The venue *Metro Tech Auditorium* (`V-METRO`, Quezon City, capacity 300) is stored in three rows: `(101, SESS-A1)`, `(101, SESS-A2)` and `(103, SESS-A1)`. If its capacity changes to 350, all three rows must be edited. If only one or two are updated, the table disagrees with itself about the venue's capacity. The same happens for organizer *Green Earth Initiative*, whose name/email repeat in rows 102 and 104.
- **Insertion Anomaly:** The new venue `V-CAMPUS` (University Amphitheater, Quezon City, 500) cannot be stored on its own. Every row requires a `booking_id`, `session_code`, `booking_date`, organizer, event title, ticket category, price and ticket count (all `NOT NULL`), so a venue with no booking cannot be registered without inventing fake booking data.
- **Deletion Anomaly:** Row `(103, SESS-A1)` is the only row for the event *AI & Cloud Infrastructure* and for the organizer *Innovate Campus Lab* (`lead@innovatecampus.edu`). Deleting that single booking row also erases the event, its date and the organizer's contact details. Likewise, deleting the only row of a venue would erase the venue itself.

### 2. Functional Dependencies
- `booking_id -> booking_date, event_title, organizer_id, venue_code`  (partial: depends on only part of the composite key)
- `organizer_id -> organizer_name, organizer_email`
- `organizer_email -> organizer_id`  (emails are unique per organizer, so email is a candidate key of organizers)
- `venue_code -> venue_name, venue_city, venue_capacity`
- `booking_id, session_code -> ticket_category, ticket_price, tickets_booked`  (full dependency on the whole composite key)
- `booking_id, session_code ->> speaker_name`  (multi-valued: one session has several speakers)
- Transitive chains: `booking_id -> organizer_id -> organizer_name, organizer_email` and `booking_id -> venue_code -> venue_name, venue_city, venue_capacity`
- Non-dependencies (checked on purpose): `session_code` alone determines nothing (`SESS-A1` appears in events 101 and 103 with different speakers), and `ticket_category` does not determine `ticket_price`.

### 3. Normalization Progression

- **First Normal Form (1NF)** (include how speakers become atomic rows):
  `speaker_list` held values like `'Dr. Perez, Engr. Cruz'`, which is not atomic. In 1NF every speaker gets its own row, so the key becomes `(booking_id, session_code, speaker_name)` and the 7 flat rows become 11 rows (one per session-speaker pair). Because a speaker appears in many sessions and a session has many speakers, speakers are modeled as their own entity `speakers` linked to sessions through a junction table `booking_speakers` (many-to-many). All other attributes now hold single values.
- **Second Normal Form (2NF):**
  The 1NF table still has partial dependencies. `booking_date, event_title, organizer_*, venue_*` depend only on `booking_id`, and ticket data depends only on `(booking_id, session_code)`. I split the data so every non-key attribute depends on the whole key of its table:
  `event_booking(booking_id, booking_date, event_title, organizer_id, organizer_name, organizer_email, venue_code, venue_name, venue_city, venue_capacity)`,
  `booking(booking_id, session_code, ticket_category, ticket_price, tickets_booked)`,
  `speakers` and the session-speaker junction.
- **Third Normal Form (3NF):**
  `event_booking` still contains transitive dependencies (`booking_id -> organizer_id -> organizer_name/email` and `booking_id -> venue_code -> venue_name/city/capacity`). I moved organizer details into `organizers` (key `organizer_id`) and venue details into `venues` (key `venue_code`), leaving `events` with only `event_title`, `booking_date` and two foreign keys. Every non-key column now depends on the key, the whole key, and nothing but the key. I also gave the ticket-booking table a surrogate key `booking_no` (with `(event_id, session_code)` kept `UNIQUE` as the original natural key) so the junction table can use a clean two-column composite key.

### 4. Final Relational Schema Notation

```
venues(<u>venue_code</u>, venue_name, venue_city, venue_capacity)
organizers(<u>organizer_id</u>, organizer_name, organizer_email)
events(<u>event_id</u>, event_title, booking_date, organizer_id [FK], venue_code [FK])
bookings(<u>booking_no</u>, event_id [FK], session_code, ticket_category, ticket_price, tickets_booked, booking_status)
speakers(<u>speaker_id</u>, speaker_name)
booking_speakers(<u>booking_no</u> [FK], <u>speaker_id</u> [FK])
```

Rendered:

- venues(<u>venue_code</u>, venue_name, venue_city, venue_capacity)
- organizers(<u>organizer_id</u>, organizer_name, organizer_email)
- events(<u>event_id</u>, event_title, booking_date, organizer_id [FK], venue_code [FK])
- bookings(<u>booking_no</u>, event_id [FK], session_code, ticket_category, ticket_price, tickets_booked, booking_status)
- speakers(<u>speaker_id</u>, speaker_name)
- booking_speakers(<u>booking_no</u> [FK], <u>speaker_id</u> [FK])

Notes: `event_id` is the flat table's `booking_id` (it identifies one reserved event). `bookings` has the candidate key `(event_id, session_code)`, enforced with `UNIQUE`. `booking_status` is a new column added for the DEFAULT guardrail.

### Evidence
- Update anomaly: flat rows `(101, SESS-A1)`, `(101, SESS-A2)`, `(103, SESS-A1)` all repeat `V-METRO / Metro Tech Auditorium / Quezon City / 300`.
- Insertion anomaly: no flat row can exist for `V-CAMPUS`, since all booking columns are `NOT NULL`.
- Deletion anomaly: row `(103, SESS-A1)` is the only carrier of event 103 and organizer 3.
- Non-atomic values: rows `(101, SESS-A1)`, `(103, SESS-A1)`, `(104, SESS-C1)` and `(106, SESS-D2)` hold two speakers each in `speaker_list`.
- Partial dependency: `booking_id = 101` always gives *Modern Web & DB Summit*, `2025-04-10`, organizer 1 and `V-METRO`, regardless of `session_code`.

### Reflection
Why does the many-to-many relationship between sessions and speakers require a junction table instead of another column?

A speaker can work in many sessions (Dr. Perez is in bookings 1 and 4; Dr. Aquino in 6 and 7) and a session can have many speakers (booking 1 has Dr. Perez and Engr. Cruz). Putting a list in one column breaks atomicity (1NF), and adding columns like `speaker1`, `speaker2` fixes the maximum and wastes space for sessions with fewer speakers. A foreign key on either side can only point to one row. A junction table `booking_speakers` stores one row per (session, speaker) pair, so any number of speakers per session and sessions per speaker is possible and each speaker name is stored only once in `speakers`.

---

## Task 2: DDL Implementation with Constraints

### Approach
Types: `INT` for numeric identifiers and counts, `VARCHAR` sized to the seed data for codes, names, emails and categories, `DATE` for `booking_date`, and `DECIMAL(8,2)` for `ticket_price` so money is exact (no floating-point rounding). Constraints, all named so errors are readable:
- **PRIMARY KEY** on every table; the junction table `booking_speakers` has a composite PK `(booking_no, speaker_id)`.
- **FOREIGN KEY** `events -> organizers`, `events -> venues`, `bookings -> events`, and both columns of the junction table (`-> bookings`, `-> speakers`). Tables are created parent-first.
- **NOT NULL** on every essential column (names, dates, prices, counts, status).
- **UNIQUE** on `organizers.organizer_email` (also on `speakers.speaker_name` and `bookings(event_id, session_code)` to protect the natural keys).
- **DEFAULT** `'CONFIRMED'` on `bookings.booking_status`.
- **CHECK** `venue_capacity > 0` and `ticket_price >= 0.00` (plus `tickets_booked > 0`).

### Code / Query Used
(Full script is in `task2_schema_ddl.sql`; the table definitions are shown below.)

```sql
-- =====================================================================
-- INFOMAN1 Midterm Lab Exam -- Task 2: DDL Implementation with Constraints
-- Database: eventhub_midterm
-- Target: 3NF schema derived in Task 1
--
--   venues(venue_code PK, venue_name, venue_city, venue_capacity)
--   organizers(organizer_id PK, organizer_name, organizer_email UNIQUE)
--   events(event_id PK, event_title, booking_date, organizer_id FK, venue_code FK)
--   bookings(booking_no PK, event_id FK, session_code, ticket_category,
--            ticket_price, tickets_booked, booking_status)
--   speakers(speaker_id PK, speaker_name UNIQUE)
--   booking_speakers(booking_no FK, speaker_id FK)  -- junction, composite PK
--
-- Run order: eventhub_seed.sql -> task2_schema_ddl.sql -> task3 ...
-- (event_booking_flat is kept; it is the source for the Task 3 migration.)
-- =====================================================================

USE eventhub_midterm;

-- Drop in child-to-parent order so the script can be re-run safely
DROP TABLE IF EXISTS booking_speakers;
DROP TABLE IF EXISTS bookings;
DROP TABLE IF EXISTS speakers;
DROP TABLE IF EXISTS events;
DROP TABLE IF EXISTS organizers;
DROP TABLE IF EXISTS venues;

-- ---------------------------------------------------------------------
-- venues: venue_code -> venue_name, venue_city, venue_capacity
-- ---------------------------------------------------------------------
CREATE TABLE venues (
    venue_code     VARCHAR(20)  NOT NULL,
    venue_name     VARCHAR(100) NOT NULL,
    venue_city     VARCHAR(50)  NOT NULL,
    venue_capacity INT          NOT NULL,
    CONSTRAINT pk_venues PRIMARY KEY (venue_code),
    CONSTRAINT chk_venues_capacity CHECK (venue_capacity > 0)
);

-- ---------------------------------------------------------------------
-- organizers: organizer_id -> organizer_name, organizer_email
-- ---------------------------------------------------------------------
CREATE TABLE organizers (
    organizer_id    INT          NOT NULL,
    organizer_name  VARCHAR(100) NOT NULL,
    organizer_email VARCHAR(100) NOT NULL,
    CONSTRAINT pk_organizers PRIMARY KEY (organizer_id),
    CONSTRAINT uq_organizers_email UNIQUE (organizer_email)
);

-- ---------------------------------------------------------------------
-- events: event_id (= booking_id in the flat table) ->
--         event_title, booking_date, organizer_id, venue_code
-- ---------------------------------------------------------------------
CREATE TABLE events (
    event_id     INT          NOT NULL,
    event_title  VARCHAR(150) NOT NULL,
    booking_date DATE         NOT NULL,
    organizer_id INT          NOT NULL,
    venue_code   VARCHAR(20)  NOT NULL,
    CONSTRAINT pk_events PRIMARY KEY (event_id),
    CONSTRAINT fk_events_organizer FOREIGN KEY (organizer_id)
        REFERENCES organizers (organizer_id),
    CONSTRAINT fk_events_venue FOREIGN KEY (venue_code)
        REFERENCES venues (venue_code)
);

-- ---------------------------------------------------------------------
-- bookings: one row per (event, session) ticket booking.
-- (event_id, session_code) is the original composite key of the flat
-- table; it is kept as a UNIQUE candidate key and a surrogate booking_no
-- is the PK so the speaker junction table needs only a 2-column key.
-- ---------------------------------------------------------------------
CREATE TABLE bookings (
    booking_no      INT           NOT NULL AUTO_INCREMENT,
    event_id        INT           NOT NULL,
    session_code    VARCHAR(20)   NOT NULL,
    ticket_category VARCHAR(50)   NOT NULL,
    ticket_price    DECIMAL(8,2)  NOT NULL,
    tickets_booked  INT           NOT NULL,
    booking_status  VARCHAR(20)   NOT NULL DEFAULT 'CONFIRMED',
    CONSTRAINT pk_bookings PRIMARY KEY (booking_no),
    CONSTRAINT uq_bookings_event_session UNIQUE (event_id, session_code),
    CONSTRAINT fk_bookings_event FOREIGN KEY (event_id)
        REFERENCES events (event_id),
    CONSTRAINT chk_bookings_price CHECK (ticket_price >= 0.00),
    CONSTRAINT chk_bookings_tickets CHECK (tickets_booked > 0)
);

-- ---------------------------------------------------------------------
-- speakers: speaker_id -> speaker_name
-- ---------------------------------------------------------------------
CREATE TABLE speakers (
    speaker_id   INT          NOT NULL AUTO_INCREMENT,
    speaker_name VARCHAR(100) NOT NULL,
    CONSTRAINT pk_speakers PRIMARY KEY (speaker_id),
    CONSTRAINT uq_speakers_name UNIQUE (speaker_name)
);

-- ---------------------------------------------------------------------
-- booking_speakers: junction table for the many-to-many relationship
-- between bookings (sessions) and speakers. Composite PK + two FKs.
-- ---------------------------------------------------------------------
CREATE TABLE booking_speakers (
    booking_no INT NOT NULL,
    speaker_id INT NOT NULL,
    CONSTRAINT pk_booking_speakers PRIMARY KEY (booking_no, speaker_id),
    CONSTRAINT fk_bs_booking FOREIGN KEY (booking_no)
        REFERENCES bookings (booking_no),
    CONSTRAINT fk_bs_speaker FOREIGN KEY (speaker_id)
        REFERENCES speakers (speaker_id)
);

-- ---------------------------------------------------------------------
```

### Evidence: Table Verification (SHOW TABLES / DESCRIBE)

```sql
-- SHOW TABLES;
+----------------------------+
| Tables_in_eventhub_midterm |
+----------------------------+
| booking_speakers           |
| bookings                   |
| event_booking_flat         |
| events                     |
| organizers                 |
| speakers                   |
| venues                     |
+----------------------------+

-- DESCRIBE venues;
+----------------+--------------+------+-----+---------+-------+
| Field          | Type         | Null | Key | Default | Extra |
+----------------+--------------+------+-----+---------+-------+
| venue_code     | varchar(20)  | NO   | PRI | NULL    |       |
| venue_name     | varchar(100) | NO   |     | NULL    |       |
| venue_city     | varchar(50)  | NO   |     | NULL    |       |
| venue_capacity | int          | NO   |     | NULL    |       |
+----------------+--------------+------+-----+---------+-------+

-- DESCRIBE organizers;
+-----------------+--------------+------+-----+---------+-------+
| Field           | Type         | Null | Key | Default | Extra |
+-----------------+--------------+------+-----+---------+-------+
| organizer_id    | int          | NO   | PRI | NULL    |       |
| organizer_name  | varchar(100) | NO   |     | NULL    |       |
| organizer_email | varchar(100) | NO   | UNI | NULL    |       |
+-----------------+--------------+------+-----+---------+-------+

-- DESCRIBE events;
+--------------+--------------+------+-----+---------+-------+
| Field        | Type         | Null | Key | Default | Extra |
+--------------+--------------+------+-----+---------+-------+
| event_id     | int          | NO   | PRI | NULL    |       |
| event_title  | varchar(150) | NO   |     | NULL    |       |
| booking_date | date         | NO   |     | NULL    |       |
| organizer_id | int          | NO   | MUL | NULL    |       |
| venue_code   | varchar(20)  | NO   | MUL | NULL    |       |
+--------------+--------------+------+-----+---------+-------+

-- DESCRIBE bookings;
+-----------------+--------------+------+-----+-----------+----------------+
| Field           | Type         | Null | Key | Default   | Extra          |
+-----------------+--------------+------+-----+-----------+----------------+
| booking_no      | int          | NO   | PRI | NULL      | auto_increment |
| event_id        | int          | NO   | MUL | NULL      |                |
| session_code    | varchar(20)  | NO   |     | NULL      |                |
| ticket_category | varchar(50)  | NO   |     | NULL      |                |
| ticket_price    | decimal(8,2) | NO   |     | NULL      |                |
| tickets_booked  | int          | NO   |     | NULL      |                |
| booking_status  | varchar(20)  | NO   |     | CONFIRMED |                |
+-----------------+--------------+------+-----+-----------+----------------+

-- DESCRIBE speakers;
+--------------+--------------+------+-----+---------+----------------+
| Field        | Type         | Null | Key | Default | Extra          |
+--------------+--------------+------+-----+---------+----------------+
| speaker_id   | int          | NO   | PRI | NULL    | auto_increment |
| speaker_name | varchar(100) | NO   | UNI | NULL    |                |
+--------------+--------------+------+-----+---------+----------------+

-- DESCRIBE booking_speakers;
+------------+------+------+-----+---------+-------+
| Field      | Type | Null | Key | Default | Extra |
+------------+------+------+-----+---------+-------+
| booking_no | int  | NO   | PRI | NULL    |       |
| speaker_id | int  | NO   | PRI | NULL    |       |
+------------+------+------+-----+---------+-------+
```

The CHECK rules do not show in `DESCRIBE`; they are proven by the rejected insert in Task 3 (negative price) and the rejected update in Task 6 (invalid status).

### Reflection
Which table in your schema needed a composite primary key, and why?

`booking_speakers` needs the composite primary key `(booking_no, speaker_id)`. Neither column is unique alone (a booking has several speakers, a speaker is in several bookings), but each *pair* appears once, so the pair is the key. It also stops the same speaker from being linked twice to the same session. In the flat table `(booking_id, session_code)` was the composite key; I kept it as a `UNIQUE` key on `bookings`.

---

## Task 3: Data Migration & Safe DML Operations

### Approach
I loaded parents before children so foreign keys always resolve: `venues` and `organizers` first (`SELECT DISTINCT` from the flat table), then `events` (7 flat rows collapse to 6 events because `booking_id` 101 appears twice), then `bookings` (all 7 rows), then `speakers` and `booking_speakers`. To split `speaker_list`, I joined each flat row with a small number list (1, 2, 3) limited to the real item count (`commas + 1`), pulled the n-th item with two nested `SUBSTRING_INDEX` calls and removed the leading space with `TRIM`. `DISTINCT` keeps each speaker only once in `speakers`; the junction rows then look up `booking_no` and `speaker_id`. No data was lost: 7 bookings, 6 events, 3 venues, 4 organizers, 7 distinct speakers and 11 session-speaker links (2+1+1+2+2+1+2 names in the flat `speaker_list` values).

### Code / Query Used
(Full script is in `task3_dml_operations.sql`.)

```sql
INSERT INTO venues (venue_code, venue_name, venue_city, venue_capacity)
SELECT DISTINCT venue_code, venue_name, venue_city, venue_capacity FROM event_booking_flat ORDER BY venue_code;

INSERT INTO organizers (organizer_id, organizer_name, organizer_email)
SELECT DISTINCT organizer_id, organizer_name, organizer_email FROM event_booking_flat ORDER BY organizer_id;

INSERT INTO events (event_id, event_title, booking_date, organizer_id, venue_code)
SELECT DISTINCT booking_id, event_title, booking_date, organizer_id, venue_code FROM event_booking_flat ORDER BY booking_id;

INSERT INTO bookings (event_id, session_code, ticket_category, ticket_price, tickets_booked)
SELECT booking_id, session_code, ticket_category, ticket_price, tickets_booked
FROM event_booking_flat ORDER BY booking_id, session_code;

INSERT INTO speakers (speaker_name)
SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(f.speaker_list, ',', n.n), ',', -1))
FROM event_booking_flat AS f
JOIN (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3) AS n
  ON n.n <= 1 + LENGTH(f.speaker_list) - LENGTH(REPLACE(f.speaker_list, ',', ''))
WHERE f.speaker_list IS NOT NULL;

INSERT INTO booking_speakers (booking_no, speaker_id)
SELECT DISTINCT b.booking_no, s.speaker_id
FROM event_booking_flat AS f
JOIN (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3) AS n
  ON n.n <= 1 + LENGTH(f.speaker_list) - LENGTH(REPLACE(f.speaker_list, ',', ''))
JOIN bookings AS b ON b.event_id = f.booking_id AND b.session_code = f.session_code
JOIN speakers AS s ON s.speaker_name = TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(f.speaker_list, ',', n.n), ',', -1))
WHERE f.speaker_list IS NOT NULL;

INSERT INTO venues (venue_code, venue_name, venue_city, venue_capacity)
VALUES ('V-CAMPUS', 'University Amphitheater', 'Quezon City', 500);
```

Migration check output (row counts, the split speaker links, then the venues after adding `V-CAMPUS`):

```
+------------------+-----------+
| table_name       | row_count |
+------------------+-----------+
| venues           |         3 |
| organizers       |         4 |
| events           |         6 |
| bookings         |         7 |
| speakers         |         7 |
| booking_speakers |        11 |
+------------------+-----------+

+------------+----------+--------------+--------------+
| booking_no | event_id | session_code | speaker_name |
+------------+----------+--------------+--------------+
|          1 |      101 | SESS-A1      | Dr. Perez    |
|          1 |      101 | SESS-A1      | Engr. Cruz   |
|          2 |      101 | SESS-A2      | Engr. Cruz   |
|          3 |      102 | SESS-B1      | Prof. Santos |
|          4 |      103 | SESS-A1      | Dr. Perez    |
|          4 |      103 | SESS-A1      | Ms. Lim      |
|          5 |      104 | SESS-C1      | Dr. Reyes    |
|          5 |      104 | SESS-C1      | Prof. Santos |
|          6 |      105 | SESS-D1      | Dr. Aquino   |
|          7 |      106 | SESS-D2      | Dr. Aquino   |
|          7 |      106 | SESS-D2      | Engr. Tan    |
+------------+----------+--------------+--------------+

+------------+------------------------------+-------------+----------------+
| venue_code | venue_name                   | venue_city  | venue_capacity |
+------------+------------------------------+-------------+----------------+
| V-BAY      | Bayview Convention Hall      | Manila      |            150 |
| V-CAMPUS   | University Amphitheater      | Quezon City |            500 |
| V-METRO    | Metro Tech Auditorium        | Quezon City |            300 |
| V-PARK     | Greenfield Innovation Center | Pasig       |             80 |
+------------+------------------------------+-------------+----------------+
```

### Safe Change Loop: 10% Ticket Price Increase

- **Step 1 (Preview Rows):**
  ```sql
  SELECT booking_no, event_id, session_code, ticket_category,
         ticket_price AS old_price, ROUND(ticket_price * 1.10, 2) AS new_price
  FROM bookings
  WHERE ticket_price > 400.00
  ORDER BY booking_no;
  ```
  ```
+------------+----------+--------------+-----------------+-----------+-----------+
| booking_no | event_id | session_code | ticket_category | old_price | new_price |
+------------+----------+--------------+-----------------+-----------+-----------+
|          1 |      101 | SESS-A1      | Standard        |    500.00 |    550.00 |
|          2 |      101 | SESS-A2      | VIP             |   1200.00 |   1320.00 |
|          6 |      105 | SESS-D1      | VIP             |   1500.00 |   1650.00 |
|          7 |      106 | SESS-D2      | Standard        |    600.00 |    660.00 |
+------------+----------+--------------+-----------------+-----------+-----------+
  ```
- **Step 2 (Confirm Target Count):**
  `SELECT COUNT(*) AS rows_to_update FROM bookings WHERE ticket_price > 400.00;` returned **4**, matching the 4 previewed rows (Standard 500.00, VIP 1200.00, VIP 1500.00, Standard 600.00).
  ```
+----------------+
| rows_to_update |
+----------------+
|              4 |
+----------------+
  ```
- **Step 3 (Execute UPDATE):**
  ```sql
  UPDATE bookings
  SET ticket_price = ROUND(ticket_price * 1.10, 2)
  WHERE ticket_price > 400.00;
  ```
  The WHERE clause is identical to the one used in Steps 1 and 2.
- **Step 4 (Verify Changes):**
  ```sql
  SELECT booking_no, event_id, session_code, ticket_category, ticket_price AS new_price
  FROM bookings ORDER BY booking_no;
  ```
  ```
+------------+----------+--------------+-----------------+-----------+
| booking_no | event_id | session_code | ticket_category | new_price |
+------------+----------+--------------+-----------------+-----------+
|          1 |      101 | SESS-A1      | Standard        |    550.00 |
|          2 |      101 | SESS-A2      | VIP             |   1320.00 |
|          3 |      102 | SESS-B1      | Standard        |    350.00 |
|          4 |      103 | SESS-A1      | Student         |    250.00 |
|          5 |      104 | SESS-C1      | Standard        |    350.00 |
|          6 |      105 | SESS-D1      | VIP             |   1650.00 |
|          7 |      106 | SESS-D2      | Standard        |    660.00 |
+------------+----------+--------------+-----------------+-----------+
  ```
  Exactly the 4 targeted rows changed (550.00, 1320.00, 1650.00, 660.00); the 350.00, 350.00 and 250.00 tickets are untouched.

### Safe Change Loop: DELETE of `V-TEMP`
First I inserted the temporary venue: `INSERT INTO venues (venue_code, venue_name, venue_city, venue_capacity) VALUES ('V-TEMP', 'Temporary Pop-up Hall', 'Makati', 50);`
- **Step 1 (Preview Rows):**
  ```sql
  SELECT * FROM venues WHERE venue_code = 'V-TEMP';
  ```
  ```
+------------+-----------------------+------------+----------------+
| venue_code | venue_name            | venue_city | venue_capacity |
+------------+-----------------------+------------+----------------+
| V-TEMP     | Temporary Pop-up Hall | Makati     |             50 |
+------------+-----------------------+------------+----------------+
  ```
- **Step 2 (Confirm Target Count):**
  ```sql
  SELECT COUNT(*) AS rows_to_delete FROM venues WHERE venue_code = 'V-TEMP';
  SELECT COUNT(*) AS events_using_venue FROM events WHERE venue_code = 'V-TEMP';
  ```
  ```
+----------------+
| rows_to_delete |
+----------------+
|              1 |
+----------------+
+--------------------+
| events_using_venue |
+--------------------+
|                  0 |
+--------------------+
  ```
  Exactly 1 row will be deleted and no event references it, so the foreign key will not block the delete.
- **Step 3 (Execute DELETE):**
  ```sql
  DELETE FROM venues WHERE venue_code = 'V-TEMP';
  ```
- **Step 4 (Verify Changes):**
  ```sql
  SELECT COUNT(*) AS remaining_v_temp FROM venues WHERE venue_code = 'V-TEMP';
  SELECT venue_code, venue_name, venue_city, venue_capacity FROM venues ORDER BY venue_code;
  ```
  ```
+------------------+
| remaining_v_temp |
+------------------+
|                0 |
+------------------+
+------------+------------------------------+-------------+----------------+
| venue_code | venue_name                   | venue_city  | venue_capacity |
+------------+------------------------------+-------------+----------------+
| V-BAY      | Bayview Convention Hall      | Manila      |            150 |
| V-CAMPUS   | University Amphitheater      | Quezon City |            500 |
| V-METRO    | Metro Tech Auditorium        | Quezon City |            300 |
| V-PARK     | Greenfield Innovation Center | Pasig       |             80 |
+------------+------------------------------+-------------+----------------+
  ```

### Evidence: Constraint Protection Verification

- **Invalid SQL Statement:**
  ```sql
  INSERT INTO bookings (event_id, session_code, ticket_category, ticket_price, tickets_booked)
  VALUES (101, 'SESS-X9', 'Standard', -100.00, 1);
  ```
- **MySQL Error Message Received:**
  ```
  ERROR 3819 (HY000) at line 123: Check constraint 'chk_bookings_price' is violated.
  ```

### Reflection
Why is the `DELETE` targeted by primary key rather than by venue name?

A primary key identifies exactly one row, so `WHERE venue_code = 'V-TEMP'` can never remove more than the row I previewed. `venue_name` is not guaranteed unique: two venues may share a name, or differ by a typo or trailing space, so a name filter could delete several rows or none. Descriptive columns do repeat in this database (`V-METRO` and `V-CAMPUS` are both in Quezon City). Targeting the key also keeps the preview, count, delete and verify steps consistent.

---

## Task 4: Filtering, Functions & Aggregate Analytics

### Approach
All four queries run on the normalized tables after Tasks 2–3, so prices already include the 10% increase (for example SESS-A1 is now 550.00, which is why it passes the "price exceeds 500" test in Query 1). Query 1 joins `bookings` to `events` because the booking date lives in `events`. Query 2 joins `events` to `organizers` for the contact card and uses `DATEDIFF('2025-05-01', booking_date)` so the result is positive. Query 3 uses `LIKE` on `venue_city`. Query 4 groups only by `ticket_category` and uses `HAVING` for the aggregate filter.

### Query 1: Compound Logical Filtering with Precedence
**SQL Query:**
```sql
SELECT e.event_id, e.event_title, e.booking_date,
       b.session_code, b.ticket_category, b.ticket_price, b.tickets_booked
FROM bookings AS b
INNER JOIN events AS e ON e.event_id = b.event_id
WHERE e.booking_date BETWEEN '2025-04-10' AND '2025-04-20'
  AND (b.ticket_category = 'VIP' OR b.ticket_price > 500.00)
ORDER BY e.booking_date, b.session_code;
```
**Output:**
```
+----------+-------------------------+--------------+--------------+-----------------+--------------+----------------+
| event_id | event_title             | booking_date | session_code | ticket_category | ticket_price | tickets_booked |
+----------+-------------------------+--------------+--------------+-----------------+--------------+----------------+
|      101 | Modern Web & DB Summit  | 2025-04-10   | SESS-A1      | Standard        |       550.00 |              4 |
|      101 | Modern Web & DB Summit  | 2025-04-10   | SESS-A2      | VIP             |      1320.00 |              2 |
|      105 | Health Informatics 2025 | 2025-04-20   | SESS-D1      | VIP             |      1650.00 |              1 |
+----------+-------------------------+--------------+--------------+-----------------+--------------+----------------+
```

### Query 2: Scalar String & Date Functions
**SQL Query:**
```sql
SELECT e.event_id, e.event_title,
       CONCAT(o.organizer_name, ' <', o.organizer_email, '>') AS contact_card,
       e.booking_date,
       DATEDIFF('2025-05-01', e.booking_date) AS days_elapsed
FROM events AS e
INNER JOIN organizers AS o ON o.organizer_id = e.organizer_id
ORDER BY e.booking_date, e.event_id;
```
**Output:**
```
+----------+-----------------------------+-------------------------------------------------+--------------+--------------+
| event_id | event_title                 | contact_card                                    | booking_date | days_elapsed |
+----------+-----------------------------+-------------------------------------------------+--------------+--------------+
|      101 | Modern Web & DB Summit      | Tech Forward PH <info@techforward.ph>           | 2025-04-10   |           21 |
|      102 | Urban Ecology Seminar       | Green Earth Initiative <contact@greenearth.org> | 2025-04-12   |           19 |
|      103 | AI & Cloud Infrastructure   | Innovate Campus Lab <lead@innovatecampus.edu>   | 2025-04-15   |           16 |
|      104 | Community Climate Action    | Green Earth Initiative <contact@greenearth.org> | 2025-04-18   |           13 |
|      105 | Health Informatics 2025     | Digital Health Alliance <care@digitalhealth.ph> | 2025-04-20   |           11 |
|      106 | Telemedicine Implementation | Digital Health Alliance <care@digitalhealth.ph> | 2025-04-22   |            9 |
+----------+-----------------------------+-------------------------------------------------+--------------+--------------+
```

### Query 3: Pattern Matching with LIKE Wildcards
**SQL Query:**
```sql
SELECT venue_code, venue_name, venue_city, venue_capacity
FROM venues
WHERE venue_city LIKE '%City' OR venue_city LIKE 'M%'
ORDER BY venue_city, venue_code;
```
**Output:**
```
+------------+-------------------------+-------------+----------------+
| venue_code | venue_name              | venue_city  | venue_capacity |
+------------+-------------------------+-------------+----------------+
| V-BAY      | Bayview Convention Hall | Manila      |            150 |
| V-CAMPUS   | University Amphitheater | Quezon City |            500 |
| V-METRO    | Metro Tech Auditorium   | Quezon City |            300 |
+------------+-------------------------+-------------+----------------+
```

### Query 4: GROUP BY and HAVING Summary
**SQL Query:**
```sql
SELECT ticket_category,
       SUM(tickets_booked) AS total_tickets,
       SUM(tickets_booked * ticket_price) AS gross_revenue
FROM bookings
GROUP BY ticket_category
HAVING SUM(tickets_booked) >= 5
ORDER BY gross_revenue DESC;
```
**Output:**
```
+-----------------+---------------+---------------+
| ticket_category | total_tickets | gross_revenue |
+-----------------+---------------+---------------+
| Standard        |            18 |       8960.00 |
| Student         |            10 |       2500.00 |
+-----------------+---------------+---------------+
```
VIP (2 + 1 = 3 tickets) is removed by the `HAVING` filter.

### Reflection
Why does Query 4 filter with `HAVING` instead of `WHERE`?

`WHERE` is evaluated before grouping, row by row, so it cannot see `SUM(tickets_booked)`, which only exists after `GROUP BY` has built the groups. `HAVING` runs after grouping and can test aggregates. Using `WHERE tickets_booked >= 5` would instead filter individual bookings and give a different (wrong) answer: it would drop bookings of 4, 2, 3 and 1 tickets and miscompute every category total.

---

## Task 5: Multi-Table Joins & Outer Join Diagnostics

### Approach
The report starts from `bookings` (the many side) and walks up the foreign keys: `bookings.event_id = events.event_id`, `events.venue_code = venues.venue_code`, `events.organizer_id = organizers.organizer_id`. Every join uses `ON` with a primary-key/foreign-key pair, so no Cartesian product occurs. The row count (7) equals the flat table, and an extra check against `event_booking_flat` shows all 7 rows match on every column not changed by the Task 3 price update. For the missing-record and trap queries, I start from `venues` with `LEFT JOIN`. I join `events` and `bookings` as one nested unit so that a venue with an event but no booking is also treated as idle.

### 1. Multi-Table INNER JOIN
**SQL Query:**
```sql
SELECT e.event_title, o.organizer_name, v.venue_name,
       b.ticket_category, b.tickets_booked,
       b.tickets_booked * b.ticket_price AS total_price
FROM bookings AS b
INNER JOIN events     AS e ON e.event_id     = b.event_id
INNER JOIN venues     AS v ON v.venue_code   = e.venue_code
INNER JOIN organizers AS o ON o.organizer_id = e.organizer_id
ORDER BY e.event_id, b.session_code;
```
**Output:**
```
+-----------------------------+-------------------------+------------------------------+-----------------+----------------+-------------+
| event_title                 | organizer_name          | venue_name                   | ticket_category | tickets_booked | total_price |
+-----------------------------+-------------------------+------------------------------+-----------------+----------------+-------------+
| Modern Web & DB Summit      | Tech Forward PH         | Metro Tech Auditorium        | Standard        |              4 |     2200.00 |
| Modern Web & DB Summit      | Tech Forward PH         | Metro Tech Auditorium        | VIP             |              2 |     2640.00 |
| Urban Ecology Seminar       | Green Earth Initiative  | Bayview Convention Hall      | Standard        |              5 |     1750.00 |
| AI & Cloud Infrastructure   | Innovate Campus Lab     | Metro Tech Auditorium        | Student         |             10 |     2500.00 |
| Community Climate Action    | Green Earth Initiative  | Bayview Convention Hall      | Standard        |              3 |     1050.00 |
| Health Informatics 2025     | Digital Health Alliance | Greenfield Innovation Center | VIP             |              1 |     1650.00 |
| Telemedicine Implementation | Digital Health Alliance | Greenfield Innovation Center | Standard        |              6 |     3960.00 |
+-----------------------------+-------------------------+------------------------------+-----------------+----------------+-------------+
```
Losslessness check (`flat_rows` = rows in the flat table, `matching_rows` = rows where the rebuilt data equals the flat data):
```
+-----------+---------------+
| flat_rows | matching_rows |
+-----------+---------------+
|         7 |             7 |
+-----------+---------------+
```

### 2. Finding Unbooked Venues (LEFT JOIN ... IS NULL)
**SQL Query:**
```sql
SELECT v.venue_code, v.venue_name, v.venue_city
FROM venues AS v
LEFT JOIN (events AS e
           INNER JOIN bookings AS b ON b.event_id = e.event_id)
       ON e.venue_code = v.venue_code
WHERE b.booking_no IS NULL;
```
**Output:**
```
+------------+-------------------------+-------------+
| venue_code | venue_name              | venue_city  |
+------------+-------------------------+-------------+
| V-CAMPUS   | University Amphitheater | Quezon City |
+------------+-------------------------+-------------+
```

### 3. The "Silent Inner Join" Trap Comparison
- **Version A (Flawed WHERE filter):**
  ```sql
  SELECT v.venue_code, v.venue_name, b.session_code, b.ticket_category, b.tickets_booked
  FROM venues AS v
  LEFT JOIN (events AS e INNER JOIN bookings AS b ON b.event_id = e.event_id)
         ON e.venue_code = v.venue_code
  WHERE b.ticket_category = 'VIP'
  ORDER BY v.venue_code;
  ```
  ```
+------------+------------------------------+--------------+-----------------+----------------+
| venue_code | venue_name                   | session_code | ticket_category | tickets_booked |
+------------+------------------------------+--------------+-----------------+----------------+
| V-METRO    | Metro Tech Auditorium        | SESS-A2      | VIP             |              2 |
| V-PARK     | Greenfield Innovation Center | SESS-D1      | VIP             |              1 |
+------------+------------------------------+--------------+-----------------+----------------+
  ```
  *Result / Behavior:* Only 2 venues (`V-METRO`, `V-PARK`) are returned. `V-BAY` and `V-CAMPUS` disappeared even though the query used `LEFT JOIN`.

- **Version B (Correct ON condition):**
  ```sql
  SELECT v.venue_code, v.venue_name, b.session_code, b.ticket_category, b.tickets_booked
  FROM venues AS v
  LEFT JOIN (events AS e INNER JOIN bookings AS b ON b.event_id = e.event_id)
         ON e.venue_code = v.venue_code
        AND b.ticket_category = 'VIP'
  ORDER BY v.venue_code;
  ```
  ```
+------------+------------------------------+--------------+-----------------+----------------+
| venue_code | venue_name                   | session_code | ticket_category | tickets_booked |
+------------+------------------------------+--------------+-----------------+----------------+
| V-BAY      | Bayview Convention Hall      | NULL         | NULL            |           NULL |
| V-CAMPUS   | University Amphitheater      | NULL         | NULL            |           NULL |
| V-METRO    | Metro Tech Auditorium        | SESS-A2      | VIP             |              2 |
| V-PARK     | Greenfield Innovation Center | SESS-D1      | VIP             |              1 |
+------------+------------------------------+--------------+-----------------+----------------+
  ```
  *Result / Behavior:* All 4 venues are returned. Venues with VIP bookings show them; `V-BAY` and `V-CAMPUS` stay in the result with `NULL` booking columns.

- **Technical Explanation:**
  In a `LEFT JOIN`, a left row with no match is kept by filling the right-hand columns with `NULL`. A `WHERE` clause runs *after* the join, and `NULL = 'VIP'` evaluates to `UNKNOWN`, not `TRUE`, so `WHERE` throws those preserved rows away. The outer join is silently turned into an inner join. Putting `ticket_category = 'VIP'` in the `ON` clause makes it part of the matching rule: it only decides which bookings attach to a venue, and venues with no matching booking are still preserved with `NULL`s. Rule of thumb: conditions on the *preserved* (left) table go in `WHERE`; conditions on the *optional* (right) table go in `ON`.

### Reflection
Why is `= NULL` the wrong way to find unbooked venues, and what is the correct test?

`NULL` means "unknown", so any comparison with it (`= NULL`, `<> NULL`) yields `UNKNOWN` and never `TRUE`; `WHERE b.booking_no = NULL` would return zero rows even for `V-CAMPUS`. The correct test is `IS NULL` (and `IS NOT NULL`), which asks whether the value is missing. I test the primary key `b.booking_no` because it can never be `NULL` in a real match, so a `NULL` there can only come from the outer join.

---

## Task 6: Schema Evolution & Cross-Week Synthesis

### Approach
I used one `ALTER TABLE` to add `venue_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'` and a named `CHECK` constraint limiting it to `'ACTIVE'`, `'RENOVATION'` and `'INACTIVE'`, exactly the three states in the requirement. A `CHECK` list was chosen over a lookup table because the set of values is small and fixed. The report joins `venues → events → bookings`, filters active venues with `WHERE`, groups by venue name and city, and uses `HAVING` for the average-price rule. Because `V-PARK` was set to `RENOVATION` first, it is excluded by the `WHERE` filter, and `V-CAMPUS` (no bookings) disappears in the inner join.

### 1. ALTER TABLE Statement & Status Constraint
```sql
ALTER TABLE venues
    ADD COLUMN venue_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    ADD CONSTRAINT chk_venues_status
        CHECK (venue_status IN ('ACTIVE', 'RENOVATION', 'INACTIVE'));
```
Result (`DESCRIBE venues;` then the status of every venue, all defaulting to `ACTIVE`):
```
+----------------+--------------+------+-----+---------+-------+
| Field          | Type         | Null | Key | Default | Extra |
+----------------+--------------+------+-----+---------+-------+
| venue_code     | varchar(20)  | NO   | PRI | NULL    |       |
| venue_name     | varchar(100) | NO   |     | NULL    |       |
| venue_city     | varchar(50)  | NO   |     | NULL    |       |
| venue_capacity | int          | NO   |     | NULL    |       |
| venue_status   | varchar(20)  | NO   |     | ACTIVE  |       |
+----------------+--------------+------+-----+---------+-------+

+------------+------------------------------+--------------+
| venue_code | venue_name                   | venue_status |
+------------+------------------------------+--------------+
| V-BAY      | Bayview Convention Hall      | ACTIVE       |
| V-CAMPUS   | University Amphitheater      | ACTIVE       |
| V-METRO    | Metro Tech Auditorium        | ACTIVE       |
| V-PARK     | Greenfield Innovation Center | ACTIVE       |
+------------+------------------------------+--------------+
```

### 2. Targeted Primary-Key UPDATE
```sql
UPDATE venues SET venue_status = 'RENOVATION' WHERE venue_code = 'V-PARK';
```
Preview before, then verification after:
```
+------------+------------------------------+--------------+
| venue_code | venue_name                   | venue_status |
+------------+------------------------------+--------------+
| V-PARK     | Greenfield Innovation Center | ACTIVE       |
+------------+------------------------------+--------------+

+------------+------------------------------+--------------+
| venue_code | venue_name                   | venue_status |
+------------+------------------------------+--------------+
| V-BAY      | Bayview Convention Hall      | ACTIVE       |
| V-CAMPUS   | University Amphitheater      | ACTIVE       |
| V-METRO    | Metro Tech Auditorium        | ACTIVE       |
| V-PARK     | Greenfield Innovation Center | RENOVATION   |
+------------+------------------------------+--------------+
```

### 3. Constraint Test (invalid status)
- **Invalid SQL Statement:**
  ```sql
  UPDATE venues SET venue_status = 'CLOSED' WHERE venue_code = 'V-CAMPUS';
  ```
- **MySQL Error Message Received:**
  ```
  ERROR 3819 (HY000) at line 40: Check constraint 'chk_venues_status' is violated.
  ```
  `V-CAMPUS` kept its status `ACTIVE`.

### 4. Integrated Synthesis Report Query
**SQL Query:**
```sql
SELECT v.venue_name,
       v.venue_city,
       COUNT(b.booking_no)                    AS total_bookings,
       SUM(b.tickets_booked)                  AS total_attendees,
       ROUND(AVG(b.ticket_price), 2)          AS avg_ticket_price,
       SUM(b.tickets_booked * b.ticket_price) AS total_revenue
FROM venues AS v
INNER JOIN events   AS e ON e.venue_code = v.venue_code
INNER JOIN bookings AS b ON b.event_id   = e.event_id
WHERE v.venue_status = 'ACTIVE'
GROUP BY v.venue_name, v.venue_city
HAVING AVG(b.ticket_price) > 300.00
ORDER BY total_revenue DESC;
```
**Output:**
```
+-------------------------+-------------+----------------+-----------------+------------------+---------------+
| venue_name              | venue_city  | total_bookings | total_attendees | avg_ticket_price | total_revenue |
+-------------------------+-------------+----------------+-----------------+------------------+---------------+
| Metro Tech Auditorium   | Quezon City |              3 |              16 |           706.67 |       7340.00 |
| Bayview Convention Hall | Manila      |              2 |               8 |           350.00 |       2800.00 |
+-------------------------+-------------+----------------+-----------------+------------------+---------------+
```
`V-PARK` is excluded by the status filter and `V-CAMPUS` has no bookings.

### Reflection
Why does adding `NOT NULL DEFAULT 'ACTIVE'` succeed on a table that already holds rows?

When MySQL adds a `NOT NULL` column it fills every existing row with the column's `DEFAULT` value. Each of the 4 existing venues received `'ACTIVE'`, so no row is ever `NULL` and the `NOT NULL` rule holds immediately. Without a `DEFAULT`, the new column would have no meaningful value for existing rows (MySQL would fall back to an implicit empty string, which would then violate the `CHECK`). The same default also supplies the status for new inserts that do not mention it.

---

## Task 7: Self-Review & Reflection

### Self-Audit Checklist
- [x] All three anomalies (update, insert, delete) clearly explained with examples
- [x] Schema systematically normalized from flat table $\rightarrow$ 1NF $\rightarrow$ 2NF $\rightarrow$ 3NF
- [x] Speakers modeled with a junction table
- [x] All primary keys underlined and foreign keys marked in schema notation
- [x] DDL created with `NOT NULL`, `UNIQUE`, `DEFAULT`, and `CHECK` constraints
- [x] 4-step Safe Change Loop followed for the `UPDATE` and the `DELETE`
- [x] Invalid insert correctly triggered and documented MySQL constraint error
- [x] Query 1 properly uses parentheses for `AND` / `OR` operator precedence
- [x] Query 4 properly uses `HAVING` instead of `WHERE` for aggregate filter
- [x] Outer join missing-record query uses `IS NULL` check
- [x] Silent inner join trap clearly explained with both query variations
- [x] `ALTER TABLE` successfully executed and invalid status rejected
- [x] Integrated synthesis report combines joins, aggregation, grouping, and ordering

### Concluding Reflection
1. What was the most significant challenge when decomposing the unnormalized flat table into 3NF, and how did separating entities improve data integrity?

   The hardest part was deciding the right key for each table. The flat table's composite key `(booking_id, session_code)` hid the fact that `booking_id` alone determines the event, its date, organizer and venue, while `session_code` alone means nothing (`SESS-A1` appears in events 101 and 103). Splitting the comma-separated `speaker_list` was the second challenge: it needed a `speakers` table, a junction table, and a surrogate `booking_no` so the junction key stays two columns, plus a `SUBSTRING_INDEX` + `TRIM` split during migration. Separating entities fixed the anomalies from Task 1: Metro Tech Auditorium's capacity is now stored in one `venues` row instead of three flat rows, `V-CAMPUS` could be inserted with no booking (Task 3), and `V-TEMP` could be deleted without touching any booking. Foreign keys and `CHECK`/`UNIQUE` constraints then block orphan rows, negative prices (Task 3) and invalid statuses (Task 6).

2. What are the practical performance tradeoffs between keeping a single flat table versus querying multiple normalized tables using `JOIN`s in a high-traffic production environment?

   A flat table is faster for reads: the Task 5 report needs no joins, just one table scan or index lookup. But it makes writes more expensive and risky: changing a venue means updating every row for it (3 rows for Metro Tech Auditorium here, thousands in production), it wastes storage on repeated names and emails, and it risks inconsistent data. The 3NF schema needs a 4-table join for the same report (bookings → events → venues → organizers), which costs CPU and I/O, but with indexes on the primary and foreign keys those joins are cheap, and each write touches one small row, with smaller tables that fit better in memory and less locking contention. In a high-traffic system a common compromise is to keep the normalized tables as the source of truth for writes and add read-optimized copies (views, caching, summary tables or a read replica) for the heaviest reports, rather than giving up integrity.
